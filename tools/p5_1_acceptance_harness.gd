extends SceneTree
## P5.1 automated acceptance harness.
## Instantiates the real graybox scenes in Godot and validates runtime contracts.
## world_state.debug_map_test_mode protects the normal save.

const TOPOLOGY_PATH := "res://tools/world_map_topology.json"
const REPORT_PATH := "user://p5_1_automated_acceptance_report.json"

const REGION_SCENES := {
	"A0": "res://scenes/regions/escape_prologue.tscn",
	"A1": "res://scenes/regions/village_hub.tscn",
	"A2": "res://scenes/regions/ash_forest.tscn",
	"A3": "res://scenes/regions/forgotten_city.tscn",
	"A4": "res://scenes/regions/sewer_reservoir.tscn",
	"A5": "res://scenes/regions/old_battlefield.tscn",
	"A6": "res://scenes/regions/monastery_tower.tscn",
	"A7": "res://scenes/regions/prison_depths.tscn",
	"A8": "res://scenes/regions/royal_tomb.tscn",
	"A9": "res://scenes/regions/royal_outer_ring.tscn",
	"A10": "res://scenes/regions/grand_cathedral.tscn",
	"A11": "res://scenes/regions/deep_research_depths.tscn",
	"A12": "res://scenes/regions/inner_city.tscn",
	"A13": "res://scenes/regions/terminal_anomaly.tscn",
	"OB01": "res://scenes/royal_tomb_boss.tscn",
	"H01": "res://scenes/hidden_well.tscn",
	"H02": "res://scenes/hidden_bell_chamber.tscn",
	"H03": "res://scenes/erased_third_street.tscn",
	"H04": "res://scenes/reflected_stairwell.tscn",
	"H05": "res://scenes/silent_bell_room.tscn",
	"H06": "res://scenes/erased_royal_name_corridor.tscn",
	"H07": "res://scenes/mirror_street.tscn",
	"H08": "res://scenes/primordial_hollow.tscn"
}

var topology: Dictionary = {}
var results: Array[Dictionary] = []
var failures := 0
var passes := 0
var started_at: int = 0
var world_state: Node

func _initialize() -> void:
	started_at = Time.get_ticks_msec()
	# In SceneTree --script mode, _initialize runs after project Autoloads are installed.
	# Use the real WorldState singleton so runtime scene scripts and the harness share state.
	world_state = get_root().get_node_or_null("WorldState")
	call_deferred("_run")

func _run() -> void:
	print("")
	print("============================================================")
	print(" P5.1 AUTOMATED ACCEPTANCE HARNESS")
	print(" Godot %s" % Engine.get_version_info().string)
	print("============================================================")
	if not _load_topology():
		_finish()
		return
	_prime_acceptance_state()
	await _validate_scene_inventory_and_runtime()
	await _validate_topology_connections()
	await _validate_c24_phase_gate()
	await _validate_hidden_regions()
	await _validate_loop_contracts()
	await _validate_ground_jump_high_door_clearance()
	await _validate_dynamic_c21_ending_route()
	var report := {
		"schema_version": 1,
		"engine": Engine.get_version_info().string,
		"topology_schema_version": topology.get("schema_version", "unknown"),
		"generated_at_unix": Time.get_unix_time_from_system(),
		"duration_ms": Time.get_ticks_msec() - started_at,
		"summary": {
			"passed": passes,
			"failed": failures,
			"total": passes + failures,
			"status": "PASS" if failures == 0 else "FAIL"
		},
		"checks": results
	}
	_write_report(report)
	print("")
	print("P5.1 HARNESS RESULT: %s | PASS=%d FAIL=%d" % [report.summary.status, passes, failures])
	print("Report: %s" % ProjectSettings.globalize_path(REPORT_PATH))
	_finish()

func _finish() -> void:
	if is_instance_valid(world_state):
		world_state.debug_map_test_mode = false
		world_state.debug_natural_test_active = false
		world_state.debug_natural_test_visited_regions.clear()
	quit(0 if failures == 0 else 1)

func _load_topology() -> bool:
	if not FileAccess.file_exists(TOPOLOGY_PATH):
		_fail("TOPOLOGY_LOAD", "Missing %s" % TOPOLOGY_PATH)
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(TOPOLOGY_PATH))
	if not (parsed is Dictionary):
		_fail("TOPOLOGY_PARSE", "Topology JSON is not a Dictionary")
		return false
	topology = parsed
	_pass("TOPOLOGY_LOAD", "schema=%s regions=%d connections=%d hidden=%d" % [
		str(topology.get("schema_version", "?")),
		(topology.get("regions", []) as Array).size(),
		(topology.get("connections", []) as Array).size(),
		(topology.get("hidden_regions", []) as Array).size()
	])
	return true

