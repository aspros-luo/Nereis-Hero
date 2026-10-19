#!/usr/bin/env python3
"""Static validator for Nereis Hero world-map topology. No third-party packages required."""

from __future__ import annotations

import argparse
import json
import sys
from collections import deque
from pathlib import Path
from typing import Any


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def neighbors_from_edge(edge: dict[str, Any], *, initial: bool) -> list[tuple[str, str]]:
    """Return directed arcs for this edge in the initial or final world state."""
    source, target = edge["from"], edge["to"]
    if initial:
        access = edge["initial_access"]
        if access == "blocked":
            return []
        if access == "from_to":
            return [(source, target)]
        if access == "both":
            return [(source, target), (target, source)]
        return []
    direction = edge["final_direction"]
    if direction == "forward":
        return [(source, target)]
    if direction == "both":
        return [(source, target), (target, source)]
    return []


def build_graph(
    region_ids: set[str],
    connections: list[dict[str, Any]],
    hidden_regions: list[dict[str, Any]] | None = None,
    *,
    initial: bool = False,
    include_hidden: bool = True,
) -> dict[str, set[str]]:
    graph = {region_id: set() for region_id in region_ids}
    for edge in connections:
        for source, target in neighbors_from_edge(edge, initial=initial):
            if source in graph and target in graph:
                graph[source].add(target)
    if include_hidden and hidden_regions:
        for secret in hidden_regions:
            parent = secret["parent"]
            secret_id = secret["id"]
            if parent in graph and secret_id in graph:
                # The entry is eventually discoverable from its parent; the actual
                # discovery/threshold conditions are validated separately.
                graph[parent].add(secret_id)
                graph[secret_id].add(parent)
            secondary = secret.get("secondary_exit")
            if secondary and secret_id in graph and secondary["to"] in graph:
                graph[secret_id].add(secondary["to"])
                # Secondary exits may become bidirectional once the remote side
                # has been reached and its progress gate has been opened.
                graph[secondary["to"]].add(secret_id)
    return graph


def reachable(graph: dict[str, set[str]], start: str) -> set[str]:
    if start not in graph:
        return set()
    visited = {start}
    queue = deque([start])
    while queue:
        current = queue.popleft()
        for target in graph[current]:
            if target not in visited:
                visited.add(target)
                queue.append(target)
    return visited


def shortest_path(graph: dict[str, set[str]], start: str, goal: str) -> list[str]:
    if start not in graph or goal not in graph:
        return []
    queue = deque([start])
    previous: dict[str, str | None] = {start: None}
    while queue:
        current = queue.popleft()
        if current == goal:
            break
        for target in sorted(graph[current]):
            if target not in previous:
                previous[target] = current
                queue.append(target)
    if goal not in previous:
        return []
    path = []
    node: str | None = goal
    while node is not None:
        path.append(node)
        node = previous[node]
    return list(reversed(path))


