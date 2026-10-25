#!/usr/bin/env python3
"""Static structure audit for A2 authored room scenes.

This audit checks serialized scene structure, collision resources, room markers,
and source wiring. It is not a Godot import/runtime test or a movement-reachability
proof. Contract-vs-wrapper size differences are surfaced as warnings so legacy
mismatches are not confused with R01's scene reconstruction.
"""
from __future__ import annotations

import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNTIME_SCRIPT = "scripts/levels/a2_room_runtime.gd"
ROOMS = [
    ("R01", "scenes/rooms/a2_fog_forest/a2_r01_forest_crossroads.tscn",
     "A2R01ForestCrossroads", 18, 21, "A2-R01", "a2_r01_room.tscn"),
    ("R02", "scenes/rooms/a2_fog_forest/a2_r02_canopy_bridge.tscn",
     "A2R02AuthoredRoom", 4, 4, "A2-R02", "a2_r02_room.tscn"),
    ("R03", "scenes/rooms/a2_fog_forest/a2_r03_bell_tomb_gallery.tscn",
     "A2R03AuthoredRoom", 4, 4, "A2-R03", "a2_r03_room.tscn"),
    ("R04", "scenes/rooms/a2_fog_forest/a2_r04_crypt_landing.tscn",
     "A2R04AuthoredRoom", 5, 5, "A2-R04", "a2_r04_room.tscn"),
    ("R05", "scenes/rooms/a2_fog_forest/a2_r05_old_pilgrim_highroad.tscn",
     "A2R05AuthoredRoom", 4, 4, "A2-R05", "a2_r05_room.tscn"),
    ("R06", "scenes/rooms/a2_fog_forest/a2_r06_eastern_ravine.tscn",
     "A2R06AuthoredRoom", 6, 6, "A2-R06", "a2_r06_room.tscn"),
]
MARKERS = {
    "R01": ["EntryWest", "EntryCanopyReturn", "EntryTombReturn", "ExitVillage", "ExitCanopy", "ExitBellTomb", "DropToR04"],
    "R02": ["EntryWest", "EntryFromR01", "EntryHighReturn", "ExitToR01", "ExitToR05"],
    "R03": ["EntryWest", "EntryFromR01", "EntryCryptReturn", "EntryHighroadShortcut", "ExitToR01", "ExitToR05", "DropToR04"],
    "R04": ["EntryDefault", "EntryTombDrop", "EntryTombDropR01", "H02Gate", "EntryH02Return", "EntryRavineReturn", "ExitToR03", "ExitToR06"],
    "R05": ["EntryDefault", "EntryFromR02", "EntryUpperShortcut", "EntryRavineReturn", "EntryC04Return", "ExitToR02", "ExitToR03", "ExitToR06", "ExitToA5"],
    "R06": ["EntryDefault", "EntryHigh", "EntryLow", "EntryC03Return", "EntryRavineReturn", "ExitToR05", "ExitToR04", "ExitToA3"],
}


def report(errors: list[str], message: str) -> None:
    errors.append(message)


def vector(text: str, label: str) -> tuple[float, float]:
    match = re.search(r"Vector2\(\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\)", text)
    if not match:
        raise ValueError(f"Cannot parse {label}: {text!r}")
    return float(match.group(1)), float(match.group(2))


def parse_rectangle_shapes(source: str, room_id: str, errors: list[str]) -> dict[str, tuple[float, float]]:
    result: dict[str, tuple[float, float]] = {}
    for shape_id, block in re.findall(
        r'^\[sub_resource type="RectangleShape2D" id="([^"]+)"\](.*?)(?=^\[|\Z)',
        source, re.M | re.S
    ):
        size_match = re.search(r"^size\s*=\s*(Vector2\([^\n]+\))", block, re.M)
        if not size_match:
            report(errors, f"{room_id}: RectangleShape2D {shape_id} has no size")
            continue
        try:
            width, height = vector(size_match.group(1), f"{room_id}/{shape_id}")
            if width <= 0 or height <= 0:
                report(errors, f"{room_id}: RectangleShape2D {shape_id} has non-positive size")
            result[shape_id] = (width, height)
        except ValueError as exc:
            report(errors, f"{room_id}: {exc}")
    return result


