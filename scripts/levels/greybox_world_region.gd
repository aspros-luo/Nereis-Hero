extends Node2D
## Shared playable graybox for the first connected world-map loop.
## 第一条互通地图环路的通用可玩灰盒场景。

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const INTERACTION_DOOR_SCRIPT = preload("res://scripts/world/interaction_door.gd")
const REST_POINT_SCRIPT = preload("res://scripts/world/rest_point.gd")
const RESONANCE_SOURCE_SCRIPT = preload("res://scripts/world/resonance_source_clue.gd")
const RESONANCE_SECRET_GATE_SCRIPT = preload("res://scripts/world/resonance_secret_gate.gd")
const LOCAL_RESONANCE_ROUTE_SCRIPT = preload("res://scripts/world/resonance_local_route.gd")
const ENDGAME_GATE_SCRIPT = preload("res://scripts/core/endgame_gate.gd")
const CULTIST_SCRIPT = preload("res://scripts/enemies/cultist.gd")
const PALE_HOUND_SCRIPT = preload("res://scripts/enemies/pale_hound.gd")
const BANDIT_RAIDER_SCRIPT = preload("res://scripts/enemies/bandit_raider.gd")
const RESEARCH_HUSK_SCRIPT = preload("res://scripts/enemies/research_husk.gd")
const CHURCH_INQUISITOR_SCRIPT = preload("res://scripts/enemies/church_inquisitor.gd")
const BELL_WRAITH_SCRIPT = preload("res://scripts/enemies/bell_wraith.gd")
const THIRD_CORD_FRAGMENT_SCRIPT = preload("res://scripts/world/third_cord_fragment.gd")
const REGION_AMBIENCE_SCRIPT = preload("res://scripts/effects/region_ambience.gd")

const ENCOUNTER_ACTIVATE_RANGE := 420.0
const ENCOUNTER_DEACTIVATE_RANGE := 560.0

@export var region_id: String = "A2"
@export var location_id: String = "ash_forest"
@export var region_title: String = "旧朝圣路"
@export var map_width: float = 2600.0
@export var floor_y: float = 540.0

var hero: CharacterBody2D
var camera: Camera2D
var narrative: CanvasLayer
var hud: CanvasLayer
var platforms: Array[Rect2] = []
# Debug-only route markers make every authored exit and resonance gate obvious during graybox iteration.
# 灰盒开发阶段专用的路线标记：明确显示每个实体出口与灵视入口，正式导出版本不绘制。
var debug_exit_markers: Array[Dictionary] = []
var respawning := false

func _ready() -> void:
	WorldState.prepare_scene_runtime()
	var spawn_side := WorldState.pending_region_spawn_side
	# Save the target location and its incoming side before clearing the one-shot transition value.
	# 先保存目标地图与进入侧，再清理一次性切图方向。
	WorldState.set_location(location_id)
	WorldState.pending_region_spawn_side = "west"
	if region_id == "A10":
		# Being inside the cathedral proves the main route has reached A10; this also repairs older saves.
		# 进入大圣堂本身即证明主线已抵达 A10，也可修复旧存档中的进程标记。
		WorldState.record_achievement("reached_A10_via_A9")
	elif region_id == "A12":
		# The inner city is only entered from the cathedral on the main route; persist this for H07's side gate.
		# 主线内城入口来自大圣堂；持久记录该事实，供 H07 的镜街侧门判断是否允许回程。
		WorldState.record_achievement("reached_A12_via_A10")

	_create_floor()
	_create_boundaries()
	_configure_platforms()
	_spawn_region_ambience()
	# Spawn the local bridge before the Hero so its visual is drawn behind the character.
	# 局部桥先于主角生成，确保桥体绘制在角色后方。
	_spawn_local_resonance_routes()
	_spawn_hero(_spawn_x_for_side(spawn_side), _spawn_y_for_side(spawn_side))
	print("[NEREIS][MAP][SPAWN] region=%s location=%s side=%s x=%.1f y=%.1f resume_side=%s" % [region_id, location_id, spawn_side, hero.position.x, hero.position.y, WorldState.resume_spawn_side])
	_spawn_ui()
	_spawn_region_sources()
	_spawn_region_exits()
	_register_debug_locked_route_hints()
	_spawn_region_rest_point()
	_spawn_region_encounters()
	queue_redraw()

	var intro_id := "graybox_intro_%s" % location_id
	if intro_id not in WorldState.achievement_flags:
		WorldState.record_achievement(intro_id)
		get_tree().create_timer(0.55).timeout.connect(_show_intro)

func _unhandled_input(event: InputEvent) -> void:
	if WorldState.debug_map_test_mode and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://scenes/world_map_test_menu.tscn")

func _process(_delta: float) -> void:
	# Encounters wake only when the Hero is nearby, so distant enemies do not cross the entire region.
	# 敌人只在主角接近时启动 AI，避免远处敌人横穿整张地图追击。
	if hero == null or not is_instance_valid(hero):
		return
	for child in get_children():
		if not (child is CharacterBody2D) or not child.has_meta("region_encounter"):
			continue
		if child.is_queued_for_deletion():
			continue
		var enemy := child as CharacterBody2D
		var distance := absf(hero.global_position.x - enemy.global_position.x)
		var active := bool(enemy.get_meta("encounter_active", false))
		if active and distance > ENCOUNTER_DEACTIVATE_RANGE:
			active = false
		elif not active and distance <= ENCOUNTER_ACTIVATE_RANGE:
			active = true
		if active != bool(enemy.get_meta("encounter_active", false)):
			enemy.set_meta("encounter_active", active)
			enemy.set_physics_process(active)


func _spawn_region_encounters() -> void:
	# One or two authored encounters per region; A9 stays a low-pressure transit hub.
	# 每个区域布置一至两场有意安排的遭遇；A9 保留为低压力的交通枢纽。
	match region_id:
		"A2":
			_spawn_encounter(PALE_HOUND_SCRIPT, "A2_PaleHound_01", 500.0, 14.0, 32.0)
			_spawn_encounter(CULTIST_SCRIPT, "A2_Cultist_01", 1750.0, 13.0, 38.0)
		"A3":
			_spawn_encounter(BANDIT_RAIDER_SCRIPT, "A3_Bandit_01", 350.0, 14.0, 40.0)
			_spawn_encounter(CULTIST_SCRIPT, "A3_Cultist_01", 1320.0, 13.0, 38.0)
		"A4":
			_spawn_encounter(RESEARCH_HUSK_SCRIPT, "A4_ResearchHusk_01", 700.0, 14.0, 42.0)
		"A5":
			_spawn_encounter(BANDIT_RAIDER_SCRIPT, "A5_Bandit_01", 800.0, 14.0, 40.0)
		"A6":
			if "defeated_mad_cleric" not in WorldState.achievement_flags:
				_spawn_encounter(CHURCH_INQUISITOR_SCRIPT, "A6_MadCleric_01", 850.0, 17.0, 48.0)
		"A7":
			_spawn_encounter(RESEARCH_HUSK_SCRIPT, "A7_ResearchHusk_01", 1750.0, 14.0, 42.0)
		"A8":
			_spawn_encounter(CULTIST_SCRIPT, "A8_Cultist_01", 1800.0, 13.0, 38.0)
		"A10":
			_spawn_encounter(CHURCH_INQUISITOR_SCRIPT, "A10_Inquisitor_01", 600.0, 14.0, 42.0)
			_spawn_encounter(BELL_WRAITH_SCRIPT, "A10_BellWraith_01", 1700.0, 14.0, 40.0)
		"A11":
			_spawn_encounter(RESEARCH_HUSK_SCRIPT, "A11_ResearchHusk_01", 500.0, 14.0, 42.0)
		"A12":
			_spawn_encounter(CHURCH_INQUISITOR_SCRIPT, "A12_Inquisitor_01", 900.0, 14.0, 42.0)
			_spawn_encounter(CULTIST_SCRIPT, "A12_Cultist_01", 1800.0, 13.0, 38.0)
		"H01":
			_spawn_encounter(CULTIST_SCRIPT, "H01_Cultist_01", 1200.0, 13.0, 38.0)
		"H02":
			_spawn_encounter(BELL_WRAITH_SCRIPT, "H02_BellWraith_01", 1300.0, 14.0, 40.0)
		"H03":
			_spawn_encounter(BANDIT_RAIDER_SCRIPT, "H03_Bandit_01", 1400.0, 14.0, 40.0)
		"H04":
			_spawn_encounter(PALE_HOUND_SCRIPT, "H04_PaleHound_01", 1400.0, 14.0, 32.0)
		"H05":
			_spawn_encounter(BELL_WRAITH_SCRIPT, "H05_BellWraith_01", 1300.0, 14.0, 40.0)
		"H06":
			_spawn_encounter(CHURCH_INQUISITOR_SCRIPT, "H06_Inquisitor_01", 1450.0, 14.0, 42.0)
		"H07":
			_spawn_encounter(PALE_HOUND_SCRIPT, "H07_PaleHound_01", 1400.0, 14.0, 32.0)
		"H08":
			_spawn_encounter(RESEARCH_HUSK_SCRIPT, "H08_ResearchHusk_01", 1500.0, 14.0, 42.0)
		"H09":
			if "cliff_cave_experiment_defeated" not in WorldState.achievement_flags:
				_spawn_encounter(RESEARCH_HUSK_SCRIPT, "H09_AncientExperiment", 1450.0, 20.0, 54.0)
			elif "provisional_h09_relic_collected" not in WorldState.achievement_flags:
				_spawn_cord_fragment_pickup(Vector2(1450.0, floor_y - 40.0))


func _spawn_encounter(enemy_script: Script, enemy_name: String, spawn_x: float, body_radius: float, body_height: float) -> void:
	var enemy := CharacterBody2D.new()
	enemy.set_script(enemy_script)
	enemy.name = enemy_name
	enemy.position = Vector2(spawn_x, floor_y)
	_add_character_collision(enemy, body_radius, body_height)
	enemy.set_meta("region_encounter", true)
	enemy.set_meta("encounter_active", false)
	add_child(enemy)
	if enemy.has_signal("defeated"):
		enemy.connect("defeated", _on_region_enemy_defeated.bind(enemy_name, enemy))
	if enemy_name == "A6_MadCleric_01":
		enemy.set("health", 240)
	elif enemy_name == "H09_AncientExperiment":
		enemy.set("health", 360)
	enemy.set_physics_process(false)
	print("[NEREIS][MAP][ENCOUNTER] region=%s enemy=%s x=%.1f" % [region_id, enemy_name, spawn_x])


func _on_region_enemy_defeated(enemy_name: String, enemy_node: Node2D) -> void:
	if enemy_name == "A6_MadCleric_01":
		if WorldState.record_achievement("defeated_mad_cleric") and is_instance_valid(narrative):
			narrative.show_message(
				"疯狂神职人员",
				"他倒下时，祷词仍在继续。你从他的衣襟里听见蜂群般的振翅声——不是昆虫，而是某种在石头内部移动的东西。\n\n村庄的山崖似乎回应了这声低鸣。",
				6.0
			)
	elif enemy_name == "H09_AncientExperiment":
		if WorldState.record_achievement("cliff_cave_experiment_defeated"):
			_spawn_cord_fragment_pickup(enemy_node.global_position + Vector2(0.0, -40.0))
			if is_instance_valid(narrative):
				narrative.show_message(
					"银线中仍有脉动",
					"实验体的胸腔里没有心脏，只有一件被银线缠绕、尚无法辨识的异物。它的用途与意义尚未确定。\n\n靠近后按 E 拾取；即使暂时离开，这件候选遗物仍会留在这里。",
					6.5
				)


func _spawn_cord_fragment_pickup(pickup_position: Vector2) -> void:
	if "provisional_h09_relic_collected" in WorldState.achievement_flags:
		return
	var pickup := Node2D.new()
	pickup.set_script(THIRD_CORD_FRAGMENT_SCRIPT)
	pickup.name = "ThirdUmbilicalCordFragment"
	pickup.position = pickup_position
	add_child(pickup)
	pickup.collected.connect(_on_cord_fragment_collected)


func _on_cord_fragment_collected() -> void:
	if not is_instance_valid(narrative):
		return
	narrative.show_message(
		"临时候选遗物",
		"这件遗物的材质与用途尚未确定。它只用于验证隐藏区域中的可选物品能否被拾取并持久记录；当前版本不会因此改变任何结局条件。",
		6.5
	)


func _spawn_y_for_side(side: String) -> float:
	# Elevated cross-region doors must land on their matching ledge, not underneath it on the continuous floor.
	# 高位跨区门应将主角送到对应栈台，而不是落在连续地面上、再要求玩家反向跳回门口。
	if region_id == "A2" and side == "east":
		return floor_y - 140.0
	if region_id == "A6" and side == "bell_drop":
		return floor_y - 90.0
	if region_id == "A9" and side == "old_lift":
		return floor_y - 110.0
	if region_id == "A9" and side == "royal_drain":
		return floor_y - 150.0
	if region_id == "A3" and side == "sewer":
		return floor_y - 115.0
	if region_id == "A3" and side == "old_lift":
		return floor_y - 70.0
	if region_id == "A4" and side == "prison_tunnel":
		return floor_y - 75.0
	if region_id == "A4" and side == "royal_tomb_waterway":
		return floor_y - 85.0
	if region_id == "A4" and side == "royal_drain":
		return floor_y - 120.0
	return floor_y


func _spawn_x_for_side(side: String) -> float:
	if region_id == "A6" and side == "bell_drop":
		# C10 returns to the upper landing before the final step down to the elevated shortcut door.
		# C10 回程落在高位落脚平台，再走到低一级的捷径门。
		return 2100.0
	if region_id == "A2" and side == "east":
		# Returning from A3 lands on the western approach platform below A2's elevated A3 exit.
		# 从 A3 返回时落在森林西侧的高路接近平台，与城区出口处于同一空间层。
		return 2120.0
	if region_id == "H09" and side == "east":
		return map_width - 280.0
	if region_id == "A9" and side == "mirror":
		return 1680.0
	if region_id == "A3" and side == "village_city_cut":
		# C24's return door is at x=520; balance the landing between it and the anomaly at x=900.
		# C24 回程门位于 x=520；出生点在回程门与 x=900 异常源之间保持安全距离。
		return 700.0
	if region_id == "A11" and side == "chapel_entry":
		# C19 enters from the cathedral-facing side, but must not overlap A11's return door at the east boundary.
		# C19 从大圣堂侧进入 A11，但出生点不能与 A11 东侧边界的返回门重叠。
		return map_width - 700.0
	# Far-side entrances place the Hero near, but not inside, the return door.
	# 从远侧捷径进入隐藏地图时，主角会落在出口附近，但不会与门的碰撞区重叠。
	if region_id == "H02" and side == "bell_tower_entry":
		return map_width - 360.0
	if region_id == "H03" and side == "third_street_entry":
		return map_width - 360.0
	if region_id == "H04" and side == "royal_tomb_side_entry":
		return map_width - 360.0
	if region_id == "H05" and side == "bell_drop_entry":
		return map_width - 360.0
	if region_id == "H06" and side == "royal_transport_entry":
		return map_width - 360.0
	if region_id == "A2" and side == "old_pilgrim_highroad":
		# C04's return door is at x=1880; keep the arrival outside its interaction trigger.
		# C04 回程门位于 x=1880；出生点必须避开其交互触发范围。
		return 1750.0
	if region_id == "A5" and side == "old_pilgrim_highroad":
		# C04's battlefield door is at x=520; land nearby without overlapping its trigger.
		# C04 战场侧门位于 x=520；出生在门附近，但不进入其触发区。
		return 650.0
	if region_id == "A2" and side == "bell_gate":
		# Leave the H02 entrance's interaction radius after returning from the hidden chamber.
		# 从倒响钟室返回时，出生点应离入口足够远，避免一落地就抢占 E 交互。
		return map_width - 450.0
	if region_id == "A3" and side == "third_street_gate":
		# The gate is at map_width - 300; keep the return spawn outside its 80px focus radius.
		# 第三街入口位于 map_width - 300；返回出生点必须离开其 80px 交互半径。
		return map_width - 500.0
	if region_id == "A3" and side == "bell_drop":
		# The C10 return door is at x=1710; stay outside its trigger while landing on the same route.
		# C10 回程门位于 x=1710；出生点应在同一路线附近，但避开门的触发区。
		return 1600.0
	if region_id == "A3" and side == "old_lift":
		# C16 returns to the eastern upper ledge, outside both the H05 and door interaction triggers.
		# C16 回程落在东侧高位平台，并避开 H05 与旧升降机门的交互范围。
		return 1960.0
	if region_id == "A4" and side == "water_reflection_gate":
		# Move away from H04, whose entrance is at x=1780.
		# 旧水库侧的 H04 入口位于 x=1780，返回点与其保持明显距离。
		return 1550.0
	if region_id == "A4" and side == "east":
		# H01's A4-side well gate sits near the east boundary; avoid spawning inside its 80px interaction radius.
		# A4 东侧井门靠近地图边界；返回时避开其 80px 交互范围，防止落地就重新聚焦。
		return map_width - 360.0
	if region_id == "A4" and side == "prison_tunnel":
		# C12's low ledge is at x=1050; arrive below it within one short jump of the door.
		# C12 低位栈台门位于 x=1050；出生在门下方，短跳即可抵达。
		return 1090.0
	if region_id == "A4" and side == "royal_tomb_waterway":
		# C07's middle platform door is at x=1320; land just before the platform within safe interaction range.
		# C07 中层平台门位于 x=1320；出生在平台前方，距离足以交互且能看见支路。
		return 1260.0
	if region_id == "A4" and side == "royal_drain":
		# C23's raised pipe door is at x=1650; arrive directly below its ledge, clear of H04 at x=1780.
		# C23 高位管线门位于 x=1650；出生在平台下方，并与 x=1780 的 H04 保持距离。
		return 1620.0
	if region_id == "A9" and side == "old_lift":
		# C16's upper door is at x=520; land on the same ledge without overlapping the door focus.
		# C16 高位门位于 x=520；落在同一栈台并避开门的交互焦点。
		return 610.0
	if region_id == "A9" and side == "royal_drain":
		# C23's upper door is at x=850; land on the approach ledge at x=770, outside the door focus.
		# C23 高位门位于 x=850；落在 x=770 的接近栈道，避开门的交互焦点。
		return 770.0
	if region_id == "A9" and side == "inner_city_side_gate":
		# C18 opens at x=900; land just beyond its trigger and clear of the rest point at x=1100.
		# C18 门位于 x=900；落点避开门的触发区与 x=1100 的休整点。
		return 980.0
	if region_id == "A12" and side == "inner_city_side_gate":
		# C18's inner-city door is at x=520; arrive nearby rather than at the cathedral entrance.
		# C18 内城侧门位于 x=520；返回时落在门附近，而不是大圣堂主入口。
		return 650.0
	if region_id == "A5" and side == "bell_tower":
		# H02's far-side door is at x=2060; land nearby without overlapping its trigger.
		# H02 远侧门位于 x=2060；落点靠近门，但不进入其触发区。
		return 1900.0
	if region_id == "A6" and side == "silent_window":
		# H05 sits at x=1660. Keep this arrival away from its interaction radius.
		# H05 入口位于 x=1660，返回修道院后不应立即重新聚焦该入口。
		return 1400.0
	if region_id == "A7" and side == "supply_tunnel":
		# C12's prison-side door is at x=520; return near it, away from the royal-tomb entrance at the east edge.
		# C12 监牢侧门位于 x=520；回程落在门附近，避开东侧王墓主入口。
		return 610.0
	if region_id == "A8" and side == "royal_tomb_waterway":
		# C07 returns beside its A8 door at x=520, without overlapping the door trigger.
		# C07 回到 A8 时落在 x=520 王墓水道门附近，但不进入门的触发范围。
		return 610.0
	if region_id == "A8" and side == "royal_name_gate":
		# H06 sits at x=1870; place returnees clear of the secret entrance.
		# H06 入口位于 x=1870，从王名抹除廊返回时应远离入口。
		return 1350.0
	if region_id == "A8" and side == "royal_tomb_side":
		# The side door is at x=930 and the rest point at x=1150; land in the clear corridor between them.
		# 王墓侧门位于 x=930、休整点位于 x=1150；落点选择两者之间的安全走廊。
		return 1020.0
	if region_id == "A9" and side == "third_street_service":
		# The service door now sits at x=1250; arrive beyond the anomaly source and away from the H07 gate.
		# 旧服务门移至 x=1250；回程出生点避开异常调查点与 H07 镜街入口。
		return 1600.0
	if region_id == "A9" and side == "royal_transport":
		# Land between the royal transport door (x=2200) and H07 (x=1850), clear of both interaction zones.
		# 落在王室运输门（x=2200）与 H07（x=1850）之间，避开两侧交互范围。
		return 2050.0
	if region_id == "A3" and side == "sewer":
		return 1380.0
	if region_id == "H01" and side == "east":
		# Return from A4 to the hidden well without immediately overlapping its east exit.
		# 从 A4 回到隐藏水井时，不能直接出生在东侧出口触发区内。
		return map_width - 360.0
	if side == "east":
		return map_width - 180.0
	if region_id == "H01":
		# The village entrance drops the Hero near the well shaft, not at the far edge.
		# 从村庄进入井底时，主角应出现在井道附近，而不是场景边缘。
		return 700.0
	return 180.0

