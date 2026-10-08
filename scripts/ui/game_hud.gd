extends CanvasLayer

var hero: Node
var debug_enabled := true
var debug_panel: ColorRect
var debug_label: Label
var title_label: Label
var controls_label: Label
var region_label: Label
var objective_label: Label
var combat_banner: Label
var combat_banner_time := 0.0
var boss: Node
var boss_panel: ColorRect
var boss_bar: ColorRect
var boss_title: Label
var status_panel: ColorRect
var hp_bar: ColorRect
var stamina_bar: ColorRect
var hp_label: Label
var stamina_label: Label
var humanity_label: Label
var humanity_bar: ColorRect
var objective_rule: ColorRect
var impact_flash: ColorRect
var impact_flash_time := 0.0
var pause_overlay: ColorRect
var pause_panel: ColorRect
var pause_title: Label
var resume_button: Button
var save_button: Button
var new_game_button: Button
var title_button: Button
var language_option: OptionButton
var language_label: Label
var save_status_label: Label
var new_game_dialog: ConfirmationDialog
var pause_open := false

func _ready() -> void:
    layer = 10
    process_mode = Node.PROCESS_MODE_ALWAYS
    if not WorldState.hidden_resistance_awakened_event.is_connected(_on_hidden_resistance_awakened):
        WorldState.hidden_resistance_awakened_event.connect(_on_hidden_resistance_awakened)

    impact_flash = ColorRect.new()
    impact_flash.position = Vector2.ZERO
    impact_flash.color = Color(0.95, 0.86, 0.72, 0.0)
    impact_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(impact_flash)

    title_label = Label.new()
    title_label.position = Vector2(36, 24)
    title_label.text = "NEREIS HERO"
    title_label.add_theme_font_size_override("font_size", 24)
    title_label.add_theme_color_override("font_color", Color("#d6c7b2"))
    add_child(title_label)

    controls_label = Label.new()
    controls_label.position = Vector2(38, 62)
    controls_label.text = "A/D  MOVE     SPACE  JUMP     J  ATTACK     K  DODGE"
    controls_label.add_theme_font_size_override("font_size", 13)
    controls_label.add_theme_color_override("font_color", Color("#8f8586"))
    add_child(controls_label)

    region_label = Label.new()
    region_label.position = Vector2(38, 91)
    region_label.text = "ASHEN ROAD"
    region_label.add_theme_font_size_override("font_size", 13)
    region_label.add_theme_color_override("font_color", Color("#665b5d"))
    add_child(region_label)

    objective_label = Label.new()
    objective_label.position = Vector2(38, 118)
    objective_label.add_theme_font_size_override("font_size", 16)
    objective_label.add_theme_color_override("font_color", Color("#b7a48c"))
    add_child(objective_label)

    objective_rule = ColorRect.new()
    objective_rule.position = Vector2(38, 145)
    objective_rule.size = Vector2(280, 2)
    objective_rule.color = Color("#5d5050", 0.55)
    add_child(objective_rule)

    combat_banner = Label.new()
    combat_banner.position = Vector2(410, 116)
    combat_banner.size = Vector2(460, 46)
    combat_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    combat_banner.add_theme_font_size_override("font_size", 28)
    combat_banner.visible = false
    add_child(combat_banner)

    status_panel = ColorRect.new()
    status_panel.position = Vector2(36, 630)
    status_panel.size = Vector2(300, 98)
    status_panel.color = Color("#0a090d", 0.78)
    add_child(status_panel)

    hp_label = Label.new()
    hp_label.position = Vector2(12, 7)
    hp_label.add_theme_font_size_override("font_size", 13)
    status_panel.add_child(hp_label)

    var hp_bg := ColorRect.new()
    hp_bg.position = Vector2(72, 10)
    hp_bg.size = Vector2(235, 10)
    hp_bg.color = Color("#2a2026")
    status_panel.add_child(hp_bg)

    hp_bar = ColorRect.new()
    hp_bar.position = Vector2(72, 10)
    hp_bar.size = Vector2(235, 10)
    hp_bar.color = Color("#a4505a")
    status_panel.add_child(hp_bar)

    stamina_label = Label.new()
    stamina_label.position = Vector2(12, 37)
    stamina_label.add_theme_font_size_override("font_size", 13)
    status_panel.add_child(stamina_label)

    var stamina_bg := ColorRect.new()
    stamina_bg.position = Vector2(72, 40)
    stamina_bg.size = Vector2(235, 10)
    stamina_bg.color = Color("#2a2026")
    status_panel.add_child(stamina_bg)

    stamina_bar = ColorRect.new()
    stamina_bar.position = Vector2(72, 40)
    stamina_bar.size = Vector2(235, 10)
    stamina_bar.color = Color("#9e8b72")
    status_panel.add_child(stamina_bar)

    humanity_label = Label.new()
    humanity_label.position = Vector2(12, 67)
    humanity_label.add_theme_font_size_override("font_size", 13)
    status_panel.add_child(humanity_label)

    var humanity_bg := ColorRect.new()
    humanity_bg.position = Vector2(72, 70)
    humanity_bg.size = Vector2(235, 10)
    humanity_bg.color = Color("#2a2026")
    status_panel.add_child(humanity_bg)

    humanity_bar = ColorRect.new()
    humanity_bar.position = Vector2(72, 70)
    humanity_bar.size = Vector2(235, 10)
    humanity_bar.color = Color("#8e7777")
    status_panel.add_child(humanity_bar)

    boss_panel = ColorRect.new()
    boss_panel.position = Vector2(390, 24)
    boss_panel.size = Vector2(500, 54)
    boss_panel.color = Color("#0a090d", 0.88)
    boss_panel.visible = false
    add_child(boss_panel)

    boss_title = Label.new()
    boss_title.position = Vector2(16, 7)
    boss_title.text = "ASHEN KNIGHT"
    boss_title.add_theme_font_size_override("font_size", 15)
    boss_panel.add_child(boss_title)

    boss_bar = ColorRect.new()
    boss_bar.position = Vector2(16, 31)
    boss_bar.size = Vector2(468, 10)
    boss_bar.color = Color("#9e5961")
    boss_panel.add_child(boss_bar)

    debug_panel = ColorRect.new()
    debug_panel.position = Vector2(930, 24)
    debug_panel.size = Vector2(326, 260)
    debug_panel.color = Color("#0a090d", 0.88)
    add_child(debug_panel)

    debug_label = Label.new()
    debug_label.position = Vector2(18, 14)
    debug_label.size = Vector2(290, 230)
    debug_label.add_theme_font_size_override("font_size", 15)
    debug_panel.add_child(debug_label)

    _build_pause_menu()
    _refresh_localized_ui()

