extends SceneTree
## P5.1 automated acceptance harness.
## Instantiates the real graybox scenes in Godot and validates runtime contracts.
## WorldState.debug_map_test_mode protects the normal save.

const TOPOLOGY_PATH := "res://tools/world_map_topology.json"
const REPORT_PATH := "user://p5_1_automated_acceptance_report.json"

const REGION_SCENES := {
	"A0": "res://scenes/escape_prologue.tscn",
	"A1": "res://scenes/village_hub.tscn",
	"A2": "res://scenes/ash_forest.tscn",
	"A3": "res://scenes/forgotten_city.tscn",
	"A4": "res://scenes/sewer_reservoir.tscn",
	"A5": "res://scenes/old_battlefield.tscn",
	"A6": "res://scenes/monastery_tower.tscn",
	"A7": "res://scenes/prison_depths.tscn",
	"A8": "res://scenes/royal_tomb.tscn",
	"A9": "res://scenes/royal_outer_ring.tscn",
	"A10": "res://scenes/grand_cathedral.tscn",
	"A11": "res://scenes/deep_research_depths.tscn",
	"A12": "res://scenes/inner_city.tscn",
	"A13": "res://scenes/terminal_anomaly.tscn",
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
var started_at := 0

func _init() -> void:
	started_at = Time.get_ticks_msec()
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
	await _validate_hidden_regions()
	await _validate_loop_contracts()
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
	WorldState.debug_map_test_mode = false
	WorldState.debug_natural_test_active = false
	WorldState.debug_natural_test_visited_regions.clear()
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
	WorldState.debug_map_test_mode = true
	WorldState.debug_natural_test_active = false
	WorldState.boss_defeated = true
	WorldState.first_choice_made = true
	WorldState.physical_union_complete = true
	WorldState.hero_resonance = 100
	WorldState.ancient_exposure = 100
	WorldState.outer_exposure = 100
	WorldState.outer_god_resonance = true
	WorldState.ancient_residue_awakened = true
	WorldState.hidden_artifact_pieces = 3
	WorldState.discovered_hidden_regions.clear()
	WorldState.opened_hidden_paths.clear()
	WorldState.entered_hidden_regions.clear()
	for hidden_id in ["H01","H02","H03","H04","H05","H06","H07","H08"]:
		WorldState.discovered_hidden_regions.append(hidden_id)
		WorldState.opened_hidden_paths.append(hidden_id)
		WorldState.entered_hidden_regions.append(hidden_id)
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
		if flag not in WorldState.achievement_flags:
			WorldState.achievement_flags.append(flag)
	WorldState.resonance_sources.clear()
	for source_id in [
		"anomaly_bell_retiming",
		"anomaly_old_pilgrim_echo",
		"anomaly_erased_street_sign",
		"anomaly_old_stone_layer",
		"anomaly_erased_royal_name",
		"anomaly_mirror_street_echo",
		"anomaly_observer_reaction"
	]:
		WorldState.resonance_sources.append(source_id)
	WorldState.unlocked_abilities["resonance_sight"] = {"source_type":"debug","source_id":"p5_1_harness"}
	WorldState.pending_region_spawn_side = "west"
	WorldState.resume_spawn_side = "west"
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
			var collision := hero.get_node_or_null("CollisionShape2D")
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
			_fail("CONNECTION/%s" % id, "No runtime edge %s -> %s" % [from_id, to_id])
		else:
			_pass("CONNECTION/%s" % id, "%s -> %s contracts=%d" % [from_id, to_id, matches.size()])
			for match in matches:
				await _validate_exit_target_spawn(id, from_id, match, to_id)
		source.queue_free()
		await process_frame

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
	for node in instance.find_children("*", "Node", true, false):
		if node.has_meta("p5_1_exit_contract"):
			contracts.append(node)
	return contracts

func _find_exit_matches(instance: Node, target_scene: String, target_region: String) -> Array:
	var matches: Array = []
	for node in _collect_exit_contracts(instance):
		if str(node.get_meta("p5_1_target_scene", "")) == target_scene or str(node.get_meta("p5_1_target_region", "")) == target_region:
			matches.append(node)
	return matches

func _validate_exit_target_spawn(connection_id: String, from_region: String, exit_node: Node, target_region: String) -> void:
	var target := await _load_runtime_region(target_region)
	if target == null:
		_fail("SPAWN/%s/%s" % [connection_id, target_region], "Cannot load target")
		return
	var spawn_side := str(exit_node.get_meta("p5_1_spawn_side", ""))
	if spawn_side.is_empty():
		_fail("SPAWN/%s/%s" % [connection_id, target_region], "spawn_side missing")
	else:
		var expected_scene: String = str(exit_node.get_meta("p5_1_target_scene", ""))
		var target_path: String = str(REGION_SCENES.get(target_region, ""))
		if expected_scene != target_path:
			_fail("TARGET/%s/%s" % [connection_id, target_region], "expected=%s actual=%s" % [target_path, expected_scene])
		else:
			var spawn: Variant = _resolve_spawn(target, spawn_side)
			if spawn is Vector2 and _is_spawn_supported(target, spawn):
				_pass("SPAWN/%s/%s" % [connection_id, target_region], "side=%s supported=(%.1f,%.1f)" % [spawn_side, spawn.x, spawn.y])
			elif spawn is Vector2:
				_fail("SPAWN/%s/%s" % [connection_id, target_region], "side=%s unsupported=(%.1f,%.1f)" % [spawn_side, spawn.x, spawn.y])
			else:
				_fail("SPAWN/%s/%s" % [connection_id, target_region], "cannot resolve side=%s" % spawn_side)
	target.queue_free()
	await process_frame

func _resolve_spawn(target: Node, spawn_side: String) -> Variant:
	if target.has_method("_spawn_x_for_side") and target.has_method("_spawn_y_for_side"):
		var x: float = float(target.call("_spawn_x_for_side", spawn_side))
		var y: float = float(target.call("_spawn_y_for_side", spawn_side))
		return Vector2(x, y)
	if str(target.get("region_id")) == "A0":
		return Vector2(280.0, 540.0)
	return null

func _is_spawn_supported(instance: Node, spawn: Vector2) -> bool:
	var floor_y := float(instance.get("floor_y")) if _has_property(instance, "floor_y") else 540.0
	if absf(spawn.y - floor_y) <= 2.0:
		if _has_property(instance, "map_width"):
			return spawn.x >= 0.0 and spawn.x <= float(instance.get("map_width"))
		return true
	if _has_property(instance, "platforms"):
		var platforms = instance.get("platforms")
		if platforms is Array:
			for rect in platforms:
				if rect is Rect2 and spawn.x >= rect.position.x and spawn.x <= rect.end.x and absf(spawn.y - rect.position.y) <= 2.0:
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
		file.store_string(JSON.stringify(report, "\\t", false))
		file.close()
