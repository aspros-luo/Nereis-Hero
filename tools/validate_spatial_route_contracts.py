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
        x_body = function_body(region_source, "_spawn_x_for_side")
        y_body = function_body(region_source, "_spawn_y_for_side")
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"[FAIL] Could not load spatial contract inputs: {exc}")
        return 1

    edges = {edge.get("id"): edge for edge in topology.get("connections", [])}

    # Each tuple is (edge ID, destination region, incoming side, x, y offset).
    # These are the ledges whose coordinates must remain synchronized with the map contract.
    contracts = [
        ("C03", "A2", "east", 2120.0, -140.0),
        ("C05", "A3", "sewer", 1380.0, -115.0),
        ("C07", "A4", "royal_tomb_waterway", 1260.0, -85.0),
        ("C08", "A3", "city_highroad_return", 2360.0, -130.0),
        ("C10", "A6", "bell_drop", 2100.0, -90.0),
        ("C12", "A4", "prison_tunnel", 960.0, -75.0),
        ("C13", "A7", "maintenance_shaft_return", 2340.0, -120.0),
        ("C16", "A3", "old_lift", 1960.0, -70.0),
        ("C23", "A4", "royal_drain", 1620.0, -120.0),
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

    # C13's door anchors and safe return spawn must match the topology; the two door
    # nodes are at y=-140 while the Hero lands on the y=-120 ledge top.
    # C13 的门锚点与安全回程出生点必须和拓扑一致；门节点为 y=-140，主角落在 y=-120 的平台顶。
    c13 = edges.get("C13", {}).get("spatial_contract", {})
    c13_from = c13.get("from_region_anchor", {})
    c13_to = c13.get("to_region_anchor", {})
    c13_return = c13.get("return_spawn", {})
    c13_arrival = c13.get("to_region_spawn", {})
    require(
        errors,
        c13_from.get("region") == "A7" and c13_from.get("x") == 2528
        and c13_from.get("y_offset") == -140,
        "C13: A7 door anchor must be x=2528 / y_offset=-140.",
    )
    require(
        errors,
        c13_to.get("region") == "A8" and c13_to.get("x") == 72
        and c13_to.get("y_offset") == -140,
        "C13: A8 door anchor must be x=72 / y_offset=-140.",
    )
    require(
        errors,
        c13_return.get("region") == "A7" and c13_return.get("x") == 2340
        and c13_return.get("y_offset") == -120
        and c13_return.get("spawn_side") == "maintenance_shaft_return",
        "C13: A7 return spawn must be x=2340 / y_offset=-120, clear of the east door focus.",
    )
    require(
        errors,
        c13_arrival.get("region") == "A8" and c13_arrival.get("x") == 190
        and c13_arrival.get("y_offset") == -120
        and c13_arrival.get("spawn_side") == "maintenance_shaft_entry",
        "C13: A8 arrival spawn must be x=190 / y_offset=-120 on the supported entry platform.",
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
    require(
        errors,
        to_spawn.get("region") == "A3"
        and to_spawn.get("spawn_side") == "village_city_cut"
        and float(to_spawn.get("x", float("nan"))) == 700.0
        and float(to_spawn.get("y_offset", float("nan"))) == 0.0,
        "C24: topology must keep the A3 landing at x=700 on the ground-level drainage route.",
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
        ("C03", "A2", 2240.0, -160.0),
        ("C22", "A12", 2130.0, -65.0),
        ("C13", "A7", 2528.0, -140.0),
        ("C13", "A8", 72.0, -140.0),
        ("C08", "A3", 2240.0, -130.0),
        ("C08", "A5", 180.0, -130.0),
        ("C05", "A3", 1600.0, -115.0),
        ("C09", "A5", 2250.0, -90.0),
        ("C10", "A6", 2230.0, -55.0),
        ("C16", "A3", 2040.0, -70.0),
        ("C17", "A9", 2350.0, -180.0),
        ("C23", "A9", 850.0, -150.0),
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
        and "floor_y - 140.0" in c13_a7_exit,
        "C13: A7's east door must use x=map_width-72 and y_offset=-140.",
    )
    require(
        errors,
        "maintenance_shaft_return" in c13_a8_exit
        and "72.0" in c13_a8_exit
        and "floor_y - 140.0" in c13_a8_exit,
        "C13: A8's west door must use x=72 and y_offset=-140.",
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
        and c22_from.get("y_offset") == -65,
        "C22: A12 exit must use the supported upper approach at x=2130 / y_offset=-65.",
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
        "2130.0" in c22_exit and "floor_y - 65.0" in c22_exit,
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
        and to_anchor.get("spawn_side") == "west",
        "C17: cathedral transition must remain an elevated A9 approach with a west-side A10 entry.",
    )

    if errors:
        for error in errors:
            print(f"[FAIL] {error}")
        print(f"Spatial route contract check failed: {len(errors)} issue(s).")
        return 1

    print("Spatial route contract check passed.")
    print("Checked C03/C05/C07/C10/C12/C16/C17/C23/C24 spawn and elevation contracts.")
    print("Note: run the Godot project for collision, jump reachability, and transition acceptance.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
