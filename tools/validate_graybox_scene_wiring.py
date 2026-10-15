#!/usr/bin/env python3
"""Static wiring checks for the A0-A13 graybox, H01-H08, and world-map route contracts.

This script checks file references and save/transition contracts. It does not
replace Godot runtime tests for collision, interaction focus, or scene changes.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REGIONS = {
    "A2": ("scenes/ash_forest.tscn", "ash_forest", "THE OLD PILGRIM ROAD"),
    "A3": ("scenes/forgotten_city.tscn", "forgotten_city", "THE FORGOTTEN CITY"),
    "A4": ("scenes/sewer_reservoir.tscn", "sewer_reservoir", "THE SEDIMENT HALL"),
    "A5": ("scenes/old_battlefield.tscn", "old_battlefield", "THE BORDER BATTLEFIELD"),
    "A6": ("scenes/monastery_tower.tscn", "monastery_tower", "THE MONASTERY THAT KEPT ITS BELL"),
    "A7": ("scenes/prison_depths.tscn", "prison_depths", "THE PENITENTIAL DEPTHS"),
    "A8": ("scenes/royal_tomb.tscn", "royal_tomb", "THE ROYAL TOMB"),
    "A9": ("scenes/royal_outer_ring.tscn", "royal_outer_ring", "THE ROYAL OUTER RING"),
    "A10": ("scenes/grand_cathedral.tscn", "grand_cathedral", "THE GREAT CATHEDRAL"),
    "A12": ("scenes/inner_city.tscn", "inner_city", "THE INNER CITY"),
    "A13": ("scenes/terminal_anomaly.tscn", "terminal_anomaly", "THE DEEP DREAM AND FINAL ANOMALY"),
    "A11": ("scenes/deep_research_depths.tscn", "deep_research_depths", "THE DEPTHS THAT PRECEDED THE LAB"),
    "H08": ("scenes/primordial_hollow.tscn", "primordial_hollow", "THE WOMB BELOW THE LAB"),
    "H07": ("scenes/mirror_street.tscn", "mirror_street", "MIRROR STREET: BEHIND THE RAIN"),
    "H01": ("scenes/hidden_well.tscn", "hidden_well", "THE WELL BELOW THE WELL"),
    "H02": ("scenes/hidden_bell_chamber.tscn", "hidden_bell_chamber", "THE BELL BEFORE THE SOUND"),
    "H03": ("scenes/erased_third_street.tscn", "erased_third_street", "THE STREET THE CITY REMOVED"),
    "H04": ("scenes/reflected_stairwell.tscn", "reflected_stairwell", "THE STAIRS BEHIND THE WATER"),
    "H05": ("scenes/silent_bell_room.tscn", "silent_bell_room", "THE WINDOW THAT CASTS NO SHADOW"),
    "H06": ("scenes/erased_royal_name_corridor.tscn", "erased_royal_name_corridor", "THE NAME SCRAPED FROM STONE"),
}

REQUIRED_FILES = [
    "scripts/levels/greybox_world_region.gd",
    "scripts/levels/escape_prologue.gd",
    "scripts/levels/village_hub.gd",
    "scripts/levels/village_defense_demo.gd",
    "scripts/world/resonance_source_clue.gd",
    "scripts/world/resonance_secret_gate.gd",
    "scripts/world/interaction_door.gd",
    "scripts/world/resonance_local_route.gd",
    "scripts/world/rest_point.gd",
    "scripts/world/world_clue.gd",
    "scripts/world/checkpoint.gd",
    "scripts/world/village_poi.gd",
    "scripts/core/world_state.gd",
    "scripts/core/boot.gd",
    "scripts/core/world_map_test_menu.gd",
    "scripts/core/narrative_manager.gd",
    "scripts/player/hero.gd",
    "scripts/enemies/experiment_warden.gd",
    "scripts/npc/route_npc.gd",
    "scripts/npc/mite.gd",
    "scripts/audio/narrative_audio.gd",
    "scripts/effects/village_fireflies.gd",
    "scripts/effects/region_ambience.gd",
]

ART_ASSETS = [
    "assets/art/backdrops/forest_backdrop.svg",
    "assets/art/backdrops/ruins_backdrop.svg",
    "assets/art/backdrops/church_backdrop.svg",
    "assets/art/backdrops/eldritch_backdrop.svg",
    "assets/art/backdrops/stone_floor_strip.svg",
    "assets/art/backdrops/surgery_ward_backdrop.svg",
    "assets/art/backdrops/surgery_floor_strip.svg",
    "assets/art/backdrops/village_backdrop.svg",
    "assets/art/backdrops/village_ground_strip.svg",
]

REQUIRED_ENTRY_SCENES = [
    "scenes/boot.tscn",
    "scenes/world_map_test_menu.tscn",
    "scenes/escape_prologue.tscn",
    "scenes/village_hub.tscn",
]


def read(relative_path: str, errors: list[str]) -> str:
    path = ROOT / relative_path
    if not path.is_file():
        errors.append(f"Missing file: {relative_path}")
        return ""
    return path.read_text(encoding="utf-8")


def require(text: str, needle: str, source: str, errors: list[str]) -> None:
    if needle not in text:
        errors.append(f"{source}: missing required contract {needle!r}")


def fail(errors: list[str], message: str) -> None:
    """Append a focused static-contract failure without raising immediately."""
    errors.append(message)


def main() -> int:
    errors: list[str] = []
    # Load the shared controller before topology checks that inspect its clue wiring.
    # 拓扑检查会读取共享控制器中的线索 ID，因此必须先加载，避免局部变量尚未赋值。
    region_script = read("scripts/levels/greybox_world_region.gd", errors)
    platform_audit_regions = 0
    platform_audit_count = 0
    local_route_count = 0
    platforms_by_region: dict[str, list[tuple[float, float, float, float]]] = {}

    # The topology metadata must agree with the playable C10 shortcut.
    # 世界拓扑元数据必须与实际可玩的 C10 钟塔捷径保持一致。
    topology_path = ROOT / "tools/world_map_topology.json"
    if not topology_path.is_file():
        errors.append("Missing file: tools/world_map_topology.json")
    else:
        try:
            topology = json.loads(topology_path.read_text(encoding="utf-8"))
            hidden_regions = topology.get("hidden_regions", [])
            h05 = next((region for region in hidden_regions if region.get("id") == "H05"), None)
            if h05 is None or h05.get("secondary_exit", {}).get("requires_target_already_reached") is not True:
                errors.append("Topology H05/C10 contract must record A3 as already reached before the shortcut.")
            h01 = next((region for region in hidden_regions if region.get("id") == "H01"), None)
            h01_exit = h01.get("secondary_exit", {}) if h01 else {}
            if h01_exit.get("unlock_condition") != "reached_A4_via_A3_and_H01_opened_from_either_side":
                errors.append("Topology H01 return contract must match the shared persistent gate state used by runtime.")
            if h01_exit.get("opens_from") != "A4" or h01_exit.get("to") != "A4":
                errors.append("Topology H01 secondary exit must remain the A4-side return through the well gate.")
            h06 = next((region for region in hidden_regions if region.get("id") == "H06"), None)
            if h06 and set(h06.get("required_source_ids", [])) != {"anomaly_bell_retiming", "anomaly_erased_royal_name"}:
                errors.append("Topology H06 must require the bell-retiming and royal-inscription clues.")
            if '"anomaly_erased_royal_name"' not in region_script or '"anomaly_erased_street_sign"' not in region_script:
                errors.append("Runtime must keep H06 tied to the royal inscription while the erased-street clue remains a separate source.")
            h08 = next((region for region in hidden_regions if region.get("id") == "H08"), None)
            h08_exit = h08.get("secondary_exit", {}) if h08 else {}
            if h08_exit.get("unlock_condition") != "physical_union_complete_then_enter_A13_terminal_layer":
                errors.append("Topology H08 exit must converge on A13 after physical union rather than skip the terminal layer.")
            c21 = next((edge for edge in topology.get("connections", []) if edge.get("id") == "C21"), None)
            c22 = next((edge for edge in topology.get("connections", []) if edge.get("id") == "C22"), None)
            if not c21 or c21.get("unlock_condition") != "physical_union_complete" or c21.get("to") != "A13":
                errors.append("C21 must gate the A11 deep-dream entrance on physical_union_complete.")
            if not c22 or c22.get("initial_access") != "from_to" or c22.get("unlock_condition") != "reached_A12_via_A10" or c22.get("to") != "A13":
                errors.append("C22 must route the main A12 path into A13 after reaching the inner city.")
            regions = topology.get("regions", [])
            region_ids = [region.get("id") for region in regions]
            if len(region_ids) != len(set(region_ids)):
                errors.append("World map topology contains duplicate region IDs.")
            region_id_set = set(region_ids)

            primary_route = topology.get("primary_route", [])
            for region_id in primary_route:
                if region_id not in region_id_set:
                    errors.append(f"Primary route references unknown region: {region_id}")

            connections = topology.get("connections", [])
            # Check that the reliable main route is actually traversable in its intended direction
            # before any shortcuts or secret gates are unlocked.
            # 检查玩家不依赖捷径或隐藏门时，仍能沿设计方向走通可靠主线。
            if primary_route and all(region_id in region_id_set for region_id in primary_route):
                initially_reachable = {primary_route[0]}
                changed = True
                while changed:
                    changed = False
                    for connection in connections:
                        access = connection.get("initial_access", "")
                        source = connection.get("from")
                        target = connection.get("to")
                        if access in ("from_to", "both") and source in initially_reachable and target not in initially_reachable:
                            initially_reachable.add(target)
                            changed = True
                        if access == "both" and target in initially_reachable and source not in initially_reachable:
                            initially_reachable.add(source)
                            changed = True
                unreachable_route_regions = [
                    region_id for region_id in primary_route if region_id not in initially_reachable
                ]
                if unreachable_route_regions:
                    errors.append(
                        "Primary route is not initially traversable from its start: "
                        f"{unreachable_route_regions}"
                    )

            # Every documented loop must be a closed region path with an actual connection for
            # each adjacent pair; the path is topology QA, not a claim of runtime traversal.
            # 每条环路必须首尾闭合，且每一对相邻区域都存在对应拓扑连线。
            for loop in topology.get("loops", []):
                path = loop.get("path", [])
                if len(path) < 3 or path[0] != path[-1]:
                    errors.append(f"Loop {loop.get('id', '<missing>')} is not a closed path.")
                    continue
                for source, target in zip(path, path[1:]):
                    linked = any(
                        {connection.get("from"), connection.get("to")} == {source, target}
                        for connection in connections
                    )
                    if not linked:
                        errors.append(
                            f"Loop {loop.get('id', '<missing>')} has no connection between {source} and {target}."
                        )

            connection_ids = [connection.get("id") for connection in connections]
            if len(connection_ids) != len(set(connection_ids)):
                errors.append("World map topology contains duplicate connection IDs.")
            for connection in connections:
                connection_id = connection.get("id", "<missing>")
                for endpoint_key in ("from", "to"):
                    endpoint = connection.get(endpoint_key)
                    if endpoint not in region_id_set:
                        errors.append(f"Connection {connection_id} references unknown {endpoint_key} region: {endpoint}")

            loops = topology.get("loops", [])
            loop_ids = [loop.get("id") for loop in loops]
            if len(loop_ids) != len(set(loop_ids)):
                errors.append("World map topology contains duplicate loop IDs.")
            for loop in loops:
                for region_id in loop.get("path", []):
                    if region_id not in region_id_set:
                        errors.append(f"Loop {loop.get('id', '<missing>')} references unknown region: {region_id}")

            hidden_ids = [region.get("id") for region in hidden_regions]
            if len(hidden_ids) != len(set(hidden_ids)):
                errors.append("World map topology contains duplicate hidden-region IDs.")
            for hidden in hidden_regions:
                hidden_id = hidden.get("id", "<missing>")
                if hidden.get("parent") not in region_id_set:
                    errors.append(f"Hidden region {hidden_id} references unknown parent: {hidden.get('parent')}")
                scene_path = hidden.get("scene_path", "")
                if scene_path and not (ROOT / scene_path).is_file():
                    errors.append(f"Hidden region {hidden_id} scene does not exist: {scene_path}")
        except (json.JSONDecodeError, OSError) as exc:
            errors.append(f"World map topology cannot be parsed: {exc}")

    for relative_path in REQUIRED_FILES:
        read(relative_path, errors)
    for relative_path in REQUIRED_ENTRY_SCENES:
        read(relative_path, errors)

    # Audit direct scene targets used by the startup, prologue, hub, and regional controller.
    # 检查启动、序章、村庄据点与区域控制器直接引用的所有场景路径。
    for source_path in (
        "scripts/core/boot.gd",
        "scripts/levels/escape_prologue.gd",
        "scripts/levels/village_hub.gd",
        "scripts/levels/greybox_world_region.gd",
    ):
        source_text = read(source_path, errors)
        for scene_path in set(re.findall(r'"res://(scenes/[^"]+\.tscn)"', source_text)):
            if not (ROOT / scene_path).is_file():
                errors.append(f"Scene reference in {source_path} does not exist: {scene_path}")

    interaction_focus = read("scripts/core/interaction_focus.gd", errors)
    if interaction_focus.count("WorldState.menu_input_locked") < 2:
        errors.append(
            "Interaction focus must block world interactions while menu_input_locked is active."
        )

    secret_gate = read("scripts/world/resonance_secret_gate.gd", errors)
    require(secret_gate, "func _is_debug_override_active()", "Resonance secret gate", errors)
    require(secret_gate, "allow_debug_override: bool = true", "Resonance secret gate", errors)
    require(secret_gate, "_is_debug_override_active()", "Resonance secret gate", errors)
    require(secret_gate, "[NEREIS][MAP][GATE] id=%s revealed=%s", "Gate Debug log", errors)
    require(secret_gate, "[NEREIS][MAP][GATE] enter id=%s", "Gate transition log", errors)

    world_state = read("scripts/core/world_state.gd", errors)
    require(world_state, "var debug_ability_override_active := false", "WorldState", errors)
    require(world_state, '"resume_spawn_side": resume_spawn_side', "WorldState save payload", errors)
    require(world_state, 'resume_spawn_side = str(parsed.get("resume_spawn_side", "west"))', "WorldState save migration", errors)
    require(world_state, '"res://scenes/terminal_anomaly.tscn": "A13"', "Natural map test A13 tracking", errors)
    require(world_state, "[%d/22]", "Natural map test region total", errors)
    require(world_state, 'resume_spawn_side = requested_spawn_side', "WorldState location save", errors)
    require(world_state, 'resume_spawn_side.length() > 64', "WorldState spawn-side input guard", errors)
    require(world_state, "pending_region_spawn_side = \"west\"\n    resume_spawn_side = \"west\"", "WorldState new-game reset", errors)
    boot_script = read("scripts/core/boot.gd", errors)
    require(boot_script, "WorldState.pending_region_spawn_side = WorldState.resume_spawn_side", "Continue spawn restore", errors)
    require(boot_script, "res://scenes/world_map_test_menu.tscn", "Boot macro-map acceptance entry", errors)
    map_test_script = read("scripts/core/world_map_test_menu.gd", errors)
    require(map_test_script, "WorldState.begin_natural_test_session()", "Macro-map visit tracking", errors)
    require(map_test_script, "WorldState.physical_union_complete = true", "Macro-map route test flags", errors)
    require(map_test_script, "res://scenes/terminal_anomaly.tscn", "A13 acceptance destination", errors)
    require(map_test_script, "res://scenes/primordial_hollow.tscn", "H08 acceptance destination", errors)
    require(map_test_script, "WorldState.debug_map_test_mode = true", "Save-safe macro-map test mode", errors)
    region_spawn_script = read("scripts/levels/greybox_world_region.gd", errors)
    require(region_spawn_script, "KEY_F6", "Macro-map launcher return shortcut", errors)
    require(region_spawn_script, "WorldState.set_location(location_id)\n    WorldState.pending_region_spawn_side = \"west\"", "Graybox spawn-side save order", errors)
    hero_script = read("scripts/player/hero.gd", errors)
    require(hero_script, "WorldState.debug_ability_override_active = enabled", "Hero Debug toggle", errors)
    require(hero_script, "debug_ability_override = WorldState.debug_ability_override_active", "Hero scene re-entry", errors)
    for method in [
        "func record_resonance_milestone(",
        "ancient_exposure_floor: int = 0",
        "outer_exposure_floor: int = 0",
        "func discover_hidden_region(",
        "func open_hidden_path(",
        "func mark_hidden_region_entered(",
        "func is_hidden_path_opened(",
        'var exposure_target := 18 if "anomaly_observer_reaction" in resonance_sources else 12',
        '"discovered_hidden_regions": discovered_hidden_regions',
        '"opened_hidden_paths": opened_hidden_paths',
        '"entered_hidden_regions": entered_hidden_regions',
    ]:
        require(world_state, method, "WorldState", errors)

    for _region_id, (scene_path, location_id, title) in REGIONS.items():
        scene = read(scene_path, errors)
        require(scene, 'path="res://scripts/levels/greybox_world_region.gd"', scene_path, errors)
        require(scene, f'region_id = "{_region_id}"', scene_path, errors)
        require(scene, f'location_id = "{location_id}"', scene_path, errors)
        require(scene, f'region_title = "{title}"', scene_path, errors)
        require(world_state, f'"{location_id}":', "WorldState resume mapping", errors)
        require(world_state, f'res://{scene_path}', "WorldState resume mapping", errors)

    prologue_script = read("scripts/levels/escape_prologue.gd", errors)
    require(prologue_script, "func _create_surgical_catwalks() -> void:", "A0 surgical catwalk builder", errors)
    require(prologue_script, "Rect2(430, 455, 100, 16)", "A0 surgical first ledge", errors)
    require(prologue_script, "MAINTENANCE ACCESS ONLY", "A0 catwalk landmark", errors)
    require(prologue_script, "Cold surgical shafts and suspended cables", "A0 environmental lighting layer", errors)
    require(prologue_script, "Sparse surgical floor seams", "A0 floor material layer", errors)

    # Visual polish helpers are part of the shared graybox renderer and must remain wired.
    # 共享灰盒渲染器的美术层函数必须保持接入，避免后续重构时悄然退回纯色背景。
    require(region_script, "_draw_atmospheric_layers()", "Regional atmosphere render call", errors)
    require(region_script, "func _draw_atmospheric_layers() -> void:", "Regional silhouette layer", errors)
    require(region_script, 'func _draw_terminal_anomaly_landmarks() -> void:', "A13 terminal environment landmark", errors)
    require(region_script, "func _draw_ground_detail() -> void:", "Ground surface detail layer", errors)
    require(region_script, 'const REGION_AMBIENCE_SCRIPT = preload("res://scripts/effects/region_ambience.gd")', "Regional ambience script preload", errors)
    require(region_script, "func _spawn_region_ambience() -> void:", "Regional ambience setup", errors)
    require(region_script, 'ambience.set("atmosphere_color", _atmosphere_color())', "Regional ambience palette binding", errors)
    require(region_script, "Broken paving seams and small rubble clusters", "Ground material treatment", errors)
    # Original SVG art must be present and wired into the shared renderer.
    # 原创 SVG 美术资源必须存在，并由共享渲染器实际调用。
    for art_path in ART_ASSETS:
        if not (ROOT / art_path).is_file():
            errors.append(f"Missing art asset: {art_path}")
    require(region_script, 'const FOREST_BACKDROP = preload("res://assets/art/backdrops/forest_backdrop.svg")', "Forest backdrop preload", errors)
    require(region_script, 'const RUINS_BACKDROP = preload("res://assets/art/backdrops/ruins_backdrop.svg")', "Ruins backdrop preload", errors)
    require(region_script, 'const CHURCH_BACKDROP = preload("res://assets/art/backdrops/church_backdrop.svg")', "Church backdrop preload", errors)
    require(region_script, 'const ELDRITCH_BACKDROP = preload("res://assets/art/backdrops/eldritch_backdrop.svg")', "Eldritch backdrop preload", errors)
    require(region_script, 'const STONE_FLOOR_STRIP = preload("res://assets/art/backdrops/stone_floor_strip.svg")', "Textured floor preload", errors)
    require(region_script, "func _region_backdrop_texture() -> Texture2D:", "Biome backdrop selector", errors)
    require(region_script, "draw_texture_rect(STONE_FLOOR_STRIP, Rect2(0.0, floor_y, map_width, 180.0), false)", "Textured ground draw call", errors)
    prologue_script = read("scripts/levels/escape_prologue.gd", errors)
    require(prologue_script, 'const SURGERY_BACKDROP = preload("res://assets/art/backdrops/surgery_ward_backdrop.svg")', "Opening surgery backdrop preload", errors)
    require(prologue_script, 'const SURGERY_FLOOR_STRIP = preload("res://assets/art/backdrops/surgery_floor_strip.svg")', "Opening surgery floor preload", errors)
    require(prologue_script, "draw_texture_rect(SURGERY_BACKDROP, Rect2(0, 0, LEVEL_WIDTH, 720), false)", "Opening surgery illustrated backdrop", errors)
    require(prologue_script, "draw_texture_rect(SURGERY_FLOOR_STRIP, Rect2(0, FLOOR_Y, LEVEL_WIDTH, 180), false)", "Opening surgery floor texture", errors)
    village_script = read("scripts/levels/village_hub.gd", errors)
    require(village_script, 'const VILLAGE_BACKDROP = preload("res://assets/art/backdrops/village_backdrop.svg")', "Village backdrop preload", errors)
    require(village_script, 'const VILLAGE_GROUND_STRIP = preload("res://assets/art/backdrops/village_ground_strip.svg")', "Village ground preload", errors)
    require(village_script, "draw_texture_rect(VILLAGE_BACKDROP, Rect2(0, 0, 2600, 720), false)", "Village illustrated backdrop", errors)
    require(village_script, "draw_texture_rect(VILLAGE_GROUND_STRIP, Rect2(0, 520, 2600, 200), false)", "Village textured ground", errors)
    # Elevated exits must not remain interactable from the uninterrupted ground floor.
    # 高位出口不能从连续地面直接交互，避免平台只成为装饰路线。
    require(region_script, "rectangle.size = Vector2(110.0, 80.0)", "Door interaction volume height", errors)
    require(region_script, "shape.position = Vector2(0.0, -35.0)", "Door interaction volume vertical alignment", errors)

    require(region_script, "[NEREIS][MAP][SPAWN] region=%s", "Map spawn Debug log", errors)
    require(region_script, "func _spawn_hero(spawn_x: float, spawn_y: float = -1.0) -> void:", "Region-local death checkpoint setup", errors)
    require(region_script, "WorldState.set_checkpoint(hero.global_position)", "Region-local death checkpoint", errors)
    require(region_script, "Keep death recovery inside the current region", "Region-local death checkpoint rationale", errors)
    require(region_script, "[NEREIS][MAP][EXIT] from=%s", "Map exit Debug log", errors)
    require(region_script, 'const REST_POINT_SCRIPT = preload("res://scripts/world/rest_point.gd")', "Regional rest point script", errors)
    require(region_script, "func _spawn_region_rest_point() -> void:", "Regional rest point builder", errors)
    require(region_script, 'rest.rest_id = "rest_%s" % region_id', "Regional rest point identity", errors)
    local_route_script = read("scripts/world/resonance_local_route.gd", errors)
    localization_script = read("scripts/core/localization.gd", errors)
    require(region_script, 'const LOCAL_RESONANCE_ROUTE_SCRIPT = preload("res://scripts/world/resonance_local_route.gd")', "A3 local resonance route preload", errors)
    require(region_script, 'route.route_id = "A3_THIRD_STREET_ROOFLINE"', "A3 local route identity", errors)
    require(region_script, "route.required_resonance = 28", "A3 local route resonance threshold", errors)
    require(region_script, "route.bridge_start_x = 1320.0", "A3 local route start coordinate", errors)
    require(region_script, 'route.route_id = "A4_OLD_STONE_AQUEDUCT"', "A4 local route identity", errors)
    require(region_script, "route.required_resonance = 36", "A4 local route resonance threshold", errors)
    require(region_script, "route.bridge_start_x = 1650.0", "A4 local route start coordinate", errors)
    require(region_script, "route.bridge_end_x = 1935.0", "A4 local route end coordinate", errors)
    require(region_script, 'route.prompt_text = "E  ANCHOR THE DRY AQUEDUCT"', "A4 local route interaction prompt", errors)
    require(local_route_script, "@export var prompt_text: String = \"E  ANCHOR THE THIRD STREET\"", "Configurable local route prompt", errors)
    require(region_script, "route.bridge_end_x = 1690.0", "A3 local route end coordinate", errors)
    require(region_script, "route.bridge_y = 400.0", "A3 local route vertical placement", errors)
    require(local_route_script, 'add_to_group("resonance_hidden_targets")', "Local resonance route reveal registration", errors)
    require(local_route_script, "func update_reveal_state(", "Local route reacts to Resonance Sight state changes", errors)
    require(local_route_script, "sight_active and resonance >= required_resonance", "Local route requires active sight and sufficient resonance", errors)
    require(local_route_script, "WorldState.is_hidden_path_opened(route_id)", "Local route persistent open-state restore", errors)
    require(local_route_script, "WorldState.open_hidden_path(route_id)", "Local route persistence", errors)
    require(local_route_script, "func _sync_bridge_collision() -> void:", "Local route collision lifecycle", errors)
    require(local_route_script, "bridge_body.position = Vector2(bridge_start_x, bridge_y)", "Local route bridge origin", errors)
    require(local_route_script, "rectangle.size = Vector2(bridge_end_x - bridge_start_x, 18.0)", "Local route bridge collision dimensions", errors)
    require(local_route_script, "collision.position = rectangle.size * 0.5", "Local route bridge collision centering", errors)
    require(local_route_script, "bridge_body.queue_free()", "Temporary bridge collision removal", errors)
    require(local_route_script, "func _hero_over_bridge() -> bool:", "Local route protects a Hero standing on a temporary bridge", errors)
    require(local_route_script, "revealed or opened_permanently or _hero_over_bridge()", "Bridge collision remains while the Hero occupies it", errors)
    require(local_route_script, "INTERACTION_FOCUS_SCRIPT.is_focused(self)", "Local route uses shared interaction focus", errors)
    require(local_route_script, 'set_meta("interaction_focus_position", to_global(bridge_center))', "Local route focus uses the bridge anchor", errors)
    require(interaction_focus, "static func _focus_position(node: Node2D) -> Vector2:", "Shared focus supports composite interaction anchors", errors)
    require(interaction_focus, "_focus_position(node).distance_to(hero.global_position)", "Shared focus ranks the active object by its actual focus point", errors)
    require(interaction_focus, "_focus_position(other).distance_to(hero.global_position)", "Shared focus ranks competing objects by their actual focus points", errors)
    require(local_route_script, '"E  ANCHOR THE THIRD STREET"', "Local route explicit E interaction", errors)
    require(world_state, 'for target in get_tree().get_nodes_in_group("resonance_hidden_targets"):', "WorldState refreshes resonance targets", errors)
    require(world_state, 'target.call("update_reveal_state", resonance_sight_active, hero_resonance, ancient_exposure, outer_exposure, debug_override)', "WorldState passes current sight state to map targets", errors)

    # M1 alternate route and vertical traversal contracts.
    # M1 替代路线与垂直探索的静态契约。
    prologue_route_script = read("scripts/levels/escape_prologue.gd", errors)
    require(prologue_route_script, 'SceneTransition.fade_to_scene("res://scenes/village_hub.tscn")', "C01 A0-to-A1 transition", errors)
    village_route_script = read("scripts/levels/village_hub.gd", errors)
    require(village_route_script, 'if location_id == "north_gate":', "C02 A1 north-gate route", errors)
    require(village_route_script, 'WorldState.pending_region_spawn_side = "west"', "C02 A1-to-A2 spawn side", errors)
    require(village_route_script, 'SceneTransition.fade_to_scene("res://scenes/ash_forest.tscn")', "C02 A1-to-A2 transition", errors)
    require(region_script, '"res://scenes/village_hub.tscn", "north_gate"', "C02 A2-to-A1 reverse transition", errors)
    require(village_route_script, 'city_cut.poi_id = "city_cut"', "A1 drainage route", errors)
    require(village_route_script, "city_cut.position = Vector2(100, 520)", "C24 A1 ground-level drainage anchor", errors)
    require(village_route_script, '350.0 if spawn_side == "city_cut_return"', "C24 village return spawn x=350", errors)
    require(village_route_script, "func _spawn_village_rest_point() -> void:", "A1 hearth rest point", errors)
    require(village_route_script, 'rest.rest_id = "rest_A1_village_hearth"', "A1 rest point persistence ID", errors)
    require(village_route_script, '"village_defense_survived" in WorldState.achievement_flags', "A1 drainage gate", errors)
    require(village_route_script, 'WorldState.pending_region_spawn_side = "village_city_cut"', "A1 to A3 spawn mapping", errors)
    require(village_route_script, "func _create_village_rooftop_route() -> void:", "A1 rooftop route builder", errors)
    require(village_route_script, "Rect2(220, 445, 90, 16)", "A1 rooftop first ledge", errors)
    require(village_route_script, "Rect2(1710, 270, 110, 16)", "A1 rooftop route over tavern", errors)
    require(region_script, 'if region_id == "A3" and side == "village_city_cut":\n\t\treturn 700.0', "C24 A3 arrival spawn x=700", errors)
    require(region_script, '520.0, "E  经旧排水道返回"', "A3 return-to-village exit at x=520", errors)
    require(region_script, "_add_platform(Rect2(760, 370, 110, 18))", "A2 forest canopy route", errors)
    require(region_script, "_add_platform(Rect2(450, 400, 110, 18))", "A3 rooftop loop", errors)
    require(region_script, "_add_platform(Rect2(1650, 310, 130, 18))", "A4 pipe-walk route", errors)
    require(region_script, "_add_platform(Rect2(420, 420, 120, 18))", "A5 battlefield parapet route", errors)
    require(region_script, "_add_platform(Rect2(2190, 450, 140, 18))", "A5 elevated monastery approach", errors)
    require(region_script, "2250.0, \"E  沿残墙高路进入修道院\"", "A5 raised main exit", errors)
    require(region_script, '"res://scenes/monastery_tower.tscn", "west", true, "", "", floor_y - 90.0', "C09 elevated door height contract", errors)
    require(region_script, '2350.0, "E  沿外环屋顶阶梯登上大圣堂"', "C17 A9 rooftop exit anchor", errors)
    require(region_script, '"res://scenes/grand_cathedral.tscn", "cathedral_roof", true, "", "", floor_y - 180.0', "C17 elevated destination spawn side", errors)
    require(region_script, '_add_platform(Rect2(80, 360, 150, 18))', "A10 C17 west upper landing platform", errors)
    require(region_script, '"res://scenes/royal_outer_ring.tscn", "cathedral_roof_return",\n\t\t\t\ttrue, "", "", floor_y - 180.0', "C17 elevated return door", errors)
    require(region_script, 'if region_id == "A10" and side == "cathedral_roof":\n\t\treturn floor_y - 180.0', "C17 A10 arrival height mapping", errors)
    require(region_script, 'if region_id == "A9" and side == "cathedral_roof_return":\n\t\treturn floor_y - 180.0', "C17 A9 return height mapping", errors)
    require(region_script, 'if region_id == "A10" and side == "cathedral_roof":\n\t\treturn 180.0', "C17 A10 arrival X mapping", errors)
    require(region_script, 'if region_id == "A9" and side == "cathedral_roof_return":\n\t\treturn 2320.0', "C17 A9 return X mapping", errors)
    require(region_script, "_add_platform(Rect2(1250, 270, 120, 18))", "A6 cloister balcony route", errors)
    require(region_script, "_add_platform(Rect2(1280, 320, 110, 18))", "A7 maintenance catwalk", errors)
    require(region_script, "_add_platform(Rect2(1240, 310, 110, 18))", "A8 upper burial gallery", errors)
    require(region_script, "_add_platform(Rect2(390, 395, 115, 18))", "A9 outer-ring roof loop", errors)
    require(region_script, "_add_platform(Rect2(2190, 390, 140, 18))", "A9 cathedral approach lower step", errors)
    require(region_script, "_add_platform(Rect2(2300, 360, 140, 18))", "A9 cathedral approach upper step", errors)
    require(region_script, "2350.0, \"E  沿外环屋顶阶梯登上大圣堂\"", "A9 raised main exit", errors)
    require(region_script, "_add_platform(Rect2(815, 290, 120, 18))", "A10 cathedral choir gallery", errors)
    require(region_script, "_add_platform(Rect2(1230, 285, 120, 18))", "A11 observation bridge", errors)
    require(region_script, "_add_platform(Rect2(1400, 305, 120, 18))", "A12 crown-wall route", errors)
    require(region_script, '"anomaly_battlefield_late_orders"', "A5 battlefield evidence source", errors)
    require(region_script, '"anomaly_prisoner_register"', "A7 prison evidence source", errors)
    require(region_script, '"anomaly_double_sealed_reliquary"', "A10 cathedral evidence source", errors)
    require(region_script, '"anomaly_kings_unopened_letter"', "A12 king letter evidence source", errors)
    for source_id in [
        "hidden_well_no_water", "hidden_bell_after_sound", "hidden_third_street_numbers",
        "hidden_stair_reflection", "hidden_bell_shadowless_record", "hidden_royal_name_scrape",
        "hidden_mirror_lamp_count", "hidden_primordial_cradle",
    ]:
        require(region_script, '"' + source_id + '"', "Hidden-area evidence source", errors)
    require(region_script, "_add_platform(Rect2(420, 390, 110, 18))", "H01 well upper shore", errors)
    require(region_script, "_add_platform(Rect2(390, 400, 110, 18))", "H02 silent bell gallery", errors)
    require(region_script, "_add_platform(Rect2(380, 395, 110, 18))", "H03 erased street roofline", errors)
    require(region_script, "_add_platform(Rect2(1070, 385, 110, 18))", "H03 upper route gap bridge", errors)
    require(region_script, "_add_platform(Rect2(390, 400, 110, 18))", "H04 reflected stair loop", errors)
    require(region_script, "_add_platform(Rect2(400, 405, 110, 18))", "H05 silent bell gallery", errors)
    require(region_script, "_add_platform(Rect2(390, 405, 110, 18))", "H06 erased royal name gallery", errors)
    require(region_script, "_add_platform(Rect2(380, 395, 110, 18))", "H07 mirror avenue upper route", errors)
    require(region_script, "_add_platform(Rect2(1060, 410, 110, 18))", "H07 lamp bridge gap", errors)
    require(region_script, "_add_platform(Rect2(390, 385, 110, 18))", "H08 organic rib route", errors)

    # Estimate jump reachability for every authored platform using the actual Hero constants.
    # This is an approximate geometry check, not a replacement for collision testing in Godot.
    # 使用主角实际跳跃参数估算所有平台是否能从地面逐段抵达；这不能替代 Godot 碰撞实测。
    hero_physics = read("scripts/player/hero.gd", errors)
    speed_match = re.search(r"const SPEED := ([0-9.]+)", hero_physics)
    jump_match = re.search(r"const JUMP_VELOCITY := -([0-9.]+)", hero_physics)
    gravity_match = re.search(r"const GRAVITY := ([0-9.]+)", hero_physics)
    if not (speed_match and jump_match and gravity_match):
        errors.append("Platform route audit: unable to read Hero speed/jump/gravity constants.")
    else:
        move_speed = float(speed_match.group(1))
        jump_speed = float(jump_match.group(1))
        gravity = float(gravity_match.group(1))
        max_rise = jump_speed * jump_speed / (2.0 * gravity)
        platform_section_start = region_script.find("func _configure_platforms() -> void:")
        platform_section_end = region_script.find("\nfunc _add_platform", platform_section_start)
        platform_section = (
            region_script[platform_section_start:platform_section_end]
            if platform_section_start >= 0 and platform_section_end > platform_section_start
            else ""
        )
        region_headers = list(re.finditer(r'^\s*"([A-Z]\d+)":\s*$', platform_section, re.MULTILINE))
        if not region_headers:
            errors.append("Platform route audit: no region blocks found in _configure_platforms().")
        else:
            for header_index, header in enumerate(region_headers):
                region_id = header.group(1)
                block_end = (
                    region_headers[header_index + 1].start()
                    if header_index + 1 < len(region_headers)
                    else len(platform_section)
                )
                region_block = platform_section[header.start():block_end]
                platforms = [
                    tuple(float(value) for value in match.groups())
                    for match in re.finditer(
                        r"_add_platform\(Rect2\(([0-9.]+),\s*([0-9.]+),\s*([0-9.]+),\s*([0-9.]+)\)\)",
                        region_block,
                    )
                ]
                if not platforms:
                    continue
                platform_audit_regions += 1
                platform_audit_count += len(platforms)
                platforms_by_region[region_id] = platforms
                # Node zero is the continuous ground floor. Platform tuples are x, y, width, height.
                nodes = [(0.0, 540.0, 2600.0, 40.0, True)] + [
                    (x, y, width, height, False) for x, y, width, height in platforms
                ]
                adjacency: list[list[int]] = [[] for _ in nodes]
                for source_index, source_node in enumerate(nodes):
                    sx, sy, sw, _sh, _sfloor = source_node
                    for target_index, target_node in enumerate(nodes):
                        if source_index == target_index:
                            continue
                        tx, ty, tw, _th, _tfloor = target_node
                        vertical_delta = ty - sy
                        if vertical_delta < -max_rise:
                            continue
                        discriminant = jump_speed * jump_speed + 2.0 * gravity * vertical_delta
                        if discriminant < 0.0:
                            continue
                        flight_time = (jump_speed + discriminant ** 0.5) / gravity
                        horizontal_overlap = min(sx + sw, tx + tw) - max(sx, tx)
                        horizontal_gap = max(0.0, tx - (sx + sw), sx - (tx + tw))
                        if vertical_delta < 0.0 and horizontal_overlap > 0.0 and not _sfloor:
                            # A solid platform blocks a direct upward jump from underneath it.
                            # The continuous ground is below the platforms, not an overhead obstruction.
                            # Permit an edge approach only when the source platform extends beyond the target.
                            # 实体平台会挡住从下方直接上跳；地面不是头顶障碍，只有起跳平台在目标平台边缘之外留有可绕行空间时才计入。
                            approach_gaps = []
                            if sx < tx:
                                approach_gaps.append(tx - sx)
                            if sx + sw > tx + tw:
                                approach_gaps.append((sx + sw) - (tx + tw))
                            if not approach_gaps:
                                continue
                            horizontal_gap = min(approach_gaps)
                        if horizontal_gap <= move_speed * flight_time + 36.0:
                            adjacency[source_index].append(target_index)
                reachable = {0}
                pending = [0]
                while pending:
                    current = pending.pop()
                    for neighbour in adjacency[current]:
                        if neighbour not in reachable:
                            reachable.add(neighbour)
                            pending.append(neighbour)
                unreachable_platforms = [
                    index for index in range(1, len(nodes)) if index not in reachable
                ]
                if unreachable_platforms:
                    errors.append(
                        f"Platform route audit {region_id}: unreachable platform indices "
                        f"{[index - 1 for index in unreachable_platforms]} "
                        f"using SPEED={move_speed:g}, JUMP={jump_speed:g}, GRAVITY={gravity:g}."
                    )

    # Verify that every source ID required by a gate is actually spawned by the region controller.
    # 检查所有入口要求的异常来源，都确实由区域控制器生成。
    required_source_ids: set[str] = set()
    for raw_ids in re.findall(r'gate\.required_source_ids\s*=\s*\[([^\]]*)\]', region_script, re.DOTALL):
        required_source_ids.update(re.findall(r'"([^"]+)"', raw_ids))
    spawned_source_ids = set(
        re.findall(r'_spawn_source\(\s*Vector2\([^)]*\),\s*"([^"]+)"', region_script, re.DOTALL)
    )
    missing_source_ids = sorted(required_source_ids - spawned_source_ids)
    if missing_source_ids:
        errors.append(f"Hidden gate source IDs have no spawn point: {missing_source_ids}")

    # Check scene paths used by the map, save-resume routing, and hidden gates.
    # 检查地图、存档续玩和隐藏入口引用的场景路径均存在。
    referenced_scripts = [world_state, boot_script, region_script, secret_gate, local_route_script]
    for referenced_scene in sorted(set(
        re.findall(r'res://(scenes/[^"\s]+\.tscn)', "\n".join(referenced_scripts))
    )):
        if not (ROOT / referenced_scene).is_file():
            errors.append(f"Missing referenced scene: {referenced_scene}")
    for contract in [
        'const RESONANCE_SECRET_GATE_SCRIPT = preload("res://scripts/world/resonance_secret_gate.gd")',
        "_spawn_a4_hidden_well_gate(map_width - 90.0)",
        'gate.secret_id = "H01"',
        'gate.secret_id = "H02"',
        'gate.secret_id = "H03"',
        'gate.secret_id = "H04"',
        'gate.secret_id = "H05"',
        'gate.secret_id = "H06"',
        'gate.secret_id = "H07"',
        'gate.secret_id = "C15"',
        'gate.secret_id = "C19"',
        'gate.secret_id = "H08"',
        'gate.region_record_id = "A11"',
        'func _spawn_h02_gate',
        'func _spawn_h03_gate',
        'func _spawn_h04_gate',
        'func _spawn_h05_gate',
        'func _spawn_h06_gate',
        'func _spawn_a11_maintenance_gate',
        'func _spawn_a11_chapel_gate',
        'func _spawn_h08_gate',
        'func _on_h08_gate_opened',
        'func _draw_deep_research_landmarks',
        'func _draw_primordial_hollow_landmarks',
        'func _draw_hidden_bell_chamber_landmarks',
        'func _draw_erased_third_street_landmarks',
        'func _draw_reflected_stairwell_landmarks',
        'func _draw_silent_bell_room_landmarks',
        'func _draw_erased_royal_name_landmarks',
        'anomaly_observer_reaction',
        'if WorldState.physical_union_complete:',
        'ENDGAME_GATE_SCRIPT',
        'reached_A10_via_A9',
        'primordial_hollow',
        'deep_research_depths',
        'gate.required_resonance = 68',
        'gate.required_outer_exposure = 12',
        'gate.require_outer_god_resonance = true',
        'gate.required_source_ids = ["anomaly_mirror_street_echo"]',
        'opened_mirror_street_side_gate',
        'reached_A12_via_A10',
        'anomaly_mirror_street_echo',
        'royal_outer_ring',
        'grand_cathedral',
        'inner_city',
        'mirror_street',
        'gate.target_spawn_side = "east"',
        'gate.required_resonance = 12',
        'if "reached_A4_via_A3" in WorldState.achievement_flags:',
        '"A2"',
        '"A3"',
        '"A4"',
        '"H01"',
        '"anomaly_bell_retiming"',
        '"anomaly_old_pilgrim_echo"',
        '"anomaly_erased_street_sign"',
        '"anomaly_old_stone_layer"',
        '"anomaly_silent_bell_window"',
        '"anomaly_erased_royal_name"',
        'opened_sewer_inspection_hatch_from_A4',
        'reached_A5_and_opened_old_pilgrim_highroad',
        'E  OPEN THE OLD PILGRIM HIGHROAD',
        'E  RETURN TO THE BATTLEFIELD',
        'opened_bell_tower_drop',
        'E  RETURN TO THE MONASTERY DROP',
        'reached_A7_then_opened_supply_tunnel',
        'reached_A8_via_A7_then_opened_royal_tomb_gate',
        'reached_A9_via_A8_then_opened_old_lift_from_A9',
        'reached_A12_via_A10_then_opened_inner_city_side_gate',
        'reached_A9_then_opened_royal_drain_from_outer_ring',
        'E  OPEN THE SUPPLY TUNNEL',
        'E  OPEN THE ROYAL TOMB WATERWAY',
        'E  OPEN THE OLD LIFT',
        'E  OPEN THE INNER-CITY SIDE GATE',
        'E  OPEN THE ROYAL DRAIN',
        'opened_old_bell_tower_connection',
        'opened_old_service_door',
        'opened_royal_tomb_side_door',
        'opened_bell_tower_drop',
        'opened_royal_transport_side_door',
        'WorldState.mark_hidden_region_entered("H02")',
        'WorldState.mark_hidden_region_entered("H03")',
        'WorldState.mark_hidden_region_entered("H04")',
        'WorldState.mark_hidden_region_entered("H05")',
        'WorldState.mark_hidden_region_entered("H06")',
        'unlock_once_flag_id: String = ""',
        'door.unlock_once_flag_id = unlock_once_flag_id',
        '"reached_A4_via_A3"',
        '"old_battlefield"',
        '"monastery_tower"',
        '"prison_depths"',
        '"royal_tomb"',
        'E  打开检修舱口',
        'opened_sewer_inspection_hatch_from_A4',
        'SceneTransition.fade_to_scene(target_scene)',
        "clue.ancient_exposure_floor = ancient_floor",
    ]:
        require(region_script, contract, "Graybox region controller", errors)

    # Catch accidental line-join syntax defects in spawn mapping and ensure C04 is wired on both ends.
    # 检查出生点映射中意外粘连的语法错误，并确保 C04 两端都接线。
    if 'return 850.0    if region_id' in region_script:
        fail(errors, "Graybox spawn mapping: C04 A5 spawn branch is concatenated with the next if statement.")
    for contract in [
        '"E  打开旧朝圣高路"',
        '"E  返回边境战场"',
        '"reached_A5_and_opened_old_pilgrim_highroad" in WorldState.achievement_flags',
        '"reached_A5_and_opened_old_pilgrim_highroad", "E  沿旧朝圣高路返回"',
    ]:
        require(region_script, contract, "C04 old pilgrim highroad", errors)

    # C05 is recorded only by traversing from A3; merely loading/entering A4 from another branch must not fake it.
    # C05 只能由 A3 实际进入 A4 时记录；从其他支路进入或读档不能伪造这条路线。
    require(region_script, 'if region_id == "A3" and target_location == "sewer_reservoir":\n        WorldState.record_achievement("reached_A4_via_A3")', "C05 route recording", errors)
    a4_ready_start = region_script.find('func _ready()')
    a4_ready_end = region_script.find('func _spawn_x_for_side', a4_ready_start)
    ready_block = region_script[a4_ready_start:a4_ready_end] if a4_ready_start >= 0 and a4_ready_end > a4_ready_start else ""
    if 'WorldState.record_achievement("reached_A4_via_A3")' in ready_block:
        fail(errors, "C05 route flag must not be recorded unconditionally on A4 scene entry.")

    # C24 must be gated on the city side too, matching the village's defense requirement.
    # C24 城区侧也必须受村庄防卫标记约束，与村庄入口条件一致。
    a3_start = region_script.find('        "A3":', region_script.find("func _spawn_region_exits"))
    a4_start = region_script.find('        "A4":', a3_start)
    a3_exit_block = region_script[a3_start:a4_start] if a3_start >= 0 and a4_start > a3_start else ""
    if not a3_exit_block:
        fail(errors, "C24 route audit: cannot isolate A3 exit block.")
    else:
        require(a3_exit_block, 'if "village_defense_survived" in WorldState.achievement_flags:', "C24 city-side defense gate", errors)
        require(a3_exit_block, '"E  经旧排水道返回"', "C24 city-side return door", errors)
        if a3_exit_block.find('"E  经旧排水道返回"') < a3_exit_block.find('if "village_defense_survived" in WorldState.achievement_flags:'):
            fail(errors, "C24 A3 return door must remain inside the village-defense condition.")

    # Locate the exit mapping before any public or hidden route audit uses it.
    # 在公开路线与隐藏路线审计使用前，先定位出口映射函数。
    exits_start = region_script.find("func _spawn_region_exits")
    if exits_start < 0:
        fail(errors, "Graybox route audit: cannot find _spawn_region_exits function.")
        exits_start = 0

    # Check both directions of the remaining public backbone connections.
    # 检查其余公开主干连线的双向出口，避免场景仍存在但主线断开。
    route_blocks = {}
    ordered_route_regions = ["A2", "A3", "A4", "A5", "A6", "A7", "A8", "A9", "A10", "A12", "H07", "H01", "H02", "H03", "H04", "H05", "H06", "A11", "H08"]
    route_positions = {
        region: region_script.find(f'        "{region}":', exits_start)
        for region in ordered_route_regions
    }
    sorted_route_regions = sorted(
        ((position, region) for region, position in route_positions.items() if position >= 0)
    )
    for index, (position, region) in enumerate(sorted_route_regions):
        next_position = sorted_route_regions[index + 1][0] if index + 1 < len(sorted_route_regions) else len(region_script)
        route_blocks[region] = region_script[position:next_position]
    main_route_contracts = [
        ("A2", '"E  沿树冠高路进入被遗忘的城区"', "C03 A2-to-A3"),
        ("A3", '"E  返回旧朝圣路"', "C03 A3-to-A2"),
        ("A3", '"E  沿残墙高路前往战场"', "C08 A3-to-A5"),
        ("A5", '"E  返回被遗忘的城区"', "C08 A5-to-A3"),
        ("A5", '"E  沿残墙高路进入修道院"', "C09 A5-to-A6"),
        ("A6", '"E  返回边境战场"', "C09 A6-to-A5"),
        ("A6", '"E  深入监牢"', "C11 A6-to-A7"),
        ("A7", '"E  返回修道院"', "C11 A7-to-A6"),
        ("A7", '"E  进入旧王墓"', "C13 A7-to-A8"),
        ("A8", '"E  返回监牢"', "C13 A8-to-A7"),
        ("A8", '"E  进入王城外环"', "C14 A8-to-A9"),
        ("A9", '"E  返回旧王墓"', "C14 A9-to-A8"),
    ]
    for source_region, contract, connection_label in main_route_contracts:
        require(route_blocks.get(source_region, ""), contract, connection_label, errors)

    # C04 is a paired upper-route shortcut: both door heights, platform support, and arrival elevations must remain aligned.
    # C04 是双侧高路捷径：两侧门高、承托平台与到达高度必须保持一致。
    for contract in (
        '1880.0, "E  返回边境战场", "old_battlefield"',
        '"res://scenes/old_battlefield.tscn", "old_pilgrim_highroad",\n\t\t\t\t\ttrue, "", "", floor_y - 115.0',
        '520.0, "E  打开旧朝圣高路", "ash_forest"',
        '"reached_A5_and_opened_old_pilgrim_highroad", "E  沿旧朝圣高路返回",\n\t\t\t\tfloor_y - 140.0',
        'if region_id == "A2" and side == "old_pilgrim_highroad":\n\t\treturn floor_y - 140.0',
        'if region_id == "A5" and side == "old_pilgrim_highroad":\n\t\treturn floor_y - 85.0',
        '_add_platform(Rect2(1840, 445, 130, 18))',
        '_add_platform(Rect2(420, 420, 120, 18))',
        '_add_platform(Rect2(560, 455, 160, 18))',
        'if region_id == "A4" and side == "prison_tunnel":\n\t\t# C12 arrives on the low ledge 90px away from its own return door.\n\t\t# C12 出生在低位栈台上，距回程门 90px，避免落地立即重新触发。\n\t\treturn 960.0',
        'if region_id == "A4" and side == "royal_drain":\n\t\t# C23 lands on the lower support lip at x=1570, then steps right to the pipe door.\n\t\t# C23 落在 x=1570 的承托边沿，再向右走到管线门。\n\t\treturn 1570.0',
        '_add_platform(Rect2(1530, 420, 70, 18))',
        '_add_platform(Rect2(620, 390, 180, 18))',
        '740.0, "E  打开王城排水门"',
    ):
        require(region_script, contract, "C04 paired canopy route", errors)

    # C17 and C20 are the intended public route through the cathedral; C18 must remain a later shortcut.
    # C17/C20 是经过大圣堂的公开主线；C18 只能作为抵达内城后的后期开启捷径。
    a9_start = region_script.find('        "A9":', exits_start)
    a10_start = region_script.find('        "A10":', a9_start)
    a12_start = region_script.find('        "A12":', a10_start)
    h07_start = region_script.find('        "H07":', a12_start)
    a9_route_block = region_script[a9_start:a10_start] if a9_start >= 0 and a10_start > a9_start else ""
    a10_route_block = region_script[a10_start:a12_start] if a10_start >= 0 and a12_start > a10_start else ""
    a12_route_block = region_script[a12_start:h07_start] if a12_start >= 0 and h07_start > a12_start else ""
    for contract in [
        '"E  沿外环屋顶阶梯登上大圣堂"',
        'res://scenes/grand_cathedral.tscn", "west"',
    ]:
        require(a9_route_block, contract, "C17 outer-ring-to-cathedral main route", errors)
    for contract in [
        '"E  进入王室内城"',
        'res://scenes/inner_city.tscn", "west"',
    ]:
        require(a10_route_block, contract, "C20 cathedral-to-inner-city main route", errors)
    require(a12_route_block, '"E  返回大圣堂"', "C20 inner-city return route", errors)
    require(a12_route_block, '"reached_A12_via_A10_then_opened_inner_city_side_gate"', "C18 main-route prerequisite", errors)
    if a9_route_block.find('"E  RETURN TO THE INNER CITY"') >= 0 and a9_route_block.find('"reached_A12_via_A10_then_opened_inner_city_side_gate"') < 0:
        fail(errors, "C18 A9-side shortcut must remain gated by opening it from A12 after the main route.")

    # C10 must be available independently of H05; its only persisted unlock is its own drop flag.
    # C10 必须独立于 H05 可用；它只依赖自身的钟塔落差开门标记。
    a6_start = region_script.find('        "A6":', region_script.find("func _spawn_region_exits"))
    a7_start = region_script.find('        "A7":', a6_start)
    a6_exit_block = region_script[a6_start:a7_start] if a6_start >= 0 and a7_start > a6_start else ""
    if not a6_exit_block:
        fail(errors, "C10 route audit: cannot isolate A6 exit block.")
    else:
        require(a6_exit_block, '"E  打开钟塔落差通路"', "C10 monastery shortcut", errors)
        require(a6_exit_block, '"opened_bell_tower_drop"', "C10 monastery shortcut", errors)
        if 'if WorldState.is_hidden_path_opened("H05")' in a6_exit_block:
            fail(errors, "C10 monastery shortcut must not depend on the optional H05 secret path.")
    if "1830.0, \"E  RETURN TO THE SILENT BELL WINDOW\"" in region_script:
        fail(errors, "H05 return door at x=1830 is too close to the C10 door at x=1710.")
    if "1950.0, \"E  RETURN TO THE SILENT BELL WINDOW\"" in region_script:
        fail(errors, "H05 return door at x=1950 overlaps the A3 rest-point interaction radius.")
    require(region_script, '1870.0, "E  返回无声之窗"', "H05/C10/C16 interaction spacing", errors)
    require(region_script, '1250.0, "E  打开旧服务门"', "A9 H03/C18 interaction spacing", errors)
    if '1020.0, "E  打开旧服务门"' in region_script:
        fail(errors, "A9 H03 service door remains too close to the C18 inner-city side gate.")

    # Each playable region must have its intended lightweight encounter roster.
    # 每个可玩区域必须保留对应的轻量遭遇配置，A9 作为交通枢纽刻意不生成战斗敌人。
    encounter_contracts = {
        "A2": ["A2_PaleHound_01", "A2_Cultist_01"],
        "A3": ["A3_Bandit_01", "A3_Cultist_01"],
        "A4": ["A4_ResearchHusk_01"],
        "A5": ["A5_Bandit_01"],
        "A6": ["A6_Inquisitor_01"],
        "A7": ["A7_ResearchHusk_01"],
        "A8": ["A8_Cultist_01"],
        "A10": ["A10_Inquisitor_01", "A10_BellWraith_01"],
        "A11": ["A11_ResearchHusk_01"],
        "A12": ["A12_Inquisitor_01", "A12_Cultist_01"],
        "H01": ["H01_Cultist_01"],
        "H02": ["H02_BellWraith_01"],
        "H03": ["H03_Bandit_01"],
        "H04": ["H04_PaleHound_01"],
        "H05": ["H05_BellWraith_01"],
        "H06": ["H06_Inquisitor_01"],
        "H07": ["H07_PaleHound_01"],
        "H08": ["H08_ResearchHusk_01"],
    }
    for region_id, enemy_names in encounter_contracts.items():
        require(region_script, f'"{region_id}":', f"{region_id} encounter region", errors)
        for enemy_name in enemy_names:
            require(region_script, f'"{enemy_name}"', f"{region_id} encounter roster", errors)
    require(region_script, "ENCOUNTER_ACTIVATE_RANGE := 420.0", "Encounter activation radius", errors)
    require(region_script, "ENCOUNTER_DEACTIVATE_RANGE := 560.0", "Encounter deactivation hysteresis", errors)
    require(region_script, 'enemy.set_physics_process(false)', "Dormant encounters do not chase across the whole region", errors)

    # Hidden-region exits must preserve their intended return loops and second-side unlocks.
    # 隐藏区域的出口必须保留预期回环，并且远侧出口只能在对应实体门开启后可用。
    hidden_exit_contracts = {
        "H01": [
            '"E  返回边境村庄"',
            '"reached_A4_via_A3" in WorldState.achievement_flags',
            'WorldState.is_hidden_path_opened("H01")',
            '"sewer_reservoir"',
        ],
        "H02": [
            '"E  返回旧朝圣路"',
            '"opened_old_bell_tower_connection" in WorldState.achievement_flags',
            '"old_battlefield"',
        ],
        "H03": [
            '"E  返回被遗忘的城区"',
            '"opened_old_service_door" in WorldState.achievement_flags',
            '"royal_outer_ring"',
        ],
        "H04": [
            '"E  返回旧水库"',
            '"opened_royal_tomb_side_door" in WorldState.achievement_flags',
            '"royal_tomb"',
        ],
        "H05": [
            '"E  返回修道院"',
            '"opened_bell_tower_drop" in WorldState.achievement_flags',
            '"forgotten_city"',
        ],
        "H06": [
            '"E  返回旧王墓"',
            '"opened_royal_transport_side_door" in WorldState.achievement_flags',
            '"royal_outer_ring"',
        ],
        "H07": [
            '"E  穿过积水返回"',
            '"opened_mirror_street_side_gate" in WorldState.achievement_flags',
            '"inner_city"',
        ],
        "H08": [
            '"E  返回深层研究区"',
            'if WorldState.physical_union_complete:',
            '"terminal_anomaly"',
            '"res://scenes/terminal_anomaly.tscn"',
        ],
    }
    for hidden_id, contracts in hidden_exit_contracts.items():
        # GDScript match branches are tab-indented; support either tabs or spaces so this
        # source-level check does not silently fail when formatting changes.
        branch_match = re.search(
            rf'^[\t ]*"{re.escape(hidden_id)}":',
            region_script[exits_start:],
            re.MULTILINE,
        )
        block_start = exits_start + branch_match.start() if branch_match else -1
        next_branch = re.search(
            r'^[\t ]*"[A-Z]\d{1,2}":',
            region_script[block_start + 1:] if block_start >= 0 else "",
            re.MULTILINE,
        )
        block_end = block_start + 1 + next_branch.start() if block_start >= 0 and next_branch else -1
        block = region_script[block_start:block_end] if block_start >= 0 and block_end > block_start else ""
        if not block:
            fail(errors, f"{hidden_id} hidden-region exit block is missing or malformed.")
            continue
        for contract in contracts:
            require(block, contract, f"{hidden_id} hidden-region return contract", errors)

    # A13 is a real terminal map layer, not merely an abstract topology node. Ending selection occurs after entering it.
    # A13 必须是实际终局地图层，而不是只存在于拓扑中的抽象节点；进入后才选择结局。
    a13_match = re.search(r'^[\t ]*"A13":', region_script[exits_start:], re.MULTILINE)
    a13_start = exits_start + a13_match.start() if a13_match else -1
    a13_next = re.search(
        r'^[\t ]*"[A-Z]\d{1,2}":',
        region_script[a13_start + 1:] if a13_start >= 0 else "",
        re.MULTILINE,
    )
    a13_end = (
        a13_start + 1 + a13_next.start()
        if a13_start >= 0 and a13_next
        else region_script.find("\nfunc ", a13_start) if a13_start >= 0 else -1
    )
    a13_block = region_script[a13_start:a13_end] if a13_start >= 0 and a13_end > a13_start else ""
    if not a13_block:
        fail(errors, "A13 terminal exit block is missing or malformed.")
    else:
        require(a13_block, 'ending_gate.call("route_candidate")', "A13 ending evaluator", errors)
        require(a13_block, '"ending_fire_demo.tscn"', "A13 fire ending route", errors)
        require(a13_block, '"ending_paradise_demo.tscn"', "A13 paradise ending route", errors)
        require(a13_block, '"E  接受终局"', "A13 final threshold", errors)
    require(region_script, '"terminal_anomaly"', "A13 runtime location id", errors)
    require(world_state, '"terminal_anomaly":', "A13 save/resume mapping", errors)

    # A3 exits must occupy distinct spatial lanes: raised sewer branch, street-level hidden clue,
    # and elevated far-eastern lift. This prevents all major choices from collapsing into one doorway cluster.
    # A3 出口必须分布在不同空间层：抬高的下水道支路、街面隐藏线索、东侧高位升降机。
    # 这样可以避免主要路线全部挤在同一片门口区域。
    require(region_script, '1600.0, "E  沿旧管线栈道下行至水库"', "A3 raised C05 branch", errors)
    require(region_script, 'true, "", "", floor_y - 115.0', "A3 C05 elevation", errors)
    require(region_script, '_add_platform(Rect2(80, 445, 220, 18))', "A4 C05 upper inspection landing", errors)
    require(region_script, '"E  打开上层检修舱口"', "A4 C05 raised hatch label", errors)
    require(region_script, '"E  返回城区", floor_y - 115.0', "A4 C05 hatch elevation", errors)
    require(region_script, 'if region_id == "A4" and side == "sewer_upper":\n\t\treturn floor_y - 115.0', "A4 C05 arrival height mapping", errors)
    spawn_y_start = region_script.find("func _spawn_y_for_side(side: String) -> float:")
    spawn_x_start = region_script.find("func _spawn_x_for_side(side: String) -> float:")
    spawn_y_block = region_script[spawn_y_start:spawn_x_start] if spawn_y_start >= 0 and spawn_x_start > spawn_y_start else ""
    c05_y_branch = 'if region_id == "A4" and side == "sewer_upper":\n\t\treturn floor_y - 115.0'
    if spawn_y_block.count(c05_y_branch) != 1:
        fail(errors, "C05 A4 sewer_upper Y mapping must appear exactly once in _spawn_y_for_side.")
    if 'if region_id == "A4" and side == "sewer_upper":\n\t\treturn 180.0' in spawn_y_block:
        fail(errors, "C05 A4 sewer_upper Y mapping must not use absolute y=180.0 above its supported landing.")
    require(region_script, 'if region_id == "A4" and side == "sewer_upper":\n\t\treturn 180.0', "A4 C05 arrival X mapping", errors)
    require(region_script, '2040.0, "E  经东侧高位旧升降机返回王城外环"', "A3 elevated C16 branch", errors)
    require(region_script, 'true, "", "", floor_y - 70.0', "A3 C16 elevation", errors)
    require(region_script, '_register_debug_locked_route_hint(2040.0, "royal_outer_ring"', "A3 C16 debug marker", errors)

    # A4's transport hub must distribute the three cross-region doors across separate ledges.
    # A4 交通枢纽必须将三条跨区门分布在不同高度的栈台上。
    require(region_script, '_add_platform(Rect2(930, 465, 180, 18))', "A4 low supply-tunnel ledge", errors)
    require(region_script, '1050.0, "E  返回监牢"', "A4 C12 low ledge exit", errors)
    require(region_script, 'if region_id == "A4" and side == "prison_tunnel":\n\t\t# C12 arrives on the low ledge 90px away from its own return door.\n\t\t# C12 出生在低位栈台上，距回程门 90px，避免落地立即重新触发。\n\t\treturn 960.0', "A4 C12 safe spawn", errors)
    require(region_script, 'true, "", "", floor_y - 75.0', "A4 C12 elevation", errors)
    require(region_script, '1320.0, "E  返回旧王墓"', "A4 C07 middle ledge exit", errors)
    require(region_script, 'true, "", "", floor_y - 85.0', "A4 C07 elevation", errors)
    require(region_script, '1650.0, "E  返回王城外环"', "A4 C23 upper pipe exit", errors)
    require(region_script, 'true, "", "", floor_y - 105.0', "A4 C23 elevation", errors)
    require(region_script, '2220.0, "E  打开村庄井道水闸"', "A4 C06 return lane", errors)
    require(region_script, '2020, 450, 130, 18', "A6 C10 upper approach platform", errors)
    require(region_script, '2230.0, "E  打开钟塔落差通路"', "A6 C10 elevated door", errors)
    require(region_script, 'true, "opened_bell_tower_drop", "E  返回被遗忘的城区", floor_y - 55.0', "A6 C10 door height", errors)
    require(region_script, '520.0, "E  打开旧升降梯"', "A9 C16 rooftop door", errors)
    require(region_script, 'true, "reached_A9_via_A8_then_opened_old_lift_from_A9", "E  乘旧升降梯返回",\n\t\t\t\tfloor_y - 110.0', "A9 C16 door height", errors)
    require(region_script, '_add_platform(Rect2(620, 390, 180, 18))', "A9 C23 supported upper service ledge", errors)
    require(region_script, '740.0, "E  打开王城排水门"', "A9 C23 supported upper door", errors)
    require(region_script, 'if region_id == "A9" and side == "royal_drain":\n\t\t# C23\'s door is at x=740; land at x=650 on the same supported ledge, clear of C16 and C18.\n\t\t# C23 门移至 x=740；落点 x=650 与门保持净距，并避开 C16 与 C18。\n\t\treturn 650.0', "A9 C23 safe spawn", errors)
    require(region_script, '_add_platform(Rect2(1530, 420, 70, 18))', "A4 C23 return spawn support", errors)
    require(region_script, 'return 1570.0', "A4 C23 safe return spawn", errors)
    require(region_script, 'true, "reached_A9_then_opened_royal_drain_from_outer_ring", "E  沿王城排水道返回",\n\t\t\t\tfloor_y - 150.0', "A9 C23 door height", errors)
    require(region_script, 'Vector2(850, floor_y - 18.0),\n\t\t\t\t"anomaly_old_stone_layer"', "A4 clue/door interaction spacing", errors)

    # C03's canopy route and C07's middle tomb-waterway route must keep their authored elevation on both ends.
    # C03 树冠高路与 C07 王墓中层水道必须在双向转场中保留设计高度。
    for contract in [
        'map_width - 160.0, "E  沿树冠高路进入被遗忘的城区"',
        '"res://scenes/forgotten_city.tscn", "city_canopy_entry",',
        'true, "", "", floor_y - 160.0',
        '72.0, "E  返回旧朝圣路", "ash_forest"',
        '_add_platform(Rect2(80, 410, 150, 18))',
        'if region_id == "A3" and side == "city_canopy_entry":\n\t\treturn floor_y - 130.0',
        'if region_id == "A3" and side == "city_canopy_entry":\n\t\treturn 180.0',
        '_add_platform(Rect2(500, 375, 140, 18))',
        '520.0, "E  打开王墓水道", "sewer_reservoir"',
        'true, "reached_A8_via_A7_then_opened_royal_tomb_gate", "E  沿王室水道返回",\n\t\t\t\tfloor_y - 165.0',
        'if region_id == "A8" and side == "royal_tomb_waterway":\n\t\treturn floor_y - 165.0',
        'if region_id == "A8" and side == "royal_tomb_waterway":',
        "C07 returns beside its A8 door",
        "return 610.0",
    ]:
        require(region_script, contract, "C03/C07 vertical route contract", errors)
    require(region_script, '_spawn_hero(_spawn_x_for_side(spawn_side), _spawn_y_for_side(spawn_side))', "Spawn uses both axes", errors)
    for vertical_spawn_contract in [
        'if region_id == "A2" and side == "east":\n\t\treturn floor_y - 140.0',
        'if region_id == "A6" and side == "bell_drop":\n\t\treturn floor_y - 90.0',
        'if region_id == "A3" and side == "sewer":\n\t\treturn floor_y - 115.0',
        'if region_id == "A3" and side == "old_lift":\n\t\treturn floor_y - 70.0',
        'if region_id == "A4" and side == "prison_tunnel":\n\t\treturn floor_y - 75.0',
        'if region_id == "A4" and side == "royal_tomb_waterway":\n\t\treturn floor_y - 85.0',
        'if region_id == "A4" and side == "royal_drain":\n\t\treturn floor_y - 120.0',
        'if region_id == "A9" and side == "old_lift":\n\t\treturn floor_y - 110.0',
        'if region_id == "A9" and side == "royal_drain":\n\t\treturn floor_y - 150.0',
    ]:
        require(region_script, vertical_spawn_contract, "Elevated route spawn height", errors)

    # Spawn-side contracts keep the Hero clear of the very door/gate used to enter a region.
    # 出口出生点必须避开刚刚使用的门与隐藏入口，防止落地即重新触发 E 交互。
    spawn_contracts = [
        ('if region_id == "A2" and side == "east":', "return 2120.0"),
        ('if region_id == "A9" and side == "mirror":', "return 1680.0"),
        ('if region_id == "A11" and side == "chapel_entry":', "return map_width - 700.0"),
        ('if region_id == "H02" and side == "bell_tower_entry":', "return map_width - 360.0"),
        ('if region_id == "H03" and side == "third_street_entry":', "return map_width - 360.0"),
        ('if region_id == "H04" and side == "royal_tomb_side_entry":', "return map_width - 360.0"),
        ('if region_id == "H05" and side == "bell_drop_entry":', "return map_width - 360.0"),
        ('if region_id == "H06" and side == "royal_transport_entry":', "return map_width - 360.0"),
        ('if region_id == "A3" and side == "sewer":', "return 1380.0"),
        ('if region_id == "A3" and side == "village_city_cut":', "return 700.0"),
        ('if region_id == "A2" and side == "bell_gate":', "return map_width - 450.0"),
        ('if region_id == "A2" and side == "old_pilgrim_highroad":', "return 1750.0"),
        ('if region_id == "A5" and side == "old_pilgrim_highroad":', "return 650.0"),
        ('if region_id == "A3" and side == "bell_drop":', "return 1600.0"),
        ('if region_id == "A3" and side == "old_lift":', "return 1960.0"),
        ('if region_id == "A6" and side == "bell_drop":', "return 2100.0"),
        ('if region_id == "A9" and side == "royal_drain":', "return 650.0"),
        ('if region_id == "A9" and side == "old_lift":', "return 610.0"),
        ('if region_id == "A9" and side == "inner_city_side_gate":', "return 980.0"),
        ('if region_id == "A12" and side == "inner_city_side_gate":', "return 650.0"),
        ('if region_id == "A3" and side == "third_street_gate":', "return map_width - 500.0"),
        ('if region_id == "A4" and side == "water_reflection_gate":', "return 1550.0"),
        ('if region_id == "A4" and side == "east":', "return map_width - 360.0"),
        ('if region_id == "A4" and side == "prison_tunnel":', "return 960.0"),
        ('if region_id == "A7" and side == "supply_tunnel":', "return 610.0"),
        ('if region_id == "A4" and side == "royal_tomb_waterway":', "return 1260.0"),
        ('if region_id == "A4" and side == "royal_drain":', "return 1570.0"),
        ('if region_id == "A5" and side == "bell_tower":', "return 1900.0"),
        ('if region_id == "A6" and side == "silent_window":', "return 1400.0"),
        ('if region_id == "A8" and side == "royal_name_gate":', "return 1350.0"),
        ('if region_id == "A8" and side == "royal_tomb_waterway":', "return 610.0"),
        ('if region_id == "A8" and side == "royal_tomb_side":', "return 1020.0"),
        ('if region_id == "A9" and side == "third_street_service":', "return 1600.0"),
        ('if region_id == "A9" and side == "royal_transport":', "return 2050.0"),
        ('if region_id == "H01" and side == "east":', "return map_width - 360.0"),
    ]
    for condition, expected_return in spawn_contracts:
        start = region_script.find(condition)
        if start < 0:
            fail(errors, f"Graybox spawn mapping: missing {condition!r}")
            continue
        branch = region_script[start:]
        next_branch = branch.find("\n    if ", len(condition))
        if next_branch >= 0:
            branch = branch[:next_branch]
        require(branch, expected_return, f"Graybox spawn mapping {condition}", errors)

    # Death recovery must stay inside the current region and restore the Hero safely.
    # 死亡恢复必须留在当前区域，并安全恢复主角状态。
    spawn_hero_start = region_script.find("func _spawn_hero(")
    spawn_hero_end = region_script.find("\nfunc ", spawn_hero_start + 1)
    spawn_hero_block = region_script[spawn_hero_start:spawn_hero_end if spawn_hero_end >= 0 else len(region_script)]
    for contract in [
        "WorldState.set_checkpoint(hero.global_position)",
        "hero.defeated.connect(_on_hero_defeated)",
    ]:
        require(spawn_hero_block, contract, "Region-local checkpoint setup", errors)

    death_start = region_script.find("func _on_hero_defeated() -> void:")
    death_end = region_script.find("\nfunc ", death_start + 1)
    death_block = region_script[death_start:death_end if death_end >= 0 else len(region_script)]
    for contract in [
        "if respawning:",
        "respawning = true",
        "hero.velocity = Vector2.ZERO",
        "hero.global_position = WorldState.checkpoint_position",
        'hero.call("restore_full")',
        "WorldState.input_locked = false",
        "respawning = false",
    ]:
        require(death_block, contract, "Death recovery", errors)
    if "SceneTransition.fade_to_scene(" in death_block or "change_scene_to_file(" in death_block:
        fail(errors, "Death recovery must not transition to another region or reuse a previous scene checkpoint.")

    source_clue = read("scripts/world/resonance_source_clue.gd", errors)
    require(source_clue, "WorldState.record_resonance_milestone(", "Resonance source clue", errors)
    require(source_clue, "func _milestone_needs_repair() -> bool:", "Legacy-save anomaly repair", errors)
    require(source_clue, "func _refresh_consumed_state() -> void:", "Legacy-save anomaly repair", errors)
    require(source_clue, "not WorldState.is_ability_unlocked(unlock_ability_id)", "Legacy-save ability repair", errors)
    require(source_clue, "ancient_exposure_floor,", "Resonance source exposure floor", errors)
    require(source_clue, "outer_exposure_floor", "Resonance source exposure floor", errors)
    require(source_clue, "require_outer_god_resonance", "Resonance source story gate", errors)
    require(source_clue, 'KEY_E', "Resonance source clue", errors)
    require(source_clue, "INTERACTION_FOCUS_SCRIPT.is_focused(self)", "Resonance source clue", errors)

    interaction_door = read("scripts/world/interaction_door.gd", errors)
    for contract in [
        'unlock_once_flag_id: String = ""',
        'opened_prompt_text: String = ""',
        'WorldState.record_achievement(unlock_once_flag_id)',
        'prompt_text = opened_prompt_text',
        'var available := enabled and not WorldState.input_locked and hero_nearby and cooldown <= 0.0',
    ]:
        require(interaction_door, contract, "One-time inspection hatch", errors)
    if "if hero_nearby and WorldState.input_locked:" in interaction_door:
        errors.append("Interaction doors must preserve physical proximity while dialogue locks world input.")

    secret_gate = read("scripts/world/resonance_secret_gate.gd", errors)
    for contract in [
        'add_to_group("resonance_hidden_targets")',
        "WorldState.is_hidden_path_opened(secret_id)",
        "@export var region_record_id: String = \"\"",
        "func _get_region_record_id() -> String:",
        "WorldState.discover_hidden_region(_get_region_record_id())",
        "WorldState.open_hidden_path(secret_id)",
        "WorldState.mark_hidden_region_entered(_get_region_record_id())",
        "WorldState.resonance_sight_active",
        "KEY_E",
        "SceneTransition.fade_to_scene(target_scene_path)",
        'target_spawn_side: String = "west"',
        "require_outer_god_resonance",
        "WorldState.pending_region_spawn_side = target_spawn_side",
        "match secret_id:",
        "func _draw_well_marker() -> void:",
        "func _draw_early_bell_marker() -> void:",
        "func _draw_erased_street_marker() -> void:",
        "func _draw_reflected_stairs_marker() -> void:",
        "func _draw_silent_window_marker() -> void:",
        "func _draw_mirror_street_marker() -> void:",
        "func _draw_erased_royal_name_marker() -> void:",
        "func _draw_silent_chapel_marker() -> void:",
        "func _draw_breathing_wall_marker() -> void:",
        "func _draw_generic_anomaly_marker() -> void:",
    ]:
        require(secret_gate, contract, "Resonance hidden gate", errors)

    village_hub = read("scripts/levels/village_hub.gd", errors)
    require(village_hub, "_spawn_resonance_well_gate()", "Village hub", errors)
    require(village_hub, "resonance_well_gate.opened.connect(_on_resonance_well_opened)", "Village hub", errors)
    require(village_hub, 'resonance_well_gate.secret_id = "H01"', "Village hidden gate ID", errors)
    require(village_hub, 'resonance_well_gate.required_resonance = 12', "Village hidden gate threshold", errors)
    require(village_hub, 'resonance_well_gate.target_location_id = "hidden_well"', "Village hidden gate destination", errors)
    require(village_hub, 'var spawn_x := 1850.0 if spawn_side == "well_exit"', "Village watergate return spawn spacing", errors)
    require(village_hub, 'var spawn_side := WorldState.pending_region_spawn_side\n    # Persist the incoming side before clearing the one-shot transition value.\n    # 必须先保存实际进入侧，再清理一次性切图方向，确保 Continue 能恢复正确落点。\n    WorldState.set_location("village")\n    WorldState.pending_region_spawn_side = "west"', "Village resume spawn-side save order", errors)
    require(village_hub, '2310.0 if spawn_side == "north_gate"', "Village north-gate return spawn", errors)
    require(region_spawn_script, '"res://scenes/village_hub.tscn", "north_gate"', "A2 village return side", errors)
    require(village_hub, '"village_defense_survived"', "Village old-road unlock", errors)
    require(village_hub, 'res://scenes/ash_forest.tscn', "Village old-road route", errors)

    defense = read("scripts/levels/village_defense_demo.gd", errors)
    require(defense, 'WorldState.record_achievement("village_defense_survived")', "Village defense", errors)

    # Keep the hidden-region design table and its actual gate constructors in sync.
    # 将隐藏区域设计表与运行时入口构造函数逐项对齐，避免门槛、来源或落点悄悄漂移。
    topology_path = ROOT / "tools/world_map_topology.json"
    if topology_path.is_file():
        try:
            hidden_topology = json.loads(topology_path.read_text(encoding="utf-8"))
            hidden_gate_functions = {
                "H01": ("village_hub", "_spawn_resonance_well_gate"),
                "H02": ("region", "_spawn_h02_gate"),
                "H03": ("region", "_spawn_h03_gate"),
                "H04": ("region", "_spawn_h04_gate"),
                "H05": ("region", "_spawn_h05_gate"),
                "H06": ("region", "_spawn_h06_gate"),
                "H07": ("region", "_spawn_a9_mirror_gate"),
                "H08": ("region", "_spawn_h08_gate"),
            }
            source_by_kind = {"region": region_script, "village_hub": village_hub}
            for hidden in hidden_topology.get("hidden_regions", []):
                hidden_id = hidden.get("id", "")
                if hidden_id not in hidden_gate_functions:
                    continue
                source_kind, function_name = hidden_gate_functions[hidden_id]
                source_text = source_by_kind[source_kind]
                match = re.search(
                    rf"func {re.escape(function_name)}\([^)]*\).*?(?=\nfunc |\Z)",
                    source_text,
                    re.DOTALL,
                )
                if match is None:
                    errors.append(f"{hidden_id} topology gate audit cannot find {function_name}().")
                    continue
                gate_block = match.group(0)

                def gate_int(property_name: str, default: int = 0) -> int:
                    value = re.search(rf"gate\.{re.escape(property_name)}\s*=\s*(\d+)", gate_block)
                    return int(value.group(1)) if value else default

                def gate_string(property_name: str) -> str:
                    value = re.search(rf'gate\.{re.escape(property_name)}\s*=\s*"([^"]*)"', gate_block)
                    return value.group(1) if value else ""

                def gate_string_array(property_name: str) -> list[str]:
                    value = re.search(
                        rf"gate\.{re.escape(property_name)}\s*=\s*\[(.*?)\]",
                        gate_block,
                        re.DOTALL,
                    )
                    return re.findall(r'"([^"]+)"', value.group(1)) if value else []

                for topology_key, runtime_key in (
                    ("min_resonance", "required_resonance"),
                    ("min_ancient_exposure", "required_ancient_exposure"),
                    ("min_outer_exposure", "required_outer_exposure"),
                ):
                    expected = int(hidden.get(topology_key, 0))
                    actual = gate_int(runtime_key)
                    if actual != expected:
                        errors.append(
                            f"{hidden_id} gate threshold mismatch: topology {topology_key}={expected}, runtime {runtime_key}={actual}."
                        )

                expected_sources = sorted(hidden.get("required_source_ids", []))
                actual_sources = sorted(gate_string_array("required_source_ids"))
                if actual_sources != expected_sources:
                    errors.append(
                        f"{hidden_id} gate source mismatch: topology={expected_sources}, runtime={actual_sources}."
                    )
                minimum_distinct_sources = int(hidden.get("min_distinct_anomaly_sources", 0))
                if minimum_distinct_sources > len(actual_sources):
                    errors.append(
                        f"{hidden_id} requires {minimum_distinct_sources} distinct anomaly sources, "
                        f"but its runtime gate lists only {len(actual_sources)}."
                    )

                expected_outer_resonance = hidden.get("requires_outer_god_resonance", False)
                actual_outer_resonance = bool(re.search(
                    r"gate\.require_outer_god_resonance\s*=\s*true",
                    gate_block,
                ))
                if actual_outer_resonance != expected_outer_resonance:
                    errors.append(
                        f"{hidden_id} outer-god resonance mismatch: topology={expected_outer_resonance}, runtime={actual_outer_resonance}."
                    )

                expected_scene = hidden.get("scene_path", "")
                actual_scene = gate_string("target_scene_path")
                if actual_scene and actual_scene != f"res://{expected_scene}":
                    errors.append(
                        f"{hidden_id} target scene mismatch: topology={expected_scene}, runtime={actual_scene}."
                    )
                expected_location = hidden.get("location_id", "")
                actual_location = gate_string("target_location_id")
                if actual_location != expected_location:
                    errors.append(
                        f"{hidden_id} target location mismatch: topology={expected_location}, runtime={actual_location}."
                    )
        except (json.JSONDecodeError, OSError) as exc:
            errors.append(f"Hidden gate/topology consistency audit could not read topology: {exc}")

    # Keep the topology's local Resonance routes aligned with their runtime construction.
    # 确保拓扑中的局部鸣响路线与运行时构造参数一致。
    try:
        topology_for_local_routes = json.loads((ROOT / "tools/world_map_topology.json").read_text(encoding="utf-8"))
        local_routes = topology_for_local_routes.get("local_resonance_routes", [])
        local_route_count = len(local_routes)
        local_route_ids = [route.get("id") for route in local_routes]
        if len(local_route_ids) != len(set(local_route_ids)):
            errors.append("Topology contains duplicate local Resonance route IDs.")
        known_region_ids = {region.get("id") for region in topology_for_local_routes.get("regions", [])}
        route_by_id = {route.get("id"): route for route in local_routes}
        route_builder_start = region_script.find("func _spawn_local_resonance_routes()")
        route_builder_end = region_script.find("func _on_local_resonance_route_opened", route_builder_start)
        if route_builder_start < 0 or route_builder_end < 0:
            route_builder = ""
            errors.append("Could not isolate the local Resonance route builder for region/identity auditing.")
        else:
            route_builder = region_script[route_builder_start:route_builder_end]
        runtime_route_ids = re.findall(r'route\.route_id\s*=\s*"([^"]+)"', route_builder)
        if len(runtime_route_ids) != len(set(runtime_route_ids)):
            errors.append("Runtime local Resonance route builder contains duplicate route IDs.")
        topology_route_id_set = set(local_route_ids)
        runtime_route_id_set = set(runtime_route_ids)
        if runtime_route_id_set != topology_route_id_set:
            errors.append(
                "Runtime/topology local Resonance route ID mismatch: "
                f"runtime-only={sorted(runtime_route_id_set - topology_route_id_set, key=str)}, "
                f"topology-only={sorted(topology_route_id_set - runtime_route_id_set, key=str)}."
            )
        expected_local_route_ids = ("A2_BELLGRAVE_CANOPY_CROSSING", "A3_THIRD_STREET_ROOFLINE", "A4_OLD_STONE_AQUEDUCT", "A5_BURIED_STANDARD_CROSSING", "A6_SILENT_BELL_SERVICE_WALK", "A7_PRISON_MAINTENANCE_CROSSWALK", "A8_ERASED_REGENT_GALLERY", "A9_RAIN_REFLECTION_ROOFWALK", "A10_CHOIRLESS_UPPER_GALLERY", "A11_SECOND_OBSERVER_SPAN", "A12_CROWN_WALL_WALK")
        if set(expected_local_route_ids) != topology_route_id_set:
            errors.append(
                "Validator/topology local Resonance route list drift: "
                f"validator-only={sorted(set(expected_local_route_ids) - topology_route_id_set, key=str)}, "
                f"topology-only={sorted(topology_route_id_set - set(expected_local_route_ids), key=str)}."
            )
        expected_local_route_prompts = {
            "A2_BELLGRAVE_CANOPY_CROSSING": "E  ANCHOR THE BELLGRAVE CANOPY",
            "A3_THIRD_STREET_ROOFLINE": "E  ANCHOR THE THIRD STREET",
            "A4_OLD_STONE_AQUEDUCT": "E  ANCHOR THE DRY AQUEDUCT",
            "A5_BURIED_STANDARD_CROSSING": "E  RAISE THE BURIED STANDARD",
            "A6_SILENT_BELL_SERVICE_WALK": "E  ANCHOR THE SILENT BELL WALK",
            "A7_PRISON_MAINTENANCE_CROSSWALK": "E  ANCHOR THE PRISON CROSSWALK",
            "A8_ERASED_REGENT_GALLERY": "E  ANCHOR THE ERASED REGENT GALLERY",
            "A9_RAIN_REFLECTION_ROOFWALK": "E  ANCHOR THE RAIN REFLECTION",
            "A10_CHOIRLESS_UPPER_GALLERY": "E  ANCHOR THE CHOIRLESS GALLERY",
            "A11_SECOND_OBSERVER_SPAN": "E  ANCHOR THE OBSERVER SPAN",
            "A12_CROWN_WALL_WALK": "E  ANCHOR THE CROWN WALL",
        }
        expected_local_route_narratives = {
            "A2_BELLGRAVE_CANOPY_CROSSING": "THE BELL'S SECOND SHADOW",
            "A3_THIRD_STREET_ROOFLINE": "THE THIRD STREET HOLDS",
            "A4_OLD_STONE_AQUEDUCT": "THE AQUEDUCT WITHOUT WATER",
            "A5_BURIED_STANDARD_CROSSING": "THE STANDARD THAT OUTLIVED THE ARMY",
            "A6_SILENT_BELL_SERVICE_WALK": "THE SERVICE WALK OF THE SILENT BELL",
            "A7_PRISON_MAINTENANCE_CROSSWALK": "THE CROSSWALK OF UNNUMBERED CELLS",
            "A8_ERASED_REGENT_GALLERY": "THE REGENT WHO NEVER REIGNED",
            "A9_RAIN_REFLECTION_ROOFWALK": "THE HOMES THAT THE RAIN REMEMBERS",
            "A10_CHOIRLESS_UPPER_GALLERY": "THE CHOIR THAT WAS NEVER RECORDED",
            "A11_SECOND_OBSERVER_SPAN": "THE OBSERVER WHO LEFT NO FOOTPRINTS",
            "A12_CROWN_WALL_WALK": "THE WALL BUILT FOR A KING'S ABSENCE",
        }
        for route_id in expected_local_route_ids:
            route_design = route_by_id.get(route_id)
            if route_design is None:
                errors.append(f"Topology is missing local Resonance route {route_id}.")
                continue
            require(route_builder, f'route.route_id = "{route_id}"', f"{route_id} runtime identity", errors)
            route_match = re.search(rf'route\.route_id\s*=\s*"{re.escape(route_id)}"', route_builder)
            if route_match is not None:
                region_branches = re.findall(r'^\s*"([^"]+)":\s*$', route_builder[:route_match.start()], re.MULTILINE)
                runtime_region = region_branches[-1] if region_branches else None
                expected_region = route_design.get("region_id")
                if runtime_region != expected_region:
                    errors.append(
                        f"Local route {route_id} is built under runtime region {runtime_region!r}, "
                        f"but topology assigns it to {expected_region!r}."
                    )
            prompt = expected_local_route_prompts.get(route_id)
            if prompt:
                require(region_script, f'route.prompt_text = "{prompt}"', f"{route_id} interaction prompt", errors)
            narrative_title = expected_local_route_narratives.get(route_id)
            if narrative_title:
                require(region_script, f'"{narrative_title}"', f"{route_id} narrative title", errors)
                require(localization_script, f'"{narrative_title}": {{', f"{route_id} localized narrative title", errors)
                body_match = re.search(
                    rf'"{re.escape(narrative_title)}",\s*"((?:[^"\\]|\\.)*)"',
                    region_script,
                )
                if body_match is None:
                    errors.append(f"{route_id} narrative body could not be located for localization audit.")
                else:
                    require(
                        localization_script,
                        f'"{body_match.group(1)}": {{',
                        f"{route_id} localized narrative body",
                        errors,
                    )
            if prompt:
                require(localization_script, f'"{prompt}": {{', f"{route_id} localized interaction prompt", errors)
            # Every authored route string must have all three non-English translations;
            # English is the source text and remains the fallback.
            # 每条路线的标题、正文和交互提示都必须有简中、繁中、日语译文。
            localized_sources = [value for value in (prompt, narrative_title) if value]
            narrative_section_start = region_script.find("func _on_local_resonance_route_opened")
            if narrative_title and narrative_section_start >= 0:
                body_match = re.search(
                    rf'"{re.escape(narrative_title)}",\s*"((?:[^"\\]|\\.)*)"',
                    region_script[narrative_section_start:],
                )
                if body_match is not None:
                    localized_sources.append(body_match.group(1))
            for source_text in localized_sources:
                entry = re.search(rf'"{re.escape(source_text)}"\s*:\s*\{{([^}}]*)\}}', localization_script)
                if entry is None:
                    errors.append(f"{route_id} is missing a localization entry for {source_text[:70]!r}.")
                    continue
                for language in ("zh_cn", "zh_tw", "ja"):
                    translation = re.search(rf'"{language}"\s*:\s*"([^"]+)"', entry.group(1))
                    if translation is None or not translation.group(1).strip():
                        errors.append(f"{route_id} has no non-empty {language} translation for {source_text[:70]!r}.")
            for key, property_name in (
                ("required_resonance", "required_resonance"),
                ("bridge_start_x", "bridge_start_x"),
                ("bridge_end_x", "bridge_end_x"),
                ("bridge_y", "bridge_y"),
            ):
                expected_value = route_design.get(key)
                if expected_value is None:
                    errors.append(f"Topology local route {route_id} is missing {key}.")
                    continue
                if key == "required_resonance":
                    literal = str(int(expected_value))
                else:
                    literal = f"{float(expected_value):.1f}"
                require(
                    region_script,
                    f"route.{property_name} = {literal}",
                    f"{route_id} {property_name} matches topology",
                    errors,
                )
            if route_design.get("requires_resonance_sight") is not True:
                errors.append(f"Topology local route {route_id} must require Resonance Sight.")
            if route_design.get("persistent_on_open") is not True:
                errors.append(f"Topology local route {route_id} must persist after opening.")
            if route_design.get("region_id") not in known_region_ids:
                errors.append(f"Topology local route {route_id} references unknown region {route_design.get('region_id')}.")
            geometry_valid = True
            try:
                start_x = float(route_design.get("bridge_start_x"))
                end_x = float(route_design.get("bridge_end_x"))
                bridge_y = float(route_design.get("bridge_y"))
                threshold = int(route_design.get("required_resonance"))
                if end_x <= start_x:
                    errors.append(f"Topology local route {route_id} must have bridge_end_x > bridge_start_x.")
                    geometry_valid = False
                if not 0 <= threshold <= 100:
                    errors.append(f"Topology local route {route_id} has an invalid Resonance threshold.")
                    geometry_valid = False
                if not 0.0 <= bridge_y <= 540.0:
                    errors.append(f"Topology local route {route_id} has a bridge elevation outside the graybox floor bounds.")
                    geometry_valid = False
            except (TypeError, ValueError):
                errors.append(f"Topology local route {route_id} has non-numeric geometry or threshold values.")
                geometry_valid = False
            if not geometry_valid:
                continue
            route_platforms = platforms_by_region.get(route_design.get("region_id"), [])
            if not route_platforms:
                errors.append(f"Local route {route_id} has no parsed platform layout for {route_design.get('region_id')}.")
            else:
                bridge_y = float(route_design.get("bridge_y", 0.0))
                for endpoint_key in ("bridge_start_x", "bridge_end_x"):
                    endpoint_x = float(route_design.get(endpoint_key, 0.0))
                    nearest = min(
                        (
                            (
                                max(0.0, x - endpoint_x, endpoint_x - (x + width)),
                                abs(y - bridge_y),
                            )
                            for x, y, width, _height in route_platforms
                        ),
                        key=lambda gap: gap[0] ** 2 + gap[1] ** 2,
                    )
                    if nearest[0] > 100.0 or nearest[1] > 45.0:
                        errors.append(
                            f"Local route {route_id} {endpoint_key} is detached from nearby platforms "
                            f"(horizontal gap={nearest[0]:g}, vertical gap={nearest[1]:g})."
                        )
                # A bridge may touch a platform edge, but should not be embedded through its collision body.
                # 桥体可以与平台边缘相接，但不应大面积穿进平台碰撞体。
                for x, y, width, height in route_platforms:
                    horizontal_overlap = min(end_x, x + width) - max(start_x, x)
                    vertical_overlap = min(bridge_y + 18.0, y + height) - max(bridge_y, y)
                    if horizontal_overlap > 0.0 and vertical_overlap > 2.0:
                        errors.append(
                            f"Local route {route_id} overlaps a platform collision body by "
                            f"{vertical_overlap:g}px vertically across {horizontal_overlap:g}px."
                        )
    except (json.JSONDecodeError, OSError) as exc:
        errors.append(f"Local Resonance route topology audit could not read topology: {exc}")

    if errors:
        print("GRAYBOX SCENE WIRING CHECK FAILED")
        for error in errors:
            print(f" - {error}")
        return 1

    print("GRAYBOX SCENE WIRING STATIC CHECK PASSED")
    print(" - A2-A13 plus H01-H08 scenes have scripts and resume mappings.")
    print(" - The R01-R08 anomaly source chain is present.")
    print(" - H01-H08 plus C15/C19 gates use saved discovery/open/entry state and progression conditions.")
    print(f" - Platform reachability estimate: {platform_audit_regions} regions, {platform_audit_count} platforms.")
    print(f" - Local resonance route contract: {local_route_count} routes; IDs, prompts, narratives, endpoint proximity, collision overlap, sight gating, and persistence checked.")
    print(" - C15/C19 enter A11 from separate sides; H08 and the A11 deep-dream gate converge on A13 after physical union.")
    print("NOTE: Godot runtime/collision/input validation is still required.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
