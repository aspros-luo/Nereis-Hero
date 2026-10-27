#!/usr/bin/env python3
"""Static contracts for scene-authored A1 graybox structure.

Run from the repository root:
    python3 tools/validate_a1_scene_split.py

This is a source-contract check, not a substitute for opening/running Godot 4.6.1.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str, errors: list[str]) -> str:
    path = ROOT / relative
    if not path.is_file():
        errors.append(f"Missing file: {relative}")
        return ""
    return path.read_text(encoding="utf-8")


def require(condition: bool, message: str, errors: list[str]) -> None:
    if not condition:
        errors.append(message)


def require_sized_label(source: str, name: str, owner: str, errors: list[str]) -> None:
    start = source.find(f'[node name="{name}" type="Label"')
    if start < 0:
        errors.append(f"{owner}: missing Label node {name!r}")
        return
    end = source.find("\n[node ", start + 1)
    block = source[start:] if end < 0 else source[start:end]
    if "offset_right = " not in block or "offset_bottom = " not in block:
        errors.append(f"{owner}: Label {name!r} needs explicit width and height")


def check_scene_resources(scene: str, path: str, errors: list[str]) -> None:
    header = re.search(r"^\[gd_scene load_steps=(\d+) format=3\]", scene, re.M)
    if not header:
        errors.append(f"{path}: missing Godot 4 scene header")
        return
    ext_ids = re.findall(r'^\[ext_resource[^\]]* id="([^"]+)"\]', scene, re.M)
    sub_ids = re.findall(r'^\[sub_resource[^\]]* id="([^"]+)"\]', scene, re.M)
    expected = 1 + len(ext_ids) + len(sub_ids)
    require(
        int(header.group(1)) == expected,
        f"{path}: load_steps={header.group(1)} but resources require {expected}",
        errors,
    )
    require(len(ext_ids) == len(set(ext_ids)), f"{path}: duplicate ext_resource ids", errors)
    require(len(sub_ids) == len(set(sub_ids)), f"{path}: duplicate sub_resource ids", errors)
    ext_refs = re.findall(r'ExtResource\("([^"]+)"\)', scene)
    sub_refs = re.findall(r'SubResource\("([^"]+)"\)', scene)
    for resource_id in sorted(set(ext_refs) - set(ext_ids)):
        errors.append(f"{path}: ExtResource({resource_id}) is not declared")
    for resource_id in sorted(set(sub_refs) - set(sub_ids)):
        errors.append(f"{path}: SubResource({resource_id}) is not declared")

    # Ensure every declared node parent path exists in this scene. This is a structural
    # check of the human-editable scene tree, not a Godot parser.
    node_paths: set[str] = set()
    node_records: list[tuple[str, str]] = []
    for match in re.finditer(
        r'^\[node name="([^"]+)"(?: type="[^"]+")? parent="([^"]+)"[^\]]*\]',
        scene,
        re.M,
    ):
        name, parent = match.groups()
        node_path = name if parent == "." else f"{parent}/{name}"
        node_records.append((node_path, parent))
        node_paths.add(node_path)
    for node_path, parent in node_records:
        if parent != "." and parent not in node_paths:
            errors.append(f"{path}: node {node_path!r} has missing parent {parent!r}")


def main() -> int:
    errors: list[str] = []
    a10 = read("scenes/regions/village_hub.tscn", errors)
    a10_script = read("scripts/levels/village_hub.gd", errors)
    a11 = read("scenes/village_backhill.tscn", errors)
    a11_script = read("scripts/levels/village_backhill.gd", errors)
    cliff_scene = read("scenes/cliff_exploration.tscn", errors)
    cliff_script = read("scripts/levels/cliff_exploration.gd", errors)
    smoke_test = read("tools/a1_scene_smoke_test.gd", errors)
    poi_visual = read("scenes/world/village_poi_visual.tscn", errors)
    npc_labels = read("scenes/world/route_npc_labels.tscn", errors)
    interaction_prompt = read("scenes/world/interaction_prompt.tscn", errors)
    rest_visual = read("scenes/world/rest_point_visual.tscn", errors)
    checkpoint_visual = read("scenes/world/checkpoint_visual.tscn", errors)
    fireflies_scene = read("scenes/world/village_fireflies.tscn", errors)
    mite_visual = read("scenes/characters/mite_village_visual.tscn", errors)
    humanoid_visual = read("scenes/characters/humanoid_character_visual.tscn", errors)
    humanoid_script = read("scripts/characters/humanoid_character_visual.gd", errors)
    poi_script = read("scripts/world/village_poi.gd", errors)
    npc_script = read("scripts/npc/route_npc.gd", errors)
    door_script = read("scripts/world/interaction_door.gd", errors)
    rest_script = read("scripts/world/rest_point.gd", errors)
    checkpoint_script = read("scripts/world/checkpoint.gd", errors)
    mite_script = read("scripts/npc/mite.gd", errors)
    fireflies_script = read("scripts/effects/village_fireflies.gd", errors)
    gate_script = read("scripts/world/resonance_secret_gate.gd", errors)

    for scene, path in [
        (a10, "scenes/regions/village_hub.tscn"),
        (a11, "scenes/village_backhill.tscn"),
        (cliff_scene, "scenes/cliff_exploration.tscn"),
        (poi_visual, "scenes/world/village_poi_visual.tscn"),
        (npc_labels, "scenes/world/route_npc_labels.tscn"),
        (interaction_prompt, "scenes/world/interaction_prompt.tscn"),
        (rest_visual, "scenes/world/rest_point_visual.tscn"),
        (checkpoint_visual, "scenes/world/checkpoint_visual.tscn"),
        (fireflies_scene, "scenes/world/village_fireflies.tscn"),
        (mite_visual, "scenes/characters/mite_village_visual.tscn"),
        (humanoid_visual, "scenes/characters/humanoid_character_visual.tscn"),
    ]:
        check_scene_resources(scene, path, errors)
        require(
            'Color("#' not in scene,
            f"{path}: Color values must use numeric serialization in .tscn resources.",
            errors,
        )

    # A1 roots must not paint map geometry or labels from script.
    for script, path in [(a10_script, "village_hub.gd"), (a11_script, "village_backhill.gd")]:
        require("func _draw() -> void:" not in script, f"{path}: map-root _draw() must be removed", errors)
        require(
            not re.search(r"\bdraw_(?:rect|string|circle|line|arc|texture_rect|colored_polygon|polyline)\s*\(", script),
            f"{path}: draw_* call remains in a map root",
            errors,
        )
    for script, path in [
        (poi_script, "village_poi.gd"),
        (npc_script, "route_npc.gd"),
        (door_script, "interaction_door.gd"),
        (rest_script, "rest_point.gd"),
        (checkpoint_script, "checkpoint.gd"),
        (mite_script, "mite.gd"),
        (fireflies_script, "village_fireflies.gd"),
        (humanoid_script, "humanoid_character_visual.gd"),
    ]:
        require("func _draw() -> void:" not in script, f"{path}: visual draw method remains", errors)

    require(
        all(f'[node name="Firefly{i:02d}" type="Polygon2D" parent="."]' in fireflies_scene for i in range(1, 27)),
        "Fireflies must be 26 scene-authored Polygon2D nodes.",
        errors,
    )
    require(".new()" not in fireflies_script, "Fireflies must not construct visual nodes in code", errors)

    for name in ["RegionTitle", "DrainLabel", "GraveyardLabel", "OldHouseLabel", "CampLabel", "NorthGateLabel", "PromptLabel", "StatusLabel"]:
        require_sized_label(a10, name, "A1.0", errors)
    for name in ["ChurchTitle", "TavernTitle", "BackhillTitle", "CliffEntryTitle", "FutureA2Title"]:
        require_sized_label(a11, name, "A1.1", errors)
    for source, names, owner in [
        (poi_visual, ["PromptLabel"], "POI visual"),
        (npc_labels, ["NameLabel", "PromptLabel"], "NPC labels"),
        (interaction_prompt, ["PromptLabel"], "interaction prompt"),
        (rest_visual, ["RestNameLabel", "PromptLabel"], "rest point visual"),
        (checkpoint_visual, ["TitleLabel"], "checkpoint visual"),
        (mite_visual, ["NameLabel", "PromptLabel"], "Mite visual"),
    ]:
        for name in names:
            require_sized_label(source, name, owner, errors)

    # A1.0: scene-authored architecture, traversable terrain and persistent interaction anchors.
    for needle, label in [
        ('[node name="Hero" type="CharacterBody2D" parent="."]', "Hero"),
        ('[node name="VillageCheckpoint" type="Area2D" parent="."]', "checkpoint"),
        ('[node name="VillageHearthRestPoint" type="Node2D" parent="."]', "hearth rest point"),
        ('[node name="MiteHouseDoor" type="Area2D" parent="."]', "Mite house door"),
        ('[node name="Mite" type="Node2D" parent="."]', "Mite"),
        ('[node name="Gatekeeper" type="Node2D" parent="."]', "gatekeeper"),
        ('[node name="Grandmother" type="Node2D" parent="."]', "grandmother"),
        ('[node name="BlacksmithNPC" type="Node2D" parent="."]', "blacksmith NPC"),
        ('[node name="TravelingMerchant" type="Node2D" parent="."]', "merchant NPC"),
        ('[node name="GraveyardPOI" type="Node2D" parent="."]', "graveyard POI"),
        ('[node name="RestorationCampPOI" type="Node2D" parent="."]', "camp POI"),
        ('[node name="NorthGatePOI" type="Node2D" parent="."]', "north gate POI"),
        ('[node name="CityCutPOI" type="Node2D" parent="."]', "old drain POI"),
        ('[node name="ResonanceWellGate" type="Node2D" parent="."]', "H01 well gate"),
        ('[node name="DrainEntranceVisual" type="Node2D" parent="."]', "drain entrance visuals"),
        ('[node name="CampVisual" type="Node2D" parent="."]', "camp visuals"),
        ('[node name="NorthGateVisual" type="Node2D" parent="."]', "north gate state visuals"),
        ('[node name="WorldEventDirector" type="Node" parent="."]', "authored world event director"),
        ('[node name="NarrativeAudio" type="Node" parent="."]', "authored narrative audio node"),
        ('[node name="VillageFireflies" parent="." instance=ExtResource("19")]', "authored firefly scene"),
        ('[node name="BackhillEntrance" type="Node2D" parent="."]', "A1.1 entrance"),
        ('[node name="BackdropVisual" type="TextureRect" parent="."]', "authored backdrop"),
        ('[node name="GroundStripVisual" type="TextureRect" parent="."]', "authored ground strip"),
        ('[node name="GroundMain" type="StaticBody2D" parent="Terrain"]', "continuous main-ground collider"),
        ('[node name="CollisionShape2D" type="CollisionShape2D" parent="Terrain/GroundMain"]', "continuous main-ground collision shape"),
        ('[node name="BlockedState" type="Node2D" parent="NorthGateVisual"]', "blocked gate state"),
        ('[node name="RepairedState" type="Node2D" parent="NorthGateVisual"]', "repaired gate state"),
        ('[node name="RubbleState" type="Node2D" parent="DrainEntranceVisual"]', "drain rubble state"),
        ('[node name="AuthoredVisual" type="Node2D" parent="ResonanceWellGate"]', "H01 authored marker"),
        ('[node name="RevealedState" type="Node2D" parent="ResonanceWellGate/AuthoredVisual"]', "H01 revealed state"),
        ('[node name="OpenedState" type="Node2D" parent="ResonanceWellGate/AuthoredVisual"]', "H01 opened state"),
        ('[node name="PromptLabel" type="Label" parent="ResonanceWellGate"]', "H01 prompt"),
        ('[node name="StatusLabel" type="Label" parent="ResonanceWellGate"]', "H01 discovered status"),
    ]:
        require(needle in a10, f"A1.0 scene missing {label}: {needle}", errors)

    # The blacksmith-side drop was an unused greybox artifact, not a sewer connection.
    require(
        'size = Vector2(3000, 40)' in a10
        and 'position = Vector2(1500, 20)' in a10
        and 'shape = SubResource("GroundMain")' in a10,
        "A1.0 main ground must remain continuous across the former blacksmith-side drop.",
        errors,
    )
    for obsolete_node in [
        '[node name="GroundCutouts" type="Node2D" parent="."]',
        '[node name="WestPit" type="Polygon2D" parent="GroundCutouts"]',
        '[node name="EastPit" type="Polygon2D" parent="GroundCutouts"]',
        '[node name="LowerRouteVisuals" type="Node2D" parent="."]',
        '[node name="LowerLedge1" type="Polygon2D" parent="LowerRouteVisuals"]',
        '[node name="LowerLedge2" type="Polygon2D" parent="LowerRouteVisuals"]',
        '[node name="LowerLedge3" type="Polygon2D" parent="LowerRouteVisuals"]',
        '[node name="LowerRouteWest" type="StaticBody2D" parent="Terrain"]',
        '[node name="LowerRouteMiddle" type="StaticBody2D" parent="Terrain"]',
        '[node name="LowerRouteEast" type="StaticBody2D" parent="Terrain"]',
    ]:
        require(obsolete_node not in a10, f"A1.0 unused drop terrain returned: {obsolete_node}", errors)

    # Required reusable scene instances are direct children of their authored anchors.
    for needle, label in [
        ('[node name="CheckpointVisual" parent="VillageCheckpoint" instance=ExtResource("18")]', "checkpoint visual"),
        ('[node name="RestVisual" parent="VillageHearthRestPoint" instance=ExtResource("13")]', "rest point visual"),
        ('[node name="Prompt" parent="MiteHouseDoor" instance=ExtResource("14")]', "Mite door prompt"),
        ('[node name="POIVisual" parent="BackhillEntrance" instance=ExtResource("15")]', "backhill entrance marker"),
        ('[node name="POIVisual" parent="GraveyardPOI" instance=ExtResource("15")]', "graveyard marker"),
        ('[node name="POIVisual" parent="NorthGatePOI" instance=ExtResource("15")]', "north gate marker"),
        ('[node name="POIVisual" parent="CityCutPOI" instance=ExtResource("15")]', "drain POI marker"),
        ('[node name="CharacterVisual" parent="Gatekeeper" instance=ExtResource("17")]', "gatekeeper rig"),
        ('[node name="CharacterVisual" parent="Grandmother" instance=ExtResource("17")]', "grandmother rig"),
        ('[node name="CharacterVisual" parent="BlacksmithNPC" instance=ExtResource("17")]', "blacksmith rig"),
        ('[node name="CharacterVisual" parent="TravelingMerchant" instance=ExtResource("17")]', "merchant rig"),
    ]:
        require(needle in a10, f"A1.0 authored scene instance missing {label}", errors)
    for parent in ["MiteAbsence", "RestorationCampPOI"]:
        require(f'[node name="POIVisual" parent="{parent}" instance=ExtResource("15")]' in a10,
                f"A1.0 authored POI visual missing beneath {parent}", errors)
    for parent in ["Gatekeeper", "Grandmother", "BlacksmithNPC", "TravelingMerchant"]:
        require(f'[node name="Labels" parent="{parent}" instance=ExtResource("16")]' in a10,
                f"A1.0 authored NPC labels missing beneath {parent}", errors)

    # A1.1 is a walkable hub; cliff traversal is a separate authored scene.
    for needle, label in [
        ('[node name="WorldEventDirector" type="Node" parent="."]', "event director"),
        ('[node name="Hero" type="CharacterBody2D" parent="."]', "Hero"),
        ('[node name="CliffExplorationDoor" type="Area2D" parent="."]', "left cliff exploration entrance"),
        ('[node name="CliffEntryVisual" type="Node2D" parent="."]', "scene-authored cliff entrance visual"),
        ('[node name="FutureA2RoadDoor" type="Area2D" parent="."]', "right reserved A2 entrance"),
        ('[node name="FutureA2RoadBlocker" type="StaticBody2D" parent="."]', "right reserved A2 route physical blocker"),
        ('[node name="CollisionShape2D" type="CollisionShape2D" parent="FutureA2RoadBlocker"]', "full-height blocker collider"),
        ('[node name="FutureA2EntranceVisual" type="Node2D" parent="."]', "scene-authored sealed A2 entrance"),
        ('[node name="FutureA2Title" type="Label" parent="."]', "A2 entrance label"),
        ('[node name="ChurchPOI" type="Node2D" parent="."]', "church POI"),
        ('[node name="TavernPOI" type="Node2D" parent="."]', "tavern POI"),
        ('[node name="BackToVillagePOI" type="Node2D" parent="."]', "return POI"),
        ('[node name="ChurchTitle" type="Label" parent="."]', "church title"),
        ('[node name="TavernTitle" type="Label" parent="."]', "tavern title"),
        ('[node name="BackhillTitle" type="Label" parent="."]', "backhill title"),
        ('[node name="CliffEntryTitle" type="Label" parent="."]', "cliff-entry title"),
        ('[node name="POIVisual" parent="ChurchPOI" instance=ExtResource("6")]', "church marker"),
        ('[node name="POIVisual" parent="TavernPOI" instance=ExtResource("6")]', "tavern marker"),
        ('[node name="POIVisual" parent="BackToVillagePOI" instance=ExtResource("6")]', "return marker"),
        ('[node name="Prompt" parent="CliffExplorationDoor" instance=ExtResource("7")]', "cliff entrance prompt"),
    ]:
        require(needle in a11, f"A1.1 scene missing {label}: {needle}", errors)
    require('groups = ["a1_tavern_poi"]' in a11, "A1.1 tavern POI group was removed", errors)
    for obsolete in ["BackhillStairs", "RidgePlatform01", "RidgePlatform02", "RidgePlatform03", "CliffLookout", "CliffLowerShelf", "CliffCaveDoor"]:
        require(f'name="{obsolete}"' not in a11, f"A1.1 still contains jump-platform/cliff-cave content: {obsolete}", errors)

    # The cliff is a separate scene with continuous walkable ground; the A2 reserve is at the backhill.
    for needle, label in [
        ('[node name="CliffExploration" type="Node2D"]', "scene root"),
        ('[node name="Hero" type="CharacterBody2D" parent="."]', "Hero"),
        ('[node name="MainGround" type="StaticBody2D" parent="."]', "continuous walkable ground"),
        ('[node name="BackToBackhillDoor" type="Area2D" parent="."]', "left return connection"),
        ('[node name="CliffEndBoundary" type="StaticBody2D" parent="."]', "physical east-end boundary"),
        ('[node name="H09CaveDoor" type="Area2D" parent="."]', "H09 door"),
        ('[node name="H09CaveVisual" type="Node2D" parent="."]', "H09 authored cave mouth"),
    ]:
        require(needle in cliff_scene, f"Cliff exploration scene missing {label}", errors)
    require("size = Vector2(2400, 40)" in cliff_scene, "Cliff exploration must use continuous ground, not jump platforms", errors)
    require("FutureA2RoadDoor" not in cliff_scene and "FutureRoadBlocker" not in cliff_scene,
            "The reserved A2 connection must remain at the backhill, not the cliff scene", errors)
    require("enabled = false" in a11, "The future A2 entrance must start disabled in the backhill scene", errors)
    require("size = Vector2(60, 720)" in a11 and 'shape = SubResource("FutureA2BlockerShape")' in a11 and 'position = Vector2(0, -340)' in a11,
            "The right-hand future A2 route must use a full-height physical blocker", errors)
    require('const CLIFF_EXPLORATION_SCENE := "res://scenes/cliff_exploration.tscn"' in a11_script
            and 'SceneTransition.fade_to_scene(CLIFF_EXPLORATION_SCENE)' in a11_script,
            "A1.1 cliff entrance does not transition to the separate exploration scene", errors)

    # Shared visual prefabs and scripts must expose scene-driven labels/state.
    for src, needle, label in [
        (poi_visual, '[node name="PromptLabel" type="Label" parent="."]', "POI prompt"),
        (npc_labels, '[node name="NameLabel" type="Label" parent="."]', "NPC name"),
        (interaction_prompt, '[node name="PromptLabel" type="Label" parent="."]', "door prompt"),
        (rest_visual, '[node name="RestNameLabel" type="Label" parent="."]', "rest label"),
        (checkpoint_visual, '[node name="InactiveState" type="Node2D" parent="."]', "checkpoint state"),
        (checkpoint_visual, '[node name="ActiveState" type="Node2D" parent="."]', "active checkpoint state"),
        (mite_visual, '[node name="CharacterVisual" parent="." instance=ExtResource("1")]', "Mite rig"),
        (humanoid_visual, '[node name="Skeleton2D" type="Skeleton2D" parent="."]', "serialized skeleton"),
        (humanoid_visual, '[node name="RootBone" type="Bone2D" parent="Skeleton2D"]', "rig root bone"),
    ]:
        require(needle in src, f"{label}: required node missing", errors)

    # Root scripts only wire state, signals and transitions; no visible drawing or map node factory.
    for method in ["_spawn_hero(", "_spawn_checkpoint(", "_spawn_village_rest_point(", "_spawn_mite(", "_spawn_mite_house_door(", "_spawn_gatekeeper(", "_spawn_shared_world_npcs(", "func _spawn_village_pois(", "func _spawn_resonance_well_gate("]:
        require(method not in a10_script, f"A1.0 script still constructs fixed map content: {method}", errors)
    for needle, label in [
        ('$DrainEntranceVisual/RubbleState.visible = not defense_survived', "drainage rubble story state"),
        ('$NorthGateVisual/BlockedState.visible = not defense_survived', "blocked gate story state"),
        ('$NorthGateVisual/RepairedState.visible = defense_survived', "repaired gate story state"),
        ('$CampVisual.visible = camp_established', "camp visual explicit arrival gate"),
        ('$RestorationCampPOI.visible = camp_established', "camp POI explicit arrival gate"),
        ('resonance_well_gate.secret_id = "H01"', "H01 identity"),
        ('resonance_well_gate.target_scene_path = "res://scenes/hidden_well.tscn"', "H01 destination"),
        ('WorldState.pending_region_spawn_side = "backhill_return"', "A1.1 return spawn contract"),
        ('SceneTransition.fade_to_scene("res://scenes/village_backhill.tscn")', "A1.0 to A1.1 transition"),
    ]:
        require(needle in a10_script, f"A1.0 root contract missing {label}", errors)
    require('returned_to_village_after_mad_cleric' in cliff_script, "H09 return-after-boss gate missing", errors)
    require('WorldState.discover_hidden_region("H09")' in cliff_script, "H09 discovery contract missing", errors)
    require('WorldState.open_hidden_path("H09")' in cliff_script, "H09 open-path contract missing", errors)
    require('SceneTransition.fade_to_scene(CLIFF_CAVE_SCENE)' in cliff_script, "H09 destination contract missing", errors)
    require('world_event_director.dispatch("interaction", {"region": "A1", "interaction_id": String(poi.poi_id)' in a11_script,
            "A1.1 tavern interaction event hook missing", errors)
    require('A1_tavern_sound_notice' in read("scripts/core/world_event_director.gd", errors),
            "Persistent tavern one-time event is missing", errors)
    require("屋顶捷径" not in a10_script and "rooftop_waybill" not in a10_script,
            "Retired rooftop route/reward returned", errors)
    require("func _build_rig() -> void:" not in humanoid_script and ".new()" not in humanoid_script,
            "Humanoid rig is still procedurally built instead of authored in scene", errors)
    require(
        'if secret_id == "H01" and has_node("AuthoredVisual"):' in gate_script
        and 'if secret_id == "H01" and region_record_id not in WorldState.discovered_hidden_regions:' in gate_script
        and 'WorldState.discover_hidden_region(region_record_id)' in gate_script,
        "H01 authored visuals or discovery/open state contract is missing",
        errors,
    )

    require(
        "WorldState.debug_map_test_mode = true" in smoke_test
        and "WorldState.debug_map_test_mode = original_debug_map_test_mode" in smoke_test,
        "A1 headless smoke test must suppress and restore save writes.",
        errors,
    )
    for needle, label in [
        ('func _test_spawn_side_matrix() -> void:', "spawn-side matrix test"),
        ('{"side": "backhill_return", "x": 2420.0}', "backhill return spawn"),
        ('{"side": "well_exit", "x": 1850.0}', "well exit spawn"),
        ('{"side": "cliff_cave_return", "x": 1850.0}', "cliff-cave return spawn"),
        ('{"side": "city_cut_return", "x": 350.0}', "drain return spawn"),
        ('{"side": "north_gate", "x": 2630.0}', "north-gate return spawn"),
        ('{"side": "mite_house_return", "x": 530.0}', "Mite-house return spawn"),
        ('func _test_a11_authored_terrain() -> void:', "A1.1 terrain smoke test"),
        ('func _test_cliff_exploration() -> void:', "standalone cliff exploration smoke test"),
        ('A1.1 right route is reserved and disabled until A2 is designed', "reserved future route lock test"),
        ('H01 discovery status uses its authored Label', "H01 discovered-status Label check"),
        ('H01 discovery prompt clears after permanent opening', "H01 permanent-open status check"),
    ]:
        require(needle in smoke_test, f"A1 headless smoke test missing {label}", errors)

    if errors:
        print("A1 SCENE-AUTHORED STATIC CHECK FAILED")
        for error in errors:
            print(f" - {error}")
        return 1

    print("A1 SCENE-AUTHORED STATIC CHECK PASSED")
    print(" - Both A1 map roots have no draw-based map rendering.")
    print(" - Static architecture, route surfaces, interactors, labels, NPC rigs and H01/H09 states are scene-authored.")
    print(" - Scene resources, node parents, and resource references are structurally consistent.")
    print(" - Route and story flags for C01/C02/C06/H01/C24/H09 are preserved.")
    print("NOTE: This static check does not replace Godot 4.6.1 parser and runtime acceptance.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
