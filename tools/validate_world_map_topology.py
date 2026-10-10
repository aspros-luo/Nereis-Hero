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
    primary_route = data.get("primary_route", [])
    loops = data.get("loops", [])
    region_ids_list = [item.get("id", "") for item in regions]
    region_ids = set(region_ids_list)
    all_ids = region_ids | {item.get("id", "") for item in hidden}

    if len(region_ids_list) != len(region_ids):
        fail(errors, "Duplicate primary region IDs.")
    if len(region_ids) != 14:
        fail(errors, f"Expected 14 primary regions, found {len(region_ids)}.")
    if len(hidden) != 8:
        fail(errors, f"Expected 8 hidden regions, found {len(hidden)}.")
    if len(connections) != 23:
        fail(errors, f"Expected 23 macro connections, found {len(connections)}.")

    edge_ids = [edge.get("id", "") for edge in connections]
    if len(edge_ids) != len(set(edge_ids)):
        fail(errors, "Duplicate connection IDs.")

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
    final_reached = reachable(final_graph, "A0")
    unreachable = sorted(all_ids - final_reached)
    if unreachable:
        fail(errors, f"Regions unreachable after all intended gates open: {unreachable}.")

    for loop in loops:
        path = loop.get("path", [])
        if len(path) < 4 or path[0] != path[-1]:
            fail(errors, f"{loop.get('id')}: loop path must return to its start.")
            continue
        for source, target in zip(path, path[1:]):
            connected = any(
                {edge.get("from"), edge.get("to")} == {source, target}
                for edge in connections
            )
            if not connected:
                fail(errors, f"{loop.get('id')}: no macro edge for {source} <-> {target}.")
        if not loop.get("requires"):
            fail(errors, f"{loop.get('id')}: loop must list its unlock requirements.")

    hidden_ids = [item.get("id", "") for item in hidden]
    if len(hidden_ids) != len(set(hidden_ids)):
        fail(errors, "Duplicate hidden region IDs.")
    if set(hidden_ids) != {f"H{i:02d}" for i in range(1, 9)}:
        fail(errors, f"Hidden IDs must be H01-H08, found {sorted(hidden_ids)}.")

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
            if secondary.get("opens_from") not in {parent, destination}:
                fail(errors, f"{sid}: secondary exit must identify the side that opens it.")
            if destination in primary_route:
                source_index = primary_route.index(parent) if parent in primary_route else -1
                target_index = primary_route.index(destination)
                if target_index > source_index and secondary.get("requires_target_already_reached") is not True:
                    fail(errors, f"{sid}: secondary exit could bypass main progression to {destination}.")
        else:
            fail(errors, f"{sid}: a hidden area needs a safe secondary exit or an explicit single-entry return design.")

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
    print(f" - Macro loops: {len(data['loops'])}")
    print(" - Main route reaches A12 without hidden regions or locked shortcuts.")
    print(" - All primary and hidden regions become reachable after intended gates open.")
    print("NOTE: This does not replace Godot runtime / graybox validation.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
