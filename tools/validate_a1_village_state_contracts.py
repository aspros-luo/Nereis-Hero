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

    # Camp arrival is a separate, explicitly confirmed later story fact.
    # Never infer the Restoration Army's arrival from surviving the village defense.
    camp_poi_start = village.find('if "restoration_camp_established" in WorldState.achievement_flags:')
    camp_poi_end = village.find('var north_gate := Node2D.new()', camp_poi_start)
    camp_visual_start = village.find('# Hide the camp\'s distinctive fire and label')
    camp_visual_end = village.find('draw_rect(Rect2(2780, 330, 120, 190)', camp_visual_start)
    require(
        camp_poi_start >= 0
        and camp_poi_end > camp_poi_start
        and 'rebel_camp.poi_id = "rebel_camp"' in village[camp_poi_start:camp_poi_end]
        and 'if "village_defense_survived" in WorldState.achievement_flags' not in village[camp_poi_start:camp_poi_end],
        "A1: Restoration Army camp POI must use its own explicit arrival flag, not the defense milestone.",
    )
    require(
        camp_visual_start >= 0
        and camp_visual_end > camp_visual_start
        and 'if "restoration_camp_established" in WorldState.achievement_flags:' in village[camp_visual_start:camp_visual_end],
        "A1: camp fire/label visuals must share the explicit camp-arrival gate.",
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

    # The cliff-cave consequence requires a real return to A1 after the boss defeat.
    require(
        'if "defeated_mad_cleric" in WorldState.achievement_flags:' in village
        and 'WorldState.record_achievement("returned_to_village_after_mad_cleric")' in village
        and 'if "returned_to_village_after_mad_cleric" not in WorldState.achievement_flags:' in village,
        "A1: cliff-cave unlock must be recorded on physical return after defeating the mad cleric.",
    )
    require(
        'WorldState.record_achievement("defeated_mad_cleric")' in read("scripts/levels/greybox_world_region.gd")
        and '村庄的山崖似乎回应了这声低鸣。' not in read("scripts/levels/greybox_world_region.gd"),
        "A6: mad-cleric defeat must not force an explanatory exposition panel.",
    )

    # Merchant route feedback must depend on actual scene-entry facts, not unlocked exits.
    require(
        '"graybox_intro_forgotten_city" in WorldState.achievement_flags' in village
        and '"graybox_intro_ash_forest" in WorldState.achievement_flags' in village
        and village.index('"graybox_intro_forgotten_city" in WorldState.achievement_flags')
            < village.index('"graybox_intro_ash_forest" in WorldState.achievement_flags')
        and 'elif "village_defense_survived" in WorldState.achievement_flags:' in village,
        "A1: merchant revisit dialogue must prioritize actual A3/A2 exploration facts before generic defense feedback.",
    )

    # The pilgrim knight is manifest-managed in exactly one interior selected by explicit story facts.
    require(
        director.count('"id": "pilgrim_knight_a1"') == 2
        and '"value": "pilgrim_knight_a1_arrived"' in director
        and '"value": "pilgrim_knight_at_tavern"' in director
        and '{"type": "location", "value": "tavern"}' in director
        and '{"type": "location", "value": "church"}' in director
        and '"dialogue_variants"' in director,
        "A1: pilgrim knight must be manifest-managed, arrival-gated, and assigned to only one interior by the location flag.",
    )
    require(
        'const WORLD_EVENT_DIRECTOR_SCRIPT = preload("res://scripts/core/world_event_director.gd")' in interior
        and 'world_event_director.setup(WorldState, self)' in interior
        and 'world_event_director.spawn_npcs(self, ROUTE_NPC_SCRIPT, Callable(self, "_on_npc_interacted"))' in interior
        and 'var pilgrim_arrived :=' not in interior,
        "A1: interior progression NPCs must spawn through the director rather than duplicate hand-written branches.",
    )

    # The tavern sound event is a one-time, persisted world fact; dialogue is resolved on re-entry.
    director = read("scripts/core/world_event_director.gd")
    require(
        '"id": "A1_tavern_sound_notice"' in director
        and '"trigger": "interaction"' in director
        and '"interaction_id": "tavern"' in director
        and '"once": true' in director
        and '{"type": "flag_absent", "value": "A1_tavern_sound_noticed"}' in director
        and '{"type": "add_flag", "value": "A1_tavern_sound_noticed"}' in director,
        "A1: tavern sound notice must be an idempotent one-time event gated by the missing fact.",
    )
    require(
        'world_event_director.dispatch("interaction", {"region": "A1", "interaction_id": String(poi.poi_id)' in village
        and 'world_event_director.dispatch("region_entered", {"region": "A1", "location": "village"' in village
        and 'if "A1_tavern_sound_noticed" in WorldState.achievement_flags' in interior,
        "A1: tavern notice must dispatch from the real POI interaction and resolve the follow-up on interior re-entry.",
    )
    require(
        'func _apply_effects(effects: Array)' in director
        and '_world_state.save_game()' in director
        and 'func _mark_fired(event_id: String)' in director
        and '_world_state.save_game()' in director[director.find('func _mark_fired(event_id: String)'):],
        "A1: one-time event effects and fired markers must persist across scene changes and Continue.",
    )

    # Baseline villagers must recalculate dialogue from current facts, not only at scene creation.
    require(
        'npc.add_to_group("a1_baseline_npcs")' in village
        and 'grandmother.add_to_group("a1_baseline_npcs")' in village
        and 'blacksmith.add_to_group("a1_baseline_npcs")' in village
        and 'merchant.add_to_group("a1_baseline_npcs")' in village
        and 'for npc in get_tree().get_nodes_in_group("a1_baseline_npcs"):' in village
        and '_refresh_baseline_npc_dialogue(npc)' in village,
        "A1: gatekeeper, grandmother, blacksmith and merchant dialogue must refresh from current world facts.",
    )
    require(
        'func _refresh_baseline_npc_dialogue(npc: Node)' in village
        and '"graybox_intro_forgotten_city" in WorldState.achievement_flags' in village
        and '"graybox_intro_ash_forest" in WorldState.achievement_flags' in village,
        "A1: refreshed merchant dialogue must preserve actual A3/A2 exploration priority.",
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
    print("[PASS] Restoration Army camp appearance is gated by its own later-story flag")
    print("[PASS] Village-defense milestone, H01 well, cliff cave and C24 contracts are preserved")
    print("A1 VILLAGE STATE CONTRACTS: PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, KeyError, StopIteration, json.JSONDecodeError) as error:
        print(f"[FAIL] {error}", file=sys.stderr)
        raise SystemExit(1)
