#!/usr/bin/env python3
"""Static acceptance checks for A5 standalone graybox rooms.

This checks authored geometry contracts and repository wiring. It does not replace
Godot parsing, live collision testing, or manual playtesting.
"""
from __future__ import annotations

import json
import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT / "tools" / "a5_room_design_contract.json"
RUNTIME = ROOT / "scripts" / "levels" / "greybox_world_region.gd"
HERO = ROOT / "scripts" / "player" / "hero.gd"
RUNTIME_HARNESS = ROOT / "tools" / "a5_room_runtime_acceptance.gd"
WORLD = ROOT / "scripts" / "world" / "world.gd"
NUMBER_ROW = re.compile(r"\[([0-9.,\s]+)\]")


def fail(message: str) -> None:
    print(f"[FAIL] {message}")


def read_numeric_constant(source: str, name: str) -> float:
    match = re.search(rf"^const {re.escape(name)} := (-?[0-9.]+)$", source, re.M)
    if not match:
        raise ValueError(f"cannot read Hero constant {name}")
    return float(match.group(1))


def can_traverse(
    source: tuple[float, float, float],
    target: tuple[float, float, float],
    jump_speed: float,
    gravity: float,
    horizontal_speed: float,
    collider_radius: float,
) -> bool:
    """Approximate a jump using the Hero's actual movement constants."""
    sx, source_offset, sw = source
    tx, target_offset, tw = target
    rise = target_offset - source_offset
    discriminant = jump_speed * jump_speed - 2.0 * gravity * rise
    if discriminant < 0.0:
        return False
    # Descending root: land on a one-way platform at the target elevation.
    flight_time = (jump_speed + math.sqrt(discriminant)) / gravity
    horizontal_gap = max(0.0, tx - (sx + sw), sx - (tx + tw))
    # The capsule may overhang both ledges by its radius at takeoff/landing.
    horizontal_reach = horizontal_speed * flight_time + 2.0 * collider_radius
    return horizontal_gap <= horizontal_reach


def room_case_arrays(source: str, function_name: str, end_function: str, variable: str) -> dict[str, list[list[float]]]:
    start = source.find(function_name)
    end = source.find(end_function, start)
    if start < 0 or end < 0:
        raise ValueError(f"cannot isolate {function_name}")
    function = source[start:end]
    pattern = rf'"(A5-R\d{{2}})":[ \t]*\n[ \t]*{variable}[ \t]*=[ \t]*(\[\[.*?\]\]|\[\])'
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
    pattern = r'"(A5-R\d{2})":[ \t]*\n(?:[ \t]*#[^\n]*\n)*[ \t]*gaps[ \t]*=[ \t]*\[(.*?)\]'
    for room_id, encoded in re.findall(pattern, function, re.S):
        parsed[room_id] = [(float(x), float(width))
                           for x, width in re.findall(r"Vector2\(([0-9.]+),\s*([0-9.]+)\)", encoded)]
    return parsed


