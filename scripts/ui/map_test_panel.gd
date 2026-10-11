extends Control
## Temporary map acceptance tools. All changes stay in memory while WorldState.debug_map_test_mode is active.
## 临时地图验收工具。开启地图测试模式后，所有调试改动只保留在内存中。

const MAPS: Array[Dictionary] = [
	{"label": "A0｜教会手术所与逃脱通道", "scene": "res://scenes/escape_prologue.tscn"},
	{"label": "A1｜边境村庄", "scene": "res://scenes/village_hub.tscn"},
	{"label": "A2｜雾林、钟墓与旧朝圣路", "scene": "res://scenes/ash_forest.tscn"},
	{"label": "A3｜废弃城区", "scene": "res://scenes/forgotten_city.tscn"},
	{"label": "A4｜下水道、沉积大厅与旧水库", "scene": "res://scenes/sewer_reservoir.tscn"},
	{"label": "A5｜旧战场与边境堡垒", "scene": "res://scenes/old_battlefield.tscn"},
	{"label": "A6｜修道院、回廊与钟塔", "scene": "res://scenes/monastery_tower.tscn"},
	{"label": "A7｜监牢、忏悔井与维护竖井", "scene": "res://scenes/prison_depths.tscn"},
	{"label": "A8｜旧王墓与王室地下道", "scene": "res://scenes/royal_tomb.tscn"},
	{"label": "A9｜王城外环与废弃街区", "scene": "res://scenes/royal_outer_ring.tscn"},
	{"label": "A10｜大圣堂、朝圣阶梯与教会内廷", "scene": "res://scenes/grand_cathedral.tscn"},
	{"label": "A11｜古神遗迹与深层研究区", "scene": "res://scenes/deep_research_depths.tscn"},
	{"label": "A12｜王室内城与王座区", "scene": "res://scenes/inner_city.tscn"},
	{"label": "H01｜井底回声层", "scene": "res://scenes/hidden_well.tscn"},
	{"label": "H02｜倒响钟室", "scene": "res://scenes/hidden_bell_chamber.tscn"},
	{"label": "H03｜被删去的第三街", "scene": "res://scenes/erased_third_street.tscn"},
	{"label": "H04｜水面背后的楼梯", "scene": "res://scenes/reflected_stairwell.tscn"},
	{"label": "H05｜无声钟室", "scene": "res://scenes/silent_bell_room.tscn"},
	{"label": "H06｜王名抹除廊", "scene": "res://scenes/erased_royal_name_corridor.tscn"},
	{"label": "H07｜镜街：雨幕背后", "scene": "res://scenes/mirror_street.tscn"},
	{"label": "H08｜胎宫／原初空腔", "scene": "res://scenes/primordial_hollow.tscn"}
]

const ALL_PATH_IDS := [
	"C04", "C05", "C06", "C07", "C10", "C12", "C15", "C16", "C18", "C19",
	"C21", "C22", "C23", "C24", "H01", "H02", "H03", "H04", "H05", "H06", "H07", "H08"
]
const ALL_ANOMALIES := [
	"anomaly_bell_retiming", "anomaly_erased_street_sign", "anomaly_old_stone_layer",
	"anomaly_mirror_street_echo", "anomaly_erased_royal_name", "anomaly_observer_reaction",
	"anomaly_old_battlefield_record", "anomaly_prisoner_transfer", "anomaly_double_sealed_relic",
	"anomaly_king_knows", "anomaly_village_well_echo"
]
const PROGRESSION_FLAGS := [
	"village_defense_survived", "reached_A5", "reached_A7", "reached_A8_via_A7",
	"reached_A9_via_A8", "reached_A10_via_A9", "reached_A12_via_A10",
	"opened_old_pilgrim_highroad", "opened_sewer_inspection_hatch_from_A4",
	"opened_watergate_and_village_well_exit", "opened_royal_tomb_gate",
	"opened_bell_tower_drop", "opened_supply_tunnel", "opened_old_lift_from_A9",
	"opened_inner_city_side_gate", "opened_royal_drain_from_outer_ring",
	"reached_A5_and_opened_old_pilgrim_highroad", "reached_A7_then_opened_supply_tunnel",
	"reached_A8_via_A7_then_opened_royal_tomb_gate", "reached_A9_via_A8_then_opened_old_lift_from_A9",
	"reached_A9_then_opened_royal_drain_from_outer_ring", "reached_A9_via_A8_then_opened_royal_transport_side_door",
	"reached_A8_then_opened_royal_tomb_side_door", "reached_A5_then_opened_old_bell_tower_connection",
	"reached_A9_then_opened_old_service_door", "discovered_royal_tomb_maintenance_shaft_after_reaching_A8",
	"discovered_and_opened_silent_side_chapel_in_A10", "ending_state_allows_deep_dream_entry",
	"ending_state_allows_throne_entry", "outer_god_resonance"
]

var panel: PanelContainer
var map_picker: OptionButton
var status_label: Label
var mode_button: Button
var natural_start_button: Button
var full_sight_button: Button
var all_routes_button: Button
var teleport_button: Button
var restore_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_panel()
	visible = false

