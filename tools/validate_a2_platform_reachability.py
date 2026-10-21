#!/usr/bin/env python3
"""Static reachability approximation for A2 graybox platforms.

This checks whether the authored platform graph is connected from the west ground
using Hero's current jump constants. It is intentionally not a substitute for
Godot collision/input acceptance: acceleration, body shape, camera, and real
one-way-collision behavior are approximated here.
"""
from __future__ import annotations

import math
import re
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGION_SOURCE = ROOT / "scripts/levels/greybox_world_region.gd"
HERO_SOURCE = ROOT / "scripts/player/hero.gd"
SCENE_SOURCE = ROOT / "scenes/ash_forest.tscn"


@dataclass(frozen=True)
class Platform:
    name: str
    x: float
    y: float
    width: float
    height: float

    @property
    def right(self) -> float:
        return self.x + self.width


def required_float(source: str, pattern: str, label: str) -> float:
    match = re.search(pattern, source, re.MULTILINE)
    if not match:
        raise ValueError(f"Could not find {label} in source.")
    return float(match.group(1))


def a2_configure_block(source: str) -> str:
    # Restrict indentation matching to spaces/tabs. \s also matches newlines,
    # which can consume the block boundary and silently truncate the parsed platform set.
    match = re.search(
        r'^[ \t]*"A2":[ \t]*\r?\n(.*?)^[ \t]*"A3":[ \t]*$',
        source,
        re.MULTILINE | re.DOTALL,
    )
    if not match:
        raise ValueError("Could not isolate the A2 platform block.")
    return match.group(1)


def function_body(source: str, name: str) -> str:
    start = source.find(f"func {name}(")
    if start < 0:
        raise ValueError(f"Could not find function {name}.")
    end = source.find("\nfunc ", start + 6)
    return source[start:] if end < 0 else source[start:end]


def parse_platforms(source: str, floor_y: float) -> list[Platform]:
    platforms: list[Platform] = []
    block = a2_configure_block(source)
    for index, match in enumerate(
        re.finditer(
            r"_add_platform\(Rect2\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*\)\)",
            block,
        )
    ):
        x, y, width, height = map(float, match.groups())
        platforms.append(Platform(f"A2-platform-{index:02d}", x, y, width, height))

    floor_body = function_body(source, "_create_floor")
    a2_floor = floor_body.split('\n\t\treturn', 1)[0]
    for match in re.finditer(
        r'_add_ground_segment\("([^"]+)",\s*([\d.]+),\s*([\w. +\-]+)\)',
        a2_floor,
    ):
        name, x_text, width_expr = match.groups()
        x = float(x_text)
        width_expr = width_expr.strip()
        if width_expr == "map_width - 2660.0":
            width = required_float(
                SCENE_SOURCE.read_text(encoding="utf-8"),
                r"map_width\s*=\s*([\d.]+)",
                "A2 map_width",
            ) - 2660.0
        else:
            width = float(width_expr)
        platforms.append(Platform(name, x, floor_y, width, 40.0))

    for index, match in enumerate(
        re.finditer(
            r"_add_platform\(Rect2\(\s*([\d.]+)\s*,\s*floor_y\s*([+-])\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*\)\)",
            a2_floor,
        )
    ):
        x_text, sign, offset, width_text, height_text = match.groups()
        y = floor_y + float(offset) * (1 if sign == "+" else -1)
        platforms.append(
            Platform(
                f"A2-floor-feature-{index:02d}",
                float(x_text),
                y,
                float(width_text),
                float(height_text),
            )
        )
    return platforms


def horizontal_gap(a: Platform, b: Platform) -> float:
    if a.right < b.x:
        return b.x - a.right
    if b.right < a.x:
        return a.x - b.right
    return 0.0


def can_reach(
    source: Platform,
    target: Platform,
    speed: float,
    jump_velocity: float,
    gravity: float,
    half_width: float,
) -> bool:
    # Solve target.y - source.y = -v*t + 0.5*g*t^2 using the descending root.
    delta_y = target.y - source.y
    discriminant = jump_velocity * jump_velocity + 2.0 * gravity * delta_y
    if discriminant < 0.0:
        return False
    landing_time = (jump_velocity + math.sqrt(discriminant)) / gravity
    max_horizontal = speed * landing_time + half_width * 2.0
    return horizontal_gap(source, target) <= max_horizontal


def has_support(platforms: list[Platform], x: float, y: float) -> bool:
    return any(
        platform.x <= x <= platform.right and abs(platform.y - y) <= 1.0
        for platform in platforms
    )