def static_body_blocks(source: str) -> list[tuple[str, str]]:
    return re.findall(
        r'^\[node name="([^"]+)" type="StaticBody2D" parent="\."\]\n'
        r'(.*?)(?=^\[node name="[^"]+" type="StaticBody2D" parent="\."\]|\Z)',
        source, re.M | re.S
    )


def audit_scene(
    room_id: str,
    relative_path: str,
    expected_root: str,
    expected_platform_count: int,
    expected_body_count: int,
    errors: list[str],
) -> tuple[int, int]:
    path = ROOT / relative_path
    if not path.is_file():
        report(errors, f"{room_id}: missing terrain scene {relative_path}")
        return 0, 0
    source = path.read_text(encoding="utf-8")
    if f'[node name="{expected_root}" type="Node2D"]' not in source:
        report(errors, f"{room_id}: root node mismatch; expected {expected_root}")

    load_match = re.search(r"^\[gd_scene load_steps=(\d+)", source, re.M)
    ext_count = len(re.findall(r"^\[ext_resource ", source, re.M))
    sub_count = len(re.findall(r"^\[sub_resource ", source, re.M))
    if not load_match or int(load_match.group(1)) != ext_count + sub_count + 1:
        report(errors, f"{room_id}: gd_scene load_steps does not match resource declarations")

    for resource_path in re.findall(r'^\[ext_resource type="[^"]+" path="res://([^"]+)"', source, re.M):
        if not (ROOT / resource_path).is_file():
            report(errors, f"{room_id}: missing external resource res://{resource_path}")

    shapes = parse_rectangle_shapes(source, room_id, errors)
    bodies = static_body_blocks(source)
    body_names = [name for name, _ in bodies]
    if len(body_names) != expected_body_count:
        report(errors, f"{room_id}: collision body count={len(body_names)}; expected {expected_body_count}")

    if room_id == "R01":
        platforms = [name for name in body_names if re.fullmatch(r"Platform_\d{3}", name)]
        if len(platforms) != expected_platform_count:
            report(errors, f"R01: authored ledge count={len(platforms)}; expected {expected_platform_count}")
        if set(platforms) != {f"Platform_{i:03d}" for i in range(1, 19)}:
            report(errors, "R01: expected Platform_001 through Platform_018")
        if set(body_names) != {"Ground_West", "WestBoundary", "EastBoundary", *platforms}:
            report(errors, f"R01: unexpected/missing collision body IDs: {sorted(set(body_names))}")
    else:
        if len(body_names) != expected_platform_count:
            report(errors, f"{room_id}: authored ledge count={len(body_names)}; expected {expected_platform_count}")

    for body_name, body in bodies:
        collision_match = re.search(
            r'^\[node name="CollisionShape2D" type="CollisionShape2D" parent="'
            + re.escape(body_name) + r'"\]\n(.*?)(?=^\[node |\Z)',
            body, re.M | re.S
        )
        if not collision_match:
            report(errors, f"{room_id}/{body_name}: missing editor-visible CollisionShape2D")
            continue
        shape_match = re.search(r'shape\s*=\s*SubResource\("([^"]+)"\)', collision_match.group(1))
        if not shape_match or shape_match.group(1) not in shapes:
            report(errors, f"{room_id}/{body_name}: missing/unsupported RectangleShape2D")
        if room_id != "R01":
            if f'[node name="TerrainMass" type="Polygon2D" parent="{body_name}"]' not in body:
                report(errors, f"{room_id}/{body_name}: missing visible TerrainMass")
            if f'[node name="TerrainTopEdge" type="Line2D" parent="{body_name}"]' not in body:
                report(errors, f"{room_id}/{body_name}: missing visible TerrainTopEdge")

    for marker in MARKERS[room_id]:
        if f'[node name="{marker}" type="Marker2D" parent="RoomMarkers"]' not in source:
            report(errors, f"{room_id}: missing RoomMarkers anchor {marker}")

    return expected_platform_count, expected_body_count


