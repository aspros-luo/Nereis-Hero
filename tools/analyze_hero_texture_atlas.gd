extends SceneTree
## Inspect the committed character texture atlas only. This does not read the reference sprite sheet.
## 仅分析仓库内正式纹理图集，不读取仅供参考的精灵图。

const ATLAS_PATH := "res://assets/characters/hero/tex1_512x512_4d6c36bcbd5d9ddc_423915aa39e773f2_9.png"
const REPORT_PATH := "user://hero_texture_atlas_analysis.json"
const ALPHA_THRESHOLD := 0.10
const MIN_COMPONENT_AREA := 8

func _initialize() -> void:
	call_deferred("_analyze")


func _analyze() -> void:
	var image := Image.new()
	var error := image.load(ATLAS_PATH)
	if error != OK:
		push_error("Unable to load texture atlas: %s (error %d)" % [ATLAS_PATH, error])
		quit(1)
		return

	var width := image.get_width()
	var height := image.get_height()
	var total := width * height
	var transparent_count := 0
	var partial_alpha_count := 0
	var opaque_count := 0
	var alpha_min := 1.0
	var alpha_max := 0.0
	var alpha_sum := 0.0
	var visited := PackedByteArray()
	visited.resize(total)
	var active_pixels := PackedInt32Array()

	for y in range(height):
		for x in range(width):
			var index := y * width + x
			var alpha := image.get_pixel(x, y).a
			alpha_min = minf(alpha_min, alpha)
			alpha_max = maxf(alpha_max, alpha)
			alpha_sum += alpha
			if alpha <= 0.001:
				transparent_count += 1
			elif alpha < 0.999:
				partial_alpha_count += 1
			else:
				opaque_count += 1
			if alpha > ALPHA_THRESHOLD:
				active_pixels.append(index)

	var components: Array[Dictionary] = []
	if transparent_count > 0:
		for seed in active_pixels:
			if visited[seed] != 0:
				continue
			var queue := PackedInt32Array()
			queue.append(seed)
			visited[seed] = 1
			var cursor := 0
			var min_x := width
			var min_y := height
			var max_x := -1
			var max_y := -1
			while cursor < queue.size():
				var current: int = queue[cursor]
				cursor += 1
				var px := current % width
				var py := int(current / width)
				min_x = mini(min_x, px)
				min_y = mini(min_y, py)
				max_x = maxi(max_x, px)
				max_y = maxi(max_y, py)
				var neighbors := PackedInt32Array()
				if px > 0:
					neighbors.append(current - 1)
				if px + 1 < width:
					neighbors.append(current + 1)
				if py > 0:
					neighbors.append(current - width)
				if py + 1 < height:
					neighbors.append(current + width)
				for neighbor in neighbors:
					if visited[neighbor] != 0:
						continue
					var nx := neighbor % width
					var ny := int(neighbor / width)
					if image.get_pixel(nx, ny).a <= ALPHA_THRESHOLD:
						continue
					visited[neighbor] = 1
					queue.append(neighbor)
			if queue.size() >= MIN_COMPONENT_AREA:
				components.append({
					"area_pixels": queue.size(),
					"bounds": {"x": min_x, "y": min_y, "width": max_x - min_x + 1, "height": max_y - min_y + 1}
				})

	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.area_pixels) > int(b.area_pixels))
	var report := {
		"source": ATLAS_PATH,
		"analysis_scope": "committed texture atlas only; reference sprite sheet excluded",
		"dimensions": {"width": width, "height": height},
		"alpha": {
			"minimum": alpha_min,
			"maximum": alpha_max,
			"mean": alpha_sum / float(total),
			"transparent_pixels": transparent_count,
			"partial_alpha_pixels": partial_alpha_count,
			"opaque_pixels": opaque_count,
			"transparent_ratio": float(transparent_count) / float(total)
		},
		"segmentation": {
			"method": "4-neighbor connected components where alpha > %.2f" % ALPHA_THRESHOLD,
			"minimum_reported_area": MIN_COMPONENT_AREA,
			"component_count": components.size(),
			"components": components,
			"interpretation": "Components are geometric candidates only, not automatically identified body parts."
		}
	}
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write report: " + REPORT_PATH)
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Hero texture atlas analysis complete: %dx%d" % [width, height])
	print("Alpha transparent=%d partial=%d opaque=%d; candidate components=%d" % [transparent_count, partial_alpha_count, opaque_count, components.size()])
	print("Report: " + REPORT_PATH)
	quit(0)
