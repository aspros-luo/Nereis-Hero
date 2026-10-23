extends Node
## Headless smoke tests for the scene-authored A1 map and flag-driven visuals.
## Run: godot --headless --path . res://tools/a1_scene_smoke_test.tscn
## This does not replace manual collision/jump/transition testing.

var failures: Array[String] = []
var original_flags: Array = []
var original_discovered_hidden_regions: Array = []
var original_debug_map_test_mode := false

func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	original_flags = WorldState.achievement_flags.duplicate()
	original_discovered_hidden_regions = WorldState.discovered_hidden_regions.duplicate()
	original_debug_map_test_mode = WorldState.debug_map_test_mode
	# Suppress save writes: loading A1.0 activates its checkpoint during smoke testing.
	WorldState.debug_map_test_mode = true
	WorldState.achievement_flags.clear()
	await _test_a10_scene_and_state_matrix()
	await _test_spawn_side_matrix()
	await _test_a11_authored_terrain()
	await _test_h09_lock_and_unlock()
	_restore_flags()
	WorldState.debug_map_test_mode = original_debug_map_test_mode
	if failures.is_empty():
		print("A1 GODOT SCENE SMOKE TEST: PASS")
		print(" - A1.0/A1.1 scenes instantiate and required authored nodes resolve.")
		print(" - Drain/gate/camp visuals follow their independent story flags.")
		print(" - H01 resonance/open states and H09 cave/door states follow their story flags.")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error("[A1 SMOKE FAIL] " + failure)
	print("A1 GODOT SCENE SMOKE TEST: FAIL (%d)" % failures.size())
	get_tree().quit(1)


func _test_a10_scene_and_state_matrix() -> void:
	var packed := load("res://scenes/village_hub.tscn") as PackedScene
	_expect(packed != null, "A1.0 PackedScene loads")
	if packed == null:
		return
	var scene := packed.instantiate()
	_expect(scene != null, "A1.0 scene instantiates")
	if scene == null:
		return
	get_tree().root.add_child(scene)
	await get_tree().process_frame

	for path in [
		"Hero", "Hero/HeroCamera", "VillageCheckpoint", "VillageHearthRestPoint",
		"MiteHouseDoor", "BackhillEntrance", "Gatekeeper", "Grandmother",
		"BlacksmithNPC", "TravelingMerchant", "GraveyardPOI", "RestorationCampPOI",
		"NorthGatePOI", "CityCutPOI", "ResonanceWellGate", "WorldEventDirector",
		"NarrativeAudio", "VillageFireflies"
	]:
		_expect(scene.has_node(path), "A1.0 node exists: " + path)

	var main_ground := scene.get_node_or_null("Terrain/GroundMain") as StaticBody2D
	var main_ground_collision := scene.get_node_or_null("Terrain/GroundMain/CollisionShape2D") as CollisionShape2D
	_expect(main_ground != null and main_ground_collision != null, "A1.0 has one continuous scene-authored ground collider")
	_expect(
		main_ground_collision != null
		and main_ground_collision.shape is RectangleShape2D
		and is_equal_approx((main_ground_collision.shape as RectangleShape2D).size.x, 3000.0),
		"Main ground collision spans the village width without the blacksmith-side drop"
	)
	_expect(
		not scene.has_node("GroundCutouts")
		and not scene.has_node("LowerRouteVisuals")
		and not scene.has_node("Terrain/LowerRouteWest")
		and not scene.has_node("Terrain/LowerRouteMiddle")
		and not scene.has_node("Terrain/LowerRouteEast"),
		"Unused blacksmith-side pits and lower platforms are removed"
	)

	scene.call("_refresh_world_visual_states")
	_expect(scene.get_node("DrainEntranceVisual/RubbleState").visible, "Drain rubble is visible before defense")
	_expect(scene.get_node("NorthGateVisual/BlockedState").visible, "North gate is blocked before defense")
	_expect(not scene.get_node("NorthGateVisual/RepairedState").visible, "North gate repair is hidden before defense")
	_expect(not scene.get_node("CampVisual").visible, "Camp is hidden before its own arrival flag")
	_expect(not scene.get_node("RestorationCampPOI").visible, "Camp POI is hidden before its own arrival flag")

	var well: Node = scene.get_node("ResonanceWellGate")
	well.set("revealed", false)
	well.set("opened_permanently", false)
	well.call("_sync_authored_visuals")
	_expect(not well.get_node("AuthoredVisual/RevealedState").visible, "H01 resonance marks are hidden before reveal")
	_expect(not well.get_node("AuthoredVisual/OpenedState").visible, "H01 opened marker is hidden before opening")
	well.set("revealed", true)
	well.set("opened_permanently", false)
	well.set("hero_nearby", true)
	WorldState.discovered_hidden_regions.clear()
	WorldState.discovered_hidden_regions.append("H01")
	well.call("_sync_authored_visuals")
	_expect(well.get_node("AuthoredVisual/RevealedState").visible, "H01 authored resonance state appears when revealed")
	_expect(not well.get_node("AuthoredVisual/OpenedState").visible, "H01 is not shown as opened while only revealed")
	_expect(well.get_node("StatusLabel").visible, "H01 discovery status uses its authored Label")
	well.set("opened_permanently", true)
	well.call("_sync_authored_visuals")
	_expect(not well.get_node("AuthoredVisual/RevealedState").visible, "H01 resonance-only state clears after opening")
	_expect(well.get_node("AuthoredVisual/OpenedState").visible, "H01 authored opened state appears after opening")
	_expect(not well.get_node("StatusLabel").visible, "H01 discovery prompt clears after permanent opening")

	WorldState.achievement_flags.append("village_defense_survived")
	scene.call("_refresh_world_visual_states")
	_expect(not scene.get_node("DrainEntranceVisual/RubbleState").visible, "Drain rubble clears after defense")
	_expect(not scene.get_node("NorthGateVisual/BlockedState").visible, "Blocked gate bars clear after defense")
	_expect(scene.get_node("NorthGateVisual/RepairedState").visible, "Repaired gate state appears after defense")
	_expect(not scene.get_node("CampVisual").visible, "Defense alone does not establish Restoration Army camp")

	WorldState.achievement_flags.append("restoration_camp_established")
	scene.call("_refresh_world_visual_states")
	_expect(scene.get_node("CampVisual").visible, "Camp visual appears after explicit camp-arrival flag")
	_expect(scene.get_node("RestorationCampPOI").visible, "Camp POI appears after explicit camp-arrival flag")

	scene.queue_free()
	await get_tree().process_frame


