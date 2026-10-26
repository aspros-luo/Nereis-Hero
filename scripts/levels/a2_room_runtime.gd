extends "res://scripts/levels/greybox_world_region.gd"
## Room-scoped runtime for A2. Terrain remains authored in the six child scenes;
## this script supplies the shared Hero, camera, save/respawn state and room doors.

const ROOM_DEBUG_OVERLAY_SCENE: PackedScene = preload("res://scenes/ui/room_debug_overlay.tscn")

const ROOM_SCENE_PATHS := {
	"A2-R01": "res://scenes/rooms/a2_fog_forest/runtime/a2_r01_room.tscn",
	"A2-R02": "res://scenes/rooms/a2_fog_forest/runtime/a2_r02_room.tscn",
	"A2-R03": "res://scenes/rooms/a2_fog_forest/runtime/a2_r03_room.tscn",
	"A2-R04": "res://scenes/rooms/a2_fog_forest/runtime/a2_r04_room.tscn",
	"A2-R05": "res://scenes/rooms/a2_fog_forest/runtime/a2_r05_room.tscn",
	"A2-R06": "res://scenes/rooms/a2_fog_forest/runtime/a2_r06_room.tscn",
}

var room_transition_locked := false


func _physics_process(_delta: float) -> void:
	# R01 has one authored safe drop to R04. Every other fall beyond the expanded room
	# bounds is lethal and returns the Hero to R01's west entry.
	if room_id != "A2-R01" or hero == null or room_transition_locked or respawning:
		return
	if hero.global_position.y > global_position.y + room_height + 96.0:
		_recover_r01_void_fall()


func _recover_r01_void_fall() -> void:
	if room_transition_locked or respawning:
		return
	respawning = true
	room_transition_locked = true
	WorldState.input_locked = true
	INTERACTION_FOCUS_SCRIPT.clear_all(get_tree())
	WorldState.pending_region_spawn_side = "west"
	WorldState.current_a2_room_scene_path = ROOM_SCENE_PATHS["A2-R01"]
	WorldState.set_location("ash_forest")
	SceneTransition.fade_to_scene(ROOM_SCENE_PATHS["A2-R01"], 0.62, 0.48, 0.38)


func _ready() -> void:
	if not ROOM_SCENE_PATHS.has(room_id):
		push_error("[NEREIS][A2][ROOM][FAIL] unknown room_id=%s" % room_id)
		return

	WorldState.prepare_scene_runtime()
	WorldState.load_room_state()
	var spawn_side := WorldState.pending_region_spawn_side
	WorldState.current_a2_room_scene_path = _scene_path_for_room(room_id)
	# Save the actual incoming side for Continue before clearing the one-shot transition value.
	WorldState.set_location(location_id)
	WorldState.pending_region_spawn_side = "west"

	# The playable R01 scene owns terrain, markers, Hero, HUD and boundaries as editor-visible nodes; no A2 region-wide floor is generated.
	_create_boundaries()
	_spawn_region_ambience()
	var spawn_position := _spawn_position_for_side(spawn_side)
	_spawn_hero(spawn_position.x, spawn_position.y)
	if camera != null:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(map_width)
		camera.limit_bottom = int(room_height)
	_spawn_ui()
	_spawn_room_debug_label()

	_spawn_room_content()
	_spawn_room_exits()
	WorldState.mark_room_explored(room_id)
	if "graybox_intro_ash_forest" not in WorldState.achievement_flags:
		WorldState.record_achievement("graybox_intro_ash_forest")
	queue_redraw()
	print("[NEREIS][A2][ROOM] loaded=%s size=%.0fx%.0f spawn=%s at=(%.1f,%.1f)" % [
		room_id, map_width, room_height, spawn_side, hero.position.x, hero.position.y
	])


## Temporary on-screen room marker for manual map acceptance.
## 实机验收临时标识：始终显示当前 A2 房间编号与场景名称。
func _spawn_room_debug_label() -> void:
	var layer := ROOM_DEBUG_OVERLAY_SCENE.instantiate() as CanvasLayer
	layer.name = "RoomDebugOverlay"
	var label := layer.get_node("RoomNamePanel/RoomNameLabel") as Label
	label.text = "%s · %s · %s" % [region_id, room_id.replace("A2-", ""), region_title]
	add_child(layer)
func _scene_path_for_room(target_room_id: String) -> String:
	return str(ROOM_SCENE_PATHS.get(target_room_id, ROOM_SCENE_PATHS["A2-R01"]))


func _room_id_for_scene_path(scene_path: String) -> String:
	for key in ROOM_SCENE_PATHS:
		if str(ROOM_SCENE_PATHS[key]) == scene_path:
			return str(key)
	return ""


