extends CanvasLayer


var hero: Node
var debug_enabled := false
@onready var debug_panel: ColorRect = $DebugPanel
@onready var debug_label: Label = $DebugPanel/DebugLabel
@onready var title_label: Label = $TitleLabel
@onready var controls_label: Label = $ControlsLabel
@onready var region_label: Label = $RegionLabel
@onready var objective_label: Label = $ObjectiveLabel
@onready var combat_banner: Label = $CombatBanner
var combat_banner_time := 0.0
var technique_banner_queue: Array[String] = []
var boss: Node
@onready var boss_panel: ColorRect = $BossPanel
@onready var boss_bar: ColorRect = $BossPanel/BossBar
@onready var boss_title: Label = $BossPanel/BossTitle
@onready var status_panel: ColorRect = $StatusPanel
@onready var hp_bar: ColorRect = $StatusPanel/HPBar
@onready var stamina_bar: ColorRect = $StatusPanel/StaminaBar
@onready var hp_label: Label = $StatusPanel/HPLabel
@onready var stamina_label: Label = $StatusPanel/StaminaLabel
@onready var humanity_label: Label = $StatusPanel/HumanityLabel
@onready var humanity_bar: ColorRect = $StatusPanel/HumanityBar
@onready var humanity_bg: ColorRect = $StatusPanel/HumanityBackground
@onready var objective_rule: ColorRect = $ObjectiveRule
@onready var impact_flash: ColorRect = $ImpactFlash
var impact_flash_time := 0.0
@onready var pause_overlay: ColorRect = $PauseOverlay
@onready var pause_panel: ColorRect = $PauseOverlay/PausePanel
@onready var pause_title: Label = $PauseOverlay/PausePanel/PauseTitle
@onready var resume_button: Button = $PauseOverlay/PausePanel/ResumeButton
@onready var save_button: Button = $PauseOverlay/PausePanel/SaveButton
@onready var new_game_button: Button = $PauseOverlay/PausePanel/NewGameButton
@onready var title_button: Button = $PauseOverlay/PausePanel/TitleButton
@onready var language_option: OptionButton = $PauseOverlay/PausePanel/LanguageOption
@onready var language_label: Label = $PauseOverlay/PausePanel/LanguageLabel
@onready var save_status_label: Label = $PauseOverlay/PausePanel/SaveStatusLabel
@onready var character_button: Button = $PauseOverlay/PausePanel/CharacterButton
@onready var character_details_label: Label = $PauseOverlay/PausePanel/CharacterDetailsLabel
@onready var new_game_dialog: ConfirmationDialog = $NewGameDialog
var story_region_source := ""
var story_objective_source := ""
var pause_open := false
var character_details_open := false
@onready var world_map_overlay: Control = $WorldMapOverlay
@onready var inventory_overlay: CanvasLayer = $InventoryOverlay
@onready var item_inspection_panel: CanvasLayer = $ItemInspectionPanel
var map_overlay_previous_input_locked := false

func _ready() -> void:
	if not WorldState.hidden_resistance_awakened_event.is_connected(_on_hidden_resistance_awakened):
		WorldState.hidden_resistance_awakened_event.connect(_on_hidden_resistance_awakened)
	_build_pause_menu()
	debug_panel.visible = debug_enabled
	_refresh_localized_ui()
func show_item_description(item_name: String, description: String) -> void:
	if is_instance_valid(item_inspection_panel):
		item_inspection_panel.call("show_description", item_name, description)

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
	# Keep the authored map code visible even when the region name is localized.
	# 即使区域名称被本地化，也始终保留 A1／H01 等地图编号。
	var region_parts := region.split("｜", false, 1)
	if region_parts.size() == 2 and (region_parts[0].begins_with("A") or region_parts[0].begins_with("H")):
		region_label.text = "%s｜%s" % [region_parts[0], _localize_region(region_parts[1])]
	else:
		region_label.text = _localize_region(region)
	objective_label.text = _localize_objective(objective)
	_set_humanity_visible(false)

func set_combat_demo_mode() -> void:
	title_label.text = NereisLocalization.t("hud.title") + "  /  " + NereisLocalization.translate_text("核心战斗")
	region_label.text = "灰烬之路"
	_set_humanity_visible(false)

func _on_hidden_resistance_awakened() -> void:
	_show_banner("皮肤之下的温热", 1.9)

func _set_humanity_visible(_value: bool) -> void:
	# Hidden narrative values never appear in the normal HUD.
	humanity_label.visible = false
	humanity_bg.visible = false
	humanity_bar.visible = false


func set_combat_demo_progress(defeated: int, boss_active: bool, complete: bool) -> void:
	if complete:
		objective_label.text = "核心战斗演示完成"

	elif boss_active:
		objective_label.text = "击败灰烬骑士"
	else:
		objective_label.text = NereisLocalization.translate_text("击败小型敌人    %d / 3") % defeated

