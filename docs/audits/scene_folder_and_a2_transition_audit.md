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


### A3 fixed clue and exploration pickup moved into the scene tree

- `scenes/regions/forgotten_city.tscn` now contains editor-visible instances for the fixed `anomaly_erased_street_sign` clue and `third_street_survey` pickup, including their saved positions and IDs.
- Removed the A3 branches that created these objects at hard-coded runtime coordinates.
- Added callback binding for scene-authored resonance sources; this binds progression behavior only and does not instantiate or reposition clue nodes.
- Static check: both nodes exist as direct scene children with the expected properties; the A3 spawn branches are absent. Godot import and interaction acceptance are still pending.


### A4, A6 and A8 fixed anomaly clues moved into authored scenes

- Added the fixed resonance clue instances to `sewer_reservoir.tscn`, `monastery_tower.tscn`, and `royal_tomb.tscn`, preserving their IDs, positions, resonance targets, and ancient-exposure thresholds.
- Removed the matching region-specific clue creation branches from `greybox_world_region.gd`. The shared authored-source callback binder connects them to progression handling.
- Static checks confirm each source is represented in its region scene and no longer spawned by its former region branch. Godot editor import and interaction acceptance remain pending.


### A7, A9 and A10 fixed anomaly clues moved into authored scenes

- Added the prisoner register clue to A7, the mirror-street echo to A9, and the double-sealed reliquary clue to A10 as editor-visible instances.
- Preserved each source ID, displayed text, world position, resonance threshold, and A9's outer-exposure / outer-god requirements.
- Removed these three region-specific runtime creation branches; the shared callback binder handles progression signals only.
- Static text checks passed; Godot editor import and runtime interactions remain unverified.


### A11 and A12 fixed anomaly clues moved into authored scenes

- Added the observer-reaction clue to A11 and the king's unopened letter to A12 as fixed scene instances.
- Preserved A11's resonance target, ancient-exposure floor, and outer-exposure reward; preserved A12's resonance target and description.
- Removed both runtime spawn branches. Source callbacks remain bound by the shared authored-source binder.
- Static source checks only; Godot editor/runtime validation remains pending.


### A5 battlefield clue moved to the assembled region scene

- Added the fixed battlefield-orders clue as a direct child of `old_battlefield.tscn` at its assembled world coordinate, so its placement is visible without opening or running a script.
- Removed the old runtime placement calculation from the region source table.
- The A5 assembled-region setup now binds authored clue callbacks after Hero/UI creation. This preserves the clue's ability to find the sibling Hero while leaving its position authored in the scene.
- Static validation only; the saved coordinate and interaction must still be checked in Godot.


### H01–H04 fixed clues moved into their hidden-region scenes

- Added the first four hidden-region clue nodes to their terrain-owning `.tscn` files and removed their runtime spawn branches.
- Their saved IDs, descriptions, resonance targets and authored positions are preserved.
- Static source checks only; Godot editor import and progression interaction remain pending.


### H05–H08 fixed clues moved into their hidden-region scenes

- Added the remaining four hidden-region clue nodes to the corresponding `.tscn` files and removed their runtime spawn branches.
- The entire H01–H08 clue set is now scene-authored; the shared runtime only binds their progression signals.
- Static source checks only; Godot editor import and interaction checks remain pending.


### A6/A8 fixed pickups are scene-authored, with progression handled as state

- A6's Bell Tower Winch Key is now an editor-visible pickup node. Its `required_achievement_flag` keeps it hidden and non-interactive until `defeated_A6_BellWarden_01` is recorded; runtime no longer creates it at the fixed coordinate.
- A8's Royal Mortuary Register is now an editor-visible pickup node, and its fixed-coordinate spawn branch has been removed.
- `world_item_pickup.gd` now supports an optional required achievement flag for authored conditional rewards. Existing pickups without that field retain their prior behavior.
- Static source checks only; test reward visibility after defeating the A6 boss and collection persistence in Godot.


### Legacy A2 assembler neutralized

- `scripts/levels/a2_authored_terrain.gd` referenced six legacy A2 room paths that no longer exist in the current tree and could instantiate fixed room geometry under a region parent.
- The file now contains no stale `preload()` references, no fixed-position mutations, and no `PackedScene.instantiate()` / `add_child()` terrain assembly. Calling its former `configure_platforms()` entry point fails loudly instead of generating geometry.
- The six current runtime room scenes remain untouched. This is a source-level safety guard, not a claim that the retired script has been removed from every external caller; reference tracing and Godot import validation remain pending.


### A5 rest point migrated to the editor-authored scene tree

- Added `RegionRestPoint_A5` as a direct `RestPoint` instance in `scenes/regions/old_battlefield.tscn`, at the existing contract-derived R12 hub coordinate (17740, 2700).
- The shared controller now validates the authored rest point against the R12 hub and fails loudly if the node is missing or misplaced; it no longer instantiates or repositions the fixed A5 rest point.
- Static check: A5 room contract still contains 22 rooms; the rest node is a scene instance, and the controller contains no `REST_POINT_SCENE.instantiate()` in the rest-point method. Godot import/runtime validation remains pending.


### A5 legacy scene path redirected to the authored production region

