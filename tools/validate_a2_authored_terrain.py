#!/usr/bin/env python3
"""Static checks for the A2 authored terrain overlay and its existing C03/C04 anchors."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SCENE = ROOT / "scenes/ash_forest.tscn"
TERRAIN = ROOT / "scripts/levels/a2_authored_terrain.gd"
REGION = ROOT / "scripts/levels/greybox_world_region.gd"


def main() -> int:
    errors: list[str] = []
    for path in (SCENE, TERRAIN, REGION):
        if not path.is_file():
            errors.append(f"Missing required file: {path.relative_to(ROOT)}")
    if errors:
        print("\n".join(f"[FAIL] {error}" for error in errors))
        return 1

    scene = SCENE.read_text(encoding="utf-8")
    terrain = TERRAIN.read_text(encoding="utf-8")
    region = REGION.read_text(encoding="utf-8")

    required_scene_contracts = (
        'path="res://scripts/levels/greybox_world_region.gd"',
        'path="res://scripts/levels/a2_authored_terrain.gd"',
        'region_id = "A2"',
        'location_id = "ash_forest"',
    )
    for contract in required_scene_contracts:
        if contract not in scene:
            errors.append(f"A2 scene missing wiring: {contract}")

    required_terrain_contracts = (
        'call_deferred("_apply_authored_terrain")',
        '"WestForestGround", 0.0, 860.0, 540.0',
        '"EastForestGround", 1480.0, 1120.0, 540.0',
        '"FloodedCryptFloor", 860.0, 620.0, CRYPT_FLOOR_Y',
        'Rect2(2195, 380, 160, 18)',
        'Rect2(2055, 400, 145, 18)',
        'Rect2(1805, 425, 165, 18)',
        'Rect2(1660, 400, 150, 18)',
        'rest.position = Vector2(1600.0, 540.0)',
        'bell.position = Vector2(735.0, 322.0)',
    )
    for contract in required_terrain_contracts:
        if contract not in terrain:
            errors.append(f"A2 terrain missing contract: {contract}")

    required_visual_contracts = (
        'if region_id == "A2":',
        'draw_rect(Rect2(860.0, floor_y - 1.0, 620.0, 121.0)',
        'draw_texture_rect(STONE_FLOOR_STRIP, Rect2(860.0, 660.0, 620.0, 60.0), false)',
        'draw_line(Vector2(860.0, floor_y), Vector2(860.0, 660.0)',
        'draw_line(Vector2(1480.0, floor_y), Vector2(1480.0, 660.0)',
    )
    for contract in required_visual_contracts:
        if contract not in region:
            errors.append(f"A2 sinkhole visual missing contract: {contract}")

    if errors:
        print("A2 AUTHORED TERRAIN STATIC CHECK: FAIL")
        for error in errors:
            print(f" - {error}")
        return 1

    print("A2 AUTHORED TERRAIN STATIC CHECK: PASS")
    print(" - Shared world controller remains the scene root.")
    print(" - Surface collision is split around the lower crypt.")
    print(" - C03/C04 landings, rest point and bell clue have authored support.")
    print(" - Sinkhole and crypt have dedicated visual treatment.")
    print("NOTE: static checks do not replace Godot runtime traversal acceptance.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
