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
    "scripts/levels/royal_tomb_boss.gd",
    "scenes/royal_tomb_boss.tscn",
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
    "scripts/core/world_event_director.gd",
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
    item_catalog = read("scripts/core/item_catalog.gd", errors)
    for item_id in ("bell_tower_winch_key", "charred_church_seal", "old_pilgrim_waybill", "third_street_survey", "royal_mortuary_register"):
        require(item_catalog, f'"{item_id}"', "scripts/core/item_catalog.gd", errors)
        require(region_script, f'"item_id": "{item_id}"', "scripts/levels/greybox_world_region.gd", errors)
    require(region_script, "func _spawn_region_item_pickups() -> void:", "scripts/levels/greybox_world_region.gd", errors)
    require(region_script, 'region_id not in ["A2", "A3"]', "A2/A3 first-entry popups are replaced by in-world discovery", errors)
    require(region_script, '"anomaly_bell_retiming"', "A2 retains its inspectable bell evidence", errors)
    require(region_script, '"anomaly_erased_street_sign"', "A3 retains its inspectable erased-street evidence", errors)
    require(region_script, '"defeated_A2_Cultist_01"', "scripts/levels/greybox_world_region.gd", errors)
    require(region_script, '"combat_reward_a2_cultist_seal"', "scripts/levels/greybox_world_region.gd", errors)
    require(region_script, '"A6_BellWarden_01"', "scripts/levels/greybox_world_region.gd", errors)
    require(region_script, '"combat_reward_a6_bell_winch_key"', "scripts/levels/greybox_world_region.gd", errors)
    require(region_script, "func _refresh_a6_bell_shortcut() -> void:", "scripts/levels/greybox_world_region.gd", errors)
    require(region_script, '"bell_tower_winch_key"', "scripts/levels/greybox_world_region.gd", errors)
    require(region_script, "\t_spawn_region_item_pickups()", "scripts/levels/greybox_world_region.gd", errors)

    platform_audit_regions = 0
    platform_audit_count = 0
    local_route_count = 0
    platforms_by_region: dict[str, list[tuple[float, float, float, float]]] = {}

    # The topology metadata must agree with the playable C10 shortcut.
    # 世界拓扑元数据必须与实际可玩的 C10 钟塔捷径保持一致。
    topology_path = ROOT / "tools/world_map_topology.json"
    topology: dict = {}
    if not topology_path.is_file():
        errors.append("Missing file: tools/world_map_topology.json")
    else:
        try:
            topology = json.loads(topology_path.read_text(encoding="utf-8"))
            hidden_regions = topology.get("hidden_regions", [])
            c10 = next((connection for connection in topology.get("connections", []) if connection.get("id") == "C10"), None)
            c10_access = c10.get("access_prerequisite", {}) if c10 else {}
            if c10_access.get("combat_flag") != "defeated_A6_BellWarden_01" or c10_access.get("item_id") != "bell_tower_winch_key":
                errors.append("Topology C10 must require the A6 bell warden and its winch key.")
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
            if h08_exit.get("unlock_condition") != "ending_candidate_is_not_human_grave_based_on_resonance_truth_anchors_and_exploration":
                errors.append("Topology H08 exit must use the shared ending evaluator, not physical-union state.")
            c21 = next((edge for edge in topology.get("connections", []) if edge.get("id") == "C21"), None)
            c22 = next((edge for edge in topology.get("connections", []) if edge.get("id") == "C22"), None)
            if not c21 or c21.get("unlock_condition") != "ending_candidate_is_not_human_grave_based_on_resonance_truth_anchors_and_exploration" or c21.get("to") != "A13":
                errors.append("C21 must use the shared resonance/truth-anchor/exploration ending evaluator.")
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

            # Full-map structural audit: validate the hierarchy, every inter-region edge,
            # and the final directed graph in one pass (not a hand-picked route subset).
            # 全地图结构审计：一次性检查层级、全部跨区连接与最终有向可达图，而非只抽查部分路线。
            macro_regions = topology.get("macro_regions", [])
            macro_ids = [item.get("id") for item in macro_regions]
            if len(macro_ids) != len(set(macro_ids)):
                errors.append("World map topology contains duplicate macro-region IDs.")
            macro_memberships: dict[str, list[str]] = {region_id: [] for region_id in region_id_set}
            for macro in macro_regions:
                for member in macro.get("regions", []):
                    if member not in region_id_set:
                        errors.append(f"Macro-region {macro.get('id', '<missing>')} references unknown region {member}.")
                    else:
                        macro_memberships[member].append(str(macro.get("id", "<missing>")))
            unassigned_regions = sorted(region_id for region_id, owners in macro_memberships.items() if len(owners) == 0)
            multiply_assigned_regions = sorted(region_id for region_id, owners in macro_memberships.items() if len(owners) > 1)
            if unassigned_regions:
                errors.append(f"Regions missing macro-region ownership: {unassigned_regions}.")
            if multiply_assigned_regions:
                errors.append(f"Regions assigned to multiple macro-regions: {multiply_assigned_regions}.")

            subregions = topology.get("subregions", [])
            subregion_ids = [item.get("id") for item in subregions]
            if len(subregion_ids) != len(set(subregion_ids)):
                errors.append("World map topology contains duplicate subregion IDs.")
            subregion_by_id = {item.get("id"): item for item in subregions}
            for subregion in subregions:
                parent = subregion.get("parent_region")
                if parent not in region_id_set:
                    errors.append(f"Subregion {subregion.get('id', '<missing>')} references unknown parent region {parent}.")
            intra_connections = topology.get("intra_region_connections", [])
            intra_ids = [item.get("id") for item in intra_connections]
            if len(intra_ids) != len(set(intra_ids)):
                errors.append("World map topology contains duplicate intra-region connection IDs.")
            for edge in intra_connections:
                edge_id = edge.get("id", "<missing>")
                source = subregion_by_id.get(edge.get("from"))
                target = subregion_by_id.get(edge.get("to"))
                if source is None or target is None:
                    errors.append(f"Intra-region connection {edge_id} references an unknown subregion.")
                    continue
                if source.get("parent_region") != target.get("parent_region"):
                    errors.append(
                        f"Intra-region connection {edge_id} crosses region parents "
                        f"{source.get('parent_region')} -> {target.get('parent_region')}."
                    )
                if edge.get("travel") not in ("both", "one_way"):
                    errors.append(f"Intra-region connection {edge_id} has invalid travel direction {edge.get('travel')!r}.")
                if edge.get("initial_state") not in ("open", "blocked", "locked", "sealed", "unpowered", "broken"):
                    errors.append(f"Intra-region connection {edge_id} has unknown initial state {edge.get('initial_state')!r}.")

            elevator_contracts = topology.get("elevators", [])
            elevator_ids = [item.get("id") for item in elevator_contracts]
            if len(elevator_ids) != len(set(elevator_ids)):
                errors.append("World map topology contains duplicate elevator IDs.")
            for elevator in elevator_contracts:
                elevator_id = elevator.get("id", "<missing>")
                for endpoint in ("from", "to"):
                    if elevator.get(endpoint) not in subregion_by_id:
                        errors.append(f"Elevator {elevator_id} references unknown {endpoint} subregion {elevator.get(endpoint)!r}.")
                if elevator.get("from") == elevator.get("to"):
                    errors.append(f"Elevator {elevator_id} must connect two distinct subregions.")
                if not elevator.get("unlock_condition") or not elevator.get("safety"):
                    errors.append(f"Elevator {elevator_id} is missing its unlock or safety contract.")

            # Every edge must have valid access semantics and a meaningful source for any locked route.
            # 每条跨区边都必须有合法方向；锁定路线必须写明解锁条件与开启侧。
            allowed_initial_access = {"from_to", "both", "blocked"}
            allowed_final_direction = {"forward", "both"}
            for edge in connections:
                edge_id = edge.get("id", "<missing>")
                initial_access = edge.get("initial_access")
                final_direction = edge.get("final_direction")
                if initial_access not in allowed_initial_access:
                    errors.append(f"Connection {edge_id} has invalid initial_access {initial_access!r}.")
                if final_direction not in allowed_final_direction:
                    errors.append(f"Connection {edge_id} has invalid final_direction {final_direction!r}.")
                if initial_access == "blocked" and not edge.get("unlock_condition"):
                    errors.append(f"Blocked connection {edge_id} has no unlock_condition.")
                opens_from = edge.get("opens_from", "")
                if opens_from and opens_from not in (edge.get("from"), edge.get("to")):
                    errors.append(f"Connection {edge_id} opens_from={opens_from} is not one of its endpoints.")
                spatial = edge.get("spatial_contract", {})
                for anchor_key in ("from_region_anchor", "to_region_anchor", "return_spawn", "from_region_spawn", "to_region_spawn"):
                    anchor = spatial.get(anchor_key)
                    if not isinstance(anchor, dict):
                        continue
                    anchor_region = anchor.get("region")
                    if anchor_region and anchor_region not in region_id_set:
                        errors.append(f"Connection {edge_id} {anchor_key} references unknown region {anchor_region}.")
                    for coordinate_key in ("x", "y_offset"):
                        if coordinate_key not in anchor:
                            continue
                        try:
                            coordinate = float(anchor[coordinate_key])
                        except (TypeError, ValueError):
                            errors.append(f"Connection {edge_id} {anchor_key}.{coordinate_key} is not numeric.")
                            continue
                        if coordinate_key == "x" and not 0.0 <= coordinate <= (3600.0 if anchor.get("region") == "A2" else 2600.0):
                            errors.append(f"Connection {edge_id} {anchor_key}.x={coordinate:g} is outside the authored map width for {anchor.get('region')}.")
                        if coordinate_key == "y_offset" and not -300.0 <= coordinate <= 0.0:
                            errors.append(f"Connection {edge_id} {anchor_key}.y_offset={coordinate:g} is outside the supported vertical contract.")

            # Treat all unlocks as available and verify the final directed map is navigable from the prologue.
            # 仅在最终图检查中假定所有门槛已解锁，确认从序章出发可沿最终方向到达全部 A0-A13 区域。
            final_reachable = {"A0"} if "A0" in region_id_set else set()
            changed = True
            while changed:
                changed = False
                for edge in connections:
                    source, target = edge.get("from"), edge.get("to")
                    direction = edge.get("final_direction")
                    if source in final_reachable and target not in final_reachable:
                        final_reachable.add(target)
                        changed = True
                    if direction == "both" and target in final_reachable and source not in final_reachable:
                        final_reachable.add(source)
                        changed = True
            final_unreachable = sorted(region_id_set - final_reachable)
            if final_unreachable:
                errors.append(f"Final directed world map is unreachable from A0: {final_unreachable}.")

            canonical_hidden_ids = {item.get("id") for item in hidden_regions}
            if canonical_hidden_ids != {f"H{index:02d}" for index in range(1, 9)}:
                errors.append(
                    "Canonical hidden-region inventory must remain exactly H01-H08; "
                    f"found {sorted(str(item) for item in canonical_hidden_ids)}."
                )
            provisional_ids = {item.get("id") for item in topology.get("provisional_regions", [])}
            if "H09" in canonical_hidden_ids or ("H09" in provisional_ids and any(
                item.get("id") == "H09" and item.get("story_canon") is True
                for item in topology.get("provisional_regions", [])
            )):
                errors.append("H09 must remain provisional and non-canonical until narrative approval.")
            if len(regions) != 14 or len(connections) != 24 or len(subregions) != 78 or len(intra_connections) != 73 or len(elevator_contracts) != 8:
                errors.append(
                    "World map inventory drift: expected 14 regions / 24 C-connections / "
                    "78 subregions / 73 intra-region connections / 8 elevator contracts, got "
                    f"{len(regions)} / {len(connections)} / {len(subregions)} / "
                    f"{len(intra_connections)} / {len(elevator_contracts)}."
                )

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
    require(world_state, "[%d/23]", "Natural map test region total", errors)
    require(world_state, 'resume_spawn_side = requested_spawn_side', "WorldState location save", errors)
    require(world_state, 'resume_spawn_side.length() > 64', "WorldState spawn-side input guard", errors)
    require(world_state, '"royal_tomb_boss":', "Royal tomb boss Continue location", errors)
    require(world_state, 'return "res://scenes/royal_tomb_boss.tscn"', "Royal tomb boss Continue scene", errors)
    boss_arena_script = read("scripts/levels/royal_tomb_boss.gd", errors)
    for contract in [
        'const BOSS_FLAG := "defeated_royal_tomb_guardian"',
        'WorldState.set_location("royal_tomb_boss")',
        'boss.set("boss_display_name", "王墓守墓者")',
        'boss.set("persist_global_boss_defeat", false)',
        'boss.connect("defeated", Callable(self, "_on_boss_defeated"))',
        'boss.connect("phase_changed", Callable(self, "_on_boss_phase_changed"))',
        'WorldState.record_achievement(BOSS_FLAG)',
        'func _on_boss_phase_changed(phase: int)',
        'hud.call("show_phase_two")',
        'func _on_hero_defeated()',
        'func _respawn_boss_after_death()',
        'WorldState.pending_region_spawn_side = "boss_return"',
        'WorldState.set_location("royal_tomb")',
        'SceneTransition.fade_to_scene("res://scenes/royal_tomb.tscn")',
        'func _spawn_return_door()',
    ]:
        require(boss_arena_script, contract, "Royal tomb Boss arena lifecycle", errors)
    boss_scene = read("scenes/royal_tomb_boss.tscn", errors)
    require(boss_scene, 'path="res://scripts/levels/royal_tomb_boss.gd"', "Royal tomb Boss scene script", errors)
    ashen_knight_script = read("scripts/enemies/ashen_knight.gd", errors)
    require(ashen_knight_script, 'var boss_display_name := "灰烬骑士"', "Reusable Boss display name", errors)
    require(ashen_knight_script, "var max_health := 240", "Reusable Boss max-health contract", errors)
    require(ashen_knight_script, "var phase := 1", "Reusable Boss phase HUD contract", errors)
    require(ashen_knight_script, "phase = 2", "Reusable Boss second phase contract", errors)
    require(ashen_knight_script, 'var visual_theme := "ashen"', "Reusable Boss visual theme contract", errors)
    require(ashen_knight_script, "var persist_global_boss_defeat := true", "Reusable Boss legacy flag isolation", errors)
    require(ashen_knight_script, 'if persist_global_boss_defeat:', "Reusable Boss victory persistence switch", errors)
    hud_script = read("scripts/ui/game_hud.gd", errors)
    require(hud_script, 'int(boss.get("health")) <= 0', "Encounter-local Boss HUD visibility", errors)

    require(world_state, "pending_region_spawn_side = \"west\"\n    resume_spawn_side = \"west\"", "WorldState new-game reset", errors)
    boot_script = read("scripts/core/boot.gd", errors)
    require(boot_script, "WorldState.pending_region_spawn_side = WorldState.resume_spawn_side", "Continue spawn restore", errors)
    require(boot_script, "res://scenes/world_map_test_menu.tscn", "Boot macro-map acceptance entry", errors)
    map_test_script = read("scripts/core/world_map_test_menu.gd", errors)
    require(map_test_script, "WorldState.begin_natural_test_session()", "Macro-map visit tracking", errors)
    require(map_test_script, "WorldState.finish_natural_test_session()", "Whole-map coverage summary", errors)
    require(world_state, "func finish_natural_test_session() -> void:", "Whole-map coverage evaluator", errors)
    require(world_state, '"OB01"', "Optional boss included in full-map coverage", errors)
    require(world_state, '"INCOMPLETE"', "Incomplete whole-map coverage is reported", errors)
    require(map_test_script, "WorldState.physical_union_complete = true", "Macro-map route test flags", errors)
    require(map_test_script, "res://scenes/terminal_anomaly.tscn", "A13 acceptance destination", errors)
    require(map_test_script, "res://scenes/primordial_hollow.tscn", "H08 acceptance destination", errors)
    require(map_test_script, '"id":"OB01"', "Royal tomb boss isolated acceptance entry", errors)
    require(world_state, '"res://scenes/royal_tomb_boss.tscn": "OB01"', "Royal tomb boss natural-test coverage mapping", errors)
    require(world_state, "[%d/23]", "Natural-test coverage count includes optional boss arena", errors)
    require(map_test_script, "WorldState.debug_map_test_mode = true", "Save-safe macro-map test mode", errors)
    region_spawn_script = read("scripts/levels/greybox_world_region.gd", errors)
    require(region_spawn_script, "KEY_F6", "Macro-map launcher return shortcut", errors)
    require(region_spawn_script, "WorldState.pending_region_spawn_side = spawn_side", "Graybox incoming spawn-side capture", errors)
    require(region_spawn_script, "WorldState.set_location(target_location)", "Graybox spawn-side persistence", errors)
    if region_spawn_script.find("WorldState.pending_region_spawn_side = spawn_side") > region_spawn_script.find("WorldState.set_location(target_location)"):
        fail(errors, "Graybox transition must persist the incoming spawn side before saving the destination location.")
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

    # Optional boss encounters are not C-edges, but still require a traceable entry, victory, death-reset, and return contract.
    # 可选 Boss 遭遇不计入跨区 C 边，但入口、胜利、死亡重置和回程必须可追踪。
    encounter_contracts = topology.get("optional_encounters", [])
    royal_encounter = next((item for item in encounter_contracts if item.get("id") == "OB01"), None)
    if royal_encounter is None:
        errors.append("Topology must register optional encounter OB01 for the royal tomb guardian.")
    else:
        require(str(royal_encounter), "defeated_royal_tomb_guardian", "Topology OB01 victory contract", errors)
        require(str(royal_encounter), "boss_return", "Topology OB01 return contract", errors)
        require(str(royal_encounter), "static_contract_added_runtime_not_verified", "Topology OB01 verification status", errors)
        if royal_encounter.get("main_route_blocked_by_optional_encounter") is not False:
            errors.append("OB01 must remain optional and must not block the A8 to A9 main route.")

    boss_scene = read("scenes/royal_tomb_boss.tscn", errors)
    boss_controller = read("scripts/levels/royal_tomb_boss.gd", errors)
    boss_script = read("scripts/enemies/ashen_knight.gd", errors)
    hud_script = read("scripts/ui/game_hud.gd", errors)
    require(boss_scene, 'path="res://scripts/levels/royal_tomb_boss.gd"', "Royal tomb boss scene", errors)
    require(region_script, '"res://scenes/royal_tomb_boss.tscn", "west"', "A8 optional boss entrance", errors)
    require(region_script, '"defeated_royal_tomb_guardian" not in WorldState.achievement_flags', "A8 boss entrance persistence gate", errors)
    require(region_script, 'if region_id == "A8" and side == "boss_return":', "A8 boss return spawn mapping", errors)
    require(world_state, '"royal_tomb_boss":', "WorldState boss-arena resume mapping", errors)
    require(world_state, 'res://scenes/royal_tomb_boss.tscn', "WorldState boss-arena resume scene", errors)
    require(boss_controller, 'boss.set("persist_global_boss_defeat", false)', "Royal tomb boss isolation from the global combat demo", errors)
    require(boss_controller, 'boss.connect("phase_changed"', "Royal tomb boss phase signal", errors)
    require(boss_controller, 'WorldState.record_achievement(BOSS_FLAG)', "Royal tomb boss victory persistence", errors)
    require(boss_controller, 'WorldState.pending_region_spawn_side = "boss_return"', "Royal tomb boss return spawn side", errors)
    require(boss_controller, 'SceneTransition.fade_to_scene("res://scenes/royal_tomb.tscn")', "Royal tomb boss return transition", errors)
    require(boss_controller, '_respawn_boss_after_death', "Royal tomb boss death-reset route", errors)
    require(boss_controller, 'if BOSS_FLAG in WorldState.achievement_flags:', "Royal tomb boss Continue-state recovery", errors)
    require(boss_script, 'if not phase_two and health <= 120:', "Boss phase-two threshold", errors)
    require(boss_controller, 'boss.queue_free()', "Royal tomb boss death reset", errors)
    require(boss_controller, 'victory = true', "Royal tomb boss victory latch", errors)
    require(boss_controller, 'return_door.interacted.connect(_return_to_tomb)', "Royal tomb boss exit interaction", errors)
    require(region_script, 'return 1700.0', "A8 boss-return safe landing", errors)
    require(boss_script, 'var boss_display_name := "灰烬骑士"', "Reusable boss display-name contract", errors)
    require(boss_script, "var persist_global_boss_defeat := true", "Reusable boss global-defeat isolation switch", errors)
    require(boss_script, "phase = 2", "Reusable boss second-phase state", errors)
    require(hud_script, 'var phase_variant = boss.get("phase")', "Boss HUD phase display", errors)
    require(hud_script, 'int(boss.get("health")) <= 0', "Boss HUD active-instance visibility guard", errors)

    prologue_script = read("scripts/levels/escape_prologue.gd", errors)
    require(prologue_script, "func _create_surgical_catwalks() -> void:", "A0 surgical catwalk builder", errors)
    # Combat shutters must be visually legible; physics-only barriers are not acceptable.
    # 战斗封锁必须有明确视觉反馈，禁止只有碰撞体而没有可见障碍。
    require(prologue_script, "func _draw_security_shutter(gate_x: float) -> void:", "A0 visible combat shutter renderer", errors)
    require(prologue_script, 'Color("#a54c62", 0.10)', "A0 shutter warning silhouette", errors)
    require(prologue_script, 'Color("#f0b35c")', "A0 shutter active-state warning lamp", errors)
    require(prologue_script, "Warning lamps communicate that the shutter is an active combat lock", "A0 shutter intent is documented in source", errors)
    require(prologue_script, "Rect2(430, 455, 100, 16)", "A0 surgical first ledge", errors)
    if "MAINTENANCE ACCESS ONLY" not in prologue_script and "仅供维护人员通行" not in prologue_script:
        errors.append("A0 catwalk landmark: missing the maintenance-only label in either source or localized form.")
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
    require(village_script, "draw_texture_rect(VILLAGE_BACKDROP, Rect2(0, 0, 3000, 720), false)", "Village illustrated backdrop", errors)
    require(village_script, "draw_texture_rect(VILLAGE_GROUND_STRIP, Rect2(0, 520, 3000, 200), false)", "Village textured ground", errors)
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

    # A0 exterior forced-loss must progress through a short fade placeholder, not depend on unfinished animation.
    # A0 洞外必败流程用短暂黑屏占位，不得依赖尚未完成的撤退/坠落动画。
    prologue_exterior_script = read("scripts/levels/prologue_exterior.gd", errors)
    executioner_script = read("scripts/enemies/ashen_knight.gd", errors)
    require(prologue_exterior_script, "const FORCED_DEFEAT_SECONDS := 12.0", "A0 exterior forced-loss timeout", errors)
    require(prologue_exterior_script, 'boss.set("damage_immune", true)', "A0 executioner cannot be defeated before rescue", errors)
    require(prologue_exterior_script, "WorldState.mark_prologue_complete()", "A0 prologue completion is committed before transition", errors)
    require(prologue_exterior_script, 'WorldState.current_location = "mite_house"', "A0 first arrival resumes in Mite's house", errors)
    require(prologue_exterior_script, 'SceneTransition.fade_to_scene("res://scenes/mite_house.tscn")', "A0 uses fade transition directly to Mite's house", errors)
    if "prologue_cliff_fall_rescue_pending" in prologue_exterior_script:
        errors.append("A0 first-arrival narrative: redundant rescue-narrative flag must not be written.")
    require(executioner_script, "if damage_immune:", "Boss runtime honors the prologue damage-immunity contract", errors)

    # M1 alternate route and vertical traversal contracts.
    # M1 替代路线与垂直探索的静态契约。
    prologue_route_script = read("scripts/levels/escape_prologue.gd", errors)
    require(prologue_route_script, 'if WorldState.prologue_complete:', "C01 completed-prologue resume guard", errors)
    require(prologue_route_script, 'wardens_defeated >= wardens.size()', "C01 escape opens only after all wardens are defeated", errors)
    require(prologue_route_script, 'exit_area.enabled = true', "C01 escape door is enabled by prologue progression", errors)
    require(prologue_route_script, 'WorldState.mark_prologue_complete()', "C01 completion persists before leaving A0", errors)
    require(prologue_route_script, 'SceneTransition.fade_to_scene("res://scenes/village_hub.tscn")', "C01 A0-to-A1 transition", errors)

    village_hub_script = read("scripts/levels/village_hub.gd", errors)
    if "prologue_cliff_fall_rescue_pending" in village_hub_script or "_show_prologue_rescue" in village_hub_script:
        errors.append("A1 arrival: redundant forced rescue narration must not be present.")
    require(village_hub_script, 'spawn_side == "mite_house_return"', "A1 return from Mite's house declares its own entry side", errors)
    require(village_hub_script, '530.0 if spawn_side == "mite_house_return"', "A1 return from Mite's house lands beside, but outside, its door trigger", errors)
    mite_house_script = read("scripts/levels/mite_house.gd", errors)
    require(mite_house_script, 'WorldState.pending_region_spawn_side = "mite_house_return"', "Mite's house return declares its village entry side", errors)
    require(mite_house_script, '"YOU WAKE IN A SMALL ROOM"', "A0 arrival uses quiet wake-up framing instead of rescue exposition", errors)
    world_state_script = read("scripts/core/world_state.gd", errors)
    require(world_state_script, 'return "res://scenes/mite_house.tscn"', "Continue can resume the one-time A0 arrival scene", errors)

    defense_route_script = read("scripts/levels/village_defense_demo.gd", errors)
    require(defense_route_script, 'if defeated == 3 and stage == 1:', "A1 defense first wave completion", errors)
    require(defense_route_script, 'elif defeated == 7 and stage == 2:', "A1 defense second wave completion", errors)
    require(defense_route_script, 'WorldState.record_achievement("village_defense_survived")', "A1 defense victory persists progression flag", errors)
    require(defense_route_script, 'SceneTransition.fade_to_scene("res://scenes/village_hub.tscn")', "A1 defense victory returns to village", errors)
    require(defense_route_script, 'defeated = 0', "A1 defense retry resets wave counter", errors)
    require(defense_route_script, "hero.defer_death_recovery = true", "A1 defense uses its authored Hero lifecycle", errors)
    require(defense_route_script, "hero.global_position = Vector2(420.0, FLOOR_Y)", "A1 defeat returns to its local start point", errors)
    require(defense_route_script, "hero.restore_full()", "A1 defeat restores combat state", errors)
    require(defense_route_script, '_begin_attack()', "A1 defense retry restarts encounter", errors)

    village_route_script = read("scripts/levels/village_hub.gd", errors)
    village_poi_script = read("scripts/world/village_poi.gd", errors)
    require(village_route_script, 'if location_id == "north_gate":', "C02 A1 north-gate route", errors)
    require(village_route_script, 'north_gate.position = Vector2(2840, 520)', "C02 north-gate interaction anchor at expanded A1 east edge", errors)
    require(village_route_script, '2630.0 if spawn_side == "north_gate"', "C02 A2 return spawn x=2630", errors)
    require(village_poi_script, 'distance_to(hero.global_position) <= interaction_range', "A1 POI interaction radius is configurable per point", errors)
    # The A2 return spawn must remain outside the North Gate POI radius to prevent
    # a transition loop or an immediate repeated interaction after returning.
    if 2840.0 - 2630.0 <= 110.0:
        errors.append("C02: A2 return spawn overlaps the North Gate POI interaction radius.")
    require(village_route_script, 'if "village_defense_survived" in WorldState.achievement_flags:', "C02 defense flag gates A2 entry", errors)
    require(village_route_script, 'SceneTransition.fade_to_scene("res://scenes/village_defense_demo.tscn")', "C02 first North Gate interaction starts defense", errors)
    require(village_route_script, 'WorldState.pending_region_spawn_side = "west"', "C02 A1-to-A2 spawn side", errors)
    require(village_route_script, 'SceneTransition.fade_to_scene("res://scenes/ash_forest.tscn")', "C02 A1-to-A2 transition", errors)
    require(region_script, '"res://scenes/village_hub.tscn", "north_gate"', "C02 A2-to-A1 reverse transition", errors)

    # C03 must remain a genuinely supported two-way canopy route between A2 and A3.
    require(region_script, '3400.0, "E  沿树冠高路进入被遗忘的城区"', "C03 A2 eastern canopy door anchor", errors)
    require(region_script, '"res://scenes/forgotten_city.tscn", "city_canopy_entry",\n\t\t\t\ttrue, "", "", floor_y - 160.0', "C03 A2 door transition and elevation", errors)
    require(region_script, "_add_platform(Rect2(3335, 490, 145, 18))", "C03 A2 exit support platform", errors)
    require(region_script, 'if region_id == "A2" and side == "east":', "C03 A2 return X mapping branch", errors)
    require(region_script, "return 3220.0", "C03 A2 return X landing", errors)
    require(region_script, 'if region_id == "A2" and side == "east":', "C03 A2 return height mapping branch", errors)
    require(region_script, "return floor_y - 140.0", "C03 A2 return height mapping", errors)
    require(region_script, 'if region_id == "A3" and side == "city_canopy_entry":', "C03 A3 arrival X mapping branch", errors)
    require(region_script, "return 180.0", "C03 A3 arrival X mapping", errors)
    require(region_script, 'if region_id == "A3" and side == "city_canopy_entry":\n\t\treturn floor_y - 130.0', "C03 A3 arrival height mapping", errors)
    require(region_script, "_add_platform(Rect2(80, 410, 150, 18))", "C03 A3 west arrival support platform", errors)

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
    require(region_script, 'if region_id == "A3" and side == "village_city_cut":', "C24 A3 arrival spawn branch", errors)
    require(region_script, "return 700.0", "C24 A3 arrival spawn x=700", errors)
    require(region_script, '520.0, "E  经旧排水道返回"', "A3 return-to-village exit at x=520", errors)
    require(region_script, "_add_platform(Rect2(760, 370, 110, 18))", "A2 forest canopy route", errors)
    require(region_script, "_add_platform(Rect2(450, 400, 110, 18))", "A3 rooftop loop", errors)
    require(region_script, "_add_platform(Rect2(1650, 310, 130, 18))", "A4 pipe-walk route", errors)
    require(region_script, "_add_platform(Rect2(420, 420, 120, 18))", "A5 battlefield parapet route", errors)
    require(region_script, "_add_platform(Rect2(2190, 450, 140, 18))", "A5 elevated monastery approach", errors)
    require(region_script, "2250.0, \"E  沿残墙高路进入修道院\"", "A5 raised main exit", errors)
    require(region_script, '"res://scenes/monastery_tower.tscn", "battlefield_entry", true, "", "", floor_y - 90.0', "C09 elevated door height contract", errors)
    require(region_script, '2350.0, "E  沿外环屋顶阶梯登上大圣堂"', "C17 A9 rooftop exit anchor", errors)
    require(region_script, '"res://scenes/grand_cathedral.tscn", "cathedral_roof", true, "", "", floor_y - 180.0', "C17 elevated destination spawn side", errors)
    require(region_script, '_add_platform(Rect2(80, 360, 150, 18))', "A10 C17 west upper landing platform", errors)
    require(region_script, '"res://scenes/royal_outer_ring.tscn", "cathedral_roof_return",\n\t\t\t\ttrue, "", "", floor_y - 180.0', "C17 elevated return door", errors)
    require(region_script, 'if region_id == "A10" and side == "cathedral_roof":', "C17 A10 arrival height mapping branch", errors)
    require(region_script, "return floor_y - 180.0", "C17 A10 arrival height mapping", errors)
    require(region_script, 'if region_id == "A9" and side == "cathedral_roof_return":', "C17 A9 return height mapping branch", errors)
    require(region_script, "return floor_y - 180.0", "C17 A9 return height mapping", errors)
    require(region_script, 'if region_id == "A10" and side == "cathedral_roof":', "C17 A10 arrival X mapping branch", errors)
    require(region_script, "return 180.0", "C17 A10 arrival X mapping", errors)
    require(region_script, 'if region_id == "A9" and side == "cathedral_roof_return":', "C17 A9 return X mapping branch", errors)
    require(region_script, "return 2450.0", "C17 A9 return X mapping", errors)
    require(region_script, "_add_platform(Rect2(1250, 270, 120, 18))", "A6 cloister balcony route", errors)
    require(region_script, "_add_platform(Rect2(1280, 320, 110, 18))", "A7 maintenance catwalk", errors)
    require(region_script, "_add_platform(Rect2(1240, 310, 110, 18))", "A8 upper burial gallery", errors)
    require(region_script, "_add_platform(Rect2(390, 395, 115, 18))", "A9 outer-ring roof loop", errors)
    require(region_script, "_add_platform(Rect2(2190, 390, 140, 18))", "A9 cathedral approach lower step", errors)
    require(region_script, "_add_platform(Rect2(2300, 360, 220, 18))", "A9 cathedral approach upper step", errors)
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
                nodes = [(0.0, 540.0, 3000.0 if region_id == "A1" else (3600.0 if region_id == "A2" else 2600.0), 40.0, True)] + [
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
        'if NereisEndingEvaluator.get_candidate() != "凡人之墓":',
        'ENDGAME_GATE_SCRIPT',
        'reached_A10_via_A9',
        'primordial_hollow',
        'deep_research_depths',
        'gate.required_resonance = 68',
        'gate.required_outer_exposure = 12',
        'gate.require_outer_god_resonance = true',
        'var required_source_ids: Array[String] = ["anomaly_mirror_street_echo"]',
        "gate.required_source_ids = required_source_ids",
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
        'E  打开旧朝圣高路',
        'E  返回边境战场',
        'opened_bell_tower_drop',
        'E  返回修道院落差口',
        'reached_A7_then_opened_supply_tunnel',
        'reached_A8_via_A7_then_opened_royal_tomb_gate',
        'reached_A9_via_A8_then_opened_old_lift_from_A9',
        'reached_A12_via_A10_then_opened_inner_city_side_gate',
        'reached_A9_then_opened_royal_drain_from_outer_ring',
        'E  打开补给隧道',
        'E  打开王墓水道',
        'E  打开旧升降梯',
        'E  打开内城侧门',
        'E  打开王城排水门',
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
        'E  打开上层检修舱口',
        'opened_sewer_inspection_hatch_from_A4',
        'SceneTransition.fade_to_scene(target_scene)',
        "clue.ancient_exposure_floor = ancient_floor",
    ]:
        require(region_script, contract, "Graybox region controller", errors)

    def _region_exit_block(region_id: str) -> str:
        # GDScript uses tabs in match-case indentation; whitespace-agnostic matching keeps this audit stable.
        # GDScript 的 match 分支使用 Tab 缩进；提取时不应假定为 8 个空格。
        exits_start = region_script.find("func _spawn_region_exits")
        if exits_start < 0:
            return ""
        exits_end = region_script.find("\nfunc ", exits_start + len("func _spawn_region_exits"))
        if exits_end < 0:
            exits_end = len(region_script)
        exits_source = region_script[exits_start:exits_end]
        current = re.search(rf'(?m)^[ \t]*"{re.escape(region_id)}":[ \t]*$', exits_source)
        if current is None:
            return ""
        next_region = re.search(r'(?m)^[ \t]*"(?:A(?:[0-9]|1[0-3])|H(?:0[1-9]))":[ \t]*$', exits_source[current.end():])
        block_end = current.end() + next_region.start() if next_region else len(exits_source)
        return exits_source[current.start():block_end]

    # P2 Boss requirement: the A8 arena is an optional independent scene and cannot replace the C13/C14/C07/C15 routes.
    # P2 Boss 合同：A8 Boss 必须是独立可选场景，不能替代 C13/C14/C07/C15 既有路线。
    a8_exit_block = _region_exit_block("A8")
    require(a8_exit_block, '"defeated_royal_tomb_guardian" not in WorldState.achievement_flags', "A8 optional Boss entrance gate", errors)
    require(a8_exit_block, '"res://scenes/royal_tomb_boss.tscn"', "A8 Boss scene transition", errors)
    require(a8_exit_block, '1540.0, "E  进入王墓内殿"', "A8 Boss door anchor", errors)
    require(a8_exit_block, 'map_width - 72.0, "E  进入王城外环"', "A8→A9 main route remains open beside optional Boss", errors)
    require(region_script, 'if region_id == "A8" and side == "boss_return":', "A8 Boss return spawn mapping", errors)
    require(region_script, "return 1700.0", "A8 Boss return spawn clearance", errors)
    # Keep the victory return away from both the arena entrance and the adjacent H06 gate's focus volume.
    # 胜利回程点必须同时避开 Boss 入口与相邻 H06 的交互焦点。
    if min(abs(1700.0 - 1540.0), abs(1870.0 - 1700.0)) < 130.0:
        errors.append("A8 Boss return spawn is too close to the arena entrance or H06 gate.")

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
    require(region_script, 'if region_id == "A3" and target_location == "sewer_reservoir":', "C05 route recording condition", errors)
    require(region_script, 'WorldState.record_achievement("reached_A4_via_A3")', "C05 route recording action", errors)
    a4_ready_start = region_script.find('func _ready()')
    a4_ready_end = region_script.find('func _spawn_x_for_side', a4_ready_start)
    ready_block = region_script[a4_ready_start:a4_ready_end] if a4_ready_start >= 0 and a4_ready_end > a4_ready_start else ""
    if 'WorldState.record_achievement("reached_A4_via_A3")' in ready_block:
        fail(errors, "C05 route flag must not be recorded unconditionally on A4 scene entry.")

    # C24 must be gated on the city side too, matching the village's defense requirement.
    # C24 城区侧也必须受村庄防卫标记约束，与村庄入口条件一致。
    a3_exit_block = _region_exit_block("A3")
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
    for region in ordered_route_regions:
        route_blocks[region] = _region_exit_block(region)
        if not route_blocks[region]:
            errors.append(f"Graybox route audit: cannot isolate {region} exit block.")
    # Audit all 24 C-edges against the actual source-region transition wiring in one pass.
    # 一次性逐条核对全部 24 条 C 连接的源区域转场代码与反向门，不再只依赖主线抽样断言。
    village_route_script = read("scripts/levels/village_hub.gd", errors)
    scene_path_by_region = {
        "A0": "scenes/escape_prologue.tscn",
        "A1": "scenes/village_hub.tscn",
    }
    scene_path_by_region.update({
        region_id: scene_data[0]
        for region_id, scene_data in REGIONS.items()
        if region_id.startswith("A")
    })
    topology_for_route_audit = topology
    runtime_route_source = dict(route_blocks)
    runtime_route_source["A0"] = prologue_route_script
    runtime_route_source["A1"] = village_route_script
    for edge in topology_for_route_audit.get("connections", []):
        edge_id = edge.get("id", "<missing>")
        source_region = str(edge.get("from", ""))
        target_region = str(edge.get("to", ""))
        source_block = runtime_route_source.get(source_region, "")
        target_block = runtime_route_source.get(target_region, "")
        target_path = scene_path_by_region.get(target_region, "")
        source_path = scene_path_by_region.get(source_region, "")
        if not source_block:
            errors.append(f"{edge_id} has no isolated runtime source block for {source_region}.")
        elif edge_id == "C15":
            require(source_block, "_spawn_a11_maintenance_gate(", "C15 A8-side gate wiring", errors)
        elif edge_id == "C19":
            require(source_block, "_spawn_a11_chapel_gate(", "C19 A10-side gate wiring", errors)
        elif not target_path:
            errors.append(f"{edge_id} has no scene-path mapping for target region {target_region}.")
        else:
            require(source_block, f'res://{target_path}', f"{edge_id} {source_region}-to-{target_region} transition", errors)
        if edge.get("final_direction") == "both":
            if not target_block:
                errors.append(f"{edge_id} has no isolated runtime reverse block for {target_region}.")
            elif not source_path:
                errors.append(f"{edge_id} has no scene-path mapping for reverse target region {source_region}.")
            else:
                require(target_block, f'res://{source_path}', f"{edge_id} reverse {target_region}-to-{source_region} transition", errors)

    main_route_contracts = [
        ("A2", '"E  沿树冠高路进入被遗忘的城区"', "C03 A2-to-A3"),
        ("A3", '"E  返回旧朝圣路"', "C03 A3-to-A2"),
        ("A3", '"E  沿残墙高路前往战场"', "C08 A3-to-A5"),
        ("A5", '"E  沿残墙高路返回被遗忘的城区"', "C08 A5-to-A3"),
        ("A5", '"E  沿残墙高路进入修道院"', "C09 A5-to-A6"),
        ("A6", '"E  返回边境战场"', "C09 A6-to-A5"),
        ("A6", '"E  深入监牢"', "C11 A6-to-A7"),
        ("A7", '"E  返回修道院"', "C11 A7-to-A6"),
        ("A7", '"E  沿维护竖井进入旧王墓"', "C13 A7-to-A8"),
        ("A8", '"E  沿维护竖井返回监牢"', "C13 A8-to-A7"),
        ("A8", '"E  进入王城外环"', "C14 A8-to-A9"),
        ("A9", '"E  返回旧王墓"', "C14 A9-to-A8"),
    ]
    for source_region, contract, connection_label in main_route_contracts:
        require(route_blocks.get(source_region, ""), contract, connection_label, errors)

    # C13 must be elevated at both ends; its authored vertical route must not collapse into a ground-level door pair.
    # C13 两端必须保持高位；维护竖井主线不能退化为地面门对门。
    c13_route = route_blocks.get("A7", "")
    c13_return_route = route_blocks.get("A8", "")
    for required, label in [
        ('"maintenance_shaft_entry"', "C13 A7-to-A8 target side"),
        ('floor_y - 180.0', "C13 A7 elevated door height"),
    ]:
        require(c13_route, required, label, errors)
    for required, label in [
        ('"maintenance_shaft_return"', "C13 A8-to-A7 target side"),
        ('floor_y - 180.0', "C13 A8 elevated door height"),
    ]:
        require(c13_return_route, required, label, errors)
    for required, label in [
        ('_add_platform(Rect2(2140, 460, 110, 18))', "C13 prison approach step"),
        ('_add_platform(Rect2(2180, 380, 390, 18))', "C13 prison upper exit ledge"),
        ('_add_platform(Rect2(60, 380, 170, 18))', "C13 tomb upper arrival ledge"),
        ('_add_platform(Rect2(240, 380, 170, 18))', "C13 tomb route connection"),
    ]:
        require(region_script, required, label, errors)

    # C19's A11 return is paired to the C19 opened state, not a generic A10 progression flag.
    require(region_script, 'var can_return_to_cathedral := WorldState.is_hidden_path_opened("C19")', "C19 paired return gate", errors)

    # C08/C09 high-road transitions must land on collision-backed ledges in both directions.
    # C08/C09 高路转场的双向落点都必须由真实碰撞平台承托。
    for contract, label in [
        ('_add_platform(Rect2(2180, 410, 250, 18))', "C08 A3 upper return ledge"),
        ('_add_platform(Rect2(100, 410, 300, 18))', "C08 A5 upper arrival ledge"),
        ('_add_platform(Rect2(2190, 450, 140, 18))', "C09 A5 upper exit ledge"),
        ('_add_platform(Rect2(2150, 485, 150, 18))', "C09 A5 lower return approach"),
        ('_add_platform(Rect2(100, 450, 140, 18))', "C09 A6 west bridge arrival"),
        ('if region_id == "A6" and side == "battlefield_entry":\n\t\treturn floor_y - 90.0', "C09 A6 bridge spawn height"),
        ('if region_id == "A5" and side == "monastery_return":\n\t\treturn floor_y - 55.0', "C09 A5 return spawn height"),
        
        
    ]:
        require(region_script, contract, label, errors)

    # Branch bodies may include explanatory comments; assert that each C09 X mapping returns from its own side branch.
    # 出生映射允许分支内包含说明注释，但返回值必须仍属于对应区域和进入侧。
    for region_id, side, expected_x, label in [
        ("A6", "battlefield_entry", "160.0", "C09 A6 bridge spawn X"),
        ("A5", "monastery_return", "2165.0", "C09 A5 return spawn X"),
    ]:
        branch_pattern = (
            rf'if region_id == "{re.escape(region_id)}" and side == "{re.escape(side)}":'
            rf'\s*(?:#.*\n\s*)*return {re.escape(expected_x)}(?:\s|$)'
        )
        if re.search(branch_pattern, region_script) is None:
            errors.append(f"{label}: missing branch mapping {region_id}/{side} -> {expected_x}.")

    # C04 is a paired upper-route shortcut: both door heights, platform support, and arrival elevations must remain aligned.
    # C04 是双侧高路捷径：两侧门高、承托平台与到达高度必须保持一致。
    for contract in (
        '1880.0, "E  返回边境战场", "old_battlefield"',
        '"res://scenes/old_battlefield.tscn", "old_pilgrim_highroad",',
        '520.0, "E  打开旧朝圣高路", "ash_forest"',
        '"reached_A5_and_opened_old_pilgrim_highroad", "E  沿旧朝圣高路返回"',
        'if region_id == "A2" and side == "old_pilgrim_highroad":',
        'if region_id == "A5" and side == "old_pilgrim_highroad":',
        'return floor_y - 140.0',
        'return floor_y - 85.0',
        '_add_platform(Rect2(1840, 445, 130, 18))',
        '_add_platform(Rect2(420, 420, 120, 18))',
        '_add_platform(Rect2(560, 455, 160, 18))',
        'if region_id == "A4" and side == "prison_tunnel":',
        'return 960.0',
        'if region_id == "A4" and side == "royal_drain":',
        'return 1540.0',
        '_add_platform(Rect2(1530, 420, 70, 18))',
        '_add_platform(Rect2(620, 390, 180, 18))',
        '740.0, "E  打开王城排水门"',
    ):
        require(region_script, contract, "C04 paired canopy route", errors)

    # C17 and C20 are the intended public route through the cathedral; C18 must remain a later shortcut.
    # C17/C20 是经过大圣堂的公开主线；C18 只能作为抵达内城后的后期开启捷径。
    a9_route_block = _region_exit_block("A9")
    a10_route_block = _region_exit_block("A10")
    a12_route_block = _region_exit_block("A12")
    for contract in [
        '"E  沿外环屋顶阶梯登上大圣堂"',
        'res://scenes/grand_cathedral.tscn", "cathedral_roof"',
    ]:
        require(a9_route_block, contract, "C17 outer-ring-to-cathedral main route", errors)
    for contract in [
        '"E  进入王室内城"',
        'res://scenes/inner_city.tscn", "west"',
    ]:
        require(a10_route_block, contract, "C20 cathedral-to-inner-city main route", errors)
    require(a12_route_block, '"E  返回大圣堂"', "C20 inner-city return route", errors)
    require(a12_route_block, '"reached_A12_via_A10_then_opened_inner_city_side_gate"', "C18 main-route prerequisite", errors)
    require(region_script, '900.0, "E  返回王室内城"', "C18 A9-side door anchor", errors)
    require(region_script, '520.0, "E  打开内城侧门"', "C18 A12-side door anchor", errors)
    require(region_script, 'if region_id == "A9" and side == "inner_city_side_gate":\n\t\t# C18 lands outside the x=900 door trigger and just beyond the x=1100 rest point\'s 110px focus radius.\n\t\t# C18 出生点避开 x=900 门触发区，并位于 x=1100 休整点的 110px 交互半径之外。\n\t\treturn 980.0', "C18 A9 safe arrival", errors)
    if a9_route_block.find('"E  RETURN TO THE INNER CITY"') >= 0 and a9_route_block.find('"reached_A12_via_A10_then_opened_inner_city_side_gate"') < 0:
        fail(errors, "C18 A9-side shortcut must remain gated by opening it from A12 after the main route.")

    # C10 remains independent of H05; the warden key is its access prerequisite, and the drop flag records the opened door.
    # C10 与 H05 独立；钟塔守卫钥匙是进入条件，落差标记只记录门已开启。
    a6_exit_block = _region_exit_block("A6")
    if not a6_exit_block:
        fail(errors, "C10 route audit: cannot isolate A6 exit block.")
    else:
        require(a6_exit_block, "C10 is created after the bell warden drops the winch key.", "C10 monastery shortcut", errors)
        require(region_script, '"E  使用绞盘钥匙打开钟塔落差通路"', "C10 monastery shortcut", errors)
        require(region_script, 'WorldState.is_item_owned("bell_tower_winch_key")', "C10 monastery shortcut", errors)
        require(region_script, '"opened_bell_tower_drop"', "C10 monastery shortcut", errors)
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
        "A6": ["A6_MadCleric_01"],
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
            'if NereisEndingEvaluator.get_candidate() != "凡人之墓":',
            '"terminal_anomaly"',
            '"res://scenes/terminal_anomaly.tscn"',
        ],
    }
    exits_source = region_script[exits_start:]
    for hidden_id, contracts in hidden_exit_contracts.items():
        # Start the next-branch search after the current header; searching at block_start + 1
        # accidentally matched the same header and reduced this block to one character.
        branch_match = re.search(
            rf'^[\t ]*"{re.escape(hidden_id)}":[\t ]*$',
            exits_source,
            re.MULTILINE,
        )
        if branch_match is None:
            fail(errors, f"{hidden_id} hidden-region exit block is missing or malformed.")
            continue
        next_branch = re.search(
            r'^[\t ]*"(?:A(?:[0-9]|1[0-3])|H(?:0[1-9]))":[\t ]*$',
            exits_source[branch_match.end():],
            re.MULTILINE,
        )
        if next_branch:
            block_end = branch_match.end() + next_branch.start()
        else:
            block_end = exits_source.find("\nfunc ", branch_match.end())
            if block_end < 0:
                block_end = len(exits_source)
        block = exits_source[branch_match.start():block_end]
        for contract in contracts:
            require(block, contract, f"{hidden_id} hidden-region return contract", errors)

    # A13 is a real terminal map layer, not merely an abstract topology node. Ending selection occurs after entering it.
    # A13 必须是实际终局地图层，而不是只存在于拓扑中的抽象节点；进入后才选择结局。
    exits_source = region_script[exits_start:]
    a13_match = re.search(r'^[\t ]*"A13":[\t ]*$', exits_source, re.MULTILINE)
    a13_start = exits_start + a13_match.start() if a13_match else -1
    if a13_match is None:
        a13_block = ""
    else:
        a13_next = re.search(
            r'^[\t ]*"(?:A(?:[0-9]|1[0-3])|H(?:0[1-9]))":[\t ]*$',
            exits_source[a13_match.end():],
            re.MULTILINE,
        )
        if a13_next:
            a13_end = exits_start + a13_match.end() + a13_next.start()
        else:
            a13_end = region_script.find("\nfunc ", a13_start)
            if a13_end < 0:
                a13_end = len(region_script)
        a13_block = region_script[a13_start:a13_end]
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
    require(region_script, 'if region_id == "A4" and side == "sewer_upper":', "A4 C05 arrival height mapping branch", errors)
    require(region_script, "return floor_y - 95.0", "A4 C05 arrival height mapping", errors)
    spawn_y_start = region_script.find("func _spawn_y_for_side(side: String) -> float:")
    spawn_x_start = region_script.find("func _spawn_x_for_side(side: String) -> float:")
    spawn_y_block = region_script[spawn_y_start:spawn_x_start] if spawn_y_start >= 0 and spawn_x_start > spawn_y_start else ""
    c05_y_branch = 'if region_id == "A4" and side == "sewer_upper":\n\t\t# The Hero origin is at the feet; align the spawn exactly with the landing y=445 collision top.\n\t\t# 主角坐标位于脚底；出生高度应与 y=445 的实体平台顶面精确对齐。\n\t\treturn floor_y - 95.0'
    if spawn_y_block.count(c05_y_branch) != 1:
        fail(errors, "C05 A4 sewer_upper Y mapping must appear exactly once in _spawn_y_for_side.")
    if 'if region_id == "A4" and side == "sewer_upper":\n\t\treturn 180.0' in spawn_y_block:
        fail(errors, "C05 A4 sewer_upper Y mapping must not use absolute y=180.0 above its supported landing.")
    require(region_script, 'if region_id == "A4" and side == "sewer_upper":', "A4 C05 arrival X mapping branch", errors)
    require(region_script, "return 180.0", "A4 C05 arrival X mapping", errors)
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
    require(region_script, 'return 1540.0', "A4 C23 safe return spawn", errors)
    require(region_script, 'true, "reached_A9_then_opened_royal_drain_from_outer_ring", "E  沿王城排水道返回",\n\t\t\t\tfloor_y - 150.0', "A9 C23 door height", errors)
    require(region_script, 'Vector2(850, floor_y - 18.0),\n\t\t\t\t"anomaly_old_stone_layer"', "A4 clue/door interaction spacing", errors)

    # C03's canopy route and C07's middle tomb-waterway route must keep their authored elevation on both ends.
    # C03 树冠高路与 C07 王墓中层水道必须在双向转场中保留设计高度。
    for contract in [
        '3400.0, "E  沿树冠高路进入被遗忘的城区"',
        '"res://scenes/forgotten_city.tscn", "city_canopy_entry",',
        'true, "", "", floor_y - 160.0',
        '72.0, "E  返回旧朝圣路", "ash_forest"',
        '_add_platform(Rect2(80, 410, 150, 18))',
        'if region_id == "A3" and side == "city_canopy_entry":',
        'return floor_y - 130.0',
        'return 180.0',
        '_add_platform(Rect2(500, 375, 140, 18))',
        '520.0, "E  打开王墓水道", "sewer_reservoir"',
        'true, "reached_A8_via_A7_then_opened_royal_tomb_gate", "E  沿王室水道返回"',
        'if region_id == "A8" and side == "royal_tomb_waterway":',
        'return floor_y - 165.0',
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
        ('if region_id == "A2" and side == "east":', "return 3220.0"),
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
        ('if region_id == "A4" and side == "east":', "return map_width - 220.0"),
        ('if region_id == "A4" and side == "prison_tunnel":', "return 960.0"),
        ('if region_id == "A7" and side == "supply_tunnel":', "return 610.0"),
        ('if region_id == "A4" and side == "royal_tomb_waterway":', "return 1410.0"),
        ('if region_id == "A4" and side == "royal_drain":', "return 1540.0"),
        ('if region_id == "A5" and side == "bell_tower":', "return 1900.0"),
        ('if region_id == "A6" and side == "silent_window":', "return 1420.0"),
        ('if region_id == "A8" and side == "royal_name_gate":', "return 1350.0"),
        ('if region_id == "A8" and side == "royal_tomb_waterway":', "return 610.0"),
        ('if region_id == "A8" and side == "royal_tomb_side":', "return 1020.0"),
        ('if region_id == "A9" and side == "third_street_service":', "return 1600.0"),
        ('if region_id == "A9" and side == "royal_transport":', "return 2050.0"),
        ('if region_id == "H01" and side == "east":', "return map_width - 360.0"),
    ]
    spawn_x_start_for_contracts = region_script.find("func _spawn_x_for_side(side: String) -> float:")
    spawn_x_end_for_contracts = region_script.find("\nfunc ", spawn_x_start_for_contracts + 1)
    spawn_x_contract_block = (
        region_script[spawn_x_start_for_contracts:spawn_x_end_for_contracts]
        if spawn_x_start_for_contracts >= 0 and spawn_x_end_for_contracts > spawn_x_start_for_contracts
        else ""
    )
    for condition, expected_return in spawn_contracts:
        start = spawn_x_contract_block.find(condition)
        if start < 0:
            fail(errors, f"Graybox spawn mapping: missing {condition!r} in _spawn_x_for_side().")
            continue
        branch = spawn_x_contract_block[start:]
        next_branch = branch.find("\n\tif ", len(condition))
        if next_branch >= 0:
            branch = branch[:next_branch]
        require(branch, expected_return, f"Graybox spawn mapping {condition}", errors)

    # Cross-check every spatial-contract spawn against its runtime side mapping and a real collision-backed landing.
    # 将拓扑中所有出生点逐一对照运行时 side 映射，并确认高位落点有真实碰撞平台承托。
    spawn_x_end = region_script.find("\nfunc ", spawn_x_start + 1)
    spawn_x_block = region_script[spawn_x_start:spawn_x_end if spawn_x_end >= 0 else len(region_script)]

    def _spawn_expression_value(expression: str, axis: str) -> float | None:
        expression = expression.strip()
        numeric = re.fullmatch(r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)", expression)
        if numeric:
            value = float(expression)
            return value if axis == "x" else (value - 540.0)
        if axis == "x":
            match = re.fullmatch(r"map_width\s*-\s*([\d.]+)", expression)
            return 2600.0 - float(match.group(1)) if match else None
        if expression == "floor_y":
            return 0.0
        match = re.fullmatch(r"floor_y\s*-\s*([\d.]+)", expression)
        return -float(match.group(1)) if match else None

    def _mapped_spawn_value(mapping_block: str, region_id: str, side: str, axis: str) -> float | None:
        condition = re.compile(
            rf'if region_id == "{re.escape(region_id)}" and side == "{re.escape(side)}":'
            rf'(?P<body>(?:\n[ \t]*#.*)*\n[ \t]*return (?P<value>[^\n]+))'
        )
        match = condition.search(mapping_block)
        if match:
            return _spawn_expression_value(match.group("value"), axis)
        # Match the shared fallback behavior only after confirming no region-specific branch exists.
        # 仅在不存在区域专属映射时，才使用控制器的通用默认出生点。
        if axis == "y":
            return 0.0
        if side == "east":
            return 2420.0
        if region_id == "H01":
            return 700.0
        return 180.0

    topology_for_spawn_audit = topology
    spawn_mapping_audit_count = 0
    spawn_landing_audit_count = 0
    for edge in topology_for_spawn_audit.get("connections", []):
        edge_id = edge.get("id", "<missing>")
        spatial = edge.get("spatial_contract", {})
        for spawn_key in ("return_spawn", "from_region_spawn", "to_region_spawn"):
            spawn = spatial.get(spawn_key)
            if not isinstance(spawn, dict) or not spawn.get("region"):
                continue
            region_id = str(spawn.get("region"))
            # A1 is a separate authored scene with its own spawn function and is checked above.
            # A1 是独立场景，使用村庄脚本自己的出生映射并由前面的 C02/C24 断言覆盖。
            if region_id == "A1":
                continue
            try:
                spawn_x = float(spawn["x"])
                spawn_y_offset = float(spawn.get("y_offset", 0.0))
            except (KeyError, TypeError, ValueError):
                errors.append(f"{edge_id} {spawn_key} has invalid spawn coordinates.")
                continue
            side = str(spawn.get("spawn_side", ""))
            if side:
                spawn_mapping_audit_count += 1
                runtime_x = _mapped_spawn_value(spawn_x_block, region_id, side, "x")
                runtime_y_offset = _mapped_spawn_value(spawn_y_block, region_id, side, "y")
                if runtime_x is None or abs(runtime_x - spawn_x) > 0.1:
                    errors.append(
                        f"{edge_id} {spawn_key} X mapping mismatch for {region_id}/{side}: "
                        f"topology={spawn_x}, runtime={runtime_x}."
                    )
                if runtime_y_offset is None or abs(runtime_y_offset - spawn_y_offset) > 0.1:
                    errors.append(
                        f"{edge_id} {spawn_key} Y mapping mismatch for {region_id}/{side}: "
                        f"topology={spawn_y_offset}, runtime={runtime_y_offset}."
                    )
            spawn_landing_audit_count += 1
            region_platforms = platforms_by_region.get(region_id, [])
            scene_path = ROOT / REGIONS.get(region_id, ("", "", ""))[0]
            scene_text = scene_path.read_text(encoding="utf-8") if scene_path.is_file() else ""
            floor_match = re.search(r'^floor_y\s*=\s*([0-9.]+)', scene_text, re.MULTILINE)
            floor_y = float(floor_match.group(1)) if floor_match else 540.0
            ground_supported = abs(spawn_y_offset) <= 0.1 and 0.0 <= spawn_x <= (3600.0 if region_id == "A2" else 2600.0)
            expected_spawn_y = floor_y + spawn_y_offset
            supported = ground_supported or any(
                abs(platform_y - expected_spawn_y) <= 1.5
                and spawn_x >= platform_x - 0.1
                and spawn_x <= platform_x + platform_width + 0.1
                for platform_x, platform_y, platform_width, _platform_height in region_platforms
            )
            if not supported:
                errors.append(
                    f"{edge_id} {spawn_key} is not directly supported by a collision platform: "
                    f"{region_id} x={spawn_x:g}, y={expected_spawn_y:g}."
                )

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

    world_state = read("scripts/core/world_state.gd", errors)
    require(world_state, '"narrative_state_version": 2', "Narrative save schema version is persisted", errors)
    require(world_state, 'int(parsed.get("narrative_state_version", 0)) < 2', "Legacy narrative saves are detected for relationship-state migration", errors)
    require(world_state, 'mite_connection_missed = false', "Legacy church-visit false-miss lock is cleared", errors)

    ending_evaluator = read("scripts/core/ending_evaluator.gd", errors)
    require(ending_evaluator, 'COSMIC_RESONANCE_THRESHOLD: int = 68', "Ending candidate uses resonance threshold", errors)
    require(ending_evaluator, 'REQUIRED_ARTIFACT_PIECES: int = 3', "Ending candidate uses truth-anchor threshold", errors)
    require(ending_evaluator, 'REQUIRED_HIDDEN_REGIONS_FOR_FIRE: int = 2', "Ending candidate uses actual hidden-region exploration", errors)

    village_hub = read("scripts/levels/village_hub.gd", errors)
    village_poi = read("scripts/world/village_poi.gd", errors)
    interior_scene = read("scripts/levels/interior_scene.gd", errors)
    require(village_hub, "守门人打量着你", "A1 gatekeeper has neutral dialogue before route selection", errors)
    require(village_hub, 'WorldState.set_location("village")', "A1 persists village location for Continue", errors)
    require(village_hub, 'npc.position = Vector2(2360, 520)', "A1 gatekeeper is stationed beside the north gate, away from the hearth and Mite", errors)
    require(village_hub, '守门人看了看你身上的教堂印记', "A1 gatekeeper route dialogue is localized to Chinese", errors)
    event_director = read("scripts/core/world_event_director.gd", errors)
    require(village_hub, 'const WORLD_EVENT_DIRECTOR_SCRIPT = preload("res://scripts/core/world_event_director.gd")', "A1 hub wires the shared progression event director", errors)
    require(village_hub, 'world_event_director.dispatch("region_entered"', "A1 dispatches a region-entry event after hub setup", errors)
    require(village_hub, 'world_event_director.dispatch("interaction"', "A1 dispatches POI interactions to the event director", errors)
    require(village_hub, "func _spawn_progression_npcs() -> void:", "A1 has a separate progression-NPC spawn hook", errors)
    require(village_hub, "world_event_director.spawn_npcs(self, ROUTE_NPC_SCRIPT", "A1 uses the data-driven NPC manifest", errors)
    require(village_hub, "func refresh_progression_content() -> void:", "A1 can refresh progression content after state changes", errors)
    require(village_hub, 'world_event_director.dispatch("interaction", {"region": "A1", "interaction_id": String(npc.npc_id)', "A1 NPC conversations dispatch progression events", errors)
    require(village_hub, "refresh_progression_content()", "A1 refreshes progression NPCs after POI events", errors)
    require(event_director, "var _managed_npcs: Array[Node] = []", "Progression refresh tracks only director-managed NPCs", errors)
    require(event_director, "_managed_npcs.clear()", "Progression refresh removes stale managed NPC entries", errors)
    require(event_director, "const NPC_DEFINITIONS: Array[Dictionary]", "Progression NPCs are data-driven", errors)
    require(event_director, '"A1_tavern_sound_notice"', "A1 tavern visit has a persistent first-visit event", errors)
    require(village_hub, '"village_grandmother"', "A1 replaces the amnesiac youth with an ordinary grandmother NPC", errors)
    require(village_hub, "camera.limit_right = 3000", "A1 camera follows the expanded 3000px hub", errors)
    require(village_hub, "rectangle.size = Vector2(3000, 40)", "A1 ground collision spans the expanded hub", errors)
    require(village_hub, "right_shape.position = Vector2(3020, 360)", "A1 right boundary matches the expanded hub width", errors)
    require(village_hub, "Rect2(2760, 340, 110, 16)", "A1 rooftop route reaches the expanded eastern district", errors)
    if 'npc_id = "amnesiac_youth"' in village_hub:
        errors.append("A1 retired amnesiac youth must not be spawned; use the grandmother role instead.")
    require(village_poi, "@export_range(40.0, 140.0, 5.0) var interaction_range: float = 110.0", "A1 POI interaction radii can be tuned per location to avoid overlapping prompts", errors)
    require(village_hub, "grandmother.interaction_range = 60.0", "A1 grandmother focus radius is reduced near neighboring POIs", errors)
    require(village_hub, "blacksmith.interaction_range = 45.0", "A1 blacksmith focus radius is tuned for the workshop district", errors)
    require(village_hub, "merchant.interaction_range = 60.0", "A1 traveling merchant focus radius is tuned for the market district", errors)
    require(village_hub, '"village_blacksmith"', "A1 blacksmith is registered as a functional NPC", errors)
    require(village_hub, 'blacksmith.cloth_color = Color("#594038")', "A1 blacksmith has a distinct visual palette", errors)
    require(village_hub, 'grandmother.cloth_color = Color("#65594a")', "A1 grandmother has a distinct visual palette", errors)
    require(village_hub, 'NereisLocalization.translate_text("铁匠铺")', "A1 blacksmith has a distinct workshop visual landmark", errors)
    require(village_hub, 'NereisLocalization.translate_text("行商摊位")', "A1 merchant has a recognizable stall without a crafting system", errors)
    require(village_hub, 'NereisLocalization.translate_text("老屋")', "A1 grandmother has a recognizable village-home anchor", errors)
    require(village_hub, 'blacksmith.dialogue = "铁匠把锤子搁在砧边', "A1 blacksmith dialogue responds to village-defense state", errors)
    require(village_hub, 'grandmother.dialogue = "老婆婆把门边的灯芯拨亮了一些', "A1 grandmother dialogue responds to village-defense state", errors)
    require(village_hub, '"traveling_merchant"', "A1 traveling merchant has a stable functional NPC ID", errors)
    require(interior_scene, '"pilgrim_knight_a1_arrived"', "Pilgrim Knight is gated behind an explicit story arrival flag", errors)
    require(interior_scene, '"pilgrim_knight_at_tavern"', "Pilgrim Knight appears in either the tavern or church, not both", errors)
    require(interior_scene, '"pilgrim_knight_a1_arrived"', "Pilgrim Knight remains absent until explicit arrival state", errors)
    require(interior_scene, 'narrative.show_message("教堂", "旧木椅整齐地排在空旷的长厅里。', "Church interior remains empty and quiet until a story arrival", errors)
    require(interior_scene, 'npc.display_name = "酒馆值夜人"', "Tavern keeper uses localized Chinese dialogue/name", errors)
    require(interior_scene, '"A1_tavern_sound_noticed" in WorldState.achievement_flags and "village_defense_survived" in WorldState.achievement_flags', "Tavern keeper prioritizes the combined state over single-state dialogue", errors)
    require(village_hub, '"restoration_camp_established" in WorldState.achievement_flags', "A1 Restoration Army camp only appears after its explicit story-arrival flag", errors)
    require(village_hub, 'if "restoration_camp_established" in WorldState.achievement_flags:\n\t\tdraw_rect(Rect2(1945, 360, 90, 160)', "A1 Restoration Army camp visuals are also hidden before the story-arrival flag", errors)
    require(village_hub, 'church.display_name = "教堂"', "A1 religious POI is named 教堂", errors)
    require(village_hub, 'church.dialogue = "教堂的大门没有上锁。里面空荡而安静', "A1 church is initially presented as empty and quiet", errors)
    require(event_director, "func _resolve_dialogue(definition: Dictionary) -> String:", "Progression NPC dialogue supports state-specific variants", errors)
    require(event_director, '"dialogue_variants"', "Progression NPCs can switch dialogue by state", errors)
    require(event_director, '"location":', "World events can check current location facts", errors)
    require(event_director, "const EVENT_DEFINITIONS: Array[Dictionary]", "World events are data-driven", errors)
    require(event_director, "func dispatch(trigger: String, context: Dictionary = {}) -> Array[String]:", "World event trigger entry point", errors)
    require(event_director, "func _conditions_met(conditions: Array) -> bool:", "World events support condition lists", errors)
    require(event_director, '"flag_absent"', "World events can require a flag to be absent", errors)
    require(event_director, '"item_count_at_least"', "World events can require item counts", errors)
    require(event_director, '"world_event_fired:" + event_id', "One-shot world events persist their fired marker", errors)
    require(event_director, "event_triggered.emit(event_id, payload)", "World event director emits an event signal for listeners", errors)
    require(village_hub, 'rest.rest_id = "rest_A1_village_hearth"', "A1 hearth rest point has a stable save ID", errors)
    require(village_hub, 'north_gate.position = Vector2(2840, 520)', "A1 north gate is placed at the expanded east end of the village", errors)
    require(village_hub, 'city_cut.position = Vector2(100, 520)', "A1 drainage shortcut is placed at the west end", errors)
    require(village_hub, 'func _create_village_rooftop_route() -> void:', "A1 optional rooftop exploration route exists", errors)
    require(village_hub, 'mite_house_door.position = Vector2(455, 520)', "A1 Mite house door interaction anchor", errors)
    route_npc_script = read("scripts/npc/route_npc.gd", errors)
    require(route_npc_script, "@export var cloth_color: Color = Color(\"#49424a\")", "Reusable NPC presentation supports per-role clothing colors", errors)
    require(route_npc_script, '@export_range(40.0, 140.0, 5.0) var interaction_range: float = 100.0', "NPC interaction range is configurable per scene", errors)
    require(village_hub, 'npc.interaction_range = 40.0', "A1 gatekeeper uses a reduced local focus radius", errors)
    require(village_hub, 'grandmother.interaction_range = 60.0', "A1 grandmother uses a reduced local focus radius", errors)
    require(village_hub, 'blacksmith.interaction_range = 45.0', "A1 blacksmith uses a reduced local focus radius", errors)
    require(village_hub, 'merchant.interaction_range = 60.0', "A1 merchant uses a reduced local focus radius", errors)
    mite_script = read("scripts/npc/mite.gd", errors)
    require(mite_script, 'const VILLAGE_HOUSE_DOOR_POSITION := Vector2(455, 520)', "A1 Mite interaction excludes the house-door focus zone", errors)
    require(mite_script, 'const VILLAGE_HOUSE_DOOR_EXCLUSION_RANGE := 105.0', "A1 house-door exclusion radius prevents competing E prompts", errors)
    require(mite_script, 'not _blocked_by_village_house_door(hero)', "A1 Mite prompt is suppressed beside the house door", errors)
    require(mite_script, 'INTERACTION_FOCUS_SCRIPT.is_focused(self)', "A1 Mite only draws and accepts input when it owns interaction focus", errors)
    require(village_poi_script, 'INTERACTION_FOCUS_SCRIPT.is_focused(self)', "A1 POIs only draw and accept input when focused", errors)
    if "mark_mite_connection_missed()" in village_hub:
        errors.append("A1 church exploration must not irreversibly mark the Mite connection missed.")

    pickup_script = read("scripts/world/world_item_pickup.gd", errors)
    require(pickup_script, 'panel.call("show_pickup"', "Item pickup shows acquisition feedback without displaying lore as already read", errors)
    if "WorldState.mark_item_read(item_id)" in pickup_script:
        errors.append("Picking up an item must not automatically mark its description as read.")

    inventory_script = read("scripts/ui/inventory_overlay.gd", errors)
    require(inventory_script, "WorldState.mark_item_read(item_id)", "Explicit inventory item selection records reading state", errors)
    if "_select_item(str(item_ids[0]))" in inventory_script:
        errors.append("Opening inventory must not silently mark the first item as read.")


    require(village_hub, "_spawn_resonance_well_gate()", "Village hub", errors)
    require(village_hub, "resonance_well_gate.opened.connect(_on_resonance_well_opened)", "Village hub", errors)
    require(village_hub, 'resonance_well_gate.secret_id = "H01"', "Village hidden gate ID", errors)
    require(village_hub, 'resonance_well_gate.required_resonance = 12', "Village hidden gate threshold", errors)
    require(village_hub, 'resonance_well_gate.target_location_id = "hidden_well"', "Village hidden gate destination", errors)
    require(village_hub, 'var spawn_x := 1850.0 if spawn_side in ["well_exit", "cliff_cave_return"]', "Village watergate return spawn spacing", errors)
    village_spawn_capture = village_hub.find("var spawn_side := WorldState.pending_region_spawn_side")
    village_location_save = village_hub.find('WorldState.set_location("village")', village_spawn_capture)
    village_spawn_clear = village_hub.find('WorldState.pending_region_spawn_side = "west"', village_spawn_capture)
    if not (
        village_spawn_capture >= 0
        and village_location_save > village_spawn_capture
        and village_spawn_clear > village_location_save
    ):
        errors.append("Village resume spawn-side save order: capture incoming side, save destination, then clear one-shot side.")
    require(village_hub, '2630.0 if spawn_side == "north_gate"', "Village north-gate return spawn", errors)
    require(village_hub, '350.0 if spawn_side == "city_cut_return"', "Village old-drain return spawn", errors)
    require(village_hub, '1850.0 if spawn_side in ["well_exit", "cliff_cave_return"]', "Village lower east return spawn", errors)
    require(village_hub, '530.0 if spawn_side == "mite_house_return"', "Village house return spawn", errors)
    require(region_spawn_script, '"res://scenes/village_hub.tscn", "north_gate"', "A2 village return side", errors)
    require(region_spawn_script, '"res://scenes/village_hub.tscn", "city_cut_return"', "A3 old-drain return side", errors)
    require(region_spawn_script, '"res://scenes/village_hub.tscn", "well_exit"', "Watergate return side", errors)
    require(village_hub, 'WorldState.set_checkpoint(Vector2(360, 520))', "A1 checkpoint is restored on entering the hub", errors)
    require(village_hub, '"village_defense_survived"', "Village old-road unlock", errors)
    require(village_hub, 'res://scenes/ash_forest.tscn', "Village old-road route", errors)
    require(village_hub, 'if "village_defense_survived" in WorldState.achievement_flags:', "A1 north gate and old drain share the village-defense progression flag", errors)
    require(village_hub, 'draw_rect(Rect2(2818, 385, 50, 12)', "A1 north gate has a visible blocked state before village defense", errors)
    require(village_hub, 'draw_line(Vector2(2818, 360), Vector2(2794, 405)', "A1 north gate visibly opens after village defense", errors)
    require(village_hub, '守门人朝北门点了点头', "A1 gatekeeper reacts to village-defense progress", errors)
    rest_point_script = read("scripts/world/rest_point.gd", errors)
    require(rest_point_script, 'body.is_on_floor()', "A1 rest point rejects airborne use", errors)
    require(rest_point_script, 'WorldState.save_game()', "A1 rest point saves after restoring the Hero", errors)

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
                    if value is None and property_name == "required_source_ids":
                        # Gate constructors may assign a typed local array to the exported field.
                        value = re.search(
                            r"var\s+required_source_ids(?:\s*:\s*Array\[String\])?\s*(?::=|=)\s*\[(.*?)\]",
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
    print(f" - Full-map inventory: {len(topology.get('regions', []))} regions, {len(topology.get('connections', []))} C-edges, {len(topology.get('subregions', []))} subregions, {len(topology.get('intra_region_connections', []))} intra-region edges, {len(topology.get('elevators', []))} elevator contracts.")
    print(f" - Runtime C-edge wiring: {len(topology_for_route_audit.get('connections', []))} connections audited; reverse source wiring checked where final_direction=both.")
    print(f" - Spatial spawn contracts: {spawn_mapping_audit_count} side mappings and {spawn_landing_audit_count} collision-backed landings checked.")
    print(" - The R01-R08 anomaly source chain is present.")
    print(" - H01-H08 plus C15/C19 gates use saved discovery/open/entry state and progression conditions.")
    print(f" - Platform reachability estimate: {platform_audit_regions} regions, {platform_audit_count} platforms.")
    print(f" - Local resonance route contract: {local_route_count} routes; IDs, prompts, narratives, endpoint proximity, collision overlap, sight gating, and persistence checked.")
    print(" - C15/C19 enter A11 from separate sides; H08 and C21 terminal access follow the shared ending evaluator.")
    print("NOTE: Godot runtime/collision/input validation is still required.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
