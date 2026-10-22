#!/usr/bin/env python3
"""Static acceptance checks for the A5 standalone room scene set.

This validates repository wiring only. It does not replace Godot parsing or runtime playtests.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT / "tools" / "a5_room_design_contract.json"
RUNTIME = ROOT / "scripts" / "levels" / "greybox_world_region.gd"


def fail(message: str) -> None:
    print(f"[FAIL] {message}")


def main() -> int:
    failures = 0
    data = json.loads(CONTRACT.read_text(encoding="utf-8"))
    runtime = RUNTIME.read_text(encoding="utf-8")
    rooms = data.get("rooms", [])
    ids = [room.get("id") for room in rooms]

    if len(rooms) != 22:
        fail(f"expected 22 room records, got {len(rooms)}")
        failures += 1
    if len(set(ids)) != len(ids):
        fail("room IDs are not unique")
        failures += 1

    for room in rooms:
        room_id = room["id"]
        raw_path = room.get("scene_path", "")
        scene_path = ROOT / raw_path.removeprefix("res://")
        if not scene_path.is_file():
            fail(f"{room_id}: missing scene {raw_path}")
            failures += 1
            continue
        scene = scene_path.read_text(encoding="utf-8")
        required = [
            'res://scripts/levels/greybox_world_region.gd',
            'region_id = "A5"',
            f'room_id = "{room_id}"',
        ]
        missing = [needle for needle in required if needle not in scene]
        if missing:
            fail(f"{room_id}: scene contract missing {missing}")
            failures += 1
        width = re.search(r"^map_width = ([0-9.]+)$", scene, re.M)
        height = re.search(r"^room_height = ([0-9.]+)$", scene, re.M)
        screens = room.get("size_screens", [])
        if not width or not height or len(screens) != 2:
            fail(f"{room_id}: invalid or missing room dimensions/size_screens")
            failures += 1
        else:
            expected_width = int(screens[0]) * 1280
            expected_height = int(screens[1]) * 720
            if float(width.group(1)) != expected_width or float(height.group(1)) != expected_height:
                fail(f"{room_id}: dimensions {width.group(1)}x{height.group(1)} do not match {expected_width}x{expected_height}")
                failures += 1

    # Validate every authored platform against its room bounds and flag gaps that likely
    # exceed the Hero's ordinary jump envelope. This is geometric triage, not physics proof.
    layout_start = runtime.find("func _configure_a5_room_platforms() -> void:")
    layout_end = runtime.find("\\n\\nfunc _configure_platforms()", layout_start)
    if layout_start < 0 or layout_end < 0:
        fail("could not isolate _configure_a5_room_platforms()")
        failures += 1
    else:
        layout = runtime[layout_start:layout_end]
        room_layouts = re.findall(r'"(A5-R\\d{2})":\\n((?:\\t\\t\\t.*\\n)*)', layout)
        layout_by_id = {room_id: body for room_id, body in room_layouts}
        for room in rooms:
            room_id = room["id"]
            body = layout_by_id.get(room_id)
            if body is None:
                fail(f"{room_id}: no dedicated platform layout")
                failures += 1
                continue
            scene_path = ROOT / room["scene_path"].removeprefix("res://")
            scene = scene_path.read_text(encoding="utf-8")
            width_match = re.search(r"^map_width = ([0-9.]+)$", scene, re.M)
            height_match = re.search(r"^room_height = ([0-9.]+)$", scene, re.M)
            if not width_match or not height_match:
                continue
            room_width, room_height = float(width_match.group(1)), float(height_match.group(1))
            floor_y = max(540.0, room_height - 180.0)
            rects = re.findall(r"_add_platform\\(Rect2\\(([^,]+),\\s*([^,]+),\\s*([^,]+),\\s*18\\)\\)", body)
            if len(rects) < 3:
                fail(f"{room_id}: expected at least 3 authored platforms, got {len(rects)}")
                failures += 1
            resolved = []
            for x_raw, y_raw, width_raw in rects:
                try:
                    x = float(x_raw.strip())
                    platform_y = floor_y - float(y_raw.split("-")[-1].strip()) if "floor -" in y_raw else float(y_raw.strip())
                    platform_width = float(width_raw.strip())
                except ValueError:
                    fail(f"{room_id}: unsupported platform expression Rect2({x_raw}, {y_raw}, {width_raw}, 18)")
                    failures += 1
                    continue
                if x < 0 or platform_width <= 0 or x + platform_width > room_width:
                    fail(f"{room_id}: platform outside horizontal bounds x={x:g} width={platform_width:g} room={room_width:g}")
                    failures += 1
                if platform_y < 0 or platform_y + 18 > room_height:
                    fail(f"{room_id}: platform outside vertical bounds y={platform_y:g} room={room_height:g}")
                    failures += 1
                resolved.append((x, platform_y, platform_width))
            # Jump height from v=-520 and gravity=1400 is about 96.6 px; double-jump,
            # wall-climb, and grapple can extend this, so report gaps as warnings only.
            for left, right in zip(sorted(resolved, key=lambda p: p[0]), sorted(resolved, key=lambda p: p[0])[1:]):
                horizontal_gap = right[0] - (left[0] + left[2])
                vertical_rise = left[1] - right[1]
                if horizontal_gap > 430 or vertical_rise > 170:
                    print(f"[WARN] {room_id}: inspect traversal gap dx={horizontal_gap:.0f}px rise={vertical_rise:.0f}px (movement abilities may be required)")

    for needle in (
        '@export var room_id: String = ""',
        '@export var room_height: float = 720.0',
        'func _ready_a5_room_test() -> void:',
        'func _configure_a5_room_platforms() -> void:',
        'camera.limit_bottom = int(room_height) if region_id == "A5" and not room_id.is_empty() else (1000 if region_id == "A2" else 720)',
        'floor_y = maxf(540.0, room_height - 180.0)',
        'if region_id == "A5" and not room_id.is_empty():',
    ):
        if needle not in runtime:
            fail(f"shared runtime missing standalone room hook: {needle}")
            failures += 1

    if failures:
        print(f"A5 ROOM STATIC ACCEPTANCE: FAIL ({failures} issue(s))")
        return 1
    print(f"A5 ROOM STATIC ACCEPTANCE: PASS ({len(rooms)} independent scene files wired)")
    print("Note: run Godot headless/editor acceptance separately to verify parsing, physics, camera, and controls.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
