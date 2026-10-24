extends "res://scripts/levels/greybox_world_region.gd"
## Room-scoped runtime for A2. Terrain remains authored in the six child scenes;
## this script supplies the shared Hero, camera, save/respawn state and room doors.

const ROOM_SCENE_PATHS := {
	"A2-R01": "res://scenes/rooms/a2_fog_forest/runtime/a2_r01_room.tscn",
	"A2-R02": "res://scenes/rooms/a2_fog_forest/runtime/a2_r02_room.tscn",
	"A2-R03": "res://scenes/rooms/a2_fog_forest/runtime/a2_r03_room.tscn",
	"A2-R04": "res://scenes/rooms/a2_fog_forest/runtime/a2_r04_room.tscn",
	"A2-R05": "res://scenes/rooms/a2_fog_forest/runtime/a2_r05_room.tscn",
	"A2-R06": "res://scenes/rooms/a2_fog_forest/runtime/a2_r06_room.tscn",
}

var room_transition_locked := false


func _ready() -> void:
	if not ROOM_SCENE_PATHS.has(room_id):
		push_error("[NEREIS][A2][ROOM][FAIL] unknown room_id=%s" % room_id)
		return

	WorldState.prepare_scene_runtime()
	WorldState.load_room_state()
	var spawn_side := WorldState.pending_region_spawn_side
	WorldState.pending_region_spawn_side = "west"
	WorldState.current_a2_room_scene_path = _scene_path_for_room(room_id)
	WorldState.set_location(location_id)

	# The authored room child owns every ledge and ground collider; no A2 region-wide floor is generated.
	_create_boundaries()
	_spawn_region_ambience()
	_spawn_hero(_spawn_x_for_side(spawn_side), _spawn_y_for_side(spawn_side))
	if camera != null:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(map_width)
		camera.limit_bottom = int(room_height)
	_spawn_ui()

	_spawn_room_content()
	_spawn_room_exits()
	WorldState.mark_room_explored(room_id)
	if "graybox_intro_ash_forest" not in WorldState.achievement_flags:
		WorldState.record_achievement("graybox_intro_ash_forest")
	queue_redraw()
	print("[NEREIS][A2][ROOM] loaded=%s size=%.0fx%.0f spawn=%s at=(%.1f,%.1f)" % [
		room_id, map_width, room_height, spawn_side, hero.position.x, hero.position.y
	])


func _scene_path_for_room(target_room_id: String) -> String:
	return str(ROOM_SCENE_PATHS.get(target_room_id, ROOM_SCENE_PATHS["A2-R01"]))


func _room_id_for_scene_path(scene_path: String) -> String:
	for key in ROOM_SCENE_PATHS:
		if str(ROOM_SCENE_PATHS[key]) == scene_path:
			return str(key)
	return ""


func _spawn_x_for_side(side: String) -> float:
	if side == "a2_checkpoint":
		return WorldState.checkpoint_position.x
	match room_id:
		"A2-R01":
			if side in ["a2_r01_canopy_return", "a2_r01_tomb_return"]:
				return 700.0
			if side == "a2_r01_h02_return":
				return 650.0
			return 220.0
		"A2-R02":
			match side:
				"a2_r02_from_r01":
					return 350.0
				"a2_r02_high_return":
					return 1520.0
				_:
					return 50.0
		"A2-R03":
			match side:
				"a2_r03_from_r01":
					return 250.0
				"a2_r03_crypt_return":
					return 320.0
				"a2_r03_highroad_shortcut":
					return 800.0
				_:
					return 100.0
		"A2-R04":
			match side:
				"a2_r04_tomb_drop":
					return 200.0
				"a2_r04_tomb_drop_r01":
					return 400.0
				"a2_r04_h02_return":
					return 350.0
				"a2_r04_ravine_return":
					return 400.0
				_:
					return 200.0
		"A2-R05":
			match side:
				"a2_r05_from_r02", "a2_r05_upper_shortcut":
					return 200.0
				"a2_r05_ravine_return":
					return 650.0
				"a2_r05_c04_return":
					return 560.0
				_:
					return 50.0
		"A2-R06":
			match side:
				"a2_r06_high_entry":
					return 160.0
				"a2_r06_low_entry":
					return 280.0
				"a2_r06_c03_return":
					return 1010.0
				"a2_r06_ravine_return":
					return 280.0
				_:
					return 50.0
	return 220.0