func _prime_acceptance_state() -> void:
	world_state.debug_map_test_mode = true
	world_state.debug_natural_test_active = false
	# A0 otherwise shortcuts directly to A1 when the user's normal save marks the prologue complete.
	# The harness must validate A0's actual runtime setup independently of existing save progress.
	world_state.prologue_complete = false
	world_state.boss_defeated = true
	world_state.first_choice_made = true
	world_state.physical_union_complete = true
	world_state.hero_resonance = 100
	world_state.ancient_exposure = 100
	world_state.outer_exposure = 100
	world_state.outer_god_resonance = true
	world_state.ancient_residue_awakened = true
	world_state.hidden_artifact_pieces = 3
	world_state.discovered_hidden_regions.clear()
	world_state.opened_hidden_paths.clear()
	world_state.entered_hidden_regions.clear()
	for hidden_id in ["H01","H02","H03","H04","H05","H06","H07","H08"]:
		world_state.discovered_hidden_regions.append(hidden_id)
		world_state.opened_hidden_paths.append(hidden_id)
		world_state.entered_hidden_regions.append(hidden_id)
	for flag in [
		"village_defense_survived",
		"opened_bell_tower_drop",
		"opened_mirror_street_side_gate",
		"opened_old_bell_tower_connection",
		"opened_old_service_door",
		"opened_royal_tomb_side_door",
		"opened_royal_transport_side_door",
		"reached_A4_via_A3",
		"reached_A10_via_A9",
		"reached_A12_via_A10",
		"reached_A12_via_A10_then_opened_inner_city_side_gate",
		"reached_A5_and_opened_old_pilgrim_highroad",
		"reached_A7_then_opened_supply_tunnel",
		"reached_A8_via_A7_then_opened_royal_tomb_gate",
		"reached_A9_then_opened_royal_drain_from_outer_ring",
		"reached_A9_via_A8_then_opened_old_lift_from_A9",
		"reached_A5_then_opened_old_bell_tower_connection",
		"reached_A9_then_opened_old_service_door",
		"defeated_mad_cleric",
		"defeated_royal_tomb_guardian"
	]:
		if flag not in world_state.achievement_flags:
			world_state.achievement_flags.append(flag)
	world_state.resonance_sources.clear()
	for source_id in [
		"anomaly_bell_retiming",
		"anomaly_old_pilgrim_echo",
		"anomaly_erased_street_sign",
		"anomaly_old_stone_layer",
		"anomaly_erased_royal_name",
		"anomaly_mirror_street_echo",
		"anomaly_observer_reaction"
	]:
		world_state.resonance_sources.append(source_id)
	world_state.unlocked_abilities["resonance_sight"] = {"source_type":"debug","source_id":"p5_1_harness"}
	world_state.pending_region_spawn_side = "west"
	world_state.resume_spawn_side = "west"
	print("[PASS] Acceptance state primed in memory; normal save writes disabled.")

