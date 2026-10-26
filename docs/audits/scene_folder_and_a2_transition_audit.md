# Scene Audit — A2 and World Scene Organization

Branch: `feature/story-map-progression`

## Scope and limits

Static source inspection only. No claim of Godot editor import, runtime, or gameplay acceptance. This audit focuses on A2's six terrain scenes and six runtime wrappers, plus reusable world interactions.

## Confirmed structure

- R01 has been consolidated into `scenes/rooms/a2_fog_forest/runtime/a2_r01_room.tscn`: terrain, marker anchors, Hero, Narrative, HUD, and fixed boundary bodies are all visible in one editable scene tree. Its former standalone terrain file was removed after consolidating the room.
- R02–R06 still use separate terrain scenes and runtime wrappers under `scenes/rooms/a2_fog_forest/` and `scenes/rooms/a2_fog_forest/runtime/`.
- The R01 pilot keeps the terrain under an editor-visible `Terrain` node (scaled 1.25x) and moves marker lookup to `Terrain/RoomMarkers`.
- The terrain scenes already contain `RoomMarkers` for entries/exits and drops. This gives a grounded source for migrating fixed transitions into authored scene nodes.
- R05's rest point is already a scene instance in the wrapper; it should remain there unless the design calls for it to belong to the terrain itself.

## Findings

### A2 fixed transitions are not authored scene nodes yet

`scripts/levels/a2_room_runtime.gd::_spawn_room_exits()` creates the fixed doors for R01–R06 by reading `RoomMarkers`. R01 and R03 drop transitions are also instantiated by script. The marker exists in the editor, but the actual interaction/Area2D and collision shape do not.

**Required change:** add reusable door/drop-transition instances at the authored marker positions in the relevant terrain or wrapper scenes; expose route destination, spawn side, prompt, and conditional unlock configuration as scene properties; connect signals/configuration from the runtime script without duplicating the nodes.

### Runtime wrappers still create fixed region boundaries

Each of the six wrappers contains two `RegionBoundary_*` StaticBody2D nodes created at runtime by `_create_boundaries()`. These are structural bounds, not transient effects.

**Required change:** decide and document whether the left/right bounds belong in each wrapper or in the terrain scene. Prefer authored `StaticBody2D` + `CollisionShape2D` nodes when the bounds are part of the room's fixed geometry. Avoid having both scene-authored and script-generated duplicates.

### Folder migration must be atomic with references

The six terrain scenes are referenced by their wrappers; the runtime script maps room IDs to wrapper paths; other world-state, test, or documentation files may also refer to these paths. Moving files before a repository-wide reference audit risks broken `res://` paths and stale saved-scene references.

**Migration plan:** keep current paths until all references have been enumerated; then move the six terrain scenes and six wrappers in one coordinated change, update all `ExtResource`, preload, room-path map, test, and documentation references, and run static path/load-step validation.

### A5 remains excluded from mechanical migration

`scenes/a5_assembled_region.tscn` and `scenes/old_battlefield.tscn` still depend on the legacy A5 assembly route. Do not reorganize or freeze the rejected 22-room layout as if it were the final authored map.

## Target organization

```
scenes/
  regions/
    a2/
      rooms/       # authored R01-R06 terrain, markers, fixed room geometry
      runtime/     # playable wrappers: Hero, camera, HUD, save/transition orchestration
    terrain/       # only terrain scenes genuinely shared by multiple regions
  world/
    interactions/  # reusable doors, gates, levers, drop transitions
    props/         # reusable non-interactive visual props
```

The README files under `scenes/regions/` document this target. Scene files have not yet been moved; compatibility paths remain unchanged.

## Acceptance checklist

- [ ] Every `res://` scene/script/resource path resolves after migration.
- [ ] R01 consolidated scene has no duplicate terrain wrapper and all marker paths resolve.
- [ ] Consolidate R02–R06 using the validated R01 pattern after static and editor acceptance.
- [ ] Each fixed exit/drop trigger exists visibly in the editor scene tree.
- [ ] No fixed exit/drop is duplicated by runtime instantiation.
- [ ] Story/save-state conditions still control conditional exits.
- [ ] R01's intended safe drop reaches R04; other void falls remain lethal.
- [ ] R05 rest point remains reachable and does not duplicate.
- [ ] Godot 4.6.1 editor import and manual room-transition acceptance pass.
