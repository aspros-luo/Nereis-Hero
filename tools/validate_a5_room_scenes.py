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
        if not width or not height or float(width.group(1)) <= 0 or float(height.group(1)) <= 0:
            fail(f"{room_id}: invalid or missing room dimensions")
            failures += 1

    for needle in (
        '@export var room_id: String = ""',
        '@export var room_height: float = 720.0',
        'func _ready_a5_room_test() -> void:',
        'func _configure_a5_room_platforms() -> void:',
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
