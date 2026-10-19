extends SceneTree
## Alpha-projection analyzer for a transparent character sprite sheet.
## Reports occupied row/column bands and per-band alpha bounds; it does not guess animation labels.
##
## Run from the project root:
## godot --headless --path . --script res://tools/analyze_sprite_sheet_alpha.gd
##
## Optional arguments: -- --input=res://assets/characters/hero/153143.png --output=user://sprite_sheet_alpha_report.json

const DEFAULT_INPUT := "res://assets/characters/hero/153143.png"
const DEFAULT_OUTPUT := "user://sprite_sheet_alpha_report.json"
const ALPHA_THRESHOLD := 12
const MIN_BAND_SIZE := 2
const MAX_EMPTY_GAP := 1

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var input_path := DEFAULT_INPUT
	var output_path := DEFAULT_OUTPUT
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--input="):
			input_path = argument.trim_prefix("--input=")
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")

	var image := Image.new()
	var load_error := image.load(input_path)
	if load_error != OK:
		push_error("Could not load sprite sheet '%s' (error %s)." % [input_path, load_error])
		quit(1)
		return
	if image.is_compressed():
		var decompress_error := image.decompress()
		if decompress_error != OK:
			push_error("Could not decompress image '%s'." % input_path)
			quit(1)
			return

	var width := image.get_width()
	var height := image.get_height()
	var occupied_rows := PackedByteArray()
	var occupied_columns := PackedByteArray()
	occupied_rows.resize(height)
	occupied_columns.resize(width)
	occupied_rows.fill(0)
	occupied_columns.fill(0)
	var min_x := width
	var min_y := height
	var max_x := -1
	var max_y := -1

	for y in range(height):
		for x in range(width):
			if image.get_pixel(x, y).a8 > ALPHA_THRESHOLD:
				occupied_rows[y] = 1
				occupied_columns[x] = 1
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)

	if max_x < min_x or max_y < min_y:
		push_error("Image contains no pixels above alpha threshold %d." % ALPHA_THRESHOLD)
		quit(1)
		return

	var row_bands := _bands(occupied_rows)
	var column_bands := _bands(occupied_columns)
	var report := {
		"input": input_path,
		"image_size": {"width": width, "height": height},
		"alpha_threshold_8bit": ALPHA_THRESHOLD,
		"occupied_bounds": {
			"x": min_x, "y": min_y,
			"width": max_x - min_x + 1, "height": max_y - min_y + 1
		},
		"row_bands": row_bands,
		"column_bands": column_bands,
		"notes": [
			"Bands are candidates derived from alpha occupancy, not guaranteed animation frames.",
			"Overlapping poses or shared opaque regions can merge neighboring frames.",
			"Action names such as idle/walk/slash require visual review; this tool does not infer semantics."
		]
	}
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write report '%s'." % output_path)
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Sprite-sheet alpha analysis complete: %dx%d" % [width, height])
	print("Occupied bounds: (%d, %d) %dx%d" % [min_x, min_y, max_x - min_x + 1, max_y - min_y + 1])
	print("Candidate row bands: %d; column bands: %d" % [row_bands.size(), column_bands.size()])
	print("Report: %s" % output_path)
	quit(0)


func _bands(mask: PackedByteArray) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var start := -1
	var last_occupied := -1
	for index in range(mask.size()):
		if mask[index] != 0:
			if start < 0:
				start = index
			last_occupied = index
		elif start >= 0 and index - last_occupied > MAX_EMPTY_GAP:
			var length := last_occupied - start + 1
			if length >= MIN_BAND_SIZE:
				result.append({"start": start, "end": last_occupied + 1, "size": length})
			start = -1
			last_occupied = -1
	if start >= 0:
		var length := last_occupied - start + 1
		if length >= MIN_BAND_SIZE:
			result.append({"start": start, "end": last_occupied + 1, "size": length})
	return result
