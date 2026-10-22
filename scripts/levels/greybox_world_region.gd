extends Node2D
## Shared playable graybox for the first connected world-map loop.
## 第一条互通地图环路的通用可玩灰盒场景。

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const INTERACTION_DOOR_SCRIPT = preload("res://scripts/world/interaction_door.gd")
const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")
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
const WORLD_ITEM_PICKUP_SCRIPT = preload("res://scripts/world/world_item_pickup.gd")
const REGION_AMBIENCE_SCRIPT = preload("res://scripts/effects/region_ambience.gd")
const FOREST_BACKDROP = preload("res://assets/art/backdrops/forest_backdrop.svg")
const RUINS_BACKDROP = preload("res://assets/art/backdrops/ruins_backdrop.svg")
const CHURCH_BACKDROP = preload("res://assets/art/backdrops/church_backdrop.svg")
const ELDRITCH_BACKDROP = preload("res://assets/art/backdrops/eldritch_backdrop.svg")
const STONE_FLOOR_STRIP = preload("res://assets/art/backdrops/stone_floor_strip.svg")

const ENCOUNTER_ACTIVATE_RANGE := 420.0
const ENCOUNTER_DEACTIVATE_RANGE := 560.0

@export var region_id: String = "A2"
@export var location_id: String = "ash_forest"
@export var region_title: String = "旧朝圣路"
@export var map_width: float = 2600.0
@export var floor_y: float = 540.0
@export var room_height: float = 720.0
@export var room_id: String = ""
@export var use_a5_room_assembly: bool = false
@export var assembly_child_mode: bool = false
# Keep combat out of graybox traversal until the world routes have passed map acceptance.
# 世界路线完成实机验收前，灰盒探索默认不生成敌人。
@export var enable_region_encounters: bool = false

var hero: CharacterBody2D
var camera: Camera2D
var narrative: CanvasLayer
var hud: CanvasLayer
var platforms: Array[Rect2] = []
var a5_room_blocks: Array[Rect2] = []
var a5_room_floor_gaps: Array[Vector2] = []
var a5_room_floor_segments: Array[Vector2] = []
# Debug-only route markers make every authored exit and resonance gate obvious during graybox iteration.
# 灰盒开发阶段专用的路线标记：明确显示每个实体出口与灵视入口，正式导出版本不绘制。
var debug_exit_markers: Array[Dictionary] = []
var respawning := false
var a6_bell_shortcut_spawned := false
var a5_assembled_rooms: Dictionary = {}
var a5_internal_transition_cooldown := 0.0
var a5_last_route_visual_state := ""
var a5_internal_connection_visuals: Array[Dictionary] = []

func _ready() -> void:
	if assembly_child_mode:
		_ready_a5_assembly_child()
		return
	WorldState.prepare_scene_runtime()
	if region_id == "A5" and use_a5_room_assembly:
		_ready_a5_assembled_region()
		return
	if region_id == "A5" and not room_id.is_empty():
		_ready_a5_room_test()
		return
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

	# Configure authored ledges before creating the floor so A2's pit ledges remain in the
	# shared platform list used by the renderer; _configure_platforms() clears that list.
	# 先登记平台，再建立地面：_configure_platforms() 会清空绘制列表，顺序错误会让坑底碰撞存在但平台不绘制。
	_configure_platforms()
	_create_floor()
	_create_boundaries()
	_spawn_region_ambience()
	# Spawn the local bridge before the Hero so its visual is drawn behind the character.
	# 局部桥先于主角生成，确保桥体绘制在角色后方。
	_spawn_local_resonance_routes()
	_spawn_hero(_spawn_x_for_side(spawn_side), _spawn_y_for_side(spawn_side))
	print("[NEREIS][MAP][SPAWN] region=%s location=%s side=%s x=%.1f y=%.1f resume_side=%s" % [region_id, location_id, spawn_side, hero.position.x, hero.position.y, WorldState.resume_spawn_side])
	_spawn_ui()
	_spawn_region_sources()
	_spawn_region_item_pickups()
	_spawn_region_exits()
	_register_debug_locked_route_hints()
	_spawn_region_rest_point()
	if enable_region_encounters:
		_spawn_region_encounters()
	else:
		print("[NEREIS][MAP][GRAYBOX] encounters disabled until map layout acceptance region=%s" % region_id)
	queue_redraw()

	var intro_id := "graybox_intro_%s" % location_id
	if intro_id not in WorldState.achievement_flags:
		# Keep this persisted marker as proof of actual region entry for A1 return dialogue.
		# 保留真实进入标记，供 A1 回访对白使用；它不再强制等同于“首次进入就弹剧情”。
		WorldState.record_achievement(intro_id)
		# A2/A3 already contain inspectable bell/street evidence and route items. Let players discover them in-world
		# instead of pausing the first traversal with text that merely describes visible scenery.
		# A2/A3 已有可调查的钟、路牌与路线物品；不再用首次进入弹窗替代玩家主动发现。
		if not WorldState.debug_map_test_mode and region_id not in ["A2", "A3"]:
			get_tree().create_timer(0.55).timeout.connect(_show_intro)

func _unhandled_input(event: InputEvent) -> void:
	if WorldState.debug_map_test_mode and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://scenes/world_map_test_menu.tscn")

func _process(delta: float) -> void:
	a5_internal_transition_cooldown = maxf(0.0, a5_internal_transition_cooldown - delta)
	if use_a5_room_assembly:
		var visual_state := "%s|%d|%s" % [
			str(WorldState.resonance_sight_active), WorldState.hero_resonance,
			str(WorldState.opened_hidden_paths)
		]
		if visual_state != a5_last_route_visual_state:
			a5_last_route_visual_state = visual_state
			_refresh_a5_internal_connection_visuals()
			queue_redraw()
	_refresh_a6_bell_shortcut()
	# C21 can become valid after examining A11's own observer anomaly; do not freeze its state at scene entry.
	_refresh_a11_ending_route()
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
			if "defeated_A2_Cultist_01" not in WorldState.achievement_flags:
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
			if "defeated_A6_BellWarden_01" not in WorldState.achievement_flags:
				_spawn_encounter(CHURCH_INQUISITOR_SCRIPT, "A6_BellWarden_01", 1940.0, 17.0, 48.0)
		"A7":
			_spawn_encounter(RESEARCH_HUSK_SCRIPT, "A7_ResearchHusk_01", 1750.0, 14.0, 42.0)
		"A8":
			_spawn_encounter(CULTIST_SCRIPT, "A8_Cultist_01", 850.0, 13.0, 38.0)
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
		# Record the combat fact only. The meaning of the sound is left to environmental discovery
		# and the later physical return to A1; do not force an explanatory narrative panel here.
		# 这里只记录战斗事实；异常含义交给环境探索和之后实际回村的变化，不强制弹出解释面板。
		WorldState.record_achievement("defeated_mad_cleric")
	elif enemy_name == "A6_BellWarden_01":
		if WorldState.record_achievement("defeated_A6_BellWarden_01"):
			_spawn_world_item_pickup(
				"combat_reward_a6_bell_winch_key",
				"bell_tower_winch_key",
				"BellTowerWinchKey",
				enemy_node.global_position + Vector2(0.0, -40.0)
			)
			if is_instance_valid(narrative):
				narrative.show_message(
					"钟塔绞盘钥匙",
					"守卫身上的钥匙没有对应任何牢门。它的齿口沾着新鲜的润滑脂，形状与钟塔落差口旁的绞盘锁完全吻合。",
					5.5
				)
	elif enemy_name == "A2_Cultist_01":
		if WorldState.record_achievement("defeated_A2_Cultist_01"):
			_spawn_world_item_pickup(
				"combat_reward_a2_cultist_seal",
				"charred_church_seal",
				"CharredChurchSeal",
				enemy_node.global_position + Vector2(0.0, -40.0)
			)
			if is_instance_valid(narrative):
				narrative.show_message(
					"烧黑的封条",
					"薄铜片上的教会印记已经烧黑。反面刻着一串编号，末尾的符号与林中路标上的刻痕相同。",
					5.0
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
	if region_id == "A10" and side == "cathedral_roof":
		return floor_y - 180.0
	if region_id == "A9" and side == "cathedral_roof_return":
		return floor_y - 180.0
	# Elevated cross-region doors must land on their matching ledge, not underneath it on the continuous floor.
	# 高位跨区门应将主角送到对应栈台，而不是落在连续地面上、再要求玩家反向跳回门口。
	if region_id == "A3" and side == "city_highroad_return":
		return floor_y - 130.0
	if region_id == "A3" and side == "city_canopy_entry":
		return floor_y - 130.0
	if region_id == "A5" and side == "city_highroad":
		return floor_y - 130.0
	if region_id == "A6" and side == "battlefield_entry":
		return floor_y - 90.0
	# C13 connects the prison maintenance shaft and the royal-tomb entry platform above floor level.
	# C13 必须在监牢维护竖井与王墓入口平台之间保持高位双向转场。
	if region_id == "A8" and side == "maintenance_shaft_entry":
		return floor_y - 160.0
	if region_id == "A7" and side == "maintenance_shaft_return":
		return floor_y - 160.0
	if region_id == "A5" and side == "monastery_return":
		return floor_y - 55.0
	if region_id == "A2" and side == "east":
		return floor_y - 140.0
	# C04 must return to the actual old-pilgrim upper route on both sides.
	# C04 双向回程都必须落在旧朝圣高路的实际上层平台。
	if region_id == "A2" and side == "old_pilgrim_highroad":
		return floor_y - 140.0
	if region_id == "A5" and side == "old_pilgrim_highroad":
		# C04 lands on the elevated winch platform, not the trench floor.
		# C04落在高位绞盘平台，而不是战壕地面。
		return floor_y - 250.0
	if region_id == "A6" and side == "bell_drop":
		return floor_y - 90.0
	if region_id == "A9" and side == "old_lift":
		return floor_y - 110.0
	if region_id == "A9" and side == "royal_drain":
		return floor_y - 150.0
	if region_id == "A3" and side == "sewer":
		return floor_y - 115.0
	if region_id == "A4" and side == "sewer_upper":
		# The Hero origin is at the feet; align the spawn exactly with the landing y=445 collision top.
		# 主角坐标位于脚底；出生高度应与 y=445 的实体平台顶面精确对齐。
		return floor_y - 95.0
	if region_id == "A3" and side == "old_lift":
		return floor_y - 70.0
	if region_id == "A4" and side == "prison_tunnel":
		return floor_y - 75.0
	if region_id == "A4" and side == "royal_tomb_waterway":
		return floor_y - 85.0
	if region_id == "A8" and side == "royal_tomb_waterway":
		return floor_y - 165.0
	if region_id == "A4" and side == "royal_drain":
		return floor_y - 120.0
	return floor_y


func _spawn_x_for_side(side: String) -> float:
	if region_id == "A8" and side == "boss_return":
		# Return from the optional arena between its entrance and H06, clear of both interaction volumes.
		# 从可选 Boss 内殿返回时，落在入口与 H06 之间的安全走廊。
		return 1700.0
	if region_id == "A10" and side == "cathedral_roof":
		return 180.0
	if region_id == "A3" and side == "city_canopy_entry":
		return 180.0
	if region_id == "A9" and side == "cathedral_roof_return":
		# C17 returns beyond the roof door's trigger on an extended upper landing.
		# C17 回程落在延长后的上层平台远端，避开屋顶门的触发区。
		return 2450.0
	if region_id == "A6" and side == "bell_drop":
		# C10 returns to the upper landing before the final step down to the elevated shortcut door.
		# C10 回程落在高位落脚平台，再走到低一级的捷径门。
		return 2100.0
	if region_id == "A2" and side == "east":
		# C03 returns near the remote eastern exit on a supported upper landing.
		# C03 回程落在扩建森林东侧出口附近的实体高台。
		return 3220.0
	if region_id == "H09" and side == "east":
		return map_width - 280.0
	if region_id == "A9" and side == "mirror":
		return 1680.0
	if region_id == "A3" and side == "city_highroad_return":
		# C08 returns to the A3 upper parapet, clear of the door trigger and supported by its extended ledge.
		# C08 回到 A3 残墙高台，避开门触发区，并落在延长后的平台范围内。
		return 2360.0
	if region_id == "A5" and side == "city_highroad":
		# C08 enters the battlefield on its paired upper landing, not on the ground below the door.
		# C08 从城区进入战场时落在对应高台，而不是门下方的地面。
		return 330.0
	if region_id == "A6" and side == "battlefield_entry":
		# C09 enters the monastery on the upper west bridge, matching the authored route layer.
		# C09 从西侧上层廊桥进入修道院，与路线层合同保持一致。
		return 160.0
	if region_id == "A8" and side == "maintenance_shaft_entry":
		# C13 arrives clear of A8's west-side return trigger on the supported upper tomb platform.
		# C13 落在王墓西侧的实体高台上，并与返回门触发区保持净距。
		return 190.0
	if region_id == "A7" and side == "maintenance_shaft_return":
		# Keep the return landing on the upper prison ledge and at least 160px from the east door center.
		# 回程出生在监牢上层平台，并与东侧门中心保持至少 160px 距离，避免切图后立即获得门焦点。
		return map_width - 260.0
	if region_id == "A5" and side == "monastery_return":
		# C09 returns to the lower approach ledge, not the floor beneath the upper parapet door.
		# C09 回到较低的接近栈台，而不是高位门下方的地面。
		return 5050.0
	if region_id == "A3" and side == "village_city_cut":
		# C24's return door is at x=520; balance the landing between it and the anomaly at x=900.
		# C24 回程门位于 x=520；出生点在回程门与 x=900 异常源之间保持安全距离。
		return 700.0
	if region_id == "A4" and side == "old_drain_link":
		# The return from the drain gate lands on a clear reservoir-floor stretch.
		# 从旧排水闸门返回时，落在远离 C05 与其他门触发区的水库地面。
		return 820.0
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
		# C04 arrives exactly on the x=1740-1850 platform top and remains outside the return-door trigger.
		# C04 精确出生在 x=1740–1850 平台顶面，并避开回程门触发区。
		return 1750.0
	if region_id == "A5" and side == "old_pilgrim_highroad":
		# C04 optional winch branch is at x=3900; arrive on its supported upper landing.
		# C04可选绞盘支路位于x=3900；从A2返回时落在有承托的高台。
		return 3820.0
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
		# H01 returns between the C06 watergate at x=2220 and the hidden-well gate at map_width-90.
		# H01 回程落在 x=2220 的 C06 水闸与 map_width-90 的隐藏井门之间，避开两端交互区。
		return map_width - 220.0
	if region_id == "A4" and side == "prison_tunnel":
		# C12 arrives on the low ledge 90px away from its own return door.
		# C12 出生在低位栈台上，距回程门 90px，避免落地立即重新触发。
		return 960.0
	if region_id == "A4" and side == "royal_tomb_waterway":
		# C07's door is at x=1320; land on the far end of the same ledge, outside its trigger.
		# C07 门位于 x=1320；出生在同一栈台远端，避开门的实体触发区。
		return 1410.0
	if region_id == "A4" and side == "royal_drain":
		# C23 lands on the lower support lip at x=1540, with extra clearance from the x=1650 door trigger.
		# C23 落在 x=1540 的下层承托边沿，与 x=1650 的门触发区留出更充足净距。
		return 1540.0
	if region_id == "A9" and side == "old_lift":
		# C16's upper door is at x=520; land on the same ledge without overlapping the door focus.
		# C16 高位门位于 x=520；落在同一栈台并避开门的交互焦点。
		return 610.0
	if region_id == "A9" and side == "royal_drain":
		# C23's door is at x=740; land at x=650 on the same supported ledge, clear of C16 and C18.
		# C23 门移至 x=740；落点 x=650 与门保持净距，并避开 C16 与 C18。
		return 650.0
	if region_id == "A9" and side == "inner_city_side_gate":
		# C18 lands outside the x=900 door trigger and just beyond the x=1100 rest point's 110px focus radius.
		# C18 出生点避开 x=900 门触发区，并位于 x=1100 休整点的 110px 交互半径之外。
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
		# Keep the H05 return more than 110px from the monastery rest point at x=1300.
		# H05 回程点与修道院 x=1300 休整点保持超过 110px 的净距。
		return 1420.0
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
	camera.limit_bottom = int(room_height) if region_id == "A5" and not room_id.is_empty() else (1000 if region_id == "A2" else 720)
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


func _spawn_region_item_pickups() -> void:
	# Exploration rewards are placed on existing upper-route landings; they do not block the safe ground route.
	# 探索奖励放在现有上层路线的落脚点上，不封锁安全地面主路。
	var placements: Array[Dictionary] = []
	match region_id:
		"A2":
			placements.append({
				"pickup_id": "map_reward_old_pilgrim_waybill",
				"item_id": "old_pilgrim_waybill",
				"node_name": "OldPilgrimWaybill",
				"position": Vector2(1550.0, 282.0)
			})
			placements.append({
				"pickup_id": "exploration_reward_bellgrave_burial_token",
				"item_id": "bellgrave_burial_token",
				"node_name": "BellgraveBurialToken",
				"position": Vector2(965.0, 625.0)
			})
			placements.append({
				"pickup_id": "exploration_reward_canopy_waymarker_fragment",
				"item_id": "canopy_waymarker_fragment",
				"node_name": "CanopyWaymarkerFragment",
				"position": Vector2(3105.0, 300.0)
			})
			if "defeated_A2_Cultist_01" in WorldState.achievement_flags:
				placements.append({
					"pickup_id": "combat_reward_a2_cultist_seal",
					"item_id": "charred_church_seal",
					"node_name": "CharredChurchSeal",
					"position": Vector2(1750.0, floor_y - 40.0)
				})
		"A3":
			placements.append({
				"pickup_id": "map_reward_third_street_survey",
				"item_id": "third_street_survey",
				"node_name": "ThirdStreetSurvey",
				"position": Vector2(740.0, 282.0)
			})
		"A6":
			if "defeated_A6_BellWarden_01" in WorldState.achievement_flags:
				placements.append({
					"pickup_id": "combat_reward_a6_bell_winch_key",
					"item_id": "bell_tower_winch_key",
					"node_name": "BellTowerWinchKey",
					"position": Vector2(1940.0, floor_y - 40.0)
				})
		"A8":
			placements.append({
				"pickup_id": "map_reward_royal_mortuary_register",
				"item_id": "royal_mortuary_register",
				"node_name": "RoyalMortuaryRegister",
				"position": Vector2(1290.0, 282.0)
			})

	for placement in placements:
		_spawn_world_item_pickup(
			str(placement.get("pickup_id", "")),
			str(placement.get("item_id", "")),
			str(placement.get("node_name", "RegionItemPickup")),
			placement.get("position", Vector2.ZERO)
		)


func _spawn_world_item_pickup(pickup_id: String, item_id: String, node_name: String, pickup_position: Vector2) -> void:
	if pickup_id.is_empty() or pickup_id in WorldState.collected_world_item_ids:
		return
	var pickup := Node2D.new()
	pickup.set_script(WORLD_ITEM_PICKUP_SCRIPT)
	pickup.name = node_name
	pickup.position = pickup_position
	pickup.set("pickup_id", pickup_id)
	pickup.set("item_id", item_id)
	pickup.set("prompt_text", "E  拾取")
	add_child(pickup)


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
	if assembly_child_mode:
		_configure_a5_room_floor()
		return
	if region_id == "A5" and not room_id.is_empty():
		_configure_a5_room_floor()
		return
	# A2's Bell Grave is a real opening in the ground collision, not just a label or background drawing.
	# A2 钟墓必须是真正切开地面碰撞的坑口，而不只是地图标签或背景图案。
	if region_id == "A2":
		_add_ground_segment("GreyboxGround_West", 0.0, 860.0)
		_add_ground_segment("GreyboxGround_Middle", 1060.0, 1360.0)
		# The eastern ravine separates the expanded forest from the remote canopy exit.
		# 东部沟壑将扩建林地与远端树冠出口分开。
		_add_ground_segment("GreyboxGround_East", 2660.0, map_width - 2660.0)
		# Bell Grave descends below the surface into a real undercroft with staggered exit shelves.
		_add_platform(Rect2(860.0, floor_y + 125.0, 200.0, 18.0))
		_add_platform(Rect2(850.0, floor_y + 78.0, 70.0, 12.0))
		_add_platform(Rect2(1000.0, floor_y + 45.0, 70.0, 12.0))
		_add_platform(Rect2(900.0, floor_y + 5.0, 75.0, 12.0))
		# The eastern ravine is a deep cut: lower shelves make a second route under the high bridge.
		_add_platform(Rect2(2420.0, floor_y + 125.0, 240.0, 18.0))
		_add_platform(Rect2(2400.0, floor_y + 78.0, 70.0, 12.0))
		_add_platform(Rect2(2590.0, floor_y + 45.0, 70.0, 12.0))
		_add_platform(Rect2(2490.0, floor_y + 5.0, 80.0, 12.0))
		return
	# Selected regions use real floor cuts with lower shelves, not platforms buried inside a solid floor.
	# 指定区域使用真实地面断口与下层石沿，避免把平台埋在完整地面碰撞体里。
	var floor_gap := Vector2(-1.0, -1.0)
	match region_id:
		"A1":
			floor_gap = Vector2(620.0, 1140.0) # Village well and lower return shelves.
		"A3":
			floor_gap = Vector2(820.0, 1240.0) # City sewer descent and rooftop bypass.
		"A4":
			floor_gap = Vector2(780.0, 1280.0) # Reservoir undercroft.
		"A5":
			floor_gap = Vector2(820.0, 1320.0) # Battlefield trench.
		"A6":
			floor_gap = Vector2(1380.0, 1770.0) # Bell tower lower cloister.
		"A7":
			floor_gap = Vector2(800.0, 1300.0) # Prison maintenance drop.
		"A8":
			floor_gap = Vector2(1350.0, 1780.0) # Royal tomb lower crypt.
		"A9":
			floor_gap = Vector2(1350.0, 1780.0) # Outer ring undercroft.
		"A10":
			floor_gap = Vector2(1350.0, 1770.0) # Cathedral lower gallery.
		"A11":
			floor_gap = Vector2(1350.0, 1770.0) # Ancient ruin undercroft.
		"A12":
			floor_gap = Vector2(800.0, 1300.0) # Foundations beneath the crown wall.
		"A13":
			floor_gap = Vector2(850.0, 1350.0) # Final descent beneath the ending ascent.
		"H01", "H02", "H03", "H04", "H05", "H06", "H07", "H08", "H09":
			floor_gap = Vector2(760.0, 1160.0) # Hidden-region lower route beneath the secret chamber.
	if floor_gap.x >= 0.0 and floor_gap.y > floor_gap.x and floor_gap.y < map_width:
		_add_ground_segment("GreyboxGround_West", 0.0, floor_gap.x)
		_add_ground_segment("GreyboxGround_East", floor_gap.y, map_width - floor_gap.y)
		return
	_add_ground_segment("GreyboxGround", 0.0, map_width)


func _add_ground_segment(segment_name: String, start_x: float, segment_width: float) -> void:
	if segment_width <= 0.0:
		return
	var floor := StaticBody2D.new()
	floor.name = segment_name
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(segment_width, 40.0)
	shape.shape = rectangle
	shape.position = Vector2(segment_width * 0.5, floor_y + 20.0)
	floor.add_child(shape)
	floor.position.x = start_x
	add_child(floor)

func _create_boundaries() -> void:
	if assembly_child_mode:
		return
	for x in [-20.0, map_width + 20.0]:
		var wall := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(40.0, maxf(1100.0, room_height + 400.0 if region_id == "A5" and not room_id.is_empty() else 1100.0))
		shape.shape = rectangle
		shape.position = Vector2(x, (room_height + 200.0) * 0.5 if region_id == "A5" and not room_id.is_empty() else 500.0)
		wall.add_child(shape)
		add_child(wall)


func _ready_a5_assembly_child() -> void:
	# Child rooms contribute only authored geometry and atmosphere drawing. The assembled root owns
	# the single Hero, camera, HUD, region state, exits and save/respawn lifecycle.
	# 组装子房间只提供合同定义的地形碰撞与绘制；主场景统一管理主角、镜头、HUD、出口和存档。
	a5_room_blocks.clear()
	a5_room_floor_gaps.clear()
	a5_room_floor_segments.clear()
	floor_y = maxf(540.0, room_height - 180.0)
	_configure_platforms()
	_create_floor()
	_configure_a5_room_blocks()
	queue_redraw()


func _ready_a5_assembled_region() -> void:
	var spawn_side := WorldState.pending_region_spawn_side
	WorldState.set_location(location_id)
	WorldState.pending_region_spawn_side = "west"
	var contract_path := "res://tools/a5_room_assembly_contract.json"
	if not FileAccess.file_exists(contract_path):
		push_error("[NEREIS][A5_ASSEMBLY] Missing room assembly contract: " + contract_path)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(contract_path))
	if not parsed is Dictionary or not parsed.get("rooms", []) is Array:
		push_error("[NEREIS][A5_ASSEMBLY] Invalid room assembly contract JSON")
		return
	var rooms: Array = parsed.get("rooms", [])
	var room_by_id: Dictionary = {}
	a5_assembled_rooms.clear()
	var max_right := 0.0
	var min_top := 0.0
	var max_bottom := 0.0
	for room_data in rooms:
		if not room_data is Dictionary:
			continue
		var room_scene_path := str(room_data.get("scene_path", ""))
		var room_position: Array = room_data.get("position_screens", [0, 0])
		var room_size: Array = room_data.get("size_screens", [1, 1])
		if room_position.size() != 2 or room_size.size() != 2:
			push_error("[NEREIS][A5_ASSEMBLY] Invalid room placement: " + str(room_data.get("id", "?")))
			return
		var packed := load(room_scene_path) as PackedScene
		if packed == null:
			push_error("[NEREIS][A5_ASSEMBLY] Cannot load room scene: " + room_scene_path)
			return
		var room := packed.instantiate() as Node2D
		if room == null:
			push_error("[NEREIS][A5_ASSEMBLY] Room root is not Node2D: " + room_scene_path)
			return
		room.set("assembly_child_mode", true)
		room.set("map_width", float(room_size[0]) * 1280.0)
		room.set("room_height", float(room_size[1]) * 720.0)
		room.set("floor_y", maxf(540.0, float(room_size[1]) * 720.0 - 180.0))
		room.position = Vector2(float(room_position[0]) * 1280.0, float(room_position[1]) * 720.0)
		room.name = str(room_data.get("id", "A5Room")).replace("-", "_")
		add_child(room)
		room_by_id[str(room_data.get("id", ""))] = room
		max_right = maxf(max_right, room.position.x + float(room_size[0]) * 1280.0)
		min_top = minf(min_top, room.position.y)
		max_bottom = maxf(max_bottom, room.position.y + float(room_size[1]) * 720.0)
	if room_by_id.size() != rooms.size():
		push_error("[NEREIS][A5_ASSEMBLY] Not all room scenes were instantiated")
		return
	# The proposed screen grid deliberately uses negative Y for upper branches.
	# Normalize every room into the assembled map's local positive coordinate space;
	# otherwise upper rooms sit above camera.limit_top and can be clipped or unreachable.
	# 房间合同用负 Y 表示高层；组装时统一平移到地图局部正坐标，避免高层跑到镜头上边界之外。
	var vertical_offset := -min_top
	if not is_zero_approx(vertical_offset):
		for room_value in room_by_id.values():
			var placed_room := room_value as Node2D
			if placed_room != null:
				placed_room.position.y += vertical_offset
	a5_assembled_rooms = room_by_id
	map_width = max_right
	room_height = max_bottom - min_top
	floor_y = max_bottom - min_top - 180.0
	# The R01 room is the only spawn authority. Keep all child rooms geometry-only to avoid duplicate Heroes.
	var entry_room: Node2D = room_by_id.get("A5-R01")
	if entry_room == null:
		push_error("[NEREIS][A5_ASSEMBLY] Contract has no A5-R01 entry room")
		return
	_spawn_region_ambience()
	var assembled_spawn := _a5_assembled_spawn_for_side(spawn_side, entry_room)
	_spawn_hero(assembled_spawn.x, assembled_spawn.y)
	_spawn_ui()
	_spawn_region_exits()
	_spawn_a5_internal_connections(parsed.get("connections", []))
	_register_debug_locked_route_hints()
	_spawn_region_rest_point()
	queue_redraw()
	print("[NEREIS][A5_ASSEMBLY] rooms=%d internal_connections=%d bounds=%.0fx%.0f contract=%s" % [
		room_by_id.size(), get_tree().get_nodes_in_group("a5_internal_connection_door").size(),
		map_width, room_height, contract_path
	])


