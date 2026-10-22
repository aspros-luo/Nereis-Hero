extends SceneTree
## Runtime smoke acceptance for every standalone A5 graybox room.
## Run with: godot --headless --path . --script tools/a5_room_runtime_acceptance.gd
##
## This instantiates all room scenes using the real project scripts and checks
## runtime-created physics nodes. It does not simulate player input or certify
## that every route is manually playable.

const CONTRACT_PATH := "res://tools/a5_room_design_contract.json"
const REPORT_PATH := "user://a5_room_runtime_acceptance_report.json"

var checks: Array[Dictionary] = []
var passed := 0
var failed := 0
var started_at_msec := 0
var observed_platforms := 0
var observed_blocks := 0
var observed_gaps := 0

func _initialize() -> void:
	started_at_msec = Time.get_ticks_msec()
	call_deferred("_run")

func _run() -> void:
	print("")
	print("============================================================")
	print(" A5 ROOM RUNTIME ACCEPTANCE")
	print(" Godot %s" % Engine.get_version_info().string)
	print("============================================================")

	var world_state := root.get_node_or_null("WorldState")
	if world_state == null:
		_record(false, "WORLD_STATE", "WorldState autoload is missing")
		_finish(null)
		return

	# The existing test flag prevents the runtime from changing the user's normal save.
	world_state.set("debug_map_test_mode", true)
	if not FileAccess.file_exists(CONTRACT_PATH):
		_record(false, "CONTRACT_EXISTS", "Missing %s" % CONTRACT_PATH)
		_finish(world_state)
		return

	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH))
	if not (parsed is Dictionary):
		_record(false, "CONTRACT_PARSE", "A5 room contract is not a JSON object")
		_finish(world_state)
		return

	var rooms: Array = parsed.get("rooms", [])
	_record(rooms.size() == 22, "ROOM_INVENTORY", "contract room count=%d; expected 22" % rooms.size())
	for room_variant in rooms:
		if room_variant is Dictionary:
			await _test_room(room_variant)

	await _test_assembled_region(parsed.get("connections", []))

	var terrain_summary: Dictionary = parsed.get("terrain_design", {})
	var expected_platforms := int(terrain_summary.get("expected_platform_count", -1))
	var expected_blocks := int(terrain_summary.get("expected_solid_block_count", -1))
	var expected_gaps := int(terrain_summary.get("expected_floor_gap_count", -1))
	_record(observed_platforms == expected_platforms,
		"GEOMETRY_TOTALS/PLATFORMS", "contract=%d runtime=%d" % [expected_platforms, observed_platforms])
	_record(observed_blocks == expected_blocks,
		"GEOMETRY_TOTALS/RUBBLE", "contract=%d runtime=%d" % [expected_blocks, observed_blocks])
	_record(observed_gaps == expected_gaps,
		"GEOMETRY_TOTALS/FLOOR_GAPS", "contract=%d runtime=%d" % [expected_gaps, observed_gaps])

	_finish(world_state)

