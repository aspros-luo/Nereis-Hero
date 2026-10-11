# Map-First Content Completion Roadmap

> Status: implementation roadmap and static source contract. The map is designed as a Dark Souls 1-style interconnected box world, with the early branching structure of a hub that opens multiple directions. This is not a linear chapter sequence.
>
> **Important:** topology consistency and source-level geometry checks are not Godot runtime acceptance. Collision, jumps, interaction focus, scene transitions, saves, death recovery, and real shortcut value must still be tested in Godot 4.6.x.

## Completion rules

Every major region should provide:

1. **Spatial identity:** a memorable landmark, a recognizable silhouette, and more than one elevation or route where appropriate.
2. **Exploration choices:** a main route plus a branch, alternate approach, or optional discovery. Avoid reducing every region to a horizontal corridor.
3. **A meaningful return:** a loop, a door opened from the far side, a lift, a drain, or a persistent resonance bridge that reduces backtracking.
4. **Environmental narrative:** visual evidence, item text, enemy placement, and short fragments rather than exposition-heavy dialogue.
5. **Honest gates:** a hidden entrance must have a legible clue, a persistent opened state, a valid far-side return, and no accidental bypass of a story gate.
6. **A runtime acceptance record:** a scene existing in the repository is not enough to mark it playable.

## World-map constraints

- A1 is an early hub, not a mandatory one-way corridor. Players should gradually discover routes toward the forest, abandoned city, drains, old pilgrimage road, and village well.
- Regions can be built in batches, but the player-facing world must preserve loops, vertical layering, landmarks, and meaningful shortcuts.
- Resonance / Sight can reveal routes inside already visited maps, not only the eight hidden subareas H01–H08.
- Debug controls are for acceptance only. They must not lower the normal progression requirements or permanently open routes by themselves.
- The three canonical endings remain **凡人之墓**, **永恒乐园**, and **烈火天罚**. Hidden routes must not flatten their evidence chains or ending conditions.

## Local resonance bridges

Every bridge requires active Resonance Sight and the listed resonance threshold. Pressing E permanently anchors the bridge through the shared hidden-path state. The bridge stays local to its region and must not teleport the Hero or replace a story gate.

| Region | Route ID | Threshold | Span (x) | Elevation (y) | Purpose / boundary |
|---|---|---:|---:|---:|---|
| A2 | `A2_BELLGRAVE_CANOPY_CROSSING` | 20 | 1380–1610 | 328 | Reconnects upper bell-grave ledges on a return visit; does not open H02. |
| A3 | `A3_THIRD_STREET_ROOFLINE` | 28 | 1320–1690 | 400 | Reconnects the erased street; does not enter H03. |
| A4 | `A4_OLD_STONE_AQUEDUCT` | 36 | 1650–1935 | 335 | Reconnects the dry aqueduct; does not enter H04. |
| A5 | `A5_BURIED_STANDARD_CROSSING` | 24 | 880–1220 | 390 | Crosses the trench beneath the buried standard; does not bypass the fortress gate. |
| A6 | `A6_SILENT_BELL_SERVICE_WALK` | 32 | 1250–1510 | 290 | Reconnects the bell-tower service walk; does not bypass H05 or the story exit. |
| A7 | `A7_PRISON_MAINTENANCE_CROSSWALK` | 30 | 1280–1530 | 340 | Connects prison maintenance levels; does not open the royal tomb gate. |
| A8 | `A8_ERASED_REGENT_GALLERY` | 40 | 1240–1490 | 330 | Connects erased royal-name ledges; does not enter H06. |
| A9 | `A9_RAIN_REFLECTION_ROOFWALK` | 44 | 1260–1520 | 332 | Reconnects abandoned roofs; does not replace H07 or the royal transport gate. |
| A10 | `A10_CHOIRLESS_UPPER_GALLERY` | 48 | 675–960 | 307 | Connects chapel / choir ledges; does not replace either cathedral exit or C19. |
| A11 | `A11_SECOND_OBSERVER_SPAN` | 56 | 1350–1800 | 285 | Connects ancient observation ledges; does not unlock H08 or bypass C15/C19. |
| A12 | `A12_CROWN_WALL_WALK` | 62 | 1400–1940 | 323 | Connects upper palace ledges; does not alter throne access or ending gates. |

The runtime controller, machine-readable topology, static checker, and Chinese roadmap must stay synchronized when a route is changed. The static checker also verifies that each bridge endpoint remains near a platform in its region. That proximity check is an estimate, not proof of a usable jump or collision-safe landing. Temporary bridges also retain their collision and visual while the Hero is standing on them after Sight expires, then disappear once the Hero leaves.

## Hidden-area and ending gates

- H01–H08 remain optional discoveries with distinct resonance thresholds and evidence.
- C15 and C19 must retain their own source / exposure requirements and alternate-entry semantics.
- H08's ending exit remains gated by the physical-union event and delegates ending selection to the ending evaluator.
- The endings must not be made available merely by using debug sight or opening a local bridge.
- Keep hidden regions riskier than main regions; do not add free rest points to H01–H08 without a deliberate design reason.

## Acceptance checklist

### Static repository checks

- [ ] All A0–A12 and H01–H08 scene references resolve.
- [ ] Main-route connections, reverse exits, and alternate-entry conditions match runtime wiring.
- [ ] Every local route ID is unique and exists in runtime code, topology, and validator expectations.
- [ ] Bridge threshold, span, elevation, active-sight requirement, and persistent-open contract agree across files.
- [ ] Both bridge endpoints are near a platform in the region's parsed platform layout.
- [ ] H01–H08, C15, C19, C10, C18, H08 ending gate, and resume-spawn contracts remain intact.
- [ ] No accidental route bypasses a story gate or silently weakens a normal progression condition.

### Godot 4.6.x runtime checks — still required

- [ ] Fresh boot, new game, continue, save/load, death recovery, and return-to-title.
- [ ] Movement, jumps, falls, collision edges, moving enemies, combat input, and input lock during dialogue.
- [ ] Each local bridge: hidden state, sight reveal, threshold rejection, E focus, permanent open, scene re-entry, and return traversal.
- [ ] Every main-region exit and far-side shortcut opens in the correct direction and lands away from overlapping interaction prompts.
- [ ] F5/V acceptance path reveals routes for inspection but does not auto-open them or persist debug-only unlocks.
- [ ] H01–H08 evidence sequence and all three endings are reachable only under their intended conditions.
- [ ] Simplified Chinese, Traditional Chinese, English, and Japanese UI / narrative strings are checked in-game.

## Current status

The eleven local resonance routes are registered in runtime code, topology, and the static checker. All eleven route prompts, titles, and narrative bodies also have Simplified Chinese, Traditional Chinese, and Japanese translations; English remains the source text. Door proximity state is also preserved across dialogue input locks so an in-range door does not become unusable until the Hero exits and re-enters its trigger. Source-level endpoint-to-platform checks pass for all ten routes. **Godot runtime acceptance remains pending**: this work does not claim that the bridge collisions, jump arcs, interaction focus, or real shortcut loops have been tested in-engine.