func _validate_scene_inventory_and_runtime() -> void:
	for region_id in REGION_SCENES.keys():
		var path: String = REGION_SCENES[region_id]
		if not ResourceLoader.exists(path):
			_fail("SCENE_EXISTS/%s" % region_id, "Missing %s" % path)
			continue
		var packed := load(path) as PackedScene
		if packed == null:
			_fail("SCENE_LOAD/%s" % region_id, "PackedScene load returned null")
			continue
		var instance := packed.instantiate()
		if instance == null:
			_fail("SCENE_INSTANTIATE/%s" % region_id, "instantiate() returned null")
			continue
		get_root().add_child(instance)
		await process_frame
		await process_frame
		var actual_region: String = region_id
		if _has_property(instance, "region_id"):
			actual_region = str(instance.get("region_id"))
		if actual_region != region_id:
			_fail("SCENE_REGION/%s" % region_id, "expected=%s actual=%s" % [region_id, actual_region])
		else:
			_pass("SCENE_REGION/%s" % region_id, "runtime region=%s" % actual_region)
		var hero := instance.get_node_or_null("Hero")
		if hero == null or not (hero is CharacterBody2D):
			_fail("HERO/%s" % region_id, "Missing CharacterBody2D Hero")
		else:
			var collision := hero.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if collision == null:
				for child in hero.get_children():
					if child is CollisionShape2D:
						collision = child
						break
			if collision == null or collision.shape == null:
				_fail("HERO_COLLISION/%s" % region_id, "Hero CollisionShape2D/shape missing")
			else:
				_pass("HERO_COLLISION/%s" % region_id, "shape=%s" % collision.shape.get_class())
			var spawn := (hero as Node2D).position
			if _is_spawn_supported(instance, spawn):
				_pass("SPAWN_SUPPORT/%s" % region_id, "spawn=(%.1f,%.1f) supported" % [spawn.x, spawn.y])
			else:
				_fail("SPAWN_SUPPORT/%s" % region_id, "spawn=(%.1f,%.1f) unsupported" % [spawn.x, spawn.y])
		var exits := _collect_exit_contracts(instance)
		if exits.is_empty():
			_fail("EXITS/%s" % region_id, "No runtime P5.1 exit/gate contracts")
		else:
			_pass("EXITS/%s" % region_id, "contracts=%d" % exits.size())
		if region_id in ["A7", "A8"]:
			_validate_c13_upper_approach(instance, exits)
		if region_id == "A12":
			_validate_c22_upper_approach(instance, exits)
		var expected_rest: bool = region_id in ["A1","A2","A3","A4","A5","A6","A7","A8","A9","A10","A11","A12"]
		var rest_count := 0
		for node in instance.find_children("*", "Node2D", true, false):
			if node.has_meta("p5_1_rest_contract"):
				rest_count += 1
		if expected_rest and rest_count != 1:
			_fail("REST/%s" % region_id, "expected=1 actual=%d" % [rest_count])
		elif expected_rest:
			_pass("REST/%s" % region_id, "rest point present")
		instance.queue_free()
		await process_frame

func _validate_c13_upper_approach(instance: Node, exits: Array) -> void:
	var expected_target := "A8" if str(instance.get("region_id")) == "A7" else "A7"
	var door: Node2D
	for exit_node in exits:
		if _contract_target_region(exit_node) == expected_target:
			door = exit_node as Node2D
			break
	var region_id := str(instance.get("region_id"))
	if door == null:
		_fail("C13_DOOR/%s" % region_id, "C13 endpoint door targeting %s is missing" % expected_target)
		return

	var floor_y := float(instance.get("floor_y")) if _has_property(instance, "floor_y") else 540.0
	var door_height := floor_y - door.position.y
	if absf(door_height - 180.0) > 0.5:
		_fail("C13_DOOR_HEIGHT/%s" % region_id, "expected=180px above floor actual=%.1f" % door_height)
	else:
		_pass("C13_DOOR_HEIGHT/%s" % region_id, "door is %.1fpx above continuous floor" % door_height)

	var supported_by_upper_landing := false
	if _has_property(instance, "platforms"):
		var platforms = instance.get("platforms")
		if platforms is Array:
			for rect in platforms:
				if not (rect is Rect2):
					continue
				if door.position.x < rect.position.x or door.position.x > rect.end.x:
					continue
				if absf(rect.position.y - (door.position.y + 20.0)) <= 3.0:
					supported_by_upper_landing = true
					break
	if supported_by_upper_landing:
		_pass("C13_LANDING_SUPPORT/%s" % region_id, "upper landing supports the door at y=%.1f" % (door.position.y + 20.0))
	else:
		_fail("C13_LANDING_SUPPORT/%s" % region_id, "no upper platform supports the C13 door")

