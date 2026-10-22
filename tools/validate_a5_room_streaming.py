#!/usr/bin/env python3
"""Static validation for the A5 streaming adapter. Does not replace Godot runtime tests."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT / "tools" / "a5_room_assembly_contract.json"
WORLD = ROOT / "scripts" / "world" / "world.gd"
ROOM_DATA = ROOT / "scripts" / "resources" / "room_data.gd"
ROOM_STATE = ROOT / "scripts" / "core" / "world_state.gd"
SHORTCUT = ROOT / "scripts" / "rooms" / "shortcut_unlock_point.gd"
REGION_SCRIPT = ROOT / "scripts" / "levels" / "greybox_world_region.gd"

def main() -> int:
    errors = []
    data = json.loads(CONTRACT.read_text(encoding="utf-8"))
    world = WORLD.read_text(encoding="utf-8")
    room_data = ROOM_DATA.read_text(encoding="utf-8")
    room_state = ROOM_STATE.read_text(encoding="utf-8")
    shortcut = SHORTCUT.read_text(encoding="utf-8")
    region_script = REGION_SCRIPT.read_text(encoding="utf-8")
    rooms = data.get("rooms", [])
    edges = data.get("connections", [])
    ids = {room.get("id") for room in rooms}

    if len(rooms) != 22 or len(ids) != 22:
        errors.append(f"expected 22 unique rooms; found entries={len(rooms)}, unique={len(ids)}")
    for room in rooms:
        rid, scene = room.get("id"), room.get("scene_path", "")
        if not scene.startswith("res://"):
            errors.append(f"{rid}: invalid scene path {scene!r}")
            continue
        path = ROOT / scene.removeprefix("res://")
        if not path.is_file():
            errors.append(f"{rid}: missing scene {scene}")
            continue
        text = path.read_text(encoding="utf-8")
        if f'room_id = "{rid}"' not in text:
            errors.append(f"{rid}: scene does not declare its own room_id")
        if 'greybox_world_region.gd' not in text:
            errors.append(f"{rid}: expected legacy A5 room geometry script")
    edge_ids = [e.get("id") for e in edges]
    if len(edge_ids) != len(set(edge_ids)):
        errors.append("duplicate connection IDs")
    for edge in edges:
        src, dst = edge.get("from"), edge.get("to")
        if src not in ids or dst not in ids:
            errors.append(f"{edge.get('id')}: endpoint missing: {src} -> {dst}")
        if edge.get("travel") not in ("both", "one_way"):
            errors.append(f"{edge.get('id')}: unsupported travel mode")
        if edge.get("initial_state") not in ("open", "blocked"):
            errors.append(f"{edge.get('id')}: unsupported initial state")

    required_world_tokens = (
        'A5_CONTRACT_PATH', '_load_a5_contract', 'assembly_child_mode',
        '_build_room_transitions', '_target_entry_id', '_edge_entry_id',
        'load_threaded_request', 'load_threaded_get', '_apply_camera_bounds',
        'WorldState.mark_room_explored', 'edge_state == "open" or WorldState.opened_shortcut_ids.has(edge_id)',
    )
    for token in required_world_tokens:
        if token not in world:
            errors.append(f"World streaming implementation missing {token}")
    if 'as RoomBase' in world:
        errors.append("World still requires RoomBase root and cannot adapt the existing A5 room scenes")
    for token in ("room_id", "area_id", "scene_path", "adjacent_room_ids"):
        if token not in room_data:
            errors.append(f"RoomData missing field {token}")
    for token in ("mark_room_explored", "open_room_shortcut", "collect_room_item", "save_room_state", "load_room_state"):
        if token not in room_state:
            errors.append(f"WorldState room persistence missing {token}")
    for token in ("_build_shortcut_unlock_point", "_unlock_shortcut", "opened_shortcut_ids", "KEY_E"):
        if token not in world:
            errors.append(f"World shortcut interaction missing {token}")
    for token in ("player_nearby_changed", "body_entered", "body_exited", "InteractionPrompt", "prompt_text"):
        if token not in shortcut:
            errors.append(f"Shortcut unlock point missing {token}")
    for token in ('"shortcut", "elevator", "hidden"', "按 E 探查隐藏通路"):
        if token not in world:
            errors.append(f"Optional hidden-route interaction missing {token}")
    for token in ("_drop_exit_x", "_safe_entry_x", "floor_y + 30.0"):
        if token not in world:
            errors.append(f"World vertical traversal handling missing {token}")
    for token in ('"A5-R05":\n\t\t\t# The one-way drop', 'gaps = [Vector2(600, 120)]', 'gaps = [Vector2(560, 120)]'):
        if token not in region_script:
            errors.append(f"A5 drop shaft geometry missing {token}")

    # Existing macro contracts must remain attached to the intended rooms and exits.
    bindings = {item.get("id"): item for item in data.get("macro_bindings", [])}
    expected = {
        "C08": ("A5-R01", "west_high_parapet"),
        "C04": ("A5-R16", "old_pilgrim_highroad_winch_gate"),
        "C09": ("A5-R20", "east_upper_parapet"),
    }
    for edge_id, pair in expected.items():
        item = bindings.get(edge_id)
        if not item or (item.get("room"), item.get("exit")) != pair:
            errors.append(f"{edge_id}: macro binding changed")

    if errors:
        for error in errors:
            print(f"[FAIL] {error}")
        print(f"A5 ROOM STREAMING STATIC CHECK: FAIL | errors={len(errors)}")
        return 1
    print("A5 ROOM STREAMING STATIC CHECK: PASS")
    print(f"rooms={len(rooms)} connections={len(edges)} macro_bindings={len(expected)}")
    print("Scene existence, edge endpoints, travel modes, locked-edge defaults and World adapter checked.")
    print("This is a static check only; Godot parsing, collision, traversal and full-route playability remain runtime acceptance tasks.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