func _spawn_hero(spawn_x: float, spawn_y: float = -1.0) -> void:
	hero = CharacterBody2D.new()
	hero.set_script(HERO_SCRIPT)
	hero.position = Vector2(spawn_x, floor_y if spawn_y < 0.0 else spawn_y)
	hero.name = "Hero"
	_add_character_collision(hero, 18.0, 48.0)
	add_child(hero)
	hero.defeated.connect(_on_hero_defeated)
	# Keep death recovery inside the current region instead of reusing a previous scene's checkpoint.
	# 每个灰盒区域记录自己的入口检查点，避免死亡后回到上一个场景的坐标。
	WorldState.set_checkpoint(hero.global_position)

	camera = Camera2D.new()
	camera.name = "HeroCamera"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(map_width)
	camera.limit_bottom = 720
	hero.add_child(camera)

func _spawn_ui() -> void:
	narrative = CanvasLayer.new()
	narrative.set_script(NARRATIVE_SCRIPT)
	add_child(narrative)

	hud = CanvasLayer.new()
	hud.set_script(HUD_SCRIPT)
	add_child(hud)
	hud.bind_hero(hero)
	hud.set_story_mode(_localized_region_title(), _get_objective_text())

func _localized_region_title() -> String:
	var display_name := region_title
	match region_id:
		"A0": display_name = "教会手术所与逃脱通道"
		"A1": display_name = "边境村庄"
		"A2": display_name = "雾林、钟墓与旧朝圣路"
		"A3": display_name = "被遗忘的城区"
		"A4": display_name = "下水道、沉积大厅与旧水库"
		"A5": display_name = "旧战场与边境堡垒"
		"A6": display_name = "修道院、回廊与钟塔"
		"A7": display_name = "监牢、忏悔井与维护竖井"
		"A8": display_name = "旧王墓与王室地下道"
		"A9": display_name = "王城外环与废弃街区"
		"A10": display_name = "大圣堂、朝圣阶梯与教会内廷"
		"A11": display_name = "古神遗迹与深层研究区"
		"A12": display_name = "王室内城与王座区"
		"A13": display_name = "深层梦境与终局异象"
		"H01": display_name = "井底回声层"
		"H02": display_name = "倒响钟室"
		"H03": display_name = "被删去的第三街"
		"H04": display_name = "水面背后的楼梯"
		"H05": display_name = "无声钟室"
		"H06": display_name = "王名抹除廊"
		"H07": display_name = "镜街：雨幕背后"
		"H08": display_name = "胎宫／原初空腔"
		"H09": display_name = "崖下实验窟"
	return "%s｜%s" % [region_id, display_name]

func _get_objective_text() -> String:
	match region_id:
		"A2":
			return "聆听两道回声；主路沿右侧树冠高台前往城区，地面的钟墓入口可稍后探索。"
		"A3":
			return "调查第三街；沿东侧残墙高路前往战场。"
		"A4":
			return "追寻水面之下的古老石路。"
		"A5":
			return "穿过战壕，寻找通往堡垒的道路。"
		"A6":
			return "登上修道院钟塔，寻找无声之钟。"
		"A7":
			return "深入牢房，寻找王室墓穴。"
		"A8":
			return "读一读那些被抹去的名字。"
		"H02":
			return "聆听先于声音抵达的钟。"
		"H03":
			return "沿着被城市抹去的街道前行。"
		"H04":
			return "寻找水中那段干燥的阶梯。"
		"H05":
			return "攀向那扇不投下影子的窗。"
		"H06":
			return "辨认王室石碑上被刮去的名字。"

		"A9":
			return "穿过王城外环，追随雨中的倒影。"
		"A10":
			return "登上朝圣阶梯，寻找教会内廷。"
		"A11":
			return "沿观测通道前行，墙壁记得每一位来客。"
		"H08":
			return "沿着那面沉睡的呼吸之墙前行。"
		"H09":
			return "寻找古神实验体；它的遗物可能成为抵抗外神意志的锚点。"

		"A12":
			return "进入王座区，决定什么必须覆灭。"
		"A13":
			return "沿断裂的阶梯走向终局；这里不再提供普通回程。"
		"H07":
			return "追随只存在于水中的街道。"
		"H01":
			return "寻找返回地表的道路。"
		_:
			return "调查这些不合常理的石构。"

func _show_intro() -> void:
	if not is_instance_valid(narrative):
		return
	match region_id:
		"A2":
			narrative.show_message(
				"旧朝圣路",
				"森林覆盖了道路，却没有横断道路。\n\n前方悬着一口钟，钟舌纹丝不动。",
				5.0
			)
		"A3":
			narrative.show_message(
				"被遗忘的城区",
				"街道尽头是一面本应面对另一条街的墙。\n\n褪色的路牌写着第三条道路的名字，那里却空无一物。",
				5.0
			)
		"A4":
			narrative.show_message(
				"沉积大厅",
				"新铺设的管道穿过古老石层；石头的年代远早于管道。\n\n你的脚下深处，有水正在流动。",
				5.0
			)
		"A5":
			narrative.show_message(
				"边境战场",
				"尸体倒下的方向不对。\n\n堡垒大门是从内部关闭的。",
				5.0
			)
		"A6":
			narrative.show_message(
				"仍留着钟的修道院",
				"每一口钟都有钟舌。\n\n其中一口钟没有在墙上留下影子。",
				5.0
			)
		"A7":
			narrative.show_message(
				"忏悔深井",
				"牢门向内开启。\n\n铰链上刻过的名字已被刮除。",
				5.0
			)
		"A8":
			narrative.show_message(
				"旧王墓",
				"铭文并非被风雨磨去。\n\n有人想让那些名字彻底不复存在。",
				5.0
			)
		"A9":
			narrative.show_message(
				"王城外环",
				"屋顶干燥，街道上却积着雨水。\n\n水洼中的灯亮着，头顶对应的灯却没有点燃。",
				5.0
			)
		"A10":
			narrative.show_message(
				"大圣堂",
				"你走上台阶时，唱诗声戛然而止。\n\n没有人转头看你。",
				5.0
			)
		"A11":
			narrative.show_message(
				"早于实验室的深层遗迹",
				"教会围绕某种早已存在的东西修建了这些房间。\n\n观测记录却对最先进入这里的人各执一词。",
				5.0
			)
		"H08":
			narrative.show_message(
				"实验室下方的胎宫",
				"墙壁温热，所有装置都已停止运转。\n\n石头中的某种东西，总在你呼气之前先行吐息。",
				5.0
			)
		"H09":
			narrative.show_message(
				"崖下实验窟",
				"蜂巢不是入口，而是封条。蜂蜡中混着教会的银线，洞壁上却留有远早于教会的骨质纹路。\n\n有东西在深处拖动身体，像在练习如何成为人。",
				6.0
			)
		"A12":
			narrative.show_message(
				"王室内城",
				"王宫大门敞开着。\n\n守卫却仍留在原位。",
				5.0
			)
		"A13":
			narrative.show_message(
				"终局异象",
				"这里没有旗帜，也没有祷词。\n\n阶梯的每一段都指向同一个方向，但没有两段阶梯通往同一处地方。\n\n你仍然可以向前。",
				6.0
			)
		"H07":
			narrative.show_message(
				"镜街：雨幕背后",
				"这里的雨水向天空落去。\n\n倒影总比你提前一步抵达。",
				5.0
			)
		"H01":
			narrative.show_message(
				"井底回声层",
				"这口竖井深得远超村庄老井所能容纳的尺度。\n\n你的脚步声却从头顶传回。",
				5.0
			)
		"H02":
			narrative.show_message(
				"先于声音的钟",
				"钟舌始终静止。\n\n回声却从你尚未抵达的地方回应。",
				5.0
			)
		"H03":
			narrative.show_message(
				"被城市删去的街道",
				"房屋两侧都有门。\n\n城图上却只画出其中一侧。",
				5.0
			)
		"H04":
			narrative.show_message(
				"水面背后的阶梯",
				"倒影里有一段干燥的阶梯。\n\n你的靴子无法在阶梯上方的水面留下痕迹。",
				5.0
			)
		"H05":
			narrative.show_message(
				"不投影的窗",
				"钟塔的窗外没有景色。\n\n但有人一直从里面使用这扇窗。",
				5.0
			)
		"H06":
			narrative.show_message(
				"石碑上被刮去的名字",
				"铭文并非被风雨磨损。\n\n凿痕是在墓穴封闭之后才留下的。",
				5.0
			)

func _spawn_region_ambience() -> void:
	# Add a tiny independent draw layer so ambient motion never redraws the whole level.
	# 独立绘制少量环境粒子，避免为了动态效果每帧重绘整张地图。
	var ambience := Node2D.new()
	ambience.set_script(REGION_AMBIENCE_SCRIPT)
	ambience.name = "RegionAmbience"
	ambience.set("map_width", map_width)
	ambience.set("floor_y", floor_y)
	ambience.set("region_id", region_id)
	ambience.set("atmosphere_color", _atmosphere_color())
	add_child(ambience)


func _create_floor() -> void:
	var floor := StaticBody2D.new()
	floor.name = "GreyboxGround"
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(map_width, 40.0)
	shape.shape = rectangle
	shape.position = Vector2(map_width * 0.5, floor_y + 20.0)
	floor.add_child(shape)
	add_child(floor)

func _create_boundaries() -> void:
	for x in [-20.0, map_width + 20.0]:
		var wall := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(40.0, 720.0)
		shape.shape = rectangle
		shape.position = Vector2(x, 360.0)
		wall.add_child(shape)
		add_child(wall)

