#!/usr/bin/env python3
"""Static audit for A2's six authored terrain scenes and six runtime wrappers.

This is deliberately a conservative engineering estimate, not a substitute for
Godot parsing or interactive acceptance. It checks scene references, editor-visible
collision geometry, authored platform counts, and a simplified ballistic reach graph.
"""
from __future__ import annotations

import json
import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PARENT_SCENE = ROOT / "scenes/ash_forest.tscn"
RUNTIME_SCRIPT = "scripts/levels/a2_room_runtime.gd"
ROOMS = [
    ("R01", "scenes/rooms/a2_fog_forest/a2_r01_forest_crossroads.tscn", "A2R01ForestCrossroads", 16, "A2-R01", "a2_r01_room.tscn", "Ground_West", "Ground_West"),
    ("R02", "scenes/rooms/a2_fog_forest/a2_r02_canopy_bridge.tscn", "A2R02CanopyBridge", 9, "A2-R02", "a2_r02_room.tscn", "Ground_CanopyFloor", "Platform_022"),
    ("R03", "scenes/rooms/a2_fog_forest/a2_r03_bell_tomb_gallery.tscn", "A2R03BellTombGallery", 14, "A2-R03", "a2_r03_room.tscn", "Ground_TombWest", "Platform_013"),
    ("R04", "scenes/rooms/a2_fog_forest/a2_r04_crypt_landing.tscn", "A2R04FloodedCrypt", 10, "A2-R04", "a2_r04_room.tscn", "CryptLanding", "CryptLanding"),
    ("R05", "scenes/rooms/a2_fog_forest/a2_r05_old_pilgrim_highroad.tscn", "A2R05OldPilgrimHighroad", 15, "A2-R05", "a2_r05_room.tscn", "Ground_Middle", "Ground_Middle"),
    ("R06", "scenes/rooms/a2_fog_forest/a2_r06_eastern_ravine.tscn", "A2R06EasternRavine", 27, "A2-R06", "a2_r06_room.tscn", "Ground_East", "Platform_042"),
]
GROUND_NODES = {
    "R01": {"Ground_West"},
    "R02": {"Ground_CanopyFloor"},
    "R03": {"Ground_TombWest", "Ground_TombEast"},
    "R04": set(),
    "R05": {"Ground_Middle"},
    "R06": {"Ground_East"},
}
SPEED = 260.0
JUMP_VELOCITY = 520.0
GRAVITY = 1400.0
APEX = JUMP_VELOCITY * JUMP_VELOCITY / (2.0 * GRAVITY)


def vector(text: str, label: str) -> tuple[float, float]:
    match = re.search(r"Vector2\(\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\)", text)
    if not match:
        raise ValueError(f"Cannot parse {label}: {text!r}")
    return float(match.group(1)), float(match.group(2))