func bind_hero(target: Node) -> void:
    hero = target

func set_story_mode(region: String, objective: String) -> void:
    title_label.text = NereisLocalization.t("hud.title")
    region_label.text = _localize_region(region)
    objective_label.text = _localize_objective(objective)
    _set_humanity_visible(true)

func set_combat_demo_mode() -> void:
    title_label.text = NereisLocalization.t("hud.title") + "  /  CORE COMBAT"
    region_label.text = "ASHEN ROAD"
    _set_humanity_visible(false)

func _on_hidden_resistance_awakened() -> void:
    _show_banner("A WARMTH UNDER THE SKIN", 1.9)

func _set_humanity_visible(value: bool) -> void:
    humanity_label.visible = value
    humanity_bar.visible = value


func set_combat_demo_progress(defeated: int, boss_active: bool, complete: bool) -> void:
    if complete:
        objective_label.text = "CORE COMBAT DEMO COMPLETE"

    elif boss_active:
        objective_label.text = "DEFEAT THE ASHEN KNIGHT"
    else:
        objective_label.text = "DEFEAT SMALL ENEMIES    %d / 3" % defeated

func show_hit_confirm(damage: int) -> void:
    impact_flash_time = 0.07 if damage < 50 else 0.10
    _show_banner("HIT  %d" % damage, 0.18)

func show_death_feedback() -> void:
    _show_banner("DEFEATED  //  RETURNING TO CHECKPOINT", 0.75)

func show_boss_intro() -> void:
    _show_banner("THE ASHEN KNIGHT", 1.40)

func show_phase_two() -> void:
    _show_banner("THE ASHEN KNIGHT  //  PHASE II", 1.10)

func show_complete() -> void:
    _show_banner("CORE COMBAT DEMO COMPLETE", 2.40)

func _show_banner(message: String, duration: float) -> void:
    combat_banner.text = message
    combat_banner_time = duration
    combat_banner.visible = true

func bind_boss(target: Node) -> void:
    boss = target

func set_debug_visible(value: bool) -> void:
    debug_enabled = value
    debug_panel.visible = value

