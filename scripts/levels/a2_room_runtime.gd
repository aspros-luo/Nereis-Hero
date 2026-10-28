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
	if not _validate_authored_room_structure():
		return

	WorldState.prepare_scene_runtime()
	WorldState.load_room_state()
	var spawn_side := WorldState.pending_region_spawn_side
	WorldState.current_a2_room_scene_path = _scene_path_for_room(room_id)
	# Save the actual incoming side for Continue before clearing the one-shot transition value.
	WorldState.set_location(location_id)
	WorldState.pending_region_spawn_side = "west"

	# The playable R01 scene owns terrain, markers, Hero, HUD and boundaries as editor-visible nodes; no A2 region-wide floor is generated.
	# Room boundaries are authored in every R01–R06 scene; never synthesize fallback walls here.
	_spawn_region_ambience()
	var spawn_position := _spawn_position_for_side(spawn_side)
	if spawn_position.x < 0.0 or spawn_position.y < 0.0:
		push_error("[NEREIS][A2][ROOM][SPAWN_ANCHOR_INVALID] room=%s side=%s" % [room_id, spawn_side])
		return
	_spawn_hero(spawn_position.x, spawn_position.y)
	if camera != null:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(map_width)
		camera.limit_bottom = int(room_height)
	_configure_authored_ui()
	_configure_room_debug_label()

	_spawn_room_content()
	_spawn_room_exits()
	WorldState.mark_room_explored(room_id)
	if "graybox_intro_ash_forest" not in WorldState.achievement_flags:
		WorldState.record_achievement("graybox_intro_ash_forest")
	queue_redraw()
	print("[NEREIS][A2][ROOM] loaded=%s size=%.0fx%.0f spawn=%s at=(%.1f,%.1f)" % [
		room_id, map_width, room_height, spawn_side, hero.position.x, hero.position.y
	])


func _validate_authored_room_structure() -> bool:
	# A2 is assembled from editor-authored room scenes; missing fixed nodes must fail loudly.
	# A2 由编辑器场景节点构成；固定节点缺失时必须报错，不得用运行时兜底掩盖。
	for node_name in ["Hero", "Narrative", "HUD", "RoomDebugOverlay"]:
		if get_node_or_null(node_name) == null:
			push_error("[NEREIS][A2][ROOM][AUTHORED_NODE_MISSING] room=%s node=%s" % [room_id, node_name])
			return false
	for boundary_name in ["RegionBoundary_0", "RegionBoundary_1"]:
		var boundary := get_node_or_null(boundary_name) as StaticBody2D
		if boundary == null:
			push_error("[NEREIS][A2][ROOM][AUTHORED_BOUNDARY_MISSING] room=%s node=%s" % [room_id, boundary_name])
			return false
		var collision := boundary.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or collision.shape == null:
			push_error("[NEREIS][A2][ROOM][AUTHORED_BOUNDARY_SHAPE_MISSING] room=%s node=%s" % [room_id, boundary_name])
			return false
	for marker_name in _required_spawn_markers_for_room():
		if get_node_or_null("Terrain/RoomMarkers/" + marker_name) is not Marker2D:
			push_error("[NEREIS][A2][ROOM][SPAWN_MARKER_MISSING] room=%s marker=%s" % [room_id, marker_name])
			return false
	return true


func _required_spawn_markers_for_room() -> Array[String]:
	match room_id:
		"A2-R01":
			return ["EntryWest", "EntryCanopyReturn", "EntryTombReturn"]
		"A2-R02":
			return ["EntryWest", "EntryFromR01", "EntryHighReturn"]
		"A2-R03":
			return ["EntryWest", "EntryFromR01", "EntryCryptReturn", "EntryHighroadShortcut"]
		"A2-R04":
			return ["EntryDefault", "EntryTombDrop", "EntryTombDropR01", "EntryH02Return", "EntryRavineReturn"]
		"A2-R05":
			return ["EntryDefault", "EntryFromR02", "EntryUpperShortcut", "EntryRavineReturn", "EntryC04Return"]
		"A2-R06":
			return ["EntryDefault", "EntryHigh", "EntryLow", "EntryC03Return", "EntryRavineReturn"]
	return []


func _configure_authored_ui() -> void:
	# Fixed UI layers are scene instances in all six room trees; only bind and configure them.
	# 六个房间均预置固定 UI 层；运行时只绑定 Hero 并设置文本。
	narrative = get_node_or_null("Narrative") as CanvasLayer
	hud = get_node_or_null("HUD") as CanvasLayer
	if narrative == null or hud == null:
		push_error("[NEREIS][A2][ROOM][AUTHORED_UI_MISSING] room=%s" % room_id)
		return
	hud.bind_hero(hero)
	hud.set_story_mode(_localized_region_title(), _get_objective_text())


