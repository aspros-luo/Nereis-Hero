extends Node2D
## Shared playable graybox for the first connected world-map loop.
## 第一条互通地图环路的通用可玩灰盒场景。

const HERO_SCENE: PackedScene = preload("res://scenes/player/hero.tscn")
const ENEMY_ACTOR_SCENE: PackedScene = preload("res://scenes/characters/enemy_actor_base.tscn")
const NARRATIVE_SCENE: PackedScene = preload("res://scenes/core/narrative_manager.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const INTERACTION_DOOR_SCENE: PackedScene = preload("res://scenes/world/interaction_door.tscn")
const AUTO_ROOM_TRANSITION_SCENE: PackedScene = preload("res://scenes/world/automatic_room_transition.tscn")
const REST_POINT_SCENE: PackedScene = preload("res://scenes/world/rest_point.tscn")
const RESONANCE_SECRET_GATE_SCENE: PackedScene = preload("res://scenes/world/resonance_secret_gate.tscn")
const LOCAL_RESONANCE_ROUTE_SCENE: PackedScene = preload("res://scenes/world/resonance_local_route.tscn")
const THIRD_CORD_FRAGMENT_SCENE: PackedScene = preload("res://scenes/world/third_cord_fragment.tscn")
const WORLD_ITEM_PICKUP_SCENE: PackedScene = preload("res://scenes/world/world_item_pickup.tscn")
const REGION_AMBIENCE_SCENE: PackedScene = preload("res://scenes/effects/region_ambience.tscn")
const SOLID_RECTANGLE_SCENE: PackedScene = preload("res://scenes/world/solid_rectangle.tscn")
const DOOR_ARCH_SCENE: PackedScene = preload("res://scenes/world/door_arch.tscn")
const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")
const ENDGAME_GATE_SCRIPT = preload("res://scripts/core/endgame_gate.gd")
const CULTIST_SCRIPT = preload("res://scripts/enemies/cultist.gd")
const PALE_HOUND_SCRIPT = preload("res://scripts/enemies/pale_hound.gd")
const BANDIT_RAIDER_SCRIPT = preload("res://scripts/enemies/bandit_raider.gd")
const RESEARCH_HUSK_SCRIPT = preload("res://scripts/enemies/research_husk.gd")
const CHURCH_INQUISITOR_SCRIPT = preload("res://scripts/enemies/church_inquisitor.gd")
const BELL_WRAITH_SCRIPT = preload("res://scripts/enemies/bell_wraith.gd")
const FOREST_BACKDROP = preload("res://assets/art/backdrops/forest_backdrop.svg")
const RUINS_BACKDROP = preload("res://assets/art/backdrops/ruins_backdrop.svg")
const CHURCH_BACKDROP = preload("res://assets/art/backdrops/church_backdrop.svg")
const ELDRITCH_BACKDROP = preload("res://assets/art/backdrops/eldritch_backdrop.svg")
const STONE_FLOOR_STRIP = preload("res://assets/art/backdrops/stone_floor_strip.svg")

const ENCOUNTER_ACTIVATE_RANGE := 420.0
const AUTHORED_TERRAIN_REGIONS := ["A3", "A4", "A6", "A7", "A8", "A9", "A10", "A11", "A12", "A13", "H01", "H02", "H03", "H04", "H05", "H06", "H07", "H08", "H09"]
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
	if region_id in AUTHORED_TERRAIN_REGIONS and get_node_or_null("AuthoredTerrain") == null:
		push_error("[NEREIS][MAP][AUTHORED_TERRAIN_MISSING] region=%s scene=%s" % [region_id, scene_file_path])
		return
	if region_id == "A2" and room_id.is_empty():
		push_error("[NEREIS][A2][LEGACY_RUNTIME_DISABLED] Load A2-R01 through A2-R06 authored room scenes")
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

	# Configure legacy procedural platforms before the floor; authored A2 room scenes bypass this path.
	# 旧区域的程序化平台先于地面登记；A2 手工房间场景不会进入这条路径。
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
	_bind_authored_region_sources()
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
		get_tree().change_scene_to_file("res://scenes/debug/world_map_test_menu.tscn")

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
	var enemy := ENEMY_ACTOR_SCENE.instantiate() as CharacterBody2D
	if enemy == null:
		push_error("[NEREIS][MAP] Failed to instantiate enemy actor scene for " + enemy_name)
		return
	enemy.set_script(enemy_script)
	enemy.name = enemy_name
	enemy.position = Vector2(spawn_x, floor_y)
	var body_collision := enemy.get_node("CollisionShape2D") as CollisionShape2D
	var body_capsule := body_collision.shape as CapsuleShape2D
	body_capsule.radius = body_radius
	body_capsule.height = body_height
	body_collision.position = Vector2(0.0, -body_height * 0.5)
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
	var pickup := THIRD_CORD_FRAGMENT_SCENE.instantiate() as Node2D
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
		return floor_y - 160.0
	if region_id == "A2" and side == "bell_gate":
		# R04's authored CryptLanding top is at world y=1035.
		# R04 的 CryptLanding 实体平台顶面位于世界坐标 y=1035。
		return 1035.0
	# C04 must return to the actual old-pilgrim upper route on both sides.
	# C04 双向回程都必须落在旧朝圣高路的实际上层平台。
	if region_id == "A2" and side == "old_pilgrim_highroad":
		# C04 arrives on R05's eastern upper platform at world y=440.
		# C04 回到 R05 东端高位平台，世界坐标 y=440。
		return floor_y - 210.0
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
		# C04 returns to R05's eastern landing and remains outside the exit trigger.
		# C04 回到 R05 东端落脚面，并与出口触发区保持净距。
		return 1980.0
	if region_id == "A5" and side == "old_pilgrim_highroad":
		# C04 optional winch branch is at x=3900; arrive on its supported upper landing.
		# C04可选绞盘支路位于x=3900；从A2返回时落在有承托的高台。
		return 3820.0
	if region_id == "A2" and side == "bell_gate":
		# Leave the H02 entrance's interaction radius after returning from the hidden chamber.
		# 从倒响钟室返回时，出生点应离入口足够远，避免一落地就抢占 E 交互。
		return 1100.0
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
	var authored_hero := get_node_or_null("Hero") as CharacterBody2D
	if authored_hero != null:
		hero = authored_hero
	else:
		hero = HERO_SCENE.instantiate() as CharacterBody2D
		if hero == null:
			push_error("[NEREIS][REGION] Failed to instantiate Hero scene")
			return
		hero.name = "Hero"
		add_child(hero)
	# A specialized room may override _on_hero_defeated; the default handler delegates to Hero's built-in fade/checkpoint recovery.
	# 特殊房间可覆写死亡处理；默认处理器交由 Hero 自带的黑屏与检查点恢复流程。
	hero.defer_death_recovery = true
	hero.position = Vector2(spawn_x, floor_y if spawn_y < 0.0 else spawn_y)
	if not hero.defeated.is_connected(_on_hero_defeated):
		hero.defeated.connect(_on_hero_defeated)
	# Room-streamed A2 keeps an existing A2 checkpoint across door transitions; ordinary A2 entry
	# initializes a room-aware checkpoint so cross-room death recovery has a valid destination.
	# A2 房间切换时保留已经启用的 A2 检查点；首次进入才建立带房间 ID 的默认检查点。
	if region_id == "A2" and not room_id.is_empty():
		var valid_a2_checkpoint := WorldState.checkpoint_room_id in [
			"A2-R01", "A2-R02", "A2-R03", "A2-R04", "A2-R05", "A2-R06"
		]
		if not WorldState.checkpoint_active or not valid_a2_checkpoint:
			WorldState.set_checkpoint(hero.global_position, room_id)
	else:
		WorldState.set_checkpoint(hero.global_position)

	camera = hero.get_node_or_null("HeroCamera") as Camera2D
	if camera != null:
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 6.0
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(map_width)
		camera.limit_bottom = int(room_height) if region_id == "A5" and not room_id.is_empty() else (1200 if region_id == "A2" else 720)

func _on_hero_defeated() -> void:
	# This signal fires before Hero checks defer_death_recovery. Let the default Hero path run unless a subclass owns the transition.
	# 该信号在 Hero 检查 defer_death_recovery 前同步触发；默认交还 Hero 自带流程，特殊子类可接管转场。
	if is_instance_valid(hero):
		hero.defer_death_recovery = false


func _spawn_ui() -> void:
	narrative = get_node_or_null("Narrative") as CanvasLayer
	if narrative == null:
		narrative = NARRATIVE_SCENE.instantiate() as CanvasLayer
		if narrative != null:
			add_child(narrative)
	hud = get_node_or_null("HUD") as CanvasLayer
	if hud == null:
		hud = HUD_SCENE.instantiate() as CanvasLayer
		if hud != null:
			add_child(hud)
	if hud != null:
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


func _spawn_world_item_pickup(pickup_id: String, item_id: String, node_name: String, pickup_position: Vector2) -> void:
	if pickup_id.is_empty() or pickup_id in WorldState.collected_world_item_ids:
		return
	var pickup := WORLD_ITEM_PICKUP_SCENE.instantiate() as Node2D
	pickup.name = node_name
	pickup.position = pickup_position
	pickup.set("pickup_id", pickup_id)
	pickup.set("item_id", item_id)
	pickup.set("prompt_text", "E  拾取")
	add_child(pickup)
func _spawn_region_ambience() -> void:
	var ambience := REGION_AMBIENCE_SCENE.instantiate() as Node2D
	ambience.name = "RegionAmbience"
	ambience.set("map_width", map_width)
	ambience.set("floor_y", floor_y)
	ambience.set("region_id", region_id)
	ambience.set("atmosphere_color", _atmosphere_color())
	add_child(ambience)
func _create_floor() -> void:
	if get_node_or_null("AuthoredTerrain") != null:
		return
	if assembly_child_mode:
		_configure_a5_room_floor()
		return
	if region_id == "A5" and not room_id.is_empty():
		_configure_a5_room_floor()
		return
	# A2 ground collision belongs to its individual room .tscn files; never create a region-wide floor here.
	# A2 地表碰撞由各独立房间 .tscn 负责；此处禁止生成区域级整片地面。
	if region_id == "A2":
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
	var floor := SOLID_RECTANGLE_SCENE.instantiate() as StaticBody2D
	floor.name = segment_name
	floor.position.x = start_x
	var shape := floor.get_node("CollisionShape2D") as CollisionShape2D
	var rectangle := shape.shape as RectangleShape2D
	rectangle.size = Vector2(segment_width, 40.0)
	shape.position = Vector2(segment_width * 0.5, floor_y + 20.0)
	add_child(floor)
func _create_boundaries() -> void:
	if get_node_or_null("AuthoredTerrain") != null:
		return
	if assembly_child_mode:
		return
	if get_node_or_null("RegionBoundary_0") != null and get_node_or_null("RegionBoundary_1") != null:
		return
	var wall_height := 1100.0
	var wall_center_y := 500.0
	if region_id == "A2" and not room_id.is_empty():
		wall_height = room_height + 200.0
		wall_center_y = room_height * 0.5
	elif region_id == "A5" and not room_id.is_empty():
		wall_height = maxf(1100.0, room_height + 400.0)
		wall_center_y = (room_height + 200.0) * 0.5
	var index := 0
	for x in [-20.0, map_width + 20.0]:
		var wall := SOLID_RECTANGLE_SCENE.instantiate() as StaticBody2D
		wall.name = "RegionBoundary_%d" % index
		var shape := wall.get_node("CollisionShape2D") as CollisionShape2D
		var rectangle := shape.shape as RectangleShape2D
		rectangle.size = Vector2(40.0, wall_height)
		shape.position = Vector2(x, wall_center_y)
		add_child(wall)
		index += 1
func _ready_a5_assembly_child() -> void:
	# A5 assembly children read collision geometry from their authored .tscn node trees.
	# A5 组装子房间只读取场景树中的实体碰撞；这里不再创建地形节点。
	a5_room_blocks.clear()
	a5_room_floor_gaps.clear()
	a5_room_floor_segments.clear()
	platforms.clear()
	floor_y = maxf(540.0, room_height - 180.0)
	for child in get_children():
		if not (child is StaticBody2D):
			continue
		var body := child as StaticBody2D
		var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or not (collision.shape is RectangleShape2D):
			continue
		var shape := collision.shape as RectangleShape2D
		var node_name := str(body.name)
		if node_name.begins_with("A5RoomPlatform_"):
			platforms.append(Rect2(body.position, shape.size))
		elif node_name.begins_with("A5RoomRubble_"):
			a5_room_blocks.append(Rect2(body.position, shape.size))
		elif node_name.begins_with("A5RoomGround_"):
			a5_room_floor_segments.append(Vector2(body.position.x, shape.size.x))
	var cursor := 0.0
	for segment in a5_room_floor_segments:
		if segment.x > cursor:
			a5_room_floor_gaps.append(Vector2(cursor, segment.x - cursor))
		cursor = maxf(cursor, segment.x + segment.y)
	if cursor < map_width:
		a5_room_floor_gaps.append(Vector2(cursor, map_width - cursor))
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
		var room_id_value := str(room_data.get("id", ""))
		var room_node_name := room_id_value.replace("-", "_")
		var room := get_node_or_null(room_node_name) as Node2D
		if room == null:
			push_error("[NEREIS][A5_ASSEMBLY][AUTHORED_ROOM_MISSING] expected editor-authored child: " + room_node_name)
			return
		if not bool(room.get("assembly_child_mode")):
			push_error("[NEREIS][A5_ASSEMBLY][AUTHORED_ROOM_MODE] room must be geometry-only: " + room_node_name)
			return
		var room_size: Array = room_data.get("size_screens", [1, 1])
		if room_size.size() != 2:
			push_error("[NEREIS][A5_ASSEMBLY] Invalid room size: " + room_id_value)
			return
		var expected_width := float(room_size[0]) * 1280.0
		var expected_height := float(room_size[1]) * 720.0
		if not is_equal_approx(float(room.get("map_width")), expected_width) or not is_equal_approx(float(room.get("room_height")), expected_height):
			push_error("[NEREIS][A5_ASSEMBLY][ROOM_SIZE_MISMATCH] room=%s expected=%.0fx%.0f" % [room_id_value, expected_width, expected_height])
			return
		room_by_id[room_id_value] = room
		max_right = maxf(max_right, room.position.x + expected_width)
		min_top = minf(min_top, room.position.y)
		max_bottom = maxf(max_bottom, room.position.y + expected_height)
	if room_by_id.size() != rooms.size():
		push_error("[NEREIS][A5_ASSEMBLY] Not all editor-authored room scenes are present")
		return
	# Room positions are authored directly in old_battlefield.tscn. Runtime validates and reads
	# their bounds but never instantiates or repositions fixed room geometry.
	# 固定房间的位置由 old_battlefield.tscn 直接维护；运行时只校验与读取边界，不实例化或重排地形。
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
	# _spawn_hero() creates HeroCamera before the full A5 bounds are finalized.
	# Reapply limits after assembling all 22 rooms so the camera can follow vertical routes.
	if is_instance_valid(camera):
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(map_width)
		camera.limit_bottom = int(room_height)
	_spawn_ui()
	_bind_authored_region_sources()
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
	var requires_interaction := initial_state == "blocked"
	var door_scene: PackedScene = INTERACTION_DOOR_SCENE if requires_interaction else AUTO_ROOM_TRANSITION_SCENE
	var door := door_scene.instantiate() as Area2D
	if not requires_interaction:
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
	var collision := door.get_node("CollisionShape2D") as CollisionShape2D
	var rectangle := collision.shape as RectangleShape2D
	rectangle.size = Vector2(108.0, 86.0) if requires_interaction else Vector2(76.0, 128.0)
	collision.position = Vector2(0.0, -34.0) if requires_interaction else Vector2(0.0, -64.0)
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
	var arch := DOOR_ARCH_SCENE.instantiate() as Line2D
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
	var body := SOLID_RECTANGLE_SCENE.instantiate() as StaticBody2D
	body.name = "A5RoomRubble_%03d" % a5_room_blocks.size()
	body.position = rect.position
	var shape := body.get_node("CollisionShape2D") as CollisionShape2D
	var collision := shape.shape as RectangleShape2D
	collision.size = rect.size
	shape.position = rect.size * 0.5
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


func _configure_platforms() -> void:
	platforms.clear()
	var authored_terrain := get_node_or_null("AuthoredTerrain")
	if authored_terrain != null:
		for child in authored_terrain.get_children():
			if not (child is StaticBody2D) or not str(child.name).begins_with("Platform_"):
				continue
			var collision := child.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if collision == null or not (collision.shape is RectangleShape2D):
				continue
			var rectangle := collision.shape as RectangleShape2D
			platforms.append(Rect2(child.position, rectangle.size))
		return
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
			# A2 uses a2_room_runtime.gd plus authored room scenes; no procedural platform fallback.
			# A2 使用 a2_room_runtime.gd 与手工房间场景，不再生成程序化平台。
			pass
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
		"A3", "A4", "A6", "A7", "A8", "A9", "A10", "A11", "A12", "A13", "H01", "H02", "H03", "H04", "H05", "H06", "H07", "H08", "H09":
			pass
func _add_platform(rect: Rect2) -> void:
	platforms.append(rect)
	var body := SOLID_RECTANGLE_SCENE.instantiate() as StaticBody2D
	if region_id == "A5" and not room_id.is_empty():
		body.name = "A5RoomPlatform_%03d" % platforms.size()
	var shape := body.get_node("CollisionShape2D") as CollisionShape2D
	var rectangle := shape.shape as RectangleShape2D
	body.position = rect.position
	rectangle.size = rect.size
	shape.position = rect.size * 0.5
	shape.one_way_collision = true
	add_child(body)
func _register_authored_platform(rect: Rect2) -> void:
	# Authored room scenes own the StaticBody2D collision nodes; this list is only for the shared material renderer.
	# 房间场景拥有实体碰撞节点；此数组只供共享材质渲染使用。
	platforms.append(rect)

func _spawn_region_rest_point() -> void:
	# Fixed region rest points are authored in their .tscn scene trees.
	# 固定休息点由对应区域 .tscn 预置，运行时不得生成或移动。
	if get_node_or_null("AuthoredTerrain") != null:
		return
	if region_id == "A5":
		# A5 is intentionally back to one main region scene while A3/A4 are designed.
		# A5 暂时恢复单一主区域场景；等 A3/A4 设计完成后再重做内部结构。
		if not room_id.is_empty():
			return
		var authored_rest := get_node_or_null("RegionRestPoint_A5") as Node2D
		if authored_rest == null:
			push_error("[NEREIS][A5][AUTHORED_REST_MISSING] expected RegionRestPoint_A5")
			return
		if authored_rest.position.x < 0.0 or authored_rest.position.x > map_width:
			push_error("[NEREIS][A5][REST_OUT_OF_BOUNDS] position=%s width=%.1f" % [str(authored_rest.position), map_width])
		return
	push_error("[NEREIS][MAP][AUTHORED_REST_MISSING] region=%s" % region_id)

func _bind_authored_region_sources() -> void:
	# Fixed anomaly clues are scene-authored; runtime only wires their state callbacks.
	# 固定异常线索由场景预置；运行时只绑定状态回调，不创建或移动线索节点。
	for child in get_children():
		if not child is Node2D or not child.has_signal("activated"):
			continue
		if not child.get("source_id") is String:
			continue
		var source_id := str(child.get("source_id"))
		var ability_id := str(child.get("unlock_ability_id"))
		var callback := Callable(self, "_on_source_activated").bind(source_id, ability_id)
		if not child.activated.is_connected(callback):
			child.activated.connect(callback)

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
		"res://scenes/regions/terminal_anomaly.tscn", "west"
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
		"res://scenes/regions/forgotten_city.tscn", "bell_drop",
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
			push_error("[NEREIS][A2][LEGACY_EXITS_DISABLED] Use the six authored A2 room scenes")
			return
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
						"res://scenes/regions/village_hub.tscn", "city_cut_return"
					)
			_spawn_exit_door(
				72.0, "E  返回旧朝圣路", "ash_forest",
				"res://scenes/rooms/a2_fog_forest/runtime/a2_r06_room.tscn", "a2_r06_c03_return",
				true, "", "", floor_y - 130.0
			)
			# The sewer descent branches off mid-market; the main road continues to A5.
			# 下水道入口位于市场中段，城区东侧主路继续通往 A5。
			# C05 branches off the raised pipe-walk, not the uninterrupted street floor.
			# C05 从抬高的管线栈道分出，避免地下枢纽入口与城区地面主路混为一条直线。
			_spawn_exit_door(
				1600.0, "E  沿旧管线栈道下行至水库", "sewer_reservoir",
				"res://scenes/regions/sewer_reservoir.tscn", "west",
				true, "", "", floor_y - 115.0
			)
			# The city-to-battlefield route crosses a visible rooftop parapet, not the flat ground boundary.
			# 城区通往战场的主路经过可见的残墙高台，不再与地面右边界连成一条直线。
			_spawn_exit_door(
				map_width - 360.0, "E  沿残墙高路前往战场", "old_battlefield",
				"res://scenes/regions/old_battlefield.tscn", "city_highroad",
				true, "", "", floor_y - 130.0
			)
			if "reached_A9_via_A8_then_opened_old_lift_from_A9" in WorldState.achievement_flags:
				# C16 returns through the elevated old lift on the far eastern rooftop, distinct from H03 and H05.
				# C16 从东侧高位旧升降机返回王城外环，与 H03、H05 分离。
				_spawn_exit_door(
					2040.0, "E  经东侧高位旧升降机返回王城外环", "royal_outer_ring",
					"res://scenes/regions/royal_outer_ring.tscn", "old_lift",
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
					"res://scenes/hidden_regions/silent_bell_room.tscn", "bell_drop_entry"
				)
			# C10 reverse door: only exists after the bell-tower drop has been opened from A6.
			# C10 反向门：必须先从 A6 开启钟塔落差，A3 才生成回程捷径。
			if "opened_bell_tower_drop" in WorldState.achievement_flags:
				_spawn_exit_door(
					1710.0, "E  返回修道院落差口", "monastery_tower",
					"res://scenes/regions/monastery_tower.tscn", "bell_drop"
				)
			# C10's destination is the monastery tower, so the return spawn must use the drop-side mapping.
			# C10 的回程目的地是修道院塔，因此出生点必须使用钟塔落差侧的映射。
		"A4":
			# C05 is paired with A3's raised pipe-walk; the reservoir-side hatch must not fall back to ground level.
			# C05 与 A3 高架管线配对；水库侧检修舱口不能退回地面高度。
			_spawn_exit_door(
				72.0, "E  打开上层检修舱口", "forgotten_city",
				"res://scenes/regions/forgotten_city.tscn", "sewer",
				true, "opened_sewer_inspection_hatch_from_A4", "E  返回城区", floor_y - 115.0
			)
			# C06 is a one-way return shortcut from the reservoir to the village well.
			# C06 是从旧水库返回村庄的单向捷径；首次互动开闸，再次互动才转场。
			_spawn_exit_door(
				2220.0, "E  打开村庄井道水闸", "village",
				"res://scenes/regions/village_hub.tscn", "well_exit",
				true, "opened_watergate_and_village_well_exit", "E  返回边境村庄"
			)
			_spawn_h04_gate(1780.0)
			if "reached_A7_then_opened_supply_tunnel" in WorldState.achievement_flags:
				_spawn_exit_door(
					1050.0, "E  返回监牢", "prison_depths",
					"res://scenes/regions/prison_depths.tscn", "supply_tunnel",
					true, "", "", floor_y - 75.0
				)
			if "reached_A8_via_A7_then_opened_royal_tomb_gate" in WorldState.achievement_flags:
				_spawn_exit_door(
					1320.0, "E  返回旧王墓", "royal_tomb",
					"res://scenes/regions/royal_tomb.tscn", "royal_tomb_waterway",
					true, "", "", floor_y - 85.0
				)
			if "reached_A9_then_opened_royal_drain_from_outer_ring" in WorldState.achievement_flags:
				_spawn_exit_door(
					1650.0, "E  返回王城外环", "royal_outer_ring",
					"res://scenes/regions/royal_outer_ring.tscn", "royal_drain",
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
						"res://scenes/regions/forgotten_city.tscn", "city_highroad_return",
						true, "", "", entry_room.position.y + 410.0
					)
				var exit_room := _get_a5_assembled_room("A5-R20")
				if exit_room != null:
					_spawn_exit_door(
						exit_room.position.x + 1200.0, "E  沿残墙高路进入修道院", "monastery_tower",
						"res://scenes/regions/monastery_tower.tscn", "battlefield_entry", true, "", "", exit_room.position.y + 410.0
					)
				if WorldState.is_hidden_path_opened("H02"):
					var hidden_room := _get_a5_assembled_room("A5-R14")
					if hidden_room != null:
						_spawn_exit_door(
							hidden_room.position.x + 1080.0, "E  打开旧钟塔通路", "hidden_bell_chamber",
							"res://scenes/hidden_regions/hidden_bell_chamber.tscn", "bell_tower_entry",
							true, "opened_old_bell_tower_connection", "E  进入倒响钟室", hidden_room.position.y + 620.0
						)
				var winch_room := _get_a5_assembled_room("A5-R16")
				if winch_room != null:
					_spawn_exit_door(
						winch_room.position.x + 980.0, "E  打开旧朝圣高路", "ash_forest",
						"res://scenes/rooms/a2_fog_forest/runtime/a2_r05_room.tscn", "a2_r05_c04_return",
						true, "reached_A5_and_opened_old_pilgrim_highroad", "E  沿旧朝圣高路返回",
						winch_room.position.y + 610.0
					)
			else:
				_spawn_exit_door(
					180.0, "E  沿残墙高路返回被遗忘的城区", "forgotten_city",
					"res://scenes/regions/forgotten_city.tscn", "city_highroad_return",
					true, "", "", floor_y - 130.0
				)
				_spawn_exit_door(
					5350.0, "E  沿残墙高路进入修道院", "monastery_tower",
					"res://scenes/regions/monastery_tower.tscn", "battlefield_entry", true, "", "", floor_y - 90.0
				)
				if WorldState.is_hidden_path_opened("H02"):
					_spawn_exit_door(
						4500.0, "E  打开旧钟塔通路", "hidden_bell_chamber",
						"res://scenes/hidden_regions/hidden_bell_chamber.tscn", "bell_tower_entry",
						true, "opened_old_bell_tower_connection", "E  进入倒响钟室"
					)
				_spawn_exit_door(
					3900.0, "E  打开旧朝圣高路", "ash_forest",
					"res://scenes/rooms/a2_fog_forest/runtime/a2_r05_room.tscn", "a2_r05_c04_return",
					true, "reached_A5_and_opened_old_pilgrim_highroad", "E  沿旧朝圣高路返回",
					floor_y - 140.0
				)
		"A6":
			_spawn_exit_door(
				72.0, "E  返回边境战场", "old_battlefield",
				"res://scenes/regions/old_battlefield.tscn", "monastery_return"
			)
			_spawn_exit_door(
				map_width - 72.0, "E  深入监牢", "prison_depths",
				"res://scenes/regions/prison_depths.tscn", "west"
			)
			_spawn_h05_gate(1660.0)
			# C10 is a physical monastery shortcut, independent of the optional H05 secret room.
			# C10 是修道院的实体捷径，不应被可选隐藏区 H05 的发现状态锁死。
			# C10 is created after the bell warden drops the winch key.
			# C10 只有在钟塔守卫掉落绞盘钥匙后才出现。
		"A7":
			_spawn_exit_door(
				72.0, "E  返回修道院", "monastery_tower",
				"res://scenes/regions/monastery_tower.tscn", "east"
			)
			# C13 is deliberately elevated: the prison maintenance shaft must be climbed before the tomb.
			# C13 刻意设置为高位出口：玩家必须先攀上监牢维护竖井，才能进入王墓。
			_spawn_exit_door(
				map_width - 72.0, "E  沿维护竖井进入旧王墓", "royal_tomb",
				"res://scenes/regions/royal_tomb.tscn", "maintenance_shaft_entry",
				true, "", "", floor_y - 180.0
			)
			# C12: unlock the supply tunnel from the prison side; the first E opens it, the second traverses.
			# C12：从监牢侧开启补给隧道；第一次 E 开门，第二次 E 才转场。
			_spawn_exit_door(
				520.0, "E  打开补给隧道", "sewer_reservoir",
				"res://scenes/regions/sewer_reservoir.tscn", "prison_tunnel",
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
				"res://scenes/regions/prison_depths.tscn", "maintenance_shaft_return",
				true, "", "", floor_y - 180.0
			)
			_spawn_exit_door(
				map_width - 72.0, "E  进入王城外环", "royal_outer_ring",
				"res://scenes/regions/royal_outer_ring.tscn", "west"
			)
			# C07: the royal-tomb shortcut back to the reservoir is unlocked from A8.
			# C07：旧王墓返回旧水库的捷径只能在 A8 侧开启。
			_spawn_exit_door(
				520.0, "E  打开王墓水道", "sewer_reservoir",
				"res://scenes/regions/sewer_reservoir.tscn", "royal_tomb_waterway",
				true, "reached_A8_via_A7_then_opened_royal_tomb_gate", "E  沿王室水道返回",
				floor_y - 165.0
			)
			_spawn_h06_gate(1870.0)
			if WorldState.is_hidden_path_opened("H04"):
				_spawn_exit_door(
					930.0, "E  打开王墓侧门", "reflected_stairwell",
					"res://scenes/hidden_regions/reflected_stairwell.tscn", "royal_tomb_side_entry",
					true, "opened_royal_tomb_side_door", "E  进入倒影阶梯"
				)
			_spawn_a11_maintenance_gate(2310.0)

		"A9":
			_spawn_exit_door(
				72.0, "E  返回旧王墓", "royal_tomb",
				"res://scenes/regions/royal_tomb.tscn", "east"
			)
			_spawn_exit_door(
				2350.0, "E  沿外环屋顶阶梯登上大圣堂", "grand_cathedral",
				"res://scenes/regions/grand_cathedral.tscn", "cathedral_roof", true, "", "", floor_y - 180.0
			)
			if WorldState.is_hidden_path_opened("H03"):
				_spawn_exit_door(
					1250.0, "E  打开旧服务门", "erased_third_street",
					"res://scenes/hidden_regions/erased_third_street.tscn", "third_street_entry",
					true, "opened_old_service_door", "E  进入第三街"
				)
			if WorldState.is_hidden_path_opened("H06"):
				_spawn_exit_door(
					2200.0, "E  打开王室运输侧门", "erased_royal_name_corridor",
					"res://scenes/hidden_regions/erased_royal_name_corridor.tscn", "royal_transport_entry",
					true, "opened_royal_transport_side_door", "E  进入王名抹除廊"
				)
			_spawn_a9_mirror_gate(1850.0)
			if "reached_A12_via_A10_then_opened_inner_city_side_gate" in WorldState.achievement_flags:
				_spawn_exit_door(
					900.0, "E  返回王室内城", "inner_city",
					"res://scenes/regions/inner_city.tscn", "inner_city_side_gate"
				)
			# C16: reconnect A9 to A3 after the old lift is opened from the outer ring.
			# C16：从王城外环开启旧升降机后，重新连通 A9 与 A3。
			_spawn_exit_door(
				520.0, "E  打开旧升降梯", "forgotten_city",
				"res://scenes/regions/forgotten_city.tscn", "old_lift",
				true, "reached_A9_via_A8_then_opened_old_lift_from_A9", "E  乘旧升降梯返回",
				floor_y - 110.0
			)
			# C23: keep the high drain door on the supported service ledge and clear of C18 at x=900.
			# C23：高位排水门必须落在承托栈台上，并与 x=900 的 C18 保持净距。
			_spawn_exit_door(
				740.0, "E  打开王城排水门", "sewer_reservoir",
				"res://scenes/regions/sewer_reservoir.tscn", "royal_drain",
				true, "reached_A9_then_opened_royal_drain_from_outer_ring", "E  沿王城排水道返回",
				floor_y - 150.0
			)
		"A10":
			_spawn_exit_door(
				72.0, "E  返回王城外环", "royal_outer_ring",
				"res://scenes/regions/royal_outer_ring.tscn", "cathedral_roof_return",
				true, "", "", floor_y - 180.0
			)
			_spawn_exit_door(
				map_width - 72.0, "E  进入王室内城", "inner_city",
				"res://scenes/regions/inner_city.tscn", "west"
			)
			_spawn_a11_chapel_gate(1900.0)
		"A12":
			_spawn_exit_door(
				72.0, "E  返回大圣堂", "grand_cathedral",
				"res://scenes/regions/grand_cathedral.tscn", "east"
			)
			# C18: the inner-city side gate can only be opened after reaching A12 by the main route.
			# C18：必须先沿主线抵达 A12，才能从内城侧开启通往 A9 的侧门。
			_spawn_exit_door(
				520.0, "E  打开内城侧门", "royal_outer_ring",
				"res://scenes/regions/royal_outer_ring.tscn", "inner_city_side_gate",
				true, "reached_A12_via_A10_then_opened_inner_city_side_gate", "E  沿侧门返回"
			)
			if (
				"reached_A12_via_A10" in WorldState.achievement_flags
				and WorldState.is_hidden_path_opened("H07")
			):
				_spawn_exit_door(
					map_width - 350.0, "E  打开镜街侧门", "mirror_street",
					"res://scenes/hidden_regions/mirror_street.tscn", "east",
					true, "opened_mirror_street_side_gate", "E  进入镜街"
				)

			# C22 is available only after the mainline A10 -> A12 arrival has been recorded.
			# C22 仅在记录了 A10 主线抵达 A12 后开放，不能从 H07 镜街侧门绕过终局门槛。
			if "reached_A12_via_A10" in WorldState.achievement_flags:
				_spawn_exit_door(
					2130.0, "E  进入王座区", "terminal_anomaly",
					"res://scenes/regions/terminal_anomaly.tscn", "west", true, "", "", floor_y - 180.0
				)
			else:
				_register_debug_locked_route_hint(
					2130.0, "terminal_anomaly", "需要从大圣堂主线抵达 A12（C22）", floor_y - 180.0
				)
		"H07":
			_spawn_exit_door(
				72.0, "E  穿过积水返回", "royal_outer_ring",
				"res://scenes/regions/royal_outer_ring.tscn", "mirror"
			)
			if "opened_mirror_street_side_gate" in WorldState.achievement_flags:
				_spawn_exit_door(
					map_width - 72.0, "E  返回王室内城", "inner_city",
					"res://scenes/regions/inner_city.tscn", "west"
				)

		"H01":
			_spawn_exit_door(
				72.0, "E  返回边境村庄", "village",
				"res://scenes/regions/village_hub.tscn", "west"
			)
			var can_return_to_a4 := (
				"reached_A4_via_A3" in WorldState.achievement_flags
				and WorldState.is_hidden_path_opened("H01")
			)
			_spawn_exit_door(
				map_width - 105.0,
				"E  穿过井道闸门返回",
				"sewer_reservoir",
				"res://scenes/regions/sewer_reservoir.tscn",
				"east",
				can_return_to_a4
			)

		"H02":
			# H02 branches from the low Bell Grave landing; return to that same independent room.
			# H02 从钟墓坑底分出，回程回到同一个独立房间。
			_spawn_exit_door(
				72.0, "E  返回钟墓坑底", "ash_forest",
				"res://scenes/rooms/a2_fog_forest/runtime/a2_r04_room.tscn", "a2_r04_h02_return"
			)

		"H03":
			_spawn_exit_door(
				72.0, "E  返回被遗忘的城区", "forgotten_city",
				"res://scenes/regions/forgotten_city.tscn", "third_street_gate"
			)
			_spawn_exit_door(
				map_width - 105.0, "E  穿过旧服务门返回",
				"royal_outer_ring", "res://scenes/regions/royal_outer_ring.tscn", "third_street_service",
				"opened_old_service_door" in WorldState.achievement_flags
			)

		"H04":
			_spawn_exit_door(
				72.0, "E  返回旧水库", "sewer_reservoir",
				"res://scenes/regions/sewer_reservoir.tscn", "water_reflection_gate"
			)
			_spawn_exit_door(
				map_width - 105.0, "E  穿过王墓门返回",
				"royal_tomb", "res://scenes/regions/royal_tomb.tscn", "royal_tomb_side",
				"opened_royal_tomb_side_door" in WorldState.achievement_flags
			)

		"H05":
			_spawn_exit_door(
				72.0, "E  返回修道院", "monastery_tower",
				"res://scenes/regions/monastery_tower.tscn", "silent_window"
			)
			_spawn_exit_door(
				map_width - 105.0, "E  穿过钟塔落差通路返回",
				"forgotten_city", "res://scenes/regions/forgotten_city.tscn", "bell_drop",
				"opened_bell_tower_drop" in WorldState.achievement_flags
			)

		"H06":
			_spawn_exit_door(
				72.0, "E  返回旧王墓", "royal_tomb",
				"res://scenes/regions/royal_tomb.tscn", "royal_name_gate"
			)
			_spawn_exit_door(
				map_width - 105.0, "E  穿过王室运输门返回",
				"royal_outer_ring", "res://scenes/regions/royal_outer_ring.tscn", "royal_transport",
				"opened_royal_transport_side_door" in WorldState.achievement_flags
			)

		"A11":
			var can_return_to_tomb := WorldState.is_hidden_path_opened("C15")
			# The A11-to-A10 return is paired to C19 itself; reaching the cathedral on the main route alone must not open this hidden return.
			# A11 返回大圣堂必须与 C19 本身成对；仅走过主线抵达大圣堂，不应自动开启这条隐藏回程。
			var can_return_to_cathedral := WorldState.is_hidden_path_opened("C19")
			_spawn_exit_door(
				72.0, "E  沿王室竖井返回", "royal_tomb",
				"res://scenes/regions/royal_tomb.tscn", "east", can_return_to_tomb
			)
			_spawn_exit_door(
				map_width - 72.0, "E  返回大圣堂", "grand_cathedral",
				"res://scenes/regions/grand_cathedral.tscn", "east", can_return_to_cathedral
			)
			_spawn_h08_gate(map_width - 300.0)
			# C21 follows the ending evaluator: resonance, truth anchors, and exploration—not intimacy—open the optional ending route.
			# C21 遵循结局评估器：由鸣响、真相锚点与探索决定是否开放，不以亲密关系作为门槛。
			if NereisEndingEvaluator.get_candidate() != "凡人之墓":
				_spawn_exit_door(
					2050.0, "E  追随深层梦境", "terminal_anomaly",
					"res://scenes/regions/terminal_anomaly.tscn", "west"
				)
			else:
				_register_debug_locked_route_hint(2050.0, "terminal_anomaly", "需满足结局路线条件：鸣响、真相锚点与隐藏探索")

		"H09":
			_spawn_exit_door(
				72.0, "E  返回村庄山崖", "village",
				"res://scenes/regions/village_hub.tscn", "cliff_cave_return"
			)
		"H08":
			_spawn_exit_door(
				72.0, "E  返回深层研究区", "deep_research_depths",
				"res://scenes/regions/deep_research_depths.tscn", "east"
			)
			# The hidden route converges on A13 when the evaluator has selected a non-human ending candidate.
			# 结局评估器选出非“凡人之墓”路线后，隐藏通路才汇入 A13。
			if NereisEndingEvaluator.get_candidate() != "凡人之墓":
				_spawn_exit_door(
					map_width - 72.0, "E  追随最后的梦境", "terminal_anomaly",
					"res://scenes/regions/terminal_anomaly.tscn", "west"
				)
			else:
				_register_debug_locked_route_hint(map_width - 72.0, "terminal_anomaly", "需满足结局路线条件：鸣响、真相锚点与隐藏探索")

		"A13":
			var ending_scene_path := str(ENDGAME_GATE_SCRIPT.route_candidate())
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
	var gate := RESONANCE_SECRET_GATE_SCENE.instantiate() as Node2D
	gate.name = "RoyalTombDeepResearchGate"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "C15"
	gate.region_record_id = "A11"
	gate.target_scene_path = "res://scenes/regions/deep_research_depths.tscn"
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
	var gate := RESONANCE_SECRET_GATE_SCENE.instantiate() as Node2D
	gate.name = "SilentChapelDeepResearchGate"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "C19"
	gate.region_record_id = "A11"
	gate.target_scene_path = "res://scenes/regions/deep_research_depths.tscn"
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
	var gate := RESONANCE_SECRET_GATE_SCENE.instantiate() as Node2D
	gate.name = "PrimordialHollowGate"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "H08"
	gate.target_scene_path = "res://scenes/hidden_regions/primordial_hollow.tscn"
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
	var gate := RESONANCE_SECRET_GATE_SCENE.instantiate() as Node2D
	gate.name = "ResonanceMirrorStreetGate"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "H07"
	gate.target_scene_path = "res://scenes/hidden_regions/mirror_street.tscn"
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
			route = LOCAL_RESONANCE_ROUTE_SCENE.instantiate() as Node2D
			route.name = "BellgraveCanopyCrossing"
			route.route_id = "A2_BELLGRAVE_CANOPY_CROSSING"
			route.required_resonance = 20
			route.bridge_start_x = 1380.0
			route.bridge_end_x = 1610.0
			route.bridge_y = 386.0
			route.prompt_text = "E  ANCHOR THE BELLGRAVE CANOPY"
		"A3":
			route = LOCAL_RESONANCE_ROUTE_SCENE.instantiate() as Node2D
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
			route = LOCAL_RESONANCE_ROUTE_SCENE.instantiate() as Node2D
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
			route = LOCAL_RESONANCE_ROUTE_SCENE.instantiate() as Node2D
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
			route = LOCAL_RESONANCE_ROUTE_SCENE.instantiate() as Node2D
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
			route = LOCAL_RESONANCE_ROUTE_SCENE.instantiate() as Node2D
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
			route = LOCAL_RESONANCE_ROUTE_SCENE.instantiate() as Node2D
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
			route = LOCAL_RESONANCE_ROUTE_SCENE.instantiate() as Node2D
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
			route = LOCAL_RESONANCE_ROUTE_SCENE.instantiate() as Node2D
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
			route = LOCAL_RESONANCE_ROUTE_SCENE.instantiate() as Node2D
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
			route = LOCAL_RESONANCE_ROUTE_SCENE.instantiate() as Node2D
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
	# H02's gate and fixed bell motif are authored in A2-R04. Runtime only validates
	# the anchor, configures destination state, and binds the opened callback.
	var gate := get_node_or_null("HiddenBellChamberGate") as Node2D
	if gate == null:
		push_error("[NEREIS][A2][ROOM][AUTHORED_GATE_MISSING] H02")
		return
	var expected_position := Vector2(x, floor_y if y < 0.0 else y)
	if gate.position.distance_to(expected_position) > 1.0:
		push_error("[NEREIS][A2][ROOM][GATE_POSITION_MISMATCH] H02 authored=%s expected=%s" % [str(gate.position), str(expected_position)])
		return
	gate.set("secret_id", "H02")
	gate.set("target_scene_path", "res://scenes/hidden_regions/hidden_bell_chamber.tscn")
	gate.set("target_location_id", "hidden_bell_chamber")
	gate.set("target_spawn_side", "west")
	gate.set("required_resonance", 18)
	var callback := Callable(self, "_on_optional_hidden_gate_opened")
	if not gate.opened.is_connected(callback):
		gate.opened.connect(callback)
	debug_exit_markers.append({"position": gate.position, "label": "H02 倒响钟室", "kind": "secret", "condition": "灵视／进度条件"})

