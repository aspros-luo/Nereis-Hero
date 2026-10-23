extends SceneTree
## Headless smoke tests for the scene-authored A1 map and flag-driven visuals.
## Run: godot --headless --path . --script res://tools/a1_scene_smoke_test.gd
## This does not replace manual collision/jump/transition testing.

var failures: Array[String] = []
var original_flags: Array = []

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	original_flags = WorldState.achievement_flags.duplicate()
	WorldState.achievement_flags.clear()
	await _test_a10_scene_and_state_matrix()
	await _test_h09_lock_and_unlock()
	_restore_flags()
	if failures.is_empty():
		print("A1 GODOT SCENE SMOKE TEST: PASS")
		print(" - A1.0/A1.1 scenes instantiate and required authored nodes resolve.")
		print(" - Drain/gate/camp visuals follow their independent story flags.")
		print(" - H01 resonance/open states and H09 cave/door states follow their story flags.")
		quit(0)
		return
	for failure in failures:
		push_error("[A1 SMOKE FAIL] " + failure)
	print("A1 GODOT SCENE SMOKE TEST: FAIL (%d)" % failures.size())
	quit(1)


func _test_a10_scene_and_state_matrix() -> void:
	var packed := load("res://scenes/village_hub.tscn") as PackedScene
	_expect(packed != null, "A1.0 PackedScene loads")
	if packed == null:
		return
	var scene := packed.instantiate()
	_expect(scene != null, "A1.0 scene instantiates")
	if scene == null:
		return
	root.add_child(scene)
	await process_frame

	for path in [
		"Hero", "Hero/HeroCamera", "VillageCheckpoint", "VillageHearthRestPoint",
		"MiteHouseDoor", "BackhillEntrance", "Gatekeeper", "Grandmother",
		"BlacksmithNPC", "TravelingMerchant", "GraveyardPOI", "RestorationCampPOI",
		"NorthGatePOI", "CityCutPOI", "ResonanceWellGate", "WorldEventDirector",
		"NarrativeAudio", "VillageFireflies"
	]:
		_expect(scene.has_node(path), "A1.0 node exists: " + path)

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
	well.call("_sync_authored_visuals")
	_expect(well.get_node("AuthoredVisual/RevealedState").visible, "H01 authored resonance state appears when revealed")
	_expect(not well.get_node("AuthoredVisual/OpenedState").visible, "H01 is not shown as opened while only revealed")
	well.set("opened_permanently", true)
	well.call("_sync_authored_visuals")
	_expect(not well.get_node("AuthoredVisual/RevealedState").visible, "H01 resonance-only state clears after opening")
	_expect(well.get_node("AuthoredVisual/OpenedState").visible, "H01 authored opened state appears after opening")

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
	await process_frame


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
	root.add_child(locked_scene)
	await process_frame
	_expect(not locked_scene.get_node("CliffCaveDoor").visible, "H09 door remains hidden before actual return")
	_expect(not locked_scene.get_node("CliffCaveVisual").visible, "H09 cave visual remains hidden before actual return")
	locked_scene.queue_free()
	await process_frame

	WorldState.achievement_flags.append("returned_to_village_after_mad_cleric")
	var unlocked_scene := packed.instantiate()
	_expect(unlocked_scene != null, "A1.1 unlocked scene instantiates")
	if unlocked_scene == null:
		return
	root.add_child(unlocked_scene)
	await process_frame
	_expect(unlocked_scene.get_node("CliffCaveDoor").visible, "H09 door appears after actual-return flag")
	_expect(unlocked_scene.get_node("CliffCaveDoor").enabled, "H09 door interaction enables after actual-return flag")
	_expect(unlocked_scene.get_node("CliffCaveVisual").visible, "H09 authored cave visual appears after actual-return flag")
	unlocked_scene.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("[A1 SMOKE PASS] " + message)
	else:
		failures.append(message)


func _restore_flags() -> void:
	WorldState.achievement_flags.clear()
	for flag in original_flags:
		WorldState.achievement_flags.append(String(flag))
