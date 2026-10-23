extends SceneTree
## Installs the creator-declared CC0 modular character PNG pack into user://.
## Run: godot --headless --path . --script tools/install_itch_cc0_modular_character.gd

const ARCHIVE_URL := "https://opengameart.org/sites/default/files/free_2d_animated_vector_game_character_sprites.zip"
const OUTPUT_DIR := "user://itch_cc0_modular_character"
const ARCHIVE_PATH := "user://itch_cc0_modular_character/source_asset_pack.zip"
const MANIFEST_PATH := "user://itch_cc0_modular_character/manifest.json"
const ASSET_PAGE := "https://rgsdev.itch.io/free-cc0-modular-animated-vector-characters-2d"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var absolute_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	var dir_error := DirAccess.make_dir_recursive_absolute(absolute_dir)
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		push_error("Could not create asset directory: " + absolute_dir)
		quit(1)
		return

	# Prefer a manually downloaded local ZIP when the game engine cannot reach the asset host.
	if not FileAccess.file_exists(ARCHIVE_PATH):
		var local_archive := _find_local_archive()
		if not local_archive.is_empty():
			var copy_error := DirAccess.copy_absolute(local_archive, ProjectSettings.globalize_path(ARCHIVE_PATH))
			if copy_error != OK:
				push_error("Could not copy local asset archive (error %d): %s" % [copy_error, local_archive])
				quit(1)
				return
			print("Using locally downloaded asset pack: " + local_archive)

	if not FileAccess.file_exists(ARCHIVE_PATH):
		print("Downloading CC0 modular character pack (~73 MB) from OpenGameArt...")
		var downloader := HTTPRequest.new()
		downloader.timeout = 240.0
		downloader.max_redirects = 8
		downloader.download_file = ProjectSettings.globalize_path(ARCHIVE_PATH)
		root.add_child(downloader)
		var request_error := downloader.request(ARCHIVE_URL)
		if request_error != OK:
			push_error("Download request failed to start: %s" % error_string(request_error))
			downloader.queue_free()
			quit(1)
			return
		var response: Array = await downloader.request_completed
		downloader.queue_free()
		var result_code := int(response[0])
		var http_code := int(response[1])
		if result_code != HTTPRequest.RESULT_SUCCESS or http_code != 200:
			if FileAccess.file_exists(ARCHIVE_PATH):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVE_PATH))
			push_error("Asset download failed. result=%d HTTP=%d. Download manually from %s" % [result_code, http_code, ASSET_PAGE])
			quit(1)
			return

	if not _extract_archive(ARCHIVE_PATH, OUTPUT_DIR):
		quit(1)
		return
	quit(0)

func _find_local_archive() -> String:
	var home := OS.get_environment("HOME")
	if home.is_empty():
		return ""
	var download_dir := home.path_join("Downloads")
	var dir := DirAccess.open(download_dir)
	if dir == null:
		return ""
	var matches: Array[String] = []
	dir.list_dir_begin()
	var filename := dir.get_next()
	while not filename.is_empty():
		if not dir.current_is_dir():
			var lower := filename.to_lower()
			var expected_name := lower.contains("free 2d animated vector game character sprites") or lower.contains("free_2d_animated_vector_game_character_sprites")
			if expected_name and lower.ends_with(".zip"):
				matches.append(download_dir.path_join(filename))
		filename = dir.get_next()
	dir.list_dir_end()
	if matches.is_empty():
		return ""
	matches.sort()
	# Prefer a plain original filename over browser-added duplicate suffixes.
	for candidate in matches:
		var base := candidate.get_file().to_lower()
		if base in ["free 2d animated vector game character sprites.zip", "free_2d_animated_vector_game_character_sprites.zip"]:
			return candidate
	return matches[0]

func _extract_archive(archive_path: String, output_dir: String) -> bool:
	var reader := ZIPReader.new()
	var open_error := reader.open(archive_path)
	if open_error != OK:
		if FileAccess.file_exists(archive_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(archive_path))
		push_error("Could not open downloaded ZIP (error %d): %s. The partial archive was removed so a retry can download it cleanly." % [open_error, archive_path])
		return false

	var files: Array[Dictionary] = []
	var png_count := 0
	var license_files: Array[String] = []
	for archive_name in reader.get_files():
		var normalized := str(archive_name).replace("\\", "/")
		if normalized.begins_with("/") or normalized.contains("../") or normalized == "..":
			push_warning("Skipped unsafe archive path: " + normalized)
			continue
		var lower_name := normalized.to_lower()
		var is_png := lower_name.ends_with(".png")
		var base_name := lower_name.get_file()
		var is_license := base_name in ["license", "license.txt", "license.md", "copying", "readme.txt", "readme.md"]
		if not is_png and not is_license:
			continue
		var bytes: PackedByteArray = reader.read_file(archive_name)
		if bytes.is_empty():
			push_warning("Skipped empty archive entry: " + normalized)
			continue
		var destination := output_dir.path_join(normalized)
		var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination.get_base_dir()))
		if make_error != OK and make_error != ERR_ALREADY_EXISTS:
			push_warning("Could not create directory for " + normalized)
			continue
		var output := FileAccess.open(destination, FileAccess.WRITE)
		if output == null:
			push_warning("Could not write extracted asset: " + destination)
			continue
		output.store_buffer(bytes)
		output.close()
		if is_png:
			png_count += 1
			files.append({"path": normalized, "bytes": bytes.size()})
		else:
			license_files.append(normalized)
	reader.close()

	var manifest := {
		"schema_version": 1,
		"source_page": ASSET_PAGE,
		"archive_url": ARCHIVE_URL,
		"license": "CC0-1.0 (creator-declared for the free raster PNG pack; retain included notices)",
		"asset_scope": "External user-data installation. No third-party PNGs are committed by this tool.",
		"asset_count": png_count,
		"license_files": license_files,
		"files": files
	}
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if manifest_file == null:
		push_error("Could not write manifest: " + MANIFEST_PATH)
		return false
	manifest_file.store_string(JSON.stringify(manifest, "\t"))
	manifest_file.close()
	print("CC0 character pack installed.")
	print("PNG files: %d" % png_count)
	print("Directory: %s" % ProjectSettings.globalize_path(output_dir))
	print("Manifest: %s" % ProjectSettings.globalize_path(MANIFEST_PATH))
	print("Next: open res://scenes/debug/itch_cc0_modular_rig_lab.tscn")
	return png_count > 0