func _spawn_a5_internal_connections(raw_connections: Array) -> void:
	# Each contract edge gets a real interaction portal at both ends. This keeps
	# every authored room reachable without pretending that distant room rectangles
	# physically touch in the macro grid.
	# 合同中的每条边都生成真实交互门；即使宏观房间不直接相邻，也能在同一张地图内连续探索。
	var spawned_endpoints := 0
	var endpoint_slots: Dictionary = {}
	for edge_variant in raw_connections:
		if not edge_variant is Dictionary:
			continue
		var edge: Dictionary = edge_variant
		var from_id := str(edge.get("from", ""))
		var to_id := str(edge.get("to", ""))
		var from_room := _get_a5_assembled_room(from_id)
		var to_room := _get_a5_assembled_room(to_id)
		if from_room == null or to_room == null:
			push_error("[NEREIS][A5_ASSEMBLY] Connection %s references missing room %s -> %s" % [
				str(edge.get("id", "?")), from_id, to_id
			])
			continue
		var edge_id := str(edge.get("id", "A5-UNKNOWN"))
		var from_anchor := _a5_connection_anchor(from_room, to_room, endpoint_slots, from_id)
		var to_anchor := _a5_connection_anchor(to_room, from_room, endpoint_slots, to_id)
		_spawn_a5_internal_door(
			edge, from_id, to_id, from_room.position + from_anchor, to_room.position + to_anchor, false
		)
		spawned_endpoints += 1
		if str(edge.get("travel", "both")) != "one_way":
			_spawn_a5_internal_door(
				edge, to_id, from_id, to_room.position + to_anchor, from_room.position + from_anchor, true
			)
			spawned_endpoints += 1
		print("[NEREIS][A5_CONNECTION] id=%s %s -> %s kind=%s state=%s endpoints=%d" % [
			edge_id, from_id, to_id, str(edge.get("kind", "walk")),
			str(edge.get("initial_state", "open")), 1 if str(edge.get("travel", "both")) == "one_way" else 2
		])
	set_meta("a5_internal_connection_endpoint_count", spawned_endpoints)


func _a5_connection_anchor(
	source_room: Node2D, target_room: Node2D, endpoint_slots: Dictionary, source_id: String
) -> Vector2:
	var source_width := float(source_room.get("map_width"))
	var source_height := float(source_room.get("room_height"))
	var source_floor := float(source_room.get("floor_y"))
	var source_center := source_room.position.x + source_width * 0.5
	var target_center := target_room.position.x + float(target_room.get("map_width")) * 0.5
	var target_floor_world := target_room.position.y + float(target_room.get("floor_y")) - 36.0
	var desired_local_y := clampf(
		target_floor_world - source_room.position.y, 36.0, minf(source_height - 36.0, source_floor - 36.0)
	)
	var side := "center"
	if target_center > source_center + 1.0:
		side = "right"
	elif target_center < source_center - 1.0:
		side = "left"

	var used_key := "%s:anchors" % source_id
	var used_positions: Array = endpoint_slots.get(used_key, [])
	var offsets: Array = [0.0, 150.0, -150.0, 300.0, -300.0, 450.0, -450.0]
	if side == "right":
		offsets = [0.0, -150.0, -300.0, 150.0, 300.0, -450.0, 450.0]
	elif side == "left":
		offsets = [0.0, 150.0, 300.0, -150.0, -300.0, 450.0, -450.0]

	# Choose a real platform near the target landing height. Candidate positions
	# are scored against already-used anchors so multiple exits never overlap.
	# 选择靠近目标落脚高度的真实平台，并避开同房间已经占用的出口锚点。
	var platform_values: Variant = source_room.get("platforms")
	var best_anchor := Vector2(source_width * 0.5, source_floor - 36.0)
	var best_score := INF
	if platform_values is Array:
		for platform_variant in platform_values:
			if not platform_variant is Rect2:
				continue
			var platform: Rect2 = platform_variant
			if platform.size.x < 100.0 or platform.position.y < 72.0:
				continue
			var left_limit := platform.position.x + 48.0
			var right_limit := platform.end.x - 48.0
			if right_limit < left_limit:
				continue
			var side_distance := 0.0
			match side:
				"right":
					side_distance = source_width - platform.end.x
				"left":
					side_distance = platform.position.x
				_:
					side_distance = absf(platform.get_center().x - source_width * 0.5)
			var candidate_y := platform.position.y - 36.0
			for offset in offsets:
				var preferred_x := source_width * 0.5
				match side:
					"right":
						preferred_x = minf(source_width - 120.0, right_limit)
					"left":
						preferred_x = maxf(120.0, left_limit)
					_:
						preferred_x = clampf(source_width * 0.5, left_limit, right_limit)
				var candidate_x := clampf(preferred_x + float(offset), left_limit, right_limit)
				var overlap_penalty := 0.0
				for used_variant in used_positions:
					if used_variant is Vector2 and Vector2(candidate_x, candidate_y).distance_to(used_variant) < 100.0:
						overlap_penalty += 10000.0
				var score := absf(candidate_y - desired_local_y) + side_distance * 0.3
				score += absf(candidate_x - preferred_x) * 0.1 + overlap_penalty
				if score < best_score:
					best_score = score
					best_anchor = Vector2(candidate_x, candidate_y)

	if best_score == INF:
		var fallback_x := source_width * 0.5
		if side == "right":
			fallback_x = source_width - 120.0
		elif side == "left":
			fallback_x = 120.0
		var fallback_y := clampf(source_floor - 36.0, 36.0, minf(source_height - 36.0, source_floor - 36.0))
		for offset in offsets:
			var candidate_x := clampf(fallback_x + float(offset), 72.0, maxf(72.0, source_width - 72.0))
			var candidate := Vector2(candidate_x, fallback_y)
			var overlap := false
			for used_variant in used_positions:
				if used_variant is Vector2 and candidate.distance_to(used_variant) < 100.0:
					overlap = true
					break
			if not overlap:
				best_anchor = candidate
				break

	used_positions.append(best_anchor)
	endpoint_slots[used_key] = used_positions
	return best_anchor


func _spawn_a5_internal_door(
	edge: Dictionary, from_id: String, to_id: String, anchor: Vector2,
	destination_anchor: Vector2, reverse_endpoint: bool
) -> void:
	var edge_id := str(edge.get("id", "A5-UNKNOWN"))
	var kind := str(edge.get("kind", "walk"))
	var initial_state := str(edge.get("initial_state", "open"))
	var door := Area2D.new()
	var requires_interaction := initial_state == "blocked"
	if requires_interaction:
		door.set_script(INTERACTION_DOOR_SCRIPT)
	else:
		# Open room links trigger when the Hero crosses the doorway, like a room-based
		# metroidvania; only locked shortcuts and secret gates require pressing E.
		# 已开放的房间连接在主角穿过门洞时自动转场；只有锁闭捷径/隐藏门需要按 E。
		door.collision_layer = 8
		door.collision_mask = 1
		door.monitoring = true
	door.name = "A5Door_%s_%s" % [edge_id.replace("-", "_"), from_id.replace("-", "_")]
	door.position = anchor
	if requires_interaction:
		door.prompt_text = _a5_connection_prompt(kind, initial_state, edge_id)
	door.set_meta("a5_internal_connection_door", true)
	door.set_meta("a5_connection_id", edge_id)
	door.set_meta("a5_connection_kind", kind)
	door.set_meta("a5_transition_mode", "interact" if requires_interaction else "auto")
	door.set_meta("a5_from_room", from_id)
	door.set_meta("a5_to_room", to_id)
	door.set_meta("a5_destination_anchor", destination_anchor)
	door.set_meta("a5_reverse_endpoint", reverse_endpoint)
	var marker_kind := "exit"
	if kind == "hidden" or kind == "resonance_shortcut":
		marker_kind = "secret"
	elif kind == "shortcut" or kind == "elevator":
		marker_kind = "shortcut"
	elif initial_state == "blocked":
		marker_kind = "locked"
	debug_exit_markers.append({
		"position": anchor,
		"visual_position": anchor + Vector2(0.0, 36.0),
		"label": "%s → %s" % [from_id, to_id],
		"kind": marker_kind,
		"condition": str(edge.get("unlock_condition", "")),
		"connection_id": edge_id,
		"connection_kind": kind
	})
	var visual := _create_a5_door_arch(anchor, marker_kind, door.name)
	if marker_kind == "secret":
		visual.visible = WorldState.is_hidden_path_opened(edge_id) or _a5_internal_connection_requirement_met(edge_id, kind, "")
		door.enabled = visual.visible
	a5_internal_connection_visuals.append({
		"visual": visual,
		"door": door,
		"connection_id": edge_id,
		"connection_kind": kind,
		"marker_kind": marker_kind
	})
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(108.0, 86.0) if requires_interaction else Vector2(76.0, 128.0)
	collision.shape = rectangle
	collision.position = Vector2(0.0, -34.0) if requires_interaction else Vector2(0.0, -64.0)
	door.add_child(collision)
	add_child(door)
	door.add_to_group("a5_internal_connection_door")
	if requires_interaction:
		door.interacted.connect(_on_a5_internal_door_interacted.bind(
			edge.duplicate(true), from_id, to_id, destination_anchor, door
		))
	else:
		door.body_entered.connect(_on_a5_internal_auto_transition_body_entered.bind(
			edge.duplicate(true), from_id, to_id, destination_anchor, door
		))