func _test_room(room: Dictionary) -> void:
	var room_id := str(room.get("id", "UNKNOWN"))
	var raw_path := str(room.get("scene_path", ""))
	if raw_path.is_empty() or not ResourceLoader.exists(raw_path):
		_record(false, "SCENE_LOAD/%s" % room_id, "scene missing: %s" % raw_path)
		return

	var resource := ResourceLoader.load(raw_path)
	if not (resource is PackedScene):
		_record(false, "SCENE_PACKED/%s" % room_id, "failed to load PackedScene: %s" % raw_path)
		return
	var instance := (resource as PackedScene).instantiate()
	if instance == null:
		_record(false, "SCENE_INSTANTIATE/%s" % room_id, "instantiate() returned null")
		return

	root.add_child(instance)
	# Let _ready(), world setup, Hero initialization, and collision node creation run.
	await process_frame
	await process_frame

	_record(str(instance.get("region_id")) == "A5" and str(instance.get("room_id")) == room_id,
		"ROOM_ID/%s" % room_id,
		"region=%s room=%s" % [str(instance.get("region_id")), str(instance.get("room_id"))])

	var screens: Array = room.get("size_screens", [])
	var expected_width := float(screens[0]) * 1280.0 if screens.size() == 2 else -1.0
	var expected_height := float(screens[1]) * 720.0 if screens.size() == 2 else -1.0
	var map_width := float(instance.get("map_width"))
	var room_height := float(instance.get("room_height"))
	var floor_y := float(instance.get("floor_y"))
	_record(is_equal_approx(map_width, expected_width) and is_equal_approx(room_height, expected_height),
		"DIMENSIONS/%s" % room_id,
		"map=%.0fx%.0f expected=%.0fx%.0f" % [map_width, room_height, expected_width, expected_height])

	var expected_floor := maxf(540.0, room_height - 180.0)
	_record(is_equal_approx(floor_y, expected_floor),
		"FLOOR_HEIGHT/%s" % room_id, "floor_y=%.1f expected=%.1f" % [floor_y, expected_floor])

	var terrain: Dictionary = room.get("terrain_geometry", {})
	var platform_bodies: Array[StaticBody2D] = []
	var rubble_bodies: Array[StaticBody2D] = []
	var ground_bodies: Array[StaticBody2D] = []
	for child in instance.get_children():
		if not (child is StaticBody2D):
			continue
		var body := child as StaticBody2D
		var body_name := str(body.name)
		if body_name.begins_with("A5RoomPlatform_"):
			platform_bodies.append(body)
		elif body_name.begins_with("A5RoomRubble_"):
			rubble_bodies.append(body)
		elif body_name.begins_with("A5RoomGround_"):
			ground_bodies.append(body)

	_record(platform_bodies.size() == int(terrain.get("platform_count", -1)),
		"PLATFORM_COUNT/%s" % room_id,
		"runtime=%d contract=%d" % [platform_bodies.size(), int(terrain.get("platform_count", -1))])
	_record(rubble_bodies.size() == int(terrain.get("solid_rubble_count", -1)),
		"RUBBLE_COUNT/%s" % room_id,
		"runtime=%d contract=%d" % [rubble_bodies.size(), int(terrain.get("solid_rubble_count", -1))])

	var invalid_platforms := 0
	for body in platform_bodies:
		if not _has_rectangle_collision(body, true) or not _rectangle_collision_inside_room(body, map_width, room_height):
			invalid_platforms += 1
	_record(invalid_platforms == 0, "PLATFORM_COLLISIONS/%s" % room_id,
		"invalid one-way rectangle collisions=%d of %d" % [invalid_platforms, platform_bodies.size()])

	var invalid_blocks := 0
	for body in rubble_bodies:
		if not _has_rectangle_collision(body, false) or not _rectangle_collision_inside_room(body, map_width, room_height):
			invalid_blocks += 1
	_record(invalid_blocks == 0, "RUBBLE_COLLISIONS/%s" % room_id,
		"invalid solid rectangle collisions=%d of %d" % [invalid_blocks, rubble_bodies.size()])

	var gap_list: Variant = instance.get("a5_room_floor_gaps")
	var segment_list: Variant = instance.get("a5_room_floor_segments")
	var runtime_gap_count: int = gap_list.size() if gap_list is Array else -1
	var runtime_segment_count: int = segment_list.size() if segment_list is Array else -1
	var expected_gap_count := int(terrain.get("floor_gap_count", -1))
	observed_platforms += platform_bodies.size()
	observed_blocks += rubble_bodies.size()
	observed_gaps += runtime_gap_count
	_record(runtime_gap_count == expected_gap_count,
		"FLOOR_GAP_COUNT/%s" % room_id,
		"runtime=%d contract=%d" % [runtime_gap_count, expected_gap_count])
	_record(runtime_segment_count == expected_gap_count + 1,
		"GROUND_SEGMENTS/%s" % room_id,
		"runtime=%d expected=%d" % [runtime_segment_count, expected_gap_count + 1])

	var ground_coverage := 0.0
	if segment_list is Array:
		for segment in segment_list:
			if segment is Vector2:
				ground_coverage += segment.y
	var gap_coverage := 0.0
	if gap_list is Array:
		for gap in gap_list:
			if gap is Vector2:
				gap_coverage += gap.y
	_record(is_equal_approx(ground_coverage + gap_coverage, map_width),
		"GROUND_COVERAGE/%s" % room_id,
		"solid_width=%.1f + gap_width=%.1f map_width=%.1f" % [ground_coverage, gap_coverage, map_width])

	var invalid_ground_shapes := 0
	var actual_ground_coverage := 0.0
	for body in ground_bodies:
		var ground_collision := _first_collision_shape(body)
		if (
			ground_collision == null
			or ground_collision.shape == null
			or not (ground_collision.shape is RectangleShape2D)
			or not _rectangle_collision_inside_room(body, map_width, room_height)
		):
			invalid_ground_shapes += 1
		else:
			actual_ground_coverage += (ground_collision.shape as RectangleShape2D).size.x
	_record(ground_bodies.size() == expected_gap_count + 1,
		"GROUND_COLLISION_COUNT/%s" % room_id,
		"runtime=%d expected=%d" % [ground_bodies.size(), expected_gap_count + 1])
	_record(invalid_ground_shapes == 0,
		"GROUND_COLLISION_SHAPES/%s" % room_id,
		"invalid ground rectangle collisions=%d" % invalid_ground_shapes)
	_record(is_equal_approx(actual_ground_coverage + gap_coverage, map_width),
		"GROUND_COLLISION_COVERAGE/%s" % room_id,
		"collision_width=%.1f + gap_width=%.1f map_width=%.1f" % [
			actual_ground_coverage, gap_coverage, map_width
		])

	var hero := instance.get_node_or_null("Hero") as CharacterBody2D
	_record(hero != null, "HERO/%s" % room_id, "Hero CharacterBody2D exists=%s" % str(hero != null))
	if hero != null:
		var hero_collision := _first_collision_shape(hero)
		_record(hero_collision != null and hero_collision.shape != null,
			"HERO_COLLISION/%s" % room_id, "Hero collision shape is configured")
		var camera := hero.get_node_or_null("HeroCamera") as Camera2D
		_record(camera != null, "CAMERA/%s" % room_id, "HeroCamera exists=%s" % str(camera != null))
		if camera != null:
			var camera_ok := (
				camera.limit_left == 0
				and camera.limit_top == 0
				and camera.limit_right == int(map_width)
				and camera.limit_bottom == int(room_height)
			)
			_record(camera_ok, "CAMERA_LIMITS/%s" % room_id,
				"limits=(%d,%d,%d,%d) expected=(0,0,%d,%d)" % [
					camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom,
					int(map_width), int(room_height)
				])
		var expected_spawn := Vector2(96.0, floor_y - 96.0)
		if room_id == "A5-R06":
			expected_spawn = Vector2(380.0, 96.0)
		# The scene may advance a few physics ticks before this assertion.
		# Allow limited gravity drift while keeping the authored spawn position exact.
		var spawn_near_expected := (
			absf(hero.position.x - expected_spawn.x) <= 1.0
			and absf(hero.position.y - expected_spawn.y) <= 24.0
		)
		_record(spawn_near_expected,
			"SPAWN/%s" % room_id,
			"actual=(%.1f,%.1f) expected=(%.1f,%.1f)" % [
				hero.position.x, hero.position.y, expected_spawn.x, expected_spawn.y
			])
		# Advance real physics without player input and require the Hero to land on a platform or ground.
		for physics_step in range(45):
			await physics_frame
		_record(hero.is_on_floor(), "PHYSICS_GROUNDING/%s" % room_id,
			"Hero grounded after 45 physics frames; position=(%.1f,%.1f)" % [
				hero.position.x, hero.position.y
			])

	# Standalone room scenes are deliberately terrain-only: no shared world doors or region encounters.
	var unexpected_doors := 0
	var unexpected_encounters := 0
	for node in instance.find_children("*", "Node", true, false):
		if node.get_script() == load("res://scripts/world/interaction_door.gd"):
			unexpected_doors += 1
		if node.has_meta("region_encounter"):
			unexpected_encounters += 1
	_record(unexpected_doors == 0 and unexpected_encounters == 0,
		"ISOLATION/%s" % room_id,
		"doors=%d encounters=%d" % [unexpected_doors, unexpected_encounters])

	print("[A5_RUNTIME] %s platforms=%d rubble=%d gaps=%d ground_segments=%d" % [
		room_id, platform_bodies.size(), rubble_bodies.size(), runtime_gap_count, runtime_segment_count
	])
	instance.queue_free()
	await process_frame