func show_hit_confirm(damage: int) -> void:
	impact_flash_time = 0.07 if damage < 50 else 0.10
	_show_banner("命中  %d" % damage, 0.18)

func show_death_feedback() -> void:
	_show_banner("战败  //  返回检查点", 0.75)

func show_boss_intro() -> void:
	_show_banner("灰烬骑士", 1.40)

func show_phase_two() -> void:
	_show_banner("灰烬骑士  //  第二阶段", 1.10)

func show_complete() -> void:
	_show_banner("核心战斗演示完成", 2.40)

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

	var state_name: String = _localize_debug_state(str(hero.get_debug_state()))
	var hp: int = int(hero.get("health"))
	var stamina: int = int(hero.get("stamina"))
	var invulnerable: bool = bool(hero.get("invulnerable"))

	var action_kind: String = _localize_debug_action(str(hero.call("get_debug_action_kind"))) if hero.has_method("get_debug_action_kind") else "未知"
	var echo_cooldown: float = float(hero.call("get_debug_eldritch_cooldown")) if hero.has_method("get_debug_eldritch_cooldown") else 0.0
	var debug_override: bool = bool(hero.get("debug_ability_override"))
	debug_label.text = (
		"调试信息 [F3] 世界面板｜F4 主角面板\nF5 能力调试｜F6 恢复战斗资源｜F10 地图测试\n"
		+ "A/D 移动  空格跳跃  J 攻击\n"
		+ "K 闪避  Q 切换武器  X 冲刺\n"
		+ "G 抓钩／取消  W 攀墙\n"
		+ "V 灵视  F 武器战技  R 深渊回响\n"
		+ "L 居合斩  PgUp/PgDn 切换招式\n"
		+ "能力调试：%s\n" % debug_override
		+ "当前动作：%s\n" % action_kind
		+ "回响冷却：%.1f 秒\n" % echo_cooldown
		+ "生命：%d\n" % hp
		+ "体力：%d\n" % stamina
		+ "动作状态：%s\n" % state_name
		+ "无敌状态：%s\n" % invulnerable
		+ "记忆：%d\n" % WorldState.hero_memory
		+ "人性：%d\n" % WorldState.hero_humanity
		+ "教会倾向：%d\n" % WorldState.church_alignment
		+ "摇篮曲共鸣：%d\n" % WorldState.lullaby_resonance
		+ "蜜忒互动次数：%d\n" % WorldState.mite_interactions_seen.size()
		+ "错过蜜忒关系线：%s\n" % WorldState.mite_connection_missed
		+ "古神残留苏醒：%s\n" % WorldState.ancient_residue_awakened
		+ "外神共鸣：%s\n" % WorldState.outer_god_resonance
		+ "蜜忒影响阶段：%d/3\n" % WorldState.mite_control_stage
		+ "身体交融：%s\n" % WorldState.physical_union_complete
		+ "隐藏证物：%d/4\n" % WorldState.hidden_artifact_pieces
		+ "复国线索锚点：%s\n" % WorldState.hidden_resistance_awakened
		+ "结局路线：%s\n" % _localize_route(WorldState.ending_route)
		+ "结局候选：%s\n" % NereisEndingEvaluator.get_candidate()
		+ "当前位置：%s\n" % _localize_location(WorldState.current_location)
		+ "探索路线：%s\n" % _localize_route(WorldState.selected_route)
		+ "室内线索：%d\n" % WorldState.interior_clues_seen.size()
		+ "世界线索：%d\n" % WorldState.world_clues_seen.size()
		+ "首领已击败：%s\n" % WorldState.boss_defeated
		+ "路线已完成：%s\n" % WorldState.route_complete
		+ "切片已完成：%s" % WorldState.slice_complete
	)

func _localize_debug_state(value: String) -> String:
	var labels := {
		"IDLE": "待机", "MOVE": "移动", "JUMP": "跳跃", "FALL": "下落",
		"ATTACK": "攻击", "DODGE": "闪避", "QUICK_DASH": "快速冲刺",
		"GRAPPLE": "抓钩移动", "WALL_CLIMB": "攀墙", "HURT": "受击", "DEAD": "死亡"
	}
	return str(labels.get(value, value))

func _localize_debug_action(value: String) -> String:
	var labels := {
		"none": "无", "basic": "普通攻击", "judgment_slash": "裁决斩",
		"crescent_combo": "新月连斩", "eldritch_echo": "深渊回响",
		"human_iaijutsu": "凡人居合", "blood": "血之居合",
		"abyssal": "深渊居合", "black_horizon": "黑色天际"
	}
	return str(labels.get(value, value))