func _validate_c22_upper_approach(instance: Node, exits: Array) -> void:
	var terminal_door: Node2D
	for exit_node in exits:
		if _contract_target_scene(exit_node) == str(REGION_SCENES.get("A13", "")):
			terminal_door = exit_node as Node2D
			break
	if terminal_door == null:
		_fail("C22_DOOR/A12", "A12 -> A13 terminal door is missing")
		return

	var floor_y := float(instance.get("floor_y")) if _has_property(instance, "floor_y") else 540.0
	var door_height := floor_y - terminal_door.position.y
	if absf(door_height - 180.0) > 0.5:
		_fail("C22_DOOR_HEIGHT/A12", "expected=180px above floor actual=%.1f" % door_height)
	else:
		_pass("C22_DOOR_HEIGHT/A12", "door is %.1fpx above continuous floor" % door_height)

	var supported_by_upper_landing := false
	if _has_property(instance, "platforms"):
		var platforms = instance.get("platforms")
		if platforms is Array:
			for rect in platforms:
				if not (rect is Rect2):
					continue
				if terminal_door.position.x < rect.position.x or terminal_door.position.x > rect.end.x:
					continue
				if absf(rect.position.y - (terminal_door.position.y + 20.0)) <= 3.0:
					supported_by_upper_landing = true
					break
	if supported_by_upper_landing:
		_pass("C22_LANDING_SUPPORT/A12", "terminal door overlaps the upper landing at y=%.1f" % (terminal_door.position.y + 20.0))
	else:
		_fail("C22_LANDING_SUPPORT/A12", "no platform supports the terminal door at its authored landing height")

func _validate_dynamic_c21_ending_route() -> void:
	# C21 must appear in the same A11 session when local progression changes the ending candidate.
	# C21 条件可能在 A11 内通过异常调查达成，不能要求玩家离开并重新进入场景。
	var original_resonance: int = world_state.hero_resonance
	var original_artifact_pieces: int = world_state.hidden_artifact_pieces
	var original_entered_regions: Array[String] = world_state.entered_hidden_regions.duplicate()
	var original_sources: Array[String] = world_state.resonance_sources.duplicate()

	world_state.hero_resonance = 55
	world_state.hidden_artifact_pieces = 0
	world_state.entered_hidden_regions.clear()
	world_state.entered_hidden_regions.append("A11")
	world_state.resonance_sources.erase("anomaly_observer_reaction")

	var region := await _load_runtime_region("A11")
	if region == null:
		_fail("C21_DYNAMIC/SCENE", "Cannot instantiate A11 for ending-candidate refresh check")
		world_state.hero_resonance = original_resonance
		world_state.hidden_artifact_pieces = original_artifact_pieces
		world_state.entered_hidden_regions.assign(original_entered_regions)
		world_state.resonance_sources.assign(original_sources)
		return

	var candidate_before := NereisEndingEvaluator.get_candidate()
	var door_before := region.get_node_or_null("Exit_terminal_anomaly")
	if candidate_before == "凡人之墓" and door_before == null:
		_pass("C21_DYNAMIC/INITIAL_LOCKED", "C21 remains unavailable while the candidate is 凡人之墓")
	else:
		_fail("C21_DYNAMIC/INITIAL_LOCKED", "Expected no C21 door for the initial human-grave candidate")

	# This mirrors the A11 observer-anomaly milestone: resonance rises and the candidate source is recorded.
	world_state.hero_resonance = 78
	if "anomaly_observer_reaction" not in world_state.resonance_sources:
		world_state.resonance_sources.append("anomaly_observer_reaction")
	var candidate_after := NereisEndingEvaluator.get_candidate()
	for tick in range(3):
		await process_frame

	if candidate_after != "凡人之墓":
		_pass("C21_DYNAMIC/CANDIDATE_UPDATE", "A11 progression changed candidate to %s" % candidate_after)
	else:
		_fail("C21_DYNAMIC/CANDIDATE_UPDATE", "Observer milestone did not produce a non-human ending candidate")

	var ending_door := region.get_node_or_null("Exit_terminal_anomaly") as Area2D
	var contract_ok := (
		ending_door != null
		and bool(ending_door.get("enabled"))
		and str(ending_door.get_meta("p5_1_target_region", "")) == "A13"
		and str(ending_door.get_meta("p5_1_target_scene", "")) == "res://scenes/regions/terminal_anomaly.tscn"
		and str(ending_door.get_meta("p5_1_spawn_side", "")) == "west"
	)
	if contract_ok:
		_pass("C21_DYNAMIC/ROUTE_CREATED", "C21 door appeared in-place with the A13/west transition contract")
	else:
		_fail("C21_DYNAMIC/ROUTE_CREATED", "C21 door did not appear with the expected enabled A13/west contract")

	region.queue_free()
	await process_frame
	world_state.hero_resonance = original_resonance
	world_state.hidden_artifact_pieces = original_artifact_pieces
	world_state.entered_hidden_regions.assign(original_entered_regions)
	world_state.resonance_sources.assign(original_sources)