def audit_room(room_id: str, relative_path: str, root_name: str, expected_platforms: int,
               runtime_id: str, runtime_file: str, start_node: str, errors: list[str]) -> tuple[int, int, int]:
    path = ROOT / relative_path
    if not path.is_file():
        errors.append(f"{room_id}: missing terrain scene {relative_path}")
        return 0, 0, 0
    source = path.read_text(encoding="utf-8")
    if f'[node name="{root_name}" type="Node2D"]' not in source:
        errors.append(f"{room_id}: root node mismatch; expected {root_name}")

    load_match = re.search(r"\[gd_scene load_steps=(\d+)", source)
    ext_count = len(re.findall(r"^\[ext_resource ", source, re.M))
    sub_count = len(re.findall(r"^\[sub_resource ", source, re.M))
    if not load_match or int(load_match.group(1)) != ext_count + sub_count + 1:
        errors.append(f"{room_id}: gd_scene load_steps does not match resource declarations")

    shapes: dict[str, tuple[float, float]] = {}
    for shape_id, body in re.findall(r'\[sub_resource type="RectangleShape2D" id="([^"]+)"\](.*?)(?=\n\[|\Z)', source, re.S):
        try:
            size_match = re.search(r"size\s*=\s*(Vector2\([^\n]+\))", body)
            if not size_match:
                raise ValueError("missing size")
            shapes[shape_id] = vector(size_match.group(1), f"{room_id} shape {shape_id}")
        except ValueError as exc:
            errors.append(f"{room_id}: invalid rectangle resource {shape_id}: {exc}")

    bodies = re.findall(r'\[node name="([^"]+)" type="StaticBody2D" parent="\."\](.*?)(?=\n\[node name="[^"]+" type="StaticBody2D" parent="\."\]|\Z)', source, re.S)
    platform_bodies = [(name, body) for name, body in bodies if not name.startswith("Ground_")]
    ground_names = {name for name, _ in bodies if name.startswith("Ground_")}
    if len(platform_bodies) != expected_platforms:
        errors.append(f"{room_id}: platform count={len(platform_bodies)}, expected={expected_platforms}")
    if ground_names != GROUND_NODES[room_id]:
        errors.append(f"{room_id}: ground nodes={sorted(ground_names)}, expected={sorted(GROUND_NODES[room_id])}")

    parsed: list[dict[str, float | str]] = []
    for body_name, body in bodies:
        position_match = re.search(r"^position\s*=\s*(Vector2\([^\n]+\))", body, re.M)
        if not position_match:
            errors.append(f"{room_id}/{body_name}: missing body position")
            continue
        bx, by = vector(position_match.group(1), f"{room_id}/{body_name} position")
        collision_match = re.search(r'\[node name="CollisionShape2D" type="CollisionShape2D" parent="' + re.escape(body_name) + r'"\](.*?)(?=\n\[node |\Z)', body, re.S)
        if not collision_match:
            errors.append(f"{room_id}/{body_name}: missing CollisionShape2D")
            continue
        collision = collision_match.group(1)
        shape_match = re.search(r'shape\s*=\s*SubResource\("([^"]+)"\)', collision)
        if not shape_match or shape_match.group(1) not in shapes:
            errors.append(f"{room_id}/{body_name}: missing or unsupported rectangle shape")
            continue
        try:
            pos_match = re.search(r"^position\s*=\s*(Vector2\([^\n]+\))", collision, re.M)
            if not pos_match:
                raise ValueError("missing CollisionShape2D position")
            cx, cy = vector(pos_match.group(1), f"{room_id}/{body_name} collision position")
        except ValueError as exc:
            errors.append(f"{room_id}/{body_name}: invalid collision position: {exc}")
            continue
        width, height = shapes[shape_match.group(1)]
        if width <= 0 or height <= 0:
            errors.append(f"{room_id}/{body_name}: non-positive collision size")
            continue
        if "Polygon2D" not in body or "Line2D" not in body:
            errors.append(f"{room_id}/{body_name}: expected editor-visible Polygon2D and Line2D terrain styling")
        parsed.append({
            "id": body_name,
            "left": bx + cx - width / 2,
            "right": bx + cx + width / 2,
            "top": by + cy - height / 2,
        })

    start = next((node for node in parsed if node["id"] == start_node), None)
    if start is None:
        errors.append(f"{room_id}: missing reachability start node {start_node}")
        reachable = set()
    else:
        reachable = {str(start["id"])}
        queue = [start]
        while queue:
            current = queue.pop(0)
            for target in parsed:
                target_id = str(target["id"])
                if target_id in reachable:
                    continue
                delta = float(target["top"]) - float(current["top"])
                if delta < 0:
                    rise = -delta
                    if rise > APEX:
                        continue
                    flight_time = (JUMP_VELOCITY + math.sqrt(max(0.0, JUMP_VELOCITY ** 2 - 2.0 * GRAVITY * rise))) / GRAVITY
                else:
                    flight_time = (JUMP_VELOCITY + math.sqrt(JUMP_VELOCITY ** 2 + 2.0 * GRAVITY * delta)) / GRAVITY
                max_horizontal = SPEED * flight_time
                gap = max(0.0, float(target["left"]) - float(current["right"]), float(current["left"]) - float(target["right"]))
                if gap <= max_horizontal:
                    reachable.add(target_id)
                    queue.append(target)
    if len(reachable) != len(parsed):
        unreachable = sorted(str(node["id"]) for node in parsed if str(node["id"]) not in reachable)
        errors.append(f"{room_id}: simplified jump graph reaches {len(reachable)}/{len(parsed)} collision bodies; unreachable={unreachable}")
    return len(platform_bodies), len(bodies), len(reachable)


