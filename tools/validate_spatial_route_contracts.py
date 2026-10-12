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
        ("C10", "A6", "bell_drop", 2100.0, -90.0),
        ("C12", "A4", "prison_tunnel", 1090.0, -75.0),
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
        require(
            errors,
            has_side_return(x_body, region, side, f"{expected_x:.1f}"),
            f"{edge_id}: _spawn_x_for_side lacks {region}/{side} -> {expected_x:g}.",
        )
        require(
            errors,
            has_side_return(y_body, region, side, f"floor_y - {abs(expected_y_offset):.1f}")
            if expected_y_offset < 0
            else has_side_return(y_body, region, side, "floor_y"),
            f"{edge_id}: _spawn_y_for_side lacks the matching vertical offset for {region}/{side}.",
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