func _test_spawn_side_matrix() -> void:
	var packed := load("res://scenes/village_hub.tscn") as PackedScene
	_expect(packed != null, "A1.0 scene loads for spawn matrix")
	if packed == null:
		return
	WorldState.achievement_flags.clear()
	var cases := [
		{"side": "west", "x": 260.0},
		{"side": "backhill_return", "x": 2420.0},
		{"side": "well_exit", "x": 1850.0},
		{"side": "cliff_cave_return", "x": 1850.0},
		{"side": "city_cut_return", "x": 350.0},
		{"side": "north_gate", "x": 2630.0},
		{"side": "mite_house_return", "x": 530.0},
	]
	for test_case in cases:
		WorldState.pending_region_spawn_side = String(test_case["side"])
		var scene := packed.instantiate()
		_expect(scene != null, "A1.0 scene instantiates for spawn side " + String(test_case["side"]))
		if scene == null:
			continue
		get_tree().root.add_child(scene)
		await get_tree().process_frame
		var hero := scene.get_node("Hero") as CharacterBody2D
		_expect(
			is_equal_approx(hero.position.x, float(test_case["x"])),
			"A1.0 spawn side %s resolves to x=%s" % [String(test_case["side"]), str(test_case["x"])]
		)
		scene.queue_free()
		await get_tree().process_frame


func _test_a11_authored_terrain() -> void:
	var packed := load("res://scenes/village_backhill.tscn") as PackedScene
	_expect(packed != null, "A1.1 scene loads for authored-terrain checks")
	if packed == null:
		return
	WorldState.achievement_flags.clear()
	var scene := packed.instantiate()
	_expect(scene != null, "A1.1 scene instantiates for authored-terrain checks")
	if scene == null:
		return
	get_tree().root.add_child(scene)
	await get_tree().process_frame
	var stair_count := 0
	for child in scene.get_node("BackhillStairs").get_children():
		if child is StaticBody2D and child.has_node("CollisionShape2D") and child.has_node("Visual"):
			stair_count += 1
	_expect(stair_count == 8, "A1.1 has eight authored collision-backed stair steps")
	_expect(scene.has_node("CliffLookout/CollisionShape2D"), "A1.1 lookout has authored collision")
	_expect(scene.has_node("CliffLowerShelf/CollisionShape2D"), "A1.1 lower shelf has authored collision")
	_expect(scene.has_node("EastBoundary/CollisionShape2D"), "A1.1 cliff boundary has authored collision")
	_expect(scene.has_node("ChurchTitle") and scene.has_node("TavernTitle") and scene.has_node("BackhillTitle") and scene.has_node("CliffTitle"), "A1.1 landmarks use authored Label nodes")
	scene.queue_free()
	await get_tree().process_frame


func _test_h09_lock_and_unlock() -> void:
	var packed := load("res://scenes/village_backhill.tscn") as PackedScene
	_expect(packed != null, "A1.1 PackedScene loads")
	if packed == null:
		return

	WorldState.achievement_flags.clear()
	var locked_scene := packed.instantiate()
	_expect(locked_scene != null, "A1.1 locked scene instantiates")
	if locked_scene == null:
		return
	get_tree().root.add_child(locked_scene)
	await get_tree().process_frame
	_expect(not locked_scene.get_node("CliffCaveDoor").visible, "H09 door remains hidden before actual return")
	_expect(not locked_scene.get_node("CliffCaveVisual").visible, "H09 cave visual remains hidden before actual return")
	locked_scene.queue_free()
	await get_tree().process_frame

	WorldState.achievement_flags.append("returned_to_village_after_mad_cleric")
	var unlocked_scene := packed.instantiate()
	_expect(unlocked_scene != null, "A1.1 unlocked scene instantiates")
	if unlocked_scene == null:
		return
	get_tree().root.add_child(unlocked_scene)
	await get_tree().process_frame
	_expect(unlocked_scene.get_node("CliffCaveDoor").visible, "H09 door appears after actual-return flag")
	_expect(unlocked_scene.get_node("CliffCaveDoor").enabled, "H09 door interaction enables after actual-return flag")
	_expect(unlocked_scene.get_node("CliffCaveVisual").visible, "H09 authored cave visual appears after actual-return flag")
	unlocked_scene.queue_free()
	await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("[A1 SMOKE PASS] " + message)
	else:
		failures.append(message)


func _restore_flags() -> void:
	WorldState.achievement_flags.clear()
	for flag in original_flags:
		WorldState.achievement_flags.append(String(flag))
	WorldState.discovered_hidden_regions.clear()
	for region_id in original_discovered_hidden_regions:
		WorldState.discovered_hidden_regions.append(String(region_id))