func _validate_ground_jump_high_door_clearance() -> void:
	# Exercise the real CharacterBody2D and Area2D overlap behavior, not only static jump-height math.
	# 实际推进物理帧，检查真实 CharacterBody2D 是否能从高门正下方触发门的 Area2D。
	var test_cases: Array[Dictionary] = [
		{"region": "A7", "target": "A8", "id": "C13_GROUND_JUMP/A7"},
		{"region": "A8", "target": "A7", "id": "C13_GROUND_JUMP/A8"},
		{"region": "A12", "target": "A13", "id": "C22_GROUND_JUMP/A12"}
	]
	for test_case in test_cases:
		var region_id := str(test_case["region"])
		var target_id := str(test_case["target"])
		var check_id := str(test_case["id"])
		var region := await _load_runtime_region(region_id)
		if region == null:
			_fail("%s/SCENE" % check_id, "Cannot instantiate %s" % region_id)
			continue

		var hero := region.get_node_or_null("Hero") as CharacterBody2D
		var door: Area2D
		for exit_node in _collect_exit_contracts(region):
			if _contract_target_region(exit_node) == target_id:
				door = exit_node as Area2D
				break
		if hero == null or door == null:
			_fail("%s/SETUP" % check_id, "Hero or target Area2D door is missing")
			region.queue_free()
			await process_frame
			continue

		var floor_y := float(region.get("floor_y")) if _has_property(region, "floor_y") else 540.0
		hero.global_position = Vector2(door.global_position.x, floor_y)
		hero.velocity = Vector2.ZERO
		for settle_frame in range(4):
			await physics_frame
		if not hero.is_on_floor():
			_fail("%s/GROUND_START" % check_id, "Hero did not settle on the continuous floor")
			region.queue_free()
			await process_frame
			continue
		_pass("%s/GROUND_START" % check_id, "Hero grounded directly below door at x=%.1f" % door.global_position.x)

		var start_y := hero.global_position.y
		hero.velocity = Vector2(0.0, -520.0)
		var highest_y := start_y
		var entered_door_trigger := false
		var focus_became_available := false
		var returned_to_floor := false
		for tick in range(72):
			await physics_frame
			highest_y = minf(highest_y, hero.global_position.y)
			entered_door_trigger = entered_door_trigger or bool(door.get("hero_nearby"))
			focus_became_available = focus_became_available or bool(door.get_meta("interaction_available", false))
			if tick > 6 and hero.is_on_floor():
				returned_to_floor = true
				break

		var rise := start_y - highest_y
		if rise >= 75.0 and rise <= 110.0:
			_pass("%s/PHYSICS_JUMP" % check_id, "simulated rise=%.1fpx within the expected ground-jump envelope" % rise)
		else:
			_fail("%s/PHYSICS_JUMP" % check_id, "expected a real jump rise of 75-110px; observed %.1fpx" % rise)

		if not entered_door_trigger and not focus_became_available:
			_pass("%s/NO_GROUND_BYPASS" % check_id, "ground jump did not overlap or focus the elevated door")
		else:
			_fail("%s/NO_GROUND_BYPASS" % check_id, "ground jump unexpectedly entered/focused the elevated door Area2D")

		if returned_to_floor:
			_pass("%s/RECOVERY" % check_id, "Hero returned to the continuous floor after the jump")
		else:
			_fail("%s/RECOVERY" % check_id, "Hero did not return to the continuous floor within 72 physics frames")

		region.queue_free()
		await process_frame


func _validate_topology_connections() -> void:
	for connection in topology.get("connections", []):
		if not (connection is Dictionary):
			_fail("CONNECTION/INVALID", "entry is not Dictionary")
			continue
		var id := str(connection.get("id", ""))
		var from_id := str(connection.get("from", ""))
		var to_id := str(connection.get("to", ""))
		var source := await _load_runtime_region(from_id)
		if source == null:
			_fail("CONNECTION/%s" % id, "Cannot instantiate source=%s" % from_id)
			continue
		var target_path := str(REGION_SCENES.get(to_id, ""))
		var matches := _find_exit_matches(source, target_path, to_id)
		if matches.is_empty():
			var staged_detail := await _validate_staged_route(connection)
			if staged_detail.is_empty():
				_fail("CONNECTION/%s" % id, "No runtime edge %s -> %s and declared staged route did not validate" % [from_id, to_id])
			else:
				_pass("CONNECTION/%s" % id, "%s -> %s validated as staged route: %s" % [from_id, to_id, staged_detail])
		else:
			_pass("CONNECTION/%s" % id, "%s -> %s contracts=%d" % [from_id, to_id, matches.size()])
			for match in matches:
				await _validate_exit_target_spawn(id, from_id, match, to_id)
		source.queue_free()
		await process_frame


