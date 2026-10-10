#!/usr/bin/env python3
"""Static wiring checks for the A2-A4 graybox and H01 hidden-well loop.

This script checks file references and save/transition contracts. It does not
replace Godot runtime tests for collision, interaction focus, or scene changes.
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REGIONS = {
    "A2": ("scenes/ash_forest.tscn", "ash_forest", "THE OLD PILGRIM ROAD"),
    "A3": ("scenes/forgotten_city.tscn", "forgotten_city", "THE FORGOTTEN CITY"),
    "A4": ("scenes/sewer_reservoir.tscn", "sewer_reservoir", "THE SEDIMENT HALL"),
    "H01": ("scenes/hidden_well.tscn", "hidden_well", "THE WELL BELOW THE WELL"),
}

REQUIRED_FILES = [
    "scripts/levels/greybox_world_region.gd",
    "scripts/world/resonance_source_clue.gd",
    "scripts/world/resonance_secret_gate.gd",
    "scripts/levels/village_hub.gd",
    "scripts/levels/village_defense_demo.gd",
    "scripts/core/world_state.gd",
]


def read(relative_path: str, errors: list[str]) -> str:
    path = ROOT / relative_path
    if not path.is_file():
        errors.append(f"Missing file: {relative_path}")
        return ""
    return path.read_text(encoding="utf-8")


def require(text: str, needle: str, source: str, errors: list[str]) -> None:
    if needle not in text:
        errors.append(f"{source}: missing required contract {needle!r}")


def main() -> int:
    errors: list[str] = []

    for relative_path in REQUIRED_FILES:
        read(relative_path, errors)

    world_state = read("scripts/core/world_state.gd", errors)
    for method in [
        "func record_resonance_milestone(",
        "func discover_hidden_region(",
        "func open_hidden_path(",
        "func mark_hidden_region_entered(",
        "func is_hidden_path_opened(",
        '"discovered_hidden_regions": discovered_hidden_regions',
        '"opened_hidden_paths": opened_hidden_paths',
        '"entered_hidden_regions": entered_hidden_regions',
    ]:
        require(world_state, method, "WorldState", errors)

    for _region_id, (scene_path, location_id, title) in REGIONS.items():
        scene = read(scene_path, errors)
        require(scene, 'path="res://scripts/levels/greybox_world_region.gd"', scene_path, errors)
        require(scene, f'region_id = "{_region_id}"', scene_path, errors)
        require(scene, f'location_id = "{location_id}"', scene_path, errors)
        require(scene, f'region_title = "{title}"', scene_path, errors)
        require(world_state, f'"{location_id}":', "WorldState resume mapping", errors)
        require(world_state, f'res://{scene_path}', "WorldState resume mapping", errors)

    region_script = read("scripts/levels/greybox_world_region.gd", errors)
    for contract in [
        '"A2"',
        '"A3"',
        '"A4"',
        '"H01"',
        '"anomaly_bell_retiming"',
        '"anomaly_old_pilgrim_echo"',
        '"anomaly_erased_street_sign"',
        '"anomaly_old_stone_layer"',
        '"reached_A4_via_A3"',
        'WorldState.record_resonance_milestone(',
        'SceneTransition.fade_to_scene(target_scene)',
    ]:
        require(region_script, contract, "Graybox region controller", errors)

    source_clue = read("scripts/world/resonance_source_clue.gd", errors)
    require(source_clue, "WorldState.record_resonance_milestone(", "Resonance source clue", errors)
    require(source_clue, 'KEY_E', "Resonance source clue", errors)
    require(source_clue, "INTERACTION_FOCUS_SCRIPT.is_focused(self)", "Resonance source clue", errors)

    secret_gate = read("scripts/world/resonance_secret_gate.gd", errors)
    for contract in [
        'add_to_group("resonance_hidden_targets")',
        "WorldState.is_hidden_path_opened(secret_id)",
        "WorldState.discover_hidden_region(secret_id)",
        "WorldState.open_hidden_path(secret_id)",
        "WorldState.mark_hidden_region_entered(secret_id)",
        "WorldState.resonance_sight_active",
        "KEY_E",
        "SceneTransition.fade_to_scene(target_scene_path)",
    ]:
        require(secret_gate, contract, "Resonance hidden gate", errors)

    village_hub = read("scripts/levels/village_hub.gd", errors)
    require(village_hub, "_spawn_resonance_well_gate()", "Village hub", errors)
    require(village_hub, "resonance_well_gate.opened.connect(_on_resonance_well_opened)", "Village hub", errors)
    require(village_hub, '"village_defense_survived"', "Village old-road unlock", errors)
    require(village_hub, 'res://scenes/ash_forest.tscn', "Village old-road route", errors)

    defense = read("scripts/levels/village_defense_demo.gd", errors)
    require(defense, 'WorldState.record_achievement("village_defense_survived")', "Village defense", errors)

    if errors:
        print("GRAYBOX SCENE WIRING CHECK FAILED")
        for error in errors:
            print(f" - {error}")
        return 1

    print("GRAYBOX SCENE WIRING STATIC CHECK PASSED")
    print(" - A2, A3, A4 and H01 scenes have scripts and resume mappings.")
    print(" - The R01-R04 anomaly source chain is present.")
    print(" - The hidden-well gate is connected to the saved discovery/open/entry states.")
    print("NOTE: Godot runtime/collision/input validation is still required.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