func _create_a5_door_arch(anchor: Vector2, marker_kind: String, visual_id: String) -> Line2D:
	# This visual is a child of the assembled root, created after room scenes so it
	# renders above room backdrops rather than being painted over by child rooms.
	var arch := Line2D.new()
	arch.name = "A5DoorArch_%s" % visual_id.replace("-", "_").replace(" ", "_")
	arch.position = anchor + Vector2(0.0, 36.0)
	arch.width = 4.0
	arch.antialiased = true
	var tint := Color("#8eaa9a")
	if marker_kind == "shortcut":
		tint = Color("#d5b36b")
	elif marker_kind == "locked":
		tint = Color("#a47d86")
	elif marker_kind == "secret":
		tint = Color("#c6a0f6")
	tint.a = 0.72
	arch.default_color = tint
	for point in [
		Vector2(-27.0, 0.0), Vector2(-27.0, -46.0), Vector2(-20.0, -62.0),
		Vector2(-10.0, -72.0), Vector2(10.0, -72.0), Vector2(20.0, -62.0),
		Vector2(27.0, -46.0), Vector2(27.0, 0.0)
	]:
		arch.add_point(point)
	add_child(arch)
	return arch


func _refresh_a5_internal_connection_visuals() -> void:
	for visual_data in a5_internal_connection_visuals:
		var visual := visual_data.get("visual") as Line2D
		if visual == null or not is_instance_valid(visual):
			continue
		var marker_kind := str(visual_data.get("marker_kind", "exit"))
		if marker_kind != "secret":
			visual.visible = true
			continue
		var edge_id := str(visual_data.get("connection_id", ""))
		var edge_kind := str(visual_data.get("connection_kind", "hidden"))
		var revealed := WorldState.is_hidden_path_opened(edge_id) or _a5_internal_connection_requirement_met(edge_id, edge_kind, "")
		visual.visible = revealed
		var door := visual_data.get("door") as Area2D
		if door != null and is_instance_valid(door):
			door.enabled = revealed


func _a5_connection_prompt(kind: String, initial_state: String, _edge_id: String) -> String:
	if kind == "hidden" or kind == "resonance_shortcut":
		return "E  感知残响，探查隐藏通路"
	if kind == "ability_gate":
		return "E  检查封锁（需要特殊移动能力）"
	if initial_state == "blocked":
		return "E  检查并开启通路"
	if kind == "elevator":
		return "E  操作升降机"
	if kind == "ladder" or kind == "climb":
		return "E  攀上连接路线"
	if kind == "drop":
		return "E  沿落差进入相邻区域"
	return "E  进入相邻区域"


func _on_a5_internal_auto_transition_body_entered(
	body: Node2D, edge: Dictionary, from_id: String, to_id: String,
	destination_anchor: Vector2, _door: Area2D
) -> void:
	if body == hero and a5_internal_transition_cooldown <= 0.0:
		_traverse_a5_connection(edge, from_id, to_id, destination_anchor)


func _on_a5_internal_door_interacted(
	edge: Dictionary, from_id: String, to_id: String, destination_anchor: Vector2, door: Area2D
) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var edge_id := str(edge.get("id", "A5-UNKNOWN"))
	var kind := str(edge.get("kind", "walk"))
	var initial_state := str(edge.get("initial_state", "open"))
	var unlock_condition := str(edge.get("unlock_condition", ""))
	var opened := WorldState.is_hidden_path_opened(edge_id)
	if initial_state == "blocked" and not opened:
		if not _a5_internal_connection_requirement_met(edge_id, kind, unlock_condition):
			if is_instance_valid(door):
				door.prompt_text = _a5_connection_locked_prompt(edge_id, kind)
			print("[NEREIS][A5_CONNECTION][LOCKED] id=%s kind=%s resonance=%d sight=%s" % [
				edge_id, kind, WorldState.hero_resonance, str(WorldState.resonance_sight_active)
			])
			return
		WorldState.open_hidden_path(edge_id)
		if is_instance_valid(door):
			if edge_id == "A5-RESONANCE-01":
				door.prompt_text = "E  进入已显现的残响通路"
			else:
				door.prompt_text = "E  通路已开启，继续前进"
		print("[NEREIS][A5_CONNECTION][OPEN] id=%s from=%s to=%s" % [edge_id, from_id, to_id])
		return

	_traverse_a5_connection(edge, from_id, to_id, destination_anchor)


func _traverse_a5_connection(edge: Dictionary, from_id: String, to_id: String, destination_anchor: Vector2) -> void:
	if hero == null or not is_instance_valid(hero) or a5_internal_transition_cooldown > 0.0:
		return
	var edge_id := str(edge.get("id", "A5-UNKNOWN"))
	var destination := _get_a5_assembled_room(to_id)
	if destination == null:
		push_error("[NEREIS][A5_ASSEMBLY] Internal destination disappeared: " + to_id)
		return
	INTERACTION_FOCUS_SCRIPT.clear_all(get_tree())
	hero.velocity = Vector2.ZERO
	hero.global_position = to_global(destination_anchor)
	a5_internal_transition_cooldown = 0.45
	# Ensure the respawn/checkpoint system retains a valid world coordinate after room transition.
	if hero.has_method("reset_physics_interpolation"):
		hero.call("reset_physics_interpolation")
	print("[NEREIS][A5_CONNECTION][TRAVERSE] id=%s from=%s to=%s position=(%.1f,%.1f)" % [
		edge_id, from_id, to_id, hero.global_position.x, hero.global_position.y
	])


func _a5_internal_connection_requirement_met(edge_id: String, kind: String, _unlock_condition: String) -> bool:
	if kind == "resonance_shortcut" or edge_id == "A5-RESONANCE-01":
		return WorldState.resonance_sight_active and WorldState.hero_resonance >= 24
	if kind == "hidden":
		if edge_id == "A5-B02":
			return WorldState.resonance_sight_active
		if edge_id == "A5-B03":
			return WorldState.resonance_sight_active and WorldState.hero_resonance >= 24
		return WorldState.resonance_sight_active and WorldState.hero_resonance >= 12
	if kind == "ability_gate":
		return (
			WorldState.is_ability_unlocked("double_jump")
			or WorldState.is_ability_unlocked("quick_dash")
			or WorldState.is_ability_unlocked("grapple")
			or WorldState.is_ability_unlocked("wall_climb")
		)
	# Other blocked edges are physical mechanisms / shortcuts: E persistently opens them.
	return true


func _a5_connection_locked_prompt(edge_id: String, kind: String) -> String:
	if kind == "resonance_shortcut" or edge_id == "A5-RESONANCE-01":
		return "需要灵视与 24 点共鸣"
	if edge_id == "A5-B02":
		return "需要开启灵视"
	if edge_id == "A5-B03":
		return "需要灵视与 24 点共鸣"
	if edge_id == "A5-B01":
		return "需要灵视与 12 点共鸣"
	if kind == "ability_gate":
		return "需要二段跳、快速闪避、抓钩或攀墙能力"
	return "通路尚未开启"


func _a5_assembled_spawn_for_side(side: String, entry_room: Node2D) -> Vector2:
	# Cross-region doors must land on the matching room's supported ledge, not always
	# at R01. These are the assembled equivalents of the legacy C08/C09/C04 spawns.
	# 跨区回程必须落到对应房间的实体平台，不能无论从哪侧进入都送回 R01。
	var fallback := entry_room.position + Vector2(96.0, maxf(540.0, float(entry_room.get("room_height")) - 180.0) - 96.0)
	match side:
		"city_highroad":
			var entry := _get_a5_assembled_room("A5-R01")
			if entry != null:
				return entry.position + Vector2(330.0, 410.0)
		"monastery_return":
			var exit_room := _get_a5_assembled_room("A5-R20")
			if exit_room != null:
				return exit_room.position + Vector2(500.0, 365.0)
		"old_pilgrim_highroad":
			var winch_room := _get_a5_assembled_room("A5-R16")
			if winch_room != null:
				return winch_room.position + Vector2(820.0, 575.0)
		"bell_gate", "bell_tower_return":
			var hidden_room := _get_a5_assembled_room("A5-R14")
			if hidden_room != null:
				return hidden_room.position + Vector2(900.0, 430.0)
	return fallback


func _ready_a5_room_test() -> void:
	a5_room_blocks.clear()
	a5_room_floor_gaps.clear()
	a5_room_floor_segments.clear()
	# Tall test rooms use a bottom-anchored floor and a matching camera range.
	floor_y = maxf(540.0, room_height - 180.0)
	WorldState.set_location(location_id)
	WorldState.pending_region_spawn_side = "west"
	_configure_platforms()
	_create_floor()
	_create_boundaries()
	_configure_a5_room_blocks()
	_spawn_region_ambience()
	var start_position := Vector2(96.0, floor_y - 96.0)
	if room_id == "A5-R06":
		start_position = Vector2(380.0, 96.0)
	_spawn_hero(start_position.x, start_position.y)
	_spawn_ui()
	queue_redraw()
	print("[NEREIS][A5_ROOM_TEST] room=%s width=%.0f height=%.0f" % [room_id, map_width, room_height])


func _configure_a5_room_platforms() -> void:
	var specs: Array = []
	match room_id:
		"A5-R01":
			specs = [[70, 80, 300], [410, 80, 230], [690, 145, 190], [920, 85, 220], [1140, 70, 100]]
		"A5-R02":
			specs = [[70, 80, 320], [420, 80, 180], [650, 150, 200], [900, 155, 360], [1320, 100, 220], [1580, 70, 330], [1960, 85, 180], [2180, 145, 220], [2440, 80, 100]]
		"A5-R03":
			specs = [[70, 70, 300], [400, 70, 260], [710, 150, 230], [720, 230, 180], [960, 230, 180], [1000, 70, 300], [1330, 130, 240], [1640, 70, 280], [1980, 70, 400]]
		"A5-R04":
			specs = [[70, 70, 260], [360, 70, 160], [560, 130, 150], [760, 80, 170], [980, 155, 180], [1210, 75, 170], [1440, 135, 170], [1680, 70, 200], [1980, 70, 360]]
		"A5-R05":
			specs = [[100, 70, 300], [430, 145, 180], [700, 220, 300], [420, 295, 220], [100, 370, 260], [420, 445, 300], [760, 520, 180], [500, 595, 240], [180, 670, 300], [500, 745, 300], [820, 820, 180], [570, 895, 240], [260, 970, 300], [570, 1045, 300], [900, 1120, 260]]
		"A5-R06":
			specs = [[280, 1120, 260], [570, 1040, 220], [850, 960, 200], [1010, 880, 220], [760, 800, 280], [470, 720, 220], [170, 640, 260], [100, 560, 200], [350, 480, 280], [650, 400, 220], [900, 320, 260], [760, 240, 220], [520, 160, 220], [260, 90, 220], [650, 45, 300]]
		"A5-R07":
			specs = [[70, 25, 470], [570, 35, 210], [840, 85, 150], [680, 110, 140], [1010, 30, 190]]
		"A5-R08":
			specs = [[70, 70, 300], [410, 125, 190], [650, 70, 160], [850, 70, 250], [1140, 145, 200], [1400, 80, 190], [1650, 150, 210], [1920, 75, 200], [2180, 70, 300]]
		"A5-R09":
			specs = [[70, 40, 210], [320, 105, 160], [520, 165, 180], [760, 105, 230], [1030, 40, 180]]
		"A5-R10":
			specs = [[70, 70, 260], [300, 140, 260], [530, 210, 220], [760, 280, 220], [990, 350, 220], [1220, 420, 260], [1510, 490, 220], [1760, 560, 220], [2010, 630, 260], [2300, 700, 180], [2240, 780, 220], [1960, 850, 220], [1680, 920, 220], [1400, 990, 260], [1080, 1060, 220], [800, 1130, 220], [520, 1060, 220], [300, 990, 220], [520, 920, 220], [780, 850, 220]]
		"A5-R11":
			specs = [[70, 70, 280], [380, 145, 200], [630, 70, 280], [950, 145, 200], [1200, 70, 280], [1520, 145, 200], [1770, 70, 280], [2090, 145, 200], [2340, 70, 220]]
		"A5-R12":
			specs = [[70, 65, 300], [430, 70, 350], [840, 65, 300], [1180, 130, 200], [1430, 70, 300], [1780, 65, 300], [2130, 130, 200], [2300, 70, 180]]
		"A5-R13":
			specs = [[110, 70, 260], [420, 150, 200], [180, 230, 220], [420, 310, 220], [110, 390, 280], [420, 470, 220], [180, 550, 220], [420, 630, 260], [110, 710, 220], [420, 790, 220], [180, 870, 300], [500, 950, 220], [220, 1030, 220], [500, 1110, 260], [180, 1190, 220], [500, 1270, 220], [220, 1350, 300], [500, 1430, 220], [180, 1510, 220], [500, 1590, 260], [220, 1670, 220], [500, 1750, 220], [180, 1830, 300], [800, 550, 220], [820, 630, 220], [800, 710, 220], [820, 790, 220], [800, 870, 220], [900, 950, 220], [900, 1110, 220], [900, 1270, 220], [800, 1430, 220], [800, 1590, 220]]
		"A5-R14":
			specs = [[70, 25, 420], [520, 30, 220], [800, 75, 180], [590, 90, 150], [1000, 25, 190]]
		"A5-R15":
			specs = [[70, 145, 280], [390, 145, 220], [650, 80, 300], [1000, 80, 180], [1220, 160, 180], [1450, 160, 300], [1800, 90, 250], [2090, 90, 220], [2350, 145, 210]]
		"A5-R16":
			specs = [[100, 70, 280], [420, 145, 220], [150, 220, 220], [420, 295, 300], [120, 370, 220], [420, 445, 220], [150, 520, 280], [440, 595, 220], [150, 670, 220], [440, 745, 300], [150, 820, 220], [440, 895, 220], [150, 970, 280], [440, 1045, 220], [150, 1120, 300], [780, 650, 250], [820, 725, 250], [780, 800, 280], [980, 650, 220], [1000, 725, 220], [960, 800, 280]]
		"A5-R17":
			specs = [[70, 70, 300], [400, 145, 220], [700, 220, 220], [1000, 295, 220], [1300, 370, 260], [1650, 445, 220], [1950, 520, 220], [2200, 595, 260], [2160, 670, 220], [1840, 745, 220], [1540, 820, 260], [1220, 895, 220], [920, 970, 220], [620, 1045, 260], [300, 1120, 300]]
		"A5-R18":
			specs = [[70, 45, 330], [440, 45, 200], [680, 90, 170], [900, 45, 340], [1280, 45, 180], [1500, 95, 180], [1720, 45, 330], [2090, 45, 200], [2330, 85, 180]]
		"A5-R19":
			specs = [[70, 55, 230], [350, 125, 180], [590, 55, 220], [850, 125, 170], [1080, 55, 140]]
		"A5-R20":
			specs = [[70, 80, 260], [370, 140, 220], [630, 140, 260], [930, 80, 220], [1160, 70, 100]]
		"A5-R21":
			specs = [[70, 60, 260], [370, 60, 220], [630, 120, 220], [890, 180, 220], [1150, 240, 220], [1410, 300, 220], [1670, 360, 220], [1930, 420, 220], [2220, 480, 260], [2220, 390, 220], [1940, 330, 220], [1660, 270, 220], [1380, 210, 220], [1100, 150, 220], [820, 90, 220]]
		"A5-R22":
			specs = [[70, 25, 360], [480, 45, 190], [720, 100, 150], [920, 55, 150], [1080, 25, 130]]
		_:
			specs = [[100, 75, 200], [360, 130, 200], [620, 85, 200]]
	for spec in specs:
		_add_platform(Rect2(float(spec[0]), floor_y - float(spec[1]), float(spec[2]), 18.0))


