# Demo and Debug Scenes

Standalone demonstration scenes that are not campaign region entry points live here. The first migration batch moved these authored scenes without changing their node trees:

- `church_final_demo.tscn`
- `combat_demo.tscn`
- `mite_resonance_demo.tscn`
- `village_defense_demo.tscn`

Their attached scripts remain under `scripts/levels/` for now; script reorganization is a separate step. Before moving additional scenes, update all `res://` references, launch/test instructions, and path-based validation contracts in the same change.