func _spawn_y_for_side(side: String) -> float:
	if side == "a2_checkpoint":
		return WorldState.checkpoint_position.y
	match room_id:
		"A2-R01":
			if side in ["a2_r01_canopy_return", "a2_r01_tomb_return"]:
				return 560.0
			return 650.0
		"A2-R02":
			match side:
				"a2_r02_from_r01":
					return 0.0
				"a2_r02_high_return":
					return 260.0
				_:
					return 40.0
		"A2-R03":
			match side:
				"a2_r03_from_r01":
					return 120.0
				"a2_r03_crypt_return":
					return 310.0
				"a2_r03_highroad_shortcut":
					return 106.0
				_:
					return 85.0
		"A2-R04":
			return 380.0
		"A2-R05":
			match side:
				"a2_r05_from_r02", "a2_r05_upper_shortcut":
					return 40.0
				"a2_r05_ravine_return":
					return 170.0
				"a2_r05_c04_return":
					return 105.0
				_:
					return 95.0
		"A2-R06":
			match side:
				"a2_r06_high_entry":
					return 260.0
				"a2_r06_low_entry":
					return 490.0
				"a2_r06_c03_return":
					return 345.0
				"a2_r06_ravine_return":
					return 610.0
				_:
					return 325.0
	return floor_y


func _spawn_room_content() -> void:
	match room_id:
		"A2-R03":
			_spawn_source(
				Vector2(735.0, floor_y - 18.0),
				"anomaly_bell_retiming",
				"从未移动的钟",
				"钟舌垂落不动。\n\n钟声却依然响起。你掌下的石头震动了一次，随后归于沉寂。\n\n第二道脉动仍残留在你的眼后。",
				12, 0, 0, "resonance_sight"
			)
			_spawn_world_item_pickup(
				"exploration_reward_bellgrave_burial_token",
				"bellgrave_burial_token",
				"BellgraveBurialToken",
				Vector2(300.0, 275.0)
			)
		"A2-R04":
			pass
		"A2-R05":
			_spawn_source(
				Vector2(650.0, floor_y - 18.0),
				"anomaly_old_pilgrim_echo",
				"第二道回声",
				"你轻敲旧里程碑，回应却从身后的道路传来。\n\n石头仍然温热，仿佛有人刚刚离开。",
				18
			)
			_spawn_world_item_pickup(
				"map_reward_old_pilgrim_waybill",
				"old_pilgrim_waybill",
				"OldPilgrimWaybill",
				Vector2(650.0, 130.0)
			)
			if "defeated_A2_Cultist_01" in WorldState.achievement_flags:
				_spawn_world_item_pickup(
					"combat_reward_a2_cultist_seal",
					"charred_church_seal",
					"CharredChurchSeal",
					Vector2(560.0, 130.0)
				)
			_spawn_room_rest_point()
		"A2-R06":
			_spawn_world_item_pickup(
				"exploration_reward_canopy_waymarker_fragment",
				"canopy_waymarker_fragment",
				"CanopyWaymarkerFragment",
				Vector2(1120.0, 295.0)
			)


func _spawn_room_rest_point() -> void:
	var rest := Node2D.new()
	rest.set_script(REST_POINT_SCRIPT)
	rest.name = "RegionRestPoint_A2"
	rest.position = Vector2(350.0, floor_y)
	rest.rest_id = "rest_A2"
	rest.display_name = "旧朝圣圣龛"
	add_child(rest)