func _configure_a5_room_blocks() -> void:
	var block_specs: Array = []
	match room_id:
		"A5-R01":
			block_specs = [[420, 32, 52, 32], [930, 48, 70, 48]]
		"A5-R02":
			block_specs = [[510, 36, 60, 36], [1510, 52, 75, 52], [2080, 30, 85, 30]]
		"A5-R03":
			block_specs = [[300, 42, 68, 42], [1320, 32, 58, 32], [2130, 50, 72, 50]]
		"A5-R04":
			block_specs = [[380, 55, 80, 55], [1370, 45, 90, 45], [2020, 58, 70, 58]]
		"A5-R05":
			block_specs = [[640, 180, 90, 85], [650, 590, 70, 75], [620, 950, 90, 80]]
		"A5-R06":
			block_specs = [[620, 250, 90, 80], [650, 610, 70, 75], [620, 930, 90, 80]]
		"A5-R07":
			block_specs = [[300, 32, 55, 32], [720, 48, 70, 48], [1000, 30, 45, 30]]
		"A5-R08":
			block_specs = [[500, 45, 78, 45], [1530, 56, 80, 56], [2130, 34, 60, 34]]
		"A5-R09":
			block_specs = [[290, 34, 56, 34], [900, 50, 68, 50]]
		"A5-R10":
			block_specs = [[500, 45, 75, 45], [1020, 56, 84, 56], [1740, 38, 90, 38], [2210, 50, 70, 50], [610, 470, 65, 70], [1890, 620, 60, 70]]
		"A5-R11":
			block_specs = [[520, 38, 65, 38], [1320, 55, 90, 55], [2100, 42, 75, 42]]
		"A5-R12":
			block_specs = [[370, 30, 60, 30], [910, 42, 70, 42], [1510, 34, 65, 34], [2080, 48, 72, 48]]
		"A5-R13":
			block_specs = [[600, 260, 55, 80], [590, 700, 55, 75], [600, 1180, 55, 80], [590, 1650, 55, 75]]
		"A5-R14":
			block_specs = [[270, 30, 52, 30], [650, 45, 66, 45], [900, 34, 55, 34]]
		"A5-R15":
			block_specs = [[490, 42, 70, 42], [1270, 53, 82, 53], [2050, 36, 68, 36]]
		"A5-R16":
			block_specs = [[600, 170, 80, 80], [620, 520, 75, 75], [610, 900, 80, 80]]
		"A5-R17":
			block_specs = [[520, 42, 75, 42], [1030, 54, 80, 54], [1540, 38, 90, 38], [2050, 50, 75, 50], [700, 510, 60, 70], [1860, 790, 65, 70]]
		"A5-R18":
			block_specs = [[320, 35, 70, 35], [1350, 52, 86, 52], [2110, 40, 75, 40]]
		"A5-R19":
			block_specs = [[280, 34, 60, 34], [730, 48, 72, 48]]
		"A5-R20":
			block_specs = [[300, 36, 70, 36], [850, 50, 70, 50]]
		"A5-R21":
			block_specs = [[500, 34, 70, 34], [1080, 54, 80, 54], [1830, 36, 72, 36], [1300, 440, 60, 60]]
		"A5-R22":
			block_specs = [[290, 32, 56, 32], [780, 45, 62, 45]]
		_:
			block_specs = [[420, 35, 60, 35]]
	for spec in block_specs:
		_add_a5_room_block(float(spec[0]), float(spec[1]), float(spec[2]), float(spec[3]))


func _add_a5_room_block(x: float, top_offset: float, block_width: float, block_height: float) -> void:
	var rect := Rect2(x, floor_y - top_offset, block_width, block_height)
	a5_room_blocks.append(rect)
	var body := StaticBody2D.new()
	body.name = "A5RoomRubble_%03d" % a5_room_blocks.size()
	body.position = rect.position
	var shape := CollisionShape2D.new()
	var collision := RectangleShape2D.new()
	collision.size = rect.size
	shape.shape = collision
	shape.position = rect.size * 0.5
	body.add_child(shape)
	add_child(body)


func _configure_a5_room_floor() -> void:
	var gaps: Array[Vector2] = []
	match room_id:
		"A5-R01":
			gaps = [Vector2(780, 80)]
		"A5-R02":
			gaps = [Vector2(850, 320)]
		"A5-R03":
			gaps = [Vector2(760, 240)]
		"A5-R04":
			gaps = [Vector2(590, 140), Vector2(1600, 120)]
		"A5-R05":
			# The one-way drop to R06 must pass through a real floor opening, not a trigger buried below solid ground.
			gaps = [Vector2(600, 120)]
		"A5-R06":
			gaps = []
		"A5-R07":
			gaps = []
		"A5-R08":
			gaps = [Vector2(980, 280)]
		"A5-R09":
			gaps = [Vector2(470, 100)]
		"A5-R10":
			gaps = [Vector2(800, 380), Vector2(1710, 130)]
		"A5-R11":
			gaps = [Vector2(900, 320)]
		"A5-R12":
			gaps = []
		"A5-R13":
			# The lower route to R15 exits through a real shaft opening.
			gaps = [Vector2(560, 120)]
		"A5-R14":
			gaps = []
		"A5-R15":
			gaps = [Vector2(720, 240)]
		"A5-R16":
			gaps = []
		"A5-R17":
			gaps = [Vector2(780, 520)]
		"A5-R18":
			gaps = [Vector2(760, 420)]
		"A5-R19":
			gaps = [Vector2(430, 160)]
		"A5-R20":
			gaps = []
		"A5-R21":
			gaps = [Vector2(840, 220)]
		"A5-R22":
			gaps = [Vector2(560, 120)]
		_:
			gaps = []
	a5_room_floor_gaps.clear()
	a5_room_floor_segments.clear()
	var cursor := 0.0
	var segment_index := 0
	for gap in gaps:
		var start_x := maxf(cursor, gap.x)
		if start_x > cursor:
			_add_a5_room_floor_segment(cursor, start_x - cursor, segment_index)
			segment_index += 1
		var gap_start := maxf(cursor, gap.x)
		var gap_end := minf(map_width, gap.x + gap.y)
		if gap_end > gap_start:
			a5_room_floor_gaps.append(Vector2(gap_start, gap_end - gap_start))
			cursor = gap_end
	if cursor < map_width:
		_add_a5_room_floor_segment(cursor, map_width - cursor, segment_index)


func _add_a5_room_floor_segment(start_x: float, segment_width: float, index: int) -> void:
	if segment_width <= 0.0:
		return
	a5_room_floor_segments.append(Vector2(start_x, segment_width))
	_add_ground_segment("A5RoomGround_%02d" % index, start_x, segment_width)


func _draw_a5_room_floor_gaps() -> void:
	for gap in a5_room_floor_gaps:
		draw_rect(Rect2(gap.x, floor_y - 1.0, gap.y, 300.0), Color("#171820"))
		draw_rect(Rect2(gap.x, floor_y - 1.0, 10.0, 150.0), Color("#51434a"))
		draw_rect(Rect2(gap.x + gap.y - 10.0, floor_y - 1.0, 10.0, 150.0), Color("#51434a"))




func _configure_platforms() -> void:
	platforms.clear()
	if (region_id == "A5" and not room_id.is_empty()) or assembly_child_mode:
		_configure_a5_room_platforms()
		return
	match region_id:
		"A0":
			# The prologue escape has a broken stair and a raised breach ledge, teaching layered traversal early.
			# 序章逃脱通道用断阶与高位破口，让玩家尽早理解分层路线。
			_add_platform(Rect2(180.0, floor_y - 75.0, 135.0, 18.0))
			_add_platform(Rect2(390.0, floor_y - 125.0, 115.0, 18.0))
			_add_platform(Rect2(570.0, floor_y - 175.0, 125.0, 18.0))
			_add_platform(Rect2(780.0, floor_y - 135.0, 130.0, 18.0))
			_add_platform(Rect2(1010.0, floor_y - 90.0, 150.0, 18.0))
		"A1":
			# A1 is the persistent hub: a surface lane, a well-side descent, and a broken roof loop.
			# A1 作为持续回访的枢纽：地表主路、井侧下沉路线与断裂屋顶回环并存。
			_add_platform(Rect2(170, 475, 150, 18))
			_add_platform(Rect2(390, 430, 130, 18))
			_add_platform(Rect2(610, 385, 145, 18))
			_add_platform(Rect2(840, 420, 135, 18))
			_add_platform(Rect2(1060, 465, 150, 18))
			_add_platform(Rect2(1320, 430, 145, 18))
			_add_platform(Rect2(1560, 390, 150, 18))
			_add_platform(Rect2(1800, 440, 150, 18))
			# Upper roofline loops back toward the well instead of forming a single dead-end ladder.
			_add_platform(Rect2(300, 395, 110, 18))
			_add_platform(Rect2(415, 350, 115, 18))
			_add_platform(Rect2(540, 310, 120, 18))
			_add_platform(Rect2(675, 330, 115, 18))
			_add_platform(Rect2(790, 370, 120, 18))
			_add_platform(Rect2(910, 330, 115, 18))
			_add_platform(Rect2(1030, 290, 120, 18))
			_add_platform(Rect2(1150, 325, 120, 18))
			_add_platform(Rect2(1270, 370, 115, 18))
			# A lower return shelf lets players recover from the well-side drop and rejoin the hub route.
			_add_platform(Rect2(650, floor_y + 90.0, 150, 18))
			_add_platform(Rect2(820, floor_y + 135.0, 150, 18))
			_add_platform(Rect2(990, floor_y + 90.0, 145, 18))
		"A2":
			# A2 is a vertically interlocked region, not a longer flat corridor.
			# A2 采用犬牙交错的上下层：主路会攀升、回落，再从另一侧绕回同一地标。
			# West root climb: jagged shelves climb into the first canopy.
			_add_platform(Rect2(300, 585, 120, 18))
			_add_platform(Rect2(430, 530, 110, 18))
			_add_platform(Rect2(555, 465, 115, 18))
			_add_platform(Rect2(690, 410, 105, 18))
			_add_platform(Rect2(770, 345, 105, 18))
			_add_platform(Rect2(900, 290, 120, 18))
			_add_platform(Rect2(1035, 235, 130, 18))
			_add_platform(Rect2(1175, 275, 115, 18))
			_add_platform(Rect2(1265, 345, 120, 18))
			_add_platform(Rect2(1380, 405, 130, 18))
			_add_platform(Rect2(1510, 465, 120, 18))
			_add_platform(Rect2(1630, 520, 135, 18))
			# Bell Grave outer gallery: an upper rim and a lower return skirt overlap vertically.
			_add_platform(Rect2(820, 470, 105, 18))
			_add_platform(Rect2(935, 420, 115, 18))
			_add_platform(Rect2(1060, 385, 120, 18))
			_add_platform(Rect2(1180, 430, 115, 18))
			_add_platform(Rect2(1290, 490, 125, 18))
			_add_platform(Rect2(760, 535, 100, 18))
			_add_platform(Rect2(910, 560, 110, 18))
			_add_platform(Rect2(1050, 535, 110, 18))
			_add_platform(Rect2(1190, 555, 115, 18))
			# A broken canopy bridge rises over the gallery, then descends behind its ribs.
			_add_platform(Rect2(850, 185, 115, 18))
			_add_platform(Rect2(985, 145, 125, 18))
			_add_platform(Rect2(1125, 175, 115, 18))
			_add_platform(Rect2(1245, 220, 115, 18))
			_add_platform(Rect2(1360, 285, 115, 18))
			_add_platform(Rect2(1475, 330, 120, 18))
			_add_platform(Rect2(1490, 405, 130, 18))
			# Central pilgrim ribs: upper crossing and lower shelves weave around one another.
			_add_platform(Rect2(1585, 365, 115, 18))
			_add_platform(Rect2(1710, 310, 120, 18))
			_add_platform(Rect2(1840, 270, 120, 18))
			_add_platform(Rect2(1970, 315, 115, 18))
			_add_platform(Rect2(2085, 375, 120, 18))
			_add_platform(Rect2(2185, 440, 115, 18))
			_add_platform(Rect2(1735, 430, 115, 18))
			_add_platform(Rect2(1850, 485, 115, 18))
			_add_platform(Rect2(1975, 525, 125, 18))
			_add_platform(Rect2(2100, 565, 120, 18))
			# C04 remains on a supported highroad shelf; the lower path can pass beneath it.
			_add_platform(Rect2(1740, 510, 125, 18))
			_add_platform(Rect2(1840, 535, 140, 18))
			_add_platform(Rect2(1975, 465, 115, 18))
			# Eastern ravine: an upper bridge and a deep underpass share the same footprint.
			_add_platform(Rect2(2250, 490, 115, 18))
			_add_platform(Rect2(2355, 425, 110, 18))
			_add_platform(Rect2(2465, 350, 115, 18))
			_add_platform(Rect2(2580, 300, 120, 18))
			_add_platform(Rect2(2695, 345, 115, 18))
			_add_platform(Rect2(2795, 410, 115, 18))
			_add_platform(Rect2(2895, 465, 115, 18))
			_add_platform(Rect2(2985, 400, 115, 18))
			_add_platform(Rect2(3075, 335, 115, 18))
			_add_platform(Rect2(3165, 390, 115, 18))
			_add_platform(Rect2(3220, 510, 130, 18))
			# C03's remote canopy exit has a real landing at the authored anchor height.
			_add_platform(Rect2(3335, 490, 145, 18))
			# A second, higher route crosses above the ravine and rejoins the exit approach.
			_add_platform(Rect2(2310, 250, 115, 18))
			_add_platform(Rect2(2435, 205, 115, 18))
			_add_platform(Rect2(2560, 165, 120, 18))
			_add_platform(Rect2(2685, 205, 115, 18))
			_add_platform(Rect2(2805, 260, 115, 18))
			_add_platform(Rect2(2925, 305, 115, 18))
			_add_platform(Rect2(3045, 270, 115, 18))
			_add_platform(Rect2(3155, 315, 115, 18))
		"A3":
			# Street-level route: rubble, market, sewer descent, and the battlefield road.
			# 地面主路连接碎墙、市场、下水道入口与战场方向。
			_add_platform(Rect2(300, 470, 170, 18))
			_add_platform(Rect2(600, 430, 110, 18))
			_add_platform(Rect2(850, 390, 180, 18))
			_add_platform(Rect2(1190, 465, 200, 18))
			_add_platform(Rect2(1540, 425, 150, 18))
			_add_platform(Rect2(1880, 470, 170, 18))
			# Extend the C08 landing so its reverse spawn has a safe, continuous upper ledge.
			# 延长 C08 落脚平台，确保反向回程出生点落在连续高台上。
			_add_platform(Rect2(2180, 410, 250, 18))
			# C03's west arrival/return is a real canopy landing, not a ground-level spawn below the route.
			# C03 西侧进出点使用实体树冠平台，避免高路转场后落回地面。
			_add_platform(Rect2(80, 410, 150, 18))
			# Optional rooftop loop rises above the erased third street, then descends to the sewer-side route.
			# 可选屋顶环路爬过被抹除的第三街，再下降接回下水道一侧的主路。
			_add_platform(Rect2(450, 400, 110, 18))
			_add_platform(Rect2(565, 355, 120, 18))
			_add_platform(Rect2(700, 310, 120, 18))
			_add_platform(Rect2(850, 300, 120, 18))
			_add_platform(Rect2(1000, 340, 120, 18))
			_add_platform(Rect2(1130, 390, 120, 18))
			_add_platform(Rect2(1320, 425, 130, 18))
			# The sewer descent is a real lower route beneath the rooftop loop, with shelves to climb back out.
			# 下水道入口下方存在真实下层通路，错层石沿可攀回屋顶环路。
			_add_platform(Rect2(850.0, floor_y + 90.0, 145.0, 18.0))
			_add_platform(Rect2(1015.0, floor_y + 135.0, 145.0, 18.0))
			_add_platform(Rect2(1180.0, floor_y + 90.0, 145.0, 18.0))
		"A4":
			# C05 arrival ledge: the raised city pipe-walk must connect to a supported upper inspection landing.
			# C05 到达平台：城区高架管线必须接入有实体承托的上层检查廊。
			_add_platform(Rect2(80, 445, 220, 18))
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
			# C23 return arrival is supported just left of the pipe door, not suspended over a gap.
			# C23 回程出生点由管线门左侧的实体栈台承托，避免悬空出生。
			_add_platform(Rect2(1530, 420, 70, 18))
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
			# The reservoir floor breaks into a stepped undercroft while the pipe-walk remains the high route.
			# 水库地面下切为错层地下廊，管线栈道仍是高位路线。
			_add_platform(Rect2(810.0, floor_y + 90.0, 170.0, 18.0))
			_add_platform(Rect2(970.0, floor_y + 135.0, 140.0, 18.0))
			_add_platform(Rect2(1130.0, floor_y + 90.0, 140.0, 18.0))
		"A5":
			# A5 pilot implementation: long layered battlefield with room-scale landmarks.
			# A5试点落地：长距离、多层、可辨识的探索空间。
			_add_platform(Rect2(100, 410, 300, 18))
			_add_platform(Rect2(300, 350, 130, 18))
			_add_platform(Rect2(445, 300, 145, 18))
			_add_platform(Rect2(580, 350, 140, 18))
			_add_platform(Rect2(640, 455, 180, 18))
			_add_platform(Rect2(760, 410, 110, 18))
			_add_platform(Rect2(800, 350, 100, 18))
			_add_platform(Rect2(845, 290, 105, 18))
			_add_platform(Rect2(890, 230, 120, 18))
			_add_platform(Rect2(960, 365, 150, 18))
			# Preserve the existing buried-standard resonance crossing at x=880..1220.
			_add_platform(Rect2(850.0, floor_y + 90.0, 145.0, 18.0))
			_add_platform(Rect2(1015.0, floor_y + 135.0, 145.0, 18.0))
			_add_platform(Rect2(1180.0, floor_y + 90.0, 145.0, 18.0))
			_add_platform(Rect2(1280, 470, 180, 18))
			_add_platform(Rect2(1460, 420, 140, 18))
			_add_platform(Rect2(1600, 360, 150, 18))
			_add_platform(Rect2(1740, 420, 140, 18))
			_add_platform(Rect2(1880, 470, 170, 18))
			_add_platform(Rect2(1980, 405, 140, 18))
			_add_platform(Rect2(2110, 345, 140, 18))
			_add_platform(Rect2(2240, 290, 150, 18))
			_add_platform(Rect2(2370, 350, 150, 18))
			_add_platform(Rect2(2500, 420, 170, 18))
			_add_platform(Rect2(2670, 365, 160, 18))
			_add_platform(Rect2(2830, 420, 180, 18))
			_add_platform(Rect2(2960, 345, 140, 18))
			_add_platform(Rect2(3090, 290, 120, 18))
			_add_platform(Rect2(3210, 235, 125, 18))
			_add_platform(Rect2(3335, 290, 130, 18))
			_add_platform(Rect2(3465, 350, 160, 18))
			_add_platform(Rect2(3600, 410, 180, 18))
			_add_platform(Rect2(3770, 350, 170, 18))
			_add_platform(Rect2(3910, 290, 150, 18))
			_add_platform(Rect2(4040, 350, 160, 18))
			_add_platform(Rect2(4190, 420, 180, 18))
			_add_platform(Rect2(3710, 500, 180, 18))
			_add_platform(Rect2(3900, 555, 170, 18))
			_add_platform(Rect2(4080, 500, 180, 18))
			_add_platform(Rect2(4260, 450, 150, 18))
			_add_platform(Rect2(4380, 390, 160, 18))
			_add_platform(Rect2(4540, 340, 160, 18))
			_add_platform(Rect2(4700, 390, 160, 18))
			_add_platform(Rect2(4860, 440, 170, 18))
			_add_platform(Rect2(5020, 450, 180, 18))
			_add_platform(Rect2(5180, 450, 200, 18))
		"A6":
			# Main stair climbs the bell tower; the side cloister balcony loops around its outer wall.
			# 主阶梯攀上钟塔；侧边回廊阳台绕塔外墙形成另一条路线。
			_add_platform(Rect2(100, 450, 140, 18))
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
			# C13's upper exit is approached by three collision-backed elevations from the prison floor route.
			# C13 高位出口由三级实体碰撞台阶接入，避免监牢地面直通王墓。
			_add_platform(Rect2(2140, 460, 110, 18))
			_add_platform(Rect2(2160, 420, 120, 18))
			_add_platform(Rect2(2180, 380, 390, 18))
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
			# The maintenance drop connects the prison cells to a lower crosswalk and two climb-out shelves.
			# 维修井道把牢房接入下层横道，并用两侧石沿保留回攀路线。
			_add_platform(Rect2(830.0, floor_y + 90.0, 145.0, 18.0))
			_add_platform(Rect2(995.0, floor_y + 135.0, 145.0, 18.0))
			_add_platform(Rect2(1160.0, floor_y + 90.0, 145.0, 18.0))
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
			_add_platform(Rect2(500, 375, 140, 18))
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
			# C13's west exit and arrival are supported on the upper royal-tomb entry platform.
			# C13 王墓西侧出口与到达点均由上层入口平台承托。
			_add_platform(Rect2(60, 380, 170, 18))
			_add_platform(Rect2(240, 380, 170, 18))
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
			_add_platform(Rect2(2300, 360, 220, 18))
			_add_platform(Rect2(390, 395, 115, 18))
			_add_platform(Rect2(520, 355, 120, 18))
			_add_platform(Rect2(665, 320, 120, 18))
			# The royal drain door and its arrival spawn must both sit on a real upper service ledge.
			# 王城排水门与到达出生点必须同时落在实体上层检修栈台。
			_add_platform(Rect2(620, 390, 180, 18))
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
			# C17 arrives on a dedicated upper landing matching A9's rooftop door height.
			# C17 从 A9 屋顶门进入时，先落在独立高位平台，而不是圣堂地面。
			_add_platform(Rect2(80, 360, 150, 18))
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
			# C22 must be supported by the raised throne approach and stay outside a max-height ground jump.
			# C22 必须由王座高路承托，并避开从连续地面起跳时的最大碰撞包络。
			_add_platform(Rect2(2100, 380, 190, 18))
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
			# A lower foundation passage runs beneath the crown-wall walk and rejoins the avenue.
			# 王冠城墙高路下方增加基础层通道，并重新接回大道。
			_add_platform(Rect2(830.0, floor_y + 90.0, 145.0, 18.0))
			_add_platform(Rect2(995.0, floor_y + 135.0, 145.0, 18.0))
			_add_platform(Rect2(1160.0, floor_y + 90.0, 145.0, 18.0))
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
			# The final ascent has a lower chasm route, then returns to the central climb via staggered shelves.
			# 终局攀升下方增设深坑路线，再通过错层石沿回到中央上升段。
			_add_platform(Rect2(880.0, floor_y + 90.0, 145.0, 18.0))
			_add_platform(Rect2(1045.0, floor_y + 135.0, 145.0, 18.0))
			_add_platform(Rect2(1210.0, floor_y + 90.0, 145.0, 18.0))
	_configure_additional_lower_route_platforms()

