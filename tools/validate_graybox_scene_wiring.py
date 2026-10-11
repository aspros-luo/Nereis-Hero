#!/usr/bin/env python3
"""Static wiring checks for the A0-A12 graybox, H01-H08, and world-map route contracts.

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
    "scripts/world/resonance_source_clue.gd",
    "scripts/world/resonance_secret_gate.gd",
    "scripts/world/interaction_door.gd",
    "scripts/world/resonance_local_route.gd",
    "scripts/levels/village_hub.gd",
    "scripts/levels/village_defense_demo.gd",
    "scripts/core/world_state.gd",
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
    platform_audit_regions = 0
    platform_audit_count = 0
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
            h08 = next((region for region in hidden_regions if region.get("id") == "H08"), None)
            h08_exit = h08.get("secondary_exit", {}) if h08 else {}
            if h08_exit.get("unlock_condition") != "physical_union_complete_then_route_candidate_selects_ending":
                errors.append("Topology H08 ending exit must match the runtime physical-union gate and delegate ending choice to the evaluator.")
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
    require(world_state, 'resume_spawn_side = requested_spawn_side', "WorldState location save", errors)
    require(world_state, 'resume_spawn_side.length() > 64', "WorldState spawn-side input guard", errors)
    require(world_state, "pending_region_spawn_side = \"west\"\n    resume_spawn_side = \"west\"", "WorldState new-game reset", errors)
    boot_script = read("scripts/core/boot.gd", errors)
    require(boot_script, "WorldState.pending_region_spawn_side = WorldState.resume_spawn_side", "Continue spawn restore", errors)
    region_spawn_script = read("scripts/levels/greybox_world_region.gd", errors)
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

    region_script = read("scripts/levels/greybox_world_region.gd", errors)
    require(region_script, "[NEREIS][MAP][SPAWN] region=%s", "Map spawn Debug log", errors)
    require(region_script, "func _spawn_hero(spawn_x: float) -> void:", "Region-local death checkpoint setup", errors)
    require(region_script, "WorldState.set_checkpoint(hero.global_position)", "Region-local death checkpoint", errors)
    require(region_script, "Keep death recovery inside the current region", "Region-local death checkpoint rationale", errors)
    require(region_script, "[NEREIS][MAP][EXIT] from=%s", "Map exit Debug log", errors)
    require(region_script, 'const REST_POINT_SCRIPT = preload("res://scripts/world/rest_point.gd")', "Regional rest point script", errors)
    require(region_script, "func _spawn_region_rest_point() -> void:", "Regional rest point builder", errors)
    require(region_script, 'rest.rest_id = "rest_%s" % region_id', "Regional rest point identity", errors)
    local_route_script = read("scripts/world/resonance_local_route.gd", errors)
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
    require(local_route_script, "bridge_body.queue_free()", "Temporary bridge collision removal", errors)
    require(local_route_script, "func _hero_over_bridge() -> bool:", "Local route protects a Hero standing on a temporary bridge", errors)
    require(local_route_script, "revealed or opened_permanently or _hero_over_bridge()", "Bridge collision remains while the Hero occupies it", errors)
    require(local_route_script, "INTERACTION_FOCUS_SCRIPT.is_focused(self)", "Local route uses shared interaction focus", errors)
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
    require(village_route_script, "func _spawn_village_rest_point() -> void:", "A1 hearth rest point", errors)
    require(village_route_script, 'rest.rest_id = "rest_A1_village_hearth"', "A1 rest point persistence ID", errors)
    require(village_route_script, '"village_defense_survived" in WorldState.achievement_flags', "A1 drainage gate", errors)
    require(village_route_script, 'WorldState.pending_region_spawn_side = "village_city_cut"', "A1 to A3 spawn mapping", errors)
    require(village_route_script, "func _create_village_rooftop_route() -> void:", "A1 rooftop route builder", errors)
    require(village_route_script, "Rect2(220, 445, 90, 16)", "A1 rooftop first ledge", errors)
    require(village_route_script, "Rect2(1710, 270, 110, 16)", "A1 rooftop route over tavern", errors)
    require(region_script, 'if region_id == "A3" and side == "village_city_cut"', "A3 alternate entrance spawn", errors)
    require(region_script, '520.0, "E  RETURN THROUGH THE OLD DRAIN"', "A3 return-to-village exit", errors)
    require(region_script, "_add_platform(Rect2(760, 370, 110, 18))", "A2 forest canopy route", errors)
    require(region_script, "_add_platform(Rect2(450, 400, 110, 18))", "A3 rooftop loop", errors)
    require(region_script, "_add_platform(Rect2(1650, 310, 130, 18))", "A4 pipe-walk route", errors)
    require(region_script, "_add_platform(Rect2(420, 420, 120, 18))", "A5 battlefield parapet route", errors)
    require(region_script, "_add_platform(Rect2(1250, 270, 120, 18))", "A6 cloister balcony route", errors)
    require(region_script, "_add_platform(Rect2(1280, 320, 110, 18))", "A7 maintenance catwalk", errors)
    require(region_script, "_add_platform(Rect2(1240, 310, 110, 18))", "A8 upper burial gallery", errors)
    require(region_script, "_add_platform(Rect2(390, 395, 115, 18))", "A9 outer-ring roof loop", errors)
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
        'E  OPEN THE INSPECTION HATCH',
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
        '"E  OPEN THE OLD PILGRIM HIGHROAD"',
        '"E  RETURN TO THE BATTLEFIELD"',
        '"reached_A5_and_opened_old_pilgrim_highroad" in WorldState.achievement_flags',
        '"reached_A5_and_opened_old_pilgrim_highroad", "E  RETURN BY THE OLD PILGRIM HIGHROAD"',
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
        require(a3_exit_block, '"E  RETURN THROUGH THE OLD DRAIN"', "C24 city-side return door", errors)
        if a3_exit_block.find('"E  RETURN THROUGH THE OLD DRAIN"') < a3_exit_block.find('if "village_defense_survived" in WorldState.achievement_flags:'):
            fail(errors, "C24 A3 return door must remain inside the village-defense condition.")

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
        ("A2", '"E  ENTER THE FORGOTTEN CITY"', "C03 A2-to-A3"),
        ("A3", '"E  RETURN TO PILGRIM ROAD"', "C03 A3-to-A2"),
        ("A3", '"E  FOLLOW THE BATTLEFIELD ROAD"', "C08 A3-to-A5"),
        ("A5", '"E  RETURN TO THE FORGOTTEN CITY"', "C08 A5-to-A3"),
        ("A5", '"E  ENTER THE MONASTERY"', "C09 A5-to-A6"),
        ("A6", '"E  RETURN TO THE BATTLEFIELD"', "C09 A6-to-A5"),
        ("A6", '"E  DESCEND INTO THE PRISON"', "C11 A6-to-A7"),
        ("A7", '"E  RETURN TO THE MONASTERY"', "C11 A7-to-A6"),
        ("A7", '"E  ENTER THE ROYAL TOMB"', "C13 A7-to-A8"),
        ("A8", '"E  RETURN TO THE PRISON"', "C13 A8-to-A7"),
        ("A8", '"E  ENTER THE ROYAL OUTER RING"', "C14 A8-to-A9"),
        ("A9", '"E  RETURN TO THE ROYAL TOMB"', "C14 A9-to-A8"),
    ]
    for source_region, contract, connection_label in main_route_contracts:
        require(route_blocks.get(source_region, ""), contract, connection_label, errors)

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
        '"E  CLIMB TO THE GREAT CATHEDRAL"',
        'res://scenes/grand_cathedral.tscn", "west"',
    ]:
        require(a9_route_block, contract, "C17 outer-ring-to-cathedral main route", errors)
    for contract in [
        '"E  ENTER THE INNER CITY"',
        'res://scenes/inner_city.tscn", "west"',
    ]:
        require(a10_route_block, contract, "C20 cathedral-to-inner-city main route", errors)
    require(a12_route_block, '"E  RETURN TO THE CATHEDRAL"', "C20 inner-city return route", errors)
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
        require(a6_exit_block, '"E  OPEN THE BELL TOWER DROP"', "C10 monastery shortcut", errors)
        require(a6_exit_block, '"opened_bell_tower_drop"', "C10 monastery shortcut", errors)
        if 'if WorldState.is_hidden_path_opened("H05")' in a6_exit_block:
            fail(errors, "C10 monastery shortcut must not depend on the optional H05 secret path.")
    if "1830.0, \"E  RETURN TO THE SILENT BELL WINDOW\"" in region_script:
        fail(errors, "H05 return door at x=1830 is too close to the C10 door at x=1710.")
    if "1950.0, \"E  RETURN TO THE SILENT BELL WINDOW\"" in region_script:
        fail(errors, "H05 return door at x=1950 overlaps the A3 rest-point interaction radius.")
    require(region_script, '1900.0, "E  RETURN TO THE SILENT BELL WINDOW"', "H05/C10 interaction spacing", errors)
    require(region_script, '1250.0, "E  OPEN THE OLD SERVICE DOOR"', "A9 H03/C18 interaction spacing", errors)
    if '1020.0, "E  OPEN THE OLD SERVICE DOOR"' in region_script:
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
            '"E  RETURN TO VILLAGE"',
            '"reached_A4_via_A3" in WorldState.achievement_flags',
            'WorldState.is_hidden_path_opened("H01")',
            '"sewer_reservoir"',
        ],
        "H02": [
            '"E  RETURN TO THE PILGRIM ROAD"',
            '"opened_old_bell_tower_connection" in WorldState.achievement_flags',
            '"old_battlefield"',
        ],
        "H03": [
            '"E  RETURN TO THE FORGOTTEN CITY"',
            '"opened_old_service_door" in WorldState.achievement_flags',
            '"royal_outer_ring"',
        ],
        "H04": [
            '"E  RETURN TO THE RESERVOIR"',
            '"opened_royal_tomb_side_door" in WorldState.achievement_flags',
            '"royal_tomb"',
        ],
        "H05": [
            '"E  RETURN TO THE MONASTERY"',
            '"opened_bell_tower_drop" in WorldState.achievement_flags',
            '"forgotten_city"',
        ],
        "H06": [
            '"E  RETURN TO THE ROYAL TOMB"',
            '"opened_royal_transport_side_door" in WorldState.achievement_flags',
            '"royal_outer_ring"',
        ],
        "H07": [
            '"E  RETURN THROUGH THE PUDDLES"',
            '"opened_mirror_street_side_gate" in WorldState.achievement_flags',
            '"inner_city"',
        ],
        "H08": [
            '"E  RETURN TO THE DEPTHS"',
            'if WorldState.physical_union_complete:',
            'ending_gate.call("route_candidate")',
            'var ending_location := "church_final_demo"',
            'elif ending_scene_path.ends_with("ending_fire_demo.tscn"):',
        ],
    }
    exits_start = region_script.find("func _spawn_region_exits")
    for hidden_id, contracts in hidden_exit_contracts.items():
        block_start = region_script.find(f'        "{hidden_id}":', exits_start)
        block_end = region_script.find("\n        \"", block_start + 12) if block_start >= 0 else -1
        block = region_script[block_start:block_end] if block_start >= 0 and block_end > block_start else ""
        if not block:
            fail(errors, f"{hidden_id} hidden-region exit block is missing or malformed.")
            continue
        for contract in contracts:
            require(block, contract, f"{hidden_id} hidden-region return contract", errors)

    # Spawn-side contracts keep the Hero clear of the very door/gate used to enter a region.
    # 出口出生点必须避开刚刚使用的门与隐藏入口，防止落地即重新触发 E 交互。
    spawn_contracts = [
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
        ('if region_id == "A3" and side == "old_lift":', "return 1060.0"),
        ('if region_id == "A6" and side == "bell_drop":', "return 1900.0"),
        ('if region_id == "A9" and side == "royal_drain":', "return 810.0"),
        ('if region_id == "A9" and side == "old_lift":', "return 610.0"),
        ('if region_id == "A9" and side == "inner_city_side_gate":', "return 980.0"),
        ('if region_id == "A12" and side == "inner_city_side_gate":', "return 650.0"),
        ('if region_id == "A3" and side == "third_street_gate":', "return map_width - 500.0"),
        ('if region_id == "A4" and side == "water_reflection_gate":', "return 1550.0"),
        ('if region_id == "A4" and side == "east":', "return map_width - 360.0"),
        ('if region_id == "A4" and side == "prison_tunnel":', "return 1160.0"),
        ('if region_id == "A7" and side == "supply_tunnel":', "return 610.0"),
        ('if region_id == "A4" and side == "royal_tomb_waterway":', "return 1160.0"),
        ('if region_id == "A4" and side == "royal_drain":', "return 1600.0"),
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
    ]:
        require(interaction_door, contract, "One-time inspection hatch", errors)

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
        local_route_ids = [route.get("id") for route in local_routes]
        if len(local_route_ids) != len(set(local_route_ids)):
            errors.append("Topology contains duplicate local Resonance route IDs.")
        known_region_ids = {region.get("id") for region in topology_for_local_routes.get("regions", [])}
        route_by_id = {route.get("id"): route for route in local_routes}
        expected_local_route_ids = ("A3_THIRD_STREET_ROOFLINE", "A4_OLD_STONE_AQUEDUCT", "A5_BURIED_STANDARD_CROSSING", "A6_SILENT_BELL_SERVICE_WALK", "A7_PRISON_MAINTENANCE_CROSSWALK", "A8_ERASED_REGENT_GALLERY", "A9_RAIN_REFLECTION_ROOFWALK", "A10_CHOIRLESS_UPPER_GALLERY", "A11_SECOND_OBSERVER_SPAN", "A12_CROWN_WALL_WALK")
        for route_id in expected_local_route_ids:
            route_design = route_by_id.get(route_id)
            if route_design is None:
                errors.append(f"Topology is missing local Resonance route {route_id}.")
                continue
            require(region_script, f'route.route_id = "{route_id}"', f"{route_id} runtime identity", errors)
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
            try:
                start_x = float(route_design.get("bridge_start_x"))
                end_x = float(route_design.get("bridge_end_x"))
                bridge_y = float(route_design.get("bridge_y"))
                threshold = int(route_design.get("required_resonance"))
                if end_x <= start_x:
                    errors.append(f"Topology local route {route_id} must have bridge_end_x > bridge_start_x.")
                if not 0 <= threshold <= 100:
                    errors.append(f"Topology local route {route_id} has an invalid Resonance threshold.")
                if not 0.0 <= bridge_y <= 540.0:
                    errors.append(f"Topology local route {route_id} has a bridge elevation outside the graybox floor bounds.")
            except (TypeError, ValueError):
                errors.append(f"Topology local route {route_id} has non-numeric geometry or threshold values.")
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
    except (json.JSONDecodeError, OSError) as exc:
        errors.append(f"Local Resonance route topology audit could not read topology: {exc}")

    if errors:
        print("GRAYBOX SCENE WIRING CHECK FAILED")
        for error in errors:
            print(f" - {error}")
        return 1

    print("GRAYBOX SCENE WIRING STATIC CHECK PASSED")
    print(" - A2-A12 plus H01-H08 scenes have scripts and resume mappings.")
    print(" - The R01-R08 anomaly source chain is present.")
    print(" - H01-H08 plus C15/C19 gates use saved discovery/open/entry state and progression conditions.")
    print(f" - Platform reachability estimate: {platform_audit_regions} regions, {platform_audit_count} platforms.")
    print(" - C15 enters A11 from A8; C19 is the alternate A10 entry; H08 ending exit requires physical union.")
    print("NOTE: Godot runtime/collision/input validation is still required.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
