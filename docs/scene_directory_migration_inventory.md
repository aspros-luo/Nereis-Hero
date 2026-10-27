# Scene Directory Migration Inventory

Branch: `feature/story-map-progression`

Status: inventory derived from the current branch tree, `scripts/core/world_state.gd`, and `tools/world_map_topology.json`. This is a migration plan, not evidence of runtime acceptance.

## Primary region entry scenes

| Region | Current entry scene | Proposed path |
|---|---|---|
| A0 | `scenes/escape_prologue.tscn` | `scenes/regions/escape_prologue.tscn` |
| A1 | `scenes/village_hub.tscn` | `scenes/regions/village_hub.tscn` |
| A2 | `scenes/ash_forest.tscn` | `scenes/regions/ash_forest.tscn` |
| A3 | `scenes/forgotten_city.tscn` | `scenes/regions/forgotten_city.tscn` |
| A4 | `scenes/sewer_reservoir.tscn` | `scenes/regions/sewer_reservoir.tscn` |
| A5 | `scenes/old_battlefield.tscn` | `scenes/regions/old_battlefield.tscn` |
| A6 | `scenes/monastery_tower.tscn` | `scenes/regions/monastery_tower.tscn` |
| A7 | `scenes/prison_depths.tscn` | `scenes/regions/prison_depths.tscn` |
| A8 | `scenes/royal_tomb.tscn` | `scenes/regions/royal_tomb.tscn` |
| A9 | `scenes/royal_outer_ring.tscn` | `scenes/regions/royal_outer_ring.tscn` |
| A10 | `scenes/grand_cathedral.tscn` | `scenes/regions/grand_cathedral.tscn` |
| A11 | `scenes/deep_research_depths.tscn` | `scenes/regions/deep_research_depths.tscn` |
| A12 | `scenes/inner_city.tscn` | `scenes/regions/inner_city.tscn` |
| A13 | `scenes/terminal_anomaly.tscn` | `scenes/regions/terminal_anomaly.tscn` |

## Root-level scenes that are not primary region entries

These remain separate until their ownership and every reference are audited:

- `scenes/boot.tscn` — project launch scene; keep path stable.
- `scenes/prologue_exterior.tscn`, `scenes/mite_house.tscn` — staged C01 arrival scenes.
- `scenes/village_backhill.tscn`, `scenes/village_graveyard.tscn`, `scenes/rebel_camp.tscn` — A1 auxiliary/visit scenes.
- `scenes/old_drain_exploration.tscn` — shared C24 route segment, not a region entry.
- `scenes/royal_tomb_boss.tscn` — optional boss arena OB01, not A8's region entry.
- `scenes/a5_assembled_region.tscn` — legacy/assembled A5 scene; review ownership separately before moving.
- `scenes/cliff_exploration.tscn` — cliff exploration scene; review ownership separately.
- `scenes/ancient_research_lab.tscn` — auxiliary research scene; review ownership separately.

## Required pre-move audit

Before moving any entry scene, update and verify all path consumers in:
- `scripts/core/world_state.gd` (region ID mapping and resume destinations)
- `scripts/levels/greybox_world_region.gd` (doors, exits and route destinations)
- `tools/validate_graybox_scene_wiring.py` (acceptance assertions)
- `tools/world_map_topology.json` and other data contracts
- Every other `.gd`, `.tscn`, `.tres`, `.json`, `.py`, and `project.godot` reference on this branch.

The first reference scan found direct consumers in the files above. It is not yet a complete repository-wide scan, so primary entry scenes have deliberately not been moved in this batch.

## Non-negotiable preservation

- Keep A2 R01–R06 as six separate authored room scenes.
- Keep all 22 legacy A5 room scenes; do not merge or delete them during directory cleanup.
- Preserve each moved scene's node tree and attached scripts.
- A GitHub path/reference check is not a substitute for Godot 4.6.1 editor and runtime acceptance.