- `scenes/a5_assembled_region.tscn` previously declared `use_a5_room_assembly = true` on a root-only scene with no 22 room children, which conflicts with the controller's new authored-child contract.
- Kept the legacy resource path for compatibility, but converted it to an inherited instance of `scenes/regions/old_battlefield.tscn`. Opening either path now exposes the same authored room tree rather than a second incomplete assembly root.
- This avoids deleting a potentially referenced scene while removing its contradictory root-only implementation. Static source validation only; local Godot import remains pending.


## A5 scope rollback — 2026-10-27

- Reverted `scenes/regions/old_battlefield.tscn` to one main A5 region scene. The 22 `A5_R##` child instances and their 22 room resource declarations are no longer part of the active region scene tree.
- Restored the main region bounds to 2600×720 and disabled `use_a5_room_assembly`. The fixed anomaly clue and rest point remain as scene-authored instances inside the main region.
- Updated the rest-point validator to check the single-scene A5 contract rather than requiring the removed R12 hub.
- A5's room files and room-streaming contract are retained as inactive source material for now because the legacy `scenes/world/world.tscn` streaming path and its validators still reference them. They are not instantiated by `old_battlefield.tscn`. Remove those orphaned files only after that separate legacy entry path is retired; otherwise opening it would fail to load rooms.
- Static source review only; no Godot editor/runtime acceptance was run.


### A0 fixed progress-barrier position is scene-owned — 2026-10-27

- Removed the runtime assignment that moved `ProgressBarrier_Left/Right` to hard-coded coordinates.
- The barrier nodes and their collision shapes remain authored in `scenes/regions/escape_prologue.tscn`; encounter logic only toggles visibility and collision enabled state.
- Static source inspection confirms the selected barrier is still resolved by its authored node name. Godot editor/runtime acceptance remains pending.


### A0 progress-shutter visual migrated into its scene — 2026-10-27

- Added a visible `ShutterVisual` node subtree to the shared `scenes/rooms/prologue_progress_barrier.tscn`, including the panel, caps, rails and cross bars.
- Removed runtime `_draw_security_shutter()` drawing; the authored barrier instance now owns both the fixed visual and collision shape. Encounter logic controls visibility/collision state.
- Static source checks only; Godot scene import and visual alignment still require local editor/runtime acceptance.


### A0/A1/A2 priority audit pass — 2026-10-27

- **A0:** Progress-barrier visuals are authored as child nodes in `prologue_progress_barrier.tscn`; its collision shape is already authored disabled by default. `escape_prologue.gd` enables it only when the ambush phase calls for it. The barrier's fixed position is scene-owned. Static source check only.
- **A1 finding:** `village_hub.gd` sets the persistent checkpoint to the village hearth on every entry, then separately places the Hero based on the incoming return side. This may be intentional as the village hub checkpoint, but it needs a death/continue acceptance check against the intended return-point behavior before changing it. Baseline NPCs are authored in the scene; progression NPCs are delegated to `WorldEventDirector`.
- **A2 finding:** `a2_room_runtime.gd` binds authored doors and validates authored drop Areas, but fixed room clues and rewards for R03/R05/R06 are still created through inherited runtime helpers (`_spawn_source` / `_spawn_world_item_pickup`). These should be migrated to visible scene nodes after verifying persistence and conditional-reward behavior. The R03/R05/R06 scenes already contain editor-visible terrain, markers, boundary bodies, and door instances.
- **A2 finding:** room-wide ambience and debug overlays are instantiated at runtime; these are dynamic/support layers, not fixed traversal geometry. Do not remove them as part of fixed-map cleanup.
- **Not yet verified:** Godot 4.6.1 scene import, parser, runtime collision state, combat progression, room transitions, and save/continue behavior.


### A2 fixed clues and rewards migrated to room scenes — 2026-10-27

- R03 now owns the bell anomaly and burial token as visible scene instances.
- R05 now owns the pilgrim echo, waybill, and conditional charred church seal. The seal remains present in the editor and uses its existing `required_achievement_flag` to control availability.
- R06 now owns the canopy waymarker fragment as a visible scene instance.
- `a2_room_runtime.gd` no longer creates these fixed clues/rewards at runtime; it binds authored clue callbacks and reports missing expected nodes. Pickup collection/persistence remains delegated to the existing pickup component.
- Static text checks are not a substitute for Godot 4.6.1 import/parser/runtime acceptance.


### A2 H02 gate migrated to an authored scene instance — 2026-10-27

- Added `HiddenBellChamberGate` as an editor-visible instance in `a2_r04_room.tscn`, anchored to the existing `H02Gate` marker.
- Authored the bell body, clapper, resonance arcs and opened descent marks as `Line2D` scene children. The gate script toggles reveal/open groups and no longer procedurally draws the H02 motif.
- Replaced runtime gate instantiation and position assignment with validation/configuration of the existing scene instance.
- Other legacy hidden-gate motifs still use procedural rendering and are outside this A0–A2 pass.
- Static source checks only; Godot 4.6.1 import, scene-tree validation, and interaction acceptance remain pending.


- **Layering follow-up:** Set the authored H02 gate instance to `z_index = 2` so its bell motif renders above the R04 doorway silhouette (`H02GateVisual`, z-index 1). This is a source-level ordering check; visual appearance still needs editor/runtime confirmation.
