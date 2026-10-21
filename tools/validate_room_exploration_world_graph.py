#!/usr/bin/env python3
"""Validate the design-only room-level exploration graph.

This validates topology contracts only. It does not prove Godot scenes, physics,
door transitions, ability gates, or art are implemented or playable.
"""
from __future__ import annotations

import json
import sys
from collections import defaultdict, deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GRAPH_PATH = ROOT / "tools" / "room_exploration_world_graph.json"
MACRO_PATH = ROOT / "tools" / "world_map_topology.json"


def fail(message: str) -> None:
    print(f"[FAIL] {message}")


def main() -> int:
    graph = json.loads(GRAPH_PATH.read_text(encoding="utf-8"))
    macro = json.loads(MACRO_PATH.read_text(encoding="utf-8"))
    errors: list[str] = []
    rooms = graph.get("rooms", [])
    connections = graph.get("connections", [])
    room_by_id = {room.get("id"): room for room in rooms}
    room_ids = set(room_by_id)
    edge_ids = [edge.get("id") for edge in connections]

    if len(room_by_id) != len(rooms):
        errors.append("room IDs are not unique")
    if len(set(edge_ids)) != len(edge_ids):
        errors.append("connection IDs are not unique")

    macro_ids = {edge["id"] for edge in macro.get("connections", [])}
    room_macro_ids = {edge["id"] for edge in connections if edge.get("id", "").startswith("C")}
    expected_macro_ids = {f"C{i:02d}" for i in range(1, 25)}
    if room_macro_ids != expected_macro_ids:
        errors.append(f"macro connection mapping mismatch: missing={sorted(expected_macro_ids-room_macro_ids)}, extra={sorted(room_macro_ids-expected_macro_ids)}")
    if macro_ids != expected_macro_ids:
        errors.append("source macro topology no longer contains the expected C01-C24 connection set")

    for edge in connections:
        if edge.get("from") not in room_ids:
            errors.append(f"{edge.get('id')}: unknown source room {edge.get('from')}")
        if edge.get("to") not in room_ids:
            errors.append(f"{edge.get('id')}: unknown target room {edge.get('to')}")
        if edge.get("direction") not in {"both", "forward"}:
            errors.append(f"{edge.get('id')}: invalid direction {edge.get('direction')}")
        if edge.get("direction") == "forward" and edge.get("kind") != "ending" and edge.get("id") not in {"C01", "C06"}:
            errors.append(f"{edge.get('id')}: unexpected one-way edge outside approved transition contracts")

    regions = graph.get("regions", [])
    region_ids = {region.get("id") for region in regions}
    if region_ids != {f"A{i}" for i in range(14)}:
        errors.append("region inventory must contain exactly A0-A13")
    for region in regions:
        listed = region.get("room_ids", [])
        if len(listed) < 3:
            errors.append(f"{region.get('id')}: fewer than three room design nodes")
        for room_id in listed:
            if room_id not in room_ids:
                errors.append(f"{region.get('id')}: room list references unknown {room_id}")
            elif room_by_id[room_id].get("region") != region.get("id"):
                errors.append(f"{room_id}: room's region field disagrees with region inventory")

    shapes = {room.get("shape") for room in rooms}
    if not {"compact", "wide", "tall"}.issubset(shapes):
        errors.append(f"room shape variety incomplete: {sorted(shapes)}")

    # Test structural reachability with all gates considered potentially unlockable.
    adjacency: dict[str, set[str]] = defaultdict(set)
    directed: dict[str, set[str]] = defaultdict(set)
    for edge in connections:
        source, target = edge.get("from"), edge.get("to")
        if source not in room_ids or target not in room_ids:
            continue
        adjacency[source].add(target)
        adjacency[target].add(source)
        directed[source].add(target)
        if edge.get("direction") == "both":
            directed[target].add(source)

    start = "A0-R01"
    reached = set()
    queue = deque([start])
    while queue:
        current = queue.popleft()
        if current in reached:
            continue
        reached.add(current)
        queue.extend(adjacency[current] - reached)
    disconnected = sorted(room_ids - reached)
    if disconnected:
        errors.append(f"rooms disconnected from prologue in undirected design graph: {disconnected}")

    # Mainline should be traversable in the declared direction from start to terminal layer.
    reached_directed = set()
    queue = deque([start])
    while queue:
        current = queue.popleft()
        if current in reached_directed:
            continue
        reached_directed.add(current)
        queue.extend(directed[current] - reached_directed)
    for required in graph.get("acceptance_contract", {}).get("required_mainline", []):
        if not any(room_by_id[r].get("region") == required for r in reached_directed if r in room_by_id):
            errors.append(f"mainline region {required} is not directionally reachable from {start}")

    hidden_ids = {f"H{i:02d}" for i in range(1, 9)}
    actual_hidden = {region_id for region_id in region_ids if region_id.startswith("H")}
    if actual_hidden:
        errors.append("hidden regions must be room subgraphs, not entries in the primary region inventory")
    for hidden_id in hidden_ids:
        hidden_room = f"{hidden_id}-R01"
        if hidden_room not in room_ids:
            errors.append(f"missing hidden room {hidden_room}")
        if not any(edge.get("id") == f"{hidden_id}-ENTRY" and edge.get("to") == hidden_room for edge in connections):
            errors.append(f"missing hidden-entry contract for {hidden_id}")
    for edge in connections:
        if edge.get("id") in expected_macro_ids:
            source_macro = next(item for item in macro["connections"] if item["id"] == edge["id"])
            if room_by_id[edge["from"]]["region"] != source_macro["from"] or room_by_id[edge["to"]]["region"] != source_macro["to"]:
                errors.append(f"{edge['id']}: room anchors do not match source macro edge endpoints")

    # Cycle rank indicates whether the graph has real structural loops beyond a tree.
    undirected_edge_count = sum(1 for edge in connections if edge.get("from") in room_ids and edge.get("to") in room_ids)
    cycle_rank = undirected_edge_count - len(room_ids) + 1 if len(reached) == len(room_ids) else 0
    if cycle_rank < 1:
        errors.append("graph has no structural loop")

    if errors:
        for error in errors:
            fail(error)
        print(f"ROOM EXPLORATION GRAPH CHECK FAILED | rooms={len(rooms)} edges={len(connections)} errors={len(errors)}")
        return 1

    print("ROOM EXPLORATION GRAPH STATIC CHECK PASSED")
    print(f"  - regions: {len(regions)} (A0-A13)")
    print(f"  - room design nodes: {len(rooms)}")
    print(f"  - connection contracts: {len(connections)}")
    print(f"  - macro links mapped to room anchors: {len(expected_macro_ids)}")
    print(f"  - hidden subregions: {len(hidden_ids)}")
    print(f"  - structural cycle rank: {cycle_rank}")
    print("  - scope: design topology only; Godot runtime is not tested")
    return 0


if __name__ == "__main__":
    sys.exit(main())