## Temporary on-screen room marker for manual map acceptance.
## 实机验收临时标识：始终显示当前 A2 房间编号与场景名称。
func _configure_room_debug_label() -> void:
	# The debug overlay is a scene-authored child so room trees stay visible in the editor.
	# 调试标记由房间场景预置；代码只更新当前房间文字。
	var layer := get_node_or_null("RoomDebugOverlay") as CanvasLayer
	if layer == null:
		push_error("[NEREIS][A2][ROOM][AUTHORED_DEBUG_OVERLAY_MISSING] room=%s" % room_id)
		return
	var label := layer.get_node_or_null("RoomNamePanel/RoomNameLabel") as Label
	if label == null:
		push_error("[NEREIS][A2][ROOM][DEBUG_LABEL_MISSING] room=%s" % room_id)
		return
	label.text = "%s · %s · %s" % [region_id, room_id.replace("A2-", ""), region_title]
func _scene_path_for_room(target_room_id: String) -> String:
	return str(ROOM_SCENE_PATHS.get(target_room_id, ROOM_SCENE_PATHS["A2-R01"]))


func _room_id_for_scene_path(scene_path: String) -> String:
	for key in ROOM_SCENE_PATHS:
		if str(ROOM_SCENE_PATHS[key]) == scene_path:
			return str(key)
	return ""


func _room_marker_position(marker_name: String) -> Vector2:
	var marker := get_node_or_null("Terrain/RoomMarkers/" + marker_name) as Marker2D
	if marker == null:
		push_error("[NEREIS][A2][ROOM][MARKER_MISSING] room=%s marker=%s" % [room_id, marker_name])
		return Vector2(-1.0, -1.0)
	# Convert transformed marker coordinates back to this room root's local space.
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
	return _room_marker_position(marker_name)


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
	var marker_position := _room_marker_position(marker_name)
	if marker_position.x < 0.0 or marker_position.y < 0.0:
		push_error("[NEREIS][A2][ROOM][EXIT_ANCHOR_INVALID] room=%s marker=%s" % [room_id, marker_name])
		return
	var authored_door := get_node_or_null("Door_" + marker_name) as Area2D
	if authored_door == null:
		push_error("[NEREIS][A2][ROOM][AUTHORED_EXIT_MISSING] room=%s expected=Door_%s" % [room_id, marker_name])
		return

	# Fixed exit placement belongs to the scene. Runtime validates the authored anchor,
	# then applies only destination and progression state.
	if authored_door.position.distance_to(marker_position) > 1.0:
		push_error("[NEREIS][A2][ROOM][EXIT_POSITION_MISMATCH] room=%s door=%s authored=%s marker=%s" % [room_id, authored_door.name, str(authored_door.position), str(marker_position)])
		return
	authored_door.set("prompt_text", prompt_text)
	authored_door.set("enabled", enabled)
	authored_door.set("unlock_once_flag_id", unlock_once_flag_id)
	authored_door.set("opened_prompt_text", opened_prompt_text)
	authored_door.set_meta("p5_1_exit_contract", true)
	authored_door.set_meta("p5_1_target_location", target_location)
	authored_door.set_meta("p5_1_target_region", _region_id_for_location(target_location))
	authored_door.set_meta("p5_1_target_scene", target_scene)
	authored_door.set_meta("p5_1_spawn_side", spawn_side)
	authored_door.set_meta("p5_1_enabled", enabled)
	var callback := _on_exit_interacted.bind(target_location, target_scene, spawn_side)
	if not authored_door.interacted.is_connected(callback):
		authored_door.interacted.connect(callback)
	var exit_kind := "locked" if not enabled else ("shortcut" if not unlock_once_flag_id.is_empty() else "exit")
	debug_exit_markers.append({
		"position": authored_door.position,
		"label": _debug_route_label(target_location),
		"kind": exit_kind,
		"condition": unlock_once_flag_id if not unlock_once_flag_id.is_empty() else ("需从另一侧开启" if not enabled else "")
	})
	queue_redraw()