func _spawn_h03_gate(x: float) -> void:
	var gate: Node2D
	if region_id == "A3":
		gate = get_node_or_null("ErasedThirdStreetGate") as Node2D
		if gate == null:
			push_error("[NEREIS][A3][AUTHORED_GATE_MISSING] H03")
			return
		var expected_position := Vector2(x, floor_y)
		if gate.position.distance_to(expected_position) > 1.0:
			push_error("[NEREIS][A3][GATE_POSITION_MISMATCH] H03 authored=%s expected=%s" % [str(gate.position), str(expected_position)])
			return
	else:
		gate = RESONANCE_SECRET_GATE_SCENE.instantiate() as Node2D
		gate.name = "ErasedThirdStreetGate"
		gate.position = Vector2(x, floor_y)
		gate.secret_id = "H03"
		gate.target_scene_path = "res://scenes/hidden_regions/erased_third_street.tscn"
		gate.target_location_id = "erased_third_street"
		gate.target_spawn_side = "west"
		gate.required_resonance = 28
		add_child(gate)
	if not gate.opened.is_connected(_on_optional_hidden_gate_opened):
		gate.opened.connect(_on_optional_hidden_gate_opened)
	debug_exit_markers.append({"position": gate.position, "label": "H03 被删去的第三街", "kind": "secret", "condition": "灵视／进度条件"})

