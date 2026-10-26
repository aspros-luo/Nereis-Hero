# Scene Audit — A2 Room Scene Consolidation

Branch: `feature/story-map-progression`

## Scope and limits

Static source inspection only. No claim of Godot editor import, runtime, or gameplay acceptance.

## Completed in this pass

- Consolidated R01–R06 into one playable `.tscn` per room under `scenes/rooms/a2_fog_forest/runtime/`.
- Removed the six superseded standalone terrain scenes. Each playable room now has an editor-visible `Terrain` child containing the authored platforms, artwork, decoration and `RoomMarkers`.
- Kept Hero, Narrative, HUD, fixed left/right room boundary bodies and room-level metadata in the same scene.
- Preserved R05's `RegionRestPoint_A2` scene instance.
- Updated `scripts/levels/a2_room_runtime.gd` to resolve marker anchors through `Terrain/RoomMarkers`.
- R01's authored terrain is scaled 1.25x to preserve the 1792×1200 art-space to 2240×1500 room-space contract. Its room boundary bodies remain at the playable room edges.

## Static checks completed

- All six room IDs in `ROOM_SCENE_PATHS` resolve to existing R01–R06 playable scene paths.
- Each consolidated scene has one room root, one `Terrain` node, Hero, and two authored `RegionBoundary_*` bodies.
- Scene `load_steps` values match the declared external resources and subresources.
- External and subresource references resolve within the scene text.
- The fixed exit/drop marker names used by `_spawn_room_exits()` exist in the matching room's `Terrain/RoomMarkers`.
- No `AuthoredRoom` wrapper instance remains. R05's rest point remains present.

## Remaining audit findings

### Fixed transitions are still created by script

`_spawn_room_exits()`, `_spawn_exit_door_at_marker()`, and `_spawn_drop_transition_at_marker()` still instantiate the fixed doors/drop areas at runtime. The destination marker anchors are editor-visible, but the actual `Area2D` and collision nodes are not yet authored in the scene tree.

Next change: convert fixed room-to-room doors and the two A2 drop transitions into editor-visible reusable scene instances, with target scene, spawn side, prompt and conditions configured per room. Keep genuinely state-dependent gates conditional, and prevent runtime code from duplicating authored instances.

### Cross-room route acceptance remains unverified

Static marker/path checks do not prove that the six rooms form a traversable map. R01→R04 and R03→R04 drop geometry, R04↔R06 and R05↔R06 height changes, C03/C04/H02 returns, spawn positions, collision boundaries and R05 rest-point reachability still require Godot 4.6.1 editor/runtime acceptance.

## Acceptance checklist

- [x] One editable playable scene per room (R01–R06).
- [x] Terrain, markers, Hero, HUD, Narrative and fixed room boundaries are visible in the scene tree.
- [x] Room path, marker, resource-reference and `load_steps` static checks pass.
- [x] R05 rest point preserved.
- [ ] Fixed exit/drop Area2D nodes authored in the scene tree; runtime duplication removed.
- [ ] R01's one safe drop reaches R04; other void falls remain lethal.
- [ ] R03 drop reaches R04; R04↔R06 and R05↔R06 routes work at their intended heights.
- [ ] C03, C04 and H02 cross-region/return routes and saved discovery state verified.
- [ ] Godot 4.6.1 editor import and manual gameplay acceptance pass.
