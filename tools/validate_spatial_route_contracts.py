#!/usr/bin/env python3
"""Check high-value box-world spatial contracts against the graybox spawn mappings.

This is a static consistency check. It does not run Godot physics or prove a route is
reachable in-engine.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOPOLOGY_PATH = ROOT / "tools/world_map_topology.json"
REGION_SCRIPT_PATH = ROOT / "scripts/levels/greybox_world_region.gd"
VILLAGE_SCRIPT_PATH = ROOT / "scripts/levels/village_hub.gd"
REST_POINT_SCRIPT_PATH = ROOT / "scripts/world/rest_point.gd"
LOCAL_ROUTE_SCRIPT_PATH = ROOT / "scripts/world/resonance_local_route.gd"
HIDDEN_GATE_SCRIPT_PATH = ROOT / "scripts/world/resonance_secret_gate.gd"


def function_body(source: str, function_name: str) -> str:
    match = re.search(
        rf"^func {re.escape(function_name)}\([^\n]*\).*?:\n(.*?)(?=^func |\Z)",
        source,
        re.MULTILINE | re.DOTALL,
    )
    if not match:
        raise ValueError(f"Missing function: {function_name}")
    return match.group(1)


def has_side_return(body: str, region: str, side: str, expected: str) -> bool:
    pattern = (
        rf'if region_id == "{re.escape(region)}" and side == "{re.escape(side)}":'
        rf"\s*(?:#.*\n\s*)*return {re.escape(expected)}\s*(?:\n|$)"
    )
    return re.search(pattern, body) is not None


def require(errors: list[str], condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def main() -> int:
    errors: list[str] = []
    try:
        topology = json.loads(TOPOLOGY_PATH.read_text(encoding="utf-8"))
        region_source = REGION_SCRIPT_PATH.read_text(encoding="utf-8")
        village_source = VILLAGE_SCRIPT_PATH.read_text(encoding="utf-8")
        rest_point_source = REST_POINT_SCRIPT_PATH.read_text(encoding="utf-8")
        local_route_source = LOCAL_ROUTE_SCRIPT_PATH.read_text(encoding="utf-8")
        hidden_gate_source = HIDDEN_GATE_SCRIPT_PATH.read_text(encoding="utf-8")
        x_body = function_body(region_source, "_spawn_x_for_side")
        y_body = function_body(region_source, "_spawn_y_for_side")
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"[FAIL] Could not load spatial contract inputs: {exc}")
        return 1

    edges = {edge.get("id"): edge for edge in topology.get("connections", [])}

    # Each tuple is (edge ID, destination region, incoming side, x, y offset).
    # These are the ledges whose coordinates must remain synchronized with the map contract.
    contracts = [
        ("C03", "A2", "east", 3220.0, -140.0),
        ("C05", "A3", "sewer", 1380.0, -115.0),
        ("C07", "A4", "royal_tomb_waterway", 1410.0, -85.0),
        ("C08", "A3", "city_highroad_return", 2360.0, -130.0),
        ("C10", "A6", "bell_drop", 2100.0, -90.0),
        ("C12", "A4", "prison_tunnel", 960.0, -75.0),
        ("C13", "A7", "maintenance_shaft_return", 2340.0, -160.0),
        ("C16", "A3", "old_lift", 1960.0, -70.0),
        ("C17", "A9", "cathedral_roof_return", 2450.0, -180.0),
        ("C23", "A4", "royal_drain", 1540.0, -120.0),
    ]

    for edge_id, region, side, expected_x, expected_y_offset in contracts:
        edge = edges.get(edge_id, {})
        spatial = edge.get("spatial_contract", {})
        spawn = spatial.get("return_spawn", {})
        require(errors, bool(edge), f"{edge_id}: connection is missing from topology.")
        require(
            errors,
            spawn.get("region") == region
            and float(spawn.get("x", float("nan"))) == expected_x
            and float(spawn.get("y_offset", float("nan"))) == expected_y_offset,
            f"{edge_id}: topology return_spawn must be {region} x={expected_x:g}, y_offset={expected_y_offset:g}.",
        )
        x_mapping_matches = has_side_return(x_body, region, side, f"{expected_x:.1f}")
        if edge_id == "C13":
            x_mapping_matches = (
                x_mapping_matches
                or re.search(
                    r'if region_id == "A7" and side == "maintenance_shaft_return":\s*(?:#.*\n\s*)*return map_width - 260\.0',
                    x_body,
                ) is not None
            )
        require(
            errors,
            x_mapping_matches,
            f"{edge_id}: _spawn_x_for_side lacks {region}/{side} -> {expected_x:g} (or the authored map_width-relative expression).",
        )
        require(
            errors,
            has_side_return(y_body, region, side, f"floor_y - {abs(expected_y_offset):.1f}")
            if expected_y_offset < 0
            else has_side_return(y_body, region, side, "floor_y"),
            f"{edge_id}: _spawn_y_for_side lacks the matching vertical offset for {region}/{side}.",
        )

    # C13's door anchors and safe return spawn must match the topology; door roots are y=-180 and Hero landings are y=-160.
    # C13 门锚点与安全出生点必须和拓扑一致；门节点为 y=-180，主角落在 y=-160 的平台顶。
    c13 = edges.get("C13", {}).get("spatial_contract", {})
    c13_from = c13.get("from_region_anchor", {})
    c13_to = c13.get("to_region_anchor", {})
    c13_return = c13.get("return_spawn", {})
    c13_arrival = c13.get("to_region_spawn", {})
    require(
        errors,
        c13_from.get("region") == "A7" and c13_from.get("x") == 2528
        and c13_from.get("y_offset") == -180,
        "C13: A7 door anchor must be x=2528 / y_offset=-180.",
    )
    require(
        errors,
        c13_to.get("region") == "A8" and c13_to.get("x") == 72
        and c13_to.get("y_offset") == -180,
        "C13: A8 door anchor must be x=72 / y_offset=-180.",
    )
    require(
        errors,
        c13_return.get("region") == "A7" and c13_return.get("x") == 2340
        and c13_return.get("y_offset") == -160
        and c13_return.get("spawn_side") == "maintenance_shaft_return",
        "C13: A7 return spawn must be x=2340 / y_offset=-160, clear of the east door focus.",
    )
    require(
        errors,
        c13_arrival.get("region") == "A8" and c13_arrival.get("x") == 190
        and c13_arrival.get("y_offset") == -160
        and c13_arrival.get("spawn_side") == "maintenance_shaft_entry",
        "C13: A8 arrival spawn must be x=190 / y_offset=-160 on the supported entry platform.",
    )

    # C08 must remain a paired elevated route with matching destination and return spawn metadata.
    c08 = edges.get("C08", {}).get("spatial_contract", {})
    c08_from = c08.get("from_region_anchor", {})
    c08_to = c08.get("to_region_anchor", {})
    c08_return = c08.get("return_spawn", {})
    c08_arrival = c08.get("from_region_spawn", {})
    require(
        errors,
        c08_from.get("region") == "A3"
        and float(c08_from.get("x", float("nan"))) == 2240.0
        and float(c08_from.get("y_offset", float("nan"))) == -130.0,
        "C08: A3 must leave from the raised parapet at x=2240 / y_offset=-130.",
    )
    require(
        errors,
        c08_to.get("region") == "A5"
        and c08_to.get("x") == 180
        and c08_to.get("y_offset") == -130
        and c08_to.get("spawn_side") == "city_highroad",
        "C08: A5 arrival must use the raised city_highroad landing at x=180 / y_offset=-130.",
    )
    require(
        errors,
        c08_return.get("region") == "A3"
        and c08_return.get("x") == 2360
        and c08_return.get("y_offset") == -130
        and c08_return.get("spawn_side") == "city_highroad_return",
        "C08: return to A3 must land on the supported upper parapet at x=2360 / y_offset=-130.",
    )
    require(
        errors,
        c08_arrival.get("region") == "A5"
        and c08_arrival.get("x") == 330
        and c08_arrival.get("y_offset") == -130
        and c08_arrival.get("spawn_side") == "city_highroad",
        "C08: reverse arrival in A5 must use the matching upper landing at x=330 / y_offset=-130.",
    )

    require(
        errors,
        has_side_return(x_body, "A5", "city_highroad", "330.0"),
        "C08: _spawn_x_for_side must map A5/city_highroad to x=330.",
    )
    require(
        errors,
        has_side_return(y_body, "A5", "city_highroad", "floor_y - 130.0"),
        "C08: _spawn_y_for_side must place A5/city_highroad on the raised landing.",
    )

    # C24 is authored across two different controllers, so validate both sides explicitly.
    c24 = edges.get("C24", {}).get("spatial_contract", {})
    to_spawn = c24.get("to_region_spawn", {})
    return_spawn = c24.get("return_spawn", {})
    intermediate = c24.get("intermediate_scene", {})
    require(
        errors,
        intermediate.get("scene_path") == "scenes/old_drain_exploration.tscn"
        and intermediate.get("first_visit_spawn_side") == "village_entry"
        and intermediate.get("a3_entry_spawn_side") == "city_side_entry"
        and intermediate.get("reservoir_return_spawn_side") == "reservoir_link"
        and intermediate.get("a3_link_unlock_flag") == "opened_old_drainage_link_from_A4",
        "C24: topology must document the phased old-drain scene and all three spawn sides.",
    )
    require(
        errors,
        to_spawn.get("region") == "A3"
        and to_spawn.get("spawn_side") == "village_city_cut"
        and float(to_spawn.get("x", float("nan"))) == 700.0
        and float(to_spawn.get("y_offset", float("nan"))) == 0.0,
        "C24: topology must keep the final A3 landing at x=700 after traversing the old-drain segment.",
    )
    require(
        errors,
        has_side_return(x_body, "A3", "village_city_cut", "700.0"),
        "C24: A3 spawn mapping for village_city_cut must remain x=700.",
    )
    require(
        errors,
        return_spawn.get("region") == "A1"
        and return_spawn.get("spawn_side") == "city_cut_return"
        and float(return_spawn.get("x", float("nan"))) == 350.0,
        "C24: topology must keep the A1 return spawn at x=350 / city_cut_return.",
    )
    require(
        errors,
        'spawn_side == "city_cut_return"' in village_source
        and '350.0 if spawn_side == "city_cut_return"' in village_source,
        "C24: village_hub.gd must map city_cut_return to its safe x=350 landing.",
    )

    # Elevated exits must be anchored to a platform at the authored doorway height.
    # This catches metadata/code drift that a region-level graph cannot detect.
    exit_function = function_body(region_source, "_spawn_region_exits")
    exit_blocks = {
        match.group(1): match.group(2)
        for match in re.finditer(
            r'^\t\t"([A-Z]\d{1,2})":\n(.*?)(?=^\t\t"[A-Z]\d{1,2}":|^\t\t_:|\Z)',
            exit_function,
            re.MULTILINE | re.DOTALL,
        )
    }
    require(
        errors,
        "city_highroad" in exit_blocks.get("A3", "") and "floor_y - 130.0" in exit_blocks.get("A3", ""),
        "C08: A3 must wire the raised exit to the city_highroad spawn side.",
    )
    require(
        errors,
        "city_highroad_return" in exit_blocks.get("A5", "") and "floor_y - 130.0" in exit_blocks.get("A5", ""),
        "C08: A5 must wire the raised return door to city_highroad_return.",
    )

    platform_function = function_body(region_source, "_configure_platforms")
    region_blocks = {
        match.group(1): match.group(2)
        for match in re.finditer(
            r'^\t\t"([A-Z]\d{1,2})":\n(.*?)(?=^\t\t"[A-Z]\d{1,2}":|^\t\t_:|\Z)',
            platform_function,
            re.MULTILINE | re.DOTALL,
        )
    }
    platform_rects: dict[str, list[tuple[float, float, float, float]]] = {}
    for region, block in region_blocks.items():
        platform_rects[region] = [
            tuple(float(value) for value in match.groups())
            for match in re.finditer(
                r"_add_platform\(Rect2\(([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)\)\)",
                block,
            )
        ]

    # (connection, region, x, y_offset); y is derived from the shared floor_y=540.
    elevated_doors = [
        ("C03", "A2", 3400.0, -160.0),
        ("C22", "A12", 2130.0, -180.0),
        ("C13", "A7", 2528.0, -180.0),
        ("C13", "A8", 72.0, -180.0),
        ("C08", "A3", 2240.0, -130.0),
        ("C08", "A5", 180.0, -130.0),
        ("C05", "A3", 1600.0, -115.0),
        ("C09", "A5", 2250.0, -90.0),
        ("C10", "A6", 2230.0, -55.0),
        ("C16", "A3", 2040.0, -70.0),
        ("C17", "A9", 2350.0, -180.0),
        ("C23", "A9", 740.0, -150.0),
        ("C23", "A4", 1650.0, -105.0),
    ]
    for edge_id, region, x, y_offset in elevated_doors:
        door_y = 540.0 + y_offset
        # C03's door origin sits 30px above the platform top by design; its
        # interaction shape is offset down from that origin and overlaps the ledge.
        # C03 门节点原点按设计高于平台顶 30px；交互碰撞形状向下偏移并覆盖栈台。
        vertical_tolerance = 35.0 if edge_id == "C03" else 20.0
        supported = any(
            left <= x <= left + width and abs(platform_y - door_y) <= vertical_tolerance
            for left, platform_y, width, _height in platform_rects.get(region, [])
        )
        require(
            errors,
            supported,
            f"{edge_id}: elevated door anchor {region} x={x:g}, y={door_y:g} is not supported by a nearby authored platform.",
        )

    c13_a7_exit = exit_blocks.get("A7", "")
    c13_a8_exit = exit_blocks.get("A8", "")
    require(
        errors,
        "maintenance_shaft_entry" in c13_a7_exit
        and "map_width - 72.0" in c13_a7_exit
        and "floor_y - 180.0" in c13_a7_exit,
        "C13: A7's east door must use x=map_width-72 and y_offset=-180.",
    )
    require(
        errors,
        "maintenance_shaft_return" in c13_a8_exit
        and "72.0" in c13_a8_exit
        and "floor_y - 180.0" in c13_a8_exit,
        "C13: A8's west door must use x=72 and y_offset=-180.",
    )

    # Incoming spawn points must not overlap the destination door's Area2D trigger
    # or activate a neighboring rest prompt immediately after the transition.
    # 目标出生点不得与目的地门的 Area2D 触发区重叠，也不得一落地就激活相邻休整提示。
    c07 = edges.get("C07", {}).get("spatial_contract", {})
    c07_spawn = c07.get("return_spawn", {})
    require(
        errors,
        c07_spawn.get("region") == "A4"
        and c07_spawn.get("spawn_side") == "royal_tomb_waterway"
        and float(c07_spawn.get("x", float("nan"))) == 1410.0
        and float(c07_spawn.get("y_offset", float("nan"))) == -85.0
        and has_side_return(x_body, "A4", "royal_tomb_waterway", "1410.0")
        and has_side_return(y_body, "A4", "royal_tomb_waterway", "floor_y - 85.0"),
        "C07: A4 arrival must use x=1410 / y_offset=-85, away from the x=1320 door trigger.",
    )
    c23 = edges.get("C23", {}).get("spatial_contract", {})
    c23_spawn = c23.get("return_spawn", {})
    require(
        errors,
        c23_spawn.get("region") == "A4"
        and c23_spawn.get("spawn_side") == "royal_drain"
        and float(c23_spawn.get("x", float("nan"))) == 1540.0
        and float(c23_spawn.get("y_offset", float("nan"))) == -120.0
        and has_side_return(x_body, "A4", "royal_drain", "1540.0")
        and has_side_return(y_body, "A4", "royal_drain", "floor_y - 120.0"),
        "C23: A4 arrival must use the supported x=1540 lip, not the narrow-clearance x=1570 point.",
    )
    c18 = edges.get("C18", {}).get("spatial_contract", {})
    c18_spawn = c18.get("return_spawn", {})
    require(
        errors,
        c18_spawn.get("region") == "A9"
        and c18_spawn.get("spawn_side") == "inner_city_side_gate"
        and float(c18_spawn.get("x", float("nan"))) == 980.0
        and has_side_return(x_body, "A9", "inner_city_side_gate", "980.0"),
        "C18: A9 arrival must be outside both the x=900 door trigger and x=1100 rest focus radius.",
    )
    door_trigger_half_width = 55.0
    hero_half_width = 18.0
    c07_horizontal_clearance = abs(1410.0 - 1320.0) - door_trigger_half_width - hero_half_width
    c23_horizontal_clearance = abs(1650.0 - 1540.0) - door_trigger_half_width - hero_half_width
    c18_door_clearance = abs(980.0 - 900.0) - door_trigger_half_width - hero_half_width
    c18_rest_clearance = abs(1100.0 - 980.0) - 110.0
    require(
        errors,
        c07_horizontal_clearance > 0.0 and c23_horizontal_clearance > 0.0
        and c18_door_clearance > 0.0 and c18_rest_clearance > 0.0,
        "C07/C18/C23: spawn-to-trigger or spawn-to-rest-focus clearance must remain positive.",
    )
    require(
        errors,
        "rectangle.size = Vector2(110.0, 80.0)" in region_source
        and "shape.position = Vector2(0.0, -35.0)" in region_source
        and "capsule.radius = radius" in region_source,
        "Spawn-clearance contracts assume the current 110x80 door trigger and 18px Hero collision radius.",
    )

    for connection_id, region, spawn_x, spawn_y in [
        ("C07 arrival", "A4", 1410.0, 455.0),
        ("C17 return", "A9", 2450.0, 360.0),
        ("C23 arrival", "A4", 1540.0, 420.0),
    ]:
        supported = any(
            left <= spawn_x <= left + width and abs(platform_y - spawn_y) <= 1.0
            for left, platform_y, width, _height in platform_rects.get(region, [])
        )
        require(
            errors,
            supported,
            f"{connection_id}: arrival x={spawn_x:g}, y={spawn_y:g} must stand on an authored platform top.",
        )

    # C17's return used to respawn 30px from the same door and immediately re-enter its trigger.
    # C17 旧回程点距同一扇门仅 30px，转场后会立即再次进入门触发区。
    c17_return = edges.get("C17", {}).get("spatial_contract", {}).get("return_spawn", {})
    require(
        errors,
        c17_return.get("region") == "A9"
        and c17_return.get("spawn_side") == "cathedral_roof_return"
        and float(c17_return.get("x", float("nan"))) == 2450.0
        and float(c17_return.get("y_offset", float("nan"))) == -180.0
        and has_side_return(x_body, "A9", "cathedral_roof_return", "2450.0"),
        "C17: A9 return must land at x=2450 / y_offset=-180, clear of the x=2350 door.",
    )
    c17_clearance = abs(2450.0 - 2350.0) - 55.0 - 18.0
    require(errors, c17_clearance > 0.0, "C17: rooftop return must remain outside its door trigger.")

    # Hidden-well return must stay between the east-side C06 door and the H01 gate.
    # 隐藏水井回程必须落在东侧 C06 门与 H01 隐藏井门之间。
    require(
        errors,
        has_side_return(x_body, "A4", "east", "map_width - 220.0")
        and "_spawn_a4_hidden_well_gate(map_width - 90.0)" in region_source,
        "H01 -> A4: arrival must avoid the x=2220 C06 watergate and the east-side hidden-well gate.",
    )
    a4_east_x = 2600.0 - 220.0
    require(
        errors,
        abs(a4_east_x - 2220.0) - 55.0 - 18.0 > 0.0
        and abs(a4_east_x - (2600.0 - 90.0)) > 80.0,
        "H01 -> A4: arrival must clear both the C06 door trigger and the H01 gate radius.",
    )

    # H05's return must not activate the A6 rest point as soon as the Hero arrives.
    # H05 返回 A6 时不能一落地就激活该区域的休整点。
    require(
        errors,
        has_side_return(x_body, "A6", "silent_window", "1420.0")
        and "rest_x = 1300.0" in region_source
        and abs(1420.0 - 1300.0) > 110.0,
        "H05 -> A6: arrival must stay outside the rest point's 110px interaction radius.",
    )

    # Rest points must only save grounded floor-level coordinates. A proximity-only check can
    # otherwise save an airborne or upper-platform checkpoint and respawn the Hero unsupported.
    # 休整点只能记录地面承托位置；单纯距离检测可能把空中或上层平台坐标存成死亡出生点。
    require(
        errors,
        "func _hero_can_rest(hero: Node2D) -> bool:" in rest_point_source
        and "body.is_on_floor()" in rest_point_source
        and "absf(body.global_position.x - global_position.x) <= 90.0" in rest_point_source
        and "absf(body.global_position.y - global_position.y) <= 32.0" in rest_point_source,
        "Rest points must require a grounded Hero within 90px horizontally and 32px vertically.",
    )
    require(
        errors,
        "WorldState.set_checkpoint(hero.global_position)" in rest_point_source,
        "Rest points must persist the Hero's current supported position only after the grounded gate passes.",
    )

    # Death recovery must lock input, clear stale interaction focus, and restore at the region-local checkpoint.
    # 死亡恢复必须锁定输入、清除过期交互焦点，并回到当前区域的检查点。
    death_body = function_body(region_source, "_on_hero_defeated")
    require(
        errors,
        "WorldState.input_locked = true" in death_body
        and "INTERACTION_FOCUS_SCRIPT.clear_all(get_tree())" in death_body
        and "hero.global_position = WorldState.checkpoint_position" in death_body
        and "WorldState.input_locked = false" in death_body
        and "WorldState.set_checkpoint(hero.global_position)" in function_body(region_source, "_spawn_hero"),
        "Death recovery must clear focus and use the current region's checkpoint before re-enabling interaction.",
    )

    # Ending access must follow the evaluator's resonance/item/exploration candidate,
    # never physical intimacy.
    require(
        errors,
        region_source.count('NereisEndingEvaluator.get_candidate() != "凡人之墓"') >= 2
        and "physical_union_complete" not in region_source,
        "C21/H08: terminal routes must use the ending evaluator, not physical_union_complete.",
    )

    # C22 must leave from the upper throne platform and stay distinct from H07 below.
    # C22 必须从王座厅上层平台离开，并与下方的 H07 镜街入口保持净距。
    c22 = edges.get("C22", {}).get("spatial_contract", {})
    c22_from = c22.get("from_region_anchor", {})
    c22_to = c22.get("to_region_anchor", {})
    require(
        errors,
        c22_from.get("region") == "A12" and c22_from.get("x") == 2130
        and c22_from.get("y_offset") == -180,
        "C22: A12 exit must use the supported upper approach at x=2130 / y_offset=-180.",
    )
    require(
        errors,
        c22_to.get("region") == "A13" and c22_to.get("x") == 180
        and c22_to.get("spawn_side") == "west",
        "C22: A13 arrival must remain on the west-side terminal-layer entry.",
    )
    c22_exit = exit_blocks.get("A12", "")
    require(
        errors,
        "2130.0" in c22_exit and "floor_y - 180.0" in c22_exit,
        "C22: A12 exit code must match the upper-throne spatial contract.",
    )

    # C17 has no explicit return_spawn field, but its high approach and target spawn side are important.
    c17 = edges.get("C17", {}).get("spatial_contract", {})
    from_anchor = c17.get("from_region_anchor", {})
    to_anchor = c17.get("to_region_anchor", {})
    require(
        errors,
        from_anchor.get("region") == "A9"
        and float(from_anchor.get("x", float("nan"))) == 2350.0
        and float(from_anchor.get("y_offset", float("nan"))) == -180.0
        and to_anchor.get("region") == "A10"
        and to_anchor.get("spawn_side") == "cathedral_roof",
        "C17: cathedral transition must remain an elevated A9 approach with a west-side A10 entry.",
    )

    # A2 Bell Grave / canopy baseline contracts. These checks keep source and topology
    # synchronized; they intentionally do not claim Godot physics or input acceptance.
    intra_edges = {edge.get("id"): edge for edge in topology.get("intra_region_connections", [])}
    a2_contract = topology.get("a2_spatial_acceptance_contract", {})
    sc007 = intra_edges.get("SC007", {})
    sc008 = intra_edges.get("SC008", {})
    sc009 = intra_edges.get("SC009", {})
    sc010 = intra_edges.get("SC010", {})
    sc011 = intra_edges.get("SC011", {})
    sc072 = intra_edges.get("SC072", {})
    sc073 = intra_edges.get("SC073", {})
    a2_subregions = {
        item.get("id"): item
        for item in topology.get("subregions", [])
        if item.get("parent_region") == "A2"
    }
    expected_a2_subregions = {
        "A2-S01": "雾林地面",
        "A2-S02": "钟墓外圈",
        "A2-S03": "钟墓坑底",
        "A2-S04": "树冠栈道",
        "A2-S05": "旧朝圣高路",
        "A2-S06": "东部沟壑与林下绕行",
        "A2-S07": "东部树冠延伸段",
    }
    require(
        errors,
        all(
            a2_subregions.get(subregion_id, {}).get("name") == name
            for subregion_id, name in expected_a2_subregions.items()
        ) and len(a2_subregions) == len(expected_a2_subregions),
        "A2 topology must contain the five baseline subregions plus S06-S07 expansion spaces.",
    )
    require(
        errors,
        sc007.get("from") == "A2-S01" and sc007.get("to") == "A2-S02"
        and sc007.get("travel") == "both" and sc007.get("initial_state") == "open"
        and sc007.get("unlock_condition") == "",
        "A2 SC007: ordinary ground access to the Bell Grave exterior must remain open and ungated.",
    )
    require(
        errors,
        sc009.get("from") == "A2-S01" and sc009.get("to") == "A2-S04"
        and sc009.get("travel") == "both" and sc009.get("initial_state") == "open"
        and sc009.get("unlock_condition") == "",
        "A2 SC009: the baseline ground-canopy route must remain open and bidirectional.",
    )
    require(
        errors,
        sc010.get("from") == "A2-S04" and sc010.get("to") == "A2-S05"
        and sc010.get("travel") == "both" and sc010.get("initial_state") == "open"
        and sc010.get("unlock_condition") == "",
        "A2 SC010: the canopy-to-old-pilgrim approach must remain open, independently of C04's lock.",
    )
    require(
        errors,
        sc072.get("from") == "A2-S04" and sc072.get("to") == "A2-S06"
        and sc072.get("travel") == "both" and sc072.get("initial_state") == "open",
        "A2 SC072: eastern ravine must connect canopy to a bidirectional lower bypass.",
    )
    require(
        errors,
        sc073.get("from") == "A2-S06" and sc073.get("to") == "A2-S07"
        and sc073.get("travel") == "both" and sc073.get("initial_state") == "open",
        "A2 SC073: lower bypass must rejoin the expanded eastern canopy route.",
    )
    sc068 = next((item for item in topology.get("elevators", []) if item.get("id") == "LFT01"), {})
    require(
        errors,
        sc008.get("from") == "A2-S02" and sc008.get("to") == "A2-S03"
        and sc008.get("travel") == "both" and sc008.get("initial_state") == "open",
        "A2 SC008: topology must keep the ordinary Bell Grave pit open and bidirectional.",
    )
    require(
        errors,
        sc011.get("from") == "A2-S04" and sc011.get("to") == "A2-S04"
        and sc011.get("initial_state") == "locked"
        and sc011.get("unlock_condition") == "resonance_20_and_sight",
        "A2 SC011: the resonance bridge must remain a locked canopy-internal crossing, not a ground-to-canopy loop.",
    )
    require(
        errors,
        sc068.get("id") == "LFT01"
        and sc068.get("implementation_status") == "deferred_not_in_a2_baseline_acceptance",
        "A2 LFT01: the unimplemented lift must remain deferred and excluded from baseline acceptance.",
    )
    require(
        errors,
        a2_contract.get("status") == "partial_runtime_code_added_not_engine_verified",
        "A2 spatial contract must not be marked engine-verified before Godot acceptance.",
    )

    ready_body = function_body(region_source, "_ready")
    floor_body = function_body(region_source, "_create_floor")
    local_routes_body = function_body(region_source, "_spawn_local_resonance_routes")
    hidden_gate_feedback = function_body(region_source, "_on_optional_hidden_gate_opened")
    local_route_feedback = function_body(region_source, "_on_local_resonance_route_opened")
    require(
        errors,
        ready_body.find("_configure_platforms()") >= 0
        and ready_body.find("_create_floor()") > ready_body.find("_configure_platforms()"),
        "A2: _configure_platforms() must run before _create_floor() so pit ledges remain registered for drawing.",
    )
    require(
        errors,
        '_add_ground_segment("GreyboxGround_West", 0.0, 860.0)' in floor_body
        and '_add_ground_segment("GreyboxGround_Middle", 1060.0, 1360.0)' in floor_body
        and '_add_ground_segment("GreyboxGround_East", 2660.0, map_width - 2660.0)' in floor_body
        and "_add_platform(Rect2(860.0, 610.0, 200.0, 18.0))" in floor_body
        and "_add_platform(Rect2(850.0, 580.0, 70.0, 12.0))" in floor_body
        and "_add_platform(Rect2(1000.0, 580.0, 70.0, 12.0))" in floor_body
        and "_add_platform(Rect2(2420.0, 610.0, 240.0, 18.0))" in floor_body
        and "_add_platform(Rect2(2400.0, 580.0, 70.0, 12.0))" in floor_body
        and "_add_platform(Rect2(2590.0, 580.0, 70.0, 12.0))" in floor_body,
        "A2 SC008: ground gap, pit floor, and both return ledges must remain in runtime source.",
    )
    require(
        errors,
        "resonance >= required_resonance" in hidden_gate_source
        and "var next_revealed := opened_permanently or (active and (meets_thresholds or allow_override))" in hidden_gate_source,
        "H02: the shared hidden-gate logic must still require active Resonance Sight plus the authored resonance threshold before first reveal.",
    )
    require(
        errors,
        '_spawn_h02_gate(960.0, 610.0)' in exit_blocks.get("A2", "")
        and "gate.required_resonance = 18" in region_source
        and 'gate.target_scene_path = "res://scenes/hidden_bell_chamber.tscn"' in region_source,
        "A2 H02: hidden gate must remain on the pit floor and keep its existing 18-resonance condition.",
    )
    h02_exit_block = exit_blocks.get("H02", "")
    require(
        errors,
        h02_exit_block.count("_spawn_exit_door(") == 1
        and '"res://scenes/ash_forest.tscn", "bell_gate"' in h02_exit_block
        and "old_battlefield" not in h02_exit_block
        and "old_pilgrim_highroad" not in h02_exit_block,
        "H02: retain one return door to A2 only; do not add a second A5 exit.",
    )
    require(
        errors,
        'if secret_id == "H02":' in hidden_gate_feedback
        and hidden_gate_feedback.find('if secret_id == "H02":') < hidden_gate_feedback.find("return")
        and "feedback=environmental_only" in hidden_gate_feedback,
        "H02: opening feedback must stay environmental and must not invoke narrator-style exposition.",
    )
    require(
        errors,
        'if route_id == "A2_BELLGRAVE_CANOPY_CROSSING":' in local_route_feedback
        and local_route_feedback.find('if route_id == "A2_BELLGRAVE_CANOPY_CROSSING":')
        < local_route_feedback.find("if not is_instance_valid(narrative):")
        and 'print("[NEREIS][MAP][LOCAL_ROUTE] opened id=%s" % route_id)' in local_route_feedback,
        "A2 SC011: route activation must remain environmental-only and must not show narrator-style popup text.",
    )
    require(
        errors,
        'if not WorldState.debug_map_test_mode and region_id not in ["A2", "A3"]:' in ready_body,
        "A2/A3: first-entry text popups must not replace in-world discovery.",
    )
    require(
        errors,
        "A2_BELLGRAVE_CANOPY_CROSSING" in local_routes_body
        and "route.required_resonance = 20" in local_routes_body
        and "route.bridge_start_x = 1380.0" in local_routes_body
        and "route.bridge_end_x = 1610.0" in local_routes_body
        and "route.bridge_y = 328.0" in local_routes_body,
        "A2 SC011: runtime resonance bridge coordinates and unlock threshold must match the canopy contract.",
    )
    require(
        errors,
        "var should_exist := revealed or opened_permanently or _hero_over_bridge()" in local_route_source
        and "Keep a temporary bridge solid while the Hero is standing on it" in local_route_source
        and "collision.one_way_collision = true" in local_route_source,
        "SC011: a temporary resonance bridge must not disappear under the Hero when Sight expires.",
    )

    # SC009's authored climb chain must exist in source. This is a coordinate inventory,
    # not a proof that the Hero can jump between the platforms in Godot.
    a2_climb_chain = [
        (360.0, 485.0, 145.0, 20.0),
        (535.0, 445.0, 125.0, 18.0),
        (685.0, 405.0, 110.0, 18.0),
        (760.0, 370.0, 110.0, 18.0),
        (850.0, 315.0, 150.0, 20.0),
        (1040.0, 275.0, 170.0, 20.0),
        (1250.0, 310.0, 145.0, 18.0),
        (1430.0, 350.0, 150.0, 18.0),
    ]
    require(
        errors,
        all(rect in platform_rects.get("A2", []) for rect in a2_climb_chain),
        "A2 SC009: expected landmark-led ground-to-canopy climb chain is incomplete or has drifted.",
    )

    # The eastern ravine needs two visually distinct approaches and a supported C03 landing.
    # 东部沟壑必须保留高低两种接近路线及 C03 实体承托；这仍是坐标检查，不等于实机可达。
    a2_eastern_route = [
        (2260.0, 475.0, 140.0, 18.0),
        (2390.0, 430.0, 110.0, 18.0),
        (2510.0, 465.0, 125.0, 18.0),
        (2645.0, 430.0, 125.0, 18.0),
        (2740.0, 330.0, 130.0, 18.0),
        (2900.0, 300.0, 130.0, 18.0),
        (3060.0, 330.0, 130.0, 18.0),
        (3180.0, 400.0, 130.0, 18.0),
        (3340.0, 380.0, 140.0, 18.0),
    ]
    require(
        errors,
        all(rect in platform_rects.get("A2", []) for rect in a2_eastern_route),
        "A2 eastern ravine: upper/lower route platforms or C03 support landing are missing.",
    )
    require(
        errors,
        all(label in function_body(region_source, "_draw_forest_landmarks") for label in ["钟墓外廊", "东侧残桥"]),
        "A2 landmark pass must visibly identify the Bell Grave gallery and eastern bridge.",
    )

    # Elevated A2 arrivals must be statically supported by authored platform tops.
    # This is a coordinate cross-check only; the Hero's actual feet/collision still needs engine testing.
    a2_supported_arrivals = [
        ("C03 A2 east return", 3220.0, 400.0),
        ("C03 A2 exit", 3400.0, 380.0),
        ("C04 A2 old pilgrim return", 1750.0, 400.0),
    ]
    for label, spawn_x, spawn_y in a2_supported_arrivals:
        supported = any(
            left <= spawn_x <= left + width and abs(platform_y - spawn_y) <= 1.0
            for left, platform_y, width, _height in platform_rects.get("A2", [])
        )
        require(errors, supported, f"{label}: expected support platform at x={spawn_x:g}, y={spawn_y:g}.")
    c04_edge = edges.get("C04", {})
    c04 = c04_edge.get("spatial_contract", {})
    c04_return = c04.get("return_spawn", {})
    c04_from = c04.get("from_region_anchor", {})
    c04_to = c04.get("to_region_anchor", {})
    require(
        errors,
        c04_edge.get("initial_access") == "blocked"
        and c04_edge.get("opens_from") == "A5"
        and c04_edge.get("unlock_condition") == "reached_A5_and_opened_old_pilgrim_highroad"
        and c04_from.get("region") == "A2" and c04_from.get("x") == 1880
        and c04_to.get("region") == "A5" and c04_to.get("x") == 520
        and c04_return.get("region") == "A2" and c04_return.get("x") == 1750
        and has_side_return(x_body, "A2", "old_pilgrim_highroad", "1750.0")
        and has_side_return(y_body, "A2", "old_pilgrim_highroad", "floor_y - 140.0"),
        "A2 C04: keep the A5-side unlock and supported A2 upper-route return spawn synchronized.",
    )
    require(
        errors,
        any(
            left <= 650.0 <= left + width and abs(platform_y - 455.0) <= 1.0
            for left, platform_y, width, _height in platform_rects.get("A5", [])
        )
        and has_side_return(x_body, "A5", "old_pilgrim_highroad", "650.0")
        and has_side_return(y_body, "A5", "old_pilgrim_highroad", "floor_y - 85.0"),
        "A2 C04: A5-side return spawn must remain on its authored upper platform.",
    )

    if errors:
        for error in errors:
            print(f"[FAIL] {error}")
        print(f"Spatial route contract check failed: {len(errors)} issue(s).")
        return 1

    print("Spatial route contract check passed.")
    print("Checked A2 subregions, SC007-SC011, pit/canopy/H02/C03/C04 plus C03/C05/C07/C08/C10/C12/C13/C16/C17/C18/C22/C23/C24 route and spawn contracts.")
    print("Checked arrival clearance, platform support, rest-point safety, and death-recovery focus reset.")
    print("Note: run the Godot project for collision, jump reachability, and transition acceptance.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
