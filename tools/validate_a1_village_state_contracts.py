#!/usr/bin/env python3
"""A1 story flags, routes and scene-authored state contracts.

Run from the repository root:
    python3 tools/validate_a1_village_state_contracts.py

This validates source contracts only. Godot runtime testing is still required.
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
    village_scene = read("scenes/village_hub.tscn")
    backhill = read("scripts/levels/village_backhill.gd")
    backhill_scene = read("scenes/village_backhill.tscn")
    cliff = read("scripts/levels/cliff_exploration.gd")
    cliff_scene = read("scenes/cliff_exploration.tscn")
    interior = read("scripts/levels/interior_scene.gd")
    world_state = read("scripts/core/world_state.gd")
    defense = read("scripts/levels/village_defense_demo.gd")
    director = read("scripts/core/world_event_director.gd")
    world_region = read("scripts/levels/greybox_world_region.gd")
    topology = json.loads(read("tools/world_map_topology.json"))

    # The church remains a quiet exploration space until its explicit story flag.
    require(
        'var church_occupied := "church_village_occupied" in WorldState.achievement_flags' in interior,
        "A1: church occupancy must use its explicit story flag.",
    )
    require(
        'if location_id != "church" or church_occupied:' in interior
        and "_spawn_npc()" in interior
        and "_spawn_clue()" in interior
        and "_spawn_route_door()" in interior
        and "_spawn_research_door()" in interior,
        "A1: church NPC/clue/route/research content must share the occupancy gate.",
    )
    require(
        'if location_id == "church" and "church_village_occupied" not in WorldState.achievement_flags:' in interior
        and "这里要等到后续剧情节点才会有人到来。" in interior,
        "A1: empty-church intro must not expose later-stage content.",
    )

    # Permanent village objects are authored in .tscn; story flags only change their state.
    require(
        all(f'[node name="{name}" type="Node2D" parent="."]' in village_scene for name in [
            "CampVisual", "NorthGateVisual", "DrainEntranceVisual", "ResonanceWellGate"
        ]),
        "A1: camp, gate, drainage entrance and H01 visuals must remain in the scene tree.",
    )
    require(
        '$CampVisual.visible = camp_established' in village
        and '$CampLabel.visible = camp_established' in village
        and '$RestorationCampPOI.visible = camp_established' in village
        and 'var camp_established := "restoration_camp_established" in WorldState.achievement_flags' in village,
        "A1: Restoration Army camp must use its own explicit arrival flag.",
    )
    require(
        '$NorthGateVisual/BlockedState.visible = not defense_survived' in village
        and '$NorthGateVisual/RepairedState.visible = defense_survived' in village
        and '$DrainEntranceVisual/RubbleState.visible = not defense_survived' in village,
        "A1: the defense milestone must switch authored blocked/repaired/rubble states.",
    )
    require(
        'WorldState.record_achievement("village_defense_survived")' in defense
        and '"achievement_flags": achievement_flags' in world_state,
        "A1: village-defense milestone must remain persisted.",
    )

    # Keep the phased drainage route: the defense milestone opens its short segment,
    # while the final A1/A3 shortcut remains locked until the A4-side gate opens.
    require(
        '[node name="CityCutPOI" type="Node2D" parent="."]' in village_scene
        and 'var city_cut: Node2D = $CityCutPOI' in village
        and 'city_cut.set_meta("p5_1_target_scene", "res://scenes/old_drain_exploration.tscn")' in village
        and 'elif location_id == "city_cut":' in village
        and 'WorldState.set_location("old_drain_exploration")' in village
        and 'SceneTransition.fade_to_scene("res://scenes/old_drain_exploration.tscn")' in village,
        "A1: the authored CityCut POI must enter the phased drainage segment after defense.",
    )
    c24 = next(edge for edge in topology["connections"] if edge.get("id") == "C24")
    require(
        c24.get("from") == "A1"
        and c24.get("to") == "A3"
        and c24.get("unlock_condition") == "village_defense_survived"
        and "opened_old_drainage_link_from_A4" in c24["spatial_contract"]["intermediate_scene"]["a3_link_unlock_flag"],
        "Topology: preserve C24 route identity and its later A4-side unlock.",
    )

    # H01 is represented by authored nodes; the gate script only drives the state and transition.
    require(
        'var resonance_well_gate: Node2D' in village
        and 'resonance_well_gate = $ResonanceWellGate' in village
        and 'resonance_well_gate.secret_id = "H01"' in village
        and 'resonance_well_gate.target_scene_path = "res://scenes/hidden_well.tscn"' in village
        and 'resonance_well_gate.required_resonance = 12' in village,
        "Protected route: H01 identity, threshold or target scene changed.",
    )
    require(
        '[node name="AuthoredVisual" type="Node2D" parent="ResonanceWellGate"]' in village_scene
        and '[node name="RevealedState" type="Node2D" parent="ResonanceWellGate/AuthoredVisual"]' in village_scene
        and '[node name="OpenedState" type="Node2D" parent="ResonanceWellGate/AuthoredVisual"]' in village_scene
        and 'if secret_id == "H01" and has_node("AuthoredVisual"):' in read("scripts/world/resonance_secret_gate.gd"),
        "H01 visuals must be authored nodes and not drawn from the shared gate script.",
    )

    # H09 remains gated by defeating the mad cleric and physically returning to A1, now inside the separate cliff scene.
    require(
        'var h09_unlocked := "returned_to_village_after_mad_cleric" in WorldState.achievement_flags' in cliff
        and '$H09CaveVisual.visible = h09_unlocked' in cliff
        and 'const CLIFF_CAVE_SCENE := "res://scenes/cliff_cave_experiment.tscn"' in cliff
        and 'WorldState.discover_hidden_region("H09")' in cliff
        and 'WorldState.open_hidden_path("H09")' in cliff
        and 'SceneTransition.fade_to_scene(CLIFF_CAVE_SCENE)' in cliff
        and '[node name="H09CaveDoor" type="Area2D" parent="."]' in cliff_scene,
        "A1.1: H09 must stay gated by physical return and live in the separate cliff scene.",
    )
    require(
        'WorldState.record_achievement("defeated_mad_cleric")' in world_region
        and "村庄的山崖似乎回应了这声低鸣。" not in world_region,
        "A6: defeating the boss must not replace the return-to-village unlock with exposition.",
    )

    # Four baseline villagers are scene-authored; dialogue derives from persisted state and can refresh.
    require(
        all(f'[node name="{name}" type="Node2D" parent="."]' in village_scene for name in [
            "Gatekeeper", "Grandmother", "BlacksmithNPC", "TravelingMerchant"
        ])
        and village_scene.count('groups = ["a1_baseline_npcs"]') == 4
        and 'func _configure_baseline_npcs() -> void:' in village
        and 'for npc in get_tree().get_nodes_in_group("a1_baseline_npcs"):' in village
        and '_refresh_baseline_npc_dialogue(npc)' in village,
        "A1: baseline NPCs must be scene-authored and refresh dialogue from current state.",
    )
    require(
        'match String(npc.npc_id):' in village
        and '"graybox_intro_forgotten_city" in WorldState.achievement_flags' in village
        and '"graybox_intro_ash_forest" in WorldState.achievement_flags' in village
        and village.index('"graybox_intro_forgotten_city" in WorldState.achievement_flags')
            < village.index('"graybox_intro_ash_forest" in WorldState.achievement_flags')
        and 'elif "village_defense_survived" in WorldState.achievement_flags:' in village,
        "A1: merchant dialogue must prioritize actual A3/A2 visits before generic defense feedback.",
    )

    # The one-time tavern sound event is attached to the A1.1 scene that actually owns the tavern POI.
    require(
        '"id": "A1_tavern_sound_notice"' in director
        and '"trigger": "interaction"' in director
        and '"interaction_id": "tavern"' in director
        and '"once": true' in director
        and '{"type": "flag_absent", "value": "A1_tavern_sound_noticed"}' in director
        and '{"type": "add_flag", "value": "A1_tavern_sound_noticed"}' in director,
        "A1: tavern sound must remain a one-time event guarded by the missing fact.",
    )
    require(
        '[node name="WorldEventDirector" type="Node" parent="."]' in backhill_scene
        and 'groups = ["a1_tavern_poi"]' in backhill_scene
        and 'world_event_director.dispatch("region_entered", {"region": "A1", "location": "village_backhill"})' in backhill
        and 'world_event_director.dispatch("interaction", {"region": "A1", "interaction_id": String(poi.poi_id)' in backhill
        and '"A1_tavern_sound_noticed" in WorldState.achievement_flags' in backhill,
        "A1.1: tavern one-time event must dispatch from the actual scene-owned Tavern POI.",
    )
    require(
        'if "A1_tavern_sound_noticed" in WorldState.achievement_flags:' in backhill
        and "你再次靠近酒馆。门内没有歌声" in backhill
        and 'func _refresh_tavern_poi_dialogue() -> void:' in backhill,
        "A1.1: tavern repeat interaction must react to the persisted sound-noticed flag.",
    )
    require(
        'func _apply_effects(effects: Array) -> void:' in director
        and '_world_state.save_game()' in director[director.index('func _apply_effects(effects: Array) -> void:'):],
        "A1: event effects must persist their story flags.",
    )

    # Preserve the phased-route and scene-bound manager contracts.
    require(
        '$WorldEventDirector' in village
        and '$NarrativeAudio' in village
        and '$VillageFireflies' in village
        and '[node name="VillageFireflies" parent="." instance=ExtResource("19")]' in village_scene,
        "A1.0 managers and fireflies should be scene-authored, not manually constructed.",
    )
    require(
        '"achievement_flags": achievement_flags' in world_state,
        "WorldState must serialize achievement flags.",
    )

    print("[PASS] Church occupancy and interior content remain explicitly gated")
    print("[PASS] Camp, north gate, drain and H01 use scene-authored visuals with flag-driven states")
    print("[PASS] A1/A1.1 transitions, H09 return unlock, C24 and H01 contracts are preserved")
    print("[PASS] Baseline NPCs, tavern event, event persistence and managers are scene-bound")
    print("A1 VILLAGE STATE CONTRACTS: PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, KeyError, StopIteration, json.JSONDecodeError) as error:
        print(f"[FAIL] {error}", file=sys.stderr)
        raise SystemExit(1)