func _process(delta: float) -> void:
    impact_flash_time = max(0.0, impact_flash_time - delta)
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    impact_flash.size = viewport_size
    var flash_ratio: float = clampf(impact_flash_time / 0.07, 0.0, 1.0)
    impact_flash.color.a = flash_ratio * 0.12

    combat_banner_time = max(0.0, combat_banner_time - delta)
    if combat_banner_time <= 0.0:
        combat_banner.visible = false

    _update_status_bars()
    _update_boss_bar()
    if not debug_enabled or not hero:
        return

    var state_name: String = hero.get_debug_state()
    var hp: int = int(hero.get("health"))
    var stamina: int = int(hero.get("stamina"))
    var invulnerable: bool = bool(hero.get("invulnerable"))

    debug_label.text = (
        "DEBUG [F3]
"
        + "Hero HP: %d
" % hp
        + "Stamina: %d
" % stamina
        + "State: %s
" % state_name
        + "Invulnerable: %s
" % invulnerable
        + "Memory: %d
" % WorldState.hero_memory
        + "Humanity: %d
" % WorldState.hero_humanity
        + "Church Alignment: %d
" % WorldState.church_alignment
        + "Lullaby Resonance: %d
" % WorldState.lullaby_resonance
        + "Mite Interactions: %d
" % WorldState.mite_interactions_seen.size()
        + "Mite Missed: %s
" % WorldState.mite_connection_missed
        + "Ancient Residue: %s
" % WorldState.ancient_residue_awakened
        + "Outer Resonance: %s
" % WorldState.outer_god_resonance
        + "Mite Control: %d/3
" % WorldState.mite_control_stage
        + "Union: %s
" % WorldState.physical_union_complete
        + "Artifact: %d/4
" % WorldState.hidden_artifact_pieces
        + "Anchor Awake: %s
" % WorldState.hidden_resistance_awakened
        + "Ending: %s
" % WorldState.ending_route
        + "Candidate: %s
" % NereisEndingEvaluator.get_candidate()
        + "Location: %s
" % WorldState.current_location
        + "Route: %s
" % WorldState.selected_route
        + "Interior Clues: %d
" % WorldState.interior_clues_seen.size()
        + "World Clues: %d
" % WorldState.world_clues_seen.size()
        + "Boss Defeated: %s
" % WorldState.boss_defeated
        + "Route Complete: %s
" % WorldState.route_complete
        + "Slice Complete: %s" % WorldState.slice_complete
    )

func _localize_region(value: String) -> String:
    var key := NereisLocalization.key_for_region(value)
    return NereisLocalization.t(key) if not key.is_empty() else value

func _localize_objective(value: String) -> String:
    var key := NereisLocalization.key_for_objective(value)
    return NereisLocalization.t(key) if not key.is_empty() else value

func _build_pause_menu() -> void:
    pause_overlay = ColorRect.new()
    pause_overlay.position = Vector2.ZERO
    pause_overlay.color = Color("#07060b", 0.82)
    pause_overlay.visible = false
    pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(pause_overlay)

    pause_panel = ColorRect.new()
    pause_panel.position = Vector2(390, 135)
    pause_panel.size = Vector2(500, 450)
    pause_panel.color = Color("#111018", 0.97)
    pause_overlay.add_child(pause_panel)

    pause_title = Label.new()
    pause_title.position = Vector2(44, 28)
    pause_title.size = Vector2(412, 40)
    pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pause_title.add_theme_font_size_override("font_size", 28)
    pause_title.add_theme_color_override("font_color", Color("#d6c7b2"))
    pause_panel.add_child(pause_title)

    resume_button = _make_menu_button()
    resume_button.position = Vector2(90, 88)
    pause_panel.add_child(resume_button)
    resume_button.pressed.connect(_close_pause_menu)

    save_button = _make_menu_button()
    save_button.position = Vector2(90, 148)
    pause_panel.add_child(save_button)
    save_button.pressed.connect(_save_from_menu)

    new_game_button = _make_menu_button()
    new_game_button.position = Vector2(90, 208)
    pause_panel.add_child(new_game_button)
    new_game_button.pressed.connect(_confirm_new_game)

    title_button = _make_menu_button()
    title_button.position = Vector2(90, 268)
    pause_panel.add_child(title_button)
    title_button.pressed.connect(_return_to_title)

    language_label = Label.new()
    language_label.position = Vector2(90, 337)
    language_label.add_theme_font_size_override("font_size", 14)
    language_label.add_theme_color_override("font_color", Color("#8f8586"))
    pause_panel.add_child(language_label)

    language_option = OptionButton.new()
    language_option.position = Vector2(90, 360)
    language_option.size = Vector2(320, 42)
    for language in NereisLocalization.LANGUAGES:
        language_option.add_item(NereisLocalization.language_name(language))
    language_option.item_selected.connect(_on_language_selected)
    pause_panel.add_child(language_option)

    save_status_label = Label.new()
    save_status_label.position = Vector2(90, 405)
    save_status_label.size = Vector2(320, 28)
    save_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    save_status_label.add_theme_font_size_override("font_size", 13)
    save_status_label.add_theme_color_override("font_color", Color("#9e8b72"))
    pause_panel.add_child(save_status_label)

    new_game_dialog = ConfirmationDialog.new()
    new_game_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
    new_game_dialog.confirmed.connect(_start_new_game)
    add_child(new_game_dialog)

func _make_menu_button() -> Button:
    var button := Button.new()
    button.size = Vector2(320, 46)
    button.add_theme_font_size_override("font_size", 17)
    return button