def main() -> int:
    errors: list[str] = []
    parent = PARENT_SCENE.read_text(encoding="utf-8") if PARENT_SCENE.is_file() else ""
    if "res://scenes/rooms/a2_fog_forest/runtime/a2_r01_room.tscn" not in parent:
        errors.append("scenes/ash_forest.tscn must remain a compatibility alias to the R01 runtime")
    runtime_script = ROOT / RUNTIME_SCRIPT
    if not runtime_script.is_file():
        errors.append(f"Missing runtime script {RUNTIME_SCRIPT}")

    total_platforms = total_bodies = total_reachable = 0
    for room_id, path, root_name, expected, runtime_id, runtime_file, ground_or_start, start_node in ROOMS:
        count, bodies, reachable = audit_room(room_id, path, root_name, expected, runtime_id, runtime_file, start_node, errors)
        total_platforms += count
        total_bodies += bodies
        total_reachable += reachable
        runtime_path = ROOT / "scenes/rooms/a2_fog_forest/runtime" / runtime_file
        if not runtime_path.is_file():
            errors.append(f"{room_id}: missing runtime wrapper {runtime_file}")
        else:
            wrapper = runtime_path.read_text(encoding="utf-8")
            if f'room_id = "{runtime_id}"' not in wrapper:
                errors.append(f"{room_id}: runtime wrapper room_id mismatch")
            if f'path="res://{path}"' not in wrapper:
                errors.append(f"{room_id}: runtime wrapper does not instance its terrain scene")
            if f'path="res://{RUNTIME_SCRIPT}"' not in wrapper:
                errors.append(f"{room_id}: runtime wrapper does not use {RUNTIME_SCRIPT}")
        print(f"{room_id}: platforms={count}/{expected} collision_bodies={bodies} simplified_reachable={reachable}/{bodies}")

    contract_path = ROOT / "tools/a2_room_connection_contract.json"
    if not contract_path.is_file():
        errors.append("Missing tools/a2_room_connection_contract.json")
    else:
        try:
            contract = json.loads(contract_path.read_text(encoding="utf-8"))
            for room in contract.get("rooms", []):
                terrain = ROOT / str(room.get("scene_path", "")).replace("res://", "")
                runtime = ROOT / str(room.get("runtime_scene_path", "")).replace("res://", "")
                if not terrain.is_file() or not runtime.is_file():
                    errors.append(f"{room.get('id')}: contract references missing terrain/runtime scene")
            # Room bounds and editor-visible route anchors must match the runtime wrappers.
            marker_contracts = {
                "R01": ["EntryWest", "EntryCanopyReturn", "EntryTombReturn", "ExitVillage", "ExitCanopy", "ExitBellTomb", "DropToR04"],
                "R02": ["EntryWest", "EntryFromR01", "EntryHighReturn", "ExitToR01", "ExitToR05"],
                "R03": ["EntryWest", "EntryFromR01", "EntryCryptReturn", "EntryHighroadShortcut", "ExitToR01", "ExitToR05", "DropToR04"],
                "R04": ["EntryDefault", "EntryTombDrop", "EntryTombDropR01", "H02Gate", "EntryH02Return", "EntryRavineReturn", "ExitToR03", "ExitToR06"],
                "R05": ["EntryDefault", "EntryFromR02", "EntryUpperShortcut", "EntryRavineReturn", "EntryC04Return", "ExitToR02", "ExitToR03", "ExitToR06", "ExitToA5"],
                "R06": ["EntryDefault", "EntryHigh", "EntryLow", "EntryC03Return", "EntryRavineReturn", "ExitToR05", "ExitToR04", "ExitToA3"],
            }
            for room in contract.get("rooms", []):
                room_id = str(room.get("id", "")).replace("A2-", "")
                terrain_path = ROOT / str(room.get("scene_path", "")).replace("res://", "")
                runtime_path = ROOT / str(room.get("runtime_scene_path", "")).replace("res://", "")
                if terrain_path.is_file() and runtime_path.is_file():
                    terrain_source = terrain_path.read_text(encoding="utf-8")
                    wrapper_source = runtime_path.read_text(encoding="utf-8")
                    for marker_name in marker_contracts.get(room_id, []):
                        marker_decl = f'[node name="{marker_name}" type="Marker2D" parent="RoomMarkers"]'
                        if marker_decl not in terrain_source:
                            errors.append(f"{room.get('id')}: missing authored RoomMarkers anchor {marker_name}")
                    bounds = room.get("bounds", {})
                    for key, expected in (("map_width", bounds.get("width")), ("room_height", bounds.get("height")), ("floor_y", room.get("floor_y"))):
                        if expected is None or not re.search(rf"^{key}\\s*=\\s*{re.escape(str(float(expected)))}(?:\\.0)?\\s*$", wrapper_source, re.M):
                            # Godot scene values may be serialized as either integer-like or decimal floats.
                            if expected is None or not re.search(rf"^{key}\\s*=\\s*{re.escape(str(expected))}(?:\\.0)?\\s*$", wrapper_source, re.M):
                                errors.append(f"{room.get('id')}: runtime {key} does not match connection-contract bounds ({expected})")

            for connection in contract.get("connections", []):
                if connection.get("status") != "implemented_pending_godot_playtest":
                    errors.append(f"{connection.get('id')}: unexpected status={connection.get('status')}")
        except (json.JSONDecodeError, OSError) as exc:
            errors.append(f"Invalid A2 room connection contract: {exc}")

    if total_platforms != 91:
        errors.append(f"total authored room platforms={total_platforms}; expected 91")
    if total_bodies != 97:
        errors.append(f"total authored collision bodies={total_bodies}; expected 97")
    # Cross-region returns must re-enter the room that owns each endpoint, not the R01 alias.
    if '"east":' not in (ROOT / RUNTIME_SCRIPT).read_text(encoding="utf-8"):
        pass
    runtime_source = runtime_script.read_text(encoding="utf-8") if runtime_script.is_file() else ""
    require(runtime_source, '"east":\\n\\t\\t\\t\\tdestination_scene = "res://scenes/rooms/a2_fog_forest/runtime/a2_r06_room.tscn"', RUNTIME_SCRIPT, errors)
    require(runtime_source, '"old_pilgrim_highroad":\\n\\t\\t\\t\\tdestination_scene = "res://scenes/rooms/a2_fog_forest/runtime/a2_r05_room.tscn"', RUNTIME_SCRIPT, errors)

    if errors:
        for error in errors:
            print(f"[FAIL] {error}")
        return 1
    print(f"A2 authored room structure: PASS rooms=6/6 platforms={total_platforms}/91 collision_bodies={total_bodies}/97 simplified_reachable={total_reachable}/{total_bodies}")
    print("BOUNDARY: static estimate only; not Godot parser/runtime, exact Canva fidelity, or interactive acceptance.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