func _build_panel() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(260, 54)
	panel.size = Vector2(760, 612)
	add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	var title := Label.new()
	title.text = "地图测试模式"
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)

	var warning := Label.new()
	warning.text = "仅用于地图验收。开启后不会写入或覆盖正式存档；关闭游戏前可恢复磁盘存档。"
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(warning)

	mode_button = _make_button("1. 开启地图测试模式（保护正式存档）")
	mode_button.pressed.connect(_enable_test_mode)
	column.add_child(mode_button)

	natural_start_button = _make_button("自然探索验收：从 A0 开始（无传送／无作弊解锁）")
	natural_start_button.pressed.connect(_start_natural_exploration)
	column.add_child(natural_start_button)

	var map_label := Label.new()
	map_label.text = "选择要直接进入的区域："
	column.add_child(map_label)

	map_picker = OptionButton.new()
	map_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for entry in MAPS:
		map_picker.add_item(str(entry["label"]))
	column.add_child(map_picker)

	teleport_button = _make_button("进入所选区域")
	teleport_button.pressed.connect(_teleport_to_selected_map)
	column.add_child(teleport_button)

	full_sight_button = _make_button("2. 灵视条件测试：鸣响与接触值拉满（不自动开门）")
	full_sight_button.pressed.connect(_apply_full_sight_profile)
	column.add_child(full_sight_button)

	all_routes_button = _make_button("3. 全地图连通测试：开启隐藏门与捷径")
	all_routes_button.pressed.connect(_apply_all_routes_profile)
	column.add_child(all_routes_button)

	restore_button = _make_button("退出测试并恢复磁盘存档")
	restore_button.pressed.connect(_restore_disk_save)
	column.add_child(restore_button)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.text = "F10：打开／关闭本面板。自然探索会重置当前内存进度并从 A0 开始，但不删除或覆盖磁盘正式存档。"
	column.add_child(status_label)

	var controls := Label.new()
	controls.text = "地图验收：A／D 移动；V 激活灵视；E 调查／开门；F3 调试信息；F10 本面板。"
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(controls)

func _make_button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		visible = not visible
		get_viewport().set_input_as_handled()

func _ensure_test_mode() -> void:
	if WorldState.debug_map_test_mode:
		return
	WorldState.debug_map_test_mode = true
	status_label.text = "地图测试模式已开启：正式存档写入已暂停。地图测试不会额外生成调试平台或敌人。"

func _enable_test_mode() -> void:
	_ensure_test_mode()
	status_label.text = "已开启地图测试模式。正式存档不会被调试状态覆盖；可直接选择区域传送。"

func _start_natural_exploration() -> void:
	# Reset only the in-memory WorldState. Enable save protection again before loading A0.
	# 只重置内存中的游戏状态；进入 A0 前重新开启存档保护，绝不删除或覆盖正式存档。
	WorldState.debug_map_test_mode = true
	WorldState.reset()
	WorldState.debug_map_test_mode = true
	WorldState.debug_ability_override_active = false
	WorldState.pending_region_spawn_side = "west"
	WorldState.resume_spawn_side = "west"
	status_label.text = "自然探索已启动：从 A0 正常开始；未解锁灵视、未开放隐藏门、未启用传送。正式存档写入保持关闭。全程不要使用区域传送或状态预设。"
	print("[NEREIS][MAP][NATURAL_TEST] Started clean in-memory run from A0; disk save protected.")
	SceneTransition.fade_to_scene("res://scenes/escape_prologue.tscn")

func _teleport_to_selected_map() -> void:
	_ensure_test_mode()
	var index := clampi(map_picker.selected, 0, MAPS.size() - 1)
	var scene_path := str(MAPS[index]["scene"])
	if not ResourceLoader.exists(scene_path):
		status_label.text = "目标场景不存在：" + scene_path
		return
	WorldState.pending_region_spawn_side = "west"
	status_label.text = "正在进入：" + str(MAPS[index]["label"])
	SceneTransition.fade_to_scene(scene_path)

func _apply_full_sight_profile() -> void:
	_ensure_test_mode()
	WorldState.hero_resonance = 100
	WorldState.ancient_exposure = 100
	WorldState.outer_exposure = 100
	WorldState.outer_god_resonance = true
	WorldState.ancient_residue_awakened = true
	WorldState.set_resonance_sight_active(false)
	for anomaly_id in ALL_ANOMALIES:
		if anomaly_id not in WorldState.resonance_sources:
			WorldState.resonance_sources.append(anomaly_id)
	for flag in PROGRESSION_FLAGS:
		if flag not in WorldState.achievement_flags:
			WorldState.achievement_flags.append(flag)
	if "resonance_sight" not in WorldState.unlocked_abilities:
		WorldState.unlocked_abilities["resonance_sight"] = {"source_type": "debug", "source_id": "map_test"}
	WorldState.refresh_resonance_reveals(false)
	status_label.text = "灵视测试条件已设置：鸣响／古神接触／外神接触均为 100，已补齐常见异常来源与主线到达标记；隐藏门仍需按 E 开启。"

func _apply_all_routes_profile() -> void:
	_apply_full_sight_profile()
	for path_id in ALL_PATH_IDS:
		if path_id not in WorldState.opened_hidden_paths:
			WorldState.opened_hidden_paths.append(path_id)
	for hidden_id in ["H01", "H02", "H03", "H04", "H05", "H06", "H07", "H08", "A11"]:
		if hidden_id not in WorldState.discovered_hidden_regions:
			WorldState.discovered_hidden_regions.append(hidden_id)
		if hidden_id not in WorldState.entered_hidden_regions:
			WorldState.entered_hidden_regions.append(hidden_id)
	status_label.text = "全地图连通测试条件已设置：常见隐藏门状态已开放。请逐条实际走过入口、回程与捷径；本预设不代表这些路线已经通过验收。"

func _restore_disk_save() -> void:
	WorldState.debug_map_test_mode = false
	WorldState.debug_ability_override_active = false
	WorldState.load_game()
	WorldState.prepare_scene_runtime()
	get_tree().change_scene_to_file("res://scenes/boot.tscn")
	visible = false
