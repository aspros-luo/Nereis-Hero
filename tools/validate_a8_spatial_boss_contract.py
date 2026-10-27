#!/usr/bin/env python3
"""Static source/data audit for A8 spatial routes and encounter/recovery boundaries.

This checks authored source markers only; it does not simulate Godot collision,
jump trajectories, Area2D focus, scene transitions, or death recovery.
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
A8_SCENE = ROOT / "scenes/regions/royal_tomb.tscn"
WORLD_STATE = ROOT / "scripts/core/world_state.gd"
DOOR = ROOT / "scripts/world/interaction_door.gd"


def require(errors: list[str], condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def function_body(source: str, name: str) -> str:
    pattern = rf"^func {re.escape(name)}\([^\n]*\).*?:\n(.*?)(?=^func |\Z)"
    match = re.search(pattern, source, re.MULTILINE | re.DOTALL)
    if match is None:
        raise ValueError(f"Missing function: {name}")
    return match.group(1)


def main() -> int:
    errors: list[str] = []
    try:
        topology = json.loads(TOPOLOGY.read_text(encoding="utf-8"))
        source = REGION.read_text(encoding="utf-8")
        scene = A8_SCENE.read_text(encoding="utf-8")
        world_state = WORLD_STATE.read_text(encoding="utf-8")
        door = DOOR.read_text(encoding="utf-8")
        spawn_x = function_body(source, "_spawn_x_for_side")
        spawn_y = function_body(source, "_spawn_y_for_side")
        exits = function_body(source, "_spawn_region_exits")
        platforms = function_body(source, "_configure_platforms")
        encounters = function_body(source, "_spawn_region_encounters")
        hero_spawn = function_body(source, "_spawn_hero")
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"A8 SPATIAL/RECOVERY AUDIT FAILED TO LOAD INPUTS: {exc}")
        return 1

    edges = {edge.get("id"): edge for edge in topology.get("connections", [])}
    require(errors, 'region_id = "A8"' in scene and 'location_id = "royal_tomb"' in scene,
            "A8 scene must bind the shared graybox to region A8 / royal_tomb.")
    require(errors, "map_width = 2600.0" in scene,
            "A8 scene width must remain 2600px unless the route contract is revised.")

    # C13: source-level match between A8 arrival, A7 return, and authored support ledges.
    c13 = edges.get("C13", {})
    c13s = c13.get("spatial_contract", {})
    require(errors, (c13.get("from"), c13.get("to"), c13.get("initial_access"), c13.get("final_direction"))
            == ("A7", "A8", "both", "both"),
            "C13 topology must remain bidirectional A7 <-> A8.")
    require(errors, c13s.get("to_region_spawn", {}).get("spawn_side") == "maintenance_shaft_entry"
            and c13s.get("to_region_spawn", {}).get("y_offset") == -120,
            "C13 A8 arrival must retain its elevated maintenance_shaft_entry contract.")
    require(errors, 'if region_id == "A8" and side == "maintenance_shaft_entry":' in spawn_x
            and "return 190.0" in spawn_x,
            "C13 A8 arrival x must remain 190.")
    require(errors, 'if region_id == "A8" and side == "maintenance_shaft_entry":' in spawn_y
            and "return floor_y - 120.0" in spawn_y,
            "C13 A8 arrival must remain 120px above the floor.")
    for marker in ("_add_platform(Rect2(80, 420, 150, 18))",
                   "_add_platform(Rect2(240, 420, 170, 18))"):
        require(errors, marker in platforms,
                f"C13 A8 arrival support ledge is missing: {marker}")
    require(errors, 'if region_id == "A7" and side == "maintenance_shaft_return":' in spawn_x
            and "return map_width - 160.0" in spawn_x,
            "C13 return spawn must stay on A7's east-side upper ledge.")
    require(errors, 'if region_id == "A7" and side == "maintenance_shaft_return":' in spawn_y
            and "return floor_y - 120.0" in spawn_y,
            "C13 return spawn must stay at floor_y - 120.")

    # C14: topology and scene transition wiring must agree in both directions.
    c14 = edges.get("C14", {})
    require(errors, (c14.get("from"), c14.get("to"), c14.get("initial_access"), c14.get("final_direction"))
            == ("A8", "A9", "both", "both"),
            "C14 topology must remain bidirectional A8 <-> A9.")
    require(errors, '"A8":' in exits and '"res://scenes/regions/royal_outer_ring.tscn", "west"' in exits,
            "C14 A8 -> A9 transition wiring is missing.")
    require(errors, '"A9":' in exits and '"res://scenes/regions/royal_tomb.tscn"' in exits,
            "C14 A9 -> A8 return wiring is missing.")

    # C15 is distinct from H06 and C19; source checks are not a reachability proof.
    c15 = edges.get("C15", {})
    require(errors, (c15.get("from"), c15.get("to"), c15.get("initial_access"), c15.get("final_direction"))
            == ("A8", "A11", "blocked", "both"),
            "C15 must remain a conditionally bidirectional A8/A11 route.")
    for marker in ('gate.secret_id = "C15"', "gate.required_resonance = 55",
                   "gate.required_ancient_exposure = 2",
                   '["anomaly_bell_retiming", "anomaly_erased_royal_name"]'):
        require(errors, marker in source, f"C15 gate binding/requirements missing: {marker}")
    require(errors, "H06" in source and "royal_name_gate" in source,
            "H06 must remain a separate royal-name route, not merged into C15.")

    # Door interaction is an Area2D + shared focus contract; physical range needs runtime testing.
    for marker in ("extends Area2D", "body_entered.connect(_on_body_entered)",
                   "body_exited.connect(_on_body_exited)", "INTERACTION_FOCUS_SCRIPT.is_focused(self)",
                   "event.keycode == KEY_E"):
        require(errors, marker in door, f"Door interaction contract marker missing: {marker}")
    require(errors, "func _create_floor()" in source
            and "rectangle.size = Vector2(map_width, 40.0)" in source,
            "Shared continuous floor was not found; ground-bypass review must be revisited.")
    require(errors, "shape.one_way_collision = true" in source,
            "Platform one-way collision setup is missing.")

    # Map-phase combat/recovery boundary: retain placeholder encounter and existing checkpoint path.
    require(errors, '"A8_Cultist_01"' in encounters,
            "A8's existing ordinary placeholder encounter marker is missing.")
    require(errors, "WorldState.set_checkpoint(hero.global_position)" in hero_spawn,
            "Hero spawn must initialize a region checkpoint.")
    require(errors, "func _on_hero_defeated" in source and "respawning" in source,
            "Shared Hero death/recovery handler markers are missing.")
    require(errors, "var boss_defeated := false" in world_state
            and "func mark_boss_defeated()" in world_state,
            "Existing global Boss state API was not found; do not infer an A8 Boss implementation from it.")

    if errors:
        print("A8 SPATIAL/RECOVERY SOURCE AUDIT FAILED")
        for error in errors:
            print(f" - {error}")
        return 1

    print("A8 SPATIAL/RECOVERY SOURCE AUDIT PASSED")
    print(" - A8 scene binding, C13 elevated spawn/support ledges, and C14 two-way wiring checked.")
    print(" - C15 gate requirements, H06 separation, door focus source markers, and platform setup checked.")
    print(" - Existing placeholder encounter and checkpoint/death-handler markers checked.")
    print("LIMITATION: interaction radius, jump reachability, collision, ground bypass, death/reload and return behavior are NOT runtime-verified.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
