#!/usr/bin/env python3
"""Static A1 village-state contract checks for Nereis Hero.

Run from the repository root:
    python3 tools/validate_a1_village_state_contracts.py

This is a source-contract check, not a replacement for a Godot runtime playthrough.
"""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(relative_path: str) -> str:
    path = ROOT / relative_path
    if not path.is_file():
        raise AssertionError(f"Required source file is missing: {relative_path}")
    return path.read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    village = read("scripts/levels/village_hub.gd")
    interior = read("scripts/levels/interior_scene.gd")
    world_state = read("scripts/core/world_state.gd")
    defense = read("scripts/levels/village_defense_demo.gd")

    defense_flag = '"village_defense_survived" in WorldState.achievement_flags'
    church_flag = '"church_village_occupied" in WorldState.achievement_flags'

    # The camp's world interaction and its visible structure must share the same milestone.
    require(defense_flag in village, "A1: camp POI is not gated by village-defense completion")
    require(
        'draw_rect(Rect2(1940, 360, 150, 160)' in village
        and 'NereisLocalization.translate_text("复国军营地")' in village
        and village.count(defense_flag) >= 2,
        "A1: camp visual and interaction must both be milestone-gated",
    )
    require(
        'WorldState.record_achievement("village_defense_survived")' in defense,
        "A1: village-defense completion no longer records the camp-unlock milestone",
    )
    require(
        '"achievement_flags": achievement_flags' in world_state,
        "A1: achievement flags are not serialized with save data",
    )

    # The church must remain empty before its explicit story occupation flag.
    require(church_flag in interior, "A1: church occupation flag is not referenced")
    require(
        'if location_id != "church" or "church_village_occupied" not in WorldState.achievement_flags:'
        in interior,
        "A1: NPC/clue/route-door/research-door spawning is not gated for the empty church",
    )
    require(
        'elif location_id == "church" and "church_village_occupied" not in WorldState.achievement_flags:'
        in interior,
        "A1: first-visit church intro does not reflect the empty state",
    )
    require(
        'church.display_name = "教堂"' in village
        and 'church.dialogue = "教堂大门紧闭着。' in village,
        "A1: village church exterior should be named and described as an empty church",
    )

    # Explicitly protect the user's deferred well and cliff-cave logic from A1 changes.
    require(
        'resonance_well_gate.secret_id = "H01"' in village
        and 'resonance_well_gate.target_scene_path = "res://scenes/hidden_well.tscn"' in village
        and "resonance_well_gate.required_resonance = 12" in village,
        "Protected route: the H01 well entrance contract changed",
    )
    require(
        '"returned_to_village_after_mad_cleric" not in WorldState.achievement_flags' in village
        and 'const CLIFF_CAVE_SCENE := "res://scenes/cliff_cave_experiment.tscn"' in village
        and "SceneTransition.fade_to_scene(CLIFF_CAVE_SCENE)" in village,
        "Protected route: the cliff-cave entry gate or destination changed",
    )
    require(
        'city_cut.poi_id = "city_cut"' in village
        and '"village_defense_survived" in WorldState.achievement_flags' in village
        and 'res://scenes/forgotten_city.tscn' in village,
        "Protected route: the existing old-drain route contract appears to have changed",
    )

    print("[PASS] A1 camp is hidden before defense and persists after the milestone")
    print("[PASS] A1 church remains empty until its explicit occupation flag")
    print("[PASS] H01 well, old-drain route, and cliff-cave entry contracts are present")
    print("A1 VILLAGE STATE CONTRACTS: PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as error:
        print(f"[FAIL] {error}", file=sys.stderr)
        raise SystemExit(1)