func _validate_staged_route(connection: Dictionary) -> String:
	# Some topology edges intentionally cross intermediate scenes instead of exposing
	# a direct door from the source region to the final region (A0 prologue, C24 drain).
	# Validate every authored runtime hop rather than inventing a direct connection.
	var chain: Array = connection.get("route_chain", [])
	if chain.is_empty():
		var spatial: Dictionary = connection.get("spatial_contract", {})
		chain = spatial.get("route_chain", [])
	if chain.size() < 3:
		return ""

	var connection_id := str(connection.get("id", ""))
	var had_drain_flag: bool = world_state.achievement_flags.has("opened_old_drainage_link_from_A4")
	var validated_hops: Array[String] = []
	for index in range(chain.size() - 1):
		var source_path := str(chain[index])
		var target_path := str(chain[index + 1])
		if not source_path.begins_with("res://"):
			source_path = "res://" + source_path
		if not target_path.begins_with("res://"):
			target_path = "res://" + target_path
		if connection_id == "C24" and source_path.ends_with("/old_drain_exploration.tscn"):
			if not had_drain_flag and "opened_old_drainage_link_from_A4" not in world_state.achievement_flags:
				world_state.achievement_flags.append("opened_old_drainage_link_from_A4")

		var packed := load(source_path) as PackedScene
		if packed == null:
			if not had_drain_flag:
				world_state.achievement_flags.erase("opened_old_drainage_link_from_A4")
			return "cannot load hop source=%s" % source_path
		var instance := packed.instantiate()
		if instance == null:
			if not had_drain_flag:
				world_state.achievement_flags.erase("opened_old_drainage_link_from_A4")
			return "cannot instantiate hop source=%s" % source_path
		get_root().add_child(instance)
		await process_frame
		await process_frame
		var target_region := ""
		for region_id in REGION_SCENES.keys():
			if str(REGION_SCENES[region_id]) == target_path:
				target_region = str(region_id)
				break
		var matches := _find_exit_matches(instance, target_path, target_region)
		instance.queue_free()
		await process_frame
		if matches.is_empty():
			if not had_drain_flag:
				world_state.achievement_flags.erase("opened_old_drainage_link_from_A4")
			return "missing hop %s -> %s" % [source_path, target_path]
		validated_hops.append("%s→%s" % [source_path.get_file(), target_path.get_file()])
	if not had_drain_flag:
		world_state.achievement_flags.erase("opened_old_drainage_link_from_A4")
	return "hops=%d (%s)" % [validated_hops.size(), "; ".join(validated_hops)]


func _validate_c24_phase_gate() -> void:
	# Verify both states of C24's real intermediate scene: closed before the A4-side
	# interaction, and connected to A3 only after the persistent flag is present.
	var had_flag: bool = world_state.achievement_flags.has("opened_old_drainage_link_from_A4")
	world_state.achievement_flags.erase("opened_old_drainage_link_from_A4")
	var locked := await _load_scene_path("res://scenes/old_drain_exploration.tscn")
	if locked == null:
		_fail("CONNECTION/C24/PHASE_LOCKED", "Cannot instantiate old-drain scene in locked state")
	else:
		var locked_matches := _find_exit_matches(locked, str(REGION_SCENES.get("A3", "")), "A3")
		if locked_matches.is_empty():
			_pass("CONNECTION/C24/PHASE_LOCKED", "A3 exit is absent while the old-drain gate is locked")
		else:
			_fail("CONNECTION/C24/PHASE_LOCKED", "A3 exit unexpectedly exists before the A4-side gate opens")
		locked.queue_free()
		await process_frame
	world_state.achievement_flags.append("opened_old_drainage_link_from_A4")
	var opened := await _load_scene_path("res://scenes/old_drain_exploration.tscn")
	if opened == null:
		_fail("CONNECTION/C24/PHASE_OPEN", "Cannot instantiate old-drain scene after gate unlock")
	else:
		var opened_matches := _find_exit_matches(opened, str(REGION_SCENES.get("A3", "")), "A3")
		if not opened_matches.is_empty():
			_pass("CONNECTION/C24/PHASE_OPEN", "A3 exit appears after the persistent A4-side gate flag")
		else:
			_fail("CONNECTION/C24/PHASE_OPEN", "A3 exit is missing after the A4-side gate flag")
		opened.queue_free()
		await process_frame
	if not had_flag:
		world_state.achievement_flags.erase("opened_old_drainage_link_from_A4")