func _configure_platforms() -> void:
	platforms.clear()
	match region_id:
		"A2":
			# The ground route stays readable; the canopy route is a faster, riskier line across the forest.
			# 地面主路保持清晰；树冠路线提供更快但更有风险的横穿方式。
			_add_platform(Rect2(430, 485, 105, 20))
			_add_platform(Rect2(535, 450, 110, 20))
			_add_platform(Rect2(645, 415, 130, 20))
			_add_platform(Rect2(930, 475, 180, 18))
			_add_platform(Rect2(1200, 435, 150, 18))
			_add_platform(Rect2(1500, 480, 160, 18))
			_add_platform(Rect2(1840, 445, 130, 18))
			# The eastbound route climbs back onto the canopy instead of continuing along the uninterrupted floor.
			# 向东的主路重新爬上树冠高台，不再沿着无间断的地面直线通行。
			_add_platform(Rect2(1980, 425, 120, 18))
			_add_platform(Rect2(2110, 400, 110, 18))
			_add_platform(Rect2(2220, 380, 120, 18))
			_add_platform(Rect2(760, 370, 110, 18))
			_add_platform(Rect2(870, 330, 110, 18))
			_add_platform(Rect2(1000, 360, 110, 18))
			_add_platform(Rect2(1120, 405, 110, 18))
			_add_platform(Rect2(1260, 390, 110, 18))
			_add_platform(Rect2(1380, 345, 110, 18))
			_add_platform(Rect2(1500, 310, 110, 18))
			_add_platform(Rect2(1620, 350, 110, 18))
			_add_platform(Rect2(1740, 400, 110, 18))
		"A3":
			# Street-level route: rubble, market, sewer descent, and the battlefield road.
			# 地面主路连接碎墙、市场、下水道入口与战场方向。
			_add_platform(Rect2(300, 470, 170, 18))
			_add_platform(Rect2(600, 430, 110, 18))
			_add_platform(Rect2(850, 390, 180, 18))
			_add_platform(Rect2(1190, 465, 200, 18))
			_add_platform(Rect2(1540, 425, 150, 18))
			_add_platform(Rect2(1880, 470, 170, 18))
			_add_platform(Rect2(2180, 410, 140, 18))
			# Optional rooftop loop rises above the erased third street, then descends to the sewer-side route.
			# 可选屋顶环路爬过被抹除的第三街，再下降接回下水道一侧的主路。
			_add_platform(Rect2(450, 400, 110, 18))
			_add_platform(Rect2(565, 355, 120, 18))
			_add_platform(Rect2(700, 310, 120, 18))
			_add_platform(Rect2(850, 300, 120, 18))
			_add_platform(Rect2(1000, 340, 120, 18))
			_add_platform(Rect2(1130, 390, 120, 18))
			_add_platform(Rect2(1320, 425, 130, 18))
		"A4":
			# The floor remains the safe route; a raised pipe walk is an optional way through the old stonework.
			# 地面保持安全主路；抬高的管线栈道提供穿越古老石殿的可选路线。
			_add_platform(Rect2(360, 475, 140, 18))
			_add_platform(Rect2(640, 435, 120, 18))
			_add_platform(Rect2(940, 395, 180, 18))
			# The supply-tunnel branch gets its own low ledge instead of sharing the same floor lane as the tomb and drain doors.
			# 补给隧道分支使用独立的低位平台，不再与王墓水道和王城排水门挤在同一地面线上。
			_add_platform(Rect2(930, 465, 180, 18))
			_add_platform(Rect2(1260, 455, 190, 18))
			_add_platform(Rect2(1600, 420, 150, 18))
			_add_platform(Rect2(1980, 470, 170, 18))
			_add_platform(Rect2(470, 400, 115, 18))
			_add_platform(Rect2(600, 355, 120, 18))
			_add_platform(Rect2(760, 315, 130, 18))
			_add_platform(Rect2(930, 330, 125, 18))
			_add_platform(Rect2(1090, 375, 125, 18))
			_add_platform(Rect2(1320, 400, 120, 18))
			_add_platform(Rect2(1480, 355, 120, 18))
			_add_platform(Rect2(1650, 310, 130, 18))
			_add_platform(Rect2(1810, 355, 125, 18))
		"A5":
			# The ground trench route remains open; a broken parapet line provides an optional high crossing.
			# 地面战壕主路保持开放；断裂的城墙高路提供可选的上层穿越。
			_add_platform(Rect2(280, 485, 185, 18))
			_add_platform(Rect2(560, 455, 160, 18))
			_add_platform(Rect2(850, 485, 210, 18))
			_add_platform(Rect2(1180, 450, 160, 18))
			_add_platform(Rect2(1490, 485, 175, 18))
			_add_platform(Rect2(1800, 445, 185, 18))
			_add_platform(Rect2(2150, 485, 180, 18))
			# The monastery exit leaves the battlefield from the broken upper parapet, not the ground boundary.
			# 修道院主出口从断裂的上层城墙离开战场，不再与地面边界连成直线。
			_add_platform(Rect2(2190, 450, 140, 18))
			_add_platform(Rect2(420, 420, 120, 18))
			_add_platform(Rect2(560, 375, 130, 18))
			_add_platform(Rect2(720, 335, 120, 18))
			_add_platform(Rect2(880, 370, 130, 18))
			_add_platform(Rect2(1050, 420, 120, 18))
			_add_platform(Rect2(1220, 390, 120, 18))
			_add_platform(Rect2(1390, 345, 130, 18))
			_add_platform(Rect2(1550, 390, 120, 18))
			_add_platform(Rect2(1730, 430, 110, 18))
		"A6":
			# Main stair climbs the bell tower; the side cloister balcony loops around its outer wall.
			# 主阶梯攀上钟塔；侧边回廊阳台绕塔外墙形成另一条路线。
			_add_platform(Rect2(300, 475, 155, 18))
			_add_platform(Rect2(525, 430, 125, 18))
			_add_platform(Rect2(720, 385, 125, 18))
			_add_platform(Rect2(910, 340, 130, 18))
			_add_platform(Rect2(1110, 295, 130, 18))
			_add_platform(Rect2(1320, 350, 155, 18))
			_add_platform(Rect2(1560, 405, 145, 18))
			_add_platform(Rect2(1840, 460, 160, 18))
			# The bell-tower drop is a real upper-lane branch, not another door on the floor.
			# 钟塔落差改为真正的高位支路，不再只是地面上的另一扇门。
			_add_platform(Rect2(2020, 450, 130, 18))
			_add_platform(Rect2(2150, 485, 150, 18))
			_add_platform(Rect2(1250, 270, 120, 18))
			_add_platform(Rect2(1390, 310, 120, 18))
			_add_platform(Rect2(1530, 360, 120, 18))
		"A7":
			# Cells remain traversable at ground level; the maintenance catwalk forms a zig-zag above the bars.
			# 牢房地面主路保持畅通；维修栈道在铁栏上方形成之字形路线。
			_add_platform(Rect2(300, 480, 170, 18))
			_add_platform(Rect2(585, 440, 140, 18))
			_add_platform(Rect2(850, 480, 185, 18))
			_add_platform(Rect2(1140, 435, 150, 18))
			_add_platform(Rect2(1420, 480, 190, 18))
			_add_platform(Rect2(1740, 440, 150, 18))
			_add_platform(Rect2(2040, 480, 180, 18))
			_add_platform(Rect2(440, 420, 110, 18))
			_add_platform(Rect2(560, 375, 110, 18))
			_add_platform(Rect2(700, 330, 110, 18))
			_add_platform(Rect2(850, 365, 110, 18))
			_add_platform(Rect2(1000, 410, 110, 18))
			_add_platform(Rect2(1140, 365, 110, 18))
			_add_platform(Rect2(1280, 320, 110, 18))
			_add_platform(Rect2(1420, 365, 110, 18))
			_add_platform(Rect2(1560, 410, 110, 18))
			_add_platform(Rect2(1700, 365, 110, 18))
			_add_platform(Rect2(1840, 320, 110, 18))
			_add_platform(Rect2(1980, 365, 110, 18))
		"A8":
			# The floor route passes the sarcophagi; the upper burial gallery reveals the erased royal names from above.
			# 地面路线经过石棺；上层墓廊让玩家从高处观察被抹去的王室姓名。
			_add_platform(Rect2(280, 480, 155, 18))
			_add_platform(Rect2(560, 440, 130, 18))
			_add_platform(Rect2(820, 395, 160, 18))
			_add_platform(Rect2(1100, 445, 150, 18))
			_add_platform(Rect2(1390, 395, 170, 18))
			_add_platform(Rect2(1670, 445, 150, 18))
			_add_platform(Rect2(1960, 480, 180, 18))
			_add_platform(Rect2(400, 420, 110, 18))
			_add_platform(Rect2(530, 375, 110, 18))
			_add_platform(Rect2(670, 330, 110, 18))
			_add_platform(Rect2(820, 350, 110, 18))
			_add_platform(Rect2(960, 395, 110, 18))
			_add_platform(Rect2(1100, 355, 110, 18))
			_add_platform(Rect2(1240, 310, 110, 18))
			_add_platform(Rect2(1380, 350, 110, 18))
			_add_platform(Rect2(1520, 395, 110, 18))
			_add_platform(Rect2(1660, 355, 110, 18))
			_add_platform(Rect2(1800, 310, 110, 18))
			_add_platform(Rect2(1940, 355, 110, 18))
			_add_platform(Rect2(2080, 400, 110, 18))
		"A9":
			# Street-level ring remains the safe route; the roofline creates a loop through abandoned homes.
			# 街面外环保持安全可走；屋顶路线穿过废弃民居，形成可选回环。
			_add_platform(Rect2(280, 475, 170, 18))
			_add_platform(Rect2(530, 430, 150, 18))
			_add_platform(Rect2(800, 390, 190, 18))
			_add_platform(Rect2(1110, 445, 165, 18))
			_add_platform(Rect2(1410, 405, 175, 18))
			_add_platform(Rect2(1700, 455, 175, 18))
			_add_platform(Rect2(2040, 420, 170, 18))
			# The cathedral approach climbs above the outer-ring service doors and uses two short roof steps.
			# 大圣堂入口从外环服务门上方攀过两级屋顶，避免所有连接都落在同一地面线上。
			_add_platform(Rect2(2190, 390, 140, 18))
			_add_platform(Rect2(2300, 360, 140, 18))
			_add_platform(Rect2(390, 395, 115, 18))
			_add_platform(Rect2(520, 355, 120, 18))
			_add_platform(Rect2(665, 320, 120, 18))
			# The royal drain branches from a continuous upper service ledge, separate from the street-level inner-city gate.
			# 王城排水门从连续的上层检修栈道分出，与街面内城侧门分离。
			_add_platform(Rect2(680, 390, 120, 18))
			_add_platform(Rect2(815, 340, 125, 18))
			_add_platform(Rect2(960, 385, 120, 18))
			_add_platform(Rect2(1110, 395, 120, 18))
			_add_platform(Rect2(1260, 350, 120, 18))
			_add_platform(Rect2(1400, 315, 120, 18))
			_add_platform(Rect2(1540, 350, 120, 18))
			_add_platform(Rect2(1680, 400, 120, 18))
		"A10":
			# The pilgrim stair is the direct route; side chapels and the choir gallery offer a parallel traversal.
			# 朝圣阶梯是直接主路；侧礼拜堂与唱诗席高廊提供并行路线。
			_add_platform(Rect2(260, 485, 185, 18))
			_add_platform(Rect2(520, 440, 155, 18))
			_add_platform(Rect2(760, 395, 160, 18))
			_add_platform(Rect2(1010, 350, 145, 18))
			_add_platform(Rect2(1250, 305, 145, 18))
			_add_platform(Rect2(1480, 350, 160, 18))
			_add_platform(Rect2(1730, 405, 165, 18))
			_add_platform(Rect2(2010, 455, 185, 18))
			_add_platform(Rect2(400, 405, 115, 18))
			_add_platform(Rect2(535, 365, 115, 18))
			_add_platform(Rect2(675, 325, 115, 18))
			_add_platform(Rect2(815, 290, 120, 18))
			_add_platform(Rect2(960, 310, 115, 18))
			_add_platform(Rect2(1100, 350, 115, 18))
			_add_platform(Rect2(1240, 265, 115, 18))
			_add_platform(Rect2(1380, 300, 115, 18))
			_add_platform(Rect2(1520, 340, 115, 18))
			_add_platform(Rect2(1660, 380, 115, 18))
		"A12":
			# The royal avenue remains open; the wall-walk creates a risky upper approach to the throne district.
			# 王室大道保持开放；城墙高路提供一条风险更高的王座区上层入口。
			_add_platform(Rect2(300, 475, 160, 18))
			_add_platform(Rect2(560, 430, 150, 18))
			_add_platform(Rect2(850, 385, 180, 18))
			_add_platform(Rect2(1160, 435, 170, 18))
			_add_platform(Rect2(1460, 390, 180, 18))
			_add_platform(Rect2(1770, 435, 170, 18))
			_add_platform(Rect2(2100, 475, 190, 18))
			_add_platform(Rect2(410, 405, 115, 18))
			_add_platform(Rect2(545, 365, 115, 18))
			_add_platform(Rect2(680, 325, 120, 18))
			_add_platform(Rect2(820, 345, 120, 18))
			_add_platform(Rect2(960, 390, 120, 18))
			_add_platform(Rect2(1120, 390, 120, 18))
			_add_platform(Rect2(1260, 345, 120, 18))
			_add_platform(Rect2(1400, 305, 120, 18))
			_add_platform(Rect2(1540, 340, 120, 18))
			_add_platform(Rect2(1680, 385, 120, 18))
			_add_platform(Rect2(1820, 345, 120, 18))
			_add_platform(Rect2(1960, 390, 120, 18))
		"H07":
			# The reflected avenue has a lower waterline and an upper lamp-bridge route.
			# 倒影大道同时具有低位水线与高位灯桥路线。
			_add_platform(Rect2(250, 475, 150, 18))
			_add_platform(Rect2(520, 425, 125, 18))
			_add_platform(Rect2(780, 380, 160, 18))
			_add_platform(Rect2(1060, 430, 150, 18))
			_add_platform(Rect2(1350, 385, 160, 18))
			_add_platform(Rect2(1650, 440, 150, 18))
			_add_platform(Rect2(1970, 475, 170, 18))
			_add_platform(Rect2(380, 395, 110, 18))
			_add_platform(Rect2(505, 350, 115, 18))
			_add_platform(Rect2(645, 310, 120, 18))
			_add_platform(Rect2(790, 330, 120, 18))
			_add_platform(Rect2(930, 375, 120, 18))
			_add_platform(Rect2(1060, 410, 110, 18))
			_add_platform(Rect2(1190, 385, 120, 18))
			_add_platform(Rect2(1325, 340, 120, 18))
			_add_platform(Rect2(1460, 300, 120, 18))
			_add_platform(Rect2(1600, 340, 120, 18))
		"H01":
			# The well shaft descends by ledges, then curls around a sealed echo chamber.
			# 井道以错层石沿向下，随后绕过被封住的回声室。
			_add_platform(Rect2(310, 465, 140, 18))
			_add_platform(Rect2(540, 420, 130, 18))
			_add_platform(Rect2(780, 375, 150, 18))
			_add_platform(Rect2(1040, 430, 160, 18))
			_add_platform(Rect2(1320, 475, 140, 18))
			_add_platform(Rect2(420, 390, 110, 18))
			_add_platform(Rect2(550, 345, 110, 18))
			_add_platform(Rect2(680, 305, 115, 18))
			_add_platform(Rect2(820, 325, 115, 18))
			_add_platform(Rect2(950, 370, 115, 18))
			_add_platform(Rect2(1080, 415, 115, 18))
		"A11":
			# The old ruin's observation gallery crosses above the newer laboratory floor.
			# 观测廊横跨新建实验室地面之上，强调古老遗迹与现代设施的叠压。
			_add_platform(Rect2(280, 480, 165, 18))
			_add_platform(Rect2(565, 438, 140, 18))
			_add_platform(Rect2(850, 390, 175, 18))
			_add_platform(Rect2(1150, 440, 155, 18))
			_add_platform(Rect2(1465, 385, 180, 18))
			_add_platform(Rect2(1780, 430, 150, 18))
			_add_platform(Rect2(2080, 475, 175, 18))
			_add_platform(Rect2(390, 405, 115, 18))
			_add_platform(Rect2(520, 360, 120, 18))
			_add_platform(Rect2(660, 320, 120, 18))
			_add_platform(Rect2(810, 335, 120, 18))
			_add_platform(Rect2(950, 375, 120, 18))
			_add_platform(Rect2(1090, 330, 120, 18))
			_add_platform(Rect2(1230, 285, 120, 18))
			_add_platform(Rect2(1370, 325, 120, 18))
			_add_platform(Rect2(1510, 365, 120, 18))
			_add_platform(Rect2(1660, 325, 120, 18))
			_add_platform(Rect2(1800, 285, 120, 18))
			_add_platform(Rect2(1940, 330, 120, 18))
		"H09":
			# A compact optional cave: a safe entrance shelf, a lower combat basin, and a raised relic ledge.
			# 紧凑的可选洞窟：入口安全石台、下层战斗盆地与高位遗物台形成三层空间。
			_add_platform(Rect2(260, 455, 180, 18))
			_add_platform(Rect2(620, 410, 145, 18))
			_add_platform(Rect2(990, 465, 190, 18))
			_add_platform(Rect2(1370, 420, 170, 18))
			_add_platform(Rect2(1690, 455, 180, 18))
			_add_platform(Rect2(420, 385, 120, 18))
			_add_platform(Rect2(555, 340, 120, 18))
			_add_platform(Rect2(700, 300, 135, 18))
			_add_platform(Rect2(850, 340, 120, 18))
			_add_platform(Rect2(1110, 365, 125, 18))
			_add_platform(Rect2(1260, 325, 120, 18))
			_add_platform(Rect2(1510, 350, 125, 18))
			_add_platform(Rect2(1650, 395, 120, 18))
		"H08":
			# Organic ribs spiral around the central cavity; no single straight floor line dominates.
			_add_platform(Rect2(250, 470, 150, 18))
			_add_platform(Rect2(505, 425, 135, 18))
			_add_platform(Rect2(755, 380, 160, 18))
			_add_platform(Rect2(1030, 430, 145, 18))
			_add_platform(Rect2(1290, 385, 165, 18))
			_add_platform(Rect2(1560, 440, 145, 18))
			_add_platform(Rect2(390, 385, 110, 18))
			_add_platform(Rect2(515, 340, 115, 18))
			_add_platform(Rect2(650, 300, 120, 18))
			_add_platform(Rect2(790, 320, 120, 18))
			_add_platform(Rect2(925, 365, 115, 18))
			_add_platform(Rect2(1070, 375, 115, 18))
			_add_platform(Rect2(1200, 330, 120, 18))
			_add_platform(Rect2(1340, 290, 120, 18))
			_add_platform(Rect2(1480, 335, 115, 18))
			_add_platform(Rect2(1620, 390, 115, 18))
		"H02":
			# The silent bell chamber spirals around a suspended bell, with a broken upper gallery.
			# 无声钟室围绕悬钟盘旋，上层廊道则断续残缺。
			_add_platform(Rect2(260, 475, 145, 18))
			_add_platform(Rect2(515, 430, 135, 18))
			_add_platform(Rect2(790, 385, 160, 18))
			_add_platform(Rect2(1070, 435, 145, 18))
			_add_platform(Rect2(1340, 390, 155, 18))
			_add_platform(Rect2(390, 400, 110, 18))
			_add_platform(Rect2(515, 355, 115, 18))
			_add_platform(Rect2(650, 315, 115, 18))
			_add_platform(Rect2(790, 335, 115, 18))
			_add_platform(Rect2(930, 380, 115, 18))
			_add_platform(Rect2(1070, 385, 115, 18))
		"H03":
			# The erased third street is split into visible and absent segments, with a roofline in between.
			# 被抹除的第三街分成可见与缺失的路段，中间由屋顶线连接。
			_add_platform(Rect2(250, 475, 150, 18))
			_add_platform(Rect2(515, 430, 140, 18))
			_add_platform(Rect2(780, 385, 175, 18))
			_add_platform(Rect2(1080, 445, 155, 18))
			_add_platform(Rect2(1420, 400, 170, 18))
			_add_platform(Rect2(1760, 455, 160, 18))
			_add_platform(Rect2(380, 395, 110, 18))
			_add_platform(Rect2(505, 350, 115, 18))
			_add_platform(Rect2(645, 310, 120, 18))
			_add_platform(Rect2(790, 330, 120, 18))
			_add_platform(Rect2(930, 375, 115, 18))
			_add_platform(Rect2(1070, 385, 110, 18))
			_add_platform(Rect2(1210, 395, 115, 18))
			_add_platform(Rect2(1340, 350, 115, 18))
			_add_platform(Rect2(1475, 310, 120, 18))
			_add_platform(Rect2(1615, 350, 120, 18))
		"H04":
			# Water reflection becomes a stairway that folds back over itself.
			# 水中倒影化作折返的阶梯。
			_add_platform(Rect2(250, 475, 160, 18))
			_add_platform(Rect2(530, 425, 140, 18))
			_add_platform(Rect2(810, 380, 165, 18))
			_add_platform(Rect2(1100, 435, 150, 18))
			_add_platform(Rect2(1390, 390, 170, 18))
			_add_platform(Rect2(390, 400, 110, 18))
			_add_platform(Rect2(515, 355, 115, 18))
			_add_platform(Rect2(650, 315, 115, 18))
			_add_platform(Rect2(790, 335, 115, 18))
			_add_platform(Rect2(930, 380, 115, 18))
			_add_platform(Rect2(1070, 385, 115, 18))
		"H05":
			# The upper silent-bell gallery crosses over a lower chamber with no moving shadows.
			# 无声钟上层廊道横跨一间没有移动阴影的下层房室。
			_add_platform(Rect2(280, 480, 155, 18))
			_add_platform(Rect2(560, 430, 135, 18))
			_add_platform(Rect2(840, 385, 150, 18))
			_add_platform(Rect2(1120, 340, 140, 18))
			_add_platform(Rect2(1400, 395, 155, 18))
			_add_platform(Rect2(1700, 450, 160, 18))
			_add_platform(Rect2(400, 405, 110, 18))
			_add_platform(Rect2(530, 360, 115, 18))
			_add_platform(Rect2(670, 320, 115, 18))
			_add_platform(Rect2(810, 285, 115, 18))
			_add_platform(Rect2(950, 305, 115, 18))
			_add_platform(Rect2(1090, 345, 115, 18))
			_add_platform(Rect2(1230, 390, 115, 18))
		"H06":
			# Name tablets are arranged as an interrupted procession, with an upper route past the erased names.
			# 王名石板沿中断的仪式队列排列，上层路线从被抹除的姓名上方经过。
			_add_platform(Rect2(260, 480, 160, 18))
			_add_platform(Rect2(540, 440, 140, 18))
			_add_platform(Rect2(820, 395, 165, 18))
			_add_platform(Rect2(1110, 445, 155, 18))
			_add_platform(Rect2(1420, 395, 165, 18))
			_add_platform(Rect2(1730, 450, 160, 18))
			_add_platform(Rect2(390, 405, 110, 18))
			_add_platform(Rect2(520, 360, 115, 18))
			_add_platform(Rect2(660, 320, 115, 18))
			_add_platform(Rect2(800, 340, 115, 18))
			_add_platform(Rect2(940, 385, 115, 18))
			_add_platform(Rect2(1080, 395, 115, 18))
			_add_platform(Rect2(1220, 350, 115, 18))
			_add_platform(Rect2(1360, 310, 115, 18))
			_add_platform(Rect2(1500, 350, 115, 18))
			_add_platform(Rect2(1640, 395, 115, 18))
		"A13":
			# The terminal layer uses a broken ascent that converges on the ending threshold.
			# 终局层以断裂的上升路径汇聚到结局门槛。
			_add_platform(Rect2(320, 475, 180, 18))
			_add_platform(Rect2(620, 420, 150, 18))
			_add_platform(Rect2(900, 365, 160, 18))
			_add_platform(Rect2(1210, 315, 180, 18))
			_add_platform(Rect2(1530, 355, 170, 18))
			_add_platform(Rect2(1830, 420, 180, 18))

func _add_platform(rect: Rect2) -> void:
	platforms.append(rect)
	var body := StaticBody2D.new()
	body.position = rect.position
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	shape.position = rect.size * 0.5
	# One-way ledges let the Hero jump through their undersides instead of turning every platform into a wall.
	# 单向平台允许主角从下方跳穿，避免每个平台都成为阻挡路线的墙体。
	shape.one_way_collision = true
	body.add_child(shape)
	add_child(body)

func _spawn_region_rest_point() -> void:
	# Main regions receive one deliberate rest point; hidden regions remain riskier and have no free checkpoint.
	# 主区域各有一处有意布置的休整点；隐藏区域不提供免费的安全检查点。
	var rest_x := -1.0
	var rest_name := "歇脚圣龛"
	match region_id:
		"A2":
			rest_x = 1150.0
			rest_name = "旧朝圣圣龛"
		"A3":
			rest_x = 1470.0
			rest_name = "废街圣龛"
		"A4":
			rest_x = 2050.0
			rest_name = "水库祭坛"
		"A5":
			rest_x = 1360.0
			rest_name = "战场纪念碑"
		"A6":
			rest_x = 1300.0
			rest_name = "回廊歇脚处"
		"A7":
			rest_x = 1320.0
			rest_name = "囚徒长椅"
		"A8":
			rest_x = 1150.0
			rest_name = "王室墓碑"
		"A9":
			rest_x = 1100.0
			rest_name = "外环圣龛"
		"A10":
			rest_x = 1200.0
			rest_name = "礼拜堂歇脚处"
		"A11":
			rest_x = 1050.0
			rest_name = "观测室歇脚处"
		"A12":
			rest_x = 1360.0
			rest_name = "王座区圣龛"
		_:
			return

	var rest := Node2D.new()
	rest.set_script(REST_POINT_SCRIPT)
	rest.name = "RegionRestPoint_%s" % region_id
	rest.position = Vector2(rest_x, floor_y)
	rest.rest_id = "rest_%s" % region_id
	rest.display_name = rest_name
	add_child(rest)


func _spawn_region_sources() -> void:
	match region_id:
		"A2":
			_spawn_source(
				Vector2(735, floor_y - 18.0),
				"anomaly_bell_retiming",
				"从未移动的钟",
				"钟舌垂落不动。\n\n钟声却依然响起。你掌下的石头震动了一次，随后归于沉寂。\n\n第二道脉动仍残留在你的眼后。",
				12,
				0,
				0,
				"resonance_sight"
			)
			_spawn_source(
				Vector2(1530, floor_y - 18.0),
				"anomaly_old_pilgrim_echo",
				"第二道回声",
				"你轻敲旧里程碑，回应却从身后的道路传来。\n\n石头仍然温热，仿佛有人刚刚离开。",
				18
			)
		"A3":
			_spawn_source(
				Vector2(900, floor_y - 18.0),
				"anomaly_erased_street_sign",
				"第三街",
				"路牌列出了三条街道，如今只剩两条。\n\n原本指向第三条街的地方布满刮痕。",
				28
			)
		"A4":
			_spawn_source(
				Vector2(850, floor_y - 18.0),
				"anomaly_old_stone_layer",
				"管道下的石头",
				"管道被固定在另一种工艺切削的石层上。\n\n铺设管道的工人并不是这座大厅的建造者。",
				36,
				0,
				0,
				"",
				1
			)

		"A5":
			_spawn_source(
				Vector2(1100, floor_y - 18.0),
				"anomaly_battlefield_late_orders",
				"迟于死者抵达的命令",
				"战场报告的日期比战役晚了三天。\n\n尸体早已被摆成面向堡垒的姿势，仿佛有人专为目击者修整过现场。\n\n最后一行命令幸存者将这场屠杀称为信仰的奇迹。",
				46
			)
		"A6":
			_spawn_source(
				Vector2(1125, 278),
				"anomaly_silent_bell_window",
				"无声之窗",
				"钟塔窗外没有景色。\n\n它的影子却落在一面并不存在的墙上。",
				42,
				0,
				0,
				"",
				1
			)
		"A7":
			_spawn_source(
				Vector2(1070, floor_y - 18.0),
				"anomaly_prisoner_register",
				"无名者名册",
				"账册分为姓名、判决与转送三栏。\n\n转送一栏写得满满当当，处决一栏却几乎空白。\n\n所有目的地都被写成了“观测区”。",
				52
			)
		"A8":
			_spawn_source(
				Vector2(1530, floor_y - 18.0),
				"anomaly_erased_royal_name",
				"石碑上被刮去的名字",
				"铭文并未磨损。\n\n凿痕是在石碑封存之后才留下的。",
				55,
				0,
				0,
				"",
				2
			)

		"A9":
			_spawn_source(
				Vector2(1380, floor_y - 18.0),
				"anomaly_mirror_street_echo",
				"水洼中的街道",
				"水洼倒映出一条多了一盏灯的街道。\n\n你再次清点灯火，头顶的街景却毫无变化。",
				68,
				0,
				0,
				"",
				0,
				12,
				true
			)
		"A10":
			_spawn_source(
				Vector2(700, floor_y - 18.0),
				"anomaly_double_sealed_reliquary",
				"双重封印的圣物匣",
				"教会印记覆盖在更古老的符号之上。\n\n封蜡与圣物石匣上的刻痕形状相同，官方祷文则是后来才添上的。",
				62
			)
		"A11":
			_spawn_source(
				Vector2(1450, floor_y - 18.0),
				"anomaly_observer_reaction",
				"第二位观测者",
				"记录中写着一位从未进入密室的观测者。\n\n另一行字迹来自不同的人，描述的却是你离开的情景。",
				78,
				0,
				6,
				"",
				2
			)

		"A12":
			_spawn_source(
				Vector2(1070, floor_y - 18.0),
				"anomaly_kings_unopened_letter",
				"国王未曾拆开的信",
				"这封信从未寄出。\n\n国王直言教会的实验，并请求读信者即使埋葬真相，也要保全王国。\n\n他的签名沉稳，封印却颤抖不止。",
				74
			)

		"H01":
			_spawn_source(
				Vector2(1600, floor_y - 18.0),
				"hidden_well_no_water",
				"井中无水",
				"石头是湿的，下面却没有水。\n\n潮气闻起来像是雨落在地底深处。",
				0
			)
		"H02":
			_spawn_source(
				Vector2(1650, floor_y - 18.0),
				"hidden_bell_after_sound",
				"声音之后的钟",
				"钟声停止之后，钟舌才开始摆动。\n\n金属冰冷，周围的空气却温热。",
				0
			)
		"H03":
			_spawn_source(
				Vector2(2020, floor_y - 18.0),
				"hidden_third_street_numbers",
				"编号跳过了三",
				"每一道门都按顺序编号，直到第三道。\n\n没有缺失的号码；墙体被刻意切削过，只为让编号看起来顺理成章。",
				0
			)
		"H04":
			_spawn_source(
				Vector2(1740, floor_y - 18.0),
				"hidden_stair_reflection",
				"向下攀升的阶梯",
				"石阶向下延伸，倒影中的阶梯却向上攀升。\n\n抵达平台时，两种景象同时停下，仿佛在聆听。",
				0
			)
		"H05":
			_spawn_source(
				Vector2(1960, floor_y - 18.0),
				"hidden_bell_shadowless_record",
				"无影档案",
				"档案记载钟已从塔中移走。\n\n库存清单却仍记录着它的影子，每天早晨都有人签收。",
				0
			)
		"H06":
			_spawn_source(
				Vector2(1980, floor_y - 18.0),
				"hidden_royal_name_scrape",
				"石头记得那个名字",
				"名字已被抹去，凿痕却恰好停在每个字的边界。\n\n有人细致地擦除了文字，甚至保留了它们的轮廓。",
				0
			)
		"H07":
			_spawn_source(
				Vector2(2200, floor_y - 18.0),
				"hidden_mirror_lamp_count",
				"多出来的一盏灯",
				"水中有七盏灯，街上只有六盏。\n\n当你转过身，第七盏灯已经移动到你的身后。",
				0
			)
		"H08":
			_spawn_source(
				Vector2(1850, floor_y - 18.0),
				"hidden_primordial_cradle",
				"空摇篮",
				"活石上的凹槽容不下一个人的身体，形状却精细得绝非天然形成。\n\n墙壁围绕凹槽收缩了一次，随后缓缓松弛。",
				0
			)

