#!/usr/bin/env python3
"""Static checks for the A1-A3 room spatial contracts; no Godot runtime is implied."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT_PATH = ROOT / "tools" / "room_spatial_contracts_a1_a3.json"
GRAPH_PATH = ROOT / "tools" / "room_exploration_world_graph.json"


def main() -> int:
    contracts = json.loads(CONTRACT_PATH.read_text(encoding="utf-8"))
    graph = json.loads(GRAPH_PATH.read_text(encoding="utf-8"))
    known_rooms = {room["id"] for room in graph["rooms"]}
    errors: list[str] = []
    rooms = contracts.get("rooms", [])
    room_ids = [room.get("room_id") for room in rooms]
    if len(room_ids) != len(set(room_ids)):
        errors.append("duplicate room_id in spatial contracts")

    for room in rooms:
        room_id = room.get("room_id", "<missing>")
        size = room.get("size", [])
        if len(size) != 2 or any(not isinstance(v, (int, float)) or v <= 0 for v in size):
            errors.append(f"{room_id}: invalid room size")
            continue
        width, height = size
        if room_id not in known_rooms:
            errors.append(f"{room_id}: missing from room graph")
        spawn = room.get("spawn", {})
        at = spawn.get("at", [])
        if len(at) != 2 or not (0 <= at[0] <= width and 0 <= at[1] <= height):
            errors.append(f"{room_id}: spawn is outside room bounds")
        if not spawn.get("support"):
            errors.append(f"{room_id}: spawn has no support surface contract")
        if not room.get("terrain"):
            errors.append(f"{room_id}: no terrain segments defined")
        if not room.get("exits"):
            errors.append(f"{room_id}: no exits defined")

        terrain_ids = [part.get("id") for part in room.get("terrain", [])]
        if len(terrain_ids) != len(set(terrain_ids)):
            errors.append(f"{room_id}: duplicate terrain segment IDs")
        for part in room.get("terrain", []):
            rect = part.get("rect", [])
            if len(rect) != 4:
                errors.append(f"{room_id}/{part.get('id')}: rectangle must have four values")
                continue
            x, y, w, h = rect
            if w <= 0 or h <= 0 or x < 0 or y < 0 or x + w > width or y + h > height:
                errors.append(f"{room_id}/{part.get('id')}: terrain rectangle outside room bounds: {rect}")

        for point_type in ("exits", "landmarks"):
            ids = [item.get("id") for item in room.get(point_type, [])]
            if len(ids) != len(set(ids)):
                errors.append(f"{room_id}: duplicate {point_type} IDs")
            for item in room.get(point_type, []):
                point = item.get("at", [])
                if len(point) != 2 or not (0 <= point[0] <= width and 0 <= point[1] <= height):
                    errors.append(f"{room_id}/{item.get('id')}: {point_type} point outside room bounds")
                if point_type == "exits":
                    target = item.get("target")
                    if target not in known_rooms:
                        errors.append(f"{room_id}/{item.get('id')}: unknown target room {target}")
                    if not item.get("condition"):
                        errors.append(f"{room_id}/{item.get('id')}: missing explicit condition (use 'none' when ungated)")

    if len(rooms) != 9:
        errors.append(f"expected 9 initial A1-A3 rooms, found {len(rooms)}")
    if errors:
        for error in errors:
            print(f"[FAIL] {error}")
        print(f"A1-A3 SPATIAL CONTRACT CHECK FAILED | rooms={len(rooms)} errors={len(errors)}")
        return 1

    terrain_count = sum(len(room["terrain"]) for room in rooms)
    exit_count = sum(len(room["exits"]) for room in rooms)
    landmark_count = sum(len(room["landmarks"]) for room in rooms)
    print("A1-A3 SPATIAL CONTRACT STATIC CHECK PASSED")
    print(f"  - rooms: {len(rooms)}")
    print(f"  - terrain segments: {terrain_count}")
    print(f"  - exit contracts: {exit_count}")
    print(f"  - landmarks: {landmark_count}")
    print("  - scope: coordinate/schema checks only; no Godot runtime is tested")
    return 0


if __name__ == "__main__":
    sys.exit(main())
