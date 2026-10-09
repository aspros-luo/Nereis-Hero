extends CanvasLayer

var hero: Node
var debug_enabled := false
var debug_panel: ColorRect
var debug_label: Label
var title_label: Label
var controls_label: Label
var region_label: Label
var objective_label: Label
var combat_banner: Label
var combat_banner_time := 0.0
var technique_banner_queue: Array[String] = []
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
var humanity_bg: ColorRect
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
var character_button: Button
var character_details_label: Label
var new_game_dialog: ConfirmationDialog
var story_region_source := ""
var story_objective_source := ""
var pause_open := false
var character_details_open := false

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
    controls_label.text = "A/D  MOVE     SPACE  JUMP     J  ATTACK     K  DODGE     Q  WEAPON"
    controls_label.add_theme_font_size_override("font_size", 13)
    controls_label.add_theme_color_override("font_color", Color("#8f8586"))
    add_child(controls_label)

    region_label = Label.new()
    region_label.position = Vector2(38, 91)
    region_label.text = NereisLocalization.translate_text("ASHEN ROAD")
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
    status_panel.size = Vector2(300, 70)
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

    humanity_bg = ColorRect.new()
    humanity_bg.position = Vector2(72, 70)
    humanity_bg.size = Vector2(235, 10)
    humanity_bg.color = Color("#2a2026")
    humanity_bg.visible = false
    status_panel.add_child(humanity_bg)

    humanity_bar = ColorRect.new()
    humanity_bar.position = Vector2(72, 70)
    humanity_bar.size = Vector2(235, 10)
    humanity_bar.color = Color("#8e7777")
    humanity_bar.visible = false
    humanity_label.visible = false
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
    debug_panel.size = Vector2(326, 460)
    debug_panel.color = Color("#0a090d", 0.88)
    add_child(debug_panel)

    debug_label = Label.new()
    debug_label.position = Vector2(18, 14)
    debug_label.size = Vector2(290, 430)
    debug_label.add_theme_font_size_override("font_size", 12)
    debug_panel.add_child(debug_label)
    debug_panel.visible = debug_enabled

    _build_pause_menu()
    _refresh_localized_ui()

func bind_hero(target: Node) -> void:
    hero = target
    var system: Node = target.get_node_or_null("HeroSystem") if is_instance_valid(target) else null
    if system and system.has_signal("technique_understood"):
        var callback := Callable(self, "_on_technique_understood")
        if not system.is_connected("technique_understood", callback):
            system.connect("technique_understood", callback)

func _on_technique_understood(technique_id: String) -> void:
    var message_key := ""
    match technique_id:
        "blood_iaijutsu":
            message_key = "technique.blood_unlocked"
        "abyss_iaijutsu":
            message_key = "technique.abyss_unlocked"
        "black_horizon":
            message_key = "technique.black_horizon_unlocked"
        _:
            return
    technique_banner_queue.append(NereisLocalization.t(message_key))
    if combat_banner_time <= 0.0:
        _show_next_technique_banner()

func _show_next_technique_banner() -> void:
    if technique_banner_queue.is_empty():
        return
    _show_banner(technique_banner_queue.pop_front(), 2.4)

func set_story_mode(region: String, objective: String) -> void:
    story_region_source = region
    story_objective_source = objective
    title_label.text = NereisLocalization.t("hud.title")
    region_label.text = _localize_region(region)
    objective_label.text = _localize_objective(objective)
    _set_humanity_visible(false)

func set_combat_demo_mode() -> void:
    title_label.text = NereisLocalization.t("hud.title") + "  /  " + NereisLocalization.translate_text("CORE COMBAT")
    region_label.text = "ASHEN ROAD"
    _set_humanity_visible(false)

func _on_hidden_resistance_awakened() -> void:
    _show_banner("A WARMTH UNDER THE SKIN", 1.9)