func _spawn_source(
	source_position: Vector2,
	source_id: String,
	display_name: String,
	description: String,
	resonance_target: int,
	ancient_delta: int = 0,
	outer_delta: int = 0,
	unlock_ability_id: String = "",
	ancient_floor: int = 0,
	outer_floor: int = 0,
	require_outer_god_resonance: bool = false
) -> void:
	var clue := Node2D.new()
	clue.set_script(RESONANCE_SOURCE_SCRIPT)
	clue.name = "Anomaly_%s" % source_id
	clue.position = source_position
	clue.source_id = source_id
	clue.display_name = display_name
	clue.description = description
	clue.resonance_target = resonance_target
	clue.ancient_exposure_delta = ancient_delta
	clue.outer_exposure_delta = outer_delta
	clue.ancient_exposure_floor = ancient_floor
	clue.outer_exposure_floor = outer_floor
	clue.require_outer_god_resonance = require_outer_god_resonance
	clue.unlock_ability_id = unlock_ability_id
	clue.unlock_source_type = "resonance"
	add_child(clue)
	clue.activated.connect(_on_source_activated.bind(source_id, unlock_ability_id))

func _on_source_activated(
	display_name: String,
	description: String,
	first_record: bool,
	source_id: String,
	unlock_ability_id: String
) -> void:
	if not first_record or not is_instance_valid(narrative):
		return
	var message := description
	if not unlock_ability_id.is_empty() and WorldState.is_ability_unlocked(unlock_ability_id):
		message += "\n\n能力觉醒：灵视。按 V 聆听异常。"
	narrative.show_message(display_name, message, 6.0)

func _register_debug_locked_route_hints() -> void:
	# Ghost markers reveal conditional shortcuts in development even before their doors are instantiated.
	# 即使条件捷径尚未生成实体门，开发构建也要显示其位置与未满足条件。
	if not OS.is_debug_build():
		return
	match region_id:
		"A2":
			_register_debug_locked_route_hint(1880.0, "old_battlefield", "旧朝圣高路需从 A5 开启")
		"A3":
			_register_debug_locked_route_hint(520.0, "village", "村庄防卫章节完成后开放")
			_register_debug_locked_route_hint(2040.0, "royal_outer_ring", "东侧高位旧升降机：需从 A9 开启")
			_register_debug_locked_route_hint(1710.0, "monastery_tower", "需先从 A6 开启钟塔落差")
			_register_debug_locked_route_hint(1870.0, "silent_bell_room", "需先发现并开启 H05")
		"A4":
			_register_debug_locked_route_hint(1050.0, "prison_depths", "低位栈台：需从 A7 开启补给隧道")
			_register_debug_locked_route_hint(1320.0, "royal_tomb", "中层平台：需从 A8 开启王墓水道")
			_register_debug_locked_route_hint(1650.0, "royal_outer_ring", "高位管线：需从 A9 开启王城排水道")
			_register_debug_locked_route_hint(map_width - 90.0, "hidden_well", "需先实际抵达 A4，再以灵视发现 H01")
		"A5":
			_register_debug_locked_route_hint(2060.0, "hidden_bell_chamber", "需先发现并开启 H02")
		"A8":
			_register_debug_locked_route_hint(930.0, "reflected_stairwell", "需先发现并开启 H04")
		"A9":
			_register_debug_locked_route_hint(900.0, "inner_city", "需从 A12 侧开启内城侧门")
			_register_debug_locked_route_hint(1250.0, "erased_third_street", "需先发现并开启 H03")
			_register_debug_locked_route_hint(2200.0, "erased_royal_name_corridor", "需先发现并开启 H06")


func _debug_route_label(target_location: String) -> String:
	var labels := {
		"church_escape": "A0 教会手术所",
		"village": "A1 边境村庄",
		"ash_forest": "A2 雾林钟墓",
		"forgotten_city": "A3 被遗忘城区",
		"sewer_reservoir": "A4 旧水库",
		"old_battlefield": "A5 旧战场",
		"monastery_tower": "A6 修道院钟塔",
		"prison_depths": "A7 监牢深处",
		"royal_tomb": "A8 旧王墓",
		"royal_outer_ring": "A9 王城外环",
		"grand_cathedral": "A10 大圣堂",
		"deep_research_depths": "A11 深层研究区",
		"inner_city": "A12 王室内城",
		"hidden_well": "H01 井底回声层",
		"hidden_bell_chamber": "H02 倒响钟室",
		"erased_third_street": "H03 被删去的第三街",
		"reflected_stairwell": "H04 水面背后的楼梯",
		"silent_bell_room": "H05 无声钟室",
		"erased_royal_name_corridor": "H06 王名抹除廊",
		"mirror_street": "H07 镜街",
		"primordial_hollow": "H08 胎宫／原初空腔",
		"cliff_cave_experiment": "H09 崖下实验窟",
		"terminal_anomaly": "A13 深层梦境与终局异象",
		"ending_fire_demo": "结局：烈火天罚",
		"ending_paradise_demo": "结局：永恒乐园"
	}
	return str(labels.get(target_location, target_location))


func _register_debug_locked_route_hint(x: float, target: String, condition: String) -> void:
	for marker in debug_exit_markers:
		var marker_position: Vector2 = marker.get("position", Vector2.ZERO)
		if is_equal_approx(marker_position.x, x) and str(marker.get("label", "")) == _debug_route_label(target):
			return
	debug_exit_markers.append({
		"position": Vector2(x, floor_y),
		"label": _debug_route_label(target),
		"kind": "locked",
		"condition": condition
	})


func _spawn_region_exits() -> void:
	match region_id:
		"A2":
			_spawn_exit_door(
				72.0, "E  返回边境村庄", "village",
				"res://scenes/village_hub.tscn", "north_gate"
			)
			# The main route to A3 sits on the eastern canopy ledge; the ground-level bell anomaly remains a separate choice.
			# 通往 A3 的主线出口位于东侧树冠高台；地面的钟墓异常入口保留为另一种探索选择。
			_spawn_exit_door(
				map_width - 360.0, "E  沿树冠高路进入被遗忘的城区", "forgotten_city",
				"res://scenes/forgotten_city.tscn", "west",
				true, "", "", floor_y - 160.0
			)
			_spawn_h02_gate(map_width - 300.0)
			# C04 is opened from A5; once opened, keep the reverse entrance persistent on A2.
			# C04 在 A5 侧开启；开启后，A2 侧永久生成对应回程门。
			if "reached_A5_and_opened_old_pilgrim_highroad" in WorldState.achievement_flags:
				_spawn_exit_door(
					1880.0, "E  返回边境战场", "old_battlefield",
					"res://scenes/old_battlefield.tscn", "old_pilgrim_highroad"
				)
		"A3":
			# C24 remains sealed on both ends until the village defense chapter is survived.
			# C24 两端都必须等到村庄防卫章节结束后才开放，避免城区侧提前绕过世界门槛。
			if "village_defense_survived" in WorldState.achievement_flags:
				_spawn_exit_door(
					520.0, "E  经旧排水道返回", "village",
					"res://scenes/village_hub.tscn", "city_cut_return"
				)
			_spawn_exit_door(
				72.0, "E  返回旧朝圣路", "ash_forest",
				"res://scenes/ash_forest.tscn", "east"
			)
			# The sewer descent branches off mid-market; the main road continues to A5.
			# 下水道入口位于市场中段，城区东侧主路继续通往 A5。
			# C05 branches off the raised pipe-walk, not the uninterrupted street floor.
			# C05 从抬高的管线栈道分出，避免地下枢纽入口与城区地面主路混为一条直线。
			_spawn_exit_door(
				1600.0, "E  沿旧管线栈道下行至水库", "sewer_reservoir",
				"res://scenes/sewer_reservoir.tscn", "west",
				true, "", "", floor_y - 115.0
			)
			# The city-to-battlefield route crosses a visible rooftop parapet, not the flat ground boundary.
			# 城区通往战场的主路经过可见的残墙高台，不再与地面右边界连成一条直线。
			_spawn_exit_door(
				map_width - 360.0, "E  沿残墙高路前往战场", "old_battlefield",
				"res://scenes/old_battlefield.tscn", "west",
				true, "", "", floor_y - 130.0
			)
			if "reached_A9_via_A8_then_opened_old_lift_from_A9" in WorldState.achievement_flags:
				# C16 returns through the elevated old lift on the far eastern rooftop, distinct from H03 and H05.
				# C16 从东侧高位旧升降机返回王城外环，与 H03、H05 分离。
				_spawn_exit_door(
					2040.0, "E  经东侧高位旧升降机返回王城外环", "royal_outer_ring",
					"res://scenes/royal_outer_ring.tscn", "old_lift",
					true, "", "", floor_y - 70.0
				)
			# Keep the erased-street gate beside its clue and away from the raised battlefield exit.
			# 被删去的第三街入口紧邻路牌线索，并与高台战场出口保持距离。
			_spawn_h03_gate(1120.0)
			if WorldState.is_hidden_path_opened("H05") and "opened_bell_tower_drop" in WorldState.achievement_flags:
				# Keep H05 between C10 and the eastern rooftop lift without overlapping either interaction focus.
				# H05 位于 C10 与东侧高位升降机之间，并与两者保持交互净空。
				_spawn_exit_door(
					1870.0, "E  返回无声之窗", "silent_bell_room",
					"res://scenes/silent_bell_room.tscn", "bell_drop_entry"
				)
			# C10 reverse door: only exists after the bell-tower drop has been opened from A6.
			# C10 反向门：必须先从 A6 开启钟塔落差，A3 才生成回程捷径。
			if "opened_bell_tower_drop" in WorldState.achievement_flags:
				_spawn_exit_door(
					1710.0, "E  返回修道院落差口", "monastery_tower",
					"res://scenes/monastery_tower.tscn", "bell_drop"
				)
			# C10's destination is the monastery tower, so the return spawn must use the drop-side mapping.
			# C10 的回程目的地是修道院塔，因此出生点必须使用钟塔落差侧的映射。
		"A4":
			_spawn_exit_door(
				72.0, "E  打开检修舱口", "forgotten_city",
				"res://scenes/forgotten_city.tscn", "sewer",
				true, "opened_sewer_inspection_hatch_from_A4", "E  返回城区"
			)
			# C06 is a one-way return shortcut from the reservoir to the village well.
			# C06 是从旧水库返回村庄的单向捷径；首次互动开闸，再次互动才转场。
			_spawn_exit_door(
				2220.0, "E  打开村庄井道水闸", "village",
				"res://scenes/village_hub.tscn", "well_exit",
				true, "opened_watergate_and_village_well_exit", "E  返回边境村庄"
			)
			_spawn_h04_gate(1780.0)
			if "reached_A7_then_opened_supply_tunnel" in WorldState.achievement_flags:
				_spawn_exit_door(
					1050.0, "E  返回监牢", "prison_depths",
					"res://scenes/prison_depths.tscn", "supply_tunnel",
					true, "", "", floor_y - 75.0
				)
			if "reached_A8_via_A7_then_opened_royal_tomb_gate" in WorldState.achievement_flags:
				_spawn_exit_door(
					1320.0, "E  返回旧王墓", "royal_tomb",
					"res://scenes/royal_tomb.tscn", "royal_tomb_waterway",
					true, "", "", floor_y - 85.0
				)
			if "reached_A9_then_opened_royal_drain_from_outer_ring" in WorldState.achievement_flags:
				_spawn_exit_door(
					1650.0, "E  返回王城外环", "royal_outer_ring",
					"res://scenes/royal_outer_ring.tscn", "royal_drain",
					true, "", "", floor_y - 105.0
				)
			if "reached_A4_via_A3" in WorldState.achievement_flags:
				_spawn_a4_hidden_well_gate(map_width - 90.0)

		"A5":
			_spawn_exit_door(
				72.0, "E  返回被遗忘的城区", "forgotten_city",
				"res://scenes/forgotten_city.tscn", "east"
			)
			_spawn_exit_door(
				2250.0, "E  沿残墙高路进入修道院", "monastery_tower",
				"res://scenes/monastery_tower.tscn", "west", true, "", "", floor_y - 90.0
			)
			if WorldState.is_hidden_path_opened("H02"):
				_spawn_exit_door(
					2060.0, "E  打开旧钟塔通路", "hidden_bell_chamber",
					"res://scenes/hidden_bell_chamber.tscn", "bell_tower_entry",
					true, "opened_old_bell_tower_connection", "E  进入倒响钟室"
				)
			# C04: open the old pilgrim highroad from the battlefield side, then traverse on the next interaction.
			# C04：从战场侧开启旧朝圣高路；首次互动开路，下一次互动才转场。
			_spawn_exit_door(
				520.0, "E  打开旧朝圣高路", "ash_forest",
				"res://scenes/ash_forest.tscn", "old_pilgrim_highroad",
				true, "reached_A5_and_opened_old_pilgrim_highroad", "E  沿旧朝圣高路返回"
			)
		"A6":
			_spawn_exit_door(
				72.0, "E  返回边境战场", "old_battlefield",
				"res://scenes/old_battlefield.tscn", "east"
			)
			_spawn_exit_door(
				map_width - 72.0, "E  深入监牢", "prison_depths",
				"res://scenes/prison_depths.tscn", "west"
			)
			_spawn_h05_gate(1660.0)
			# C10 is a physical monastery shortcut, independent of the optional H05 secret room.
			# C10 是修道院的实体捷径，不应被可选隐藏区 H05 的发现状态锁死。
			_spawn_exit_door(
				2230.0, "E  打开钟塔落差通路", "forgotten_city",
				"res://scenes/forgotten_city.tscn", "bell_drop",
				true, "opened_bell_tower_drop", "E  返回被遗忘的城区", floor_y - 55.0
			)
		"A7":
			_spawn_exit_door(
				72.0, "E  返回修道院", "monastery_tower",
				"res://scenes/monastery_tower.tscn", "east"
			)
			_spawn_exit_door(
				map_width - 72.0, "E  进入旧王墓", "royal_tomb",
				"res://scenes/royal_tomb.tscn", "west"
			)
			# C12: unlock the supply tunnel from the prison side; the first E opens it, the second traverses.
			# C12：从监牢侧开启补给隧道；第一次 E 开门，第二次 E 才转场。
			_spawn_exit_door(
				520.0, "E  打开补给隧道", "sewer_reservoir",
				"res://scenes/sewer_reservoir.tscn", "prison_tunnel",
				true, "reached_A7_then_opened_supply_tunnel", "E  沿补给隧道返回"
			)
		"A8":
			_spawn_exit_door(
				72.0, "E  返回监牢", "prison_depths",
				"res://scenes/prison_depths.tscn", "east"
			)
			_spawn_exit_door(
				map_width - 72.0, "E  进入王城外环", "royal_outer_ring",
				"res://scenes/royal_outer_ring.tscn", "west"
			)
			# C07: the royal-tomb shortcut back to the reservoir is unlocked from A8.
			# C07：旧王墓返回旧水库的捷径只能在 A8 侧开启。
			_spawn_exit_door(
				520.0, "E  打开王墓水道", "sewer_reservoir",
				"res://scenes/sewer_reservoir.tscn", "royal_tomb_waterway",
				true, "reached_A8_via_A7_then_opened_royal_tomb_gate", "E  沿王室水道返回"
			)
			_spawn_h06_gate(1870.0)
			if WorldState.is_hidden_path_opened("H04"):
				_spawn_exit_door(
					930.0, "E  打开王墓侧门", "reflected_stairwell",
					"res://scenes/reflected_stairwell.tscn", "royal_tomb_side_entry",
					true, "opened_royal_tomb_side_door", "E  进入倒影阶梯"
				)
			_spawn_a11_maintenance_gate(2310.0)

		"A9":
			_spawn_exit_door(
				72.0, "E  返回旧王墓", "royal_tomb",
				"res://scenes/royal_tomb.tscn", "east"
			)
			_spawn_exit_door(
				2350.0, "E  沿外环屋顶阶梯登上大圣堂", "grand_cathedral",
				"res://scenes/grand_cathedral.tscn", "west", true, "", "", floor_y - 180.0
			)
			if WorldState.is_hidden_path_opened("H03"):
				_spawn_exit_door(
					1250.0, "E  打开旧服务门", "erased_third_street",
					"res://scenes/erased_third_street.tscn", "third_street_entry",
					true, "opened_old_service_door", "E  进入第三街"
				)
			if WorldState.is_hidden_path_opened("H06"):
				_spawn_exit_door(
					2200.0, "E  打开王室运输侧门", "erased_royal_name_corridor",
					"res://scenes/erased_royal_name_corridor.tscn", "royal_transport_entry",
					true, "opened_royal_transport_side_door", "E  进入王名抹除廊"
				)
			_spawn_a9_mirror_gate(1850.0)
			if "reached_A12_via_A10_then_opened_inner_city_side_gate" in WorldState.achievement_flags:
				_spawn_exit_door(
					900.0, "E  返回王室内城", "inner_city",
					"res://scenes/inner_city.tscn", "inner_city_side_gate"
				)
			# C16: reconnect A9 to A3 after the old lift is opened from the outer ring.
			# C16：从王城外环开启旧升降机后，重新连通 A9 与 A3。
			_spawn_exit_door(
				520.0, "E  打开旧升降梯", "forgotten_city",
				"res://scenes/forgotten_city.tscn", "old_lift",
				true, "reached_A9_via_A8_then_opened_old_lift_from_A9", "E  乘旧升降梯返回",
				floor_y - 110.0
			)
			# C23: the royal drain is a separate A9-to-A4 shortcut.
			# C23：王城排水道是另一条 A9 至 A4 的独立捷径。
			_spawn_exit_door(
				850.0, "E  打开王城排水门", "sewer_reservoir",
				"res://scenes/sewer_reservoir.tscn", "royal_drain",
				true, "reached_A9_then_opened_royal_drain_from_outer_ring", "E  沿王城排水道返回",
				floor_y - 150.0
			)
		"A10":
			_spawn_exit_door(
				72.0, "E  返回王城外环", "royal_outer_ring",
				"res://scenes/royal_outer_ring.tscn", "east"
			)
			_spawn_exit_door(
				map_width - 72.0, "E  进入王室内城", "inner_city",
				"res://scenes/inner_city.tscn", "west"
			)
			_spawn_a11_chapel_gate(1900.0)
		"A12":
			_spawn_exit_door(
				72.0, "E  返回大圣堂", "grand_cathedral",
				"res://scenes/grand_cathedral.tscn", "east"
			)
			# C18: the inner-city side gate can only be opened after reaching A12 by the main route.
			# C18：必须先沿主线抵达 A12，才能从内城侧开启通往 A9 的侧门。
			_spawn_exit_door(
				520.0, "E  打开内城侧门", "royal_outer_ring",
				"res://scenes/royal_outer_ring.tscn", "inner_city_side_gate",
				true, "reached_A12_via_A10_then_opened_inner_city_side_gate", "E  沿侧门返回"
			)
			if (
				"reached_A12_via_A10" in WorldState.achievement_flags
				and WorldState.is_hidden_path_opened("H07")
			):
				_spawn_exit_door(
					map_width - 350.0, "E  打开镜街侧门", "mirror_street",
					"res://scenes/mirror_street.tscn", "east",
					true, "opened_mirror_street_side_gate", "E  进入镜街"
				)

			# The throne route chooses the ending from persistent story facts rather than requiring a secret map.
			# 王座区的最终路线依据持久剧情事实选择结局，不要求玩家先发现隐藏地图。
			var ending_gate := ENDGAME_GATE_SCRIPT.new()
			var ending_scene_path := str(ending_gate.call("route_candidate"))
			var ending_location := "church_final_demo"
			if ending_scene_path.ends_with("ending_paradise_demo.tscn"):
				ending_location = "ending_paradise_demo"
			elif ending_scene_path.ends_with("ending_fire_demo.tscn"):
				ending_location = "ending_fire_demo"
			# C22 now enters the real A13 terminal layer; the ending evaluator is invoked there.
			# C22 先进入真正的 A13 终局层，再由该层调用现有结局评估器。
			_spawn_exit_door(
				map_width - 72.0, "E  进入王座区", "terminal_anomaly",
				"res://scenes/terminal_anomaly.tscn", "west"
			)
		"H07":
			_spawn_exit_door(
				72.0, "E  穿过积水返回", "royal_outer_ring",
				"res://scenes/royal_outer_ring.tscn", "mirror"
			)
			if "opened_mirror_street_side_gate" in WorldState.achievement_flags:
				_spawn_exit_door(
					map_width - 72.0, "E  返回王室内城", "inner_city",
					"res://scenes/inner_city.tscn", "west"
				)

		"H01":
			_spawn_exit_door(
				72.0, "E  返回边境村庄", "village",
				"res://scenes/village_hub.tscn", "west"
			)
			var can_return_to_a4 := (
				"reached_A4_via_A3" in WorldState.achievement_flags
				and WorldState.is_hidden_path_opened("H01")
			)
			_spawn_exit_door(
				map_width - 105.0,
				"E  穿过井道闸门返回",
				"sewer_reservoir",
				"res://scenes/sewer_reservoir.tscn",
				"east",
				can_return_to_a4
			)

		"H02":
			_spawn_exit_door(
				72.0, "E  返回旧朝圣路", "ash_forest",
				"res://scenes/ash_forest.tscn", "bell_gate"
			)
			_spawn_exit_door(
				map_width - 105.0, "E  穿过钟塔返回",
				"old_battlefield", "res://scenes/old_battlefield.tscn", "bell_tower",
				"opened_old_bell_tower_connection" in WorldState.achievement_flags
			)

		"H03":
			_spawn_exit_door(
				72.0, "E  返回被遗忘的城区", "forgotten_city",
				"res://scenes/forgotten_city.tscn", "third_street_gate"
			)
			_spawn_exit_door(
				map_width - 105.0, "E  穿过旧服务门返回",
				"royal_outer_ring", "res://scenes/royal_outer_ring.tscn", "third_street_service",
				"opened_old_service_door" in WorldState.achievement_flags
			)

		"H04":
			_spawn_exit_door(
				72.0, "E  返回旧水库", "sewer_reservoir",
				"res://scenes/sewer_reservoir.tscn", "water_reflection_gate"
			)
			_spawn_exit_door(
				map_width - 105.0, "E  穿过王墓门返回",
				"royal_tomb", "res://scenes/royal_tomb.tscn", "royal_tomb_side",
				"opened_royal_tomb_side_door" in WorldState.achievement_flags
			)

		"H05":
			_spawn_exit_door(
				72.0, "E  返回修道院", "monastery_tower",
				"res://scenes/monastery_tower.tscn", "silent_window"
			)
			_spawn_exit_door(
				map_width - 105.0, "E  穿过钟塔落差通路返回",
				"forgotten_city", "res://scenes/forgotten_city.tscn", "bell_drop",
				"opened_bell_tower_drop" in WorldState.achievement_flags
			)

		"H06":
			_spawn_exit_door(
				72.0, "E  返回旧王墓", "royal_tomb",
				"res://scenes/royal_tomb.tscn", "royal_name_gate"
			)
			_spawn_exit_door(
				map_width - 105.0, "E  穿过王室运输门返回",
				"royal_outer_ring", "res://scenes/royal_outer_ring.tscn", "royal_transport",
				"opened_royal_transport_side_door" in WorldState.achievement_flags
			)

		"A11":
			var can_return_to_tomb := WorldState.is_hidden_path_opened("C15")
			var can_return_to_cathedral := "reached_A10_via_A9" in WorldState.achievement_flags
			_spawn_exit_door(
				72.0, "E  沿王室竖井返回", "royal_tomb",
				"res://scenes/royal_tomb.tscn", "east", can_return_to_tomb
			)
			_spawn_exit_door(
				map_width - 72.0, "E  返回大圣堂", "grand_cathedral",
				"res://scenes/grand_cathedral.tscn", "east", can_return_to_cathedral
			)
			_spawn_h08_gate(map_width - 300.0)
			# C21 is an optional deep-dream entrance, available only after the physical-union story fact.
			# C21 是可选的深层梦境入口，只有身体交融这一剧情事实成立后才出现。
			if WorldState.physical_union_complete:
				_spawn_exit_door(
					2050.0, "E  追随深层梦境", "terminal_anomaly",
					"res://scenes/terminal_anomaly.tscn", "west"
				)

		"H09":
			_spawn_exit_door(
				72.0, "E  返回村庄山崖", "village",
				"res://scenes/village_hub.tscn", "cliff_cave_return"
			)
		"H08":
			_spawn_exit_door(
				72.0, "E  返回深层研究区", "deep_research_depths",
				"res://scenes/deep_research_depths.tscn", "east"
			)
			if WorldState.physical_union_complete:
				# The hidden route converges on A13 instead of skipping the terminal map layer.
				# 隐藏路线汇入 A13，不再跳过终局地图层直接进入结局演示。
				_spawn_exit_door(
					map_width - 72.0, "E  追随最后的梦境", "terminal_anomaly",
					"res://scenes/terminal_anomaly.tscn", "west"
				)

		"A13":
			var ending_gate := ENDGAME_GATE_SCRIPT.new()
			var ending_scene_path := str(ending_gate.call("route_candidate"))
			var ending_location := "church_final_demo"
			if ending_scene_path.ends_with("ending_paradise_demo.tscn"):
				ending_location = "ending_paradise_demo"
			elif ending_scene_path.ends_with("ending_fire_demo.tscn"):
				ending_location = "ending_fire_demo"
			_spawn_exit_door(
				map_width - 90.0, "E  接受终局", ending_location,
				ending_scene_path, "west"
			)