func _load_scene_path(scene_path: String) -> Node:
	if not ResourceLoader.exists(scene_path):
		return null
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return null
	var instance := packed.instantiate()
	if instance == null:
		return null
	get_root().add_child(instance)
	await process_frame
	await process_frame
	return instance


func _validate_hidden_regions() -> void:
	for entry in topology.get("hidden_regions", []):
		var id := str(entry.get("id", ""))
		var parent := str(entry.get("parent", ""))
		var source := await _load_runtime_region(parent)
		if source == null:
			_fail("HIDDEN/%s" % id, "Cannot instantiate parent=%s" % parent)
			continue
		var target_path := str(entry.get("scene_path", ""))
		var matches := _find_exit_matches(source, target_path, id)
		if matches.is_empty():
			_fail("HIDDEN/%s" % id, "No runtime gate %s -> %s" % [parent, id])
		else:
			_pass("HIDDEN/%s" % id, "parent=%s gates=%d" % [parent, matches.size()])
			for match in matches:
				await _validate_exit_target_spawn(id, parent, match, id)
		source.queue_free()
		await process_frame

func _validate_loop_contracts() -> void:
	for loop_entry in topology.get("loops", []):
		var id := str(loop_entry.get("id", ""))
		var path: Array = loop_entry.get("path", [])
		if path.size() < 2:
			_fail("LOOP/%s" % id, "path too short")
			continue
		var edge_count := 0
		for i in range(path.size() - 1):
			var from_id := str(path[i])
			var to_id := str(path[i + 1])
			var source := await _load_runtime_region(from_id)
			if source == null:
				_fail("LOOP/%s/%d" % [id, i], "Cannot instantiate %s" % from_id)
				continue
			var target_path := str(REGION_SCENES.get(to_id, ""))
			if _find_exit_matches(source, target_path, to_id).is_empty():
				_fail("LOOP/%s/%d" % [id, i], "Missing edge %s -> %s" % [from_id, to_id])
			else:
				edge_count += 1
			source.queue_free()
			await process_frame
		if edge_count == path.size() - 1:
			_pass("LOOP/%s" % id, "edges=%d/%d" % [edge_count, path.size() - 1])
		else:
			_fail("LOOP/%s" % id, "edges=%d/%d" % [edge_count, path.size() - 1])