func _test_assembled_region(connections: Array) -> void:
	var scene_path := "res://scenes/a5_assembled_region.tscn"
	if not ResourceLoader.exists(scene_path):
		_record(false, "ASSEMBLY/SCENE_LOAD", "missing " + scene_path)
		return
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_record(false, "ASSEMBLY/PACKED_SCENE", "failed to load assembled A5 PackedScene")
		return
	var instance := packed.instantiate() as Node2D
	if instance == null:
		_record(false, "ASSEMBLY/INSTANTIATE", "assembled A5 root is not Node2D")
		return
	root.add_child(instance)
	await process_frame
	await process_frame

	var room_ids := [
		"A5_R01", "A5_R02", "A5_R03", "A5_R04", "A5_R05", "A5_R06",
		"A5_R07", "A5_R08", "A5_R09", "A5_R10", "A5_R11", "A5_R12",
		"A5_R13", "A5_R14", "A5_R15", "A5_R16", "A5_R17", "A5_R18",
		"A5_R19", "A5_R20", "A5_R21", "A5_R22"
	]
	var present_rooms := 0
	var negative_room_tops := 0
	for room_name in room_ids:
		var room := instance.get_node_or_null(room_name) as Node2D
		if room == null:
			continue
		present_rooms += 1
		if room.position.y < -0.5:
			negative_room_tops += 1
	_record(present_rooms == 22, "ASSEMBLY/ROOM_INVENTORY",
		"instantiated=%d expected=22" % present_rooms)
	_record(negative_room_tops == 0, "ASSEMBLY/UPPER_ROOM_NORMALIZATION",
		"rooms with negative local Y=%d" % negative_room_tops)

	var endpoint_nodes := instance.get_tree().get_nodes_in_group("a5_internal_connection_door")
	var expected_endpoints := 0
	for connection in connections:
		if connection is Dictionary:
			expected_endpoints += 1 if str(connection.get("travel", "both")) == "one_way" else 2
	_record(endpoint_nodes.size() == expected_endpoints and expected_endpoints == 51,
		"ASSEMBLY/CONNECTION_ENDPOINT_COUNT",
		"runtime=%d contract_expected=%d" % [endpoint_nodes.size(), expected_endpoints])

	var malformed_endpoints := 0
	var misplaced_endpoints := 0
	var wrong_transition_modes := 0
	var endpoint_positions: Array[Vector2] = []
	for endpoint_variant in endpoint_nodes:
		if not (endpoint_variant is Area2D):
			malformed_endpoints += 1
			continue
		var endpoint := endpoint_variant as Area2D
		if not endpoint.has_meta("a5_connection_id") or not endpoint.has_meta("a5_from_room") or not endpoint.has_meta("a5_to_room"):
			malformed_endpoints += 1
		var from_id := str(endpoint.get_meta("a5_from_room", ""))
		var source_room := instance.get_node_or_null(from_id.replace("-", "_")) as Node2D
		if source_room == null:
			misplaced_endpoints += 1
		else:
			var local_anchor := endpoint.position - source_room.position
			var source_width := float(source_room.get("map_width"))
			var source_height := float(source_room.get("room_height"))
			if local_anchor.x < 0.0 or local_anchor.x > source_width or local_anchor.y < 0.0 or local_anchor.y > source_height:
				misplaced_endpoints += 1
		var connection_id := str(endpoint.get_meta("a5_connection_id", ""))
		var connection_record: Dictionary = {}
		for connection_variant in connections:
			if connection_variant is Dictionary and str(connection_variant.get("id", "")) == connection_id:
				connection_record = connection_variant
				break
		var should_interact := str(connection_record.get("initial_state", "open")) == "blocked"
		var actual_mode := str(endpoint.get_meta("a5_transition_mode", ""))
		if (should_interact and actual_mode != "interact") or (not should_interact and actual_mode != "auto"):
			wrong_transition_modes += 1
		endpoint_positions.append(endpoint.global_position)
	_record(malformed_endpoints == 0, "ASSEMBLY/CONNECTION_ENDPOINT_METADATA",
		"endpoints missing required metadata=%d" % malformed_endpoints)
	_record(misplaced_endpoints == 0, "ASSEMBLY/CONNECTION_ANCHORS_IN_SOURCE_ROOM",
		"endpoints outside their source room bounds=%d" % misplaced_endpoints)
	_record(wrong_transition_modes == 0, "ASSEMBLY/CONNECTION_TRANSITION_MODES",
		"endpoints using the wrong auto/interact mode=%d" % wrong_transition_modes)

	var overlapping_endpoints := 0
	for i in range(endpoint_positions.size()):
		for j in range(i + 1, endpoint_positions.size()):
			if endpoint_positions[i].distance_to(endpoint_positions[j]) < 100.0:
				overlapping_endpoints += 1
	_record(overlapping_endpoints == 0, "ASSEMBLY/CONNECTION_ENDPOINT_SPACING",
		"endpoint pairs closer than 100px=%d" % overlapping_endpoints)

	var connection_count_errors := 0
	for connection_variant in connections:
		if not connection_variant is Dictionary:
			connection_count_errors += 1
			continue
		var connection: Dictionary = connection_variant
		var connection_id := str(connection.get("id", ""))
		var source_id := str(connection.get("from", ""))
		var target_id := str(connection.get("to", ""))
		var expected_count := 1 if str(connection.get("travel", "both")) == "one_way" else 2
		var actual_count := 0
		var has_source := false
		var has_target := false
		for endpoint_variant in endpoint_nodes:
			if not (endpoint_variant is Area2D):
				continue
			var endpoint := endpoint_variant as Area2D
			if str(endpoint.get_meta("a5_connection_id", "")) != connection_id:
				continue
			actual_count += 1
			var endpoint_from := str(endpoint.get_meta("a5_from_room", ""))
			var endpoint_to := str(endpoint.get_meta("a5_to_room", ""))
			if endpoint_from == source_id and endpoint_to == target_id:
				has_source = true
			if endpoint_from == target_id and endpoint_to == source_id:
				has_target = true
		if actual_count != expected_count or not has_source or (expected_count == 2 and not has_target) or (expected_count == 1 and has_target):
			connection_count_errors += 1
	_record(connection_count_errors == 0, "ASSEMBLY/CONNECTION_DIRECTION_MATRIX",
		"connections with missing/extra endpoints=%d of %d" % [connection_count_errors, connections.size()])

	var hero := instance.get_node_or_null("Hero") as CharacterBody2D
	_record(hero != null, "ASSEMBLY/SINGLE_HERO", "assembled Hero exists=%s" % str(hero != null))
	if hero != null:
		var camera := hero.get_node_or_null("HeroCamera") as Camera2D
		_record(camera != null, "ASSEMBLY/CAMERA", "assembled HeroCamera exists=%s" % str(camera != null))
		if camera != null:
			_record(camera.limit_left == 0 and camera.limit_top == 0
				and camera.limit_right == int(instance.get("map_width"))
				and camera.limit_bottom == int(instance.get("room_height")),
				"ASSEMBLY/CAMERA_LIMITS",
				"limits=(%d,%d,%d,%d) map=(%.0f,%.0f)" % [
					camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom,
					float(instance.get("map_width")), float(instance.get("room_height"))
				])

	for binding in [
		{"door": "Exit_forgotten_city", "room": "A5_R01", "x": 180.0, "y": 410.0, "id": "C08"},
		{"door": "Exit_monastery_tower", "room": "A5_R20", "x": 1200.0, "y": 410.0, "id": "C09"},
		{"door": "Exit_ash_forest", "room": "A5_R16", "x": 980.0, "y": 610.0, "id": "C04"}
	]:
		var room := instance.get_node_or_null(str(binding["room"])) as Node2D
		var door := instance.get_node_or_null(str(binding["door"])) as Node2D
		var ok := room != null and door != null
		if ok:
			var expected_position := room.position + Vector2(float(binding["x"]), float(binding["y"]))
			ok = door.position.distance_to(expected_position) <= 1.0
		_record(ok, "ASSEMBLY/MACRO_BINDING/%s" % str(binding["id"]),
			"room=%s door=%s expected local=(%.0f,%.0f)" % [
				str(binding["room"]), str(binding["door"]),
				float(binding["x"]), float(binding["y"])
			])

	var rest := instance.get_node_or_null("RegionRestPoint_A5") as Node2D
	var hub := instance.get_node_or_null("A5_R12") as Node2D
	var rest_ok := rest != null and hub != null
	if rest_ok:
		rest_ok = rest.position.x >= hub.position.x and rest.position.x <= hub.position.x + float(hub.get("map_width"))
			and rest.position.y >= hub.position.y and rest.position.y <= hub.position.y + float(hub.get("room_height"))
	_record(rest_ok, "ASSEMBLY/REST_POINT_IN_HUB", "rest point is inside R12=%s" % str(rest_ok))

	print("[A5_ASSEMBLY_RUNTIME] rooms=%d negative_tops=%d map=%.0fx%.0f" % [
		present_rooms, negative_room_tops, float(instance.get("map_width")), float(instance.get("room_height"))
	])
	instance.queue_free()
	await process_frame