func _spawn_h04_gate(x: float) -> void:
	var gate := RESONANCE_SECRET_GATE_SCENE.instantiate() as Node2D
	gate.name = "ReflectedStairwellGate"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "H04"
	gate.target_scene_path = "res://scenes/hidden_regions/reflected_stairwell.tscn"
	gate.target_location_id = "reflected_stairwell"
	gate.target_spawn_side = "west"
	gate.required_resonance = 36
	gate.required_ancient_exposure = 1
	gate.opened.connect(_on_optional_hidden_gate_opened)
	add_child(gate)
	debug_exit_markers.append({"position": gate.position, "label": "H04 水面背后的楼梯", "kind": "secret", "condition": "灵视／进度条件"})

func _spawn_h05_gate(x: float) -> void:
	var gate := RESONANCE_SECRET_GATE_SCENE.instantiate() as Node2D
	gate.name = "SilentBellRoomGate"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "H05"
	gate.target_scene_path = "res://scenes/hidden_regions/silent_bell_room.tscn"
	gate.target_location_id = "silent_bell_room"
	gate.target_spawn_side = "west"
	gate.required_resonance = 42
	gate.required_ancient_exposure = 1
	gate.opened.connect(_on_optional_hidden_gate_opened)
	add_child(gate)
	debug_exit_markers.append({"position": gate.position, "label": "H05 无声钟室", "kind": "secret", "condition": "灵视／进度条件"})