def audit_r01_illustration(source: str, errors: list[str]) -> None:
    art_path = ROOT / "assets/art/levels/a2_r01_forest_ruins_illustration.svg"
    if not art_path.is_file():
        report(errors, "R01: missing assets/art/levels/a2_r01_forest_ruins_illustration.svg")
        return
    try:
        root = ET.parse(art_path).getroot()
        width = int(float(root.attrib.get("width", "0").replace("px", "")))
        height = int(float(root.attrib.get("height", "0").replace("px", "")))
        view_box = [float(x) for x in root.attrib.get("viewBox", "").replace(",", " ").split()]
        if (width, height) != (1792, 1200) or view_box != [0.0, 0.0, 1792.0, 1200.0]:
            report(errors, f"R01: illustration dimensions/viewBox are invalid: {(width, height)} {view_box}")
    except (ET.ParseError, ValueError) as exc:
        report(errors, f"R01: illustration SVG failed XML/dimension parsing: {exc}")
        return

    art = art_path.read_text(encoding="utf-8")
    for fragment, label in (
        ('id="terrain-masses"', "terrain masses"),
        ("Broken bridge: purely decorative", "decorative, non-colliding broken bridge"),
        ("Waterfall and turquoise pool", "waterfall/pool"),
        ("Root lookout 1", "footing 1 / root lookout"),
        ("Lower fork / footing 2", "footing 2 / lower fork"),
        ("Central ruins platform 3", "footing 3 / central ruins"),
        ("Waterfall-side lower bank 4", "footing 4 / waterfall pool"),
        ("Shrine summit 5", "footing 5 / shrine exit"),
        ("L556 752L360 752", "lower passage with 62px vertical clearance"),
    ):
        if fragment not in art:
            report(errors, f"R01: illustration missing {label}")

    sprite_block = re.search(
        r'^\\[node name="LevelIllustration" type="Sprite2D" parent="\\."\\]\\n(.*?)(?=^\\[node |\\Z)',
        source, re.M | re.S
    )
    if sprite_block is None:
        report(errors, "R01: missing LevelIllustration Sprite2D")
    else:
        sprite_config = sprite_block.group(1)
        if 'texture = ExtResource("1_r01_art")' not in sprite_config or 'centered = false' not in sprite_config:
            report(errors, "R01: illustration sprite texture/origin is not configured")
        if not re.search(r"^z_index\\s*=\\s*0$", sprite_config, re.M):
            report(errors, "R01: illustration must render above the inherited legacy backdrop at z_index 0")
    if 'size = Vector2(200, 16)' not in source or 'position = Vector2(100, 8)' not in source:
        report(errors, "R01: west root shelf collider must remain thin to keep the lower path open")
    for marker, position in (
        ("Footing_01_RootLookout", "Vector2(220, 512)"),
        ("Footing_02_LowerFork", "Vector2(440, 768)"),
        ("Footing_03_CentralRuins", "Vector2(800, 512)"),
        ("Footing_04_WaterfallPool", "Vector2(990, 800)"),
        ("Footing_05_ShrineExit", "Vector2(1570, 480)"),
    ):
        marker_block = re.search(
            r'^\[node name="' + re.escape(marker) + r'" type="Marker2D" parent="FootingDesignMarkers"\]\n'
            r'position\s*=\s*' + re.escape(position) + r'$',
            source, re.M
        )
        if not marker_block:
            report(errors, f"R01: footing marker {marker} does not match {position}")
    if not re.search(
        r'^\[node name="DropToR04" type="Marker2D" parent="RoomMarkers"\]\n'
        r'position\s*=\s*Vector2\(672, 780\)$',
        source, re.M
    ):
        report(errors, "R01: DropToR04 marker must remain at (672,780)")