func _spawn_a11_maintenance_gate(x: float) -> void:
	# The royal shaft requires proof that the Hero investigated the erased royal name.
	# 王室竖井要求主角已调查被抹去的王室姓名。
	var gate := Node2D.new()
	gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
	gate.name = "RoyalTombDeepResearchGate"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "C15"
	gate.region_record_id = "A11"
	gate.target_scene_path = "res://scenes/deep_research_depths.tscn"
	gate.target_location_id = "deep_research_depths"
	gate.target_spawn_side = "west"
	gate.required_resonance = 55
	gate.required_ancient_exposure = 2
	var required_source_ids: Array[String] = ["anomaly_bell_retiming", "anomaly_erased_royal_name"]
	gate.required_source_ids = required_source_ids
	gate.opened.connect(_on_a11_gate_opened)
	add_child(gate)
	debug_exit_markers.append({"position": gate.position, "label": "C15｜王墓深层竖井", "kind": "secret", "condition": "灵视／剧情条件"})

func _spawn_a11_chapel_gate(x: float) -> void:
	# The cathedral approach is an alternate entrance; it still requires the Mite-related outer-god fact.
	# 大圣堂是另一条入口，但仍然要求蜜忒相关的外神共鸣事实。
	var gate := Node2D.new()
	gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
	gate.name = "SilentChapelDeepResearchGate"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "C19"
	gate.region_record_id = "A11"
	gate.target_scene_path = "res://scenes/deep_research_depths.tscn"
	gate.target_location_id = "deep_research_depths"
	gate.target_spawn_side = "chapel_entry"
	gate.required_resonance = 68
	gate.required_outer_exposure = 12
	gate.require_outer_god_resonance = true
	var required_source_ids: Array[String] = ["anomaly_mirror_street_echo"]
	gate.required_source_ids = required_source_ids
	gate.opened.connect(_on_a11_gate_opened)
	add_child(gate)
	debug_exit_markers.append({"position": gate.position, "label": "C19｜静默侧堂入口", "kind": "secret", "condition": "灵视／剧情条件"})

func _on_a11_gate_opened(secret_id: String) -> void:
	if not is_instance_valid(narrative):
		return
	var title := "王名背后的竖井" if secret_id == "C15" else "静默侧堂"
	narrative.show_message(
		title,
		"石门向内开启。\n\n记录称这一深度由教会挖掘而成。积尘落在教会的工具上，而非石壁上。",
		5.0
	)

func _spawn_h08_gate(x: float) -> void:
	var gate := Node2D.new()
	gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
	gate.name = "PrimordialHollowGate"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "H08"
	gate.target_scene_path = "res://scenes/primordial_hollow.tscn"
	gate.target_location_id = "primordial_hollow"
	gate.target_spawn_side = "west"
	gate.required_resonance = 78
	gate.required_ancient_exposure = 2
	gate.required_outer_exposure = 18
	gate.require_outer_god_resonance = true
	var required_source_ids: Array[String] = [
		"anomaly_bell_retiming",
		"anomaly_erased_street_sign",
		"anomaly_old_stone_layer"
	]
	gate.required_source_ids = required_source_ids
	gate.opened.connect(_on_h08_gate_opened)
	add_child(gate)
	debug_exit_markers.append({"position": gate.position, "label": "H08｜胎宫／原初空腔", "kind": "secret", "condition": "灵视／剧情条件"})

func _on_h08_gate_opened(_secret_id: String) -> void:
	if not is_instance_valid(narrative):
		return
	narrative.show_message(
		"会呼吸的墙",
		"墙壁缓缓吐息。\n\n你无法判断这条通道是为你而建，还是它先注意到了你。",
		5.0
	)


func _spawn_a9_mirror_gate(x: float) -> void:
	var gate := Node2D.new()
	gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
	gate.name = "ResonanceMirrorStreetGate"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "H07"
	gate.target_scene_path = "res://scenes/mirror_street.tscn"
	gate.target_location_id = "mirror_street"
	gate.target_spawn_side = "west"
	gate.required_resonance = 68
	gate.required_ancient_exposure = 0
	gate.required_outer_exposure = 12
	gate.require_outer_god_resonance = true
	var required_source_ids: Array[String] = ["anomaly_mirror_street_echo"]
	gate.required_source_ids = required_source_ids
	gate.opened.connect(_on_mirror_street_gate_opened)
	add_child(gate)
	debug_exit_markers.append({"position": gate.position, "label": "H07｜镜街入口", "kind": "secret", "condition": "灵视／剧情条件"})

func _on_mirror_street_gate_opened(secret_id: String) -> void:
	if narrative == null or not is_instance_valid(narrative):
		return
	narrative.show_message(
		"被抹去的街道",
		"倒影不再追随雨水。\n\n那扇门第一次拥有了影子。",
		4.5
	)


func _spawn_local_resonance_routes() -> void:
	# Local routes reconnect familiar spaces; they do not teleport the Hero or bypass a story gate.
	# 局部鸣响路线只重连已探索的空间，不传送主角，也不绕过剧情门槛。
	var route: Node2D
	match region_id:
		"A2":
			# A canopy span reconnects the high bell-grave ledges without opening the hidden bell chamber.
			# 树冠横桥重连钟墓高台，但不会开启隐藏钟室。
			route = Node2D.new()
			route.set_script(LOCAL_RESONANCE_ROUTE_SCRIPT)
			route.name = "BellgraveCanopyCrossing"
			route.route_id = "A2_BELLGRAVE_CANOPY_CROSSING"
			route.required_resonance = 20
			route.bridge_start_x = 1380.0
			route.bridge_end_x = 1610.0
			route.bridge_y = 328.0
			route.prompt_text = "E  固定钟墓上层通路"
		"A3":
			route = Node2D.new()
			route.set_script(LOCAL_RESONANCE_ROUTE_SCRIPT)
			route.name = "ThirdStreetResonanceBridge"
			route.route_id = "A3_THIRD_STREET_ROOFLINE"
			route.required_resonance = 28
			route.bridge_start_x = 1320.0
			route.bridge_end_x = 1690.0
			route.bridge_y = 400.0
			route.prompt_text = "E  固定第三街通路"
		"A4":
			# A dry aqueduct span appears above the old reservoir only after the buried stone answers.
			# 旧水库上方的干涸渡槽只有在埋藏石层回应鸣响后才显现。
			route = Node2D.new()
			route.set_script(LOCAL_RESONANCE_ROUTE_SCRIPT)
			route.name = "OldStoneAqueductRoute"
			route.route_id = "A4_OLD_STONE_AQUEDUCT"
			route.required_resonance = 36
			route.bridge_start_x = 1650.0
			route.bridge_end_x = 1935.0
			route.bridge_y = 335.0
			route.prompt_text = "E  固定干涸渡槽"
		"A5":
			# A buried standard marks a trench crossing erased from the fortress survey.
			# 被埋没的军旗标记着堡垒测绘图中被删去的战壕横渡路线。
			route = Node2D.new()
			route.set_script(LOCAL_RESONANCE_ROUTE_SCRIPT)
			route.name = "BuriedStandardTrenchRoute"
			route.route_id = "A5_BURIED_STANDARD_CROSSING"
			route.required_resonance = 24
			route.bridge_start_x = 880.0
			route.bridge_end_x = 1220.0
			route.bridge_y = 390.0
			route.prompt_text = "E  升起被埋葬的军旗"
		"A6":
			# The silent bell's upper service walk reconnects the tower stair to the outer cloister.
			# 无声钟的高位检修道重新连接钟塔阶梯与外侧回廊。
			route = Node2D.new()
			route.set_script(LOCAL_RESONANCE_ROUTE_SCRIPT)
			route.name = "SilentBellServiceWalk"
			route.route_id = "A6_SILENT_BELL_SERVICE_WALK"
			route.required_resonance = 32
			route.bridge_start_x = 1250.0
			route.bridge_end_x = 1510.0
			route.bridge_y = 290.0
			route.prompt_text = "E  固定无声钟室通路"
		"A7":
			# A maintenance catwalk bridges two cell-block levels without opening the royal tomb gate.
			# 维修栈道横接两层牢房，但不会打开王墓主门。
			route = Node2D.new()
			route.set_script(LOCAL_RESONANCE_ROUTE_SCRIPT)
			route.name = "PrisonMaintenanceCrosswalk"
			route.route_id = "A7_PRISON_MAINTENANCE_CROSSWALK"
			route.required_resonance = 30
			route.bridge_start_x = 1280.0
			route.bridge_end_x = 1530.0
			route.bridge_y = 340.0
			route.prompt_text = "E  固定监牢维护通路"
		"A8":
			# The erased regent gallery spans the upper tomb passage, linking the name-wall ledge to the return gallery.
			# 被抹去的摄政王墓廊横跨王墓上层，连接王名墙平台与回程廊道。
			route = Node2D.new()
			route.set_script(LOCAL_RESONANCE_ROUTE_SCRIPT)
			route.name = "ErasedRegentGalleryRoute"
			route.route_id = "A8_ERASED_REGENT_GALLERY"
			route.required_resonance = 40
			route.bridge_start_x = 1240.0
			route.bridge_end_x = 1490.0
			route.bridge_y = 330.0
			route.prompt_text = "E  固定被抹除的摄政长廊"
		"A9":
			# A rain-reflection roofwalk bridges the abandoned outer-ring homes without opening the royal transport gate.
			# 雨中倒影屋顶道横接王城外环的废弃民居，但不会开启王室运输门。
			route = Node2D.new()
			route.set_script(LOCAL_RESONANCE_ROUTE_SCRIPT)
			route.name = "RainReflectionRoofwalk"
			route.route_id = "A9_RAIN_REFLECTION_ROOFWALK"
			route.required_resonance = 44
			route.bridge_start_x = 1260.0
			route.bridge_end_x = 1520.0
			route.bridge_y = 332.0
			route.prompt_text = "E  固定雨中倒影通路"
		"A10":
			# The choir gallery bridges the staggered upper chapel ledges; it does not replace the cathedral exits or C19.
			# 唱诗席高廊横接错层的礼拜堂高台，不替代大圣堂出口或 C19 深层入口。
			route = Node2D.new()
			route.set_script(LOCAL_RESONANCE_ROUTE_SCRIPT)
			route.name = "ChoirlessUpperGallery"
			route.route_id = "A10_CHOIRLESS_UPPER_GALLERY"
			route.required_resonance = 48
			route.bridge_start_x = 675.0
			route.bridge_end_x = 960.0
			route.bridge_y = 307.0
			route.prompt_text = "E  固定无唱诗班长廊"
		"A11":
			# An upper span reconnects two ancient observation ledges above the later Church laboratory.
			# 高位横桥重连后建教会实验室上方的两处古老观测台。
			route = Node2D.new()
			route.set_script(LOCAL_RESONANCE_ROUTE_SCRIPT)
			route.name = "SecondObserverSpan"
			route.route_id = "A11_SECOND_OBSERVER_SPAN"
			route.required_resonance = 56
			route.bridge_start_x = 1350.0
			route.bridge_end_x = 1800.0
			route.bridge_y = 285.0
			route.prompt_text = "E  固定观测者桥廊"
		"A12":
			# The crown wall offers a risky upper traverse but leaves the throne approach and ending gate untouched.
			# 王冠城墙提供高风险上层横道，但不改变王座入口与结局门槛。
			route = Node2D.new()
			route.set_script(LOCAL_RESONANCE_ROUTE_SCRIPT)
			route.name = "CrownWallWalk"
			route.route_id = "A12_CROWN_WALL_WALK"
			route.required_resonance = 62
			route.bridge_start_x = 1400.0
			route.bridge_end_x = 1940.0
			route.bridge_y = 323.0
			route.prompt_text = "E  固定王冠城墙通路"
		_:
			return
	route.opened.connect(_on_local_resonance_route_opened)
	add_child(route)

func _on_local_resonance_route_opened(route_id: String) -> void:
	if not is_instance_valid(narrative):
		return
	match route_id:
		"A2_BELLGRAVE_CANOPY_CROSSING":
			narrative.show_message(
				"钟的第二道影子",
				"这条树冠通路横跨一段被森林测绘图标记为完整岩层的空隙。上方的钟投下两道影子：一道落在塔上，另一道落在一条并不存在的道路上。第二道影子止于一扇封闭的门前。",
				5.0
			)
		"A4_OLD_STONE_AQUEDUCT":
			narrative.show_message(
				"无水渡槽",
				"管道止于一条比水库更古老的石渠。桥面落定时，封闭的岩层中竟传来水流向上涌动的声音。\n\n这条石渠仍记得一条早已消失的河流。",
				5.0
			)
		"A5_BURIED_STANDARD_CROSSING":
			narrative.show_message(
				"比军队存续更久的军旗",
				"旗布早已腐烂，影子却仍横越战壕。堡垒地图将此处标为绝对不可通行。那些死者曾奉命守住一条后来被教会从所有记录中抹去的道路。",
				5.0
			)
		"A6_SILENT_BELL_SERVICE_WALK":
			narrative.show_message(
				"无声之钟的维护通道",
				"上层通道留有新鲜的维修痕迹，上方的钟却从未移动。维修账册中记载了一位钟手，而他的出生年份竟比修道院封闭晚了数十年。",
				5.0
			)
		"A7_PRISON_MAINTENANCE_CROSSWALK":
			narrative.show_message(
				"没有编号牢房之间的通路",
				"维护账册记录了每一枚铰链与每一道排水口，却唯独不给牢房编号。一条维修记录命令工人保留下层牢门，并从外部封死上层牢门。那些名字并非偶然遗漏。",
				5.0
			)
		"A8_ERASED_REGENT_GALLERY":
			narrative.show_message(
				"从未执政的摄政者",
				"这条长廊连接两处墓台，却不经过封闭的王室大门。一块石碑记载着摄政者，另一侧墙上对应的凹槽却已被凿去。王墓并非为了遗忘某位国王而建；它被改造过，好让王位继承的真相无法辨读。",
				5.0
			)
		"A9_RAIN_REFLECTION_ROOFWALK":
			narrative.show_message(
				"雨水记得的家园",
				"屋顶通路越过一排从街道侧封死门窗的房屋。雨水倒影中，空置多年的屋檐下却亮着温暖的窗。旧城的人并非一夜之间消失；有人教会了档案把他们称作从未出生。",
				5.0
			)
		"A10_CHOIRLESS_UPPER_GALLERY":
			narrative.show_message(
				"从未被记录的唱诗班",
				"长廊俯瞰大圣堂的唱诗席，下方却没有任何声音传来。地面被磨得光滑，尘土勾勒出一排跪姿人形。礼仪账册记录了每一首圣歌与每一口钟，却唯独没有记下曾在此歌唱之人的名字。",
				5.0
			)
		"A11_SECOND_OBSERVER_SPAN":
			narrative.show_message(
				"没有留下脚印的观测者",
				"古老的石台在实验室最新的仪器上方交汇。一块观测板记载着两道影子进入密室，却只有一具身体离开。后来有人将这个数字改写成了光线误差。",
				5.0
			)
		"A12_CROWN_WALL_WALK":
			narrative.show_message(
				"为国王的缺席而建的墙",
				"这道高墙是为了监视大道，而非抵御外敌。箭孔全部朝向内侧。王宫更害怕有东西从王座厅离开，而不是有什么东西靠近。",
				5.0
			)
		_:
			narrative.show_message(
				"第三街仍然存在",
				"A bridge appears where the city map was scraped clean. The road does not lead to another place; it reconnects two parts of the street you already knew.\n\nThe stone will remember this route.",
				5.0
			)
	print("[NEREIS][MAP][LOCAL_ROUTE] opened id=%s" % route_id)