func _load_runtime_region(region_id: String) -> Node:
	var path: String = REGION_SCENES.get(region_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var instance := packed.instantiate()
	if instance == null:
		return null
	get_root().add_child(instance)
	await process_frame
	await process_frame
	return instance

func _collect_exit_contracts(instance: Node) -> Array:
	var contracts: Array = []
	# Some scene roots (notably A0) carry a complete transition contract themselves.
	if instance.has_meta("p5_1_exit_contract"):
		contracts.append(instance)
	for node in instance.find_children("*", "Node", true, false):
		# P5.1 contract metadata is the preferred explicit interface. Existing runtime
		# gates also expose the same target fields directly; accept those as runtime
		# contracts so the harness verifies the shipped gate implementation rather than
		# requiring every gate to be rewritten only for the test.
		if node.has_meta("p5_1_exit_contract"):
			contracts.append(node)
		elif _has_property(node, "target_scene_path") and _has_property(node, "target_spawn_side"):
			var target_scene := str(node.get("target_scene_path"))
			var spawn_side := str(node.get("target_spawn_side"))
			if not target_scene.is_empty() and not spawn_side.is_empty():
				contracts.append(node)
	return contracts

func _contract_target_scene(node: Node) -> String:
	if node.has_meta("p5_1_target_scene"):
		return str(node.get_meta("p5_1_target_scene", ""))
	if _has_property(node, "target_scene_path"):
		return str(node.get("target_scene_path"))
	return ""

func _contract_target_region(node: Node) -> String:
	if node.has_meta("p5_1_target_region"):
		return str(node.get_meta("p5_1_target_region", ""))
	var target_scene := _contract_target_scene(node)
	for region_id in REGION_SCENES.keys():
		if REGION_SCENES[region_id] == target_scene:
			return str(region_id)
	return ""

func _contract_spawn_side(node: Node) -> String:
	if node.has_meta("p5_1_spawn_side"):
		return str(node.get_meta("p5_1_spawn_side", ""))
	if _has_property(node, "target_spawn_side"):
		return str(node.get("target_spawn_side"))
	return ""

func _find_exit_matches(instance: Node, target_scene: String, target_region: String) -> Array:
	var matches: Array = []
	for node in _collect_exit_contracts(instance):
		if _contract_target_scene(node) == target_scene or _contract_target_region(node) == target_region:
			matches.append(node)
	return matches

func _validate_exit_target_spawn(connection_id: String, from_region: String, exit_node: Node, target_region: String) -> void:
	var target := await _load_runtime_region(target_region)
	if target == null:
		_fail("SPAWN/%s/%s" % [connection_id, target_region], "Cannot load target")
		return
	var spawn_side := _contract_spawn_side(exit_node)
	if spawn_side.is_empty():
		_fail("SPAWN/%s/%s" % [connection_id, target_region], "spawn_side missing")
	else:
		var expected_scene: String = _contract_target_scene(exit_node)
		var target_path: String = str(REGION_SCENES.get(target_region, ""))
		if expected_scene != target_path:
			_fail("TARGET/%s/%s" % [connection_id, target_region], "expected=%s actual=%s" % [target_path, expected_scene])
		else:
			var spawn: Variant = _resolve_spawn(target, target_region, spawn_side)
			if spawn is Vector2 and _is_spawn_supported(target, spawn):
				_pass("SPAWN/%s/%s" % [connection_id, target_region], "side=%s supported=(%.1f,%.1f)" % [spawn_side, spawn.x, spawn.y])
			elif spawn is Vector2:
				_fail("SPAWN/%s/%s" % [connection_id, target_region], "side=%s unsupported=(%.1f,%.1f)" % [spawn_side, spawn.x, spawn.y])
			else:
				_fail("SPAWN/%s/%s" % [connection_id, target_region], "cannot resolve side=%s" % spawn_side)
	target.queue_free()
	await process_frame

func _resolve_spawn(target: Node, target_region: String, spawn_side: String) -> Variant:
	if target.has_method("_spawn_x_for_side") and target.has_method("_spawn_y_for_side"):
		var x: float = float(target.call("_spawn_x_for_side", spawn_side))
		var y: float = float(target.call("_spawn_y_for_side", spawn_side))
		return Vector2(x, y)
	if target_region == "A0":
		return Vector2(280.0, 540.0)
	if target_region == "A1":
		match spawn_side:
			"well_exit", "cliff_cave_return":
				return Vector2(1850.0, 520.0)
			"city_cut_return":
				return Vector2(350.0, 520.0)
			"north_gate":
				return Vector2(2310.0, 520.0)
			_:
				return Vector2(260.0, 520.0)
	return null

func _is_spawn_supported(instance: Node, spawn: Vector2) -> bool:
	var floor_y := float(instance.get("floor_y")) if _has_property(instance, "floor_y") else 540.0
	# Hero collision is offset upward so its feet align with the Node2D origin.
	# A spawn up to 24px above the continuous floor is a safe settling gap, not a missing support surface.
	# Keep elevated platform checks strict below so this does not mask high-route landing errors.
	var support_y := spawn.y
	if support_y <= floor_y and floor_y - support_y <= 24.0:
		if _has_property(instance, "map_width"):
			return spawn.x >= 0.0 and spawn.x <= float(instance.get("map_width"))
		return true
	if _has_property(instance, "platforms"):
		var platforms = instance.get("platforms")
		if platforms is Array:
			for rect in platforms:
				if rect is Rect2 and spawn.x >= rect.position.x and spawn.x <= rect.end.x and absf(support_y - rect.position.y) <= 3.0:
					return true
	return false

func _has_property(node: Object, property_name: String) -> bool:
	for prop in node.get_property_list():
		if str(prop.get("name", "")) == property_name:
			return true
	return false

func _pass(check_id: String, detail: String) -> void:
	passes += 1
	results.append({"id":check_id,"status":"PASS","detail":detail})
	print("[PASS] %s :: %s" % [check_id, detail])

func _fail(check_id: String, detail: String) -> void:
	failures += 1
	results.append({"id":check_id,"status":"FAIL","detail":detail})
	print("[FAIL] %s :: %s" % [check_id, detail])

func _write_report(report: Dictionary) -> void:
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t", false))
		file.close()
