#!/usr/bin/env python3
"""Static wiring checks for the A2-A12 graybox and H01 hidden-well loop.

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
    "A5": ("scenes/old_battlefield.tscn", "old_battlefield", "THE BORDER BATTLEFIELD"),
    "A6": ("scenes/monastery_tower.tscn", "monastery_tower", "THE MONASTERY THAT KEPT ITS BELL"),
    "A7": ("scenes/prison_depths.tscn", "prison_depths", "THE PENITENTIAL DEPTHS"),
    "A8": ("scenes/royal_tomb.tscn", "royal_tomb", "THE ROYAL TOMB"),
    "A9": ("scenes/royal_outer_ring.tscn", "royal_outer_ring", "THE ROYAL OUTER RING"),
    "A10": ("scenes/grand_cathedral.tscn", "grand_cathedral", "THE GREAT CATHEDRAL"),
    "A12": ("scenes/inner_city.tscn", "inner_city", "THE INNER CITY"),
    "H07": ("scenes/mirror_street.tscn", "mirror_street", "MIRROR STREET: BEHIND THE RAIN"),
    "H01": ("scenes/hidden_well.tscn", "hidden_well", "THE WELL BELOW THE WELL"),
}

REQUIRED_FILES = [
    "scripts/levels/greybox_world_region.gd",
    "scripts/world/resonance_source_clue.gd",
    "scripts/world/resonance_secret_gate.gd",
    "scripts/world/interaction_door.gd",
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
        "ancient_exposure_floor: int = 0",
        "outer_exposure_floor: int = 0",
        "func discover_hidden_region(",
        "func open_hidden_path(",
        "func mark_hidden_region_entered(",
        "func is_hidden_path_opened(",
        'var exposure_target := 18 if "anomaly_observer_reaction" in resonance_sources else 12',
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
        'const RESONANCE_SECRET_GATE_SCRIPT = preload("res://scripts/world/resonance_secret_gate.gd")',
        "_spawn_a4_hidden_well_gate(map_width - 105.0)",
        'gate.secret_id = "H01"',
        'gate.secret_id = "H07"',
        'gate.required_resonance = 68',
        'gate.required_outer_exposure = 12',
        'gate.require_outer_god_resonance = true',
        'gate.required_source_ids = ["anomaly_mirror_street_echo"]',
        'opened_mirror_street_side_gate',
        'reached_A12_via_A10',
        'anomaly_mirror_street_echo',
        'royal_outer_ring',
        'grand_cathedral',
        'inner_city',
        'mirror_street',
        'gate.target_spawn_side = "east"',
        'gate.required_resonance = 12',
        'if "reached_A4_via_A3" in WorldState.achievement_flags:',
        '"A2"',
        '"A3"',
        '"A4"',
        '"H01"',
        '"anomaly_bell_retiming"',
        '"anomaly_old_pilgrim_echo"',
        '"anomaly_erased_street_sign"',
        '"anomaly_old_stone_layer"',
        '"anomaly_silent_bell_window"',
        '"anomaly_erased_royal_name"',
        'opened_sewer_inspection_hatch_from_A4',
        'unlock_once_flag_id: String = ""',
        'door.unlock_once_flag_id = unlock_once_flag_id',
        '"reached_A4_via_A3"',
        '"old_battlefield"',
        '"monastery_tower"',
        '"prison_depths"',
        '"royal_tomb"',
        'E  OPEN THE INSPECTION HATCH',
        'opened_sewer_inspection_hatch_from_A4',
        'SceneTransition.fade_to_scene(target_scene)',
        "clue.ancient_exposure_floor = ancient_floor",
    ]:
        require(region_script, contract, "Graybox region controller", errors)

    source_clue = read("scripts/world/resonance_source_clue.gd", errors)
    require(source_clue, "WorldState.record_resonance_milestone(", "Resonance source clue", errors)
    require(source_clue, "ancient_exposure_floor,", "Resonance source exposure floor", errors)
    require(source_clue, "outer_exposure_floor", "Resonance source exposure floor", errors)
    require(source_clue, "require_outer_god_resonance", "Resonance source story gate", errors)
    require(source_clue, 'KEY_E', "Resonance source clue", errors)
    require(source_clue, "INTERACTION_FOCUS_SCRIPT.is_focused(self)", "Resonance source clue", errors)

    interaction_door = read("scripts/world/interaction_door.gd", errors)
    for contract in [
        'unlock_once_flag_id: String = ""',
        'opened_prompt_text: String = ""',
        'WorldState.record_achievement(unlock_once_flag_id)',
        'prompt_text = opened_prompt_text',
    ]:
        require(interaction_door, contract, "One-time inspection hatch", errors)

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
        'target_spawn_side: String = "west"',
        "require_outer_god_resonance",
        "WorldState.pending_region_spawn_side = target_spawn_side",
        "match secret_id:",
        "func _draw_well_marker() -> void:",
        "func _draw_mirror_street_marker() -> void:",
        "func _draw_generic_anomaly_marker() -> void:",
    ]:
        require(secret_gate, contract, "Resonance hidden gate", errors)

    village_hub = read("scripts/levels/village_hub.gd", errors)
    require(village_hub, "_spawn_resonance_well_gate()", "Village hub", errors)
    require(village_hub, "resonance_well_gate.opened.connect(_on_resonance_well_opened)", "Village hub", errors)
    require(village_hub, 'resonance_well_gate.secret_id = "H01"', "Village hidden gate ID", errors)
    require(village_hub, 'resonance_well_gate.required_resonance = 12', "Village hidden gate threshold", errors)
    require(village_hub, 'resonance_well_gate.target_location_id = "hidden_well"', "Village hidden gate destination", errors)
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
    print(" - A2-A12 plus H01/H07 scenes have scripts and resume mappings.")
    print(" - The R01-R07 anomaly source chain is present.")
    print(" - H01 and H07 gates use saved discovery/open/entry state and progression conditions.")
    print("NOTE: Godot runtime/collision/input validation is still required.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
