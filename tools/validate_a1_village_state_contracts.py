#!/usr/bin/env python3
"""Static A1 state contracts for the story-map workstream.

Run from the repository root:
    python3 tools/validate_a1_village_state_contracts.py

This is a source-contract check, not a replacement for Godot runtime acceptance.
"""
from __future__ import annotations

import json
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
    topology = json.loads(read("tools/world_map_topology.json"))

    # The church remains a quiet exploration space until an explicit story milestone.
    require(
        'var church_occupied := "church_village_occupied" in WorldState.achievement_flags' in interior,
        "A1: church occupancy must be controlled by the explicit story flag.",
    )
    require(
        'if location_id != "church" or church_occupied:' in interior
        and '_spawn_npc()' in interior
        and '_spawn_clue()' in interior
        and '_spawn_route_door()' in interior
        and '_spawn_research_door()' in interior,
        "A1: NPC, clue, route-door and research-door spawning must share the church occupancy gate.",
    )
    require(
        'if location_id == "church" and "church_village_occupied" not in WorldState.achievement_flags:' in interior
        and "这里要等到后续剧情节点才会有人到来。" in interior,
        "A1: empty-church intro must explain the current state without exposing later content.",
    )
    require(
        'church.display_name = "教堂"' in village
        and 'church.dialogue = "教堂的大门没有上锁。' in village,
        "A1: village church exterior should remain an explorable empty church.",
    )

    # Keep the actual map-branch drain transition, rather than the stale direct A3 transition.
    require(
        'city_cut.poi_id = "city_cut"' in village
        and 'city_cut.set_meta("p5_1_target_scene", "res://scenes/old_drain_exploration.tscn")' in village
        and 'WorldState.set_location("old_drain_exploration")' in village
        and 'SceneTransition.fade_to_scene("res://scenes/old_drain_exploration.tscn")' in village,
        "A1: city_cut must enter the phased old-drain exploration scene.",
    )
    require(
        'WorldState.record_achievement("village_defense_survived")' in defense
        and '"achievement_flags": achievement_flags' in world_state,
        "A1: village-defense milestone must be recorded and serialized.",
    )

    # Protect already established optional routes from unrelated A1 changes.
    require(
        'resonance_well_gate.secret_id = "H01"' in village
        and 'resonance_well_gate.target_scene_path = "res://scenes/hidden_well.tscn"' in village
        and "resonance_well_gate.required_resonance = 12" in village,
        "Protected route: H01 well entrance contract changed.",
    )
    require(
        '"returned_to_village_after_mad_cleric" not in WorldState.achievement_flags' in village
        and 'const CLIFF_CAVE_SCENE := "res://scenes/cliff_cave_experiment.tscn"' in village
        and "SceneTransition.fade_to_scene(CLIFF_CAVE_SCENE)" in village,
        "Protected route: cliff-cave gate or destination changed.",
    )

    c24 = next(edge for edge in topology["connections"] if edge.get("id") == "C24")
    require(
        c24.get("from") == "A1"
        and c24.get("to") == "A3"
        and c24.get("unlock_condition") == "village_defense_survived",
        "Topology: C24 must preserve the existing A1/A3 route identity and defense gate.",
    )

    print("[PASS] Church NPC/clue/route/research content remains gated until occupation")
    print("[PASS] A1 old-drain entrance targets the phased exploration scene")
    print("[PASS] Village-defense milestone, H01 well, cliff cave and C24 contracts are preserved")
    print("A1 VILLAGE STATE CONTRACTS: PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, KeyError, StopIteration, json.JSONDecodeError) as error:
        print(f"[FAIL] {error}", file=sys.stderr)
        raise SystemExit(1)