def require(source: str, expected: str, label: str, errors: list[str]) -> None:
    if expected not in source:
        report(errors, f"{label}: missing expected source fragment {expected!r}")


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []
    parent_path = ROOT / "scenes/ash_forest.tscn"
    parent = parent_path.read_text(encoding="utf-8") if parent_path.is_file() else ""
    require(parent, "res://scenes/rooms/a2_fog_forest/runtime/a2_r01_room.tscn",
            "scenes/ash_forest.tscn compatibility alias", errors)

    runtime_path = ROOT / RUNTIME_SCRIPT
    runtime_source = runtime_path.read_text(encoding="utf-8") if runtime_path.is_file() else ""
    if not runtime_path.is_file():
        report(errors, f"Missing runtime script {RUNTIME_SCRIPT}")

    contract_path = ROOT / "tools/a2_room_connection_contract.json"
    if not contract_path.is_file():
        report(errors, "Missing tools/a2_room_connection_contract.json")
        contract = {}
    else:
        try:
            contract = json.loads(contract_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            report(errors, f"Invalid A2 room connection contract: {exc}")
            contract = {}

    total_platforms = total_bodies = 0
    for room_id, scene_path, root_name, platform_count, body_count, runtime_id, runtime_file in ROOMS:
        count, bodies = audit_scene(room_id, scene_path, root_name, platform_count, body_count, errors)
        total_platforms += count
        total_bodies += bodies
        runtime_scene_path = ROOT / "scenes/rooms/a2_fog_forest/runtime" / runtime_file
        if not runtime_scene_path.is_file():
            report(errors, f"{room_id}: missing runtime wrapper {runtime_file}")
            continue
        wrapper = runtime_scene_path.read_text(encoding="utf-8")
        if f'room_id = "{runtime_id}"' not in wrapper:
            report(errors, f"{room_id}: runtime wrapper room_id mismatch")
        if f'path="res://{scene_path}"' not in wrapper:
            report(errors, f"{room_id}: runtime wrapper does not instance {scene_path}")
        if f'path="res://{RUNTIME_SCRIPT}"' not in wrapper:
            report(errors, f"{room_id}: runtime wrapper does not use {RUNTIME_SCRIPT}")
        # Some older room bounds in the connection JSON do not match current wrappers.
        contract_room = next((r for r in contract.get("rooms", []) if r.get("id") == runtime_id), None)
        if contract_room:
            bounds = contract_room.get("bounds", {})
            for key, expected in (
                ("map_width", bounds.get("width")),
                ("room_height", bounds.get("height")),
                ("floor_y", contract_room.get("floor_y")),
            ):
                match = re.search(r"^" + re.escape(key) + r"\s*=\s*(-?[\d.]+)", wrapper, re.M)
                actual = float(match.group(1)) if match else None
                if expected is not None and actual is not None and actual != float(expected):
                    warnings.append(f"{runtime_id}: contract {key}={expected}, wrapper {key}={actual} (pre-existing mismatch; not changed in R01 reconstruction)")
        print(f"{room_id}: editor-authored platforms={count} collision bodies={bodies}")

    if contract:
        for room in contract.get("rooms", []):
            scene_file = ROOT / str(room.get("scene_path", "")).replace("res://", "")
            runtime_file = ROOT / str(room.get("runtime_scene_path", "")).replace("res://", "")
            if not scene_file.is_file() or not runtime_file.is_file():
                report(errors, f"{room.get('id')}: contract references missing scene/runtime file")
            room_id = str(room.get("id", "")).replace("A2-", "")
            if room_id in MARKERS and scene_file.is_file():
                source = scene_file.read_text(encoding="utf-8")
                for marker in MARKERS[room_id]:
                    if f'[node name="{marker}" type="Marker2D" parent="RoomMarkers"]' not in source:
                        report(errors, f"{room.get('id')}: missing contract marker {marker}")
        for connection in contract.get("connections", []):
            if connection.get("status") != "implemented_pending_godot_playtest":
                report(errors, f"{connection.get('id')}: unexpected status={connection.get('status')}")

    r01_path = ROOT / "scenes/rooms/a2_fog_forest/a2_r01_forest_crossroads.tscn"
    if r01_path.is_file():
        audit_r01_illustration(r01_path.read_text(encoding="utf-8"), errors)

    route_contracts = [
        ('_spawn_drop_transition_at_marker("DropToR04", 48.0, 120.0, "A2-R04", "a2_r04_tomb_drop_r01")', "R01->R04 narrow drop shaft"),
        ('_spawn_drop_transition_at_marker("DropToR04", 150.0, 220.0, "A2-R04", "a2_r04_tomb_drop")', "R03->R04 drop"),
        ('_spawn_exit_door_at_marker("ExitToR06", "E  深入东侧裂谷", "ash_forest", _scene_path_for_room("A2-R06"), "a2_r06_low_entry")', "R04->R06 low entry"),
        ('_spawn_exit_door_at_marker("ExitToR04", "E  返回钟墓坑底", "ash_forest", _scene_path_for_room("A2-R04"), "a2_r04_ravine_return")', "R06->R04 low return"),
        ('_spawn_exit_door_at_marker("ExitToR06", "E  进入东侧裂谷", "ash_forest", _scene_path_for_room("A2-R06"), "a2_r06_high_entry")', "R05->R06 high entry"),
        ('_spawn_exit_door_at_marker("ExitToR05", "E  返回旧朝圣高路", "ash_forest", _scene_path_for_room("A2-R05"), "a2_r05_ravine_return")', "R06->R05 high return"),
        ('_spawn_exit_door_at_marker("ExitToA3", "E  沿树冠高路进入被遗忘的城区", "forgotten_city", "res://scenes/forgotten_city.tscn", "city_canopy_entry")', "C03 outbound"),
        ('_spawn_exit_door_at_marker("ExitToA5", "E  返回边境战场", "old_battlefield", "res://scenes/old_battlefield.tscn", "old_pilgrim_highroad")', "C04 outbound"),
        ("_spawn_h02_gate(h02_position.x, h02_position.y)", "H02 gate placement"),
    ]
    for fragment, label in route_contracts:
        require(runtime_source, fragment, label, errors)

    cross_region_path = ROOT / "scripts/levels/greybox_world_region.gd"
    cross_region_source = cross_region_path.read_text(encoding="utf-8") if cross_region_path.is_file() else ""
    require(cross_region_source, 'if region_id == "A2" and room_id.begins_with("A2-R"):', "authored A2 renderer guard", errors)
    require(cross_region_source, "Do not draw the legacy opaque graybox backdrop", "authored A2 renderer guard comment", errors)
    for fragment, label in (
        ('"east":', "C03 return-side mapping"),
        ('destination_scene = "res://scenes/rooms/a2_fog_forest/runtime/a2_r06_room.tscn"', "C03 return destination"),
        ('"old_pilgrim_highroad":', "C04 return-side mapping"),
        ('destination_scene = "res://scenes/rooms/a2_fog_forest/runtime/a2_r05_room.tscn"', "C04 return destination"),
        ('"bell_gate":', "H02 return-side mapping"),
        ('destination_scene = "res://scenes/rooms/a2_fog_forest/runtime/a2_r04_room.tscn"', "H02 return destination"),
        ('destination_spawn_side = "a2_r06_c03_return"', "C03 landing marker mapping"),
        ('destination_spawn_side = "a2_r05_c04_return"', "C04 landing marker mapping"),
        ('destination_spawn_side = "a2_r04_h02_return"', "H02 landing marker mapping"),
    ):
        require(cross_region_source, fragment, f"scripts/levels/greybox_world_region.gd {label}", errors)

    if errors:
        for error in errors:
            print(f"[FAIL] {error}")
        for warning in warnings:
            print(f"[WARN] {warning}")
        print("A2 authored room structure: FAIL")
        print("BOUNDARY: static checks only; run Godot 4.6.1 to verify SVG import, collision, movement, and transitions.")
        return 1

    print(f"A2 authored room structure: PASS rooms=6/6 platforms={total_platforms} collision_bodies={total_bodies}")
    for warning in warnings:
        print(f"[WARN] {warning}")
    print("BOUNDARY: static structure only. SVG rendering, scene parsing/import, actual jump reachability, and room transitions still require Godot 4.6.1 playtesting.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
