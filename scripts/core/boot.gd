extends Node

@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel
@onready var continue_button: Button = $TitlePanel/ContinueButton
@onready var new_game_button: Button = $TitlePanel/NewGameButton
@onready var map_test_button: Button = $TitlePanel/MapTestButton
@onready var language_label: Label = $TitlePanel/LanguageLabel
@onready var language_option: OptionButton = $TitlePanel/LanguageOption
@onready var status_label: Label = $TitlePanel/StatusLabel
@onready var confirm_dialog: ConfirmationDialog = $ConfirmDialog


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false

	for language in NereisLocalization.LANGUAGES:
		language_option.add_item(NereisLocalization.language_name(language))

	continue_button.pressed.connect(_continue_game)
	new_game_button.pressed.connect(_confirm_new_game)
	map_test_button.pressed.connect(_open_map_test)
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
	if not FileAccess.file_exists("user://nereis_hero_save.json"):
		status_label.text = NereisLocalization.t("menu.no_save")
		get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")
		return

	var next_scene := WorldState.get_resume_scene_path()
	WorldState.pending_region_spawn_side = WorldState.resume_spawn_side
	print("[NEREIS][BOOT] Continue scene=%s spawn_side=%s" % [next_scene, WorldState.pending_region_spawn_side])
	get_tree().change_scene_to_file(next_scene)


func _open_map_test() -> void:
	WorldState.debug_map_test_mode = true
	get_tree().change_scene_to_file("res://scenes/world_map_test_menu.tscn")


func _confirm_new_game() -> void:
	confirm_dialog.popup_centered()
	get_viewport().set_input_as_handled()


func _start_new_game() -> void:
	WorldState.delete_save()
	print("[NEREIS][MENU] New game started")
	get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")
