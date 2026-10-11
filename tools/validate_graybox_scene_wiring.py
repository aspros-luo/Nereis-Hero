#!/usr/bin/env python3
"""Static wiring checks for the A2-A12 graybox and H01 hidden-well loop.

This script checks file references and save/transition contracts. It does not
replace Godot runtime tests for collision, interaction focus, or scene changes.
"""

from __future__ import annotations

import re
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
    "A11": ("scenes/deep_research_depths.tscn", "deep_research_depths", "THE DEPTHS THAT PRECEDED THE LAB"),
    "H08": ("scenes/primordial_hollow.tscn", "primordial_hollow", "THE WOMB BELOW THE LAB"),
    "H07": ("scenes/mirror_street.tscn", "mirror_street", "MIRROR STREET: BEHIND THE RAIN"),
    "H01": ("scenes/hidden_well.tscn", "hidden_well", "THE WELL BELOW THE WELL"),
    "H02": ("scenes/hidden_bell_chamber.tscn", "hidden_bell_chamber", "THE BELL BEFORE THE SOUND"),
    "H03": ("scenes/erased_third_street.tscn", "erased_third_street", "THE STREET THE CITY REMOVED"),
    "H04": ("scenes/reflected_stairwell.tscn", "reflected_stairwell", "THE STAIRS BEHIND THE WATER"),
    "H05": ("scenes/silent_bell_room.tscn", "silent_bell_room", "THE WINDOW THAT CASTS NO SHADOW"),
    "H06": ("scenes/erased_royal_name_corridor.tscn", "erased_royal_name_corridor", "THE NAME SCRAPED FROM STONE"),
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

    interaction_focus = read("scripts/core/interaction_focus.gd", errors)
    if interaction_focus.count("WorldState.menu_input_locked") < 2:
        errors.append(
            "Interaction focus must block world interactions while menu_input_locked is active."
        )

    secret_gate = read("scripts/world/resonance_secret_gate.gd", errors)
    require(secret_gate, "func _is_debug_override_active()", "Resonance secret gate", errors)
    require(secret_gate, "allow_debug_override: bool = true", "Resonance secret gate", errors)
    require(secret_gate, "_is_debug_override_active()", "Resonance secret gate", errors)
    require(secret_gate, "[NEREIS][MAP][GATE] id=%s revealed=%s", "Gate Debug log", errors)
    require(secret_gate, "[NEREIS][MAP][GATE] enter id=%s", "Gate transition log", errors)

    world_state = read("scripts/core/world_state.gd", errors)
    require(world_state, "var debug_ability_override_active := false", "WorldState", errors)
    require(world_state, '"resume_spawn_side": resume_spawn_side', "WorldState save payload", errors)
    require(world_state, 'resume_spawn_side = str(parsed.get("resume_spawn_side", "west"))', "WorldState save migration", errors)
    require(world_state, 'resume_spawn_side = requested_spawn_side', "WorldState location save", errors)
    require(world_state, 'resume_spawn_side.length() > 64', "WorldState spawn-side input guard", errors)
    require(world_state, "pending_region_spawn_side = \"west\"\n    resume_spawn_side = \"west\"", "WorldState new-game reset", errors)
    boot_script = read("scripts/core/boot.gd", errors)
    require(boot_script, "WorldState.pending_region_spawn_side = WorldState.resume_spawn_side", "Continue spawn restore", errors)
    region_spawn_script = read("scripts/levels/greybox_world_region.gd", errors)
    require(region_spawn_script, "WorldState.set_location(location_id)\n    WorldState.pending_region_spawn_side = \"west\"", "Graybox spawn-side save order", errors)
    hero_script = read("scripts/player/hero.gd", errors)
    require(hero_script, "WorldState.debug_ability_override_active = enabled", "Hero Debug toggle", errors)
    require(hero_script, "debug_ability_override = WorldState.debug_ability_override_active", "Hero scene re-entry", errors)
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
    require(region_script, "[NEREIS][MAP][SPAWN] region=%s", "Map spawn Debug log", errors)
    require(region_script, "[NEREIS][MAP][EXIT] from=%s", "Map exit Debug log", errors)

    # Verify that every source ID required by a gate is actually spawned by the region controller.
    # 检查所有入口要求的异常来源，都确实由区域控制器生成。
    required_source_ids: set[str] = set()
    for raw_ids in re.findall(r'gate\.required_source_ids\s*=\s*\[([^\]]*)\]', region_script, re.DOTALL):
        required_source_ids.update(re.findall(r'"([^"]+)"', raw_ids))
    spawned_source_ids = set(
        re.findall(r'_spawn_source\(\s*Vector2\([^)]*\),\s*"([^"]+)"', region_script, re.DOTALL)
    )
    missing_source_ids = sorted(required_source_ids - spawned_source_ids)
    if missing_source_ids:
        errors.append(f"Hidden gate source IDs have no spawn point: {missing_source_ids}")

    # Check scene paths used by the map, save-resume routing, and hidden gates.
    # 检查地图、存档续玩和隐藏入口引用的场景路径均存在。
    referenced_scripts = [world_state, boot_script, region_script, secret_gate]
    for referenced_scene in sorted(set(
        re.findall(r'res://(scenes/[^"\s]+\.tscn)', "\n".join(referenced_scripts))
    )):
        if not (ROOT / referenced_scene).is_file():
            errors.append(f"Missing referenced scene: {referenced_scene}")
    for contract in [
        'const RESONANCE_SECRET_GATE_SCRIPT = preload("res://scripts/world/resonance_secret_gate.gd")',
        "_spawn_a4_hidden_well_gate(map_width - 105.0)",
        'gate.secret_id = "H01"',
        'gate.secret_id = "H02"',
        'gate.secret_id = "H03"',
        'gate.secret_id = "H04"',
        'gate.secret_id = "H05"',
        'gate.secret_id = "H06"',
        'gate.secret_id = "H07"',
        'gate.secret_id = "C15"',
        'gate.secret_id = "C19"',
        'gate.secret_id = "H08"',
        'gate.region_record_id = "A11"',
        'func _spawn_h02_gate',
        'func _spawn_h03_gate',
        'func _spawn_h04_gate',
        'func _spawn_h05_gate',
        'func _spawn_h06_gate',
        'func _spawn_a11_maintenance_gate',
        'func _spawn_a11_chapel_gate',
        'func _spawn_h08_gate',
        'func _on_h08_gate_opened',
        'func _draw_deep_research_landmarks',
        'func _draw_primordial_hollow_landmarks',
        'func _draw_hidden_bell_chamber_landmarks',
        'func _draw_erased_third_street_landmarks',
        'func _draw_reflected_stairwell_landmarks',
        'func _draw_silent_bell_room_landmarks',
        'func _draw_erased_royal_name_landmarks',
        'anomaly_observer_reaction',
        'if WorldState.physical_union_complete:',
        'ENDGAME_GATE_SCRIPT',
        'reached_A10_via_A9',
        'primordial_hollow',
        'deep_research_depths',
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
        'reached_A5_and_opened_old_pilgrim_highroad',
        'E  OPEN THE OLD PILGRIM HIGHROAD',
        'E  RETURN TO THE BATTLEFIELD',
        'opened_bell_tower_drop',
        'E  RETURN TO THE MONASTERY DROP',
        'reached_A7_then_opened_supply_tunnel',
        'reached_A8_via_A7_then_opened_royal_tomb_gate',
        'reached_A9_via_A8_then_opened_old_lift_from_A9',
        'reached_A12_via_A10_then_opened_inner_city_side_gate',
        'reached_A9_then_opened_royal_drain_from_outer_ring',
        'E  OPEN THE SUPPLY TUNNEL',
        'E  OPEN THE ROYAL TOMB WATERWAY',
        'E  OPEN THE OLD LIFT',
        'E  OPEN THE INNER-CITY SIDE GATE',
        'E  OPEN THE ROYAL DRAIN',
        'opened_old_bell_tower_connection',
        'opened_old_service_door',
        'opened_royal_tomb_side_door',
        'opened_bell_tower_drop',
        'opened_royal_transport_side_door',
        'WorldState.mark_hidden_region_entered("H02")',
        'WorldState.mark_hidden_region_entered("H03")',
        'WorldState.mark_hidden_region_entered("H04")',
        'WorldState.mark_hidden_region_entered("H05")',
        'WorldState.mark_hidden_region_entered("H06")',
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

    # Catch accidental line-join syntax defects in spawn mapping and ensure C04 is wired on both ends.
    # 检查出生点映射中意外粘连的语法错误，并确保 C04 两端都接线。
    if 'return 850.0    if region_id' in region_script:
        fail(errors, "Graybox spawn mapping: C04 A5 spawn branch is concatenated with the next if statement.")
    for contract in [
        '"E  OPEN THE OLD PILGRIM HIGHROAD"',
        '"E  RETURN TO THE BATTLEFIELD"',
        '"reached_A5_and_opened_old_pilgrim_highroad" in WorldState.achievement_flags',
        '"reached_A5_and_opened_old_pilgrim_highroad", "E  RETURN BY THE OLD PILGRIM HIGHROAD"',
    ]:
        require(region_script, contract, "C04 old pilgrim highroad", errors)

    # Spawn-side contracts keep the Hero clear of the very door/gate used to enter a region.
    # 出口出生点必须避开刚刚使用的门与隐藏入口，防止落地即重新触发 E 交互。
    spawn_contracts = [
        ('if region_id == "A9" and side == "mirror":', "return 1680.0"),
        ('if region_id == "A11" and side == "chapel_entry":', "return map_width - 700.0"),
        ('if region_id == "H02" and side == "bell_tower_entry":', "return map_width - 360.0"),
        ('if region_id == "H03" and side == "third_street_entry":', "return map_width - 360.0"),
        ('if region_id == "H04" and side == "royal_tomb_side_entry":', "return map_width - 360.0"),
        ('if region_id == "H05" and side == "bell_drop_entry":', "return map_width - 360.0"),
        ('if region_id == "H06" and side == "royal_transport_entry":', "return map_width - 360.0"),
        ('if region_id == "A3" and side == "sewer":', "return 1380.0"),
        ('if region_id == "A2" and side == "bell_gate":', "return map_width - 450.0"),
        ('if region_id == "A2" and side == "old_pilgrim_highroad":', "return map_width - 650.0"),
        ('if region_id == "A5" and side == "old_pilgrim_highroad":', "return 850.0"),
        ('if region_id == "A3" and side == "bell_drop":', "return 1600.0"),
        ('if region_id == "A9" and side == "old_lift":', "return 1450.0"),
        ('if region_id == "A9" and side == "inner_city_side_gate":', "return 1650.0"),
        ('if region_id == "A3" and side == "third_street_gate":', "return map_width - 500.0"),
        ('if region_id == "A4" and side == "water_reflection_gate":', "return 1550.0"),
        ('if region_id == "A4" and side == "east":', "return map_width - 360.0"),
        ('if region_id == "A4" and side == "prison_tunnel":', "return 520.0"),
        ('if region_id == "A4" and side == "royal_tomb_waterway":', "return 760.0"),
        ('if region_id == "A4" and side == "royal_drain":', "return 760.0"),
        ('if region_id == "A5" and side == "bell_tower":', "return map_width - 800.0"),
        ('if region_id == "A6" and side == "silent_window":', "return 1400.0"),
        ('if region_id == "A8" and side == "royal_name_gate":', "return 1350.0"),
        ('if region_id == "A8" and side == "royal_tomb_side":', "return 1200.0"),
        ('if region_id == "A9" and side == "third_street_service":', "return 1250.0"),
        ('if region_id == "A9" and side == "royal_transport":', "return map_width - 650.0"),
        ('if region_id == "H01" and side == "east":', "return map_width - 360.0"),
    ]
    for condition, expected_return in spawn_contracts:
        start = region_script.find(condition)
        if start < 0:
            fail(errors, f"Graybox spawn mapping: missing {condition!r}")
            continue
        branch = region_script[start:]
        next_branch = branch.find("\n    if ", len(condition))
        if next_branch >= 0:
            branch = branch[:next_branch]
        require(branch, expected_return, f"Graybox spawn mapping {condition}", errors)

    # Death recovery must stay inside the current region and restore the Hero safely.
    # 死亡恢复必须留在当前区域，并安全恢复主角状态。
    spawn_hero_start = region_script.find("func _spawn_hero(")
    spawn_hero_end = region_script.find("\nfunc ", spawn_hero_start + 1)
    spawn_hero_block = region_script[spawn_hero_start:spawn_hero_end if spawn_hero_end >= 0 else len(region_script)]
    for contract in [
        "WorldState.set_checkpoint(hero.global_position)",
        "hero.defeated.connect(_on_hero_defeated)",
    ]:
        require(spawn_hero_block, contract, "Region-local checkpoint setup", errors)

    death_start = region_script.find("func _on_hero_defeated() -> void:")
    death_end = region_script.find("\nfunc ", death_start + 1)
    death_block = region_script[death_start:death_end if death_end >= 0 else len(region_script)]
    for contract in [
        "if respawning:",
        "respawning = true",
        "hero.velocity = Vector2.ZERO",
        "hero.global_position = WorldState.checkpoint_position",
        'hero.call("restore_full")',
        "WorldState.input_locked = false",
        "respawning = false",
    ]:
        require(death_block, contract, "Death recovery", errors)
    if "SceneTransition.fade_to_scene(" in death_block or "change_scene_to_file(" in death_block:
        fail(errors, "Death recovery must not transition to another region or reuse a previous scene checkpoint.")

    source_clue = read("scripts/world/resonance_source_clue.gd", errors)
    require(source_clue, "WorldState.record_resonance_milestone(", "Resonance source clue", errors)
    require(source_clue, "func _milestone_needs_repair() -> bool:", "Legacy-save anomaly repair", errors)
    require(source_clue, "func _refresh_consumed_state() -> void:", "Legacy-save anomaly repair", errors)
    require(source_clue, "not WorldState.is_ability_unlocked(unlock_ability_id)", "Legacy-save ability repair", errors)
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
        "@export var region_record_id: String = \"\"",
        "func _get_region_record_id() -> String:",
        "WorldState.discover_hidden_region(_get_region_record_id())",
        "WorldState.open_hidden_path(secret_id)",
        "WorldState.mark_hidden_region_entered(_get_region_record_id())",
        "WorldState.resonance_sight_active",
        "KEY_E",
        "SceneTransition.fade_to_scene(target_scene_path)",
        'target_spawn_side: String = "west"',
        "require_outer_god_resonance",
        "WorldState.pending_region_spawn_side = target_spawn_side",
        "match secret_id:",
        "func _draw_well_marker() -> void:",
        "func _draw_early_bell_marker() -> void:",
        "func _draw_erased_street_marker() -> void:",
        "func _draw_reflected_stairs_marker() -> void:",
        "func _draw_silent_window_marker() -> void:",
        "func _draw_mirror_street_marker() -> void:",
        "func _draw_erased_royal_name_marker() -> void:",
        "func _draw_silent_chapel_marker() -> void:",
        "func _draw_breathing_wall_marker() -> void:",
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
    print(" - A2-A12 plus H01-H08 scenes have scripts and resume mappings.")
    print(" - The R01-R08 anomaly source chain is present.")
    print(" - H01-H08 plus C15/C19 gates use saved discovery/open/entry state and progression conditions.")
    print(" - C15 enters A11 from A8; C19 is the alternate A10 entry; H08 ending exit requires physical union.")
    print("NOTE: Godot runtime/collision/input validation is still required.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
