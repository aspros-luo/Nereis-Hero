extends Node

var title_panel: ColorRect
var title_label: Label
var subtitle_label: Label
var continue_button: Button
var new_game_button: Button
var map_test_button: Button
var language_label: Label
var language_option: OptionButton
var status_label: Label
var confirm_dialog: ConfirmationDialog

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().paused = false
    _build_menu()
    _refresh_localized_ui()

func _build_menu() -> void:
    var background := ColorRect.new()
    background.position = Vector2.ZERO
    background.size = Vector2(1280, 720)
    background.color = Color("#0b090f")
    add_child(background)

    var atmosphere := ColorRect.new()
    atmosphere.position = Vector2(0, 390)
    atmosphere.size = Vector2(1280, 330)
    atmosphere.color = Color("#17121a")
    add_child(atmosphere)

    title_label = Label.new()
    title_label.position = Vector2(250, 140)
    title_label.size = Vector2(780, 62)
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 42)
    title_label.add_theme_color_override("font_color", Color("#d6c7b2"))
    add_child(title_label)

    subtitle_label = Label.new()
    subtitle_label.position = Vector2(280, 208)
    subtitle_label.size = Vector2(720, 48)
    subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle_label.text = "A SONG FOR THE LAST KNIGHT"
    subtitle_label.add_theme_font_size_override("font_size", 15)
    subtitle_label.add_theme_color_override("font_color", Color("#7d7077"))
    add_child(subtitle_label)

    title_panel = ColorRect.new()
    title_panel.position = Vector2(390, 285)
    title_panel.size = Vector2(500, 335)
    title_panel.color = Color("#111018", 0.94)
    add_child(title_panel)

    continue_button = _make_button()
    continue_button.position = Vector2(90, 32)
    title_panel.add_child(continue_button)
    continue_button.pressed.connect(_continue_game)

    new_game_button = _make_button()
    new_game_button.position = Vector2(90, 86)
    title_panel.add_child(new_game_button)
    new_game_button.pressed.connect(_confirm_new_game)

    map_test_button = _make_button()
    map_test_button.position = Vector2(90, 140)
    map_test_button.text = "宏观地图验收 / World Map Test"
    title_panel.add_child(map_test_button)
    map_test_button.pressed.connect(_open_map_test)

    language_label = Label.new()
    language_label.position = Vector2(90, 198)
    language_label.add_theme_font_size_override("font_size", 14)
    language_label.add_theme_color_override("font_color", Color("#8f8586"))
    title_panel.add_child(language_label)

    language_option = OptionButton.new()
    language_option.position = Vector2(90, 221)
    language_option.size = Vector2(320, 42)
    for language in NereisLocalization.LANGUAGES:
        language_option.add_item(NereisLocalization.language_name(language))
    language_option.item_selected.connect(_on_language_selected)
    title_panel.add_child(language_option)

    status_label = Label.new()
    status_label.position = Vector2(90, 272)
    status_label.size = Vector2(320, 26)
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 12)
    status_label.add_theme_color_override("font_color", Color("#756d72"))
    title_panel.add_child(status_label)

    confirm_dialog = ConfirmationDialog.new()
    confirm_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
    confirm_dialog.confirmed.connect(_start_new_game)
    add_child(confirm_dialog)

    var footer := Label.new()
    footer.position = Vector2(0, 670)
    footer.size = Vector2(1280, 24)
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.text = "NEREIS / HERO"
    footer.add_theme_font_size_override("font_size", 12)
    footer.add_theme_color_override("font_color", Color("#4d454d"))
    add_child(footer)

func _make_button() -> Button:
    var button := Button.new()
    button.size = Vector2(320, 46)
    button.add_theme_font_size_override("font_size", 17)
    return button

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