func _room_marker_position(marker_name: String, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	var marker := get_node_or_null("Terrain/RoomMarkers/" + marker_name) as Marker2D
	if marker == null:
		push_error("[NEREIS][A2][ROOM][MARKER_MISSING] room=%s marker=%s" % [room_id, marker_name])
		return fallback
	# Room art scenes may use a root scale while their runtime wrapper remains unscaled.
	# Convert the marker's transformed world position back into the runtime's local space
	# so spawn points, doors and drop triggers stay aligned with the visible/colliding scene.
	return to_local(marker.global_position)


func _spawn_position_for_side(side: String) -> Vector2:
	if side == "a2_checkpoint":
		return WorldState.checkpoint_position
	var marker_name := "EntryWest"
	match room_id:
		"A2-R01":
			match side:
				"a2_r01_canopy_return":
					marker_name = "EntryCanopyReturn"
				"a2_r01_tomb_return":
					marker_name = "EntryTombReturn"
				_:
					marker_name = "EntryWest"
		"A2-R02":
			match side:
				"a2_r02_from_r01":
					marker_name = "EntryFromR01"
				"a2_r02_high_return":
					marker_name = "EntryHighReturn"
				_:
					marker_name = "EntryWest"
		"A2-R03":
			match side:
				"a2_r03_from_r01":
					marker_name = "EntryFromR01"
				"a2_r03_crypt_return":
					marker_name = "EntryCryptReturn"
				"a2_r03_highroad_shortcut":
					marker_name = "EntryHighroadShortcut"
				_:
					marker_name = "EntryWest"
		"A2-R04":
			match side:
				"a2_r04_tomb_drop":
					marker_name = "EntryTombDrop"
				"a2_r04_tomb_drop_r01":
					marker_name = "EntryTombDropR01"
				"a2_r04_h02_return":
					marker_name = "EntryH02Return"
				"a2_r04_ravine_return":
					marker_name = "EntryRavineReturn"
				_:
					marker_name = "EntryDefault"
		"A2-R05":
			match side:
				"a2_r05_from_r02":
					marker_name = "EntryFromR02"
				"a2_r05_upper_shortcut":
					marker_name = "EntryUpperShortcut"
				"a2_r05_ravine_return":
					marker_name = "EntryRavineReturn"
				"a2_r05_c04_return":
					marker_name = "EntryC04Return"
				_:
					marker_name = "EntryDefault"
		"A2-R06":
			match side:
				"a2_r06_high_entry":
					marker_name = "EntryHigh"
				"a2_r06_low_entry":
					marker_name = "EntryLow"
				"a2_r06_c03_return":
					marker_name = "EntryC03Return"
				"a2_r06_ravine_return":
					marker_name = "EntryRavineReturn"
				_:
					marker_name = "EntryDefault"
	return _room_marker_position(marker_name, Vector2(220.0, floor_y))


func _spawn_exit_door_at_marker(
	marker_name: String,
	prompt_text: String,
	target_location: String,
	target_scene: String,
	spawn_side: String,
	enabled: bool = true,
	unlock_once_flag_id: String = "",
	opened_prompt_text: String = ""
) -> void:
	var marker_position := _room_marker_position(marker_name, Vector2(-1.0, -1.0))
	if marker_position.x < 0.0 or marker_position.y < 0.0:
		push_error("[NEREIS][A2][ROOM][EXIT_ANCHOR_INVALID] room=%s marker=%s" % [room_id, marker_name])
		return
	_spawn_exit_door(
		marker_position.x,
		prompt_text,
		target_location,
		target_scene,
		spawn_side,
		enabled,
		unlock_once_flag_id,
		opened_prompt_text,
		marker_position.y
	)


func _spawn_drop_transition_at_marker(
	marker_name: String,
	width: float,
	height: float,
	target_room_id: String,
	target_spawn_side: String
) -> void:
	var marker_position := _room_marker_position(marker_name, Vector2(-1.0, -1.0))
	if marker_position.x < 0.0 or marker_position.y < 0.0:
		push_error("[NEREIS][A2][ROOM][DROP_ANCHOR_INVALID] room=%s marker=%s" % [room_id, marker_name])
		return
	var source_short := room_id.replace("A2-", "R")
	var target_short := target_room_id.replace("A2-", "R")
	_spawn_drop_transition(
		"Drop_%s_to_%s" % [source_short, target_short],
		marker_position.x,
		marker_position.y,
		width,
		height,
		target_room_id,
		target_spawn_side
	)


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
		"A2-R06":
			_spawn_world_item_pickup(
				"exploration_reward_canopy_waymarker_fragment",
				"canopy_waymarker_fragment",
				"CanopyWaymarkerFragment",
				Vector2(1120.0, 295.0)
			)


func _spawn_room_exits() -> void:
	match room_id:
		"A2-R01":
			_spawn_exit_door_at_marker("ExitVillage", "E  返回边境村庄", "village", "res://scenes/village_hub.tscn", "north_gate")
			_spawn_exit_door_at_marker("ExitCanopy", "E  攀上古树，进入树冠", "ash_forest", _scene_path_for_room("A2-R02"), "a2_r02_from_r01")
			_spawn_exit_door_at_marker("ExitBellTomb", "E  进入钟墓上环", "ash_forest", _scene_path_for_room("A2-R03"), "a2_r03_from_r01")
			_spawn_drop_transition_at_marker("DropToR04", 32.0, 120.0, "A2-R04", "a2_r04_tomb_drop_r01")
		"A2-R02":
			_spawn_exit_door_at_marker("ExitToR01", "E  返回林间岔路", "ash_forest", _scene_path_for_room("A2-R01"), "a2_r01_canopy_return")
			_spawn_exit_door_at_marker("ExitToR05", "E  沿旧朝圣高路前进", "ash_forest", _scene_path_for_room("A2-R05"), "a2_r05_from_r02")
		"A2-R03":
			_spawn_exit_door_at_marker("ExitToR01", "E  返回林间岔路", "ash_forest", _scene_path_for_room("A2-R01"), "a2_r01_tomb_return")
			_spawn_exit_door_at_marker("ExitToR05", "E  进入旧朝圣高路捷径", "ash_forest", _scene_path_for_room("A2-R05"), "a2_r05_upper_shortcut")
			_spawn_drop_transition_at_marker("DropToR04", 150.0, 220.0, "A2-R04", "a2_r04_tomb_drop")
		"A2-R04":
			var h02_position := _room_marker_position("H02Gate", Vector2(90.0, floor_y))
			_spawn_h02_gate(h02_position.x, h02_position.y)
			_spawn_exit_door_at_marker("ExitToR03", "E  沿回程石沿返回钟墓上环", "ash_forest", _scene_path_for_room("A2-R03"), "a2_r03_crypt_return")
			_spawn_exit_door_at_marker("ExitToR06", "E  深入东侧裂谷", "ash_forest", _scene_path_for_room("A2-R06"), "a2_r06_low_entry")
		"A2-R05":
			_spawn_exit_door_at_marker("ExitToR02", "E  返回树冠断桥", "ash_forest", _scene_path_for_room("A2-R02"), "a2_r02_high_return")
			_spawn_exit_door_at_marker("ExitToR03", "E  返回钟墓高环", "ash_forest", _scene_path_for_room("A2-R03"), "a2_r03_highroad_shortcut")
			_spawn_exit_door_at_marker("ExitToR06", "E  进入东侧裂谷", "ash_forest", _scene_path_for_room("A2-R06"), "a2_r06_high_entry")
			if "reached_A5_and_opened_old_pilgrim_highroad" in WorldState.achievement_flags:
				_spawn_exit_door_at_marker("ExitToA5", "E  返回边境战场", "old_battlefield", "res://scenes/old_battlefield.tscn", "old_pilgrim_highroad")
		"A2-R06":
			_spawn_exit_door_at_marker("ExitToR05", "E  返回旧朝圣高路", "ash_forest", _scene_path_for_room("A2-R05"), "a2_r05_ravine_return")
			_spawn_exit_door_at_marker("ExitToR04", "E  返回钟墓坑底", "ash_forest", _scene_path_for_room("A2-R04"), "a2_r04_ravine_return")
			_spawn_exit_door_at_marker("ExitToA3", "E  沿树冠高路进入被遗忘的城区", "forgotten_city", "res://scenes/forgotten_city.tscn", "city_canopy_entry")


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
	# Fixed A2 drop areas are authored in the room .tscn files so their collision
	# extents can be inspected and adjusted in the Godot editor. Keep a fallback for
	# transitional/test rooms that do not yet contain an authored Area2D.
	var area := get_node_or_null(transition_name) as Area2D
	if area == null:
		area = AUTO_ROOM_TRANSITION_SCENE.instantiate() as Area2D
		area.name = transition_name
		add_child(area)
	area.position = Vector2(x, y)
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	var shape := area.get_node("CollisionShape2D") as CollisionShape2D
	var rectangle := shape.shape as RectangleShape2D
	if rectangle == null:
		push_error("[NEREIS][A2][ROOM][DROP_SHAPE_INVALID] room=%s area=%s" % [room_id, transition_name])
		return
	rectangle.size = Vector2(width, height)
	shape.position = Vector2.ZERO
	var callback := _on_drop_transition_body_entered.bind(target_scene, target_spawn_side)
	if not area.body_entered.is_connected(callback):
		area.body_entered.connect(callback)
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
	if ROOM_SCENE_PATHS.has(WorldState.checkpoint_room_id) and WorldState.checkpoint_room_id != room_id:
		respawning = true
		WorldState.input_locked = true
		INTERACTION_FOCUS_SCRIPT.clear_all(get_tree())
		await get_tree().create_timer(0.45).timeout
		var target_scene := _scene_path_for_room(WorldState.checkpoint_room_id)
		WorldState.pending_region_spawn_side = "a2_checkpoint"
		WorldState.current_a2_room_scene_path = target_scene
		WorldState.set_location("ash_forest")
		SceneTransition.fade_to_scene(target_scene, 0.62, 0.48, 0.38)
		return
	super._on_hero_defeated()
