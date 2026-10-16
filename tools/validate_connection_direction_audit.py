#!/usr/bin/env python3
"""Focused direction and gate-contract audit for C11/C13/C14/C15/C19/C21/C22.

This is a source-level contract checker, not a substitute for Godot runtime traversal.
Run from any directory: python3 tools/validate_connection_direction_audit.py
"""
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOPOLOGY = ROOT / "tools/world_map_topology.json"
REGION_SCRIPT = ROOT / "scripts/levels/greybox_world_region.gd"
GATE_SCRIPT = ROOT / "scripts/world/resonance_secret_gate.gd"
HERO_SCRIPT = ROOT / "scripts/player/hero.gd"

def main() -> int:
    errors: list[str] = []
    try:
        data = json.loads(TOPOLOGY.read_text(encoding="utf-8"))
        region = REGION_SCRIPT.read_text(encoding="utf-8")
        gate = GATE_SCRIPT.read_text(encoding="utf-8")
        hero = HERO_SCRIPT.read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as exc:
        print(f"CONNECTION DIRECTION AUDIT FAILED: {exc}")
        return 1

    edges = {item.get("id"): item for item in data.get("connections", [])}
    expected = {
        "C11": ("A6", "A7", "both", "both"),
        "C13": ("A7", "A8", "both", "both"),
        "C14": ("A8", "A9", "both", "both"),
        "C15": ("A8", "A11", "blocked", "both"),
        "C19": ("A10", "A11", "blocked", "both"),
        "C21": ("A11", "A13", "blocked", "forward"),
        "C22": ("A12", "A13", "from_to", "forward"),
    }
    for edge_id, (source, target, initial, final) in expected.items():
        edge = edges.get(edge_id)
        if edge is None:
            errors.append(f"{edge_id}: missing from topology")
            continue
        actual = (edge.get("from"), edge.get("to"), edge.get("initial_access"), edge.get("final_direction"))
        if actual != (source, target, initial, final):
            errors.append(f"{edge_id}: expected {(source, target, initial, final)}, got {actual}")

    unlock_contracts = {
        "C15": "resonance_sight_active_and_resonance_at_least_55_and_ancient_exposure_at_least_2_and_sources_anomaly_bell_retiming_and_anomaly_erased_royal_name",
        "C19": "resonance_sight_active_and_resonance_at_least_68_and_outer_exposure_at_least_12_and_outer_god_resonance_and_source_anomaly_mirror_street_echo",
        "C21": "ending_candidate_is_not_human_grave_based_on_resonance_truth_anchors_and_exploration",
        "C22": "reached_A12_via_A10",
    }
    for edge_id, expected_condition in unlock_contracts.items():
        edge = edges.get(edge_id, {})
        if edge.get("unlock_condition") != expected_condition:
            errors.append(
                f"{edge_id}: unlock condition must match runtime contract {expected_condition!r}"
            )

    # Mainline C11/C13/C14 must be explicitly wired from both endpoint scenes.
    endpoint_contracts = {
        "C11": [
            '"A6":', '"res://scenes/prison_depths.tscn", "west"',
            '"A7":', '"res://scenes/monastery_tower.tscn", "east"',
        ],
        "C13": [
            '"A7":', '"res://scenes/royal_tomb.tscn", "maintenance_shaft_entry"',
            '"A8":', '"res://scenes/prison_depths.tscn", "maintenance_shaft_return"',
        ],
        "C14": [
            '"A8":', '"res://scenes/royal_outer_ring.tscn", "west"',
            '"A9":', '"res://scenes/royal_tomb.tscn", "east"',
        ],
    }
    for edge_id, needles in endpoint_contracts.items():
        for needle in needles:
            if needle not in region:
                errors.append(f"{edge_id}: missing endpoint wiring marker {needle!r}")

    # C14 has paired ground-level doors. Keep topology anchors aligned with the actual
    # boundary doors and the shared safe-spawn defaults.
    c14 = edges.get("C14", {}).get("spatial_contract", {})
    c14_from = c14.get("from_region_anchor", {})
    c14_to = c14.get("to_region_anchor", {})
    c14_return = c14.get("return_spawn", {})
    c14_arrival = c14.get("from_region_spawn", {})
    if not (
        c14_from.get("region") == "A8" and c14_from.get("x") == 2528
        and c14_from.get("y_offset") == 0
        and c14_to.get("region") == "A9" and c14_to.get("x") == 72
        and c14_to.get("y_offset") == 0 and c14_to.get("spawn_side") == "west"
        and c14_return.get("region") == "A8" and c14_return.get("x") == 2420
        and c14_return.get("y_offset") == 0 and c14_return.get("spawn_side") == "east"
        and c14_arrival.get("region") == "A9" and c14_arrival.get("x") == 180
        and c14_arrival.get("y_offset") == 0 and c14_arrival.get("spawn_side") == "west"
    ):
        errors.append("C14: topology must record the paired A8/A9 ground doors and safe arrival spawns.")
    if '"res://scenes/royal_outer_ring.tscn", "west"' not in region or '"res://scenes/royal_tomb.tscn", "east"' not in region:
        errors.append("C14: paired ground doors must remain wired between A8 and A9.")
    if 'if side == "east":\n\t\treturn map_width - 180.0' not in region or '\n\treturn 180.0\n' not in region:
        errors.append("C14: safe ground arrivals must remain on the far side of the paired boundary doors.")

    # Hidden gates must share persistent path state, require their intended evidence,
    # and only generate A11 return doors when that exact gate was opened.
    exit_start = region.find("func _spawn_region_exits()")
    exit_source = region[exit_start:] if exit_start >= 0 else ""
    a11_split = exit_source.split('\n\t\t"A11":', 1)
    a11_branch = a11_split[1].split('\n\t\t"', 1)[0] if len(a11_split) > 1 else ""
    for gate_id in ("C15", "C19"):
        if f'gate.secret_id = "{gate_id}"' not in region:
            errors.append(f"{gate_id}: runtime secret gate ID missing")
    if 'var can_return_to_tomb := WorldState.is_hidden_path_opened("C15")' not in a11_branch:
        errors.append("C15: A11 tomb return must be gated by C15's own persistent open state")
    if 'var can_return_to_cathedral := WorldState.is_hidden_path_opened("C19")' not in a11_branch:
        errors.append("C19: A11 cathedral return must be gated by C19's own persistent open state")
    c15_contract = (
        'gate.required_resonance = 55',
        'gate.required_ancient_exposure = 2',
        '["anomaly_bell_retiming", "anomaly_erased_royal_name"]',
    )
    for needle in c15_contract:
        if needle not in region:
            errors.append(f"C15: missing gate requirement {needle!r}")
    c19_contract = (
        'gate.required_resonance = 68',
        'gate.required_outer_exposure = 12',
        'gate.require_outer_god_resonance = true',
        '["anomaly_mirror_street_echo"]',
    )
    for needle in c19_contract:
        if needle not in region:
            errors.append(f"C19: missing gate requirement {needle!r}")

    # C13 must be authored as a genuinely elevated, bidirectional route on both ends.
    for needle in (
        '_add_platform(Rect2(2140, 460, 110, 18))',
        '_add_platform(Rect2(2200, 420, 370, 18))',
        'if region_id == "A8" and side == "maintenance_shaft_entry":',
        'if region_id == "A7" and side == "maintenance_shaft_return":',
        'return floor_y - 120.0',
    ):
        if needle not in region:
            errors.append(f"C13: missing elevated-route source marker {needle!r}")

    # C21 follows the same ending evaluator used by H08; intimacy/union state must not gate this route.
    if region.count('if NereisEndingEvaluator.get_candidate() != "凡人之墓":') < 2:
        errors.append("C21/H08: both terminal approaches must use the shared resonance/truth-anchor/exploration ending evaluator")
    if '"E  追随深层梦境", "terminal_anomaly"' not in region:
        errors.append("C21: missing A11-to-A13 terminal transition")
    if '"E  进入王座区", "terminal_anomaly"' not in region:
        errors.append("C22: missing A12-to-A13 terminal transition")
    if region.count("var ending_gate := ENDGAME_GATE_SCRIPT.new()") != 1:
        errors.append("Terminal route: ending candidate must be evaluated once, in A13 only")
    for needle in (
        "and _has_required_sources()",
        "and (not require_outer_god_resonance or WorldState.outer_god_resonance)",
        "WorldState.open_hidden_path(secret_id)",
    ):
        if needle not in gate:
            errors.append(f"Secret-gate implementation missing condition/state contract: {needle}")

    # Endgame entry must be one-way in topology and A13 must not spawn an ordinary
    # return door to A11/A12. The exit from A13 is only the ending-evaluator route.
    if exit_start < 0:
        errors.append("A13 runtime exit function missing")
    a13 = exit_source.split('\n\t\t"A13":', 1)
    if len(a13) < 2:
        errors.append("A13 exit branch could not be located")
    else:
        a13_branch = a13[1].split('\n\n\nfunc _spawn_a11_maintenance_gate', 1)[0]
        if '"deep_research_depths.tscn"' in a13_branch or '"inner_city.tscn"' in a13_branch:
            errors.append("A13 must not expose a return transition to A11/A12")
        if "route_candidate" not in a13_branch:
            errors.append("A13 must delegate ending selection to the shared evaluator")

    # C13 door trigger must be reachable from the upper platform but not by a max-height
    # jump from the continuous ground. The source constants let us check the vertical
    # envelope without pretending this replaces a Godot physics run.
    c13_a7_split = exit_source.split('\n\t\t"A7":', 1)
    c13_a7_branch = c13_a7_split[1].split('\n\t\t"', 1)[0] if len(c13_a7_split) > 1 else ""
    c13_a8_split = exit_source.split('\n\t\t"A8":', 1)
    c13_a8_branch = c13_a8_split[1].split('\n\t\t"', 1)[0] if len(c13_a8_split) > 1 else ""
    for endpoint, branch in (("A7", c13_a7_branch), ("A8", c13_a8_branch)):
        if 'true, "", "", floor_y - 140.0' not in branch:
            errors.append(f"C13: {endpoint} high-door trigger must be positioned at floor_y - 140.0")
    import re
    jump_match = re.search(r"const JUMP_VELOCITY := (-?[0-9.]+)", hero)
    gravity_match = re.search(r"const GRAVITY := ([0-9.]+)", hero)
    if not jump_match or not gravity_match:
        errors.append("C13: could not derive Hero jump envelope from hero.gd")
    else:
        jump_height = float(jump_match.group(1)) ** 2 / (2.0 * float(gravity_match.group(1)))
        hero_half_height = 24.0
        trigger_bottom_offset = -140.0 - 35.0 + 40.0
        jump_top_offset = -jump_height - hero_half_height
        if jump_top_offset <= trigger_bottom_offset:
            errors.append(
                f"C13: ground jump can reach high-door trigger (jump top {jump_top_offset:.1f}px, "
                f"trigger bottom {trigger_bottom_offset:.1f}px relative to floor)"
            )
        platform_top_offset = -120.0
        standing_hero_top_offset = platform_top_offset - hero_half_height
        if standing_hero_top_offset >= trigger_bottom_offset:
            errors.append("C13: upper-platform spawn no longer overlaps the high-door trigger vertically")

    # C13 return spawn must stay on the upper prison ledge with a safer door-focus margin.
    c13_spawn_start = region.find('if region_id == "A7" and side == "maintenance_shaft_return":', region.find("func _spawn_x_for_side"))
    c13_spawn_block = region[c13_spawn_start:c13_spawn_start + 360] if c13_spawn_start >= 0 else ""
    if "return map_width - 260.0" not in c13_spawn_block:
        errors.append("C13: A7 return spawn must be offset to map_width - 260.0 to avoid immediate door focus")
    if 'const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")' not in region:
        errors.append("Recovery/transition: shared interaction focus script is not loaded")
    if "INTERACTION_FOCUS_SCRIPT.clear_all(get_tree())" not in region:
        errors.append("Recovery/transition: must clear interaction focus before transition and after respawn")
    defeat_start = region.find("func _on_hero_defeated()")
    defeat_block = region[defeat_start:defeat_start + 850] if defeat_start >= 0 else ""
    if "WorldState.input_locked = true" not in defeat_block or "WorldState.input_locked = false" not in defeat_block:
        errors.append("Death recovery: input must remain locked during the two-stage checkpoint restore")
    if defeat_block.find("WorldState.input_locked = true") > defeat_block.find("await get_tree().create_timer(0.75).timeout"):
        errors.append("Death recovery: input lock must be set before the recovery delay")

    # Verify every runtime transition to A13 retains its own intended prerequisite.
    a12_split = exit_source.split('\n\t\t"A12":', 1)
    a12_branch = a12_split[1].split('\n\t\t"', 1)[0] if len(a12_split) > 1 else ""
    if 'if "reached_A12_via_A10" in WorldState.achievement_flags:' not in a12_branch:
        errors.append("C22: A12-to-A13 door must require reached_A12_via_A10")
    if '_register_debug_locked_route_hint(' not in a12_branch or "需要从大圣堂主线抵达 A12（C22）" not in a12_branch:
        errors.append("C22: locked mainline prerequisite should be visible when its door is unavailable")

    # C22 must be genuinely elevated: its trigger bottom stays above the maximum
    # vertical envelope of a ground jump, while a grounded Hero on the raised landing overlaps it.
    c22_contract = edges.get("C22", {}).get("spatial_contract", {})
    c22_anchor = c22_contract.get("from_region_anchor", {})
    if c22_anchor.get("region") != "A12" or c22_anchor.get("x") != 2130 or c22_anchor.get("y_offset") != -140:
        errors.append("C22: topology anchor must match the raised throne approach at A12 x=2130/y_offset=-140")
    if 'true, "", "", floor_y - 140.0' not in a12_branch:
        errors.append("C22: A12-to-A13 trigger must remain at floor_y - 140.0")
    if '_add_platform(Rect2(2100, 420, 190, 18))' not in region:
        errors.append("C22: the raised throne landing at x=2100/y=420 must support the terminal entrance")
    jump_match = re.search(r"const JUMP_VELOCITY := (-?[0-9.]+)", hero)
    gravity_match = re.search(r"const GRAVITY := ([0-9.]+)", hero)
    if jump_match and gravity_match:
        jump_height = float(jump_match.group(1)) ** 2 / (2.0 * float(gravity_match.group(1)))
        hero_half_height = 24.0
        c22_trigger_bottom_offset = -140.0 - 35.0 + 40.0
        c22_ground_jump_top_offset = -jump_height - hero_half_height
        if c22_ground_jump_top_offset <= c22_trigger_bottom_offset:
            errors.append(
                f"C22: ground jump can reach terminal trigger (jump top {c22_ground_jump_top_offset:.1f}px, "
                f"trigger bottom {c22_trigger_bottom_offset:.1f}px relative to floor)"
            )
        c22_landing_top_offset = -120.0 - hero_half_height
        if c22_landing_top_offset >= c22_trigger_bottom_offset:
            errors.append("C22: the raised landing no longer overlaps the terminal trigger vertically")
    else:
        errors.append("C22: could not derive Hero jump envelope from hero.gd")

    a11_split = exit_source.split('\n\t\t"A11":', 1)
    a11_branch_for_c21 = a11_split[1].split('\n\t\t"', 1)[0] if len(a11_split) > 1 else ""
    if 'if NereisEndingEvaluator.get_candidate() != "凡人之墓":' not in a11_branch_for_c21 or '"res://scenes/terminal_anomaly.tscn"' not in a11_branch_for_c21:
        errors.append("C21: A11-to-A13 transition must use the shared ending evaluator")
    h08_split = exit_source.split('\n\t\t"H08":', 1)
    h08_branch = h08_split[1].split('\n\t\t"', 1)[0] if len(h08_split) > 1 else ""
    if 'if NereisEndingEvaluator.get_candidate() != "凡人之墓":' not in h08_branch or '"res://scenes/terminal_anomaly.tscn"' not in h08_branch:
        errors.append("H08: alternate A13 entry must use the shared ending evaluator")
    if region.count('"res://scenes/terminal_anomaly.tscn"') != 3:
        errors.append("A13 entry audit: expected exactly three runtime entry points (C21, C22, H08)")

    # Floor geometry is continuous by design; a trigger door is not a physical wall.
    # Flag this explicitly as a manual runtime acceptance item, never as a passing claim.
    if "func _create_floor()" not in region or "rectangle.size = Vector2(map_width, 40.0)" not in region:
        errors.append("Could not verify the shared continuous-floor implementation; review bypass geometry manually")

    if errors:
        print("CONNECTION DIRECTION AUDIT FAILED")
        for error in errors:
            print(f" - {error}")
        return 1
    print("CONNECTION DIRECTION SOURCE CONTRACTS PASSED")
    print(" - C11/C13/C14 endpoint wiring and intended bidirectional topology checked.")
    print(" - C15/C19 hidden-gate thresholds, evidence, persistence, and per-gate return locks checked.")
    print(" - C21/C22 one-way terminal topology and A13 ending-only exit checked.")
    print("LIMITATION: continuous ground/fall/jump bypass, collision support, interaction focus, and transitions require Godot runtime acceptance.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
