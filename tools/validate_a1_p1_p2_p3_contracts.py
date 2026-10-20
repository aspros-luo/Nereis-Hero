#!/usr/bin/env python3
"""A1 P1/P2 source contracts plus P3 handoff guards.

Run from the repository root:
    python3 tools/validate_a1_p1_p2_p3_contracts.py

This is a static contract validator. It does not claim Godot runtime acceptance.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    target = ROOT / path
    if not target.is_file():
        raise AssertionError(f"Required file missing: {path}")
    return target.read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    village = read("scripts/levels/village_hub.gd")
    gate = read("scripts/world/resonance_secret_gate.gd")
    director = read("scripts/core/world_event_director.gd")
    world_state = read("scripts/core/world_state.gd")
    interior = read("scripts/levels/interior_scene.gd")
    region = read("scripts/levels/greybox_world_region.gd")
    drain = read("scripts/levels/old_drain_exploration.gd")
    catalog = read("scripts/core/item_catalog.gd")
    topology = json.loads(read("tools/world_map_topology.json"))

    # P1: physical roof route has collision platforms and a persisted, non-repeatable reward.
    roof_start = village.find("func _create_village_rooftop_route()")
    roof_end = village.find("func _create_boundaries()", roof_start)
    require(roof_start >= 0 and roof_end > roof_start, "A1: rooftop collision-route builder is missing.")
    roof_source = village[roof_start:roof_end]
    require(
        roof_source.count("VillageRooftopPlatform") >= 1
        and "one_way_collision = true" in roof_source
        and "Rect2(1060, 285" not in roof_source,
        "A1: rooftop route must use real one-way collision platforms, not decorative lines alone.",
    )
    require(
        'func _spawn_rooftop_waybill() -> void:' in village
        and '_spawn_rooftop_waybill()' in village
        and 'waybill.position = Vector2(1095, 350)' in village
        and '"old_pilgrim_waybill"' in catalog
        and 'WorldState.inventory_items["old_pilgrim_waybill"]' in village
        and '"A1_rooftop_old_pilgrim_waybill" in WorldState.collected_world_item_ids' in village
        and 'WorldState.record_achievement("A1_rooftop_waybill_found")' in village
        and 'if String(poi.poi_id) == "rooftop_waybill" and "A1_rooftop_waybill_found" not in WorldState.achievement_flags:' in village,
        "A1: rooftop route must grant the existing waybill item once and persist the collection state.",
    )
    require(
        '"A1_rooftop_waybill_found" in WorldState.achievement_flags' in village
        and 'WorldState.save_game()' in village,
        "A1: rooftop reward must remain collected after scene changes, death, and Continue.",
    )

    # P1: route closure and H01 discovery/open/entry are separate facts.
    require(
        'var old_pilgrim_road_open := "village_defense_survived" in WorldState.achievement_flags' in village
        and 'north_gate.display_name = "旧朝圣路" if old_pilgrim_road_open else "北门"' in village
        and 'city_cut.display_name = "旧排水通道" if city_cut_open else "封闭的排水通道"' in village
        and 'SceneTransition.fade_to_scene("res://scenes/old_drain_exploration.tscn")' in village,
        "A1: north gate and drain must visibly reflect the defense milestone and use the exploration segment.",
    )
    discover = gate.find("if region_record_id not in WorldState.discovered_hidden_regions:")
    open_path = gate.find("if not WorldState.is_hidden_path_opened(secret_id):", discover)
    enter_path = gate.find("if opened_permanently:", open_path)
    require(
        discover >= 0 and open_path > discover and enter_path > open_path
        and "WorldState.discover_hidden_region(region_record_id)" in gate
        and "WorldState.open_hidden_path(secret_id)" in gate
        and "WorldState.mark_hidden_region_entered(_get_region_record_id())" in gate
        and '"已发现 · 再按 E 开启"' in gate,
        "H01: discovery, permanent opening, and actual entry must be separate saved states with feedback.",
    )
    require(
        'WorldState.pending_region_spawn_side = "west"' in village
        and 'WorldState.pending_region_spawn_side = "village_entry"' in village
        and '"city_cut_return"' in village
        and '"well_exit", "cliff_cave_return"' in village,
        "A1: route return sides and non-overlapping landing spawn contracts must remain explicit.",
    )
    require(
        'CONNECTION_FLAG := "opened_old_drainage_link_from_A4"' in drain
        and 'func _add_gate_blocker() -> void:' in drain
        and 'if "opened_old_drainage_link_from_A4" in WorldState.achievement_flags:' in region,
        "A1/A3/A4: the old-drain gate must remain physically blocked until its own persistent unlock.",
    )

    # P2: state feedback, idempotent events, and no guessed story milestone writes.
    require(
        'draw_line(Vector2(2808, 378), Vector2(2825, 392), Color("#b58a65"), 3.0)' in village
        and 'for nail in [Vector2(2810, 374)' in village
        and 'blacksmith.dialogue = "铁匠把锤子搁在砧边，检查着刚换上的门钉。' in village,
        "A1: defense feedback must change both the gate's visible state and blacksmith dialogue.",
    )
    require(
        '"id": "A1_tavern_sound_notice"' in director
        and '"once": true' in director
        and '{"type": "flag_absent", "value": "A1_tavern_sound_noticed"}' in director
        and '{"type": "add_flag", "value": "A1_tavern_sound_noticed"}' in director
        and 'func _mark_fired(event_id: String)' in director
        and '_world_state.save_game()' in director[director.find("func _mark_fired(event_id: String)"):],
        "A1: tavern sound event must be one-shot and persist its event marker.",
    )
    require(
        'tavern.add_to_group("a1_tavern_poi")' in village
        and 'func _refresh_tavern_poi_dialogue() -> void:' in village
        and '_refresh_tavern_poi_dialogue()' in village
        and '"A1_tavern_sound_noticed" in WorldState.achievement_flags' in village
        and '你再次靠近酒馆。门内没有歌声' in village,
        "A1: the first tavern sound discovery must change the outdoor POI dialogue on revisit.",
    )
    require(
        'npc.add_to_group("a1_baseline_npcs")' in village
        and 'grandmother.add_to_group("a1_baseline_npcs")' in village
        and 'blacksmith.add_to_group("a1_baseline_npcs")' in village
        and 'merchant.add_to_group("a1_baseline_npcs")' in village
        and 'func refresh_progression_content() -> void:' in village
        and '_refresh_baseline_npc_dialogue(npc)' in village
        and '"graybox_intro_forgotten_city" in WorldState.achievement_flags' in village
        and '"graybox_intro_ash_forest" in WorldState.achievement_flags' in village,
        "A1: baseline NPC dialogue must refresh from actual progression facts on return.",
    )
    require(
        '"restoration_camp_established" in WorldState.achievement_flags' in village
        and 'if "village_defense_survived" in WorldState.achievement_flags' not in village[
            village.find('if "restoration_camp_established" in WorldState.achievement_flags:'):
            village.find("var north_gate := Node2D.new()")
        ]
        and '"pilgrim_knight_a1_arrived"' in director
        and '"pilgrim_knight_at_tavern"' in director
        and 'if location_id != "church" or church_occupied:' in interior,
        "A1: camp, pilgrim arrival, and church occupancy must not be inferred from ordinary village events.",
    )
    require(
        'if "defeated_mad_cleric" in WorldState.achievement_flags:' in village
        and 'WorldState.record_achievement("returned_to_village_after_mad_cleric")' in village
        and 'WorldState.record_achievement("defeated_mad_cleric")' in region,
        "A1: cliff-cave state must follow the actual boss defeat and physical village return.",
    )
    c24 = next(edge for edge in topology["connections"] if edge.get("id") == "C24")
    require(
        c24.get("from") == "A1" and c24.get("to") == "A3"
        and c24.get("unlock_condition") == "village_defense_survived",
        "A1: C24 must retain the existing A1-to-A3 identity and defense gate.",
    )
    require(
        '"discovered_hidden_regions": discovered_hidden_regions' in world_state
        and '"opened_hidden_paths": opened_hidden_paths' in world_state
        and '"entered_hidden_regions": entered_hidden_regions' in world_state,
        "H01: discovery/open/entry arrays must be serialized in the save.",
    )

    print("[PASS] P1 roof collision route and one-time catalog-item reward contracts")
    print("[PASS] P1 defense route states, drain gate, safe returns, and H01 staged state transitions")
    print("[PASS] P2 visible gate repair, stateful NPC feedback, and one-shot tavern event")
    print("[PASS] P2 confirmed story facts remain gated; C24 and cliff-return contracts preserved")
    print("A1 P1/P2 STATIC CONTRACTS: PASS")
    print("P3 runtime playthrough is deliberately not inferred from static checks.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, KeyError, StopIteration, json.JSONDecodeError) as error:
        print(f"[FAIL] {error}", file=sys.stderr)
        raise SystemExit(1)
