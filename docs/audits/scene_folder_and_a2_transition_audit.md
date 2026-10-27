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

## Broader map-geometry audit

### Main route: authored terrain is the source of truth

- **A1 village:** `scenes/village_hub.tscn` contains scene-authored ground/boundary collision and its fixed POIs; `scripts/levels/village_hub.gd` configures interactive targets and story state.
- **A2:** `scenes/regions/ash_forest.tscn` points at the authored R01 runtime scene; R01–R06 each contain editor-visible terrain and collision nodes. `scripts/levels/a2_room_runtime.gd` still creates some conditional/runtime objects (for example a stateful H02 gate and compatibility fallback transitions), but fixed platforms are not generated by it.
- **A3/A4/A6/A7/A8/A9/A10/A11/A12/A13 and H01–H08:** legacy region scenes instance separate `scenes/terrain/terrain_*.tscn` resources, while the room-network scenes use `scripts/levels/contract_room_region.gd` and have terrain collision nodes directly authored in their own `.tscn` files. The controller reads and validates that geometry rather than generating platforms.
- **A5 assembled map (before this audit pass):** `scenes/regions/old_battlefield.tscn` had only a root controller; `greybox_world_region.gd` loaded and positioned the 22 authored `scenes/a5_rooms/a5_r*.tscn` rooms from `tools/a5_room_assembly_contract.json` at runtime. This was a fixed-layout editor-visibility violation even though each room had authored collision nodes. This pass migrates the 22 room instances and their transforms into `scenes/regions/old_battlefield.tscn`; the controller now requires and validates those editor-authored children rather than instantiating or repositioning them. The separate A5 room-test path in `greybox_world_region.gd` still contains code-generated platform/rubble/floor helpers and remains test-only.
- **A0:** the active prologue path uses `scenes/regions/escape_prologue.tscn`; its script creates the pursuer actor dynamically, but this inspection did not find evidence that it constructs the fixed map terrain.

### Remaining code-created geometry / cleanup candidates

- `scripts/levels/greybox_world_region.gd` retains generic `_create_floor()`, `_create_boundaries()`, `_add_ground_segment()`, and `_add_platform()` generation paths, plus the explicit A5 test-room platform/block generators. These are legacy/fallback/test paths. They should be guarded or retired once every reachable region is confirmed to use authored terrain; do not remove them until callers and debug/test entry points are mapped.
- `scripts/levels/a2_authored_terrain.gd` is a stale helper candidate: its `A2_ROOM_SCENES` preloads point at the six deleted pre-consolidation scene paths under `scenes/rooms/a2_fog_forest/`. The current `scenes/ash_forest.tscn` and `a2_room_runtime.gd` use the new `runtime/a2_r0*_room.tscn` files instead. This helper should be removed or migrated after confirming no script/test references it.
- Runtime-created doors, transitions, pickups, rest points, ambience and debug route overlays still exist in controllers. Those are gameplay/stateful objects, not fixed terrain; they should be reviewed separately for editor visibility when they are meant to be permanent level fixtures.

### Audit confidence

These conclusions come from the branch tree and targeted source/scene inspection. They are not a complete dynamic trace of every possible debug/test scene, and no Godot editor import or runtime test was run in this pass.

## Acceptance checklist

- [x] One editable playable scene per room (R01–R06).
- [x] Terrain, markers, Hero, HUD, Narrative, fixed room boundaries and fixed exit doors are visible in the scene tree.
- [x] R01→R04 and R03→R04 drop Area2D nodes are visible in the scene tree.
- [x] Room path, marker, resource-reference, node-parent and `load_steps` static checks pass.
- [x] Runtime configures authored doors and reuses authored drop areas.
- [x] R05 rest point preserved; A5 exit remains progression-gated.
- [ ] Godot 4.6.1 editor import passes without parse/resource errors.
- [ ] R01 safe drop reaches R04; other void falls remain lethal.
- [ ] R03 drop reaches R04; R04↔R06 and R05↔R06 routes work at their intended heights.
- [ ] R06 low-entry climb reaches the upper R05/A3 route with the real Hero controller.
- [ ] C03, C04 and H02 cross-region/return routes and saved discovery state verified.


## Follow-up audit — fixed map structure vs runtime state

### A5 fixed-layout correction applied in source