func _set_humanity_visible(_value: bool) -> void:
    # Hidden narrative values never appear in the normal HUD.
    humanity_label.visible = false
    humanity_bg.visible = false
    humanity_bar.visible = false


func set_combat_demo_progress(defeated: int, boss_active: bool, complete: bool) -> void:
    if complete:
        objective_label.text = NereisLocalization.translate_text("CORE COMBAT DEMO COMPLETE")

    elif boss_active:
        objective_label.text = NereisLocalization.translate_text("DEFEAT THE ASHEN KNIGHT")
    else:
        objective_label.text = NereisLocalization.translate_text("DEFEAT SMALL ENEMIES    %d / 3") % defeated

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
    combat_banner.text = NereisLocalization.translate_text(message)
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
        if not technique_banner_queue.is_empty():
            _show_next_technique_banner()
        else:
            combat_banner.visible = false

    _update_status_bars()
    _update_boss_bar()
    if not debug_enabled or not hero:
        return

    var state_name: String = hero.get_debug_state()
    var hp: int = int(hero.get("health"))
    var stamina: int = int(hero.get("stamina"))
    var invulnerable: bool = bool(hero.get("invulnerable"))

    var action_kind: String = str(hero.call("get_debug_action_kind")) if hero.has_method("get_debug_action_kind") else "unknown"
    var echo_cooldown: float = float(hero.call("get_debug_eldritch_cooldown")) if hero.has_method("get_debug_eldritch_cooldown") else 0.0
    var debug_override: bool = bool(hero.get("debug_ability_override"))
    debug_label.text = (
        "DEBUG [F3]  F4 TECHNIQUES  F5 REFILL\n"
        + "Technique override: %s\n" % debug_override
        + "Action: %s\n" % action_kind
        + "Echo cooldown: %.1fs\n" % echo_cooldown
        + "Hero HP: %d\n" % hp
        + "Stamina: %d\n" % stamina
        + "State: %s\n" % state_name
        + "Invulnerable: %s\n" % invulnerable
        + "Memory: %d\n" % WorldState.hero_memory
        + "Humanity: %d\n" % WorldState.hero_humanity
        + "Church Alignment: %d\n" % WorldState.church_alignment
        + "Lullaby Resonance: %d\n" % WorldState.lullaby_resonance
        + "Mite Interactions: %d\n" % WorldState.mite_interactions_seen.size()
        + "Mite Missed: %s\n" % WorldState.mite_connection_missed
        + "Ancient Residue: %s\n" % WorldState.ancient_residue_awakened
        + "Outer Resonance: %s\n" % WorldState.outer_god_resonance
        + "Mite Control: %d/3\n" % WorldState.mite_control_stage
        + "Union: %s\n" % WorldState.physical_union_complete
        + "Artifact: %d/4\n" % WorldState.hidden_artifact_pieces
        + "Anchor Awake: %s\n" % WorldState.hidden_resistance_awakened
        + "Ending: %s\n" % WorldState.ending_route
        + "Candidate: %s\n" % NereisEndingEvaluator.get_candidate()
        + "Location: %s\n" % WorldState.current_location
        + "Route: %s\n" % WorldState.selected_route
        + "Interior Clues: %d\n" % WorldState.interior_clues_seen.size()
        + "World Clues: %d\n" % WorldState.world_clues_seen.size()
        + "Boss Defeated: %s\n" % WorldState.boss_defeated
        + "Route Complete: %s\n" % WorldState.route_complete
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
    pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    pause_overlay.color = Color("#07060b", 0.82)
    pause_overlay.visible = false
    pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(pause_overlay)

    pause_panel = ColorRect.new()
    pause_panel.position = Vector2(390, 90)
    pause_panel.size = Vector2(500, 540)
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
    character_details_label = Label.new()
    character_details_label.position = Vector2(48, 72)
    character_details_label.size = Vector2(404, 52)
    character_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    character_details_label.visible = false
    character_details_label.add_theme_font_size_override("font_size", 13)
    character_details_label.add_theme_color_override("font_color", Color("#b7a48c"))
    pause_panel.add_child(character_details_label)

    resume_button.position = Vector2(90, 132)
    pause_panel.add_child(resume_button)
    resume_button.pressed.connect(_close_pause_menu)

    save_button = _make_menu_button()
    save_button.position = Vector2(90, 187)
    pause_panel.add_child(save_button)
    save_button.pressed.connect(_save_from_menu)

    new_game_button = _make_menu_button()
    new_game_button.position = Vector2(90, 242)
    pause_panel.add_child(new_game_button)
    new_game_button.pressed.connect(_confirm_new_game)

    character_button = _make_menu_button()
    character_button.position = Vector2(90, 297)
    pause_panel.add_child(character_button)
    character_button.pressed.connect(_toggle_character_details)

    title_button = _make_menu_button()
    title_button.position = Vector2(90, 352)
    pause_panel.add_child(title_button)
    title_button.pressed.connect(_return_to_title)

    language_label = Label.new()
    language_label.position = Vector2(90, 408)
    language_label.add_theme_font_size_override("font_size", 14)
    language_label.add_theme_color_override("font_color", Color("#8f8586"))
    pause_panel.add_child(language_label)

    language_option = OptionButton.new()
    language_option.position = Vector2(90, 430)
    language_option.size = Vector2(320, 42)
    for language in NereisLocalization.LANGUAGES:
        language_option.add_item(NereisLocalization.language_name(language))
    language_option.item_selected.connect(_on_language_selected)
    pause_panel.add_child(language_option)

    save_status_label = Label.new()
    save_status_label.position = Vector2(90, 478)
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
    if not story_region_source.is_empty():
        region_label.text = _localize_region(story_region_source)
    if not story_objective_source.is_empty():
        objective_label.text = _localize_objective(story_objective_source)
    hp_label.text = NereisLocalization.t("hud.hp")
    stamina_label.text = NereisLocalization.t("hud.sta")
    pause_title.text = NereisLocalization.t("menu.paused")
    resume_button.text = NereisLocalization.t("menu.resume")
    save_button.text = NereisLocalization.t("menu.save")
    new_game_button.text = NereisLocalization.t("menu.new_game")
    character_button.text = NereisLocalization.t("menu.character")
    title_button.text = NereisLocalization.t("menu.return_title")
    language_label.text = NereisLocalization.t("menu.select_language")
    if language_option:
        language_option.select(NereisLocalization.language_index(str(WorldState.language)))
    new_game_dialog.title = NereisLocalization.t("menu.new_game")
    new_game_dialog.dialog_text = NereisLocalization.t("menu.confirm_new_game")
    new_game_dialog.ok_button_text = NereisLocalization.t("menu.confirm")
    new_game_dialog.cancel_button_text = NereisLocalization.t("menu.cancel")
    _refresh_character_details()

func _on_language_selected(index: int) -> void:
    var language: String = NereisLocalization.LANGUAGES[clampi(index, 0, NereisLocalization.LANGUAGES.size() - 1)]
    WorldState.set_language(language)
    _refresh_localized_ui()
    save_status_label.text = NereisLocalization.language_name(language)

func _toggle_character_details() -> void:
    character_details_open = not character_details_open
    character_details_label.visible = character_details_open
    _refresh_character_details()

func _refresh_character_details() -> void:
    var weapon_key := "menu.weapon_short_blade" if str(WorldState.current_weapon_style) == "short_blade" else "menu.weapon_long_sword"
    var weapon_name := NereisLocalization.t(weapon_key)
    var technique_names: PackedStringArray = []
    if WorldState.is_ability_unlocked("iaijutsu_basic"):
        technique_names.append(NereisLocalization.t("menu.technique_basic_iaijutsu"))
    for technique_id in WorldState.learned_techniques:
        if technique_id == "blood_iaijutsu":
            technique_names.append(NereisLocalization.t("menu.technique_blood_iaijutsu"))
        elif technique_id == "abyss_iaijutsu":
            technique_names.append(NereisLocalization.t("menu.technique_abyss_iaijutsu"))
        elif technique_id == "black_horizon":
            technique_names.append(NereisLocalization.t("menu.technique_black_horizon"))
    var techniques_text := ", ".join(technique_names) if not technique_names.is_empty() else NereisLocalization.t("menu.no_techniques")
    character_details_label.text = "%s: %s\n%s: %s\n%s" % [NereisLocalization.t("menu.weapon"), weapon_name, NereisLocalization.t("menu.techniques"), techniques_text, NereisLocalization.t("menu.hidden_stats_note")]

func _save_from_menu() -> void:
    WorldState.save_game()
    save_status_label.text = NereisLocalization.t("menu.saved")
    print("[NEREIS][MENU] Manual save")

func _confirm_new_game() -> void:
    new_game_dialog.popup_centered()
    get_viewport().set_input_as_handled()

func _start_new_game() -> void:
    WorldState.delete_save()
    WorldState.menu_input_locked = false
    pause_open = false
    pause_overlay.visible = false
    get_tree().paused = false
    print("[NEREIS][MENU] New game started")
    get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")

func _return_to_title() -> void:
    WorldState.menu_input_locked = false
    pause_open = false
    pause_overlay.visible = false
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/boot.tscn")

func _open_pause_menu() -> void:
    pause_open = true
    character_details_open = false
    character_details_label.visible = false
    WorldState.menu_input_locked = true
    pause_overlay.visible = true
    save_status_label.text = ""
    language_option.select(NereisLocalization.language_index(str(WorldState.language)))
    _refresh_character_details()
    print("[NEREIS][MENU] Menu opened; world simulation continues")

func _close_pause_menu() -> void:
    pause_open = false
    WorldState.menu_input_locked = false
    pause_overlay.visible = false
    print("[NEREIS][MENU] Menu closed; world simulation continues")

func _toggle_pause_menu() -> void:
    if pause_open:
        _close_pause_menu()
    else:
        _open_pause_menu()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
        set_debug_visible(not debug_enabled)
        get_viewport().set_input_as_handled()
        return
    if event is InputEventKey and event.pressed and not event.echo and debug_enabled and is_instance_valid(hero):
        if event.keycode == KEY_F4 and hero.has_method("toggle_debug_ability_override"):
            hero.call("toggle_debug_ability_override")
            get_viewport().set_input_as_handled()
            return
        if event.keycode == KEY_F5 and hero.has_method("debug_refill_combat_resources"):
            hero.call("debug_refill_combat_resources")
            get_viewport().set_input_as_handled()
            return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        if WorldState.input_locked and not pause_open:
            return
        _toggle_pause_menu()
        get_viewport().set_input_as_handled()

func _update_status_bars() -> void:
    if not hero or not is_instance_valid(hero):
        return
    var hp: int = clampi(int(hero.get("health")), 0, 100)
    var stamina: float = clampf(float(hero.get("stamina")), 0.0, 100.0)
    hp_bar.size.x = 235.0 * float(hp) / 100.0
    stamina_bar.size.x = 235.0 * stamina / 100.0
    hp_label.text = "%s %d" % [NereisLocalization.t("hud.hp"), hp]
    stamina_label.text = "%s %d" % [NereisLocalization.t("hud.sta"), int(stamina)]

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
    display_name = NereisLocalization.translate_text(display_name)
    var ratio: float = clampf(float(hp) / max_health, 0.0, 1.0)
    boss_title.text = "%s  //  PHASE %d" % [display_name, phase]
    boss_bar.color = Color("#c34f5b") if phase >= 2 else Color("#9e5961")
    boss_panel.visible = true
    boss_bar.size.x = 468.0 * ratio
