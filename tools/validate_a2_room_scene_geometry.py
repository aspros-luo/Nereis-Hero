#!/usr/bin/env python3
"""Static structural audit for the six editor-authored A2 room scenes.

This intentionally checks scene structure and authored geometry only. It does not
claim jump reachability or Godot runtime acceptance. The former validator parsed
the old procedural A2 platform branch and no longer represented the six .tscn files.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PARENT_SCENE = ROOT / "scenes/ash_forest.tscn"
ROOMS = [
    ("R01", "scenes/rooms/a2_fog_forest/a2_r01_forest_crossroads.tscn", "A2R01ForestCrossroads", 12),
    ("R02", "scenes/rooms/a2_fog_forest/a2_r02_canopy_bridge.tscn", "A2R02CanopyBridge", 7),
    ("R03", "scenes/rooms/a2_fog_forest/a2_r03_bell_tomb_gallery.tscn", "A2R03BellTombGallery", 9),
    ("R04", "scenes/rooms/a2_fog_forest/a2_r04_crypt_landing.tscn", "A2R04FloodedCrypt", 9),
    ("R05", "scenes/rooms/a2_fog_forest/a2_r05_old_pilgrim_highroad.tscn", "A2R05OldPilgrimHighroad", 13),
    ("R06", "scenes/rooms/a2_fog_forest/a2_r06_eastern_ravine.tscn", "A2R06EasternRavine", 24),
]

def vector(text: str, label: str) -> tuple[float, float]:
    match = re.search(r"Vector2\(\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\)", text)
    if not match:
        raise ValueError(f"Cannot parse {label}: {text!r}")
    return float(match.group(1)), float(match.group(2))

def audit_room(room_id: str, relative_path: str, root_name: str, expected: int, errors: list[str]) -> tuple[int, tuple[float, float, float, float]]:
    path = ROOT / relative_path
    if not path.is_file():
        errors.append(f"{room_id}: missing scene {relative_path}")
        return 0, (0.0, 0.0, 0.0, 0.0)
    source = path.read_text(encoding="utf-8")
    if f'[node name="{root_name}" type="Node2D"]' not in source:
        errors.append(f"{room_id}: root node mismatch; expected {root_name}")
    shapes: dict[str, tuple[float, float]] = {}
    for block in re.findall(r'\[sub_resource type="RectangleShape2D" id="([^"]+)"\](.*?)(?=\n\[|\Z)', source, re.S):
        shape_id, body = block
        try:
            shapes[shape_id] = vector(re.search(r"size\s*=\s*(Vector2\([^\n]+\))", body).group(1), f"{room_id} shape {shape_id}")
        except (AttributeError, ValueError) as exc:
            errors.append(f"{room_id}: invalid rectangle resource {shape_id}: {exc}")
    bodies = re.findall(r'\[node name="([^"]+)" type="StaticBody2D" parent="\."\](.*?)(?=\n\[node |\Z)', source, re.S)
    if len(bodies) != expected:
        errors.append(f"{room_id}: StaticBody2D count={len(bodies)}, expected={expected}")
    min_x = min_y = float("inf")
    max_x = max_y = float("-inf")
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
            cx, cy = vector(re.search(r"^position\s*=\s*(Vector2\([^\n]+\))", collision, re.M).group(1), f"{room_id}/{body_name} collision position")
        except (AttributeError, ValueError) as exc:
            errors.append(f"{room_id}/{body_name}: invalid collision position: {exc}")
            continue
        width, height = shapes[shape_match.group(1)]
        left, top = bx + cx - width / 2, by + cy - height / 2
        right, bottom = left + width, top + height
        min_x, min_y = min(min_x, left), min(min_y, top)
        max_x, max_y = max(max_x, right), max(max_y, bottom)
        if "Polygon2D" not in body or "Line2D" not in body:
            errors.append(f"{room_id}/{body_name}: expected editor-visible Polygon2D and Line2D terrain styling")
    if min_x == float("inf"):
        bounds = (0.0, 0.0, 0.0, 0.0)
    else:
        bounds = (min_x, min_y, max_x, max_y)
    return len(bodies), bounds

def main() -> int:
    errors: list[str] = []
    parent = PARENT_SCENE.read_text(encoding="utf-8") if PARENT_SCENE.is_file() else ""
    if not parent:
        errors.append("Missing scenes/ash_forest.tscn parent scene")
    total = 0
    for room_id, path, root_name, expected in ROOMS:
        count, bounds = audit_room(room_id, path, root_name, expected, errors)
        total += count
        if parent and path not in parent:
            errors.append(f"{room_id}: parent scene does not reference {path}")
        print(f"{room_id}: platforms={count}/{expected} local_collision_bounds={bounds}")
    if total != 74:
        errors.append(f"total authored room platforms={total}; expected sum of room contracts is 74")
    if errors:
        for error in errors:
            print(f"[FAIL] {error}")
        return 1
    print("A2 authored room structure: PASS rooms=6/6 platforms=74/74")
    print("BOUNDARY: structural/static scene audit only; not Canva fidelity, reachability, or Godot runtime acceptance.")
    return 0

if __name__ == "__main__":
    sys.exit(main())