func _refresh_localized_ui() -> void:
    if not is_instance_valid(title_label):
        return
    title_label.text = NereisLocalization.t("hud.title")
    controls_label.text = NereisLocalization.t("hud.controls")
    hp_label.text = NereisLocalization.t("hud.hp")
    stamina_label.text = NereisLocalization.t("hud.sta")
    humanity_label.text = NereisLocalization.t("hud.hum")
    pause_title.text = NereisLocalization.t("menu.paused")
    resume_button.text = NereisLocalization.t("menu.resume")
    save_button.text = NereisLocalization.t("menu.save")
    new_game_button.text = NereisLocalization.t("menu.new_game")
    title_button.text = NereisLocalization.t("menu.return_title")
    language_label.text = NereisLocalization.t("menu.select_language")
    if language_option:
        language_option.select(NereisLocalization.language_index(str(WorldState.language)))
    new_game_dialog.title = NereisLocalization.t("menu.new_game")
    new_game_dialog.dialog_text = NereisLocalization.t("menu.confirm_new_game")
    new_game_dialog.ok_button_text = NereisLocalization.t("menu.confirm")
    new_game_dialog.cancel_button_text = NereisLocalization.t("menu.cancel")

func _on_language_selected(index: int) -> void:
    var language: String = NereisLocalization.LANGUAGES[clampi(index, 0, NereisLocalization.LANGUAGES.size() - 1)]
    WorldState.set_language(language)
    _refresh_localized_ui()
    save_status_label.text = NereisLocalization.language_name(language)

func _save_from_menu() -> void:
    WorldState.save_game()
    save_status_label.text = NereisLocalization.t("menu.saved")
    print("[NEREIS][MENU] Manual save")

func _confirm_new_game() -> void:
    new_game_dialog.popup_centered()
    get_viewport().set_input_as_handled()

func _start_new_game() -> void:
    WorldState.delete_save()
    pause_open = false
    pause_overlay.visible = false
    get_tree().paused = false
    print("[NEREIS][MENU] New game started")
    get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")

func _return_to_title() -> void:
    pause_open = false
    pause_overlay.visible = false
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/boot.tscn")

func _open_pause_menu() -> void:
    pause_open = true
    pause_overlay.visible = true
    save_status_label.text = ""
    language_option.select(NereisLocalization.language_index(str(WorldState.language)))
    get_tree().paused = true
    print("[NEREIS][MENU] Pause menu opened")

func _close_pause_menu() -> void:
    pause_open = false
    pause_overlay.visible = false
    get_tree().paused = false
    print("[NEREIS][MENU] Pause menu closed")

func _toggle_pause_menu() -> void:
    if pause_open:
        _close_pause_menu()
    else:
        _open_pause_menu()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        if WorldState.input_locked:
            return
        _toggle_pause_menu()
        get_viewport().set_input_as_handled()

func _update_status_bars() -> void:
    if not hero or not is_instance_valid(hero):
        return
    var hp: int = clampi(int(hero.get("health")), 0, 100)
    var stamina: float = clampf(float(hero.get("stamina")), 0.0, 100.0)
    var humanity: int = clampi(int(WorldState.hero_humanity), 0, 100)
    hp_bar.size.x = 235.0 * float(hp) / 100.0
    stamina_bar.size.x = 235.0 * stamina / 100.0
    humanity_bar.size.x = 235.0 * float(humanity) / 100.0
    hp_label.text = "%s %d" % [NereisLocalization.t("hud.hp"), hp]
    stamina_label.text = "%s %d" % [NereisLocalization.t("hud.sta"), int(stamina)]
    humanity_label.text = "%s %d" % [NereisLocalization.t("hud.hum"), humanity]

func _update_boss_bar() -> void:
    if not boss or not is_instance_valid(boss) or boss.is_queued_for_deletion() or WorldState.boss_defeated:
        boss_panel.visible = false
        return

    if not hero or hero.global_position.distance_to(boss.global_position) > 720.0:
        boss_panel.visible = false
        return

    var hp: int = int(boss.get("health"))
    var max_health_variant = boss.get("max_health")
    var max_health: float = float(max_health_variant) if max_health_variant != null else 240.0
    var phase_variant = boss.get("phase")
    var phase: int = int(phase_variant) if phase_variant != null else 1
    var name_variant = boss.get("boss_display_name")
    var display_name: String = str(name_variant) if name_variant != null else "ASHEN KNIGHT"
    var ratio: float = clampf(float(hp) / max_health, 0.0, 1.0)
    boss_title.text = "%s  //  PHASE %d" % [display_name, phase]
    boss_bar.color = Color("#c34f5b") if phase >= 2 else Color("#9e5961")
    boss_panel.visible = true
    boss_bar.size.x = 468.0 * ratio
