#!/usr/bin/env python3
"""Validate the complete contract-driven world map without claiming Godot runtime success."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT / "tools" / "room_spatial_contracts_a1_a3.json"
GRAPH = ROOT / "tools" / "room_exploration_world_graph.json"
CONTROLLER = ROOT / "scripts" / "levels" / "contract_room_region.gd"
ROOM_DIR = ROOT / "scenes" / "rooms"
SPECIAL_SCENES = {
    "A1-R01": "a1_village_streets.tscn",
    "A1-R02": "a1_old_well_shaft.tscn",
    "A1-R03": "a1_north_gate_highroad.tscn",
    "A2-R01": "a2_mist_forest.tscn",
    "A2-R02": "a2_bell_tomb.tscn",
    "A2-R03": "a2_pilgrim_highroad.tscn",
    "A3-R01": "a3_collapsed_district.tscn",
    "A3-R02": "a3_old_market_roofs.tscn",
    "A3-R03": "a3_drain_alley.tscn",
}


def scene_path(room_id: str) -> Path:
    name = SPECIAL_SCENES.get(room_id)
    if name is None:
        name = f"world_{room_id.lower().replace('-', '_')}.tscn"
    return ROOM_DIR / name


def main() -> int:
    data = json.loads(CONTRACT.read_text(encoding="utf-8"))
    graph = json.loads(GRAPH.read_text(encoding="utf-8"))
    rooms = data.get("rooms", [])
    graph_rooms = graph.get("rooms", [])
    errors: list[str] = []
    ids = [str(room.get("room_id", "")) for room in rooms]
    known = set(ids)
    graph_ids = {str(room.get("id", "")) for room in graph_rooms}

    if len(ids) != 50:
        errors.append(f"expected 50 room contracts, found {len(ids)}")
    if len(known) != len(ids):
        errors.append("duplicate room IDs in spatial contracts")
    if known != graph_ids:
        errors.append(f"spatial contract/graph ID mismatch: contracts-only={sorted(known-graph_ids)}, graph-only={sorted(graph_ids-known)}")

    terrain_count = exit_count = landmark_count = 0
    for room in rooms:
        rid = str(room.get("room_id", "<missing>"))
        size = room.get("size", [])
        if len(size) != 2 or any(not isinstance(n, (int, float)) or n <= 0 for n in size):
            errors.append(f"{rid}: invalid room size")
            continue
        width, height = size
        spawn = room.get("spawn", {})
        at = spawn.get("at", [])
        if len(at) != 2 or not (0 <= at[0] <= width and 0 <= at[1] <= height):
            errors.append(f"{rid}: spawn outside room")
        if not spawn.get("support"):
            errors.append(f"{rid}: spawn lacks support contract")
        terrain = room.get("terrain", [])
        terrain_ids_for_spawn = {str(part.get("id", "")) for part in terrain}
        if str(spawn.get("support", "")) not in terrain_ids_for_spawn:
            errors.append(f"{rid}: spawn support does not match a terrain segment")
        exits = room.get("exits", [])
        landmarks = room.get("landmarks", [])
        terrain_count += len(terrain)
        exit_count += len(exits)
        landmark_count += len(landmarks)
        if not terrain:
            errors.append(f"{rid}: no terrain")
        if not exits:
            errors.append(f"{rid}: no exits")
        terrain_ids = [str(p.get("id", "")) for p in terrain]
        if len(terrain_ids) != len(set(terrain_ids)):
            errors.append(f"{rid}: duplicate terrain IDs")
        for part in terrain:
            rect = part.get("rect", [])
            if len(rect) != 4:
                errors.append(f"{rid}/{part.get('id')}: malformed terrain rectangle")
                continue
            x, y, w, h = rect
            if w <= 0 or h <= 0 or x < 0 or y < 0 or x + w > width or y + h > height:
                errors.append(f"{rid}/{part.get('id')}: terrain out of bounds {rect}")
        for kind, items in (("exit", exits), ("landmark", landmarks)):
            seen: set[str] = set()
            for item in items:
                item_id = str(item.get("id", ""))
                if item_id in seen:
                    errors.append(f"{rid}: duplicate {kind} ID {item_id}")
                seen.add(item_id)
                point = item.get("at", [])
                if len(point) != 2 or not (0 <= point[0] <= width and 0 <= point[1] <= height):
                    errors.append(f"{rid}/{item_id}: {kind} point out of bounds")
                if kind == "exit":
                    target = str(item.get("target", ""))
                    if target not in known:
                        errors.append(f"{rid}/{item_id}: target room missing: {target}")
                    if not item.get("condition"):
                        errors.append(f"{rid}/{item_id}: missing explicit condition")
        path = scene_path(rid)
        if not path.is_file():
            errors.append(f"{rid}: missing scene file {path.relative_to(ROOT)}")
        else:
            scene_text = path.read_text(encoding="utf-8")
            if f'room_id = "{rid}"' not in scene_text:
                errors.append(f"{rid}: scene room_id does not match contract")

    if not CONTROLLER.is_file():
        errors.append("missing contract room controller")
    elif "func _target_entry_position" not in CONTROLLER.read_text(encoding="utf-8"):
        errors.append("controller does not resolve destination-side entry anchors")

    if errors:
        for error in errors:
            print(f"[FAIL] {error}")
        print(f"FULL WORLD MAP STATIC CHECK FAILED | rooms={len(rooms)} errors={len(errors)}")
        return 1

    print("FULL WORLD MAP STATIC CHECK PASSED")
    print(f"  - rooms: {len(rooms)}")
    print(f"  - terrain/platform segments: {terrain_count}")
    print(f"  - exits: {exit_count}")
    print(f"  - landmarks: {landmark_count}")
    print(f"  - hidden regions: {sum(1 for rid in ids if rid.startswith('H'))}")
    print("  - scope: JSON, scene-file, ID, and coordinate checks only; Godot runtime not tested")
    return 0


if __name__ == "__main__":
    sys.exit(main())