func _configure_additional_lower_route_platforms() -> void:
	# The remaining tall regions get lower passages under their existing upper loops.
	# 其余高层区域在既有上层环路下方补齐低位通道。
	var shelf_start := -1.0
	match region_id:
		"A6":
			shelf_start = 1410.0
		"A8", "A9", "A10", "A11":
			shelf_start = 1380.0
		"H01", "H02", "H03", "H04", "H05", "H06", "H07", "H08", "H09":
			shelf_start = 790.0
	if shelf_start < 0.0:
		return
	_add_platform(Rect2(shelf_start, floor_y + 90.0, 145.0, 18.0))
	_add_platform(Rect2(shelf_start + 165.0, floor_y + 135.0, 145.0, 18.0))
	_add_platform(Rect2(shelf_start + 330.0, floor_y + 90.0, 145.0, 18.0))

func _add_platform(rect: Rect2) -> void:
	platforms.append(rect)
	var body := StaticBody2D.new()
	if region_id == "A5" and not room_id.is_empty():
		body.name = "A5RoomPlatform_%03d" % platforms.size()
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
	var rest_y := floor_y
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
			if use_a5_room_assembly:
				var hub := _get_a5_assembled_room("A5-R12")
				if hub != null:
					rest_x = hub.position.x + 1100.0
					rest_y = hub.position.y + float(hub.get("floor_y"))
			else:
				rest_x = 3000.0
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
	rest.position = Vector2(rest_x, rest_y)
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
			var source_position := Vector2(1100.0, floor_y - 18.0)
			if use_a5_room_assembly:
				var clue_room := _get_a5_assembled_room("A5-R03")
				if clue_room != null:
					source_position = clue_room.position + Vector2(1100.0, float(clue_room.get("floor_y")) - 18.0)
			_spawn_source(
				source_position,
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
			_register_debug_locked_route_hint(1880.0, "old_battlefield", "旧朝圣高路需从 A5 开启", floor_y - 115.0)
		"A3":
			_register_debug_locked_route_hint(520.0, "village", "村庄防卫章节完成后开放")
			_register_debug_locked_route_hint(2040.0, "royal_outer_ring", "东侧高位旧升降机：需从 A9 开启", floor_y - 70.0)
			_register_debug_locked_route_hint(1710.0, "monastery_tower", "需先从 A6 开启钟塔落差")
			_register_debug_locked_route_hint(1870.0, "silent_bell_room", "需先发现并开启 H05")
		"A4":
			_register_debug_locked_route_hint(1050.0, "prison_depths", "低位栈台：需从 A7 开启补给隧道", floor_y - 75.0)
			_register_debug_locked_route_hint(1320.0, "royal_tomb", "中层平台：需从 A8 开启王墓水道", floor_y - 85.0)
			_register_debug_locked_route_hint(1650.0, "royal_outer_ring", "高位管线：需从 A9 开启王城排水道", floor_y - 105.0)
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


func _register_debug_locked_route_hint(x: float, target: String, condition: String, marker_y: float = -1.0) -> void:
	for marker in debug_exit_markers:
		var marker_position: Vector2 = marker.get("position", Vector2.ZERO)
		if is_equal_approx(marker_position.x, x) and str(marker.get("label", "")) == _debug_route_label(target):
			return
	# High-route ghost markers must use the same vertical anchor as the door they represent.
	# 高位虚拟标识必须使用对应实体门的垂直锚点，不能一律画在地面。
	debug_exit_markers.append({
		"position": Vector2(x, floor_y if marker_y < 0.0 else marker_y),
		"label": _debug_route_label(target),
		"kind": "locked",
		"condition": condition
	})


func _refresh_a11_ending_route() -> void:
	if region_id != "A11" or NereisEndingEvaluator.get_candidate() == "凡人之墓":
		return
	if get_node_or_null("Exit_terminal_anomaly") != null:
		return

	# The candidate can change after a source or truth anchor is collected in A11.
	# Remove the locked hint and create the real C21 door as soon as the evaluator allows it.
	for index in range(debug_exit_markers.size() - 1, -1, -1):
		var marker: Dictionary = debug_exit_markers[index]
		var marker_position: Vector2 = marker.get("position", Vector2.ZERO)
		if (
			is_equal_approx(marker_position.x, 2050.0)
			and str(marker.get("label", "")) == _debug_route_label("terminal_anomaly")
			and str(marker.get("kind", "")) == "locked"
		):
			debug_exit_markers.remove_at(index)

	_spawn_exit_door(
		2050.0, "E  追随深层梦境", "terminal_anomaly",
		"res://scenes/terminal_anomaly.tscn", "west"
	)
	print("[NEREIS][MAP][GATE] C21 dynamically unlocked candidate=%s" % NereisEndingEvaluator.get_candidate())
	queue_redraw()


func _refresh_a6_bell_shortcut() -> void:
	if region_id != "A6" or a6_bell_shortcut_spawned:
		return
	if not WorldState.is_item_owned("bell_tower_winch_key") and "opened_bell_tower_drop" not in WorldState.achievement_flags:
		return
	_spawn_exit_door(
		2230.0, "E  使用绞盘钥匙打开钟塔落差通路", "forgotten_city",
		"res://scenes/forgotten_city.tscn", "bell_drop",
		true, "opened_bell_tower_drop", "E  返回被遗忘的城区", floor_y - 55.0
	)
	a6_bell_shortcut_spawned = true


func _get_a5_assembled_room(room_key: String) -> Node2D:
	if not use_a5_room_assembly:
		return null
	var room := a5_assembled_rooms.get(room_key) as Node2D
	if room != null and is_instance_valid(room):
		return room
	return get_node_or_null(room_key.replace("-", "_")) as Node2D


func _spawn_region_exits() -> void:
	match region_id:
		"A2":
			_spawn_exit_door(
				72.0, "E  返回边境村庄", "village",
				"res://scenes/village_hub.tscn", "north_gate"
			)
			# The main route to A3 sits on the eastern canopy ledge; the ground-level bell anomaly remains a separate choice.
			# 通往 A3 的主线出口位于东侧树冠高台；地面的钟墓异常入口保留为另一种探索选择。
			# C03's authored/topology anchor is x=3400, at the far eastern end of the expanded canopy.
			# C03 的正式路线锚点为 x=3400，位于扩建后树冠高路的最东端。
			_spawn_exit_door(
				3400.0, "E  沿树冠高路进入被遗忘的城区", "forgotten_city",
				"res://scenes/forgotten_city.tscn", "city_canopy_entry",
				true, "", "", floor_y - 160.0
			)
			# H02 belongs to the optional low Bell Grave space, not the far-eastern main-floor edge.
			# H02 应位于钟墓坑底的可选低位空间，而不是地图最东侧的主地面。
			_spawn_h02_gate(960.0, floor_y + 125.0)
			# C04 is opened from A5; once opened, keep the reverse entrance persistent on A2.
			# C04 在 A5 侧开启；开启后，A2 侧永久生成对应回程门。
			if "reached_A5_and_opened_old_pilgrim_highroad" in WorldState.achievement_flags:
				_spawn_exit_door(
					1880.0, "E  返回边境战场", "old_battlefield",
					"res://scenes/old_battlefield.tscn", "old_pilgrim_highroad",
					true, "", "", floor_y - 115.0
				)
		"A3":
			# C24 enters the shared exploration segment only after the A4-side gate is opened.
			# A4 侧闸门开启后，C24 才经共享探索段连通；此前仍保持原有村庄回程。
			if "village_defense_survived" in WorldState.achievement_flags:
				if "opened_old_drainage_link_from_A4" in WorldState.achievement_flags:
					_spawn_exit_door(
						520.0, "E  进入旧排水道回环", "old_drain_exploration",
						"res://scenes/old_drain_exploration.tscn", "city_side_entry"
					)
				else:
					_spawn_exit_door(
						520.0, "E  经旧排水道返回", "village",
						"res://scenes/village_hub.tscn", "city_cut_return"
					)
			_spawn_exit_door(
				72.0, "E  返回旧朝圣路", "ash_forest",
				"res://scenes/ash_forest.tscn", "east",
				true, "", "", floor_y - 130.0
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
				"res://scenes/old_battlefield.tscn", "city_highroad",
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
			# C05 is paired with A3's raised pipe-walk; the reservoir-side hatch must not fall back to ground level.
			# C05 与 A3 高架管线配对；水库侧检修舱口不能退回地面高度。
			_spawn_exit_door(
				72.0, "E  打开上层检修舱口", "forgotten_city",
				"res://scenes/forgotten_city.tscn", "sewer",
				true, "opened_sewer_inspection_hatch_from_A4", "E  返回城区", floor_y - 115.0
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
				# C24's A4-side gate unlocks the persistent route through the exploration segment.
				# C24 的 A4 侧闸门负责开启经探索段连接 A1 与 A3 的持久路线。
				_spawn_exit_door(
					600.0, "E  打开旧排水道连接", "old_drain_exploration",
					"res://scenes/old_drain_exploration.tscn", "reservoir_link",
					true, "opened_old_drainage_link_from_A4", "E  进入旧排水道"
				)

		"A5":
			if use_a5_room_assembly:
				# Bind cross-region doors to the actual room origins after the assembly grid is normalized.
				# 出口必须基于归一化后的真实房间原点计算，不能混用旧地图的绝对 Y。
				var entry_room := _get_a5_assembled_room("A5-R01")
				if entry_room != null:
					_spawn_exit_door(
						entry_room.position.x + 180.0, "E  沿残墙高路返回被遗忘的城区", "forgotten_city",
						"res://scenes/forgotten_city.tscn", "city_highroad_return",
						true, "", "", entry_room.position.y + 410.0
					)
				var exit_room := _get_a5_assembled_room("A5-R20")
				if exit_room != null:
					_spawn_exit_door(
						exit_room.position.x + 1200.0, "E  沿残墙高路进入修道院", "monastery_tower",
						"res://scenes/monastery_tower.tscn", "battlefield_entry", true, "", "", exit_room.position.y + 410.0
					)
				if WorldState.is_hidden_path_opened("H02"):
					var hidden_room := _get_a5_assembled_room("A5-R14")
					if hidden_room != null:
						_spawn_exit_door(
							hidden_room.position.x + 1080.0, "E  打开旧钟塔通路", "hidden_bell_chamber",
							"res://scenes/hidden_bell_chamber.tscn", "bell_tower_entry",
							true, "opened_old_bell_tower_connection", "E  进入倒响钟室", hidden_room.position.y + 620.0
						)
				var winch_room := _get_a5_assembled_room("A5-R16")
				if winch_room != null:
					_spawn_exit_door(
						winch_room.position.x + 980.0, "E  打开旧朝圣高路", "ash_forest",
						"res://scenes/ash_forest.tscn", "old_pilgrim_highroad",
						true, "reached_A5_and_opened_old_pilgrim_highroad", "E  沿旧朝圣高路返回",
						winch_room.position.y + 610.0
					)
			else:
				_spawn_exit_door(
					180.0, "E  沿残墙高路返回被遗忘的城区", "forgotten_city",
					"res://scenes/forgotten_city.tscn", "city_highroad_return",
					true, "", "", floor_y - 130.0
				)
				_spawn_exit_door(
					5350.0, "E  沿残墙高路进入修道院", "monastery_tower",
					"res://scenes/monastery_tower.tscn", "battlefield_entry", true, "", "", floor_y - 90.0
				)
				if WorldState.is_hidden_path_opened("H02"):
					_spawn_exit_door(
						4500.0, "E  打开旧钟塔通路", "hidden_bell_chamber",
						"res://scenes/hidden_bell_chamber.tscn", "bell_tower_entry",
						true, "opened_old_bell_tower_connection", "E  进入倒响钟室"
					)
				_spawn_exit_door(
					3900.0, "E  打开旧朝圣高路", "ash_forest",
					"res://scenes/ash_forest.tscn", "old_pilgrim_highroad",
					true, "reached_A5_and_opened_old_pilgrim_highroad", "E  沿旧朝圣高路返回",
					floor_y - 140.0
				)
		"A6":
			_spawn_exit_door(
				72.0, "E  返回边境战场", "old_battlefield",
				"res://scenes/old_battlefield.tscn", "monastery_return"
			)
			_spawn_exit_door(
				map_width - 72.0, "E  深入监牢", "prison_depths",
				"res://scenes/prison_depths.tscn", "west"
			)
			_spawn_h05_gate(1660.0)
			# C10 is a physical monastery shortcut, independent of the optional H05 secret room.
			# C10 是修道院的实体捷径，不应被可选隐藏区 H05 的发现状态锁死。
			# C10 is created after the bell warden drops the winch key.
			# C10 只有在钟塔守卫掉落绞盘钥匙后才出现。
		"A7":
			_spawn_exit_door(
				72.0, "E  返回修道院", "monastery_tower",
				"res://scenes/monastery_tower.tscn", "east"
			)
			# C13 is deliberately elevated: the prison maintenance shaft must be climbed before the tomb.
			# C13 刻意设置为高位出口：玩家必须先攀上监牢维护竖井，才能进入王墓。
			_spawn_exit_door(
				map_width - 72.0, "E  沿维护竖井进入旧王墓", "royal_tomb",
				"res://scenes/royal_tomb.tscn", "maintenance_shaft_entry",
				true, "", "", floor_y - 180.0
			)
			# C12: unlock the supply tunnel from the prison side; the first E opens it, the second traverses.
			# C12：从监牢侧开启补给隧道；第一次 E 开门，第二次 E 才转场。
			_spawn_exit_door(
				520.0, "E  打开补给隧道", "sewer_reservoir",
				"res://scenes/sewer_reservoir.tscn", "prison_tunnel",
				true, "reached_A7_then_opened_supply_tunnel", "E  沿补给隧道返回"
			)
		"A8":
			# Optional dedicated Boss arena; the ordinary A8→A9 main route remains available either way.
			# 独立 Boss 内殿是可选内容；无论是否挑战，A8→A9 主线都保持开放。
			if "defeated_royal_tomb_guardian" not in WorldState.achievement_flags:
				_spawn_exit_door(
					1540.0, "E  进入王墓内殿", "royal_tomb_boss",
					"res://scenes/royal_tomb_boss.tscn", "west"
				)
			# C13's reverse door stays on the upper entry platform, preventing a ground-level bypass.
			# C13 回程门仍位于上层入口平台，避免主线变成地面平移捷径。
			_spawn_exit_door(
				72.0, "E  沿维护竖井返回监牢", "prison_depths",
				"res://scenes/prison_depths.tscn", "maintenance_shaft_return",
				true, "", "", floor_y - 180.0
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
				true, "reached_A8_via_A7_then_opened_royal_tomb_gate", "E  沿王室水道返回",
				floor_y - 165.0
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
				"res://scenes/grand_cathedral.tscn", "cathedral_roof", true, "", "", floor_y - 180.0
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
			# C23: keep the high drain door on the supported service ledge and clear of C18 at x=900.
			# C23：高位排水门必须落在承托栈台上，并与 x=900 的 C18 保持净距。
			_spawn_exit_door(
				740.0, "E  打开王城排水门", "sewer_reservoir",
				"res://scenes/sewer_reservoir.tscn", "royal_drain",
				true, "reached_A9_then_opened_royal_drain_from_outer_ring", "E  沿王城排水道返回",
				floor_y - 150.0
			)
		"A10":
			_spawn_exit_door(
				72.0, "E  返回王城外环", "royal_outer_ring",
				"res://scenes/royal_outer_ring.tscn", "cathedral_roof_return",
				true, "", "", floor_y - 180.0
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

			# C22 is available only after the mainline A10 -> A12 arrival has been recorded.
			# C22 仅在记录了 A10 主线抵达 A12 后开放，不能从 H07 镜街侧门绕过终局门槛。
			if "reached_A12_via_A10" in WorldState.achievement_flags:
				_spawn_exit_door(
					2130.0, "E  进入王座区", "terminal_anomaly",
					"res://scenes/terminal_anomaly.tscn", "west", true, "", "", floor_y - 180.0
				)
			else:
				_register_debug_locked_route_hint(
					2130.0, "terminal_anomaly", "需要从大圣堂主线抵达 A12（C22）", floor_y - 180.0
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
			# H02 is an optional detour that returns to A2; do not add a second A5 exit.
			# H02 是返回 A2 的可选探索支路；不额外设置通往 A5 的第二出口。
			_spawn_exit_door(
				72.0, "E  返回旧朝圣路", "ash_forest",
				"res://scenes/ash_forest.tscn", "bell_gate"
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
			# The A11-to-A10 return is paired to C19 itself; reaching the cathedral on the main route alone must not open this hidden return.
			# A11 返回大圣堂必须与 C19 本身成对；仅走过主线抵达大圣堂，不应自动开启这条隐藏回程。
			var can_return_to_cathedral := WorldState.is_hidden_path_opened("C19")
			_spawn_exit_door(
				72.0, "E  沿王室竖井返回", "royal_tomb",
				"res://scenes/royal_tomb.tscn", "east", can_return_to_tomb
			)
			_spawn_exit_door(
				map_width - 72.0, "E  返回大圣堂", "grand_cathedral",
				"res://scenes/grand_cathedral.tscn", "east", can_return_to_cathedral
			)
			_spawn_h08_gate(map_width - 300.0)
			# C21 follows the ending evaluator: resonance, truth anchors, and exploration—not intimacy—open the optional ending route.
			# C21 遵循结局评估器：由鸣响、真相锚点与探索决定是否开放，不以亲密关系作为门槛。
			if NereisEndingEvaluator.get_candidate() != "凡人之墓":
				_spawn_exit_door(
					2050.0, "E  追随深层梦境", "terminal_anomaly",
					"res://scenes/terminal_anomaly.tscn", "west"
				)
			else:
				_register_debug_locked_route_hint(2050.0, "terminal_anomaly", "需满足结局路线条件：鸣响、真相锚点与隐藏探索")

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
			# The hidden route converges on A13 when the evaluator has selected a non-human ending candidate.
			# 结局评估器选出非“凡人之墓”路线后，隐藏通路才汇入 A13。
			if NereisEndingEvaluator.get_candidate() != "凡人之墓":
				_spawn_exit_door(
					map_width - 72.0, "E  追随最后的梦境", "terminal_anomaly",
					"res://scenes/terminal_anomaly.tscn", "west"
				)
			else:
				_register_debug_locked_route_hint(map_width - 72.0, "terminal_anomaly", "需满足结局路线条件：鸣响、真相锚点与隐藏探索")

		"A13":
			var ending_gate := ENDGAME_GATE_SCRIPT.new()
			var ending_scene_path := str(ending_gate.call("route_candidate"))
			ending_gate.free()
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
			route.bridge_y = 386.0
			route.prompt_text = "E  ANCHOR THE BELLGRAVE CANOPY"
		"A3":
			route = Node2D.new()
			route.set_script(LOCAL_RESONANCE_ROUTE_SCRIPT)
			route.name = "ThirdStreetResonanceBridge"
			route.route_id = "A3_THIRD_STREET_ROOFLINE"
			route.required_resonance = 28
			route.bridge_start_x = 1320.0
			route.bridge_end_x = 1690.0
			route.bridge_y = 400.0
			route.prompt_text = "E  ANCHOR THE THIRD STREET"
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
			route.prompt_text = "E  ANCHOR THE DRY AQUEDUCT"
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
			route.prompt_text = "E  RAISE THE BURIED STANDARD"
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
			route.prompt_text = "E  ANCHOR THE SILENT BELL WALK"
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
			route.prompt_text = "E  ANCHOR THE PRISON CROSSWALK"
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
			route.prompt_text = "E  ANCHOR THE ERASED REGENT GALLERY"
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
			route.prompt_text = "E  ANCHOR THE RAIN REFLECTION"
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
			route.prompt_text = "E  ANCHOR THE CHOIRLESS GALLERY"
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
			route.prompt_text = "E  ANCHOR THE OBSERVER SPAN"
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
			route.prompt_text = "E  ANCHOR THE CROWN WALL"
		_:
			return
	route.opened.connect(_on_local_resonance_route_opened)
	add_child(route)

func _on_local_resonance_route_opened(route_id: String) -> void:
	# A2's environmental narrative must not be delivered as narrator-style popup text.
	# Keep the route activation itself as world feedback; place any future story fragments in
	# diegetic objects/descriptions or NPC dialogue after the map layout is approved.
	if route_id == "A2_BELLGRAVE_CANOPY_CROSSING":
		print("[NEREIS][MAP][LOCAL_ROUTE] opened id=%s" % route_id)
		return
	if not is_instance_valid(narrative):
		return
	match route_id:
		"A3_THIRD_STREET_ROOFLINE":
			narrative.show_message(
				"THE THIRD STREET HOLDS",
				"A bridge appears where the city map was scraped clean. The road does not lead to another place; it reconnects two parts of the street you already knew.\n\nThe stone will remember this route.",
				5.0
			)
		"A4_OLD_STONE_AQUEDUCT":
			narrative.show_message(
				"THE AQUEDUCT WITHOUT WATER",
				"The pipes end at a stone channel older than the reservoir. When the bridge settles, water can be heard flowing upward through the sealed rock.\n\nThe channel remembers a river that no longer exists.",
				5.0
			)
		"A5_BURIED_STANDARD_CROSSING":
			narrative.show_message(
				"THE STANDARD THAT OUTLIVED THE ARMY",
				"The cloth has rotted away, but its shadow still points across the trench. The fortress map marks this gap as impassable. The dead were ordered to hold a road that the Church later removed from every record.",
				5.0
			)
		"A6_SILENT_BELL_SERVICE_WALK":
			narrative.show_message(
				"THE SERVICE WALK OF THE SILENT BELL",
				"The upper walkway bears fresh maintenance marks, but the bell above it has never moved. The repair ledger lists a bell-ringer who was born decades after the monastery was sealed.",
				5.0
			)
		"A7_PRISON_MAINTENANCE_CROSSWALK":
			narrative.show_message(
				"THE CROSSWALK OF UNNUMBERED CELLS",
				"The maintenance ledger counts every hinge and drain, but leaves the cells themselves unnumbered. A repair entry orders the crew to preserve the lower doors and seal the upper ones from the outside. The names were not omitted by accident.",
				5.0
			)
		"A8_ERASED_REGENT_GALLERY":
			narrative.show_message(
				"THE REGENT WHO NEVER REIGNED",
				"The gallery joins two burial ledges without passing the sealed royal gate. One stone names a regent; the matching socket on the opposite wall has been chiseled away. The tomb was not built to forget a king. It was altered to make the succession impossible to read.",
				5.0
			)
		"A9_RAIN_REFLECTION_ROOFWALK":
			narrative.show_message(
				"THE HOMES THAT THE RAIN REMEMBERS",
				"The roofline crosses houses whose doors were sealed from the street side. In the rainwater, warm windows appear beneath roofs that have stood empty for years. The old city did not lose its people all at once; someone taught the records to call them never-born.",
				5.0
			)
		"A10_CHOIRLESS_UPPER_GALLERY":
			narrative.show_message(
				"THE CHOIR THAT WAS NEVER RECORDED",
				"The gallery overlooks the cathedral choir, but no sound rises from below. Dust outlines a row of kneeling figures where the floor has been worn smooth. The service ledger lists every hymn and every bell—except the names of those who sang here.",
				5.0
			)
		"A11_SECOND_OBSERVER_SPAN":
			narrative.show_message(
				"THE OBSERVER WHO LEFT NO FOOTPRINTS",
				"The old ledges meet above the laboratory's newest instruments. One observation slate records two shadows entering the chamber and only one body leaving. A later hand has rewritten the count as a lighting error.",
				5.0
			)
		"A12_CROWN_WALL_WALK":
			narrative.show_message(
				"THE WALL BUILT FOR A KING'S ABSENCE",
				"The upper wall was built to watch the avenue, not defend it. Its arrow slits face inward. The palace feared what might leave the throne room more than what might approach it.",
				5.0
			)
		_:
			narrative.show_message(
				"第三街仍然存在",
				"A bridge appears where the city map was scraped clean. The road does not lead to another place; it reconnects two parts of the street you already knew.\n\nThe stone will remember this route.",
				5.0
			)
	print("[NEREIS][MAP][LOCAL_ROUTE] opened id=%s" % route_id)

func _spawn_h02_gate(x: float, y: float = -1.0) -> void:
	var gate := Node2D.new()
	gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
	gate.name = "HiddenBellChamberGate"
	gate.position = Vector2(x, floor_y if y < 0.0 else y)
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
	# H02's discovery must stay environmental; do not explain the bell through narrator-style popup text.
	# H02 的发现应由环境承载，不用旁白式弹窗解释钟的异常。
	if secret_id == "H02":
		print("[NEREIS][MAP][GATE] opened id=H02 feedback=environmental_only")
		return
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

func _region_id_for_location(target_location: String) -> String:
	var mapping := {
		"church_escape":"A0", "village":"A1", "ash_forest":"A2", "forgotten_city":"A3",
		"sewer_reservoir":"A4", "old_battlefield":"A5", "monastery_tower":"A6", "prison_depths":"A7",
		"royal_tomb":"A8", "royal_outer_ring":"A9", "grand_cathedral":"A10",
		"deep_research_depths":"A11", "inner_city":"A12", "terminal_anomaly":"A13",
		"royal_tomb_boss":"OB01", "hidden_well":"H01", "hidden_bell_chamber":"H02",
		"erased_third_street":"H03", "reflected_stairwell":"H04", "silent_bell_room":"H05",
		"erased_royal_name_corridor":"H06", "mirror_street":"H07", "primordial_hollow":"H08"
	}
	return str(mapping.get(target_location, ""))


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
	# Runtime contract metadata for P5.1 automated acceptance; no gameplay behavior change.
	door.set_meta("p5_1_exit_contract", true)
	door.set_meta("p5_1_target_location", target_location)
	door.set_meta("p5_1_target_region", _region_id_for_location(target_location))
	door.set_meta("p5_1_target_scene", target_scene)
	door.set_meta("p5_1_spawn_side", spawn_side)
	door.set_meta("p5_1_enabled", enabled)

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
	var exit_kind := "locked" if not enabled else ("shortcut" if not unlock_once_flag_id.is_empty() else "exit")
	debug_exit_markers.append({
		"position": door.position,
		"label": _debug_route_label(target_location),
		"kind": exit_kind,
		"condition": unlock_once_flag_id if not unlock_once_flag_id.is_empty() else ("需从另一侧开启" if not enabled else "")
	})
	if use_a5_room_assembly:
		_create_a5_door_arch(door.position, exit_kind, door.name)
	queue_redraw()
	door.interacted.connect(_on_exit_interacted.bind(target_location, target_scene, spawn_side))

# Draw distant, non-colliding silhouettes at authored exits so players can read route goals
# before reaching them. These arches are visual landmarks only; Area2D doors own all interaction.
# 在正式出口位置绘制远景门廊，让玩家抵达前就能读懂路线目标；门廊不参与碰撞，交互仍由 Area2D 出口负责。
func _draw_route_goal_landmarks() -> void:
	for marker in debug_exit_markers:
		var marker_kind := str(marker.get("kind", "exit"))
		# Hidden room links appear only when their real resonance condition is met or the path was opened.
		if marker_kind == "secret":
			var connection_id := str(marker.get("connection_id", ""))
			var connection_kind := str(marker.get("connection_kind", "hidden"))
			if connection_id.is_empty() or (
				not WorldState.is_hidden_path_opened(connection_id)
				and not _a5_internal_connection_requirement_met(connection_id, connection_kind, "")
			):
				continue
		var anchor: Vector2 = marker.get("visual_position", marker.get("position", Vector2.ZERO))
		var tint := Color("#8eaa9a")
		if marker_kind == "shortcut":
			tint = Color("#d5b36b")
		elif marker_kind == "locked":
			tint = Color("#a47d86")
		tint.a = 0.38
		var left := anchor + Vector2(-25.0, 0.0)
		var right := anchor + Vector2(25.0, 0.0)
		var crown := anchor + Vector2(0.0, -54.0)
		# Broken side pillars and a shallow arch distinguish a doorway from a solid wall.
		draw_line(left, left + Vector2(0.0, -45.0), tint, 4.0, true)
		draw_line(right, right + Vector2(0.0, -45.0), tint, 4.0, true)
		draw_arc(crown, 25.0, PI, TAU, 16, tint, 3.0, true)
		draw_line(left + Vector2(0.0, -45.0), crown + Vector2(-16.0, -1.0), tint, 3.0, true)
		draw_line(crown + Vector2(16.0, -1.0), right + Vector2(0.0, -45.0), tint, 3.0, true)
		var inner := Color(tint.r, tint.g, tint.b, 0.055)
		draw_rect(Rect2(anchor + Vector2(-17.0, -39.0), Vector2(34.0, 39.0)), inner, true)

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
		# The arrow points down to the exact door/gate anchor; the label stays above it.
		# 箭头尖端指向门/灵视入口的实际交互锚点，文字标签仍放在上方。
		var marker_top := marker_position + Vector2(0.0, -118.0)
		draw_line(marker_top, marker_position + Vector2(0.0, -8.0), marker_color, 3.0, true)
		draw_line(marker_position + Vector2(-12.0, -22.0), marker_position, marker_color, 3.0)
		draw_line(marker_position + Vector2(12.0, -22.0), marker_position, marker_color, 3.0)
		draw_circle(marker_position, 4.0, marker_color)
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

	# Clear old-scene focus before transition so no interactable retains stale availability during the fade.
	# 切图前清理旧场景交互焦点，避免淡出期间残留可交互状态。
	INTERACTION_FOCUS_SCRIPT.clear_all(get_tree())
	WorldState.pending_region_spawn_side = spawn_side
	WorldState.set_location(target_location)
	print("[NEREIS][MAP][EXIT] from=%s to=%s location=%s spawn_side=%s" % [region_id, target_scene, target_location, spawn_side])
	SceneTransition.fade_to_scene(target_scene)

func _on_hero_defeated() -> void:
	if respawning:
		return
	respawning = true
	WorldState.input_locked = true
	INTERACTION_FOCUS_SCRIPT.clear_all(get_tree())
	await get_tree().create_timer(0.75).timeout
	if is_instance_valid(hero):
		hero.velocity = Vector2.ZERO
		hero.global_position = WorldState.checkpoint_position
		if hero.has_method("restore_full"):
			hero.call("restore_full")
	INTERACTION_FOCUS_SCRIPT.clear_all(get_tree())
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

func _region_backdrop_texture() -> Texture2D:
	match region_id:
		"A1", "A2", "H01", "H08", "H09":
			return FOREST_BACKDROP
		"A0", "A6", "A10", "A11":
			return CHURCH_BACKDROP
		"A13":
			return ELDRITCH_BACKDROP
		_:
			return RUINS_BACKDROP


func _draw_floor_gap_visuals() -> void:
	var gaps: Array[Vector2] = []
	match region_id:
		"A1":
			gaps.append(Vector2(620.0, 520.0))
		"A2":
			gaps.append(Vector2(860.0, 200.0))
			gaps.append(Vector2(2420.0, 240.0))
		"A3":
			gaps.append(Vector2(820.0, 420.0))
		"A4":
			gaps.append(Vector2(780.0, 500.0))
		"A5":
			gaps.append(Vector2(820.0, 500.0))
		"A6":
			gaps.append(Vector2(1380.0, 390.0))
		"A7", "A12":
			gaps.append(Vector2(800.0, 500.0))
		"A8", "A9":
			gaps.append(Vector2(1350.0, 430.0))
		"A10", "A11":
			gaps.append(Vector2(1350.0, 420.0))
		"A13":
			gaps.append(Vector2(850.0, 500.0))
		"H01", "H02", "H03", "H04", "H05", "H06", "H07", "H08", "H09":
			gaps.append(Vector2(760.0, 400.0))
	for gap in gaps:
		draw_rect(Rect2(gap.x, floor_y - 1.0, gap.y, 260.0), Color("#171820"))
		draw_rect(Rect2(gap.x, floor_y - 1.0, 10.0, 150.0), Color("#51434a"))
		draw_rect(Rect2(gap.x + gap.y - 10.0, floor_y - 1.0, 10.0, 150.0), Color("#51434a"))


func _draw() -> void:
	if use_a5_room_assembly:
		_draw_route_goal_landmarks()
		if OS.is_debug_build():
			_draw_debug_exit_markers()
		return
	var backdrop: Texture2D = _region_backdrop_texture()
	if backdrop != null:
		draw_texture_rect(backdrop, Rect2(0.0, 0.0, map_width, room_height if region_id == "A5" and not room_id.is_empty() else (1000.0 if region_id == "A2" else 720.0)), false)
	else:
		draw_rect(Rect2(0.0, 0.0, map_width, room_height if region_id == "A5" and not room_id.is_empty() else (1000.0 if region_id == "A2" else 720.0)), _background_color())
	_draw_biome_color_wash()
	_draw_atmospheric_layers()
	_draw_midground_accents()
	if region_id == "A5" and not room_id.is_empty():
		for segment in a5_room_floor_segments:
			draw_texture_rect(STONE_FLOOR_STRIP, Rect2(segment.x, floor_y, segment.y, 180.0), false)
	else:
		draw_texture_rect(STONE_FLOOR_STRIP, Rect2(0.0, floor_y, map_width, 180.0), false)
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
		"A13":
			_draw_terminal_anomaly_landmarks()

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

	# Exit architecture is visible in normal play; hidden resonance gates remain visually concealed.
	# 正常游玩中可远眺实体出口建筑；灵视隐藏门不绘制，避免破坏发现感。
	_draw_route_goal_landmarks()
	# Draw all floor cuts after ground seams and landmarks so art never falsely bridges a collision gap.
	# 在地面接缝和地标之后绘制全部断口，避免美术线条错误地把碰撞缺口连起来。
	if region_id == "A5" and not room_id.is_empty():
		_draw_a5_room_floor_gaps()
	else:
		_draw_floor_gap_visuals()

	for platform in platforms:
		# A shallow tinted side face adds material depth while keeping the walkable top unmistakable.
		# 薄薄的染色侧壁增加材质厚度，同时让可站立顶面保持清晰。
		var platform_base := _platform_color()
		var platform_accent := _atmosphere_color()
		draw_rect(Rect2(platform.position + Vector2(0.0, 3.0), Vector2(platform.size.x, 9.0)), platform_base)
		draw_rect(Rect2(platform.position + Vector2(0.0, 12.0), Vector2(platform.size.x, 5.0)), platform_base.darkened(0.42))
		draw_line(platform.position, Vector2(platform.end.x, platform.position.y), platform_accent.lightened(0.22), 2.0)
		draw_line(platform.position + Vector2(2.0, 12.0), Vector2(platform.end.x - 2.0, platform.position.y + 12.0), Color("#1b171f", 0.82), 2.0)
		# Sparse mineral / moss flecks are deterministic and stay on the platform face.
		# 少量矿物／苔痕斑点按平台位置固定分布，不会随机闪烁。
		if int(platform.position.x / 37.0) % 3 == 0:
			draw_line(platform.position + Vector2(12.0, 6.0), platform.position + Vector2(minf(platform.size.x - 8.0, 29.0), 7.0), Color(platform_accent.r, platform_accent.g, platform_accent.b, 0.34), 1.0)

	# Solid rubble blocks are both visible graybox geometry and real collision volumes.
	# 实体残骸既是可见灰盒几何，也是实际碰撞体积。
	for block in a5_room_blocks:
		draw_rect(Rect2(block.position + Vector2(4.0, 5.0), block.size), Color("#211e25", 0.98))
		draw_rect(Rect2(block.position, Vector2(block.size.x, minf(8.0, block.size.y))), Color("#655657", 0.98))
		draw_line(block.position, block.position + Vector2(block.size.x, 0.0), Color("#a18a7c", 0.85), 2.0)
		draw_line(block.position + Vector2(block.size.x * 0.25, 5.0), block.position + Vector2(block.size.x * 0.25 - 8.0, block.size.y), Color("#383139", 0.9), 2.0)

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


# A restrained color grade gives every biome its own chromatic identity without hiding the backdrop.
# 以克制的色彩分级建立区域识别度，同时保留原有背景细节。
func _draw_biome_color_wash() -> void:
	var wash := Color("#263e36")
	var accent := Color("#7fbf8d")
	match region_id:
		"A1", "A2", "H01", "H08", "H09":
			wash = Color("#244b39")
			accent = Color("#a1dc91")
		"A3", "A9", "H03", "H07":
			wash = Color("#492b53")
			accent = Color("#e08cbf")
		"A4", "H04":
			wash = Color("#174b60")
			accent = Color("#69dce7")
		"A5":
			wash = Color("#6b3025")
			accent = Color("#ff9b58")
		"A6", "A10":
			wash = Color("#584126")
			accent = Color("#f4cb78")
		"A7":
			wash = Color("#263f62")
			accent = Color("#80b9e8")
		"A8", "H06":
			wash = Color("#44305d")
			accent = Color("#bd9bea")
		"A11", "H02", "H05":
			wash = Color("#5b2055")
			accent = Color("#f078d4")
		"A12":
			wash = Color("#672d2c")
			accent = Color("#ff9b78")
		"A13":
			wash = Color("#30205f")
			accent = Color("#d0a4ff")
	# The wash is intentionally translucent; gameplay silhouettes and exit markers stay dominant.
	# 色彩覆盖保持半透明，避免角色剪影与出口标记被淹没。
	draw_rect(Rect2(0.0, 0.0, map_width, 1000.0 if region_id == "A2" else 720.0), Color(wash.r, wash.g, wash.b, 0.20))
	for band in range(4):
		var band_y := 150.0 + float(band) * 118.0
		var band_alpha := 0.025 + float(band % 2) * 0.012
		draw_rect(Rect2(0.0, band_y, map_width, 46.0), Color(accent.r, accent.g, accent.b, band_alpha))
	# Sparse chromatic glints near the skyline create a light source cue, not a HUD-like glow.
	# 地平线附近的稀疏彩色亮点暗示环境光源，不做成 HUD 式发光。
	for index in range(5):
		var glow_x := float(index) * (map_width / 5.0) + float(int(region_id.hash() % 71))
		draw_line(Vector2(glow_x, 265.0), Vector2(glow_x + 52.0, 265.0), Color(accent.r, accent.g, accent.b, 0.18), 2.0)

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
			"A13":
				# Floating fragments replace the ordinary skyline at the world's terminal seam.
				# 世界边界处的远景不再是建筑，而是悬浮的断裂碎片。
				var shard_y := base_y - height * 0.55
				draw_colored_polygon(PackedVector2Array([
					Vector2(x + width * 0.12, shard_y), Vector2(x + width * 0.44, shard_y - 16.0),
					Vector2(x + width, shard_y - 9.0), Vector2(x + width * 0.72, shard_y + 5.0)
				]), silhouette)
				draw_line(Vector2(x + width * 0.20, shard_y - 2.0), Vector2(x + width * 0.91, shard_y - 10.0), silhouette_edge, 1.5)
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

	# Biome-specific light and silhouette cues add atmosphere without introducing collision or hiding exits.
	# 区域专属的光影与剪影强化氛围，不新增碰撞，也不遮挡出口。
	match region_id:
		"A2", "H01", "H08", "H09":
			# Low moonbeams cut through the canopy; thin hanging roots frame, rather than fill, the play space.
			# 月光从树冠缝隙落下；细垂根只做边缘构图，不填满可玩空间。
			for shaft in range(5):
				var shaft_x := float((shaft * 487 + seed_offset * 3) % int(map_width))
				draw_colored_polygon(PackedVector2Array([
					Vector2(shaft_x, 72.0), Vector2(shaft_x + 24.0, 72.0),
					Vector2(shaft_x + 108.0, floor_y - 48.0), Vector2(shaft_x + 66.0, floor_y - 48.0)
				]), Color("#9aafbd", 0.018 if region_id == "A2" else 0.012))
			for root in range(7):
				var root_x := float((root * 397 + seed_offset * 5) % int(map_width))
				var root_length := 34.0 + float((root * 29) % 64)
				draw_line(Vector2(root_x, 0.0), Vector2(root_x + 7.0, root_length), Color("#111a20", 0.72), 3.0)
		"A3", "A9", "A12", "H03", "H06", "H07":
			# Sparse broken window lights imply a city beyond the visible route.
			# 稀疏的破窗灯光暗示画面之外仍有城市延伸。
			for window_index in range(18):
				var window_x := float((window_index * 139 + seed_offset * 7) % int(map_width))
				var window_y := 250.0 + float((window_index * 47) % 150)
				var window_color := Color("#c49aa9", 0.13) if region_id != "H07" else Color("#83b4c0", 0.14)
				draw_rect(Rect2(window_x, window_y, 3.0, 8.0), window_color)
			if region_id == "A9" or region_id == "H07":
				for reflection in range(10):
					var reflection_x := float((reflection * 251 + seed_offset) % int(map_width))
					draw_line(Vector2(reflection_x, floor_y - 52.0), Vector2(reflection_x + 18.0, floor_y - 50.0), Color("#9bbbc4", 0.055), 1.0)
		"A4", "H04":
			# Cold reflected light breaks up the reservoir's darkness.
			# 冷色倒影打破水库区域的大面积暗部。
			for reflection in range(12):
				var reflection_x := float((reflection * 211 + seed_offset * 2) % int(map_width))
				var reflection_y := 330.0 + float((reflection * 31) % 105)
				draw_line(Vector2(reflection_x, reflection_y), Vector2(reflection_x + 38.0 + float(reflection % 3) * 17.0, reflection_y + 2.0), Color("#8db8c1", 0.055), 1.5)
		"A5":
			# Distant ember traces remain small so they do not resemble interactive pickups.
			# 远处余烬保持微小，避免被误认为可拾取物。
			for ember in range(9):
				var ember_x := float((ember * 283 + seed_offset) % int(map_width))
				var ember_y := 285.0 + float((ember * 43) % 120)
				draw_circle(Vector2(ember_x, ember_y), 1.4, Color("#c17d68", 0.16))
		"A6", "A10":
			# Narrow, dusty light falls from unseen clerestory windows.
			# 灰尘中的狭窄光柱来自画面外的高侧窗。
			for beam in range(4):
				var beam_x := float((beam * 613 + seed_offset * 2) % int(map_width))
				draw_colored_polygon(PackedVector2Array([
					Vector2(beam_x, 115.0), Vector2(beam_x + 11.0, 115.0),
					Vector2(beam_x + 72.0, floor_y - 60.0), Vector2(beam_x + 44.0, floor_y - 60.0)
				]), Color("#d6c2a0", 0.018))
		"A11":
			# Uneven organic glimmers hint at something breathing behind the masonry.
			# 不均匀的有机微光暗示石墙背后有东西正在呼吸。
			for node_index in range(11):
				var node_x := float((node_index * 227 + seed_offset * 3) % int(map_width))
				var node_y := 255.0 + float((node_index * 37) % 175)
				draw_circle(Vector2(node_x, node_y), 5.0, Color("#8e789f", 0.025))
				draw_circle(Vector2(node_x, node_y), 1.2, Color("#b38bab", 0.12))
		"A13":
			# Broken horizon echoes the terminal anomaly's impossible geometry.
			# 断裂地平线呼应终局区域不可能存在的空间几何。
			for seam in range(8):
				var seam_x := float(seam) * map_width / 8.0 + float(seed_offset)
				draw_line(Vector2(seam_x, 180.0 + float(seam % 3) * 19.0), Vector2(seam_x + 76.0, 176.0 + float(seam % 3) * 19.0), Color("#b99ac7", 0.10), 1.0)

	# A faint horizon line ties distant shapes together without boxing the screen.
	# 淡淡的地平线将远景剪影连接起来，但不把画面框死。
	draw_line(Vector2(0.0, floor_y - 9.0), Vector2(map_width, floor_y - 9.0), Color(atmosphere.r, atmosphere.g, atmosphere.b, 0.10), 1.0)


# Midground accents give underused biomes their own environmental rhythm without affecting traversal.
# 中景强调层为此前细节较少的区域建立独立节奏，不影响任何可通行路线。
func _draw_midground_accents() -> void:
	var seed_offset := int(region_id.hash() % 83)
	match region_id:
		"A1":
			# Snapped stakes and a distant watchline make the starting outskirts feel abandoned.
			# 折断木桩与远处哨线表达起始边境的荒废感。
			for index in range(8):
				var x := float(index) * 287.0 + float(seed_offset)
				var height := 28.0 + float((index * 19) % 31)
				draw_line(Vector2(x, floor_y - 18.0), Vector2(x - 4.0, floor_y - height), Color("#49434a", 0.38), 3.0)
				draw_line(Vector2(x - 4.0, floor_y - height), Vector2(x + 12.0, floor_y - height + 5.0), Color("#6e5d59", 0.30), 2.0)
		"A6", "A10":
			# Suspended censers and fine chains create a sacred interior scale cue.
			# 悬挂香炉与细链条建立教会建筑的纵向尺度。
			for index in range(5):
				var x := float((index * 433 + seed_offset * 2) % int(map_width))
				var drop := 92.0 + float((index * 23) % 58)
				draw_line(Vector2(x, 0.0), Vector2(x + 2.0, drop), Color("#8c795d", 0.25), 1.0)
				draw_arc(Vector2(x + 2.0, drop + 8.0), 7.0, PI, TAU, 12, Color("#c3a56f", 0.22), 1.5)
				draw_circle(Vector2(x + 2.0, drop + 8.0), 2.0, Color("#d8b875", 0.12))
		"A7":
			# Prison chains stop well above the floor route.
			# 监牢铁链始终远离地面通行区域。
			for index in range(7):
				var x := float((index * 311 + seed_offset) % int(map_width))
				var drop := 120.0 + float((index * 37) % 115)
				draw_line(Vector2(x, 0.0), Vector2(x + 1.0, drop), Color("#66788a", 0.26), 2.0)
				for link in range(3):
					var link_y := drop * (float(link + 1) / 4.0)
					draw_arc(Vector2(x, link_y), 3.0, 0.0, TAU, 8, Color("#8aa0b0", 0.22), 1.0)
		"A8":
			# Uneven tomb markers form a low procession instead of another skyline.
			# 高低错落的墓碑队列区别于常规城市天际线。
			for index in range(10):
				var x := float(index) * 241.0 + float(seed_offset)
				var height := 34.0 + float((index * 17) % 46)
				var width := 13.0 + float(index % 3) * 5.0
				draw_rect(Rect2(x, floor_y - height, width, height), Color("#332b40", 0.52))
				draw_colored_polygon(PackedVector2Array([
					Vector2(x - 3.0, floor_y - height + 2.0),
					Vector2(x + width * 0.5, floor_y - height - 8.0),
					Vector2(x + width + 3.0, floor_y - height + 2.0)
				]), Color("#4b3c59", 0.42))
		"A11":
			# Hanging specimen tubes imply a laboratory beyond the room.
			# 悬吊样本管暗示实验室向当前房间之外延伸。
			for index in range(6):
				var x := float((index * 367 + seed_offset * 3) % int(map_width))
				var top := 90.0 + float((index * 29) % 85)
				var bottom := top + 42.0 + float(index % 3) * 18.0
				draw_line(Vector2(x, top), Vector2(x, bottom), Color("#9c6d9c", 0.24), 2.0)
				draw_arc(Vector2(x, top + 3.0), 5.0, PI, TAU, 10, Color("#d18bc7", 0.22), 1.0)
				draw_arc(Vector2(x, bottom), 5.0, 0.0, PI, 10, Color("#d18bc7", 0.22), 1.0)
		"A12":
			# Broken signal wires remain between the inner-city rooflines.
			# 内城区屋顶之间残留断裂的信号线。
			for index in range(4):
				var x := 180.0 + float(index) * 560.0 + float(seed_offset % 37)
				var y := 155.0 + float((index * 41) % 75)
				draw_line(Vector2(x, y), Vector2(x + 125.0, y + 9.0), Color("#b77d7b", 0.20), 1.0)
				draw_line(Vector2(x + 125.0, y + 9.0), Vector2(x + 184.0, y + 2.0), Color("#b77d7b", 0.16), 1.0)
		"H02", "H05", "H06":
			# Hidden chambers carry faint threads like dormant old mechanisms.
			# 隐藏密室悬着细微丝线，像被遗弃的旧机关。
			for index in range(8):
				var x := float((index * 263 + seed_offset) % int(map_width))
				var drop := 65.0 + float((index * 31) % 105)
				draw_line(Vector2(x, 0.0), Vector2(x + 5.0, drop), Color("#a47b9e", 0.18), 1.0)
				draw_circle(Vector2(x + 5.0, drop), 2.0, Color("#d7a5d2", 0.16))
		"H09":
			# Mineral teeth frame the upper corners and leave the central play space open.
			# 矿脉尖齿只压住上方边角，为中央活动空间留白。
			for index in range(6):
				var x := float(index) * 355.0 + float(seed_offset)
				var length := 22.0 + float((index * 13) % 36)
				draw_colored_polygon(PackedVector2Array([
					Vector2(x, 0.0), Vector2(x + 18.0, 0.0),
					Vector2(x + 11.0, length), Vector2(x + 5.0, length * 0.65)
				]), Color("#3c3041", 0.44))


# Broken paving seams and small rubble clusters make the ground read as a surface, not a flat bar.
# 断续石板缝与少量碎石让地面呈现真实材质，而不是一条平色矩形。
func _draw_ground_detail() -> void:
	var atmosphere := _atmosphere_color()
	draw_rect(Rect2(0.0, floor_y, map_width, 3.0), Color(atmosphere.r, atmosphere.g, atmosphere.b, 0.34))
	# Layered stone strata and broad stains break up the uninterrupted floor strip.
	# 分层石材纹理与大块污渍打破整条地面的单调平色。
	var material_shadow := Color("#100f17", 0.46)
	var material_mid := _platform_color().lightened(0.08)
	draw_rect(Rect2(0.0, floor_y + 92.0, map_width, 2.0), material_shadow)
	draw_rect(Rect2(0.0, floor_y + 132.0, map_width, 1.0), Color(material_mid.r, material_mid.g, material_mid.b, 0.40))
	for stain in range(12):
		var stain_x := float((stain * 251 + int(region_id.hash() % 131)) % int(map_width))
		var stain_y := floor_y + 42.0 + float((stain * 29) % 104)
		var stain_width := 24.0 + float((stain * 17) % 48)
		var stain_color := Color("#536a50", 0.18)
		match region_id:
			"A2", "H01", "H08", "H09":
				stain_color = Color("#6c985d", 0.24)
			"A3", "A9", "H03", "H07":
				stain_color = Color("#80506f", 0.22)
			"A4", "H04":
				stain_color = Color("#4b9eae", 0.24)
			"A5":
				stain_color = Color("#a65338", 0.22)
			"A6", "A10":
				stain_color = Color("#a7894e", 0.22)
			"A11", "H02", "H05":
				stain_color = Color("#9e4e8d", 0.24)
			"A13":
				stain_color = Color("#8d6bc5", 0.28)
		draw_rect(Rect2(stain_x, stain_y, stain_width, 2.0 + float(stain % 3)), stain_color)
	# Keep every material mark inside the tile loop; this also ensures details repeat across the whole floor.
	# 所有材质细节都在循环内绘制，确保整段地面重复铺开，而不是只落在最后一块石板上。
	for index in range(1, int(map_width / 180.0)):
		var x := float(index) * 180.0 + float(int(region_id.hash() % 29))
		var seam_height := 7.0 + float((index * 11) % 13)
		draw_line(Vector2(x, floor_y + 25.0), Vector2(x - 4.0, floor_y + 25.0 + seam_height), Color("#0d0b11", 0.42), 1.0)
		if index % 2 == 0:
			draw_line(Vector2(x + 2.0, floor_y + 58.0), Vector2(x + 26.0, floor_y + 55.0), Color("#574750", 0.30), 1.0)
		if index % 3 == 0:
			var pebble_x := x + 32.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(pebble_x, floor_y + 74.0),
				Vector2(pebble_x + 5.0, floor_y + 68.0),
				Vector2(pebble_x + 13.0, floor_y + 75.0)
			]), Color(atmosphere.r, atmosphere.g, atmosphere.b, 0.20))

		# Biome-specific pigments make each floor read differently at a glance.
		# 依照区域加入不同色相，让地面一眼可辨，而不是统一灰色。
		match region_id:
			"A2", "H01", "H08", "H09":
				if index % 2 == 0:
					draw_line(Vector2(x + 14.0, floor_y + 8.0), Vector2(x + 48.0, floor_y + 9.0), Color("#79b66f", 0.34), 2.0)
				if index % 4 == 0:
					draw_circle(Vector2(x + 64.0, floor_y + 34.0), 2.4, Color("#b5d69c", 0.22))
			"A3", "A5", "A8", "A12":
				if index % 2 == 0:
					draw_line(Vector2(x + 38.0, floor_y + 18.0), Vector2(x + 55.0, floor_y + 31.0), Color("#d28a62", 0.28), 1.5)
				if index % 5 == 0:
					draw_colored_polygon(PackedVector2Array([
						Vector2(x + 76.0, floor_y + 52.0), Vector2(x + 88.0, floor_y + 48.0),
						Vector2(x + 98.0, floor_y + 54.0), Vector2(x + 83.0, floor_y + 59.0)
					]), Color("#351d26", 0.48))
			"A4", "A9", "H04", "H07":
				if index % 2 == 0:
					draw_line(Vector2(x + 18.0, floor_y + 42.0), Vector2(x + 74.0, floor_y + 44.0), Color("#62c6d4", 0.28), 2.0)
				if index % 3 == 0:
					draw_line(Vector2(x + 54.0, floor_y + 63.0), Vector2(x + 86.0, floor_y + 62.0), Color("#b2edf0", 0.20), 1.0)
			"A6", "A10":
				if index % 2 == 0:
					draw_line(Vector2(x + 24.0, floor_y + 12.0), Vector2(x + 45.0, floor_y + 12.0), Color("#e6bd70", 0.34), 1.5)
				if index % 4 == 0:
					draw_circle(Vector2(x + 61.0, floor_y + 49.0), 1.8, Color("#ffe0a0", 0.24))
			"A11", "H02", "H03", "H05", "H06":
				if index % 2 == 0:
					draw_line(Vector2(x + 18.0, floor_y + 30.0), Vector2(x + 43.0, floor_y + 34.0), Color("#d66dc2", 0.32), 1.5)
				if index % 4 == 0:
					draw_circle(Vector2(x + 67.0, floor_y + 45.0), 2.4, Color("#ed9be4", 0.20))
			"A13":
				if index % 2 == 0:
					draw_line(Vector2(x + 12.0, floor_y + 19.0), Vector2(x + 31.0, floor_y + 15.0), Color("#d4a1ff", 0.36), 1.5)


func _atmosphere_color() -> Color:
	match region_id:
		"A2", "H01", "H08", "H09":
			return Color("#8fbd86")
		"A3", "A9", "H03", "H07":
			return Color("#d28ab8")
		"A4", "H04":
			return Color("#70c7d8")
		"A5":
			return Color("#ed9165")
		"A6", "A10":
			return Color("#e5c17b")
		"A7":
			return Color("#83b8e4")
		"A8", "H06":
			return Color("#b5a0e6")
		"A11", "H02", "H05":
			return Color("#dc82d0")
		"A12":
			return Color("#e98b77")
		"A13":
			return Color("#d0a4ff")
		_:
			return Color("#b2a0bd")

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
		"A13":
			return Color("#0d0c18")
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
		"A13":
			return Color("#4b3d56")
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
	# Distinct silhouettes make the Bell Grave, canopy, tower ribs, and eastern bridge readable at a glance.
	# 用不同轮廓区分钟墓、树冠、钟楼肋架和东侧残桥。
	draw_rect(Rect2(805, 300, 46, 235), Color("#211f2a"))
	draw_rect(Rect2(816, 315, 24, 176), Color("#11131a"))
	draw_arc(Vector2(828, 300), 54.0, PI, TAU, 24, Color("#65545f"), 5.0)
	draw_line(Vector2(828, 302), Vector2(828, 365), Color("#65545f"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(780, 278), "钟墓外廊", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#82727e"))
	# A broad dead-tree canopy frames the upper loop.
	draw_line(Vector2(850, 315), Vector2(1015, 235), Color("#34343f"), 18.0)
	draw_line(Vector2(1015, 235), Vector2(1185, 265), Color("#34343f"), 15.0)
	draw_line(Vector2(1185, 265), Vector2(1370, 305), Color("#34343f"), 12.0)
	draw_line(Vector2(1015, 235), Vector2(1080, 195), Color("#34343f"), 9.0)
	draw_line(Vector2(1080, 195), Vector2(1200, 210), Color("#34343f"), 7.0)
	# Exposed masonry ribs signal the mid-level return path.
	for rib_x in [1765.0, 1855.0, 1945.0, 2035.0]:
		draw_line(Vector2(rib_x, 290), Vector2(rib_x - 28.0, 505), Color("#3b3540"), 8.0)
	draw_line(Vector2(1745, 315), Vector2(1840, 285), Color("#5a4a57"), 4.0)
	draw_line(Vector2(1840, 285), Vector2(1940, 315), Color("#5a4a57"), 4.0)
	# The eastern bridge can be seen from below, but is reached by a separate climb.
	draw_line(Vector2(2580, 285), Vector2(2750, 245), Color("#4a414d"), 8.0)
	draw_line(Vector2(2750, 245), Vector2(2925, 260), Color("#4a414d"), 8.0)
	draw_line(Vector2(2925, 260), Vector2(3100, 220), Color("#4a414d"), 8.0)
	draw_line(Vector2(3100, 220), Vector2(3290, 255), Color("#4a414d"), 8.0)
	draw_string(ThemeDB.fallback_font, Vector2(2860, 205), "东侧残桥", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#877887"))

	# Exploration tells: the bone-token site below the Bell Grave has crossed road marks,
	# while the far canopy fragment is framed by old trail notches rather than a floating label.
	# 探索线索：钟墓坑底的骨牌地点留下交错路痕；远端树冠残片由旧路标刻痕引导，不用悬浮标签直接告知。
	draw_line(Vector2(928, 610), Vector2(948, 597), Color("#887b70", 0.72), 3.0)
	draw_line(Vector2(948, 597), Vector2(968, 610), Color("#887b70", 0.72), 3.0)
	draw_line(Vector2(968, 610), Vector2(988, 597), Color("#887b70", 0.72), 3.0)
	draw_arc(Vector2(965, 625), 22.0, PI + 0.2, TAU - 0.2, 16, Color("#b2a28b", 0.58), 2.0)
	for notch_x in [3020.0, 3052.0, 3084.0, 3116.0]:
		draw_line(Vector2(notch_x, 322), Vector2(notch_x + 10.0, 309), Color("#b7c29b", 0.72), 2.0)
	draw_line(Vector2(3085, 292), Vector2(3105, 278), Color("#b7c29b", 0.62), 2.0)
	draw_line(Vector2(3105, 278), Vector2(3120, 291), Color("#b7c29b", 0.62), 2.0)

	# Readable room silhouettes: stone masses and root arches create separate visual "rooms"
	# behind the collision-backed ledges. These are intentionally decorative, so they cannot
	# accidentally seal a traversal route while the graybox jump arcs are still being tuned.
	# 房间轮廓：用石壁体块与树根拱架在实体平台后方划分空间。当前只作装饰，
	# 不擅自封死仍在调试中的跳跃通道。

	# West entrance: a low, broken lintel makes the entry feel like a passage into the forest.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 410), Vector2(95, 410), Vector2(130, 438),
		Vector2(185, 438), Vector2(218, 465), Vector2(218, 495),
		Vector2(0, 495)
	]), Color("#20232d"))
	draw_line(Vector2(0, 410), Vector2(95, 410), Color("#5b515c"), 4.0)
	draw_line(Vector2(130, 438), Vector2(185, 438), Color("#5b515c"), 3.0)
	draw_rect(Rect2(30, 495, 16, 86), Color("#292630"))
	draw_rect(Rect2(190, 485, 18, 72), Color("#292630"))

	# Bell Grave is a deep, enclosed shaft; staggered broken masonry follows the actual pit.
	draw_colored_polygon(PackedVector2Array([
		Vector2(842, 438), Vector2(866, 438), Vector2(866, 650),
		Vector2(886, 720), Vector2(920, 770), Vector2(920, 790),
		Vector2(878, 790), Vector2(844, 720)
	]), Color("#302832"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(1048, 438), Vector2(1072, 438), Vector2(1072, 720),
		Vector2(1040, 775), Vector2(1005, 790), Vector2(1005, 770),
		Vector2(1030, 710)
	]), Color("#302832"))
	for seam_y in [492.0, 548.0, 610.0, 680.0, 735.0]:
		draw_line(Vector2(846, seam_y), Vector2(862, seam_y + 7.0), Color("#66515b", 0.72), 2.0)
		draw_line(Vector2(1053, seam_y + 8.0), Vector2(1068, seam_y), Color("#66515b", 0.72), 2.0)
	# A broken chain and a suspended bell silhouette make the shaft readable from its rim.
	draw_line(Vector2(985, 390), Vector2(985, 555), Color("#65545f"), 3.0)
	for chain_y in range(405, 550, 18):
		draw_arc(Vector2(985, float(chain_y)), 4.0, 0.0, TAU, 8, Color("#65545f"), 1.4)
	draw_arc(Vector2(985, 568), 15.0, 0.0, TAU, 2, Color("#8b737e"), 3.0)
	draw_line(Vector2(985, 568), Vector2(985, 592), Color("#8b737e"), 3.0)
	draw_line(Vector2(972, 592), Vector2(998, 592), Color("#8b737e"), 3.0)

	# The canopy is a hollow under-root, not merely a row of floating planks.
	draw_colored_polygon(PackedVector2Array([
		Vector2(790, 258), Vector2(850, 220), Vector2(915, 222),
		Vector2(970, 190), Vector2(1030, 195), Vector2(1088, 225),
		Vector2(1160, 232), Vector2(1235, 265), Vector2(1320, 282),
		Vector2(1395, 320), Vector2(1375, 338), Vector2(1290, 302),
		Vector2(1215, 290), Vector2(1145, 256), Vector2(1075, 249),
		Vector2(1020, 222), Vector2(975, 220), Vector2(920, 252),
		Vector2(855, 250), Vector2(810, 280)
	]), Color("#292a35"))
	draw_line(Vector2(850, 220), Vector2(915, 222), Color("#4b4654"), 5.0)
	draw_line(Vector2(970, 190), Vector2(1030, 195), Color("#4b4654"), 5.0)
	draw_line(Vector2(1088, 225), Vector2(1160, 232), Color("#4b4654"), 4.0)
	# Hanging roots descend between platforms but leave the jumping corridor open.
	for root in [
		PackedVector2Array([Vector2(940, 232), Vector2(950, 280), Vector2(940, 306), Vector2(932, 279)]),
		PackedVector2Array([Vector2(1160, 248), Vector2(1178, 294), Vector2(1168, 315), Vector2(1158, 285)]),
		PackedVector2Array([Vector2(1320, 291), Vector2(1338, 330), Vector2(1328, 346), Vector2(1318, 321)])
	]:
		draw_colored_polygon(root, Color("#3a303c"))

	# Mid-region ruin ribs frame two elevations and a narrow return pocket.
	draw_colored_polygon(PackedVector2Array([
		Vector2(1660, 255), Vector2(1690, 245), Vector2(1715, 420),
		Vector2(1698, 458), Vector2(1680, 430)
	]), Color("#292630"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(2030, 280), Vector2(2060, 292), Vector2(2048, 475),
		Vector2(2028, 508), Vector2(2017, 475)
	]), Color("#292630"))
	draw_line(Vector2(1688, 276), Vector2(1705, 400), Color("#62515e"), 3.0)
	draw_line(Vector2(2044, 310), Vector2(2035, 430), Color("#62515e"), 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(1740, 390), Vector2(1800, 372), Vector2(1860, 390),
		Vector2(1915, 382), Vector2(1985, 410), Vector2(1980, 424),
		Vector2(1912, 402), Vector2(1858, 410), Vector2(1798, 393),
		Vector2(1745, 410)
	]), Color("#342c38"))

	# Eastern ravine: opposing cliff faces and a high broken lintel frame the lower bypass.
	draw_colored_polygon(PackedVector2Array([
		Vector2(2225, 455), Vector2(2250, 445), Vector2(2280, 520),
		Vector2(2310, 585), Vector2(2350, 650), Vector2(2350, 780),
		Vector2(2305, 780), Vector2(2288, 690), Vector2(2250, 610)
	]), Color("#282832"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(2670, 500), Vector2(2700, 475), Vector2(2720, 555),
		Vector2(2740, 625), Vector2(2740, 780), Vector2(2690, 780),
		Vector2(2690, 690), Vector2(2660, 605)
	]), Color("#282832"))
	for crack in [
		PackedVector2Array([Vector2(2250, 510), Vector2(2270, 535), Vector2(2260, 560)]),
		PackedVector2Array([Vector2(2290, 600), Vector2(2310, 620), Vector2(2305, 650)]),
		PackedVector2Array([Vector2(2690, 535), Vector2(2678, 560), Vector2(2695, 585)])
	]:
		draw_polyline(crack, Color("#66545f"), 2.0)
	draw_line(Vector2(2350, 246), Vector2(2435, 205), Color("#514653"), 9.0)
	draw_line(Vector2(2435, 205), Vector2(2560, 165), Color("#514653"), 9.0)
	draw_line(Vector2(2560, 165), Vector2(2685, 205), Color("#514653"), 9.0)
	draw_line(Vector2(2685, 205), Vector2(2805, 260), Color("#514653"), 9.0)

	# Foreground roots at the bottom edge add parallax-like depth without obscuring the Hero.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 760), Vector2(180, 735), Vector2(285, 758),
		Vector2(405, 742), Vector2(520, 770), Vector2(520, 820),
		Vector2(0, 820)
	]), Color("#171921", 0.78))
	draw_colored_polygon(PackedVector2Array([
		Vector2(2760, 795), Vector2(2870, 760), Vector2(2995, 778),
		Vector2(3090, 748), Vector2(3240, 772), Vector2(3370, 750),
		Vector2(3600, 780), Vector2(3600, 850), Vector2(2760, 850)
	]), Color("#171921", 0.72))


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


