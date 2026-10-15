# A8 spatial, encounter placeholder, and recovery contract / A8 空间、战斗占位与恢复契约

> Branch: `development`  
> Status: source review in progress; Godot 4.6.1 runtime acceptance is **pending**.  
> 本文是地图阶段契约，不代表碰撞、跳跃或死亡恢复已经在 Godot 中验收通过。

## 1. A8 scene and route facts / 场景与路线事实

- Scene: `scenes/royal_tomb.tscn`; it binds the shared graybox to `region_id = A8`, `location_id = royal_tomb`, `map_width = 2600`.
- Shared floor: `floor_y = 540`; the Hero spawn origin is treated as the feet position by the region controller.
- C13 A8 arrival: side `maintenance_shaft_entry`, x=190, y=`floor_y - 120` (420). Authored support ledges include Rect2(80,420,150,18) and Rect2(240,420,170,18). The spawn is on the ledge layer and away from the western door focus; this is a source-level geometric match, not proof of safe landing in-engine.
- C13 A7 return: side `maintenance_shaft_return`, x=`map_width - 160` (2440), y=`floor_y - 120` (420). A7 has authored ledges Rect2(2140,460,110,18) and Rect2(2200,420,370,18). Verify the actual jump chain and ground bypass in-engine.
- C14 A8↔A9 is a bidirectional ordinary route. Verify both doors, both spawn-side mappings and actual supported landings; its topology entry currently has no dedicated spatial_contract, so do not infer precise coordinates from topology alone.
- C15 is a separate conditional A8↔A11 route. It must remain distinct from H06 (the royal-name gallery). Gate discovery, gate opening and region entry are separate states; C19 must not unlock C15's return.
- A8 currently spawns `A8_Cultist_01` as an ordinary encounter. It is **not** a Boss implementation or a defined Boss arena.

## 2. Door focus / interaction-range acceptance

The shared door uses an Area2D and is eligible only when the Hero is inside its collision area and the interaction-focus manager selects it. The E prompt is therefore determined by the actual Area2D shape and focus arbitration, not just the visual doorway.

For each A8 door (C13 return, C14 to A9, C14 return, C15 gate, H06 gate, C07 waterway and nearby rest point):
1. Approach from the intended platform and confirm the prompt appears before the Hero overlaps the door visual.
2. Stand on the floor directly below an elevated door; confirm the prompt does not appear through vertical distance or accidental Area2D reach.
3. Move between adjacent doors/gates and verify focus does not jump to a different route unexpectedly.
4. Confirm the C13 arrival point does not auto-focus the west return door, and each return spawn is outside the source door's trigger.
5. Check both facing directions and test at the platform edges, not only at its center.
6. Repeat after a scene reload and with Resonance Sight toggled for C15/H06.

## 3. Map-level encounter placeholder / 地图战斗占位

Until encounter design is approved, A8's cultist remains a normal placeholder encounter. Do not add a Boss AI, arena lock, Boss health tuning or new combat framework in this map pass.

When a future Boss location is selected, the map contract must record:
- stable encounter/arena ID and region ID;
- arena bounds and entry approach;
- safe entry spawn and post-defeat return/exit anchor;
- which doors are disabled during the encounter, if any, and the exact unlock condition;
- whether a death resets the encounter and how the Hero returns to a safe spawn;
- whether victory is persistent across scene reload/save and how the return route behaves;
- a debug marker visible in map-test mode that explicitly reads “COMBAT PLACEHOLDER — NOT IMPLEMENTED” until the encounter is actually implemented.

No arena lock or Boss victory flag should be wired into A8 yet. `WorldState.boss_defeated` and `mark_boss_defeated()` exist globally, but their existence does not establish an A8-specific Boss contract.

## 4. Death recovery and return contract / 死亡恢复与回程

Current source behavior to validate:
- `_spawn_hero()` sets the current region spawn as the checkpoint.
- Region death handling and checkpoint restore must be inspected in the runtime path; do not assume that a saved checkpoint is restored correctly just because it is set.
- Main-region rest points are authored separately; hidden regions intentionally do not receive a free rest point by default.

Required acceptance:
1. Enter A8 from A7 via C13. Die before touching the rest point. Confirm the Hero returns to the documented A8 checkpoint, not to a stale coordinate from A7 or another region.
2. Rest at the A8 rest point, leave to A9 and return. Confirm the expected region and spawn side are used.
3. Die after activating the rest point. Confirm the checkpoint is the rest point, and the Hero is not trapped inside a door trigger or spawned below the intended ledge.
4. Test C13 and C14 after death/reload; neither should change direction or become blocked due to transient spawn-side state.
5. For a future Boss, test death before victory, death after victory, reload after victory, and re-entry. A defeated Boss must not respawn unless the approved encounter design explicitly says it should.
6. Verify hidden routes independently: opening C15 must enable only its own A11 return; opening C19 must enable only its own cathedral return; H06 must retain its separate condition/return behavior.
7. Record runtime evidence (scene, route, spawn coordinates/log, expected result, actual result) for every pass/fail.

## 5. Connection sweep: C11/C13/C14/C15/C19/C21/C22

- C11 A6↔A7: verify ground-level door trigger and both return points; continuous floor means the door's interaction area must not accidentally behave like an edge transition.
- C13 A7↔A8: elevated bidirectional maintenance-shaft route. Verify two-step access, landing support on both ends, trigger isolation and no ground-lane bypass.
- C14 A8↔A9: bidirectional main route; confirm matching destinations and spawn-side values on both ends.
- C15 A8↔A11: conditionally bidirectional; requirements are Resonance Sight, resonance ≥55, ancient exposure ≥2, and both `anomaly_bell_retiming` and `anomaly_erased_royal_name`. Its return is keyed to C15 itself.
- C19 A10↔A11: conditionally bidirectional; resonance ≥68, outer exposure ≥12, `outer_god_resonance`, and `anomaly_mirror_street_echo`. Its return is keyed to C19 itself.
- C21 A11→A13: terminal one-way entry gated by `physical_union_complete`; A13 must not add an ordinary return door.
- C22 A12→A13: terminal one-way entry gated by `reached_A12_via_A10`; A13 must not add an ordinary return door.

## 6. Static vs runtime boundary

Static source review can verify authored coordinates, route IDs, spawn-side branches, platform rectangles, topology direction and unlock conditions. It cannot prove collision shapes overlap as intended, jump arcs are reachable, the Hero can stand without slipping, Area2D focus radius is appropriate, or death/reload works in a running game.

Godot 4.6.1 runtime status: **NOT RUN / NOT ACCEPTED in this pass**. Do not close these map connections until the above in-engine checks are recorded.