def main() -> int:
    region = REGION_SOURCE.read_text(encoding="utf-8")
    hero = HERO_SOURCE.read_text(encoding="utf-8")
    scene = SCENE_SOURCE.read_text(encoding="utf-8")

    floor_y = required_float(scene, r"floor_y\s*=\s*([\d.]+)", "A2 floor_y")
    speed = required_float(hero, r"const SPEED\s*:=\s*([\d.]+)", "Hero SPEED")
    jump_velocity = abs(
        required_float(hero, r"const JUMP_VELOCITY\s*:=\s*(-?[\d.]+)", "Hero JUMP_VELOCITY")
    )
    gravity = required_float(hero, r"const GRAVITY\s*:=\s*([\d.]+)", "Hero GRAVITY")

    platforms = parse_platforms(region, floor_y)
    authored_platform_count = sum(1 for p in platforms if p.name.startswith("A2-platform-"))
    if authored_platform_count < 30:
        print(
            f"[FAIL] A2 platform parser found only {authored_platform_count} authored ledges; "
            "expected at least 30. Check the A2/A3 source-block boundary."
        )
        return 1
    west_ground = next((p for p in platforms if p.name == "GreyboxGround_West"), None)
    if west_ground is None:
        print("[FAIL] A2 west ground segment is missing.")
        return 1

    adjacency: list[list[int]] = [[] for _ in platforms]
    for source_index, source in enumerate(platforms):
        for target_index, target in enumerate(platforms):
            if source_index != target_index and can_reach(
                source, target, speed, jump_velocity, gravity, half_width=18.0
            ):
                adjacency[source_index].append(target_index)

    visited = {platforms.index(west_ground)}
    queue = list(visited)
    while queue:
        source_index = queue.pop(0)
        for target_index in adjacency[source_index]:
            if target_index not in visited:
                visited.add(target_index)
                queue.append(target_index)

    errors: list[str] = []
    unreachable = [
        platform.name for index, platform in enumerate(platforms) if index not in visited
    ]
    if unreachable:
        errors.append(
            f"{len(unreachable)} platform(s) are disconnected from the west ground: "
            + ", ".join(unreachable)
        )

    # Preserve the authored landing contracts for the two cross-region doors and H02.
    for label, x, y in [
        ("C03 exit", 3400.0, floor_y - 160.0),
        ("C03 return", 3220.0, floor_y - 140.0),
        ("C04 return", 1750.0, floor_y - 140.0),
        ("H02 pit gate", 960.0, floor_y + 125.0),
    ]:
        if not has_support(platforms, x, y):
            errors.append(f"{label} has no platform top under x={x:g}, y={y:g}.")

    print(f"A2 static platform graph: {len(platforms)} nodes.")
    print(f"Reachable from west ground: {len(visited)}/{len(platforms)}.")
    print(
        "Jump model: speed=%.1f, jump_velocity=-%.1f, gravity=%.1f; "
        "horizontal range includes a 36px body-width allowance."
        % (speed, jump_velocity, gravity)
    )
    print("C03/C04/H02 support anchors checked.")
    print("NOTE: this is a source-based approximation, not Godot runtime acceptance.")

    if errors:
        for error in errors:
            print(f"[FAIL] {error}")
        return 1
    print("Static A2 platform reachability check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
,
        source,
        re.MULTILINE | re.DOTALL,
    )
    if not match:
        raise ValueError("Could not isolate the A2 platform block.")
    return match.group(1)


def function_body(source: str, name: str) -> str:
    start = source.find(f"func {name}(")
    if start < 0:
        raise ValueError(f"Could not find function {name}.")
    end = source.find("\nfunc ", start + 6)
    return source[start:] if end < 0 else source[start:end]


def parse_platforms(source: str, floor_y: float) -> list[Platform]:
    platforms: list[Platform] = []
    block = a2_configure_block(source)
    for index, match in enumerate(
        re.finditer(
            r"_add_platform\(Rect2\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*\)\)",
            block,
        )
    ):
        x, y, width, height = map(float, match.groups())
        platforms.append(Platform(f"A2-platform-{index:02d}", x, y, width, height))

    floor_body = function_body(source, "_create_floor")
    a2_floor = floor_body.split('\n\t\treturn', 1)[0]
    for match in re.finditer(
        r'_add_ground_segment\("([^"]+)",\s*([\d.]+),\s*([\w. +\-]+)\)',
        a2_floor,
    ):
        name, x_text, width_expr = match.groups()
        x = float(x_text)
        width_expr = width_expr.strip()
        if width_expr == "map_width - 2660.0":
            width = required_float(
                SCENE_SOURCE.read_text(encoding="utf-8"),
                r"map_width\s*=\s*([\d.]+)",
                "A2 map_width",
            ) - 2660.0
        else:
            width = float(width_expr)
        platforms.append(Platform(name, x, floor_y, width, 40.0))

    for index, match in enumerate(
        re.finditer(
            r"_add_platform\(Rect2\(\s*([\d.]+)\s*,\s*floor_y\s*([+-])\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*\)\)",
            a2_floor,
        )
    ):
        x_text, sign, offset, width_text, height_text = match.groups()
        y = floor_y + float(offset) * (1 if sign == "+" else -1)
        platforms.append(
            Platform(
                f"A2-floor-feature-{index:02d}",
                float(x_text),
                y,
                float(width_text),
                float(height_text),
            )
        )
    return platforms