func _spawn_h02_gate(x: float) -> void:
	var gate := Node2D.new()
	gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
	gate.name = "HiddenBellChamberGate"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "H02"
	gate.target_scene_path = "res://scenes/hidden_bell_chamber.tscn"
	gate.target_location_id = "hidden_bell_chamber"
	gate.target_spawn_side = "west"
	gate.required_resonance = 18
	gate.opened.connect(_on_optional_hidden_gate_opened)
	add_child(gate)
	debug_exit_markers.append({"position": gate.position, "label": "H02 倒响钟室", "kind": "secret", "condition": "灵视／进度条件"})

func _spawn_h03_gate(x: float) -> void:
	var gate := Node2D.new()
	gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
	gate.name = "ErasedThirdStreetGate"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "H03"
	gate.target_scene_path = "res://scenes/erased_third_street.tscn"
	gate.target_location_id = "erased_third_street"
	gate.target_spawn_side = "west"
	gate.required_resonance = 28
	gate.opened.connect(_on_optional_hidden_gate_opened)
	add_child(gate)
	debug_exit_markers.append({"position": gate.position, "label": "H03 被删去的第三街", "kind": "secret", "condition": "灵视／进度条件"})

func _spawn_h04_gate(x: float) -> void:
	var gate := Node2D.new()
	gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
	gate.name = "ReflectedStairwellGate"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "H04"
	gate.target_scene_path = "res://scenes/reflected_stairwell.tscn"
	gate.target_location_id = "reflected_stairwell"
	gate.target_spawn_side = "west"
	gate.required_resonance = 36
	gate.required_ancient_exposure = 1
	gate.opened.connect(_on_optional_hidden_gate_opened)
	add_child(gate)
	debug_exit_markers.append({"position": gate.position, "label": "H04 水面背后的楼梯", "kind": "secret", "condition": "灵视／进度条件"})

func _spawn_h05_gate(x: float) -> void:
	var gate := Node2D.new()
	gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
	gate.name = "SilentBellRoomGate"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "H05"
	gate.target_scene_path = "res://scenes/silent_bell_room.tscn"
	gate.target_location_id = "silent_bell_room"
	gate.target_spawn_side = "west"
	gate.required_resonance = 42
	gate.required_ancient_exposure = 1
	gate.opened.connect(_on_optional_hidden_gate_opened)
	add_child(gate)
	debug_exit_markers.append({"position": gate.position, "label": "H05 无声钟室", "kind": "secret", "condition": "灵视／进度条件"})

func _spawn_h06_gate(x: float) -> void:
	var gate := Node2D.new()
	gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
	gate.name = "ErasedRoyalNameGate"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "H06"
	gate.target_scene_path = "res://scenes/erased_royal_name_corridor.tscn"
	gate.target_location_id = "erased_royal_name_corridor"
	gate.target_spawn_side = "west"
	gate.required_resonance = 55
	gate.required_ancient_exposure = 2
	# The royal-name corridor requires the actual royal inscription clue, not the unrelated third-street clue.
	# 王名抹除廊要求调查王室石碑本身，而不是城区第三街的无关线索。
	var required_source_ids: Array[String] = ["anomaly_bell_retiming", "anomaly_erased_royal_name"]
	gate.required_source_ids = required_source_ids
	gate.opened.connect(_on_optional_hidden_gate_opened)
	add_child(gate)
	debug_exit_markers.append({"position": gate.position, "label": "H06 王名抹除廊", "kind": "secret", "condition": "灵视／进度条件"})

func _on_optional_hidden_gate_opened(secret_id: String) -> void:
	if not is_instance_valid(narrative):
		return
	var details := {
		"H02": ["先于声音的钟", "钟舌始终静止。\n\n回声却从你尚未抵达的地方回应。"],
		"H03": ["被城市删去的街道", "房屋两侧都有门。\n\n城图上却只画出其中一侧。"],
		"H04": ["水面背后的阶梯", "倒影里有一段干燥的阶梯。\n\n你的靴子无法在阶梯上方的水面留下痕迹。"],
		"H05": ["不投影的窗", "钟塔的窗外没有景色。\n\n但有人一直从里面使用这扇窗。"],
		"H06": ["石碑上被刮去的名字", "铭文并非被风雨磨损。\n\n凿痕是在墓穴封闭之后才留下的。"]
	}
	var entry: Array = details.get(secret_id, ["异常的石构", "墙壁没有移动，却向你敞开。"])
	narrative.show_message(str(entry[0]), str(entry[1]), 5.0)

func _spawn_a4_hidden_well_gate(x: float) -> void:
	# This is the far-side entrance to H01, not a bypass: it still requires active Resonance Sight.
	# A4 另一侧井门也使用同一 H01 状态，但首次发现仍必须通过灵视条件。
	var gate := Node2D.new()
	gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
	gate.name = "ResonanceWellGateFromA4"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "H01"
	gate.target_scene_path = "res://scenes/hidden_well.tscn"
	gate.target_location_id = "hidden_well"
	gate.target_spawn_side = "east"
	gate.required_resonance = 12
	gate.required_ancient_exposure = 0
	gate.required_outer_exposure = 0
	gate.opened.connect(_on_hidden_well_gate_opened)
	add_child(gate)
	debug_exit_markers.append({"position": gate.position, "label": "H01 井底回声层", "kind": "secret", "condition": "灵视／进度条件"})

func _on_hidden_well_gate_opened(secret_id: String) -> void:
	if narrative == null or not is_instance_valid(narrative):
		return
	narrative.show_message(
		"井还有另一个出口",
		"石门没有转动，却自行开启。\n\n你已无法分辨哪一侧才是上方。",
		4.0
	)

func _spawn_exit_door(
	x: float,
	prompt_text: String,
	target_location: String,
	target_scene: String,
	spawn_side: String,
	enabled: bool = true,
	unlock_once_flag_id: String = "",
	opened_prompt_text: String = "",
	door_y: float = -1.0
) -> void:
	var door := Area2D.new()
	door.set_script(INTERACTION_DOOR_SCRIPT)
	door.name = "Exit_%s" % target_location
	door.position = Vector2(x, floor_y if door_y < 0.0 else door_y)
	door.prompt_text = prompt_text
	door.enabled = enabled
	door.unlock_once_flag_id = unlock_once_flag_id
	door.opened_prompt_text = opened_prompt_text

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	# Keep the interaction volume aligned to the visible doorway. The old 138px
	# trigger reached the continuous floor even when the door was on an upper ledge.
	# 交互触发区应贴合可见门洞；旧版 138px 高的触发体会延伸到地面，使高位出口可被绕过。
	rectangle.size = Vector2(110.0, 80.0)
	shape.shape = rectangle
	shape.position = Vector2(0.0, -35.0)
	door.add_child(shape)
	add_child(door)
	debug_exit_markers.append({
		"position": door.position,
		"label": _debug_route_label(target_location),
		"kind": "locked" if not enabled else ("shortcut" if not unlock_once_flag_id.is_empty() else "exit"),
		"condition": unlock_once_flag_id if not unlock_once_flag_id.is_empty() else ("需从另一侧开启" if not enabled else "")
	})
	door.interacted.connect(_on_exit_interacted.bind(target_location, target_scene, spawn_side))

func _draw_debug_exit_markers() -> void:
	for marker in debug_exit_markers:
		var marker_position: Vector2 = marker.get("position", Vector2.ZERO)
		var marker_kind := str(marker.get("kind", "exit"))
		var marker_color := Color("#8bd5ca")
		if marker_kind == "shortcut":
			marker_color = Color("#f0c674")
		elif marker_kind == "secret":
			marker_color = Color("#c6a0f6")
		elif marker_kind == "locked":
			marker_color = Color("#ed8796")
		var marker_top := marker_position + Vector2(0.0, -118.0)
		draw_line(marker_position + Vector2(0.0, -8.0), marker_top, marker_color, 3.0, true)
		draw_line(marker_top + Vector2(-12.0, 12.0), marker_top, marker_color, 3.0)
		draw_line(marker_top + Vector2(12.0, 12.0), marker_top, marker_color, 3.0)
		var marker_label := "[出口] "
		if marker_kind == "shortcut":
			marker_label = "[捷径] "
		elif marker_kind == "secret":
			marker_label = "[灵视入口] "
		elif marker_kind == "locked":
			marker_label = "[条件未满足] "
		marker_label += str(marker.get("label", "unknown"))
		var condition := str(marker.get("condition", ""))
		var label_offset := Vector2(14.0, -4.0)
		if marker_position.x > map_width - 420.0:
			label_offset = Vector2(-320.0, -4.0)
		draw_string(ThemeDB.fallback_font, marker_top + label_offset, marker_label, HORIZONTAL_ALIGNMENT_LEFT, 320.0, 13, marker_color)
		if not condition.is_empty():
			draw_string(ThemeDB.fallback_font, marker_top + label_offset + Vector2(0.0, 15.0), condition, HORIZONTAL_ALIGNMENT_LEFT, 320.0, 10, marker_color)

func _on_exit_interacted(target_location: String, target_scene: String, spawn_side: String) -> void:
	if region_id == "A3" and target_location == "sewer_reservoir":
		WorldState.record_achievement("reached_A4_via_A3")
	if target_location == "village" and "defeated_mad_cleric" in WorldState.achievement_flags:
		WorldState.record_achievement("returned_to_village_after_mad_cleric")
	if target_location == "hidden_well":
		WorldState.discover_hidden_region("H01")
		WorldState.open_hidden_path("H01")
		WorldState.mark_hidden_region_entered("H01")
	if target_location == "inner_city" and region_id == "A10":
		WorldState.record_achievement("reached_A12_via_A10")
	if target_location == "mirror_street":
		WorldState.mark_hidden_region_entered("H07")
	elif target_location == "sewer_reservoir" and region_id == "H01":
		WorldState.mark_hidden_region_entered("H01")

	# Re-entry through a far-side shortcut must update the same persistent region record.
	# 从远侧捷径再次进入时，仍需更新同一个隐藏区域的持久记录。
	match target_location:
		"hidden_bell_chamber":
			WorldState.discover_hidden_region("H02")
			WorldState.mark_hidden_region_entered("H02")
		"erased_third_street":
			WorldState.discover_hidden_region("H03")
			WorldState.mark_hidden_region_entered("H03")
		"reflected_stairwell":
			WorldState.discover_hidden_region("H04")
			WorldState.mark_hidden_region_entered("H04")
		"silent_bell_room":
			WorldState.discover_hidden_region("H05")
			WorldState.mark_hidden_region_entered("H05")
		"erased_royal_name_corridor":
			WorldState.discover_hidden_region("H06")
			WorldState.mark_hidden_region_entered("H06")

	WorldState.pending_region_spawn_side = spawn_side
	WorldState.set_location(target_location)
	print("[NEREIS][MAP][EXIT] from=%s to=%s location=%s spawn_side=%s" % [region_id, target_scene, target_location, spawn_side])
	SceneTransition.fade_to_scene(target_scene)

func _on_hero_defeated() -> void:
	if respawning:
		return
	respawning = true
	await get_tree().create_timer(0.75).timeout
	if is_instance_valid(hero):
		hero.velocity = Vector2.ZERO
		hero.global_position = WorldState.checkpoint_position
		if hero.has_method("restore_full"):
			hero.call("restore_full")
	WorldState.input_locked = false
	respawning = false

func _add_character_collision(character: CharacterBody2D, radius: float, height: float) -> void:
	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = radius
	capsule.height = height
	collision.shape = capsule
	collision.position = Vector2(0, -height * 0.5)
	character.add_child(collision)

func _draw() -> void:
	var background := _background_color()
	draw_rect(Rect2(0.0, 0.0, map_width, 720.0), background)
	_draw_atmospheric_layers()
	draw_rect(Rect2(0.0, floor_y, map_width, 180.0), Color("#211b23"))
	_draw_ground_detail()

	# Replace the old repetitive ground slashes with sparse, broken stone cracks and low atmospheric haze.
	# 将重复的地面斜线改为稀疏断裂石纹与贴地薄雾，降低灰盒画面的噪声感。
	var atmosphere := _atmosphere_color()
	draw_rect(Rect2(0.0, floor_y - 92.0, map_width, 44.0), Color(atmosphere.r, atmosphere.g, atmosphere.b, 0.045))
	draw_rect(Rect2(0.0, floor_y - 36.0, map_width, 20.0), Color(atmosphere.r, atmosphere.g, atmosphere.b, 0.025))
	for x in range(28, int(map_width), 128):
		draw_line(Vector2(x, floor_y + 10.0), Vector2(x + 13.0, floor_y + 17.0), Color("#302a31", 0.72), 1.0)
		if x % 384 == 28:
			draw_line(Vector2(x + 13.0, floor_y + 17.0), Vector2(x + 21.0, floor_y + 11.0), Color("#302a31", 0.58), 1.0)
	for mote in range(22):
		var mote_x := float((mote * 173 + int(region_id.hash() % 113)) % int(map_width))
		var mote_y := 235.0 + float((mote * 67) % 185)
		draw_circle(Vector2(mote_x, mote_y), 1.2 if mote % 4 != 0 else 1.8, Color(atmosphere.r, atmosphere.g, atmosphere.b, 0.22))

	match region_id:
		"A2":
			_draw_forest_landmarks()
		"A3":
			_draw_city_landmarks()
		"A4":
			_draw_reservoir_landmarks()
		"A5":
			_draw_battlefield_landmarks()
		"A6":
			_draw_monastery_landmarks()
		"A7":
			_draw_prison_landmarks()
		"A8":
			_draw_royal_tomb_landmarks()
		"A11":
			_draw_deep_research_landmarks()

		"A9":
			_draw_outer_ring_landmarks()
		"A10":
			_draw_cathedral_landmarks()
		"A12":
			_draw_inner_city_landmarks()
		"H07":
			_draw_mirror_street_landmarks()

		"H01":
			_draw_well_landmarks()
		"H02":
			_draw_hidden_bell_chamber_landmarks()
		"H03":
			_draw_erased_third_street_landmarks()
		"H04":
			_draw_reflected_stairwell_landmarks()
		"H05":
			_draw_silent_bell_room_landmarks()
		"H06":
			_draw_erased_royal_name_landmarks()
		"H08":
			_draw_primordial_hollow_landmarks()
		"H09":
			_draw_cliff_cave_landmarks()

	for platform in platforms:
		# Thin bevelled ledges stay readable without visually filling the screen with solid blocks.
		# 以薄平台与边缘高光表现可站立面，避免画面被厚重方块填满。
		draw_rect(Rect2(platform.position + Vector2(0.0, 3.0), Vector2(platform.size.x, 9.0)), _platform_color())
		draw_line(platform.position, Vector2(platform.end.x, platform.position.y), Color("#9a8178", 0.82), 2.0)
		draw_line(platform.position + Vector2(2.0, 12.0), Vector2(platform.end.x - 2.0, platform.position.y + 12.0), Color("#1b171f", 0.75), 2.0)

	if OS.is_debug_build():
		_draw_debug_exit_markers()

	draw_string(
		ThemeDB.fallback_font,
		Vector2(88.0, 190.0),
		region_title,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		28,
		Color("#b7a48c")
	)

# A restrained second silhouette layer gives each region depth without external textures.
# 克制的第二层剪影为各区域增加纵深，不依赖外部贴图。
func _draw_atmospheric_layers() -> void:
	var atmosphere := _atmosphere_color()
	var silhouette := Color(atmosphere.r * 0.52, atmosphere.g * 0.52, atmosphere.b * 0.58, 0.34)
	var silhouette_edge := Color(atmosphere.r, atmosphere.g, atmosphere.b, 0.20)
	var seed_offset := int(region_id.hash() % 97)

	# Distant haze bands are broad and low contrast so the playable platforms remain legible.
	# 远景雾带保持宽而淡，不与可站立平台争夺视觉焦点。
	for band in range(3):
		var band_y := 300.0 + float(band) * 62.0
		var band_alpha := 0.018 + float(band) * 0.009
		draw_rect(Rect2(0.0, band_y, map_width, 24.0), Color(atmosphere.r, atmosphere.g, atmosphere.b, band_alpha))

	for index in range(9):
		var x := float(index) * 315.0 - 50.0 + float(seed_offset)
		var width := 150.0 + float((index * 47 + seed_offset) % 95)
		var height := 72.0 + float((index * 31 + seed_offset) % 112)
		var base_y := floor_y - 12.0
		match region_id:
			"A2", "H01", "H08", "H09":
				# Broken tree crowns or organic ribs, never a repeated flat skyline.
				var crown := PackedVector2Array([
					Vector2(x, base_y), Vector2(x + width * 0.18, base_y - height * 0.58),
					Vector2(x + width * 0.31, base_y - height), Vector2(x + width * 0.46, base_y - height * 0.48),
					Vector2(x + width * 0.65, base_y - height * 0.82), Vector2(x + width, base_y)
				])
				draw_colored_polygon(crown, silhouette)
				draw_line(Vector2(x + width * 0.48, base_y), Vector2(x + width * 0.47, base_y - height * 0.52), silhouette_edge, 2.0)
			"A4", "H04", "H07":
				# Reservoir arches and reflected city ribs.
				draw_rect(Rect2(x, base_y - height, width, height), Color(silhouette.r, silhouette.g, silhouette.b, 0.12))
				draw_arc(Vector2(x + width * 0.5, base_y - height * 0.30), width * 0.42, PI, TAU, 20, silhouette_edge, 3.0)
				draw_line(Vector2(x, base_y - height * 0.18), Vector2(x, base_y), silhouette_edge, 2.0)
				draw_line(Vector2(x + width, base_y - height * 0.18), Vector2(x + width, base_y), silhouette_edge, 2.0)
			"A5":
				# Uneven fortress battlements suggest a defensive line already breached.
				draw_rect(Rect2(x, base_y - height * 0.68, width, height * 0.68), silhouette)
				for merlon in range(3):
					draw_rect(Rect2(x + float(merlon) * width / 3.0, base_y - height, width / 5.0, height * 0.34), silhouette)
			"A6", "A10", "A12":
				# Gothic towers and lancet arches establish a sacred architectural family.
				draw_rect(Rect2(x + width * 0.30, base_y - height, width * 0.40, height), silhouette)
				draw_colored_polygon(PackedVector2Array([
					Vector2(x + width * 0.18, base_y - height),
					Vector2(x + width * 0.50, base_y - height - 42.0),
					Vector2(x + width * 0.82, base_y - height)
				]), silhouette)
				draw_arc(Vector2(x + width * 0.50, base_y - height * 0.42), width * 0.15, PI, TAU, 16, silhouette_edge, 2.0)
			"A3", "A9", "H03", "H06":
				# Roofs, broken lintels, and missing upper storeys.
				draw_rect(Rect2(x, base_y - height * 0.72, width, height * 0.72), silhouette)
				draw_colored_polygon(PackedVector2Array([
					Vector2(x - 10.0, base_y - height * 0.72),
					Vector2(x + width * 0.52, base_y - height),
					Vector2(x + width + 12.0, base_y - height * 0.72)
				]), silhouette)
				draw_rect(Rect2(x + width * 0.20, base_y - height * 0.42, 12.0, 25.0), silhouette_edge)
			"A7", "A8", "H02", "H05":
				# Cell blocks and tomb markers remain low and heavy.
				draw_rect(Rect2(x, base_y - height * 0.62, width, height * 0.62), silhouette)
				for slit in range(2):
					draw_rect(Rect2(x + width * (0.25 + float(slit) * 0.38), base_y - height * 0.50, 8.0, height * 0.20), silhouette_edge)
			_:
				# A restrained silhouette fallback for transitional regions.
				draw_rect(Rect2(x, base_y - height * 0.62, width, height * 0.62), silhouette)
				draw_line(Vector2(x, base_y - height * 0.62), Vector2(x + width, base_y - height * 0.62), silhouette_edge, 2.0)

	# A faint horizon line ties distant shapes together without boxing the screen.
	# 淡淡的地平线将远景剪影连接起来，但不把画面框死。
	draw_line(Vector2(0.0, floor_y - 9.0), Vector2(map_width, floor_y - 9.0), Color(atmosphere.r, atmosphere.g, atmosphere.b, 0.10), 1.0)


