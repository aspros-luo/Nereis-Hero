# Scene Folder Structure

This folder is the home for region-owned map scenes. Keep scene files grouped by gameplay region, and keep reusable world interactions separate from region content.

## Conventions

- `scenes/regions/<region_id>/`: region-specific scene assets and terrain.
- `scenes/regions/<region_id>/rooms/`: authored room terrain scenes and their room-local markers.
- `scenes/regions/<region_id>/runtime/`: playable room wrappers that own Hero, camera, HUD, respawn, and transition wiring.
- `scenes/world/interactions/`: reusable interaction scenes such as doors, gates, levers, and drop transitions.
- `scenes/world/props/`: reusable non-interactive visual props.
- `scenes/characters/`, `scenes/ui/`, and `scenes/core/`: character, UI, and game-system scenes respectively.

## Scene ownership rules

1. Fixed terrain, platforms, collision bodies, room markers, fixed exits, and fixed rest points should be visible as authored nodes in the relevant `.tscn`.
2. Scripts may configure authored nodes at runtime: connect signals, apply story/save-state visibility or enabled state, and select a target scene/spawn side.
3. Scripts should not instantiate fixed map geometry or fixed exits as a substitute for scene authoring. Runtime instantiation is reserved for genuinely transient/state-created content (for example, a temporary effect or a reward that only exists after a condition).
4. Do not move a scene without updating every `res://` reference and validating the affected scenes. Keep compatibility paths until all references have been migrated.
5. A5's rejected 22-room assembly is not a template for the new region layout.

This convention is being applied incrementally on `feature/story-map-progression`; it does not claim that the existing tree has already been fully migrated.