def horizontal_gap(a: Platform, b: Platform) -> float:
    if a.right < b.x:
        return b.x - a.right
    if b.right < a.x:
        return a.x - b.right
    return 0.0


def can_reach(
    source: Platform,
    target: Platform,
    speed: float,
    jump_velocity: float,
    gravity: float,
    half_width: float,
) -> bool:
    # Solve target.y - source.y = -v*t + 0.5*g*t^2 using the descending root.
    delta_y = target.y - source.y
    discriminant = jump_velocity * jump_velocity + 2.0 * gravity * delta_y
    if discriminant < 0.0:
        return False
    landing_time = (jump_velocity + math.sqrt(discriminant)) / gravity
    max_horizontal = speed * landing_time + half_width * 2.0
    return horizontal_gap(source, target) <= max_horizontal


def has_support(platforms: list[Platform], x: float, y: float) -> bool:
    return any(
        platform.x <= x <= platform.right and abs(platform.y - y) <= 1.0
        for platform in platforms
    )


def main() -> int:
    region = REGION_SOURCE.read_text(encoding="utf-8")
    hero = HERO_SOURCE.read_text(encoding="utf-8")
    scene = SCENE_SOURCE.read_text(encoding="utf-8")

    floor_y = required_float(scene, r"floor_y\s*=\s*([\d.]+)", "A2 floor_y")
    speed = required_float(hero, r"const SPEED\s*:=\s*([\d.]+)", "Hero SPEED")
    jump_velocity = abs(
        required_float(hero, r"const JUMP_VELOCITY\s*:=\s*(-?[\d.]+)", "Hero JUMP_VELOCITY")
    )
    gravity = required_float(hero, r"const GRAVITY\s*:=\s*([\d.]+)", "Hero GRAVITY")

    platforms = parse_platforms(region, floor_y)
    west_ground = next((p for p in platforms if p.name == "GreyboxGround_West"), None)
    if west_ground is None:
        print("[FAIL] A2 west ground segment is missing.")
        return 1

    adjacency: list[list[int]] = [[] for _ in platforms]
    for source_index, source in enumerate(platforms):
        for target_index, target in enumerate(platforms):
            if source_index != target_index and can_reach(
                source, target, speed, jump_velocity, gravity, half_width=18.0
            ):
                adjacency[source_index].append(target_index)

    visited = {platforms.index(west_ground)}
    queue = list(visited)
    while queue:
        source_index = queue.pop(0)
        for target_index in adjacency[source_index]:
            if target_index not in visited:
                visited.add(target_index)
                queue.append(target_index)

    errors: list[str] = []
    unreachable = [
        platform.name for index, platform in enumerate(platforms) if index not in visited
    ]
    if unreachable:
        errors.append(
            f"{len(unreachable)} platform(s) are disconnected from the west ground: "
            + ", ".join(unreachable)
        )

    # Preserve the authored landing contracts for the two cross-region doors and H02.
    for label, x, y in [
        ("C03 exit", 3400.0, floor_y - 160.0),
        ("C03 return", 3220.0, floor_y - 140.0),
        ("C04 return", 1750.0, floor_y - 140.0),
        ("H02 pit gate", 960.0, floor_y + 125.0),
    ]:
        if not has_support(platforms, x, y):
            errors.append(f"{label} has no platform top under x={x:g}, y={y:g}.")

    print(f"A2 static platform graph: {len(platforms)} nodes.")
    print(f"Reachable from west ground: {len(visited)}/{len(platforms)}.")
    print(
        "Jump model: speed=%.1f, jump_velocity=-%.1f, gravity=%.1f; "
        "horizontal range includes a 36px body-width allowance."
        % (speed, jump_velocity, gravity)
    )
    print("C03/C04/H02 support anchors checked.")
    print("NOTE: this is a source-based approximation, not Godot runtime acceptance.")

    if errors:
        for error in errors:
            print(f"[FAIL] {error}")
        return 1
    print("Static A2 platform reachability check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
