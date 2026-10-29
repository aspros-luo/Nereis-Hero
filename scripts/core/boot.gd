extends Node

@onready var title_label: Label = $TitleLabel
@onready var continue_button: Button = $TitlePanel/ContinueButton
@onready var new_game_button: Button = $TitlePanel/NewGameButton
@onready var map_test_button: Button = $TitlePanel/MapTestButton
@onready var settings_button: Button = $TitlePanel/SettingsButton
@onready var language_label: Label = $TitlePanel/LanguageLabel
@onready var language_option: OptionButton = $TitlePanel/LanguageOption
@onready var status_label: Label = $TitlePanel/StatusLabel
@onready var confirm_dialog: ConfirmationDialog = $ConfirmDialog


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false

	var saved_settings := ConfigFile.new()
	if saved_settings.load("user://nereis_hero_settings.cfg") == OK:
		WorldState.set_language(str(saved_settings.get_value("general", "language", WorldState.language)))
		var master_volume := clampf(float(saved_settings.get_value("audio", "master_volume", 1.0)), 0.0, 1.0)
		var master_bus := AudioServer.get_bus_index("Master")
		if master_bus >= 0:
			AudioServer.set_bus_volume_linear(master_bus, master_volume)
		var fullscreen := bool(saved_settings.get_value("display", "fullscreen", false))
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

	for language in NereisLocalization.LANGUAGES:
		language_option.add_item(NereisLocalization.language_name(language))

	continue_button.pressed.connect(_continue_game)
	new_game_button.pressed.connect(_confirm_new_game)
	map_test_button.pressed.connect(_open_map_test)
	settings_button.pressed.connect(_open_settings)
	language_option.item_selected.connect(_on_language_selected)
	confirm_dialog.confirmed.connect(_start_new_game)

	_refresh_localized_ui()


func _refresh_localized_ui() -> void:
	title_label.text = NereisLocalization.t("menu.title")
	continue_button.text = NereisLocalization.t("menu.continue")
	new_game_button.text = NereisLocalization.t("menu.new_game")
	language_label.text = NereisLocalization.t("menu.language")
	language_option.select(NereisLocalization.language_index(str(WorldState.language)))
	confirm_dialog.title = NereisLocalization.t("menu.new_game")
	confirm_dialog.dialog_text = NereisLocalization.t("menu.confirm_new_game")
	confirm_dialog.ok_button_text = NereisLocalization.t("menu.confirm")
	confirm_dialog.cancel_button_text = NereisLocalization.t("menu.cancel")


func _on_language_selected(index: int) -> void:
	var language: String = NereisLocalization.LANGUAGES[clampi(index, 0, NereisLocalization.LANGUAGES.size() - 1)]
	WorldState.set_language(language)
	_refresh_localized_ui()
	status_label.text = NereisLocalization.language_name(language)


func _continue_game() -> void:
	if not WorldState.has_valid_save():
		if WorldState.save_load_status == "missing":
			status_label.text = NereisLocalization.t("menu.no_save")
		else:
			match str(WorldState.language):
				"zh_tw":
					status_label.text = "存檔無法讀取，原始檔案已保留"
				"en":
					status_label.text = "Save unavailable. The original file was preserved."
				"ja":
					status_label.text = "セーブデータを読み込めません。元のファイルは保持されています。"
				_:
					status_label.text = "存档无法读取，原始文件已保留"
		return

	var next_scene := WorldState.get_resume_scene_path()
	WorldState.pending_region_spawn_side = WorldState.resume_spawn_side
	print("[NEREIS][BOOT] Continue scene=%s spawn_side=%s" % [next_scene, WorldState.pending_region_spawn_side])
	var change_error := get_tree().change_scene_to_file(next_scene)
	if change_error != OK:
		status_label.text = "无法载入存档对应的场景，请检查资源文件。"
		push_error("[NEREIS][BOOT] Continue scene load failed path=%s error=%d" % [next_scene, change_error])


func _open_map_test() -> void:
	WorldState.debug_map_test_mode = true
	get_tree().change_scene_to_file("res://scenes/debug/world_map_test_menu.tscn")


func _open_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")


func _confirm_new_game() -> void:
	confirm_dialog.popup_centered()
	get_viewport().set_input_as_handled()


func _start_new_game() -> void:
	if not WorldState.start_new_game():
		match str(WorldState.language):
			"zh_tw":
				status_label.text = "無法建立新存檔，請檢查存檔目錄權限。"
			"en":
				status_label.text = "Could not create a new save. Check save-directory permissions."
			"ja":
				status_label.text = "新しいセーブを作成できません。保存先の権限を確認してください。"
			_:
				status_label.text = "无法创建新存档，请检查存档目录权限。"
		return
	var change_error := get_tree().change_scene_to_file("res://scenes/regions/escape_prologue.tscn")
	if change_error != OK:
		status_label.text = "无法载入序章场景，请检查资源文件。"
		push_error("[NEREIS][MENU] New-game scene load failed; error=%d" % change_error)
		return
	print("[NEREIS][MENU] New game started")
