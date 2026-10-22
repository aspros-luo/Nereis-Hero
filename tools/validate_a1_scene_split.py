#!/usr/bin/env python3
"""Static contracts for the authored A1.0/A1.1 scene split.

This validates source structure only; it does not replace Godot runtime checks.
"""
from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def read(path: str, errors: list[str]) -> str:
    target = ROOT / path
    if not target.is_file():
        errors.append(f"Missing file: {path}")
        return ""
    return target.read_text(encoding="utf-8")


def require(source: str, needle: str, label: str, errors: list[str]) -> None:
    if needle not in source:
        errors.append(f"{label}: missing {needle!r}")


def forbid(source: str, needle: str, label: str, errors: list[str]) -> None:
    if needle in source:
        errors.append(f"{label}: retired content remains: {needle!r}")


def main() -> int:
    errors: list[str] = []
    a10_scene = read("scenes/village_hub.tscn", errors)
    a10_script = read("scripts/levels/village_hub.gd", errors)
    a11_scene = read("scenes/village_backhill.tscn", errors)
    a11_script = read("scripts/levels/village_backhill.gd", errors)

    require(a10_scene, '[node name="BackhillEntrance" type="Node2D" parent="."]', "A1.0 authored A1.1 entrance", errors)
    require(a10_scene, '[node name="MiteHouse" type="Node2D" parent="."]', "A1.0 authored Mite house", errors)
    require(a10_scene, '[node name="VillageHouse01" type="Node2D" parent="."]', "A1.0 authored residential building", errors)
    require(a10_scene, '[node name="MerchantStall" type="Node2D" parent="."]', "A1.0 authored merchant stall", errors)
    require(a10_scene, '[node name="BlacksmithWorkshop" type="Node2D" parent="."]', "A1.0 authored workshop", errors)
    require(a10_scene, '[node name="Graveyard" type="Node2D" parent="."]', "A1.0 authored graveyard", errors)
    require(a10_scene, '[node name="OldHouse" type="Node2D" parent="."]', "A1.0 authored old house", errors)
    require(a10_script, '$BackhillEntrance.interacted.connect', "A1.0 authored entrance signal", errors)
    require(a10_script, 'location_id == "backhill_path"', "A1.0 to A1.1 transition", errors)
    require(a10_script, 'res://scenes/village_backhill.tscn', "A1.0 to A1.1 transition", errors)
    require(a11_script, 'res://scenes/village_hub.tscn', "A1.1 return transition", errors)
    require(a11_script, 'pending_region_spawn_side = "backhill_return"', "A1.1 return spawn contract", errors)
    require(a11_scene, '[node name="Hero" type="CharacterBody2D" parent="."]', "A1.1 authored Hero", errors)
    require(a11_scene, '[node name="BackhillStairs" type="Node2D" parent="."]', "A1.1 authored stairs", errors)
    require(a11_scene, '[node name="CliffLookout" type="StaticBody2D" parent="."]', "A1.1 cliff lookout collision", errors)
    require(a11_scene, '[node name="CliffLowerShelf" type="StaticBody2D" parent="."]', "A1.1 lower cliff landing", errors)
    require(a11_scene, '[node name="EastBoundary" type="StaticBody2D" parent="."]', "A1.1 east boundary", errors)
    require(a11_scene, '[node name="ChurchPOI" type="Node2D" parent="."]', "A1.1 church interaction node", errors)
    require(a11_scene, '[node name="TavernPOI" type="Node2D" parent="."]', "A1.1 tavern interaction node", errors)
    require(a11_scene, '[node name="BackToVillagePOI" type="Node2D" parent="."]', "A1.1 return interaction node", errors)
    require(a11_scene, '[node name="CliffCaveDoor" type="Area2D" parent="."]', "A1.1 authored cliff-cave door", errors)
    require(a11_script, 'returned_to_village_after_mad_cleric', "H09 cliff-cave story gate", errors)
    require(a11_script, 'WorldState.discover_hidden_region("H09")', "H09 discovery contract", errors)
    require(a11_script, 'WorldState.open_hidden_path("H09")', "H09 open-path contract", errors)
    forbid(a10_script, "屋顶捷径", "A1.0 renderer", errors)
    forbid(a10_script, "rooftop_waybill", "A1.0 old roof reward", errors)
    forbid(a10_script, "_spawn_cliff_cave_door", "A1.0 cave ownership", errors)
    forbid(a10_script, 'NereisLocalization.translate_text("教堂")', "A1.0 church landmark", errors)
    forbid(a10_script, 'NereisLocalization.translate_text("酒馆")', "A1.0 tavern landmark", errors)

    if errors:
        print("A1 SCENE SPLIT STATIC CHECK FAILED")
        for error in errors:
            print(f" - {error}")
        return 1

    print("A1 SCENE SPLIT STATIC CHECK PASSED")
    print(" - A1.0 owns residential/workshop village content and existing route contracts.")
    print(" - A1.1 owns authored stairs, cliff lookout, church, tavern, return, and H09 door.")
    print(" - A1.0 roof-route content and cliff-cave ownership are retired.")
    print("NOTE: Run Godot editor/runtime acceptance for collision, interaction focus, and scene transitions.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
