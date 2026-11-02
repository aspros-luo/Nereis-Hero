#!/usr/bin/env python3
"""Audit the six editor-authored A2 runtime room scenes and their connection contract.

Terrain, collision bodies, and markers must be serialized in each room .tscn.
This static audit does not replace Godot 4.6.1 physics or manual traversal tests.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT_PATH = ROOT / "tools/a2_room_connection_contract.json"
RUNTIME_SCRIPT = ROOT / "scripts/levels/a2_room_runtime.gd"
WORLD_SCRIPT = ROOT / "scripts/levels/greybox_world_region.gd"
ROOM_ROOTS = {f"A2-R{i:02d}": f"A2R{i:02d}Room" for i in range(1, 7)}
REQUIRED_MARKERS = {
    "A2-R01": ["EntryWest", "EntryCanopyReturn", "EntryTombReturn", "ExitVillage", "ExitCanopy", "ExitBellTomb", "DropToR04"],
    "A2-R02": ["EntryWest", "EntryFromR01", "EntryHighReturn", "ExitToR01", "ExitToR05"],
    "A2-R03": ["EntryWest", "EntryFromR01", "EntryCryptReturn", "EntryHighroadShortcut", "ExitToR01", "ExitToR05", "DropToR04"],
    "A2-R04": ["EntryDefault", "EntryTombDrop", "EntryTombDropR01", "H02Gate", "EntryH02Return", "EntryRavineReturn", "ExitToR03", "ExitToR06"],
    "A2-R05": ["EntryDefault", "EntryFromR02", "EntryUpperShortcut", "EntryRavineReturn", "ExitToR02", "ExitToR03", "ExitToR06"],
    "A2-R06": ["EntryDefault", "EntryHigh", "EntryLow", "EntryC03Return", "EntryRavineReturn", "ExitToR05", "ExitToR04", "ExitToA3"],
}


def audit_room(room: dict, errors: list[str]) -> tuple[int, int]:
    room_id = str(room.get("id", ""))
    scene_path = str(room.get("scene_path", "")).replace("res://", "")
    runtime_path = str(room.get("runtime_scene_path", "")).replace("res://", "")
    if not scene_path or scene_path != runtime_path:
        errors.append(f"{room_id}: scene_path and runtime_scene_path must point to the same authored runtime scene")
        return 0, 0
    path = ROOT / scene_path
    if not path.is_file():
        errors.append(f"{room_id}: missing authored runtime scene {scene_path}")
        return 0, 0
    source = path.read_text(encoding="utf-8")
    expected_root = ROOM_ROOTS.get(room_id)
    if expected_root and f'[node name="{expected_root}" type="Node2D"]' not in source:
        errors.append(f"{room_id}: expected root node {expected_root}")
    if '[node name="Terrain" type="Node2D" parent="."]' not in source:
        errors.append(f"{room_id}: Terrain must be an editor-visible child node")
    if 'path="res://scripts/levels/a2_room_runtime.gd"' not in source:
        errors.append(f"{room_id}: room scene must use the shared A2 runtime script")
    if f'room_id = "{room_id}"' not in source or 'region_id = "A2"' not in source:
        errors.append(f"{room_id}: runtime identity fields do not match the contract")

    load_match = re.search(r"^\[gd_scene load_steps=(\d+)", source, re.M)
    ext_count = len(re.findall(r"^\[ext_resource ", source, re.M))
    sub_count = len(re.findall(r"^\[sub_resource ", source, re.M))
    if not load_match or int(load_match.group(1)) != ext_count + sub_count + 1:
        errors.append(f"{room_id}: gd_scene load_steps does not match resource declarations")
    for resource_path in re.findall(r'^\[ext_resource[^\n]*path="res://([^"]+)"', source, re.M):
        if not (ROOT / resource_path).is_file():
            errors.append(f"{room_id}: missing external resource res://{resource_path}")

    shape_ids = set(re.findall(r'^\[sub_resource type="RectangleShape2D" id="([^"]+)"\]', source, re.M))
    terrain_bodies = re.findall(r'^\[node name="([^"]+)" type="StaticBody2D" parent="Terrain"\]', source, re.M)
    if not terrain_bodies:
        errors.append(f"{room_id}: no editor-authored Terrain StaticBody2D nodes found")
    collision_count = 0
    for body_name in terrain_bodies:
        child_parent = f"Terrain/{body_name}"
        if room_id == "A2-R01":
            collision = re.search(
                r'^\[node name="[^"]+" type="CollisionPolygon2D" parent="' + re.escape(child_parent) + r'"\]',
                source, re.M
            )
            if collision is None:
                errors.append(f"{room_id}/{body_name}: missing editor-visible CollisionPolygon2D")
                continue
        else:
            collider = re.search(
                r'^\[node name="CollisionShape2D" type="CollisionShape2D" parent="' + re.escape(child_parent) + r'"\]\n(.*?)(?=^\[node |\Z)',
                source, re.M | re.S
            )
            if collider is None:
                errors.append(f"{room_id}/{body_name}: missing editor-visible CollisionShape2D")
                continue
            shape_match = re.search(r'shape\s*=\s*SubResource\("([^"]+)"\)', collider.group(1))
            if not shape_match or shape_match.group(1) not in shape_ids:
                errors.append(f"{room_id}/{body_name}: collision shape must reference a local RectangleShape2D")
        collision_count += 1
        if not re.search(r'^\[node name="[^"]+" type="Polygon2D" parent="' + re.escape(child_parent) + r'"\]', source, re.M):
            errors.append(f"{room_id}/{body_name}: missing editor-visible terrain mass Polygon2D")
        if room_id != "A2-R01" and not re.search(r'^\[node name="[^"]+" type="Line2D" parent="' + re.escape(child_parent) + r'"\]', source, re.M):
            errors.append(f"{room_id}/{body_name}: missing editor-visible terrain edge Line2D")

    bounds = room.get("bounds", {})
    expected_values = {"map_width": bounds.get("width"), "room_height": bounds.get("height"), "floor_y": room.get("floor_y")}
    for key, expected in expected_values.items():
        if expected is None:
            continue
        match = re.search(r"^" + re.escape(key) + r"\s*=\s*(-?[\d.]+)", source, re.M)
        if not match or float(match.group(1)) != float(expected):
            actual = match.group(1) if match else "missing"
            errors.append(f"{room_id}: contract {key}={expected} but scene has {actual}")

    for marker in REQUIRED_MARKERS.get(room_id, []):
        if f'[node name="{marker}" type="Marker2D" parent="Terrain/RoomMarkers"]' not in source:
            errors.append(f"{room_id}: missing authored RoomMarkers anchor {marker}")
    return len(terrain_bodies), collision_count


def main() -> int:
    errors: list[str] = []
    try:
        contract = json.loads(CONTRACT_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"[FAIL] Cannot load A2 room contract: {exc}")
        return 1

    rooms = contract.get("rooms", [])
    expected_ids = {f"A2-R{i:02d}" for i in range(1, 7)}
    actual_ids = {room.get("id") for room in rooms}
    if actual_ids != expected_ids or len(rooms) != 6:
        errors.append(f"A2 room inventory must be exactly R01-R06; found {sorted(str(x) for x in actual_ids)}")
    if any(edge.get("id") == "C04" for edge in contract.get("connections", [])):
        errors.append("C04 is retired and must not remain in the active A2 room connection contract")
    if not any(item.get("id") == "C04" and item.get("status") == "retired" for item in contract.get("retired_connections", [])):
        errors.append("A2 contract is missing the C04 retirement record")

    total_bodies = total_colliders = 0
    for room in rooms:
        bodies, colliders = audit_room(room, errors)
        total_bodies += bodies
        total_colliders += colliders
        print(f'{room.get("id")}: authored terrain bodies={bodies} collision shapes={colliders}')

    active_ids = {edge.get("id") for edge in contract.get("connections", [])}
    required_active = {"A2-R06-C03", "A2-R04-H02"}
    if not required_active.issubset(active_ids):
        errors.append(f"Missing required A2 cross-region/hidden links: {sorted(required_active-active_ids)}")
    runtime = RUNTIME_SCRIPT.read_text(encoding="utf-8") if RUNTIME_SCRIPT.is_file() else ""
    world = WORLD_SCRIPT.read_text(encoding="utf-8") if WORLD_SCRIPT.is_file() else ""
    for fragment, label in (
        ('_spawn_exit_door_at_marker("ExitToA3"', "C03 outbound"),
        ('_spawn_exit_door_at_marker("ExitToR02"', "R05 to R02 internal route"),
        ('_spawn_exit_door_at_marker("ExitToR03"', "R05 to R03 internal route"),
        ('_spawn_exit_door_at_marker("ExitToR06"', "R05 to R06 internal route"),
        ('_spawn_h02_gate(h02_position.x, h02_position.y)', "H02 gate"),
    ):
        if fragment not in runtime:
            errors.append(f"A2 runtime missing {label}")
    for retired_token in ("reached_A5_and_opened_old_pilgrim_highroad", "ExitToA5", "EntryC04Return", "a2_r05_c04_return"):
        if retired_token in runtime or retired_token in world:
            errors.append(f"Retired C04 runtime token remains active: {retired_token}")
    r05_path = ROOT / "scenes/rooms/a2_fog_forest/runtime/a2_r05_room.tscn"
    r05_source = r05_path.read_text(encoding="utf-8") if r05_path.is_file() else ""
    for retired_node in ('name="EntryC04Return"', 'name="ExitToA5"', 'name="Door_ExitToA5"'):
        if retired_node in r05_source:
            errors.append(f"R05 scene still contains retired node {retired_node}")

    if errors:
        for error in errors:
            print(f"[FAIL] {error}")
        print(f"A2 authored room structure: FAIL | errors={len(errors)}")
        print("BOUNDARY: static checks only; run Godot 4.6.1 to verify import, collision, movement, and transitions.")
        return 1
    print("A2 AUTHORED ROOM STRUCTURE: PASS")
    print(f"rooms={len(rooms)} terrain_bodies={total_bodies} collision_shapes={total_colliders}")
    print("R05 internal exploration preserved; C04 retired; C03/H02 remain active.")
    print("BOUNDARY: Godot 4.6.1 runtime and manual traversal acceptance are still required.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
