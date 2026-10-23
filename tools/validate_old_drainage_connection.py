#!/usr/bin/env python3
"""Static contract checks for the phased A1/A3/A4 old-drain exploration route.

Run from the repository root:
    python3 tools/validate_old_drainage_connection.py

This checks source contracts only; it does not replace Godot parser or runtime acceptance.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    file_path = ROOT / path
    if not file_path.is_file():
        raise AssertionError(f"Missing required file: {path}")
    return file_path.read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    village = read("scripts/levels/village_hub.gd")
    backhill = read("scripts/levels/village_backhill.gd")
    region = read("scripts/levels/greybox_world_region.gd")
    drain = read("scripts/levels/old_drain_exploration.gd")
    rat = read("scripts/enemies/sewer_rat.gd")
    scene = read("scenes/old_drain_exploration.tscn")
    topology = json.loads(read("tools/world_map_topology.json"))

    require(
        'WorldState.pending_region_spawn_side = "village_entry"' in village
        and 'SceneTransition.fade_to_scene("res://scenes/old_drain_exploration.tscn")' in village,
        "A1 must enter the new drain-exploration scene after the defense milestone.",
    )
    require(
        'if "village_defense_survived" in WorldState.achievement_flags:' in village,
        "The A1 drain entrance must remain gated by village-defense completion.",
    )
    require(
        'CONNECTION_FLAG := "opened_old_drainage_link_from_A4"' in drain
        and '_spawn_door(2260.0, 690.0, "E  沿旧排水道进入城区", _enter_city)' in drain
        and '_spawn_door(2260.0, 690.0, "E  检查被堵住的闸门", _inspect_blocked_gate)' in drain
        and 'func _add_gate_blocker() -> void:' in drain
        and 'if CONNECTION_FLAG not in WorldState.achievement_flags:' in drain,
        "The eastern gate must have a real collider until the persistent A4-side unlock flag exists.",
    )
    require(
        '_spawn_rat(900.0)' in drain and '_spawn_rat(1100.0)' in drain
        and "const MOVE_SPEED := 72.0" in rat and "attack_hitbox.activate(6, 0.12)" in rat,
        "The exploration segment must contain a small number of low-threat sewer rats.",
    )
    require(
        '"city_side_entry":' in drain and '"reservoir_link":' in drain
        and '"old_drain_link"' in drain,
        "The A3/A4 return spawns must be explicitly routed.",
    )
    require(
        'if "opened_old_drainage_link_from_A4" in WorldState.achievement_flags:' in region
        and '"res://scenes/old_drain_exploration.tscn", "city_side_entry"' in region
        and '"res://scenes/old_drain_exploration.tscn", "reservoir_link"' in region,
        "C24/A4 must link through the exploration segment only after the A4-side gate is opened.",
    )
    require(
        'if region_id == "A4" and side == "old_drain_link":' in region
        and 'return 820.0' in region,
        "The return from the drain gate must land away from A4 door triggers.",
    )
    c24 = next(edge for edge in topology["connections"] if edge.get("id") == "C24")
    require(
        c24.get("from") == "A1" and c24.get("to") == "A3"
        and "A4 侧闸门开启后才与 A3 连通" in c24["layer_contract"]["readability_contract"],
        "Topology must preserve C24 as the eventual A1-A3 shortcut and document phased access.",
    )
    require(
        'resonance_well_gate.secret_id = "H01"' in village
        and 'resonance_well_gate.target_scene_path = "res://scenes/hidden_well.tscn"' in village
        and 'const CLIFF_CAVE_SCENE := "res://scenes/cliff_cave_experiment.tscn"' in backhill
        and 'var cave_unlocked := "returned_to_village_after_mad_cleric" in WorldState.achievement_flags' in backhill
        and 'WorldState.discover_hidden_region("H09")' in backhill
        and 'WorldState.open_hidden_path("H09")' in backhill,
        "Protected H01 well or H09 cliff-cave entry contract changed unexpectedly.",
    )
    require('[node name="OldDrainExploration" type="Node2D"]' in scene, "Drain scene root is missing.")

    print("[PASS] A1 entrance remains gated and now enters the exploration segment")
    print("[PASS] Descent, two low-threat rats, blocked gate, and persistent A4-side unlock are present")
    print("[PASS] C24/A4 connections use the shared segment and explicit safe return spawns")
    print("[PASS] H01 well and cliff-cave contracts remain unchanged")
    print("OLD DRAIN CONNECTION CONTRACTS: PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, KeyError, StopIteration, json.JSONDecodeError) as error:
        print(f"[FAIL] {error}", file=sys.stderr)
        raise SystemExit(1)