func _spawn_h06_gate(x: float) -> void:
	var gate := RESONANCE_SECRET_GATE_SCENE.instantiate() as Node2D
	gate.name = "ErasedRoyalNameGate"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "H06"
	gate.target_scene_path = "res://scenes/hidden_regions/erased_royal_name_corridor.tscn"
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
	var gate := RESONANCE_SECRET_GATE_SCENE.instantiate() as Node2D
	gate.name = "ResonanceWellGateFromA4"
	gate.position = Vector2(x, floor_y)
	gate.secret_id = "H01"
	gate.target_scene_path = "res://scenes/hidden_regions/hidden_well.tscn"
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
	var door: Area2D
	var expected_position := Vector2(x, floor_y if door_y < 0.0 else door_y)
	if region_id in ["A3", "A4", "A6", "A7", "A8", "A9", "A10", "A11", "A12", "A13"]:
		# A3's fixed exits are authored in forgotten_city.tscn. Runtime only configures state.
		door = get_node_or_null("Exit_%s" % target_location) as Area2D
		if door == null:
			push_error("[NEREIS][AUTHORED_EXIT][AUTHORED_EXIT_MISSING] target=%s" % target_location)
			return
		if door.position.distance_to(expected_position) > 1.0:
			push_error("[NEREIS][AUTHORED_EXIT][EXIT_POSITION_MISMATCH] target=%s authored=%s expected=%s" % [target_location, str(door.position), str(expected_position)])
			return
		var authored_shape := door.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if authored_shape == null or not (authored_shape.shape is RectangleShape2D):
			push_error("[NEREIS][AUTHORED_EXIT][EXIT_SHAPE_INVALID] target=%s" % target_location)
			return
		var authored_rect := authored_shape.shape as RectangleShape2D
		if not is_equal_approx(authored_rect.size.x, 110.0) or not is_equal_approx(authored_rect.size.y, 80.0) or authored_shape.position.distance_to(Vector2(0.0, -35.0)) > 1.0:
			push_error("[NEREIS][AUTHORED_EXIT][EXIT_GEOMETRY_MISMATCH] target=%s" % target_location)
			return
		door.visible = true
		door.monitoring = true
	else:
		door = INTERACTION_DOOR_SCENE.instantiate() as Area2D
		door.name = "Exit_%s" % target_location
		door.position = expected_position
		var shape := door.get_node("CollisionShape2D") as CollisionShape2D
		var rectangle := shape.shape as RectangleShape2D
		rectangle.size = Vector2(110.0, 80.0)
		shape.position = Vector2(0.0, -35.0)
		add_child(door)
	door.set("prompt_text", prompt_text)
	door.set("enabled", enabled)
	door.set("unlock_once_flag_id", unlock_once_flag_id)
	door.set("opened_prompt_text", opened_prompt_text)
	door.set_meta("p5_1_exit_contract", true)
	door.set_meta("p5_1_target_location", target_location)
	door.set_meta("p5_1_target_region", _region_id_for_location(target_location))
	door.set_meta("p5_1_target_scene", target_scene)
	door.set_meta("p5_1_spawn_side", spawn_side)
	door.set_meta("p5_1_enabled", enabled)
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

# World map visuals are authored as nodes in .tscn scenes.
# Keep this method intentionally empty; only genuinely state-driven special effects belong in scripts.
func _draw() -> void:
	pass
