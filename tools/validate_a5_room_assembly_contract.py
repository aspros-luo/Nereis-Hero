#!/usr/bin/env python3
"""Validate the proposed A5 room assembly contract; this does not test Godot runtime assembly."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DESIGN_PATH = ROOT / "tools" / "a5_room_design_contract.json"
ASSEMBLY_PATH = ROOT / "tools" / "a5_room_assembly_contract.json"
TOPOLOGY_PATH = ROOT / "tools" / "world_map_topology.json"

def fail(message):
    print(f"[FAIL] {message}")
    return False

def main():
    design = json.loads(DESIGN_PATH.read_text(encoding="utf-8"))
    assembly = json.loads(ASSEMBLY_PATH.read_text(encoding="utf-8"))
    topology = json.loads(TOPOLOGY_PATH.read_text(encoding="utf-8"))
    errors = []
    design_rooms = {r["id"]: r for r in design.get("rooms", [])}
    assembly_rooms = assembly.get("rooms", [])
    room_ids = [r.get("id") for r in assembly_rooms]
    known = set(room_ids)

    if len(room_ids) != 22 or len(known) != 22:
        errors.append(f"expected 22 unique assembly rooms, got {len(room_ids)} entries / {len(known)} unique")
    if known != set(design_rooms):
        errors.append(f"room inventory mismatch: missing={sorted(set(design_rooms)-known)}, extra={sorted(known-set(design_rooms))}")

    for room in assembly_rooms:
        rid = room.get("id", "<missing-id>")
        if rid in design_rooms:
            expected = design_rooms[rid]
            if room.get("scene_path") != expected.get("scene_path"):
                errors.append(f"{rid}: scene_path differs from room design contract")
            if room.get("size_screens") != expected.get("size_screens"):
                errors.append(f"{rid}: size_screens differs from room design contract")
        pos = room.get("position_screens")
        size = room.get("size_screens")
        if not isinstance(pos, list) or len(pos) != 2 or not all(isinstance(v, int) for v in pos):
            errors.append(f"{rid}: position_screens must be two integer screen coordinates")
        if not isinstance(size, list) or len(size) != 2 or not all(isinstance(v, int) and v > 0 for v in size):
            errors.append(f"{rid}: invalid size_screens")

    # Proposed room footprints may touch, but must not overlap.
    for i, a in enumerate(assembly_rooms):
        if not isinstance(a.get("position_screens"), list) or not isinstance(a.get("size_screens"), list):
            continue
        ax, ay = a["position_screens"]; aw, ah = a["size_screens"]
        for b in assembly_rooms[i+1:]:
            if not isinstance(b.get("position_screens"), list) or not isinstance(b.get("size_screens"), list):
                continue
            bx, by = b["position_screens"]; bw, bh = b["size_screens"]
            if ax < bx+bw and bx < ax+aw and ay < by+bh and by < ay+ah:
                errors.append(f"proposed footprints overlap: {a['id']} and {b['id']}")

    edges = assembly.get("connections", [])
    edge_ids = [e.get("id") for e in edges]
    if len(edge_ids) != len(set(edge_ids)):
        errors.append("duplicate internal connection IDs")
    graph = {rid: set() for rid in known}
    for edge in edges:
        src, dst = edge.get("from"), edge.get("to")
        if src not in known or dst not in known:
            errors.append(f"{edge.get('id')}: unknown endpoint {src!r} -> {dst!r}")
            continue
        # Reachability audit uses final-state traversal; one-way drops are still traversable forward.
        graph[src].add(dst)
        if edge.get("travel") != "one_way":
            graph[dst].add(src)

    if "A5-R01" in graph:
        seen, stack = set(), ["A5-R01"]
        while stack:
            node = stack.pop()
            if node in seen:
                continue
            seen.add(node)
            stack.extend(graph[node] - seen)
        if seen != known:
            errors.append(f"rooms unreachable from A5-R01 in final graph: {sorted(known-seen)}")

    for route in [assembly.get("invariants", {}).get("main_route", [])]:
        for left, right in zip(route, route[1:]):
            if not any({e.get("from"), e.get("to")} == {left, right} for e in edges):
                errors.append(f"main route lacks direct connection: {left} <-> {right}")

    bindings = {b.get("id"): b for b in assembly.get("macro_bindings", [])}
    for cid, expected_room, expected_exit in [
        ("C08", "A5-R01", "west_high_parapet"),
        ("C04", "A5-R16", "old_pilgrim_highroad_winch_gate"),
        ("C09", "A5-R20", "east_upper_parapet"),
    ]:
        b = bindings.get(cid)
        if not b or b.get("room") != expected_room or b.get("exit") != expected_exit:
            errors.append(f"{cid} macro binding mismatch")
    topology_edges = {e.get("id"): e for e in topology.get("connections", [])}
    design_edges = {e.get("id"): e for e in design.get("cross_region_connections", [])}
    for cid in ("C04", "C08", "C09"):
        top = topology_edges.get(cid)
        local = design_edges.get(cid)
        if not top or not local:
            errors.append(f"{cid}: missing existing world topology or room-design contract")
        elif (top.get("from"), top.get("to"), top.get("kind")) != (local.get("from"), local.get("to"), local.get("kind")):
            errors.append(f"{cid}: world topology was changed relative to A5 room contract")

    resonance = next((e for e in edges if e.get("id") == "A5-RESONANCE-01"), None)
    expected_resonance = assembly.get("invariants", {}).get("resonance_connection", {})
    if not resonance or (resonance.get("from"), resonance.get("to"), resonance.get("unlock_condition")) != (
        expected_resonance.get("from"), expected_resonance.get("to"), expected_resonance.get("unlock_condition")
    ):
        errors.append("resonance shortcut endpoint/unlock contract mismatch")
    if expected_resonance.get("required_resonance") != 24 or expected_resonance.get("requires_resonance_sight") is not True:
        errors.append("resonance requirement changed: expected 24 plus resonance sight")
    if (expected_resonance.get("bridge_start_x"), expected_resonance.get("bridge_end_x"), expected_resonance.get("y")) != (880, 1220, 390):
        errors.append("resonance bridge geometry contract changed")

    if errors:
        for error in errors:
            fail(error)
        print(f"A5 ROOM ASSEMBLY CONTRACT: FAIL | errors={len(errors)}")
        return 1
    print("A5 ROOM ASSEMBLY CONTRACT: PASS")
    print(f"  rooms={len(known)} connections={len(edges)} macro_bindings=3")
    print("  world topology C04/C08/C09 preserved; resonance bridge contract preserved")
    print("  NOTE: contract validation only; no claim of Godot scene assembly or in-game playability")
    return 0

if __name__ == "__main__":
    sys.exit(main())
