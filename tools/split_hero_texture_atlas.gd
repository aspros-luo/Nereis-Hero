extends SceneTree
## Export numbered texture candidates and a machine-readable manifest for manual character assembly.
## 导出编号纹理候选块与清单，供手动拼接角色使用。
##
## Run:
## godot --headless --path . --script tools/split_hero_texture_atlas.gd
##
## Output is written under user://hero_texture_parts/ so source assets remain untouched.

const ATLAS_PATH := "res://assets/characters/hero/tex1_512x512_4d6c36bcbd5d9ddc_423915aa39e773f2_9.png"
const OUTPUT_DIR := "user://hero_texture_parts"
const ALPHA_THRESHOLD := 0.10
const MIN_COMPONENT_AREA := 24
const PADDING := 3
const GRID_TILE_SIZE := 64
const GRID_OVERLAP := 8
const MAX_GRID_CANDIDATES := 4096

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var image := Image.new()
	var err := image.load(ATLAS_PATH)
	if err != OK:
		push_error("Cannot load %s (error %d)" % [ATLAS_PATH, err])
		quit(1)
		return

	var absolute_output := ProjectSettings.globalize_path(OUTPUT_DIR)
	var dir_err := DirAccess.make_dir_recursive_absolute(absolute_output)
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		push_error("Cannot create output directory: " + absolute_output)
		quit(1)
		return

	var width := image.get_width()
	var height := image.get_height()
	var components := _find_components(image)
	var component_records: Array[Dictionary] = []
	var component_dir := OUTPUT_DIR.path_join("components")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(component_dir))
	for i in range(components.size()):
		var component: Dictionary = components[i]
		var rect: Rect2i = component.bounds
		var crop_rect := _padded_rect(rect, width, height, PADDING)
		var crop := image.get_region(crop_rect)
		var filename := "component_%03d.png" % (i + 1)
		var save_err := crop.save_png(component_dir.path_join(filename))
		if save_err != OK:
			push_warning("Failed to save " + filename)
		component_records.append({
			"id": "C%03d" % (i + 1),
			"file": "components/" + filename,
			"area_pixels": component.area,
			"bounds": _rect_json(rect),
			"crop_bounds_with_padding": _rect_json(crop_rect),
			"confidence": "geometric candidate only; semantic body-part identity unverified"
		})

	var grid_records := _export_grid_candidates(image, width, height)
	var report := {
		"source": ATLAS_PATH,
		"source_dimensions": {"width": width, "height": height},
		"alpha_threshold": ALPHA_THRESHOLD,
		"component_method": "4-connected flood fill for pixels with alpha > threshold",
		"component_count": component_records.size(),
		"components": component_records,
		"grid_candidates": {
			"tile_size": GRID_TILE_SIZE,
			"overlap": GRID_OVERLAP,
			"count": grid_records.size(),
			"items": grid_records
		},
		"notes": [
			"Component crops are bounding rectangles and may include transparent pixels or neighboring visual content.",
			"Grid crops intentionally overlap to avoid missing details that touch or have no transparent separation.",
			"Candidates are not automatically classified as head, torso, arm, leg, hair, clothing, or weapon.",
			"Original atlas is never modified. Review candidates, then manually select and arrange the useful pieces."
		]
	}
	var manifest_path := OUTPUT_DIR.path_join("manifest.json")
	var manifest := FileAccess.open(manifest_path, FileAccess.WRITE)
	if manifest == null:
		push_error("Cannot write manifest: " + manifest_path)
		quit(1)
		return
	manifest.store_string(JSON.stringify(report, "\t"))
	manifest.close()

	print("Texture candidate export complete.")
	print("Atlas: %dx%d; components: %d; grid crops: %d" % [width, height, component_records.size(), grid_records.size()])
	print("Output: " + absolute_output)
	print("Manifest: " + ProjectSettings.globalize_path(manifest_path))
	quit(0)


func _find_components(image: Image) -> Array[Dictionary]:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var found: Array[Dictionary] = []
	var queue := PackedInt32Array()
	for y in range(height):
		for x in range(width):
			var seed := y * width + x
			if visited[seed] != 0 or image.get_pixel(x, y).a <= ALPHA_THRESHOLD:
				continue
			queue.clear()
			queue.append(seed)
			visited[seed] = 1
			var cursor := 0
			var min_x := x
			var max_x := x
			var min_y := y
			var max_y := y
			while cursor < queue.size():
				var idx: int = queue[cursor]
				cursor += 1
				var px := idx % width
				var py := int(idx / width)
				min_x = mini(min_x, px)
				max_x = maxi(max_x, px)
				min_y = mini(min_y, py)
				max_y = maxi(max_y, py)
				if px > 0:
					_try_add(image, idx - 1, visited, queue)
				if px + 1 < width:
					_try_add(image, idx + 1, visited, queue)
				if py > 0:
					_try_add(image, idx - width, visited, queue)
				if py + 1 < height:
					_try_add(image, idx + width, visited, queue)
			if queue.size() >= MIN_COMPONENT_AREA:
				found.append({
					"area": queue.size(),
					"bounds": Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
				})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.area) > int(b.area)
	)
	return found


func _try_add(image: Image, index: int, visited: PackedByteArray, queue: PackedInt32Array) -> void:
	if visited[index] != 0:
		return
	var width := image.get_width()
	var x := index % width
	var y := int(index / width)
	if image.get_pixel(x, y).a <= ALPHA_THRESHOLD:
		return
	visited[index] = 1
	queue.append(index)


func _export_grid_candidates(image: Image, width: int, height: int) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var output := OUTPUT_DIR.path_join("grid")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var step := maxi(1, GRID_TILE_SIZE - GRID_OVERLAP)
	var index := 0
	for y in range(0, height, step):
		for x in range(0, width, step):
			if index >= MAX_GRID_CANDIDATES:
				push_warning("Grid candidate limit reached; remaining tiles skipped.")
				return records
			var rect := Rect2i(x, y, mini(GRID_TILE_SIZE, width - x), mini(GRID_TILE_SIZE, height - y))
			if rect.size.x <= 0 or rect.size.y <= 0:
				continue
			var filename := "grid_%04d.png" % (index + 1)
			var crop := image.get_region(rect)
			crop.save_png(output.path_join(filename))
			records.append({
				"id": "G%04d" % (index + 1),
				"file": "grid/" + filename,
				"bounds": _rect_json(rect)
			})
			index += 1
	return records


func _padded_rect(rect: Rect2i, width: int, height: int, padding: int) -> Rect2i:
	var left := maxi(0, rect.position.x - padding)
	var top := maxi(0, rect.position.y - padding)
	var right := mini(width, rect.end.x + padding)
	var bottom := mini(height, rect.end.y + padding)
	return Rect2i(left, top, right - left, bottom - top)


func _rect_json(rect: Rect2i) -> Dictionary:
	return {"x": rect.position.x, "y": rect.position.y, "width": rect.size.x, "height": rect.size.y}