func _spawn_room_exits() -> void:
	match room_id:
		"A2-R01":
			_spawn_h02_gate(750.0, floor_y)
			_spawn_exit_door(72.0, "E  返回边境村庄", "village", "res://scenes/village_hub.tscn", "north_gate", true, "", "", 650.0)
			_spawn_exit_door(1680.0, "E  沿树冠阶梯前进", "ash_forest", _scene_path_for_room("A2-R02"), "a2_r02_from_r01", true, "", "", 285.0)
			_spawn_exit_door(930.0, "E  进入钟墓上环", "ash_forest", _scene_path_for_room("A2-R03"), "a2_r03_from_r01", true, "", "", 0.0)
			_spawn_drop_transition("Drop_R01_to_R04", 1110.0, 850.0, 500.0, 260.0, "A2-R04", "a2_r04_tomb_drop_r01")
		"A2-R02":
			_spawn_exit_door(50.0, "E  返回林间岔路", "ash_forest", _scene_path_for_room("A2-R01"), "a2_r01_canopy_return", true, "", "", 40.0)
			_spawn_exit_door(1510.0, "E  沿旧朝圣高路前进", "ash_forest", _scene_path_for_room("A2-R05"), "a2_r05_from_r02", true, "", "", 260.0)
		"A2-R03":
			_spawn_exit_door(100.0, "E  返回林间岔路", "ash_forest", _scene_path_for_room("A2-R01"), "a2_r01_tomb_return", true, "", "", 85.0)
			_spawn_exit_door(950.0, "E  进入旧朝圣高路捷径", "ash_forest", _scene_path_for_room("A2-R05"), "a2_r05_upper_shortcut", true, "", "", 106.0)
			_spawn_drop_transition("Drop_R03_to_R04", 425.0, 675.0, 150.0, 220.0, "A2-R04", "a2_r04_tomb_drop")
		"A2-R04":
			_spawn_exit_door(55.0, "E  沿回程石沿返回钟墓上环", "ash_forest", _scene_path_for_room("A2-R03"), "a2_r03_crypt_return", true, "", "", 0.0)
			_spawn_exit_door(450.0, "E  深入东侧裂谷", "ash_forest", _scene_path_for_room("A2-R06"), "a2_r06_low_entry", true, "", "", 380.0)
		"A2-R05":
			_spawn_exit_door(60.0, "E  返回树冠断桥", "ash_forest", _scene_path_for_room("A2-R02"), "a2_r02_high_return", true, "", "", 95.0)
			_spawn_exit_door(350.0, "E  返回钟墓高环", "ash_forest", _scene_path_for_room("A2-R03"), "a2_r03_highroad_shortcut", true, "", "", 215.0)
			_spawn_exit_door(540.0, "E  进入东侧裂谷", "ash_forest", _scene_path_for_room("A2-R06"), "a2_r06_high_entry", true, "", "", 105.0)
			if "reached_A5_and_opened_old_pilgrim_highroad" in WorldState.achievement_flags:
				_spawn_exit_door(690.0, "E  返回边境战场", "old_battlefield", "res://scenes/old_battlefield.tscn", "old_pilgrim_highroad", true, "", "", 170.0)
		"A2-R06":
			_spawn_exit_door(50.0, "E  返回旧朝圣高路", "ash_forest", _scene_path_for_room("A2-R05"), "a2_r05_ravine_return", true, "", "", 325.0)
			_spawn_exit_door(280.0, "E  返回钟墓坑底", "ash_forest", _scene_path_for_room("A2-R04"), "a2_r04_ravine_return", true, "", "", 610.0)
			_spawn_exit_door(1150.0, "E  沿树冠高路进入被遗忘的城区", "forgotten_city", "res://scenes/forgotten_city.tscn", "city_canopy_entry", true, "", "", 325.0)


func _spawn_drop_transition(
	transition_name: String,
	x: float,
	y: float,
	width: float,
	height: float,
	target_room_id: String,
	target_spawn_side: String
) -> void:
	var target_scene := _scene_path_for_room(target_room_id)
	var area := Area2D.new()
	area.name = transition_name
	area.position = Vector2(x, y)
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, height)
	shape.shape = rectangle
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_drop_transition_body_entered.bind(target_scene, target_spawn_side))


func _on_drop_transition_body_entered(body: Node2D, target_scene: String, target_spawn_side: String) -> void:
	if body != hero or room_transition_locked or hero == null or hero.velocity.y <= 0.0:
		return
	room_transition_locked = true
	WorldState.pending_region_spawn_side = target_spawn_side
	WorldState.current_a2_room_scene_path = target_scene
	WorldState.set_location("ash_forest")
	SceneTransition.fade_to_scene(target_scene)


func _on_hero_defeated() -> void:
	if respawning:
		return
	if WorldState.checkpoint_room_id.begins_with("A2-") and WorldState.checkpoint_room_id != room_id:
		respawning = true
		WorldState.input_locked = true
		INTERACTION_FOCUS_SCRIPT.clear_all(get_tree())
		await get_tree().create_timer(0.75).timeout
		var target_scene := _scene_path_for_room(WorldState.checkpoint_room_id)
		WorldState.pending_region_spawn_side = "a2_checkpoint"
		WorldState.current_a2_room_scene_path = target_scene
		WorldState.set_location("ash_forest")
		SceneTransition.fade_to_scene(target_scene)
		return
	super._on_hero_defeated()
