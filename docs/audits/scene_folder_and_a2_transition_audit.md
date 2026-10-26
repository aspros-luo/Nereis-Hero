# Scene Audit — A2 Room Scene Consolidation

Branch: `feature/story-map-progression`

## Scope and limits

Static source inspection only. No claim of Godot editor import, runtime, or gameplay acceptance.

## Completed in this pass

- Consolidated R01–R06 into one playable `.tscn` per room under `scenes/rooms/a2_fog_forest/runtime/`.
- Removed the six superseded standalone terrain scenes. Each playable room has an editor-visible `Terrain` child containing the authored platforms, artwork, decoration and `RoomMarkers`.
- Kept Hero, Narrative, HUD, room metadata and fixed left/right boundary bodies in each room scene.
- Preserved R05's `RegionRestPoint_A2` instance.
- Updated `scripts/levels/a2_room_runtime.gd` to resolve marker anchors through `Terrain/RoomMarkers`.
- Added editor-visible `InteractionDoor` scene instances for all fixed A2 exits. Runtime now configures their destination, prompt and progression metadata instead of creating duplicate fixed door areas.
- Added editor-visible `Area2D` drop triggers for R01→R04 and R03→R04. Runtime reuses these nodes and binds the transition callback instead of duplicating them.
- Kept R05→A5's door authored but disabled by default; the existing progression flag controls whether runtime enables it.
- R01's authored terrain is scaled 1.25x to preserve the 1792×1200 art-space to 2240×1500 room-space contract. Its safe-drop Area2D is authored at the transformed marker position.

## Static checks completed

- All six room IDs in `ROOM_SCENE_PATHS` resolve to existing R01–R06 playable scene paths.
- Each consolidated scene has one room root, one `Terrain` node, Hero, and two authored `RegionBoundary_*` bodies.
- Scene `load_steps` values match the declared external resources and subresources.
- External and subresource references resolve within each scene text.
- Node parent paths are valid and have no duplicate full node paths.
- Every fixed exit configured by `_spawn_room_exits()` has a matching authored `Door_<marker>` instance and a matching `Terrain/RoomMarkers` anchor.
- R01 and R03 have the authored drop Area2D nodes expected by the runtime transition names.
- R05's rest point is preserved and its A5 exit starts disabled.

## Remaining audit findings

### Room-to-room geometry is not proven by text inspection

The room graph and marker names line up statically, but this cannot prove that the player can reach each marker, that the collision gap is truly open, or that a door is reachable from the intended platform. R01's safe drop and R03's drop still require in-editor collision inspection and gameplay testing.

### Cross-region contracts require manual verification

- R06→A3 uses spawn side `city_canopy_entry`, which has an A3 spawn mapping in `greybox_world_region.gd`.
- R05→A5 uses `old_pilgrim_highroad`, which has a special A5 spawn mapping.
- The actual C03/C04 route continuity, H02 return, and persistence of discovery state still need gameplay verification.

### Dynamic stateful gates remain code-driven

The H02 resonance gate is still created at runtime because its state/requirements are conditional. That is intentional for this pass; its visual placement and collision still need manual inspection.

### R06 low-to-high return path — geometry correction

- Static collision-top review found the earlier R06 climb gaps were 100–160 px, exceeding the previously measured Hero jump apex of about 96.6 px. That made the low entry's return to the upper R05/A3 routes doubtful or impossible without runtime proof.
- Adjusted the climb ledges in `a2_r06_room.tscn` and added two editor-visible upper steps. The intended collision-top sequence is now approximately y=792 → 712 → 632 → 572 → 492 → 412 → 332, with each rise at most 80 px.
- Adjacent platforms overlap horizontally, so the route is intended to form a continuous upward climb from R06's lower entry to the upper floor. This is a source-level geometry correction, not a claim of verified jump reachability; Hero collision dimensions, coyote time, and real jump behavior still need local playtesting.

### Cross-region state audit

- R06's `a2_r06_c03_return` destination maps to `EntryC03Return`; R04's `a2_r04_ravine_return` maps to `EntryRavineReturn`; R05's `a2_r05_ravine_return` maps to `EntryRavineReturn`; and C04's `a2_r05_c04_return` maps to `EntryC04Return`.
- H02 uses `a2_r04_h02_return` → `EntryH02Return`. Hidden-region discovery/open/entry arrays are serialized by `WorldState.save_game()` and restored by `load_game()`; the room exploration/shortcut/item arrays are saved separately by `save_room_state()`.
- These mappings and serializers are present in source. Whether the correct reverse door appears after reopening a saved game still requires an end-to-end save/load test.

## Acceptance checklist

- [x] One editable playable scene per room (R01–R06).
- [x] Terrain, markers, Hero, HUD, Narrative, fixed room boundaries and fixed exit doors are visible in the scene tree.
- [x] R01→R04 and R03→R04 drop Area2D nodes are visible in the scene tree.
- [x] Room path, marker, resource-reference, node-parent and `load_steps` static checks pass.
- [x] Runtime configures authored doors and reuses authored drop areas.
- [x] R05 rest point preserved; A5 exit remains progression-gated.
- [ ] Godot 4.6.1 editor import passes without parse/resource errors.
- [ ] R01 safe drop reaches R04; other void falls remain lethal.
- [ ] R03 drop reaches R04; R04↔R06 and R05↔R06 routes work at their intended heights.\n- [ ] R06 low-entry climb reaches the upper R05/A3 route with the real Hero controller.
- [ ] C03, C04 and H02 cross-region/return routes and saved discovery state verified.