- Added all 22 room instances as direct children of `scenes/regions/old_battlefield.tscn`, with their size overrides and normalized editor-visible positions.
- Updated `_ready_a5_assembled_region()` to look up those children by stable room IDs, validate their geometry dimensions and calculate camera/world bounds from the authored positions.
- Removed runtime `load(...).instantiate()`, `add_child()`, and the runtime vertical repositioning loop from the production A5 assembly path.
- The JSON assembly contract remains the source for room identity/size checks and connection definitions; it no longer creates the fixed spatial layout.
- Static validation from source: 22 room entries in the contract, 22 corresponding authored scene instances, 23 total nodes in the region scene including its root, 23 external resources (controller plus 22 room scenes). No Godot import or runtime result is claimed.

### Remaining violations and audit work

- `greybox_world_region.gd` still contains generic `_configure_platforms()`, `_create_floor()`, `_create_boundaries()`, and A5 test-room helpers. The main A3/A4/A6–A13 scenes have an `AuthoredTerrain` child and return before those fixed terrain generators, but the legacy A0/A1/A5/test branches must be mapped to their actual entry scenes before any helper is retired.
- `_spawn_region_exits()` and `_spawn_exit_door()` create fixed exits at hard-coded coordinates for legacy region branches. Those doors are stable map fixtures and should be represented in the relevant `.tscn`; runtime should configure destination/progression state on those existing nodes. A2's production rooms already use authored doors, and the A2 runtime has now been tightened to report an error rather than synthesize a missing fixed exit or drop trigger. This makes incomplete scene authoring visible instead of silently masking it.
- `_spawn_region_sources()`, `_spawn_region_item_pickups()`, and parts of `_spawn_region_rest_point()` place repeatable, fixed-location world content through code. Conditional rewards may remain state-driven, but stable source/pickup/rest-point fixtures need an editor-visible node or an explicitly documented reason to be dynamic.
- `_spawn_h02_gate()`, encounter actors, ambience, and other stateful/runtime-only objects require per-method classification. A conditional gate may be code-instantiated only if the scene-design requirement is genuinely dynamic; fixed gate frame, position, collision footprint and visual anchor should still be authored.
- `scripts/levels/a2_authored_terrain.gd` still preloads six deleted pre-consolidation A2 scene paths. Its remaining references must be checked across all scripts and tools before deleting or rewriting it; do not remove it based only on the stale-looking preload list.
- `scenes/a5_assembled_region.tscn` is a second, root-only A5 assembly scene. Its references and launch/test usage must be traced before it can be removed or redirected.

### Acceptance status

- [x] A5 production room instances and fixed positions are visible in the formal region scene tree.
- [x] A5 production assembly controller no longer instantiates or repositions fixed room geometry.
- [x] Static text-level checks for room IDs, instance count, resource count and contract sizing.
- [ ] Godot 4.6.1 editor import and scene-tree inspection.
- [ ] A5 camera bounds, route transitions, spawn coordinates and internal connection overlays verified in local gameplay.
- [ ] Continue full audit of fixed exits, clues, pickups, rest points and remaining legacy/test generators.


### A2 compatibility fallbacks removed

- `_spawn_exit_door_at_marker()` now reports `AUTHORED_EXIT_MISSING` and returns if a fixed door instance is absent; it no longer creates a replacement `Area2D`.
- `_spawn_drop_transition()` now reports `AUTHORED_DROP_MISSING` and returns if the fixed drop trigger is absent; it no longer instantiates a transition node.
- This intentionally fails loudly for an incomplete room scene rather than hiding an editor-authoring defect with runtime node creation.
- The six production room scenes were previously statically checked to contain every door/marker and the R01/R03 drop triggers; this pass changes only the missing-node behavior. Local Godot import and runtime acceptance remain pending.


### A2 fixed door and drop geometry made read-only at runtime

- `_spawn_exit_door_at_marker()` no longer moves an authored door to the marker. It validates that the saved scene position and transformed marker agree, then applies destination and progression properties only.
- `_spawn_drop_transition()` no longer changes the authored trigger position, collision size, collision layer/mask, or monitoring flag. It validates those scene-authored properties against the route contract and only binds the transition callback.
- Mismatches now produce explicit `EXIT_POSITION_MISMATCH`, `DROP_POSITION_MISMATCH`, `DROP_SIZE_MISMATCH`, or `DROP_MONITOR_CONTRACT` errors instead of silently correcting scene layout at runtime.
- This is source-level validation only; the local Godot editor/runtime still needs to confirm the authored R01 scaled marker conversion and both drop areas behave as expected.
