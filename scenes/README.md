# Scene Directory Rules

This directory separates scene ownership from scene count. A region entry scene may compose one or more internal room scenes; room count is determined by level design, not by folder conventions.

## Categories

- `regions/`: primary A0–A13 campaign region entry scenes.
- `hidden_regions/`: optional H01–H08/H09 region entry scenes.
- `rooms/`: internal room scenes grouped by their owning region. Keep A2 R01–R06 here; do not merge them just to reduce scene count.
- `terrain/`: reusable authored terrain scene resources.
- `world/`: reusable doors, exits, checkpoints, pickups, interaction and transition components.
- `characters/`, `player/`, `ui/`, `core/`, `effects/`: reusable scene components grouped by runtime responsibility.
- `demos/`: standalone demonstrations and debug scenes that are not campaign region entries.

## Migration safety

Scene path moves must update every `res://` reference in `.tscn`, `.tres`, `.gd`, `project.godot`, data contracts and validation scripts. Keep the boot scene and autoload scene paths stable unless their consumers are updated in the same commit. Do not merge or delete A5 rooms as part of directory-only cleanup.

## Current migration status

The migration batches have moved six standalone demos and the two ending demonstration scenes into `demos/`, plus the world-map test menu into `debug/`. Their authored node trees and attached script paths are preserved; known launch, route, save/resume and validation references were updated. Primary and hidden region entry scenes remain at their existing paths pending a complete reference inventory. A2's six runtime rooms and all 22 legacy A5 room scenes remain untouched.
