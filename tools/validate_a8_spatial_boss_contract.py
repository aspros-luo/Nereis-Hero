#!/usr/bin/env python3
"""Focused static audit for A8's spatial routes and future encounter placeholder.

This validates source/data consistency only. It does not prove collision, jumps,
interaction radii, death recovery, or scene transitions in Godot.
Run: python3 tools/validate_a8_spatial_boss_contract.py
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOPOLOGY = ROOT / "tools/world_map_topology.json"
REGION = ROOT / "scripts/levels/greybox_world_region.gd"
A8_SCENE = ROOT / "scenes/royal_tomb.tscn"
WORLD_STATE = ROOT / "scripts/core/world_state.gd"


def require(errors: list[str], condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def function_body(source: str, name: str) -> str:
    match = re.search(
        rf"^func {re.escape(name)}\([^\n]*\).*?:\n(.*?)(?=^func |\Z)",
        source,
        re.MULTILINE | re.DOTALL,
    )
    if not match:
        raise ValueError(f"Missing function: {name}")
    return match.group(1)


def has_spawn(body: str, region: str, side: str, value: str) -> bool:
    return re.search(
        rf'if region_id == "{re.escape(region)}" and side == "{re.escape(side)}":'
        rf"\s*(?:#.*\n\s*)*return {re.escape(value)}(?:\s|$)",
        body,
    ) is not None


def main() -> int:
    errors: list[str] = []
    try:
        topology = json.loads(TOPOLOGY.read_text(encoding="utf-8"))
        source = REGION.read_text(encoding="utf-8")
        scene = A8_SCENE.read_text(encoding="utf-8")
        world_state = WORLD_STATE.read_text(encoding="utf-8")
        spawn_x = function_body(source, "_spawn_x_for_side")
        spawn_y = function_body(source, "_spawn_y_for_side")
        exits = function_body(source, "_spawn_region_exits")
        platforms = function_body(source, "_configure_platforms")
        encounters = function_body(source, "_spawn_region_encounters")
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"[FAIL] Could not load A8 contract inputs: {exc}")
        return 1

    edges = {edge.get("id"): edge for edge in topology.get("connections", [])}
    require(errors, 'region_id = "A8"' in scene and 'location_id = "royal_tomb"' in scene,
            "A8 scene must continue to bind the shared graybox to region A8 / royal_tomb.")

    # C13: elevated, bidirectional A7/A8 maintenance-shaft route.
    c13 = edges.get("C13", {})
    c13s = c13.get("spatial_contract", {})
    require(errors, c13.get("from") == "A7" and c13.get("to") == "A8"
            and c13.get("initial_access") == "both" and c13.get("final_direction") == "both",
            "C13 topology must remain bidirectional A7 <-> A8.")
    require(errors, c13s.get("to_region_spawn", {}).get("spawn_side") == "maintenance_shaft_entry"
            and c13s.get("to_region_spawn", {}).get("y_offset") == -120,
            "C13 A8 arrival must preserve the elevated maintenance_shaft_entry contract.")
    require(errors, has_spawn(spawn_x, "A8", "maintenance_shaft_entry", "190.0"),
            "C13 A8 arrival x must remain 190.")
    require(errors, has_spawn(spawn_y, "A8", "maintenance_shaft_entry", "floor_y - 120.0"),
            "C13 A8 arrival must remain 120px above the floor.")
    for marker in ('_add_platform(Rect2(2140, 460, 110, 18))',
                   '_add_platform(Rect2(2200, 420, 370, 18))'):
        require(errors, marker in platforms, f"C13 elevated approach is missing platform marker: {marker}")

    # C14: the ordinary A8/A9 main route must exist in both directions.
    c14 = edges.get("C14", {})
    require(errors, c14.get("from") == "A8" and c14.get("to") == "A9"
            and c14.get("initial_access") == "both" and c14.get("final_direction") == "both",
            "C14 topology must remain bidirectional A8 <-> A9.")
    require(errors, '"A8":' in exits and '"res://scenes/royal_outer_ring.tscn", "west"' in exits,
            "C14 must keep the A8 -> A9 transition wired.")
    require(errors, '"A9":' in exits and '"res://scenes/royal_tomb.tscn"' in exits,
            "C14 must keep the A9 -> A8 return transition wired.")

    # C15 and H06 must stay separate; static checks protect gate requirements, not physical reachability.
    c15 = edges.get("C15", {})
    require(errors, c15.get("from") == "A8" and c15.get("to") == "A11"
            and c15.get("initial_access") == "blocked" and c15.get("final_direction") == "both",
            "C15 must remain a blocked-by-default, conditionally bidirectional A8/A11 secret route.")
    a8_branch = source.split('"A8":', 1)[1].split('\n\t\t"', 1)[0] if '"A8":' in source else ""
    require(errors, 'secret_id = "C15"' in a8_branch or '"C15"' in a8_branch,
            "A8 region source must retain an explicit C15 gate binding.")
    for token in ("resonance", "55", "ancient_exposure", "anomaly_bell_retiming", "anomaly_erased_royal_name"):
        require(errors, token in source, f"C15 source contract is missing required gate token {token!r}.")
    require(errors, "H06" in source and "C15" in source,
            "H06 and C15 must both remain represented; do not collapse the distinct hidden route and gate.")

    # A8 combat is deliberately a map marker/placeholder at this stage, not a fabricated Boss implementation.
    require(errors, '"A8_Cultist_01"' in encounters,
            "A8 must retain its explicit placeholder encounter marker while the map is validated.")
    require(errors, "boss_defeated" in world_state and "mark_boss_defeated" in world_state,
            "WorldState's existing Boss completion state/API must not silently disappear.")
    require(errors, "func _spawn_hero" in source and "respawning" in source,
            "Shared graybox must retain the current-region Hero spawn/death-recovery path.")

    if errors:
        print("A8 SPATIAL/BOSS CONTRACT AUDIT FAILED")
        for error in errors:
            print(f" - {error}")
        return 1

    print("A8 SPATIAL/BOSS CONTRACT AUDIT: STATIC CHECKS PASSED")
    print(" - C13 elevated arrival and support-platform source markers checked.")
    print(" - C14 bidirectional topology and scene wiring checked.")
    print(" - C15 conditional gate tokens and H06 separation checked.")
    print(" - A8 encounter placeholder and existing WorldState Boss flags checked.")
    print(" - Runtime jump reachability, collision, door focus/range, death reset and return behavior remain unverified.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