def main() -> int:
    failures = 0
    data = json.loads(CONTRACT.read_text(encoding="utf-8"))
    runtime = RUNTIME.read_text(encoding="utf-8")
    world_source = WORLD.read_text(encoding="utf-8")
    hero_source = HERO.read_text(encoding="utf-8")
    if not RUNTIME_HARNESS.is_file():
        fail("missing runtime acceptance script: tools/a5_room_runtime_acceptance.gd")
        failures += 1
        harness = ""
    else:
        harness = RUNTIME_HARNESS.read_text(encoding="utf-8")
    rooms = data.get("rooms", [])
    room_ids = [room.get("id") for room in rooms]
    try:
        jump_speed = abs(read_numeric_constant(hero_source, "JUMP_VELOCITY"))
        gravity = read_numeric_constant(hero_source, "GRAVITY")
        horizontal_speed = read_numeric_constant(hero_source, "SPEED")
        collision_call = re.search(r"_add_character_collision\(hero,\s*([0-9.]+),\s*([0-9.]+)\)", runtime)
        if not collision_call:
            raise ValueError("cannot read Hero collision capsule dimensions")
        collider_radius = float(collision_call.group(1))
        jump_height = jump_speed * jump_speed / (2.0 * gravity)
    except ValueError as error:
        fail(f"cannot build Hero jump envelope: {error}")
        return 1
    expected_ids = {f"A5-R{i:02d}" for i in range(1, 23)}

    if len(rooms) != 22 or set(room_ids) != expected_ids:
        fail(f"contract must contain A5-R01..A5-R22 exactly; got {len(rooms)} records")
        failures += 1
    if len(set(room_ids)) != len(room_ids):
        fail("room IDs are not unique")
        failures += 1

    room_sizes: dict[str, tuple[float, float, float]] = {}
    scene_texts: dict[str, str] = {}
    for room in rooms:
        room_id = room.get("id", "?")
        scene_path = ROOT / room.get("scene_path", "").removeprefix("res://")
        if not scene_path.is_file():
            fail(f"{room_id}: missing scene {room.get('scene_path')}")
            failures += 1
            continue
        scene = scene_path.read_text(encoding="utf-8")
        scene_texts[room_id] = scene
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

    # Every contract edge must have editor-authored transition and unlock placeholders.
    # One-way edges only author the source-side trigger; bidirectional edges author both ends.
    expected_connection_nodes: dict[str, set[str]] = {room_id: set() for room_id in room_ids}
    for edge in data.get("connections", []):
        edge_id = str(edge.get("id", ""))
        source_id = str(edge.get("from", ""))
        target_id = str(edge.get("to", ""))
        if source_id not in expected_connection_nodes or target_id not in expected_connection_nodes:
            fail(f"{edge_id}: connection references unknown room {source_id} -> {target_id}")
            failures += 1
            continue
        expected_connection_nodes[source_id].add(edge_id)
        if edge.get("travel", "both") != "one_way":
            expected_connection_nodes[target_id].add(edge_id)

    for room_id, edge_ids in expected_connection_nodes.items():
        scene = scene_texts.get(room_id, "")
        for node_kind, resource_id in (
            ("Transition", "RoomTransitionScene"),
            ("Unlock", "ShortcutUnlockScene"),
        ):
            actual_ids = set(re.findall(
                rf'^\[node name="{node_kind}_(A5-[A-Z0-9-]+)" parent="\." instance=ExtResource\("{resource_id}"\)\]$',
                scene, re.M
            ))
            if actual_ids != edge_ids:
                missing = sorted(edge_ids - actual_ids)
                extra = sorted(actual_ids - edge_ids)
                fail(f"{room_id}: authored {node_kind} nodes mismatch; missing={missing}, extra={extra}")
                failures += 1
        for resource_path, resource_id in (
            ("res://scenes/rooms/transition_point.tscn", "RoomTransitionScene"),
            ("res://scenes/rooms/shortcut_unlock_point.tscn", "ShortcutUnlockScene"),
        ):
            if f'path="{resource_path}" id="{resource_id}"' not in scene:
                fail(f"{room_id}: missing scene resource {resource_path}")
                failures += 1

    transition_builder = re.search(
        r"func _build_room_transitions\([^\n]*\):(?P<body>.*?)(?=\nfunc )",
        world_source, re.S
    )
    if not transition_builder:
        fail("world.gd: cannot isolate _build_room_transitions()")
        failures += 1
    elif re.search(r"\.instantiate\s*\(|\badd_child\s*\(|\bqueue_free\s*\(", transition_builder.group("body")):
        fail("world.gd: _build_room_transitions() must configure authored nodes, not create/free map nodes")
        failures += 1

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

    # Detect exact room-platform template reuse. Different IDs/roles must not silently
    # share the same authored silhouette; functional similarity still requires human review.
    geometry_signatures: dict[tuple[tuple[float, float, float], ...], str] = {}
    for room_id, rows in platforms.items():
        signature = tuple(sorted((round(row[0], 2), round(row[1], 2), round(row[2], 2)) for row in rows))
        previous = geometry_signatures.get(signature)
        if previous:
            fail(f"{room_id}: exact platform-layout duplicate of {previous}; differentiate room silhouette")
            failures += 1
        else:
            geometry_signatures[signature] = room_id

    totals = {"platforms": 0, "solid_blocks": 0, "floor_gaps": 0}
    for room in rooms:
        room_id = room["id"]
        if room_id not in room_sizes or room_id not in platforms or room_id not in blocks or room_id not in gaps:
            continue
        room_width, room_height, floor_y = room_sizes[room_id]
        authored = platforms[room_id]
        solid = blocks[room_id]
        room_gap_list = gaps[room_id]
        scene_text = scene_texts.get(room_id, "")
        scene_platforms = re.findall(r'^\[node name="A5RoomPlatform_\d+" type="StaticBody2D" parent="\."\]$', scene_text, re.M)
        scene_blocks = re.findall(r'^\[node name="A5RoomRubble_\d+" type="StaticBody2D" parent="\."\]$', scene_text, re.M)
        scene_ground = re.findall(r'^\[node name="A5RoomGround_\d+" type="StaticBody2D" parent="\."\]$', scene_text, re.M)
        collision_shapes = re.findall(r'^\[node name="CollisionShape2D" type="CollisionShape2D" parent="A5Room(?:Platform|Rubble|Ground)_\d+"\]$', scene_text, re.M)
        expected_ground_segments = len(room_gap_list) + 1
        expected_shapes = len(authored) + len(solid) + expected_ground_segments
        static_checks = [
            ("scene platform nodes", len(scene_platforms), len(authored)),
            ("scene rubble nodes", len(scene_blocks), len(solid)),
            ("scene ground nodes", len(scene_ground), expected_ground_segments),
            ("scene collision-shape nodes", len(collision_shapes), expected_shapes),
            ("one-way collision flags", scene_text.count("one_way_collision = true"), len(authored)),
        ]
        for label, actual, expected in static_checks:
            if actual != expected:
                fail(f"{room_id}: {label}={actual}, expected {expected}; terrain must be authored in the .tscn")
                failures += 1
        terrain_contract = room.get("terrain_geometry", {})
        for field, actual in (
            ("platform_count", len(authored)),
            ("solid_rubble_count", len(solid)),
            ("floor_gap_count", len(room_gap_list)),
        ):
            if terrain_contract.get(field) != actual:
                fail(f"{room_id}: contract {field}={terrain_contract.get(field)} but runtime defines {actual}")
                failures += 1
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

        # Build a directed graph from floor segments and platforms using the
        # actual Hero jump/gravity/speed/capsule constants. This is a ballistic
        # approximation; runtime collision and live player-input tests remain separate.
        ground_segments: list[tuple[float, float, float]] = []
        cursor = 0.0
        for gap_x, gap_width in room_gap_list:
            if gap_x > cursor:
                ground_segments.append((cursor, 0.0, gap_x - cursor))
            cursor = max(cursor, gap_x + gap_width)
        if cursor < room_width:
            ground_segments.append((cursor, 0.0, room_width - cursor))
        nodes = ground_segments + resolved
        ground_count = len(ground_segments)
        if room_id == "A5-R06":
            start_x, start_y = 380.0, 96.0
            candidates = [
                index for index, (x, offset, width) in enumerate(resolved)
                if start_x + collider_radius >= x
                and start_x - collider_radius <= x + width
                and floor_y - offset >= start_y - 2.0
            ]
            if candidates:
                start_platform_index = min(
                    candidates, key=lambda index: abs((floor_y - resolved[index][1]) - start_y)
                )
                start_nodes = {ground_count + start_platform_index}
            else:
                fail("A5-R06: elevated spawn does not overlap a valid starting platform")
                failures += 1
                start_nodes = set()
        else:
            start_x = 96.0
            start_ground_indices = [
                index for index, (x, _offset, width) in enumerate(ground_segments)
                if x <= start_x <= x + width
            ]
            if not start_ground_indices:
                fail(f"{room_id}: default spawn x=96 is inside a floor gap")
                failures += 1
                start_nodes = set()
            else:
                start_nodes = {start_ground_indices[0]}

        reachable = set(start_nodes)
        frontier = list(start_nodes)
        while frontier:
            current_index = frontier.pop()
            for target_index, target in enumerate(nodes):
                if target_index in reachable:
                    continue
                if can_traverse(
                    nodes[current_index], target,
                    jump_speed, gravity, horizontal_speed, collider_radius
                ):
                    reachable.add(target_index)
                    frontier.append(target_index)
        unreachable = [
            index + 1 for index in range(len(resolved))
            if ground_count + index not in reachable
        ]
        totals["reachable_platforms"] = totals.get("reachable_platforms", 0) + (
            len(resolved) - len(unreachable)
        )
        totals["checked_platforms"] = totals.get("checked_platforms", 0) + len(resolved)
        if unreachable:
            labels = ", ".join(str(index) for index in unreachable[:12])
            suffix = "..." if len(unreachable) > 12 else ""
            fail(
                f"{room_id}: {len(unreachable)} platform(s) fail the Hero ballistic reachability model "
                f"(platform indices {labels}{suffix})"
            )
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

    terrain_summary = data.get("terrain_design", {})
    for field, actual in (
        ("expected_platform_count", totals["platforms"]),
        ("expected_solid_block_count", totals["solid_blocks"]),
        ("expected_floor_gap_count", totals["floor_gaps"]),
    ):
        if terrain_summary.get(field) != actual:
            fail(f"terrain_design.{field}={terrain_summary.get(field)} but geometry totals {actual}")
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

    for needle in (
        "func _test_room(room: Dictionary) -> void:",
        "PLATFORM_COLLISIONS/%s",
        "RUBBLE_COLLISIONS/%s",
        "GROUND_COLLISION_COVERAGE/%s",
        "CAMERA_LIMITS/%s",
        "PHYSICS_GROUNDING/%s",
        "A5 ROOM RUNTIME ACCEPTANCE:",
    ):
        if needle not in harness:
            fail(f"runtime acceptance harness missing check hook: {needle}")
            failures += 1

    assembly_start = runtime.find("func _ready_a5_assembly_child() -> void:")
    assembly_end = runtime.find("func _ready_a5_assembled_region() -> void:", assembly_start)
    if assembly_start < 0 or assembly_end < 0:
        fail("cannot isolate _ready_a5_assembly_child()")
        failures += 1
    else:
        assembly_reader = runtime[assembly_start:assembly_end]
        if re.search(r'\b(?:Node2D|StaticBody2D|Area2D|CollisionShape2D)\.new\s*\(|\.instantiate\s*\(|\badd_child\s*\(', assembly_reader):
            fail("A5 assembly child must read authored .tscn nodes, not construct scene nodes at runtime")
            failures += 1
    if failures:
        print(f"A5 TERRAIN STATIC ACCEPTANCE: FAIL ({failures} issue(s))")
        print(f"Geometry scanned: {totals['platforms']} platforms, {totals['solid_blocks']} solid blocks, {totals['floor_gaps']} floor gaps")
        return 1
    print("A5 TERRAIN STATIC ACCEPTANCE: PASS (22 room definitions and scene wiring)")
    print(f"Geometry scanned: {totals['platforms']} platforms, {totals['solid_blocks']} solid blocks, {totals['floor_gaps']} floor gaps")
    print(
        "Hero jump-envelope model: %d/%d platforms reachable "
        "(speed=%.0f, jump=%.0f, gravity=%.0f, apex=%.1fpx; ballistic approximation only)"
        % (
            totals.get("reachable_platforms", 0), totals.get("checked_platforms", 0),
            horizontal_speed, jump_speed, gravity, jump_height
        )
    )
    print("Not covered: live jump/collision simulation, camera motion during movement, and manual playability.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