func _first_collision_shape(body: Node) -> CollisionShape2D:
	for child in body.get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
	return null

func _has_rectangle_collision(body: StaticBody2D, expected_one_way: bool) -> bool:
	var collision := _first_collision_shape(body)
	if collision == null or collision.shape == null or not (collision.shape is RectangleShape2D):
		return false
	if expected_one_way and not collision.one_way_collision:
		return false
	return true

func _rectangle_collision_inside_room(body: StaticBody2D, map_width: float, room_height: float) -> bool:
	var collision := _first_collision_shape(body)
	if collision == null or collision.shape == null or not (collision.shape is RectangleShape2D):
		return false
	var rectangle := collision.shape as RectangleShape2D
	var collision_rect := Rect2(body.position + collision.position - rectangle.size * 0.5, rectangle.size)
	return (
		collision_rect.position.x >= -0.5
		and collision_rect.position.y >= -0.5
		and collision_rect.end.x <= map_width + 0.5
		and collision_rect.end.y <= room_height + 0.5
	)

func _record(ok: bool, name: String, detail: String) -> void:
	checks.append({"name": name, "passed": ok, "detail": detail})
	if ok:
		passed += 1
		print("[PASS] %s :: %s" % [name, detail])
	else:
		failed += 1
		push_error("[FAIL] %s :: %s" % [name, detail])

func _finish(world_state: Node) -> void:
	if world_state != null and is_instance_valid(world_state):
		world_state.set("debug_map_test_mode", false)
	var report := {
		"schema_version": 1,
		"engine": Engine.get_version_info().string,
		"generated_at_unix": Time.get_unix_time_from_system(),
		"duration_ms": Time.get_ticks_msec() - started_at_msec,
		"summary": {
			"passed": passed,
			"failed": failed,
			"total": passed + failed,
			"status": "PASS" if failed == 0 else "FAIL"
		},
		"checks": checks
	}
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[FAIL] Could not write runtime report: %s" % REPORT_PATH)
		failed += 1
	else:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print("")
	print("A5 ROOM RUNTIME ACCEPTANCE: %s | PASS=%d FAIL=%d" % [
		"PASS" if failed == 0 else "FAIL", passed, failed
	])
	print("Report: %s" % ProjectSettings.globalize_path(REPORT_PATH))
	quit(0 if failed == 0 else 1)