def validate(data: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    regions = data.get("regions", [])
    connections = data.get("connections", [])
    hidden = data.get("hidden_regions", [])
    provisional = data.get("provisional_regions", [])
    sources = data.get("resonance_sources", [])
    primary_route = data.get("primary_route", [])
    loops = data.get("loops", [])
    region_ids_list = [item.get("id", "") for item in regions]
    region_ids = set(region_ids_list)
    provisional_ids = {item.get("id", "") for item in provisional}
    all_ids = region_ids | {item.get("id", "") for item in hidden} | provisional_ids

    if len(region_ids_list) != len(region_ids):
        fail(errors, "Duplicate primary region IDs.")
    if len(region_ids) != 14:
        fail(errors, f"Expected 14 primary regions, found {len(region_ids)}.")
    if len(hidden) != 8:
        fail(errors, f"Expected 8 hidden regions, found {len(hidden)}.")
    if len(connections) != 24:
        fail(errors, f"Expected 24 macro connections, found {len(connections)}.")

    edge_ids = [edge.get("id", "") for edge in connections]
    if len(edge_ids) != len(set(edge_ids)):
        fail(errors, "Duplicate connection IDs.")

    # Hierarchical map contract: macro regions, subregions, local links, and lifts.
    # 分层地图合同：大区域、小区域、区域内连接与升降机必须彼此一致。
    macro_regions = data.get("macro_regions", [])
    subregions = data.get("subregions", [])
    local_connections = data.get("intra_region_connections", [])
    elevators = data.get("elevators", [])
    if len(macro_regions) != 6:
        fail(errors, f"Expected 6 narrative macro regions, found {len(macro_regions)}.")
    if len(subregions) != 76:
        fail(errors, f"Expected 76 subregions, found {len(subregions)}.")
    if len(local_connections) != 71:
        fail(errors, f"Expected 71 intra-region connections, found {len(local_connections)}.")
    if len(elevators) != 8:
        fail(errors, f"Expected 8 elevator contracts, found {len(elevators)}.")

    macro_ids = [item.get("id", "") for item in macro_regions]
    if len(macro_ids) != len(set(macro_ids)):
        fail(errors, "Duplicate macro-region IDs.")
    macro_members = [region_id for item in macro_regions for region_id in item.get("regions", [])]
    if set(macro_members) != region_ids or len(macro_members) != len(region_ids):
        fail(errors, "Every primary region must belong to exactly one macro region.")
    for item in macro_regions:
        unknown = sorted(set(item.get("regions", [])) - region_ids)
        if unknown:
            fail(errors, f"{item.get('id')}: macro region references unknown regions {unknown}.")

    subregion_ids = [item.get("id", "") for item in subregions]
    subregion_id_set = set(subregion_ids)
    if len(subregion_ids) != len(subregion_id_set):
        fail(errors, "Duplicate subregion IDs.")
    for item in subregions:
        if item.get("parent_region") not in region_ids:
            fail(errors, f"{item.get('id')}: subregion references unknown parent {item.get('parent_region')!r}.")
        if not item.get("layer") or not item.get("name"):
            fail(errors, f"{item.get('id')}: subregion needs a name and layer.")

    local_ids = [item.get("id", "") for item in local_connections]
    if len(local_ids) != len(set(local_ids)):
        fail(errors, "Duplicate intra-region connection IDs.")
    for edge in local_connections:
        source, target = edge.get("from"), edge.get("to")
        if source not in subregion_id_set or target not in subregion_id_set:
            fail(errors, f"{edge.get('id')}: local link references unknown subregion {source} -> {target}.")
        if edge.get("travel") not in {"both", "one_way"}:
            fail(errors, f"{edge.get('id')}: invalid local-link travel direction.")
        if edge.get("initial_state") not in {"open", "locked"}:
            fail(errors, f"{edge.get('id')}: invalid local-link initial_state.")
        if edge.get("initial_state") == "locked" and not str(edge.get("unlock_condition", "")).strip():
            fail(errors, f"{edge.get('id')}: locked local link needs an unlock condition.")

    lift_ids = [item.get("id", "") for item in elevators]
    if len(lift_ids) != len(set(lift_ids)):
        fail(errors, "Duplicate elevator IDs.")
    for lift in elevators:
        source, target = lift.get("from"), lift.get("to")
        if source not in subregion_id_set or target not in subregion_id_set:
            fail(errors, f"{lift.get('id')}: elevator references unknown subregion {source} -> {target}.")
        matching_lift_edges = [
            edge for edge in local_connections
            if edge.get("kind") == "lift"
            and {edge.get("from"), edge.get("to")} == {source, target}
            and edge.get("unlock_condition") == lift.get("unlock_condition")
        ]
        if not matching_lift_edges:
            fail(errors, f"{lift.get('id')}: no matching local lift connection exists.")
        if not str(lift.get("unlock_condition", "")).strip():
            fail(errors, f"{lift.get('id')}: lift contract needs an unlock condition.")

    # Fully unlocked local graphs must connect every subregion from that region's first-listed entry node.
    # 全部机关开启后，每个区域都必须能从清单首个入口节点到达所有小区域。
    subregions_by_parent: dict[str, list[dict[str, Any]]] = {}
    for subregion in subregions:
        subregions_by_parent.setdefault(subregion["parent_region"], []).append(subregion)

    for parent, members in subregions_by_parent.items():
        member_ids = {item["id"] for item in members}
        local_graph = {item["id"]: set() for item in members}
        for edge in local_connections:
            source, target = edge.get("from"), edge.get("to")
            if source not in member_ids or target not in member_ids:
                continue
            # Locked routes count in the fully unlocked graph; one-way drops remain directed.
            # 完全开启图包含锁定路线；单向落差仍保留方向性。
            local_graph[source].add(target)
            if edge.get("travel") == "both":
                local_graph[target].add(source)

        entry_id = members[0]["id"]
        visited = {entry_id}
        queue = deque([entry_id])
        while queue:
            current = queue.popleft()
            for target in local_graph[current] - visited:
                visited.add(target)
                queue.append(target)
        unreachable = sorted(member_ids - visited)
        if unreachable:
            fail(errors, f"{parent}: subregions unreachable even after all local gates open: {unreachable}.")

    # The five box-world hubs must preserve multiple vertical bands and real cross-layer links.
    # 五个箱庭核心枢纽必须保留多条高度带，以及真实跨层连接。
    layer_by_subregion = {item["id"]: item.get("layer", "") for item in subregions}
    for parent in ("A3", "A4", "A6", "A8", "A9"):
        members = subregions_by_parent.get(parent, [])
        distinct_layers = {item.get("layer", "") for item in members if item.get("layer")}
        cross_layer_edges = [
            edge for edge in local_connections
            if edge.get("from") in layer_by_subregion
            and edge.get("to") in layer_by_subregion
            and edge["from"].startswith(parent + "-")
            and edge["to"].startswith(parent + "-")
            and layer_by_subregion[edge["from"]] != layer_by_subregion[edge["to"]]
        ]
        if len(distinct_layers) < 3:
            fail(errors, f"{parent}: core box-world hub needs at least 3 distinct vertical layers.")
        if len(cross_layer_edges) < 2:
            fail(errors, f"{parent}: core box-world hub needs at least 2 explicit cross-layer connections.")

    # Every macro edge must name its actual source/destination subregions and route form.
    # 每条宏观连接都必须映射到真实子区域，并明确空间路线形态；这是设计追踪合同，不代表实机通过。
    layer_contracts = [edge.get("layer_contract") for edge in connections]
    if len(layer_contracts) != len(connections) or any(not isinstance(item, dict) for item in layer_contracts):
        fail(errors, "Every macro connection must provide a layer_contract.")
    subregion_by_id = {item.get("id"): item for item in subregions}
    for edge in connections:
        connection_id = edge.get("id", "<missing-id>")
        contract = edge.get("layer_contract")
        if not isinstance(contract, dict):
            continue
        source_id = contract.get("from_subregion")
        target_id = contract.get("to_subregion")
        source_subregion = subregion_by_id.get(source_id)
        target_subregion = subregion_by_id.get(target_id)
        if not source_subregion or not target_subregion:
            fail(errors, f"{connection_id}: layer contract references unknown subregion {source_id!r} -> {target_id!r}.")
            continue
        if source_subregion.get("parent_region") != edge.get("from"):
            fail(errors, f"{connection_id}: source subregion {source_id} does not belong to {edge.get('from')}.")
        if target_subregion.get("parent_region") != edge.get("to"):
            fail(errors, f"{connection_id}: destination subregion {target_id} does not belong to {edge.get('to')}.")
        if not str(contract.get("route_form", "")).strip():
            fail(errors, f"{connection_id}: layer contract needs a route_form.")
        if not str(contract.get("readability_contract", "")).strip():
            fail(errors, f"{connection_id}: layer contract needs a readability_contract.")
        if contract.get("status") != "design_contract_not_runtime_verified":
            fail(errors, f"{connection_id}: layer contract must remain explicitly unverified at runtime.")

    # Guard the connections whose vertical identity is essential to the box-world layout.
    # 对高架、落差、竖井和独立排水路线设置语义锚点，避免后续误改成普通地面门。
    expected_layer_pairs = {
        "C03": ("A2-S04", "A3-S04"),
        "C04": ("A2-S05", "A5-S03"),
        "C05": ("A3-S05", "A4-S01"),
        "C06": ("A4-S06", "A1-S04"),
        "C10": ("A6-S05", "A3-S06"),
        "C12": ("A7-S06", "A4-S05"),
        "C13": ("A7-S04", "A8-S01"),
        "C15": ("A8-S05", "A11-S01"),
        "C16": ("A3-S04", "A9-S03"),
        "C17": ("A9-S03", "A10-S04"),
        "C19": ("A10-S05", "A11-S02"),
        "C23": ("A9-S04", "A4-S01"),
        "C24": ("A1-S01", "A3-S03"),
    }
    for connection_id, expected_pair in expected_layer_pairs.items():
        edge = next((item for item in connections if item.get("id") == connection_id), None)
        contract = edge.get("layer_contract", {}) if edge else {}
        actual_pair = (contract.get("from_subregion"), contract.get("to_subregion"))
        if actual_pair != expected_pair:
            fail(errors, f"{connection_id}: critical route layer contract must remain {expected_pair}, found {actual_pair}.")

    # Narrative exploration gates connect places to ability, Resonance, story, and physical mechanisms.
    # 剧情探索门槛将地点与能力、鸣响、支线和地理机关连接起来。
    gate_contracts = data.get("exploration_gate_contracts", [])
    if len(gate_contracts) < 1:
        fail(errors, "At least one exploration gate contract is required.")
    gate_ids = [item.get("id", "") for item in gate_contracts]
    if len(gate_ids) != len(set(gate_ids)):
        fail(errors, "Duplicate exploration gate contract IDs.")
    for gate in gate_contracts:
        gate_id = gate.get("id", "<missing-id>")
        for field in ("name", "trigger", "visible_blocker", "destination", "narrative_result"):
            if not str(gate.get(field, "")).strip():
                fail(errors, f"{gate_id}: exploration gate needs {field}.")
        if gate.get("status") != "design_contract_not_runtime_verified":
            fail(errors, f"{gate_id}: design gate status must not imply runtime verification.")
        if not isinstance(gate.get("reward", []), list) or not gate.get("reward"):
            fail(errors, f"{gate_id}: exploration gate needs at least one reward.")
        if gate.get("required_ability") == "grappling_hook" and not gate.get("player_hint"):
            fail(errors, f"{gate_id}: grappling-hook gates must include a readable player hint.")
    story_geography = data.get("story_geography", [])
    if len(story_geography) != 15:
        fail(errors, f"Expected 15 story geography groups, found {len(story_geography)}.")
    story_ids = [item.get("id", "") for item in story_geography]
    if len(story_ids) != len(set(story_ids)):
        fail(errors, "Duplicate story geography IDs.")
    for place_group in story_geography:
        if not place_group.get("parent_macro") or not place_group.get("places"):
            fail(errors, f"{place_group.get('id', '<missing-id>')}: story geography needs a parent macro and places.")

    # Spatial anchors are part of the box-world contract, not decorative documentation.
    # 空间锚点属于箱庭结构合同，不只是说明文字。
    c05 = next((edge for edge in connections if edge.get("id") == "C05"), None)
    c05_spatial = c05.get("spatial_contract", {}) if c05 else {}
    if c05_spatial.get("route_layer") != "raised_pipe_walk":
        fail(errors, "C05 must branch from the raised pipe-walk.")
    if c05_spatial.get("from_region_anchor") != {"region": "A3", "x": 1600, "y_offset": -115}:
        fail(errors, "C05 spatial anchor must match the A3 raised sewer branch.")
    if c05_spatial.get("to_region_anchor") != {"region": "A4", "x": 180, "y_offset": -115, "spawn_side": "sewer_upper"}:
        fail(errors, "C05 must arrive on A4's supported upper inspection landing.")
    if c05_spatial.get("to_region_spawn") != {"region": "A4", "x": 180, "y_offset": -95, "spawn_side": "sewer_upper"}:
        fail(errors, "C05 Hero arrival must align with the A4 landing collision top, separately from the raised hatch anchor.")
    c13 = next((edge for edge in connections if edge.get("id") == "C13"), None)
    c13_spatial = c13.get("spatial_contract", {}) if c13 else {}
    if c13_spatial.get("route_layer") != "prison_maintenance_shaft_upper_entry":
        fail(errors, "C13 must remain on the prison maintenance-shaft upper route.")
    if c13_spatial.get("from_region_anchor") != {"region": "A7", "x": 2528, "y_offset": -180, "spawn_side": "maintenance_shaft_entry"}:
        fail(errors, "C13 A7 door anchor must remain on the elevated maintenance-shaft platform.")
    if c13_spatial.get("to_region_anchor") != {"region": "A8", "x": 72, "y_offset": -180, "spawn_side": "maintenance_shaft_return"}:
        fail(errors, "C13 A8 reverse door anchor must remain on the elevated tomb entry platform.")
    if c13_spatial.get("to_region_spawn") != {"region": "A8", "x": 190, "y_offset": -160, "spawn_side": "maintenance_shaft_entry"}:
        fail(errors, "C13 A8 arrival must be supported and clear of the return-door trigger.")
    if c13_spatial.get("return_spawn") != {"region": "A7", "x": 2340, "y_offset": -160, "spawn_side": "maintenance_shaft_return"}:
        fail(errors, "C13 reverse arrival must return to the upper prison ledge.")
    c02 = next((edge for edge in connections if edge.get("id") == "C02"), None)
    c02_gate = c02.get("progression_gate", {}) if c02 else {}
    if not c02 or c02.get("from") != "A1" or c02.get("to") != "A2" or c02.get("unlock_condition") != "village_defense_survived" or c02.get("opens_from") != "A1":
        fail(errors, "C02 must record the village-defense progression gate before the A1 north gate enters A2.")
    if c02_gate.get("interaction_id") != "north_gate" or c02_gate.get("before_unlock") != "enter_village_defense_demo_and_return_to_A1" or c02_gate.get("after_unlock") != "enter_A2_from_A1":
        fail(errors, "C02 progression_gate must describe the actual north-gate defense-then-entry flow.")
    c21 = next((edge for edge in connections if edge.get("id") == "C21"), None)
    c22 = next((edge for edge in connections if edge.get("id") == "C22"), None)
    if not c21 or c21.get("to") != "A13" or c21.get("unlock_condition") != "ending_candidate_is_not_human_grave_based_on_resonance_truth_anchors_and_exploration":
        fail(errors, "C21 must follow the resonance/truth-anchor/exploration ending evaluator, not a relationship flag.")
    if not c22 or c22.get("to") != "A13" or c22.get("initial_access") != "from_to" or c22.get("unlock_condition") != "reached_A12_via_A10":
        fail(errors, "C22 must route the main A12 path into A13 after reaching A12 via A10.")
    c19 = next((edge for edge in connections if edge.get("id") == "C19"), None)
    if not c19 or c19.get("from") != "A10" or c19.get("to") != "A11" or c19.get("final_direction") != "both":
        fail(errors, "C19 must remain a bidirectional hidden connection between A10 and A11.")
    h08 = next((region for region in hidden if region.get("id") == "H08"), None)
    h08_exit = h08.get("secondary_exit", {}) if h08 else {}
    if h08_exit.get("to") != "A13" or h08_exit.get("unlock_condition") != "ending_candidate_is_not_human_grave_based_on_resonance_truth_anchors_and_exploration":
        fail(errors, "H08 must converge on A13 only when the shared ending evaluator selects a non-human-grave candidate.")
    c04 = next((edge for edge in connections if edge.get("id") == "C04"), None)
    c04_spatial = c04.get("spatial_contract", {}) if c04 else {}
    if c04_spatial.get("route_layer") != "old_pilgrim_canopy_highroad":
        fail(errors, "C04 must remain an elevated old-pilgrim canopy shortcut.")
    if c04_spatial.get("from_region_anchor") != {"region": "A2", "x": 1880, "y_offset": -115}:
        fail(errors, "C04 A2 return door must align with the old-pilgrim canopy ledge.")
    if c04_spatial.get("to_region_anchor") != {"region": "A5", "x": 520, "y_offset": -140, "spawn_side": "old_pilgrim_highroad"}:
        fail(errors, "C04 A5 door must remain on the upper battlement approach.")
    if c04_spatial.get("return_spawn") != {"region": "A2", "x": 1750, "y_offset": -140, "spawn_side": "old_pilgrim_highroad"}:
        fail(errors, "C04 A2 arrival must land on the canopy approach platform.")
    if c04_spatial.get("from_region_spawn") != {"region": "A5", "x": 650, "y_offset": -85, "spawn_side": "old_pilgrim_highroad"}:
        fail(errors, "C04 A5 arrival must land on the battlement approach platform.")

    c03 = next((edge for edge in connections if edge.get("id") == "C03"), None)
    c03_spatial = c03.get("spatial_contract", {}) if c03 else {}
    if c03_spatial.get("from_region_anchor") != {"region": "A2", "x": 2240, "y_offset": -160}:
        fail(errors, "C03 main exit must remain on the A2 canopy high road.")
    if not (c03_spatial.get("return_spawn", {}).get("region") == "A2" and c03_spatial.get("return_spawn", {}).get("x") == 2120 and c03_spatial.get("return_spawn", {}).get("y_offset") == -140 and c03_spatial.get("return_spawn", {}).get("spawn_side") == "east"):
        fail(errors, "C03 return spawn must align with the A2 canopy approach.")
    c16 = next((edge for edge in connections if edge.get("id") == "C16"), None)
    c16_spatial = c16.get("spatial_contract", {}) if c16 else {}
    if c16_spatial.get("route_layer") != "eastern_rooftop_lift":
        fail(errors, "C16 must use the eastern rooftop lift lane.")
    if c16_spatial.get("from_region_anchor") != {"region": "A3", "x": 2040, "y_offset": -70}:
        fail(errors, "C16 spatial anchor must match the A3 eastern rooftop lift.")
    if c16_spatial.get("return_spawn") != {"region": "A3", "x": 1960, "y_offset": -70}:
        fail(errors, "C16 return spawn must stay aligned with the eastern rooftop lift and clear of H05.")
    if c16_spatial.get("to_region_anchor") != {"region": "A9", "x": 520, "y_offset": -110}:
        fail(errors, "C16 A9-side door must stay on the rooftop ledge.")
    if c16_spatial.get("to_region_spawn") != {"region": "A9", "x": 610, "y_offset": -110}:
        fail(errors, "C16 arrival in A9 must land on the same rooftop ledge.")
    c09 = next((edge for edge in connections if edge.get("id") == "C09"), None)
    c09_spatial = c09.get("spatial_contract", {}) if c09 else {}
    if c09_spatial.get("from_region_anchor") != {"region": "A5", "x": 2250, "y_offset": -90}:
        fail(errors, "C09 main exit must leave A5 from the upper battlefield parapet.")
    if c09_spatial.get("to_region_anchor") != {"region": "A6", "x": 160, "y_offset": -90, "spawn_side": "battlefield_entry"}:
        fail(errors, "C09 arrival must land on the supported upper west bridge in A6.")
    if c09_spatial.get("return_spawn") != {"region": "A5", "x": 2165, "y_offset": -55, "spawn_side": "monastery_return"}:
        fail(errors, "C09 reverse transition must return to A5's supported lower approach ledge, not the ground below the high door.")
    c18 = next((edge for edge in connections if edge.get("id") == "C18"), None)
    c18_spatial = c18.get("spatial_contract", {}) if c18 else {}
    if c18_spatial.get("from_region_anchor") != {"region": "A9", "x": 900, "y_offset": 0, "spawn_side": "inner_city_side_gate"}:
        fail(errors, "C18 A9 door must remain at its authored ground-level anchor.")
    if c18_spatial.get("to_region_anchor") != {"region": "A12", "x": 520, "y_offset": 0, "spawn_side": "inner_city_side_gate"}:
        fail(errors, "C18 A12 door must remain at its authored ground-level anchor.")
    if not (c18_spatial.get("return_spawn", {}).get("region") == "A9" and c18_spatial.get("return_spawn", {}).get("x") == 980 and c18_spatial.get("return_spawn", {}).get("y_offset") == 0 and c18_spatial.get("return_spawn", {}).get("spawn_side") == "inner_city_side_gate"):
        fail(errors, "C18 A9 return spawn must stay midway between its door and the rest point.")
    if c18_spatial.get("from_region_spawn") != {"region": "A12", "x": 650, "y_offset": 0, "spawn_side": "inner_city_side_gate"}:
        fail(errors, "C18 A12 arrival must remain clear of the cathedral entrance.")
    c17 = next((edge for edge in connections if edge.get("id") == "C17"), None)
    c17_spatial = c17.get("spatial_contract", {}) if c17 else {}
    if c17_spatial.get("from_region_anchor") != {"region": "A9", "x": 2350, "y_offset": -180}:
        fail(errors, "C17 main exit must use the elevated cathedral roof approach.")
    c10 = next((edge for edge in connections if edge.get("id") == "C10"), None)
    c10_spatial = c10.get("spatial_contract", {}) if c10 else {}
    if c10_spatial.get("from_region_anchor") != {"region": "A6", "x": 2230, "y_offset": -55}:
        fail(errors, "C10 must remain an elevated bell-tower drop in A6.")
    if c10_spatial.get("return_spawn") != {"region": "A6", "x": 2100, "y_offset": -90}:
        fail(errors, "C10 return spawn must land on the upper monastery approach.")
    h05 = next((region for region in hidden if region.get("id") == "H05"), None)
    h05_return_anchor = h05.get("secondary_exit", {}).get("return_spatial_anchor", {}) if h05 else {}
    if h05_return_anchor != {"region": "A3", "x": 1870, "layer": "street-level-return"}:
        fail(errors, "H05 return gate must remain spatially separated from A3 C10 and C16.")
    expected_a4_spatial = {
        "C06": ("reservoir_ground_return", "from_region_anchor", {"region": "A4", "x": 2220, "y_offset": 0}),
        "C07": ("middle_tomb_waterway_ledge", "from_region_anchor", {"region": "A4", "x": 1320, "y_offset": -85}),
        "C12": ("low_supply_tunnel_ledge", "to_region_anchor", {"region": "A4", "x": 1050, "y_offset": -75}),
        "C23": ("upper_royal_drain_pipe", "to_region_anchor", {"region": "A4", "x": 1650, "y_offset": -105}),
    }
    for connection_id, (route_layer, anchor_field, expected_anchor) in expected_a4_spatial.items():
        edge = next((item for item in connections if item.get("id") == connection_id), None)
        spatial = edge.get("spatial_contract", {}) if edge else {}
        if spatial.get("route_layer") != route_layer or spatial.get(anchor_field) != expected_anchor:
            fail(errors, f"{connection_id} must match its declared A4 layered route anchor.")
    c07_spatial = next((edge for edge in connections if edge.get("id") == "C07"), {}).get("spatial_contract", {})
    if not (c07_spatial.get("return_spawn", {}).get("region") == "A4" and c07_spatial.get("return_spawn", {}).get("x") == 1410 and c07_spatial.get("return_spawn", {}).get("y_offset") == -85 and c07_spatial.get("return_spawn", {}).get("spawn_side") == "royal_tomb_waterway"):
        fail(errors, "C07 return spawn must sit within interaction range of the middle ledge door.")
    for connection_id, expected_spawn in {
        "C05": {"region": "A3", "x": 1380, "y_offset": -115},
        "C12": {"region": "A4", "x": 960, "y_offset": -75},
        "C23": {"region": "A4", "x": 1540, "y_offset": -120},
    }.items():
        edge = next((item for item in connections if item.get("id") == connection_id), None)
        spatial = edge.get("spatial_contract", {}) if edge else {}
        actual_spawn = spatial.get("return_spawn", {})
        if any(actual_spawn.get(key) != value for key, value in expected_spawn.items()):
            fail(errors, f"{connection_id} return spawn must match its elevated destination ledge.")
    c23 = next((edge for edge in connections if edge.get("id") == "C23"), None)
    c23_spatial = c23.get("spatial_contract", {}) if c23 else {}
    if c23_spatial.get("from_region_anchor") != {"region": "A9", "x": 740, "y_offset": -150}:
        fail(errors, "C23 A9-side door must branch from the upper service ledge.")
    if c23_spatial.get("from_region_spawn") != {"region": "A9", "x": 650, "y_offset": -150}:
        fail(errors, "C23 arrival in A9 must land on the upper service ledge.")
    c12_spatial = next((edge for edge in connections if edge.get("id") == "C12"), {}).get("spatial_contract", {})
    if c12_spatial.get("from_region_spawn") != {"region": "A7", "x": 610, "y_offset": 0, "spawn_side": "supply_tunnel"}:
        fail(errors, "C12 return to A7 must preserve its authored prison-side landing.")
    if not (c23_spatial.get("return_spawn", {}).get("region") == "A4" and c23_spatial.get("return_spawn", {}).get("x") == 1540 and c23_spatial.get("return_spawn", {}).get("y_offset") == -120 and c23_spatial.get("return_spawn", {}).get("spawn_side") == "royal_drain"):
        fail(errors, "C23 return spawn must land on the supported lip, clear of the A4 door trigger.")

    # C24 is the alternate A1-to-A3 route added after the village defense.
    # C24 是村庄防卫后开放的 A1 → A3 替代路线。
    c24 = next((edge for edge in connections if edge.get("id") == "C24"), None)
    if c24 is None:
        fail(errors, "Missing C24: post-defense A1-to-A3 drainage route.")
    else:
        expected_c24 = {
            "from": "A1",
            "to": "A3",
            "kind": "shortcut",
            "initial_access": "blocked",
            "final_direction": "both",
            "unlock_condition": "village_defense_survived",
            "opens_from": "A1",
        }
        for key, value in expected_c24.items():
            if c24.get(key) != value:
                fail(errors, f"C24: expected {key}={value!r}, got {c24.get(key)!r}.")

        expected_c24_spatial = {
            "route_layer": "old_drainage_passage",
            "from_region_anchor": {"region": "A1", "x": 100, "y_offset": 0},
            "to_region_anchor": {"region": "A3", "x": 520, "y_offset": 0},
            "to_region_spawn": {"region": "A3", "x": 700, "y_offset": 0, "spawn_side": "village_city_cut"},
            "return_spawn": {"region": "A1", "x": 350, "y_offset": 0, "spawn_side": "city_cut_return"},
            "intermediate_scene": {
                "scene_path": "scenes/old_drain_exploration.tscn",
                "first_visit_spawn_side": "village_entry",
                "a3_entry_spawn_side": "city_side_entry",
                "reservoir_return_spawn_side": "reservoir_link",
                "a3_link_unlock_flag": "opened_old_drainage_link_from_A4",
            },
        }
        c24_spatial = c24.get("spatial_contract", {})
        for key, value in expected_c24_spatial.items():
            if c24_spatial.get(key) != value:
                fail(errors, f"C24: spatial_contract.{key} must match the implemented low drainage route.")

    for edge in connections:
        source, target = edge.get("from"), edge.get("to")
        if source not in region_ids or target not in region_ids:
            fail(errors, f"{edge.get('id')}: connection references unknown area {source} -> {target}.")
        if edge.get("kind") in {"shortcut", "secret", "ending"} and edge.get("initial_access") == "blocked":
            if not edge.get("unlock_condition", "").strip():
                fail(errors, f"{edge.get('id')}: blocked shortcut/secret/ending edge lacks unlock condition.")
            if edge.get("opens_from") not in {source, target}:
                fail(errors, f"{edge.get('id')}: blocked edge must identify a valid side that opens it.")
        if edge.get("initial_access") not in {"blocked", "from_to", "both"}:
            fail(errors, f"{edge.get('id')}: invalid initial_access value.")
        if edge.get("final_direction") not in {"forward", "both"}:
            fail(errors, f"{edge.get('id')}: invalid final_direction value.")

    for node in primary_route:
        if node not in region_ids:
            fail(errors, f"Primary route references unknown region {node}.")
    if primary_route and (primary_route[0] != "A0" or primary_route[-1] != "A12"):
        fail(errors, "Primary route should start at A0 and end at A12.")

    initial_graph = build_graph(region_ids, connections, initial=True, include_hidden=False)
    initial_reached = reachable(initial_graph, "A0")
    route_missing = [node for node in primary_route if node not in initial_reached]
    if route_missing:
        fail(errors, f"Primary route is not reachable in the initial map state: {route_missing}.")

    # The shortest initial route to the inner city may not use hidden regions or
    # require an unopened shortcut; this is the core anti-softlock / anti-skip check.
    path_to_throne = shortest_path(initial_graph, "A0", "A12")
    if not path_to_throne:
        fail(errors, "No initial path from prologue to the throne region.")
    else:
        expected_order = {node: i for i, node in enumerate(primary_route)}
        if any(node not in expected_order for node in path_to_throne):
            fail(errors, f"Initial throne path uses a region outside the primary route: {path_to_throne}.")
        elif [expected_order[node] for node in path_to_throne] != sorted(expected_order[node] for node in path_to_throne):
            fail(errors, f"Initial throne path violates primary story order: {path_to_throne}.")

    final_graph = build_graph(all_ids, connections, hidden, initial=False, include_hidden=True)
    for candidate in provisional:
        parent = candidate.get("parent")
        candidate_id = candidate.get("id")
        if parent in final_graph and candidate_id in final_graph:
            final_graph[parent].add(candidate_id)
            final_graph[candidate_id].add(parent)
    final_reached = reachable(final_graph, "A0")
    unreachable = sorted(all_ids - final_reached)
    if unreachable:
        fail(errors, f"Regions unreachable after all intended gates open: {unreachable}.")

    # A loop is only real if each segment can be traversed in the final opened state.
    # 回环必须在所有预期门打开后逐段可走；仅仅存在无向连线记录并不代表回程成立。
    final_primary_graph = build_graph(region_ids, connections, initial=False, include_hidden=False)
    for loop in loops:
        path = loop.get("path", [])
        if len(path) < 4 or path[0] != path[-1]:
            fail(errors, f"{loop.get('id')}: loop path must return to its start.")
            continue
        path_edges = list(zip(path, path[1:]))
        loop_unlock_conditions: set[str] = set()
        for source, target in path_edges:
            matching_edges = [
                edge for edge in connections
                if {edge.get("from"), edge.get("to")} == {source, target}
            ]
            if not matching_edges:
                fail(errors, f"{loop.get('id')}: no macro edge for {source} <-> {target}.")
                continue
            if target not in final_primary_graph.get(source, set()):
                fail(
                    errors,
                    f"{loop.get('id')}: final map direction cannot traverse {source} -> {target}.",
                )
            loop_unlock_conditions.update(
                str(edge.get("unlock_condition", "")).strip()
                for edge in matching_edges
                if str(edge.get("unlock_condition", "")).strip()
            )
        if not loop.get("requires"):
            fail(errors, f"{loop.get('id')}: loop must list its unlock requirements.")
        else:
            declared_requirements = set(loop.get("requires", []))
            if declared_requirements != loop_unlock_conditions:
                fail(
                    errors,
                    f"{loop.get('id')}: declared loop requirements {sorted(declared_requirements)} "
                    f"do not match blocked-edge gates {sorted(loop_unlock_conditions)}.",
                )

    source_ids = [item.get("source_id", "") for item in sources]
    if len(sources) != 8:
        fail(errors, f"Expected 8 resonance progression sources, found {len(sources)}.")
    if len(source_ids) != len(set(source_ids)):
        fail(errors, "Duplicate resonance source IDs.")
    if any(not source_id.strip() for source_id in source_ids):
        fail(errors, "Every resonance progression event needs a stable source_id.")

    if sources:
        first_source = sources[0]
        if first_source.get("id") != "R01" or int(first_source.get("resonance_delta", -1)) != 0:
            fail(errors, "R01 must record the first anomaly and unlock sight without duplicating the A0 resonance baseline.")
        if first_source.get("unlock_ability") != "resonance_sight":
            fail(errors, "R01 must unlock the existing resonance_sight ability.")

    expected_ancient = int(data.get("ancient_exposure_baseline_at_prologue", 0))
    for source in sources:
        expected_ancient += int(source.get("ancient_exposure_delta", 0))
        declared_ancient = source.get("ancient_exposure_after")
        if declared_ancient is not None and expected_ancient != int(declared_ancient):
            fail(
                errors,
                f"{source.get('id')}: expected cumulative ancient exposure {expected_ancient}, "
                f"but manifest declares {declared_ancient}.",
            )

    expected_resonance = int(data.get("resonance_baseline_at_prologue", 0))
    for source in sources:
        # Some one-time clues establish a floor rather than adding a delta.
        # R01 unlocks Resonance Sight and guarantees at least 12 resonance,
        # but must not grant the same baseline twice if the prologue already did.
        expected_resonance = max(
            expected_resonance + int(source.get("resonance_delta", 0)),
            int(source.get("minimum_resonance", 0)),
        )
        actual = int(source.get("resonance_after", -1))
        if expected_resonance != actual:
            fail(
                errors,
                f"{source.get('id')}: expected cumulative resonance {expected_resonance}, "
                f"but manifest declares {actual}.",
            )
        if int(source.get("resonance_delta", -1)) < 0:
            fail(errors, f"{source.get('id')}: resonance delta cannot be negative.")

    for secret in hidden:
        missing_sources = sorted(set(secret.get("required_source_ids", [])) - set(source_ids))
        if missing_sources:
            fail(errors, f"{secret.get('id')}: references missing resonance sources {missing_sources}.")
    h06 = next((item for item in hidden if item.get("id") == "H06"), None)
    if h06 and set(h06.get("required_source_ids", [])) != {"anomaly_bell_retiming", "anomaly_erased_royal_name"}:
        fail(errors, "H06 must require the bell-retiming clue and the royal-inscription clue, not the unrelated erased-street sign.")
    h07 = next((item for item in hidden if item.get("id") == "H07"), None)
    if h07 and (int(h07.get("min_outer_exposure", 0)) < 12 or h07.get("requires_outer_god_resonance") is not True):
        fail(errors, "H07 must require the outer-god resonance story fact and outer exposure >= 12.")
    h08 = next((item for item in hidden if item.get("id") == "H08"), None)
    r08 = next((item for item in sources if item.get("id") == "R08"), None)
    if h08 and int(h08.get("min_outer_exposure", 0)) < 18:
        fail(errors, "H08 must require outer exposure >= 18.")
    if r08 and int(r08.get("outer_exposure_after_if_qualified", 0)) != 18:
        fail(errors, "R08 must define the conditional outer exposure target of 18.")
    if r08 and int(r08.get("requires_prior_outer_exposure", 0)) < 12:
        fail(errors, "R08 must not grant the deep outer-exposure target without the prior outer-god resonance condition.")

    hidden_ids = [item.get("id", "") for item in hidden]
    if len(hidden_ids) != len(set(hidden_ids)):
        fail(errors, "Duplicate hidden region IDs.")
    if set(hidden_ids) != {f"H{i:02d}" for i in range(1, 9)}:
        fail(errors, f"Canonical hidden IDs must remain H01-H08, found {sorted(hidden_ids)}.")

    # Provisional graybox rooms are tracked separately so illustrative content does not
    # silently become canon or a required hidden-region acceptance gate.
    # 临时候选灰盒区域单独登记，避免示例内容被默认为正式设定或必验区域。
    provisional_ids_list = [item.get("id", "") for item in provisional]
    if len(provisional_ids_list) != len(set(provisional_ids_list)):
        fail(errors, "Duplicate provisional region IDs.")
    if provisional_ids & (region_ids | set(hidden_ids)):
        fail(errors, f"Provisional region IDs collide with canonical IDs: {sorted(provisional_ids & (region_ids | set(hidden_ids)))}.")
    for candidate in provisional:
        cid = candidate.get("id", "<unknown>")
        if candidate.get("parent") not in region_ids:
            fail(errors, f"{cid}: provisional region has unknown parent {candidate.get('parent')}.")
        if not candidate.get("scene_path", "").strip():
            fail(errors, f"{cid}: provisional region needs a scene path.")
        if candidate.get("story_canon") is not False:
            fail(errors, f"{cid}: provisional region must explicitly remain non-canonical.")
        if candidate.get("acceptance_required") is not False:
            fail(errors, f"{cid}: provisional region must not be a core acceptance requirement.")
        if candidate.get("return_to_parent") is not True:
            fail(errors, f"{cid}: provisional region must document a return to its parent.")

    for secret in hidden:
        sid = secret.get("id", "<unknown>")
        parent = secret.get("parent")
        if parent not in region_ids:
            fail(errors, f"{sid}: unknown parent region {parent}.")
        if not 0 <= int(secret.get("min_resonance", -1)) <= 100:
            fail(errors, f"{sid}: resonance threshold must be 0..100.")
        if not 0 <= int(secret.get("min_ancient_exposure", -1)) <= 100:
            fail(errors, f"{sid}: ancient exposure threshold must be 0..100.")
        if not 0 <= int(secret.get("min_outer_exposure", -1)) <= 100:
            fail(errors, f"{sid}: outer exposure threshold must be 0..100.")
        if secret.get("requires_sight_active") is not True:
            fail(errors, f"{sid}: hidden entrance must require active Resonance Sight.")
        if secret.get("interaction_key") != "E":
            fail(errors, f"{sid}: hidden entrance should use the shared E interaction flow.")
        if secret.get("persistent_on_open") is not True:
            fail(errors, f"{sid}: opened state must persist.")
        if secret.get("return_to_parent") is not True:
            fail(errors, f"{sid}: hidden area must have a reliable return to its parent.")
        secondary = secret.get("secondary_exit")
        if secondary:
            destination = secondary.get("to")
            if destination not in region_ids:
                fail(errors, f"{sid}: secondary exit points to unknown region {destination}.")
            if not secondary.get("unlock_condition", "").strip():
                fail(errors, f"{sid}: secondary exit must specify a progression condition.")
            if secondary.get("opens_from") not in {sid, parent, destination}:
                fail(errors, f"{sid}: secondary exit must identify the side that opens it.")
            if destination in primary_route:
                source_index = primary_route.index(parent) if parent in primary_route else -1
                target_index = primary_route.index(destination)
                if target_index > source_index and secondary.get("requires_target_already_reached") is not True:
                    fail(errors, f"{sid}: secondary exit could bypass main progression to {destination}.")
        else:
            fail(errors, f"{sid}: a hidden area needs a safe secondary exit or an explicit single-entry return design.")


    # Keep resonance thresholds reachable from a documented, one-time source path.
    progression = data.get("resonance_progression_contract", [])
    if len(progression) != 8:
        fail(errors, f"Expected 8 resonance progression milestones, found {len(progression)}.")

    milestone_ids = [item.get("id", "") for item in progression]
    if len(milestone_ids) != len(set(milestone_ids)):
        fail(errors, "Duplicate resonance progression milestone IDs.")

    progression_source_ids = [item.get("source_id", "") for item in progression]
    nonempty_source_ids = [source_id for source_id in progression_source_ids if source_id]
    if len(nonempty_source_ids) != len(progression_source_ids):
        fail(errors, "Every resonance milestone must define a stable source_id.")
    if len(nonempty_source_ids) != len(set(nonempty_source_ids)):
        fail(errors, "Duplicate resonance progression source IDs.")

    hidden_by_id = {item.get("id", ""): item for item in hidden}
    running_resonance = int(data.get("resonance_baseline_at_prologue", 0))
    ancient_growth = int(data.get("ancient_exposure_baseline_at_prologue", 0))
    outer_growth = int(data.get("outer_exposure_baseline_at_prologue", 0))
    progression_by_source = {item.get("source_id", ""): item for item in progression}
    for milestone in progression:
        mid = milestone.get("id", "<unknown>")
        if milestone.get("region") not in region_ids:
            fail(errors, f"{mid}: resonance source references unknown region {milestone.get('region')}.")

        if "resonance_target" in milestone:
            target = int(milestone["resonance_target"])
            if target < running_resonance or not 0 <= target <= 100:
                fail(errors, f"{mid}: resonance_target must be a reachable value from the previous source.")
            running_resonance = max(running_resonance, target)
        else:
            delta = int(milestone.get("resonance_delta", 0))
            if delta <= 0:
                fail(errors, f"{mid}: non-target resonance_delta must be positive.")
            running_resonance += max(0, delta)

        if milestone.get("cumulative_target") != running_resonance:
            fail(errors, f"{mid}: cumulative_target must match the one-time resonance source curve.")

        ancient_growth = max(ancient_growth, max(0, int(milestone.get("ancient_exposure_floor", 0))))
        ancient_growth += max(0, int(milestone.get("ancient_exposure_delta", 0)))
        outer_growth = max(outer_growth, max(0, int(milestone.get("outer_exposure_floor", 0))))
        outer_growth += max(0, int(milestone.get("outer_exposure_delta", 0)))

        for target_id in milestone.get("enables", []):
            secret = hidden_by_id.get(target_id)
            if secret is None:
                fail(errors, f"{mid}: unlocks unknown hidden region {target_id}.")
            elif int(secret.get("min_resonance", -1)) != int(milestone.get("cumulative_target", -2)):
                fail(errors, f"{mid}: resonance target does not match {target_id}'s gate.")

    source_specs = data.get("resonance_sources", [])
    source_spec_ids = [item.get("id", "") for item in source_specs]
    if len(source_spec_ids) != len(set(source_spec_ids)):
        fail(errors, "Duplicate detailed resonance source IDs.")
    if set(source_spec_ids) != set(milestone_ids):
        fail(errors, "Detailed resonance sources do not match progression milestones.")
    source_by_id = {item.get("id", ""): item for item in source_specs}
    for milestone in progression:
        spec = source_by_id.get(milestone.get("id", ""))
        if spec is None:
            continue
        comparisons = {
            "source_id": milestone.get("source_id"),
            "resonance_delta": milestone.get("resonance_delta", 0),
            "resonance_after": milestone.get("cumulative_target"),
            "ancient_exposure_delta": milestone.get("ancient_exposure_delta", 0),
            "outer_exposure_delta": milestone.get("outer_exposure_delta", 0),
        }
        for key, expected in comparisons.items():
            if spec.get(key, 0 if key != "source_id" else "") != expected:
                fail(errors, f"{milestone.get('id')}: detailed resonance source disagrees on {key}.")
        if spec.get("ancient_exposure_floor") != milestone.get("ancient_exposure_floor"):
            fail(errors, f"{milestone.get('id')}: ancient exposure floor differs between source tables.")
        if spec.get("outer_exposure_floor") != milestone.get("outer_exposure_floor"):
            fail(errors, f"{milestone.get('id')}: outer exposure floor differs between source tables.")
        if spec.get("outer_exposure_requires") != milestone.get("outer_exposure_requires"):
            fail(errors, f"{milestone.get('id')}: outer exposure condition differs between source tables.")

    known_source_ids = set(nonempty_source_ids)
    story_effects = data.get("story_state_effects", [])
    story_outer_seed = max(
        (
            int(effect.get("effects", {}).get("outer_exposure_min", 0))
            for effect in story_effects
        ),
        default=0,
    )
    outer_story_triggers = {str(effect.get("trigger", "")).split(".")[-1] for effect in story_effects}
    for secret in hidden:
        sid = secret.get("id", "<unknown>")
        required_sources = secret.get("required_source_ids", [])
        if len(required_sources) != len(set(required_sources)):
            fail(errors, f"{sid}: duplicate required resonance source IDs.")
        unknown_sources = sorted(set(required_sources) - known_source_ids)
        if unknown_sources:
            fail(errors, f"{sid}: references unknown resonance sources {unknown_sources}.")
        min_sources = int(secret.get("min_distinct_anomaly_sources", 0))
        if min_sources < 0 or min_sources > len(required_sources):
            fail(errors, f"{sid}: min_distinct_anomaly_sources exceeds its listed source prerequisites.")
        if min_sources and len(required_sources) < min_sources:
            fail(errors, f"{sid}: listed source prerequisites do not satisfy min_distinct_anomaly_sources.")
        if int(secret.get("min_ancient_exposure", 0)) > ancient_growth:
            fail(errors, f"{sid}: ancient exposure gate exceeds all planned source gains.")
        planned_outer_max = max(outer_growth, story_outer_seed)
        if int(secret.get("min_outer_exposure", 0)) > planned_outer_max:
            fail(errors, f"{sid}: outer exposure gate exceeds all planned source / story gains.")
        if secret.get("requires_outer_god_resonance") is True and "mark_outer_god_resonance" not in outer_story_triggers:
            fail(errors, f"{sid}: outer-god gate has no story-state source contract.")

    # Ensure the three intended macro loops are recorded, not merely implicit.
    expected_loops = {"L01", "L02", "L03"}
    if {loop.get("id") for loop in loops} != expected_loops:
        fail(errors, f"Expected macro loop IDs {sorted(expected_loops)}.")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    default_path = Path(__file__).with_name("world_map_topology.json")
    parser.add_argument("--topology", type=Path, default=default_path, help="Path to topology JSON.")
    args = parser.parse_args()

    try:
        data = json.loads(args.topology.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"ERROR: Could not load topology data: {exc}", file=sys.stderr)
        return 2

    errors = validate(data)
    if errors:
        print("WORLD MAP TOPOLOGY VALIDATION FAILED")
        for error in errors:
            print(f" - {error}")
        return 1

    print("WORLD MAP TOPOLOGY STATIC CHECK PASSED")
    print(f" - Primary regions: {len(data['regions'])}")
    print(f" - Macro connections: {len(data['connections'])}")
    print(f" - Main-route nodes: {len(data['primary_route'])}")
    print(f" - Hidden subregions: {len(data['hidden_regions'])}")
    print(f" - Resonance progression milestones: {len(data.get('resonance_progression_contract', []))}")
    print(f" - Resonance source events: {len(data['resonance_sources'])}")
    print(f" - Macro loops: {len(data['loops'])}")
    print(" - Main route reaches A12 without hidden regions or locked shortcuts.")
    print(" - All primary and hidden regions become reachable after intended gates open.")
    print("NOTE: This does not replace Godot runtime / graybox validation.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
