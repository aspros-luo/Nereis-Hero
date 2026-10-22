#!/usr/bin/env python3
"""Static acceptance checks for A5 standalone graybox rooms.

This checks authored geometry contracts and repository wiring. It does not replace
Godot parsing, live collision testing, or manual playtesting.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT / "tools" / "a5_room_design_contract.json"
RUNTIME = ROOT / "scripts" / "levels" / "greybox_world_region.gd"
NUMBER_ROW = re.compile(r"\[([0-9.,\s]+)\]")


def fail(message: str) -> None:
    print(f"[FAIL] {message}")


def room_case_arrays(source: str, function_name: str, end_function: str, variable: str) -> dict[str, list[list[float]]]:
    start = source.find(function_name)
    end = source.find(end_function, start)
    if start < 0 or end < 0:
        raise ValueError(f"cannot isolate {function_name}")
    function = source[start:end]
    pattern = rf'"(A5-R\d{{2}})":\s*\n\s*{variable}\s*=\s*(\[\[.*?\]\]|\[\])'
    parsed: dict[str, list[list[float]]] = {}
    for room_id, encoded in re.findall(pattern, function, re.S):
        parsed[room_id] = [[float(value.strip()) for value in row.split(",")]
                           for row in NUMBER_ROW.findall(encoded)]
    return parsed


def room_case_gaps(source: str) -> dict[str, list[tuple[float, float]]]:
    start = source.find("func _configure_a5_room_floor() -> void:")
    end = source.find("func _add_a5_room_floor_segment", start)
    if start < 0 or end < 0:
        raise ValueError("cannot isolate _configure_a5_room_floor()")
    function = source[start:end]
    parsed: dict[str, list[tuple[float, float]]] = {}
    pattern = r'"(A5-R\d{2})":\s*\n\s*gaps\s*=\s*\[(.*?)\]'
    for room_id, encoded in re.findall(pattern, function, re.S):
        parsed[room_id] = [(float(x), float(width))
                           for x, width in re.findall(r"Vector2\(([0-9.]+),\s*([0-9.]+)\)", encoded)]
    return parsed


def main() -> int:
    failures = 0
    data = json.loads(CONTRACT.read_text(encoding="utf-8"))
    runtime = RUNTIME.read_text(encoding="utf-8")
    rooms = data.get("rooms", [])
    room_ids = [room.get("id") for room in rooms]
    expected_ids = {f"A5-R{i:02d}" for i in range(1, 23)}

    if len(rooms) != 22 or set(room_ids) != expected_ids:
        fail(f"contract must contain A5-R01..A5-R22 exactly; got {len(rooms)} records")
        failures += 1
    if len(set(room_ids)) != len(room_ids):
        fail("room IDs are not unique")
        failures += 1

    room_sizes: dict[str, tuple[float, float, float]] = {}
    for room in rooms:
        room_id = room.get("id", "?")
        scene_path = ROOT / room.get("scene_path", "").removeprefix("res://")
        if not scene_path.is_file():
            fail(f"{room_id}: missing scene {room.get('scene_path')}")
            failures += 1
            continue
        scene = scene_path.read_text(encoding="utf-8")
        required = [
            'res://scripts/levels/greybox_world_region.gd',
            'region_id = "A5"',
            f'room_id = "{room_id}"',
        ]
        for needle in required:
            if needle not in scene:
                fail(f"{room_id}: scene missing {needle}")
                failures += 1
        width = re.search(r"^map_width = ([0-9.]+)$", scene, re.M)
        height = re.search(r"^room_height = ([0-9.]+)$", scene, re.M)
        screens = room.get("size_screens", [])
        if not width or not height or len(screens) != 2:
            fail(f"{room_id}: missing dimensions or size_screens")
            failures += 1
            continue
        room_width, room_height = float(width.group(1)), float(height.group(1))
        expected_width, expected_height = int(screens[0]) * 1280, int(screens[1]) * 720
        if room_width != expected_width or room_height != expected_height:
            fail(f"{room_id}: dimensions {room_width:g}x{room_height:g}, expected {expected_width}x{expected_height}")
            failures += 1
        room_sizes[room_id] = (room_width, room_height, max(540.0, room_height - 180.0))

    try:
        platforms = room_case_arrays(
            runtime, "func _configure_a5_room_platforms() -> void:",
            "func _configure_a5_room_blocks() -> void:", "specs"
        )
        blocks = room_case_arrays(
            runtime, "func _configure_a5_room_blocks() -> void:",
            "func _add_a5_room_block(", "block_specs"
        )
        gaps = room_case_gaps(runtime)
    except ValueError as error:
        fail(str(error))
        return 1

    for label, mapping in (("platform", platforms), ("solid block", blocks), ("floor gap", gaps)):
        missing = expected_ids - set(mapping)
        extra = set(mapping) - expected_ids
        if missing:
            fail(f"{label}: rooms missing definitions {sorted(missing)}")
            failures += 1
        if extra:
            fail(f"{label}: unexpected room definitions {sorted(extra)}")
            failures += 1

    totals = {"platforms": 0, "solid_blocks": 0, "floor_gaps": 0}
    for room in rooms:
        room_id = room["id"]
        if room_id not in room_sizes or room_id not in platforms or room_id not in blocks or room_id not in gaps:
            continue
        room_width, room_height, floor_y = room_sizes[room_id]
        authored = platforms[room_id]
        solid = blocks[room_id]
        room_gap_list = gaps[room_id]
        totals["platforms"] += len(authored)
        totals["solid_blocks"] += len(solid)
        totals["floor_gaps"] += len(room_gap_list)

        if len(authored) < 5:
            fail(f"{room_id}: expected at least 5 route platforms; got {len(authored)}")
            failures += 1
        if len(solid) < 2:
            fail(f"{room_id}: expected at least 2 collision-backed rubble blocks; got {len(solid)}")
            failures += 1

        resolved: list[tuple[float, float, float]] = []
        for index, row in enumerate(authored):
            if len(row) != 3:
                fail(f"{room_id}: platform #{index + 1} needs [x, height_above_floor, width]")
                failures += 1
                continue
            x, offset, width = row
            y = floor_y - offset
            if x < 0 or width <= 0 or x + width > room_width:
                fail(f"{room_id}: platform #{index + 1} exceeds horizontal bounds x={x:g} width={width:g}")
                failures += 1
            if y < 0 or y + 18 > room_height or offset <= 0:
                fail(f"{room_id}: platform #{index + 1} exceeds vertical bounds y={y:g}")
                failures += 1
            resolved.append((x, offset, width))

        # Ordered platform data is authored as the intended traversal chain. Drops are allowed;
        # horizontal gaps and upward steps are kept within a practical ordinary/double-jump envelope.
        for index, (current, following) in enumerate(zip(resolved, resolved[1:]), start=1):
            x1, offset1, width1 = current
            x2, offset2, width2 = following
            gap = max(0.0, x2 - (x1 + width1), x1 - (x2 + width2))
            rise = max(0.0, offset2 - offset1)
            if gap > 210:
                fail(f"{room_id}: route platforms #{index}→#{index + 1} have {gap:.0f}px horizontal gap")
                failures += 1
            if rise > 100:
                fail(f"{room_id}: route platforms #{index}→#{index + 1} rise {rise:.0f}px upward")
                failures += 1

        if room_id != "A5-R06" and authored and min(row[1] for row in authored if len(row) == 3) > 100:
            fail(f"{room_id}: no low starter ledge reachable from the ground")
            failures += 1
        if room_id == "A5-R06":
            scene = (ROOT / next(r["scene_path"].removeprefix("res://") for r in rooms if r["id"] == room_id)).read_text(encoding="utf-8")
            if "start_position = Vector2(380.0, 96.0)" not in runtime:
                fail("A5-R06: descent room must start at its upper landing")
                failures += 1

        for index, row in enumerate(solid):
            if len(row) != 4:
                fail(f"{room_id}: rubble block #{index + 1} needs [x, top_offset, width, height]")
                failures += 1
                continue
            x, top_offset, width, height = row
            y = floor_y - top_offset
            if x < 0 or width <= 0 or height <= 0 or x + width > room_width:
                fail(f"{room_id}: rubble block #{index + 1} exceeds horizontal bounds")
                failures += 1
            if y < 0 or y + height > room_height:
                fail(f"{room_id}: rubble block #{index + 1} exceeds vertical bounds y={y:g}")
                failures += 1

        previous_end = 0.0
        for gap_x, gap_width in room_gap_list:
            if gap_x < previous_end or gap_width <= 0 or gap_x + gap_width >= room_width:
                fail(f"{room_id}: invalid/overlapping floor gap x={gap_x:g} width={gap_width:g}")
                failures += 1
            previous_end = gap_x + gap_width
            # A visible floor break must also be represented by a collision-free span.
            if not any(x < gap_x + gap_width and x + width > gap_x
                       for x, offset, width in resolved):
                fail(f"{room_id}: floor gap x={gap_x:g} has no nearby crossing platform")
                failures += 1

    for needle in (
        '@export var room_id: String = ""',
        '@export var room_height: float = 720.0',
        "func _ready_a5_room_test() -> void:",
        "func _configure_a5_room_platforms() -> void:",
        "func _configure_a5_room_blocks() -> void:",
        "func _configure_a5_room_floor() -> void:",
        "func _draw_a5_room_floor_gaps() -> void:",
        "func _add_a5_room_block(",
        "floor_y = maxf(540.0, room_height - 180.0)",
        'camera.limit_bottom = int(room_height) if region_id == "A5" and not room_id.is_empty() else (1000 if region_id == "A2" else 720)',
    ):
        if needle not in runtime:
            fail(f"shared runtime missing required graybox terrain hook: {needle}")
            failures += 1

    if failures:
        print(f"A5 TERRAIN STATIC ACCEPTANCE: FAIL ({failures} issue(s))")
        print(f"Geometry scanned: {totals['platforms']} platforms, {totals['solid_blocks']} solid blocks, {totals['floor_gaps']} floor gaps")
        return 1
    print("A5 TERRAIN STATIC ACCEPTANCE: PASS (22 room definitions and scene wiring)")
    print(f"Geometry scanned: {totals['platforms']} platforms, {totals['solid_blocks']} solid blocks, {totals['floor_gaps']} floor gaps")
    print("Not covered: Godot parser/runtime, real jump physics, camera motion, and manual playability.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