func _draw_terminal_anomaly_landmarks() -> void:
	# The terminal region abandons believable architecture: broken rings and stairs converge on one impossible horizon.
	# 终局区域不再遵守正常建筑逻辑：断裂圆环与阶梯共同指向不可能存在的地平线。
	var halo_center := Vector2(1320.0, 285.0)
	for ring in range(5):
		var radius := 72.0 + float(ring) * 28.0
		var alpha := 0.12 - float(ring) * 0.016
		draw_arc(halo_center, radius, PI * 0.12 + float(ring) * 0.17, TAU * 0.82 - float(ring) * 0.11, 44, Color("#b99ac7", alpha), 2.0)
		draw_arc(halo_center, radius + 7.0, PI * 1.08, PI * 1.72, 22, Color("#8e789f", alpha * 0.72), 1.0)

	# Thin, suspended fragments imply that several staircases occupy the same space.
	# 悬浮的细长碎片暗示多段阶梯同时占据同一空间。
	for index in range(8):
		var x := 170.0 + float(index) * 300.0
		var y := 250.0 + float((index * 43) % 150)
		var width := 72.0 + float((index * 17) % 54)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, y + 10.0), Vector2(x + width * 0.18, y),
			Vector2(x + width, y + 2.0), Vector2(x + width * 0.82, y + 12.0)
		]), Color("#4a3d57", 0.58))
		draw_line(Vector2(x + width * 0.18, y), Vector2(x + width, y + 2.0), Color("#b69ac5", 0.28), 1.5)
		if index % 2 == 0:
			draw_line(Vector2(x + width * 0.52, y + 12.0), Vector2(x + width * 0.40, y + 44.0), Color("#9c7fae", 0.22), 1.0)

	# A central, fractured monolith acts as a visual anchor, not a literal door or character silhouette.
	# 中央断裂碑体只作为视觉锚点，不伪装成实际出口或角色轮廓。
	draw_colored_polygon(PackedVector2Array([
		Vector2(1255.0, 475.0), Vector2(1278.0, 350.0), Vector2(1304.0, 315.0),
		Vector2(1320.0, 345.0), Vector2(1342.0, 300.0), Vector2(1374.0, 475.0),
		Vector2(1350.0, 490.0), Vector2(1290.0, 486.0)
	]), Color("#292334", 0.92))
	draw_polyline(PackedVector2Array([
		Vector2(1278.0, 350.0), Vector2(1310.0, 390.0), Vector2(1296.0, 432.0),
		Vector2(1335.0, 452.0), Vector2(1320.0, 486.0)
	]), Color("#b69ac5", 0.48), 2.0, true)
	draw_line(Vector2(80.0, 505.0), Vector2(map_width - 80.0, 505.0), Color("#8f789e", 0.13), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(1050.0, 175.0), "没有两段阶梯通往同一处地方", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#a88fb7", 0.70))


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