func _localize_location(value: String) -> String:
	var labels := {
		"church_escape": "教会手术所", "village": "边境村庄", "ash_forest": "雾林与旧朝圣路",
		"forgotten_city": "被遗忘的城区", "sewer_reservoir": "下水道与旧水库",
		"old_battlefield": "旧战场", "monastery_tower": "修道院与钟塔",
		"prison_depths": "监牢深处", "royal_tomb": "旧王墓", "royal_outer_ring": "王城外环",
		"grand_cathedral": "大圣堂", "deep_research_depths": "古神遗迹与深层研究区",
		"inner_city": "王室内城", "hidden_well": "井底回声层", "hidden_bell_chamber": "倒响钟室",
		"erased_third_street": "被删去的第三街", "reflected_stairwell": "水面背后的楼梯",
		"silent_bell_room": "无声钟室", "erased_royal_name_corridor": "王名抹除廊",
		"mirror_street": "镜街", "primordial_hollow": "胎宫／原初空腔"
	}
	return str(labels.get(value, value))

func _localize_route(value: String) -> String:
	match value:
		"church": return "教会线"
		"lullaby": return "摇篮曲线"
		"ending_paradise": return "永恒乐园"
		"ending_fire": return "烈火天罚"
		"mortal_grave": return "凡人之墓"
		"": return "尚未选择"
		_: return value

func _localize_region(value: String) -> String:
	var key := NereisLocalization.key_for_region(value)
	return NereisLocalization.t(key) if not key.is_empty() else value

func _localize_objective(value: String) -> String:
	var key := NereisLocalization.key_for_objective(value)
	return NereisLocalization.t(key) if not key.is_empty() else value

func _build_pause_menu() -> void:
	resume_button.pressed.connect(_close_pause_menu)
	save_button.pressed.connect(_save_from_menu)
	new_game_button.pressed.connect(_confirm_new_game)
	character_button.pressed.connect(_toggle_character_details)
	title_button.pressed.connect(_return_to_title)
	language_option.item_selected.connect(_on_language_selected)
	new_game_dialog.confirmed.connect(_start_new_game)
	for language in NereisLocalization.LANGUAGES:
		language_option.add_item(NereisLocalization.language_name(language))

func _refresh_localized_ui() -> void:
	if not is_instance_valid(title_label):
		return
	title_label.text = NereisLocalization.t("hud.title")
	controls_label.text = "A/D 移动    空格 跳跃    J 攻击    K 闪避    Q 切换武器    I 物品    M 世界路线图" if WorldState.language == "zh_cn" else NereisLocalization.t("hud.controls")
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
	get_tree().change_scene_to_file("res://scenes/regions/escape_prologue.tscn")

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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I:
		if not pause_open and not character_details_open and not WorldState.input_locked and not (world_map_overlay and world_map_overlay.visible):
			inventory_overlay.call("open_inventory")
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		if world_map_overlay and world_map_overlay.visible:
			_close_world_map()
		elif not pause_open and not character_details_open and not WorldState.input_locked:
			map_overlay_previous_input_locked = WorldState.input_locked
			world_map_overlay.call("open_map")
			WorldState.input_locked = true
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		set_debug_visible(not debug_enabled)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if world_map_overlay and world_map_overlay.visible:
			_close_world_map()
			get_viewport().set_input_as_handled()
			return
		if WorldState.input_locked and not pause_open:
			return
		_toggle_pause_menu()
		get_viewport().set_input_as_handled()

func _close_world_map() -> void:
	if world_map_overlay and world_map_overlay.visible:
		world_map_overlay.visible = false
		WorldState.input_locked = map_overlay_previous_input_locked

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
	# Boss visibility belongs to the bound encounter instance, not the legacy global combat-demo flag.
	# Boss 血条由当前绑定的遭遇实例决定，不能被旧战斗演示的全局旗标误隐藏。
	if not boss or not is_instance_valid(boss) or boss.is_queued_for_deletion() or int(boss.get("health")) <= 0:
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
	var display_name: String = str(name_variant) if name_variant != null else "灰烬骑士"
	display_name = NereisLocalization.translate_text(display_name)
	var ratio: float = clampf(float(hp) / max_health, 0.0, 1.0)
	boss_title.text = "%s  //  PHASE %d" % [display_name, phase]
	boss_bar.color = Color("#c34f5b") if phase >= 2 else Color("#9e5961")
	boss_panel.visible = true
	boss_bar.size.x = 468.0 * ratio


func show_pickup_notification(item_name: String, quantity: int = 1) -> void:
	_show_banner("获得  %s ×%d" % [item_name, quantity], 1.8)

func show_item_acquisition_error(item_name: String) -> void:
	_show_banner("%s保存失败，请重试" % item_name, 2.0)