# Broken paving seams and small rubble clusters make the ground read as a surface, not a flat bar.
# 断续石板缝与少量碎石让地面呈现真实材质，而不是一条平色矩形。
func _draw_ground_detail() -> void:
	var atmosphere := _atmosphere_color()
	draw_rect(Rect2(0.0, floor_y, map_width, 3.0), Color(atmosphere.r, atmosphere.g, atmosphere.b, 0.22))
	for index in range(1, int(map_width / 180.0)):
		var x := float(index) * 180.0 + float(int(region_id.hash() % 29))
		var seam_height := 7.0 + float((index * 11) % 13)
		draw_line(Vector2(x, floor_y + 25.0), Vector2(x - 4.0, floor_y + 25.0 + seam_height), Color("#0d0b11", 0.34), 1.0)
		if index % 2 == 0:
			draw_line(Vector2(x + 2.0, floor_y + 58.0), Vector2(x + 26.0, floor_y + 55.0), Color("#574750", 0.22), 1.0)
		if index % 3 == 0:
			var pebble_x := x + 32.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(pebble_x, floor_y + 74.0),
				Vector2(pebble_x + 5.0, floor_y + 68.0),
				Vector2(pebble_x + 13.0, floor_y + 75.0)
			]), Color(atmosphere.r, atmosphere.g, atmosphere.b, 0.12))


func _atmosphere_color() -> Color:
	match region_id:
		"A2", "H02", "H05":
			return Color("#8a9bb4")
		"A3", "A9", "H03", "H07":
			return Color("#9e819a")
		"A4", "H04":
			return Color("#78a4ac")
		"A5", "A6", "A10":
			return Color("#b38a83")
		"A7", "A8", "H06":
			return Color("#a79ba5")
		"A11", "H08", "H09":
			return Color("#aa7c9e")
		_:
			return Color("#93849b")

func _background_color() -> Color:
	match region_id:
		"A2":
			return Color("#171823")
		"A3":
			return Color("#19161d")
		"A4":
			return Color("#11151c")
		"A5":
			return Color("#21191a")
		"A6":
			return Color("#191b25")
		"A7":
			return Color("#111319")
		"A8":
			return Color("#1a171d")

		"A9":
			return Color("#1a1a22")
		"A10":
			return Color("#211b25")
		"A12":
			return Color("#201b20")
		"H07":
			return Color("#10191e")

		"H01":
			return Color("#100f18")
		"H02":
			return Color("#171822")
		"H03":
			return Color("#1b171f")
		"H04":
			return Color("#111a20")
		"H05":
			return Color("#191722")
		"H06":
			return Color("#1a151c")
		"A11":
			return Color("#16151e")
		"H08":
			return Color("#0e1419")
		"H09":
			return Color("#18131b")
		_:
			return Color("#111018")

func _platform_color() -> Color:
	match region_id:
		"A2":
			return Color("#39343d")
		"A3":
			return Color("#343039")
		"A4":
			return Color("#30353a")
		"A5":
			return Color("#463635")
		"A6":
			return Color("#393643")
		"A7":
			return Color("#35333b")
		"A8":
			return Color("#40383e")

		"A9":
			return Color("#373741")
		"A10":
			return Color("#403847")
		"A12":
			return Color("#42343b")
		"H07":
			return Color("#2d4144")

		"H01":
			return Color("#39303a")
		"H02":
			return Color("#3b3541")
		"H03":
			return Color("#39303a")
		"H04":
			return Color("#303c43")
		"H05":
			return Color("#403943")
		"H06":
			return Color("#403039")
		"A11":
			return Color("#393744")
		"H08":
			return Color("#2c3c40")
		"H09":
			return Color("#3c303b")
		_:
			return Color("#302a33")