func _spawn_drop_transition_at_marker(
	marker_name: String,
	width: float,
	height: float,
	target_room_id: String,
	target_spawn_side: String
) -> void:
	var marker_position := _room_marker_position(marker_name)
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
	# Fixed clues and rewards are authored in each room scene. Runtime only binds
	# clue callbacks and verifies the required nodes exist; it never creates fixed pickups.
	# 固定线索和奖励由各房间场景预置；运行时只绑定线索回调并检查节点，不再按坐标生成。
	_bind_authored_region_sources()
	var expected_nodes: Array[String] = []
	match room_id:
		"A2-R03":
			expected_nodes = ["Anomaly_anomaly_bell_retiming", "BellgraveBurialToken"]
		"A2-R05":
			expected_nodes = ["Anomaly_anomaly_old_pilgrim_echo", "OldPilgrimWaybill", "CharredChurchSeal"]
		"A2-R06":
			expected_nodes = ["CanopyWaymarkerFragment"]
	for node_name in expected_nodes:
		if get_node_or_null(NodePath(node_name)) == null:
			push_error("[NEREIS][A2][ROOM][AUTHORED_CONTENT_MISSING] room=%s node=%s" % [room_id, node_name])


func _spawn_room_exits() -> void:
	match room_id:
		"A2-R01":
			_spawn_exit_door_at_marker("ExitVillage", "E  返回边境村庄", "village", "res://scenes/regions/village_hub.tscn", "north_gate")
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
			var h02_position := _room_marker_position("H02Gate")
			if h02_position.x < 0.0 or h02_position.y < 0.0:
				return
			_spawn_h02_gate(h02_position.x, h02_position.y)
			_spawn_exit_door_at_marker("ExitToR03", "E  沿回程石沿返回钟墓上环", "ash_forest", _scene_path_for_room("A2-R03"), "a2_r03_crypt_return")
			_spawn_exit_door_at_marker("ExitToR06", "E  深入东侧裂谷", "ash_forest", _scene_path_for_room("A2-R06"), "a2_r06_low_entry")
		"A2-R05":
			_spawn_exit_door_at_marker("ExitToR02", "E  返回树冠断桥", "ash_forest", _scene_path_for_room("A2-R02"), "a2_r02_high_return")
			_spawn_exit_door_at_marker("ExitToR03", "E  返回钟墓高环", "ash_forest", _scene_path_for_room("A2-R03"), "a2_r03_highroad_shortcut")
			_spawn_exit_door_at_marker("ExitToR06", "E  进入东侧裂谷", "ash_forest", _scene_path_for_room("A2-R06"), "a2_r06_high_entry")
			if "reached_A5_and_opened_old_pilgrim_highroad" in WorldState.achievement_flags:
				_spawn_exit_door_at_marker("ExitToA5", "E  返回边境战场", "old_battlefield", "res://scenes/regions/old_battlefield.tscn", "old_pilgrim_highroad")
		"A2-R06":
			_spawn_exit_door_at_marker("ExitToR05", "E  返回旧朝圣高路", "ash_forest", _scene_path_for_room("A2-R05"), "a2_r05_ravine_return")
			_spawn_exit_door_at_marker("ExitToR04", "E  返回钟墓坑底", "ash_forest", _scene_path_for_room("A2-R04"), "a2_r04_ravine_return")
			_spawn_exit_door_at_marker("ExitToA3", "E  沿树冠高路进入被遗忘的城区", "forgotten_city", "res://scenes/regions/forgotten_city.tscn", "city_canopy_entry")


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
	# The trigger and its collision geometry are authored in the room .tscn.
	# Runtime validates that editor-authored geometry still matches the route contract.
	var area := get_node_or_null(transition_name) as Area2D
	if area == null:
		push_error("[NEREIS][A2][ROOM][AUTHORED_DROP_MISSING] room=%s expected=%s" % [room_id, transition_name])
		return
	if area.position.distance_to(Vector2(x, y)) > 1.0:
		push_error("[NEREIS][A2][ROOM][DROP_POSITION_MISMATCH] room=%s area=%s authored=%s expected=%s" % [room_id, transition_name, str(area.position), str(Vector2(x, y))])
		return
	var shape := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or not (shape.shape is RectangleShape2D):
		push_error("[NEREIS][A2][ROOM][DROP_SHAPE_INVALID] room=%s area=%s" % [room_id, transition_name])
		return
	var rectangle := shape.shape as RectangleShape2D
	if not is_equal_approx(rectangle.size.x, width) or not is_equal_approx(rectangle.size.y, height):
		push_error("[NEREIS][A2][ROOM][DROP_SIZE_MISMATCH] room=%s area=%s authored=%s expected=%s" % [room_id, transition_name, str(rectangle.size), str(Vector2(width, height))])
		return
	if area.collision_layer != 0 or area.collision_mask != 1 or not area.monitoring:
		push_error("[NEREIS][A2][ROOM][DROP_MONITOR_CONTRACT] room=%s area=%s" % [room_id, transition_name])
		return
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