func _draw_forest_landmarks() -> void:
	for x in range(180, int(map_width), 230):
		var height := 110 + (int(x / 230) % 3) * 28
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(x - 46, floor_y),
				Vector2(x, floor_y - height),
				Vector2(x + 46, floor_y)
			]),
			Color("#252934")
		)
		draw_rect(Rect2(x - 8, floor_y - 30, 16, 30), Color("#30272d"))
	draw_rect(Rect2(710, 285, 48, 195), Color("#302c35"))
	draw_line(Vector2(704, 290), Vector2(765, 290), Color("#75666b"), 4.0)
	draw_line(Vector2(735, 300), Vector2(735, 350), Color("#75666b"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(690, 260), "无风", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#75666b"))
	# Canopy silhouettes guide the optional upper traversal without hiding the bell landmark.
	# 树冠剪影提示上层可选路线，同时保留钟墓地标的可见性。
	draw_line(Vector2(755, 360), Vector2(875, 320), Color("#514957"), 3.0)
	draw_line(Vector2(875, 320), Vector2(1005, 350), Color("#514957"), 3.0)
	draw_line(Vector2(1005, 350), Vector2(1125, 395), Color("#514957"), 3.0)
	draw_line(Vector2(1125, 395), Vector2(1265, 380), Color("#514957"), 3.0)
	draw_line(Vector2(1265, 380), Vector2(1385, 335), Color("#514957"), 3.0)
	draw_line(Vector2(1385, 335), Vector2(1505, 300), Color("#514957"), 3.0)
	draw_line(Vector2(1505, 300), Vector2(1625, 340), Color("#514957"), 3.0)
	draw_line(Vector2(1625, 340), Vector2(1745, 390), Color("#514957"), 3.0)
	draw_line(Vector2(1745, 390), Vector2(1845, 435), Color("#514957"), 3.0)

func _draw_city_landmarks() -> void:
	for x in range(200, int(map_width), 390):
		draw_rect(Rect2(x, floor_y - 190, 150, 190), Color("#29252f"))
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(x - 22, floor_y - 190),
				Vector2(x + 75, floor_y - 285),
				Vector2(x + 172, floor_y - 190)
			]),
			Color("#342d38")
		)
		draw_rect(Rect2(x + 56, floor_y - 92, 38, 92), Color("#131117"))
		draw_rect(Rect2(x + 20, floor_y - 150, 18, 26), Color("#15131b"))
		draw_rect(Rect2(x + 112, floor_y - 150, 18, 26), Color("#15131b"))
	# The third-street sign and the false wall are the city's primary spatial landmark.
	# 第三街路牌与假墙是城区最重要的空间地标。
	draw_rect(Rect2(842, 340, 146, 28), Color("#4a3c43"))
	draw_string(ThemeDB.fallback_font, Vector2(855, 360), "第三街", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#98867e"))
	draw_line(Vector2(905, 365), Vector2(905, 418), Color("#98867e"), 2.0)
	draw_rect(Rect2(1000, floor_y - 235, 105, 235), Color("#211e27"))
	draw_rect(Rect2(1016, floor_y - 205, 22, 46), Color("#131117"))
	draw_rect(Rect2(1066, floor_y - 205, 22, 46), Color("#131117"))
	draw_line(Vector2(990, floor_y - 240), Vector2(1115, floor_y - 240), Color("#66535e"), 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(990, floor_y - 255), "有墙／无街", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("#8b737b"))
	# Roof silhouettes mark the optional upper route; the platforms above them are physically traversable.
	# 屋顶剪影提示上层支路；其上的平台具有真实碰撞，可供玩家跳跃穿行。
	draw_line(Vector2(440, 390), Vector2(570, 345), Color("#5b4b57"), 3.0)
	draw_line(Vector2(570, 345), Vector2(710, 300), Color("#5b4b57"), 3.0)
	draw_line(Vector2(710, 300), Vector2(870, 290), Color("#5b4b57"), 3.0)
	draw_line(Vector2(870, 290), Vector2(1020, 330), Color("#5b4b57"), 3.0)

func _draw_reservoir_landmarks() -> void:
	for x in range(180, int(map_width), 410):
		draw_arc(Vector2(x, floor_y - 8), 118.0, PI, TAU, 28, Color("#343a46"), 10.0)
		draw_line(Vector2(x - 118, floor_y - 8), Vector2(x - 118, floor_y + 14), Color("#343a46"), 10.0)
		draw_line(Vector2(x + 118, floor_y - 8), Vector2(x + 118, floor_y + 14), Color("#343a46"), 10.0)
	draw_rect(Rect2(0, floor_y + 48, map_width, 36), Color("#19272f"))
	draw_line(Vector2(0, floor_y + 48), Vector2(map_width, floor_y + 48), Color("#405660"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(960, floor_y + 75), "石下之水", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#637a83"))

func _draw_outer_ring_landmarks() -> void:
	for x in range(200, int(map_width), 360):
		draw_rect(Rect2(x, floor_y - 180, 170, 180), Color("#292733"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 18, floor_y - 180),
			Vector2(x + 85, floor_y - 250),
			Vector2(x + 188, floor_y - 180)
		]), Color("#35313b"))
		draw_rect(Rect2(x + 65, floor_y - 92, 35, 92), Color("#14131a"))
	draw_rect(Rect2(1320, floor_y - 160, 170, 160), Color("#202128"))
	draw_arc(Vector2(1380, floor_y - 18), 58.0, PI, TAU, 30, Color("#6d8790"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(1300, floor_y - 195), "无云之雨", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#718790"))
	# Broken roof bridges trace a second street across the abandoned outer ring.
	# 断裂的屋顶桥在废弃外环上方勾出第二条街道。
	draw_line(Vector2(390, floor_y - 145), Vector2(520, floor_y - 185), Color("#5b5868"), 3.0)
	draw_line(Vector2(520, floor_y - 185), Vector2(665, floor_y - 220), Color("#5b5868"), 3.0)
	draw_line(Vector2(665, floor_y - 220), Vector2(815, floor_y - 200), Color("#5b5868"), 3.0)
	draw_line(Vector2(815, floor_y - 200), Vector2(960, floor_y - 155), Color("#5b5868"), 3.0)
	draw_line(Vector2(1110, floor_y - 155), Vector2(1260, floor_y - 200), Color("#5b5868"), 3.0)
	draw_line(Vector2(1260, floor_y - 200), Vector2(1400, floor_y - 235), Color("#5b5868"), 3.0)
	draw_line(Vector2(1400, floor_y - 235), Vector2(1540, floor_y - 200), Color("#5b5868"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(760, floor_y - 275), "第二条街只在雨中出现", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#718790"))

func _draw_cathedral_landmarks() -> void:
	draw_rect(Rect2(880, floor_y - 330, 600, 330), Color("#302b38"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(830, floor_y - 330),
		Vector2(1180, floor_y - 555),
		Vector2(1530, floor_y - 330)
	]), Color("#403546"))
	for x in [960, 1100, 1240, 1380]:
		draw_rect(Rect2(x, floor_y - 245, 42, 100), Color("#131119"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 10, floor_y - 245),
			Vector2(x + 21, floor_y - 285),
			Vector2(x + 52, floor_y - 245)
		]), Color("#18141e"))
	draw_line(Vector2(875, floor_y - 325), Vector2(1485, floor_y - 325), Color("#766578"), 4.0)
	# Side-chapel lintels lead toward a broken choir gallery above the nave.
	# 侧礼拜堂的横梁指向中殿上方断裂的唱诗席高廊。
	draw_line(Vector2(400, floor_y - 145), Vector2(535, floor_y - 185), Color("#6c5e72"), 3.0)
	draw_line(Vector2(535, floor_y - 185), Vector2(675, floor_y - 225), Color("#6c5e72"), 3.0)
	draw_line(Vector2(675, floor_y - 225), Vector2(815, floor_y - 260), Color("#6c5e72"), 3.0)
	draw_line(Vector2(815, floor_y - 260), Vector2(960, floor_y - 230), Color("#6c5e72"), 3.0)
	draw_line(Vector2(1100, floor_y - 190), Vector2(1240, floor_y - 230), Color("#6c5e72"), 3.0)
	draw_line(Vector2(1240, floor_y - 230), Vector2(1380, floor_y - 195), Color("#6c5e72"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(570, floor_y - 255), "唱诗班曾为墙而歌", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#92809b"))
	# The reliquary bears two seals from different eras.
	# 圣物匣上压着两个不同时代的封印。
	draw_rect(Rect2(670, floor_y - 55, 64, 38), Color("#514450"))
	draw_rect(Rect2(680, floor_y - 48, 18, 18), Color("#a18b78"))
	draw_rect(Rect2(706, floor_y - 48, 18, 18), Color("#6f8a8c"))
	draw_line(Vector2(680, floor_y - 39), Vector2(698, floor_y - 39), Color("#332b38"), 2.0)
	draw_line(Vector2(706, floor_y - 39), Vector2(724, floor_y - 39), Color("#332b38"), 2.0)

func _draw_inner_city_landmarks() -> void:
	for x in range(260, int(map_width), 460):
		draw_rect(Rect2(x, floor_y - 205, 190, 205), Color("#302932"))
		draw_rect(Rect2(x + 70, floor_y - 125, 48, 125), Color("#151217"))
		draw_rect(Rect2(x + 18, floor_y - 160, 20, 25), Color("#17141b"))
		draw_rect(Rect2(x + 145, floor_y - 160, 20, 25), Color("#17141b"))
	draw_rect(Rect2(1670, floor_y - 280, 400, 280), Color("#3b3039"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(1620, floor_y - 280),
		Vector2(1870, floor_y - 420),
		Vector2(2120, floor_y - 280)
	]), Color("#54414e"))
	draw_rect(Rect2(1825, floor_y - 175, 90, 175), Color("#141118"))
	# The crown wall is visibly walkable only in fragments, echoing the kingdom's broken authority.
	# 王冠城墙只剩断续可走的片段，映照王权破碎的状态。
	draw_line(Vector2(410, floor_y - 135), Vector2(545, floor_y - 180), Color("#77616d"), 3.0)
	draw_line(Vector2(545, floor_y - 180), Vector2(680, floor_y - 220), Color("#77616d"), 3.0)
	draw_line(Vector2(680, floor_y - 220), Vector2(820, floor_y - 200), Color("#77616d"), 3.0)
	draw_line(Vector2(1120, floor_y - 150), Vector2(1260, floor_y - 195), Color("#77616d"), 3.0)
	draw_line(Vector2(1260, floor_y - 195), Vector2(1400, floor_y - 235), Color("#77616d"), 3.0)
	draw_line(Vector2(1400, floor_y - 235), Vector2(1540, floor_y - 200), Color("#77616d"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(1640, floor_y - 445), "王冠没有影子", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#a18798"))
	# The king's sealed letter remains beside the throne, never sent to the church.
	# 国王未寄出的信留在王座旁，从未送往教会。
	draw_rect(Rect2(1040, floor_y - 42, 58, 30), Color("#c0ad8d"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(1040, floor_y - 42), Vector2(1069, floor_y - 25), Vector2(1098, floor_y - 42)
	]), Color("#79616d"))
	draw_line(Vector2(1050, floor_y - 36), Vector2(1088, floor_y - 36), Color("#594753"), 2.0)

func _draw_mirror_street_landmarks() -> void:
	for x in range(160, int(map_width), 340):
		draw_rect(Rect2(x, floor_y - 150, 110, 150), Color("#263438"))
		draw_rect(Rect2(x + 37, floor_y - 92, 36, 92), Color("#0c1317"))
		draw_rect(Rect2(x - 18, floor_y + 42, 146, 24), Color("#28444a"))
		draw_line(Vector2(x - 18, floor_y + 42), Vector2(x + 128, floor_y + 42), Color("#6ca5ad"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(680, floor_y - 220), "灯在水下", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#70979a"))
	draw_line(Vector2(380, floor_y - 145), Vector2(505, floor_y - 190), Color("#6ca5ad"), 3.0)
	draw_line(Vector2(505, floor_y - 190), Vector2(645, floor_y - 230), Color("#6ca5ad"), 3.0)
	draw_line(Vector2(645, floor_y - 230), Vector2(790, floor_y - 210), Color("#6ca5ad"), 3.0)
	draw_line(Vector2(930, floor_y - 165), Vector2(1060, floor_y - 130), Color("#6ca5ad"), 3.0)
	draw_line(Vector2(1060, floor_y - 130), Vector2(1190, floor_y - 155), Color("#6ca5ad"), 3.0)
	draw_line(Vector2(1190, floor_y - 155), Vector2(1325, floor_y - 200), Color("#6ca5ad"), 3.0)
	draw_line(Vector2(1325, floor_y - 200), Vector2(1460, floor_y - 240), Color("#6ca5ad"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(980, floor_y - 270), "倒影里还有第二层", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#70979a"))
	for lamp in range(6):
		draw_circle(Vector2(2130.0 + float(lamp) * 24.0, floor_y - 24), 4.0, Color("#6ca5ad"))
	draw_circle(Vector2(2200, floor_y - 56), 5.0, Color("#b6d4d0"))
	draw_line(Vector2(2125, floor_y - 14), Vector2(2265, floor_y - 14), Color("#6ca5ad"), 2.0)


func _draw_battlefield_landmarks() -> void:
	for x in range(260, int(map_width), 390):
		draw_rect(Rect2(x, floor_y - 58, 180, 58), Color("#302528"))
		draw_line(Vector2(x, floor_y - 58), Vector2(x + 180, floor_y - 58), Color("#5a4443"), 3.0)
	draw_rect(Rect2(2020, floor_y - 230, 280, 230), Color("#30272b"))
	draw_rect(Rect2(2080, floor_y - 170, 52, 170), Color("#151318"))
	draw_rect(Rect2(2190, floor_y - 170, 52, 170), Color("#151318"))
	draw_line(Vector2(2030, floor_y - 235), Vector2(2300, floor_y - 235), Color("#6a5050"), 4.0)
	# A broken parapet silhouette marks the optional upper crossing over the trenches.
	# 断裂城墙剪影标记战壕上方的可选高路。
	draw_line(Vector2(420, floor_y - 130), Vector2(565, floor_y - 175), Color("#6d5150"), 4.0)
	draw_line(Vector2(565, floor_y - 175), Vector2(725, floor_y - 215), Color("#6d5150"), 4.0)
	draw_line(Vector2(725, floor_y - 215), Vector2(885, floor_y - 180), Color("#6d5150"), 4.0)
	draw_line(Vector2(885, floor_y - 180), Vector2(1055, floor_y - 130), Color("#6d5150"), 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(720, floor_y - 245), "墙上没有军旗", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#8d6c6a"))
	# The report lies beside bodies deliberately turned toward the fortress.
	# 报告被放在面朝堡垒的尸体旁，暗示战场曾被重新布置。
	draw_rect(Rect2(1065, floor_y - 38, 54, 26), Color("#7a6c64"))
	draw_line(Vector2(1074, floor_y - 30), Vector2(1110, floor_y - 30), Color("#c3b49a"), 2.0)
	draw_line(Vector2(1074, floor_y - 22), Vector2(1102, floor_y - 22), Color("#c3b49a"), 2.0)
	draw_line(Vector2(1085, floor_y - 12), Vector2(1085, floor_y + 4), Color("#6c5558"), 3.0)
	draw_line(Vector2(1085, floor_y + 4), Vector2(1110, floor_y + 9), Color("#6c5558"), 3.0)

func _draw_monastery_landmarks() -> void:
	draw_rect(Rect2(930, floor_y - 355, 270, 355), Color("#292833"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(900, floor_y - 355),
		Vector2(1065, floor_y - 505),
		Vector2(1230, floor_y - 355)
	]), Color("#38323c"))
	draw_rect(Rect2(1080, floor_y - 310, 34, 52), Color("#111018"))
	draw_arc(Vector2(1097, floor_y - 287), 34.0, 0.0, TAU, 24, Color("#716975"), 2.0)
	draw_line(Vector2(1097, floor_y - 322), Vector2(1097, floor_y - 250), Color("#716975"), 2.0)
	draw_rect(Rect2(1760, floor_y - 165, 220, 165), Color("#25242e"))
	draw_rect(Rect2(1810, floor_y - 125, 42, 125), Color("#121118"))
	# The side balcony wraps the bell tower instead of repeating the same staircase.
	# 侧阳台绕过钟塔外墙，避免整张地图只有重复阶梯。
	draw_line(Vector2(1245, floor_y - 280), Vector2(1390, floor_y - 240), Color("#625a6e"), 3.0)
	draw_line(Vector2(1390, floor_y - 240), Vector2(1535, floor_y - 190), Color("#625a6e"), 3.0)
	draw_line(Vector2(1535, floor_y - 190), Vector2(1650, floor_y - 145), Color("#625a6e"), 3.0)

func _draw_prison_landmarks() -> void:
	for x in range(330, int(map_width), 330):
		draw_rect(Rect2(x, floor_y - 200, 7, 200), Color("#4a464e"))
		draw_rect(Rect2(x + 66, floor_y - 200, 7, 200), Color("#4a464e"))
		draw_line(Vector2(x, floor_y - 155), Vector2(x + 73, floor_y - 155), Color("#4a464e"), 5.0)
		draw_line(Vector2(x, floor_y - 82), Vector2(x + 73, floor_y - 82), Color("#4a464e"), 5.0)
	draw_rect(Rect2(1660, floor_y - 265, 150, 265), Color("#29272f"))
	draw_rect(Rect2(1713, floor_y - 214, 44, 214), Color("#121117"))
	# A narrow maintenance shaft is visible behind the cell bars.
	# 铁栏后方保留一条狭窄维护竖井。
	draw_line(Vector2(1280, floor_y - 320), Vector2(1280, floor_y - 205), Color("#716b76"), 3.0)
	draw_line(Vector2(1270, floor_y - 300), Vector2(1290, floor_y - 300), Color("#716b76"), 2.0)
	draw_line(Vector2(1270, floor_y - 265), Vector2(1290, floor_y - 265), Color("#716b76"), 2.0)
	draw_line(Vector2(1270, floor_y - 230), Vector2(1290, floor_y - 230), Color("#716b76"), 2.0)
	# Transfer ledgers are stacked beside the maintenance shaft, not the execution cells.
	# 转移名册堆在维护竖井旁，而不是处刑牢房内。
	draw_rect(Rect2(1035, floor_y - 48, 62, 34), Color("#5a505b"))
	draw_line(Vector2(1043, floor_y - 39), Vector2(1087, floor_y - 39), Color("#b3a1ad"), 2.0)
	draw_line(Vector2(1043, floor_y - 30), Vector2(1080, floor_y - 30), Color("#b3a1ad"), 2.0)
	draw_line(Vector2(1043, floor_y - 21), Vector2(1087, floor_y - 21), Color("#b3a1ad"), 2.0)

func _draw_royal_tomb_landmarks() -> void:
	for x in [360, 760, 1160, 1560, 1960]:
		draw_rect(Rect2(x, floor_y - 82, 180, 54), Color("#373039"))
		draw_rect(Rect2(x + 14, floor_y - 94, 152, 14), Color("#5a4d55"))
		draw_line(Vector2(x + 26, floor_y - 68), Vector2(x + 154, floor_y - 68), Color("#78666d"), 2.0)
	draw_rect(Rect2(1660, floor_y - 244, 28, 170), Color("#51454d"))
	draw_rect(Rect2(1694, floor_y - 244, 28, 170), Color("#51454d"))
	draw_line(Vector2(1648, floor_y - 244), Vector2(1734, floor_y - 244), Color("#817079"), 5.0)
	draw_string(ThemeDB.fallback_font, Vector2(1500, floor_y - 270), "名字已被抹去", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#8f8086"))
	# The upper gallery forms a broken crown over the sarcophagi.
	# 上层墓廊像破碎的王冠一样覆盖石棺列。
	draw_line(Vector2(400, floor_y - 130), Vector2(535, floor_y - 175), Color("#6b5b66"), 3.0)
	draw_line(Vector2(535, floor_y - 175), Vector2(675, floor_y - 220), Color("#6b5b66"), 3.0)
	draw_line(Vector2(675, floor_y - 220), Vector2(825, floor_y - 200), Color("#6b5b66"), 3.0)
	draw_line(Vector2(825, floor_y - 200), Vector2(965, floor_y - 155), Color("#6b5b66"), 3.0)
	draw_line(Vector2(1105, floor_y - 185), Vector2(1245, floor_y - 230), Color("#6b5b66"), 3.0)
	draw_line(Vector2(1245, floor_y - 230), Vector2(1385, floor_y - 190), Color("#6b5b66"), 3.0)
	draw_line(Vector2(1525, floor_y - 145), Vector2(1665, floor_y - 185), Color("#6b5b66"), 3.0)
	draw_line(Vector2(1805, floor_y - 230), Vector2(1945, floor_y - 185), Color("#6b5b66"), 3.0)


func _draw_hidden_bell_chamber_landmarks() -> void:
	draw_arc(Vector2(560, floor_y - 75), 88.0, PI, TAU, 32, Color("#49404b"), 8.0)
	draw_rect(Rect2(520, floor_y - 95, 80, 65), Color("#292430"))
	draw_line(Vector2(560, floor_y - 180), Vector2(560, floor_y - 92), Color("#817081"), 3.0)
	draw_line(Vector2(530, floor_y - 70), Vector2(590, floor_y - 70), Color("#6f5969"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(900, floor_y - 190), "钟舌从未摆动", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#817081"))
	draw_line(Vector2(390, floor_y - 140), Vector2(515, floor_y - 185), Color("#62566c"), 3.0)
	draw_line(Vector2(515, floor_y - 185), Vector2(650, floor_y - 225), Color("#62566c"), 3.0)
	draw_line(Vector2(650, floor_y - 225), Vector2(790, floor_y - 205), Color("#62566c"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(650, floor_y - 260), "声音有形状", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#8b7893"))
	draw_arc(Vector2(1650, floor_y - 88), 36.0, PI, TAU, 24, Color("#817081"), 3.0)
	draw_line(Vector2(1650, floor_y - 124), Vector2(1650, floor_y - 48), Color("#817081"), 3.0)
	draw_line(Vector2(1628, floor_y - 62), Vector2(1672, floor_y - 62), Color("#817081"), 2.0)

func _draw_erased_third_street_landmarks() -> void:
	for x in range(180, int(map_width), 360):
		draw_rect(Rect2(x, floor_y - 205, 160, 205), Color("#28242e"))
		draw_rect(Rect2(x + 52, floor_y - 112, 42, 112), Color("#111018"))
		draw_rect(Rect2(x + 17, floor_y - 164, 20, 28), Color("#17141d"))
		draw_rect(Rect2(x + 123, floor_y - 164, 20, 28), Color("#17141d"))
		draw_line(Vector2(x + 8, floor_y - 210), Vector2(x + 151, floor_y - 210), Color("#50424f"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(760, floor_y - 250), "没有三号街", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#8a727f"))
	draw_line(Vector2(380, floor_y - 145), Vector2(505, floor_y - 190), Color("#6a5369"), 3.0)
	draw_line(Vector2(505, floor_y - 190), Vector2(645, floor_y - 230), Color("#6a5369"), 3.0)
	draw_line(Vector2(645, floor_y - 230), Vector2(790, floor_y - 210), Color("#6a5369"), 3.0)
	draw_line(Vector2(930, floor_y - 165), Vector2(1070, floor_y - 155), Color("#6a5369"), 3.0)
	draw_line(Vector2(1070, floor_y - 155), Vector2(1210, floor_y - 145), Color("#6a5369"), 3.0)
	draw_line(Vector2(1210, floor_y - 145), Vector2(1340, floor_y - 190), Color("#6a5369"), 3.0)
	draw_line(Vector2(1340, floor_y - 190), Vector2(1475, floor_y - 230), Color("#6a5369"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(1240, floor_y - 265), "失踪的街道仍有屋顶", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#8a727f"))
	draw_rect(Rect2(1990, floor_y - 72, 64, 44), Color("#38303e"))
	draw_string(ThemeDB.fallback_font, Vector2(1998, floor_y - 42), "1  2  _", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#b19aa9"))

func _draw_reflected_stairwell_landmarks() -> void:
	draw_rect(Rect2(0, floor_y + 48, map_width, 36), Color("#15252d"))
	draw_line(Vector2(0, floor_y + 48), Vector2(map_width, floor_y + 48), Color("#50727b"), 3.0)
	for i in range(6):
		var step_x := 250.0 + float(i) * 230.0
		var step_y := floor_y - 48.0 - float(i) * 32.0
		draw_rect(Rect2(step_x, step_y, 150.0, 10.0), Color("#596e78"))
		draw_line(Vector2(step_x, step_y), Vector2(step_x + 150.0, step_y), Color("#8fa8ac"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(700, floor_y - 260), "湿室中的干燥阶梯", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#77959d"))
	draw_line(Vector2(390, floor_y - 140), Vector2(515, floor_y - 185), Color("#5e8792"), 3.0)
	draw_line(Vector2(515, floor_y - 185), Vector2(650, floor_y - 225), Color("#5e8792"), 3.0)
	draw_line(Vector2(650, floor_y - 225), Vector2(790, floor_y - 205), Color("#5e8792"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(990, floor_y - 275), "倒影正在攀升", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#77959d"))
	for ripple in range(3):
		draw_arc(Vector2(1740, floor_y - 22), 18.0 + float(ripple) * 10.0, PI, TAU, 20, Color("#5e8792"), 2.0)
	draw_line(Vector2(1700, floor_y - 18), Vector2(1780, floor_y - 18), Color("#5e8792"), 2.0)

func _draw_silent_bell_room_landmarks() -> void:
	draw_rect(Rect2(900, floor_y - 390, 300, 390), Color("#292632"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(865, floor_y - 390), Vector2(1050, floor_y - 545),
		Vector2(1235, floor_y - 390)
	]), Color("#38303f"))
	draw_arc(Vector2(1050, floor_y - 290), 56.0, PI, TAU, 30, Color("#74677d"), 3.0)
	draw_line(Vector2(1050, floor_y - 346), Vector2(1050, floor_y - 230), Color("#74677d"), 2.0)
	draw_rect(Rect2(1017, floor_y - 270, 66, 82), Color("#16131d"))
	draw_string(ThemeDB.fallback_font, Vector2(1320, floor_y - 250), "没有影子", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#8a7b94"))
	draw_line(Vector2(400, floor_y - 135), Vector2(530, floor_y - 180), Color("#766b85"), 3.0)
	draw_line(Vector2(530, floor_y - 180), Vector2(670, floor_y - 220), Color("#766b85"), 3.0)
	draw_line(Vector2(670, floor_y - 220), Vector2(810, floor_y - 255), Color("#766b85"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(1260, floor_y - 290), "钟没有投下影子", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#8a7b94"))
	draw_rect(Rect2(1925, floor_y - 66, 72, 42), Color("#393341"))
	draw_line(Vector2(1935, floor_y - 56), Vector2(1987, floor_y - 56), Color("#9b8ea6"), 2.0)
	draw_line(Vector2(1935, floor_y - 46), Vector2(1987, floor_y - 46), Color("#9b8ea6"), 2.0)
	draw_line(Vector2(1935, floor_y - 36), Vector2(1970, floor_y - 36), Color("#9b8ea6"), 2.0)

func _draw_erased_royal_name_landmarks() -> void:
	for x in [320.0, 760.0, 1200.0, 1640.0]:
		draw_rect(Rect2(x, floor_y - 82, 190, 54), Color("#393039"))
		draw_rect(Rect2(x + 14, floor_y - 94, 162, 14), Color("#5b4953"))
		draw_line(Vector2(x + 26, floor_y - 68), Vector2(x + 152, floor_y - 68), Color("#78636e"), 2.0)
		draw_line(Vector2(x + 74, floor_y - 62), Vector2(x + 112, floor_y - 74), Color("#8b7480"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(720, floor_y - 190), "一个被刮去的名字", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#9b808d"))
	draw_line(Vector2(390, floor_y - 135), Vector2(520, floor_y - 180), Color("#7c6475"), 3.0)
	draw_line(Vector2(520, floor_y - 180), Vector2(660, floor_y - 220), Color("#7c6475"), 3.0)
	draw_line(Vector2(660, floor_y - 220), Vector2(800, floor_y - 200), Color("#7c6475"), 3.0)
	draw_line(Vector2(1220, floor_y - 150), Vector2(1360, floor_y - 195), Color("#7c6475"), 3.0)
	draw_line(Vector2(1360, floor_y - 195), Vector2(1500, floor_y - 235), Color("#7c6475"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(1190, floor_y - 270), "王室血脉在此终结", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#9b808d"))
	draw_rect(Rect2(1940, floor_y - 74, 86, 46), Color("#393039"))
	draw_line(Vector2(1950, floor_y - 64), Vector2(2016, floor_y - 64), Color("#a38b98"), 2.0)
	draw_line(Vector2(1950, floor_y - 54), Vector2(2016, floor_y - 54), Color("#a38b98"), 2.0)
	draw_line(Vector2(1960, floor_y - 44), Vector2(1976, floor_y - 60), Color("#a38b98"), 2.0)
	draw_line(Vector2(1976, floor_y - 60), Vector2(1992, floor_y - 44), Color("#a38b98"), 2.0)

func _draw_deep_research_landmarks() -> void:
	# The laboratory is built around an older, warmer stone structure.
	draw_rect(Rect2(160, 280, 420, 240), Color("#211f2a"))
	draw_rect(Rect2(188, 308, 364, 212), Color("#292631"))
	draw_line(Vector2(188, 308), Vector2(552, 520), Color("#4d4954"), 3.0)
	draw_line(Vector2(552, 308), Vector2(188, 520), Color("#4d4954"), 3.0)
	draw_rect(Rect2(830, 250, 300, 270), Color("#242530"))
	draw_arc(Vector2(980, 382), 94.0, PI, TAU, 28, Color("#6d5c6a"), 3.0)
	draw_line(Vector2(980, 288), Vector2(980, 485), Color("#6d5c6a"), 2.0)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(1220, 310),
		NereisLocalization.translate_text("观测室"),
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("#827887")
	)
	draw_rect(Rect2(2050, 250, 270, 270), Color("#211f28"))
	draw_line(Vector2(2070, 310), Vector2(2302, 290), Color("#4e495a"), 3.0)
	draw_line(Vector2(2060, 398), Vector2(2310, 420), Color("#4e495a"), 3.0)
	draw_arc(Vector2(2185, 388), 90.0, PI * 0.92, TAU * 0.86, 34, Color("#5c5367"), 2.0)
	# A suspended observation bridge crosses the laboratory without erasing the older ruin beneath it.
	# 悬空观测桥横跨实验室，却没有抹掉其下方更古老的遗迹。
	draw_line(Vector2(390, floor_y - 135), Vector2(520, floor_y - 180), Color("#635a70"), 3.0)
	draw_line(Vector2(520, floor_y - 180), Vector2(660, floor_y - 220), Color("#635a70"), 3.0)
	draw_line(Vector2(660, floor_y - 220), Vector2(810, floor_y - 205), Color("#635a70"), 3.0)
	draw_line(Vector2(950, floor_y - 165), Vector2(1090, floor_y - 210), Color("#635a70"), 3.0)
	draw_line(Vector2(1090, floor_y - 210), Vector2(1230, floor_y - 255), Color("#635a70"), 3.0)
	draw_line(Vector2(1230, floor_y - 255), Vector2(1370, floor_y - 215), Color("#635a70"), 3.0)
	draw_line(Vector2(1510, floor_y - 175), Vector2(1660, floor_y - 215), Color("#635a70"), 3.0)
	draw_line(Vector2(1660, floor_y - 215), Vector2(1800, floor_y - 255), Color("#635a70"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(1170, 255), "观测者也是实验的一部分", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#8b8195"))

func _draw_cliff_cave_landmarks() -> void:
	# Layered limestone ribs frame a disturbed hive seal and the Church's silver restraints.
	# 多层石灰岩骨脊围出被破坏的蜂巢封条与教会银质束缚。
	for x in [220.0, 520.0, 860.0, 1190.0, 1530.0, 1840.0]:
		var height := 155.0 + fmod(x, 3.0) * 38.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 78.0, floor_y),
			Vector2(x - 26.0, floor_y - height),
			Vector2(x + 12.0, floor_y - height - 38.0),
			Vector2(x + 74.0, floor_y)
		]), Color("#28212d"))
		draw_line(Vector2(x - 24.0, floor_y - height + 18.0), Vector2(x + 8.0, floor_y - height - 16.0), Color("#574453"), 3.0)
	# A ribbed organic membrane surrounds the empty restraint ring after the experiment is defeated.
	# 实验体被击败后，空束缚环仍留在有机膜中央。
	draw_arc(Vector2(1460.0, floor_y - 36.0), 64.0, PI, TAU, 28, Color("#8c6877"), 4.0)
	draw_arc(Vector2(1460.0, floor_y - 36.0), 46.0, PI, TAU, 24, Color("#51414f"), 2.0)
	draw_line(Vector2(1395.0, floor_y - 36.0), Vector2(1525.0, floor_y - 36.0), Color("#6d5267"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(1320.0, floor_y - 130.0), "银线束缚已断", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#ad879b"))
	draw_rect(Rect2(1810.0, floor_y - 215.0, 110.0, 215.0), Color("#211923"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(1785.0, floor_y - 215.0),
		Vector2(1865.0, floor_y - 275.0),
		Vector2(1945.0, floor_y - 215.0)
	]), Color("#3c2d3b"))
	draw_string(ThemeDB.fallback_font, Vector2(1750.0, floor_y - 290.0), "祷词从石头里传来", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#98768b"))


func _draw_primordial_hollow_landmarks() -> void:
	# This room is grown from the research wall, rather than constructed as a machine hall.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(120, 540), Vector2(240, 405), Vector2(375, 380),
			Vector2(490, 440), Vector2(630, 360), Vector2(780, 405),
			Vector2(900, 330), Vector2(1035, 400), Vector2(1170, 365),
			Vector2(1340, 430), Vector2(1510, 382), Vector2(1700, 450),
			Vector2(1800, 540)
		]),
		Color("#1d2b31")
	)
	draw_polyline(
		PackedVector2Array([
			Vector2(210, 492), Vector2(325, 432), Vector2(430, 464),
			Vector2(565, 414), Vector2(705, 455), Vector2(850, 392),
			Vector2(1000, 451), Vector2(1135, 414), Vector2(1270, 462),
			Vector2(1420, 420), Vector2(1570, 470), Vector2(1710, 440)
		]),
		Color("#668b8b"), 2.0, true
	)
	for i in range(7):
		var x := 300.0 + float(i) * 210.0
		draw_line(Vector2(x, 445), Vector2(x + 18.0, 470), Color("#43595f"), 2.0)
		draw_line(Vector2(x + 18.0, 470), Vector2(x + 4.0, 495), Color("#43595f"), 2.0)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(510, 265),
		NereisLocalization.translate_text("石头正在呼吸"),
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color("#8db8b4")
	)
	draw_line(Vector2(390, floor_y - 150), Vector2(515, floor_y - 195), Color("#668b8b"), 3.0)
	draw_line(Vector2(515, floor_y - 195), Vector2(650, floor_y - 235), Color("#668b8b"), 3.0)
	draw_line(Vector2(650, floor_y - 235), Vector2(790, floor_y - 215), Color("#668b8b"), 3.0)
	draw_line(Vector2(1200, floor_y - 150), Vector2(1340, floor_y - 195), Color("#668b8b"), 3.0)
	draw_line(Vector2(1340, floor_y - 195), Vector2(1480, floor_y - 235), Color("#668b8b"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(1120, 245), "空腔长着肋骨", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#8db8b4"))
	draw_arc(Vector2(1850, floor_y - 30), 38.0, PI, TAU, 24, Color("#668b8b"), 4.0)
	draw_arc(Vector2(1850, floor_y - 30), 26.0, PI, TAU, 24, Color("#668b8b"), 3.0)
	draw_line(Vector2(1812, floor_y - 30), Vector2(1888, floor_y - 30), Color("#668b8b"), 3.0)

func _draw_well_landmarks() -> void:
	draw_rect(Rect2(460, 70, 170, floor_y - 70), Color("#1b1822"))
	draw_line(Vector2(460, 70), Vector2(460, floor_y), Color("#403844"), 18.0)
	draw_line(Vector2(630, 70), Vector2(630, floor_y), Color("#403844"), 18.0)
	draw_line(Vector2(460, 170), Vector2(630, 170), Color("#302932"), 12.0)
	draw_line(Vector2(460, 300), Vector2(630, 300), Color("#302932"), 12.0)
	draw_line(Vector2(460, 425), Vector2(630, 425), Color("#302932"), 12.0)
	draw_arc(Vector2(1100, floor_y - 20), 54.0, PI, TAU, 32, Color("#73656d"), 6.0)
	draw_rect(Rect2(1046, floor_y - 20, 108, 22), Color("#16131b"))
	draw_line(Vector2(420, floor_y - 150), Vector2(550, floor_y - 195), Color("#6b596f"), 3.0)
	draw_line(Vector2(550, floor_y - 195), Vector2(680, floor_y - 235), Color("#6b596f"), 3.0)
	draw_line(Vector2(680, floor_y - 235), Vector2(820, floor_y - 215), Color("#6b596f"), 3.0)
	draw_line(Vector2(820, floor_y - 215), Vector2(950, floor_y - 170), Color("#6b596f"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(660, floor_y - 265), "井中另有上岸之处", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#8b7890"))
	draw_arc(Vector2(1600, floor_y - 18), 34.0, PI, TAU, 24, Color("#6e8b91"), 3.0)
	draw_line(Vector2(1565, floor_y - 18), Vector2(1635, floor_y - 18), Color("#6e8b91"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(1540, floor_y - 65), "潮湿／空无", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("#7a9aa0"))

