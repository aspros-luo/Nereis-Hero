# Macro Map Spatial Layout and Connection Audit (Round 2)

> Status: macro-structure review draft v2. This is a design-data audit, not Godot runtime acceptance. It stabilizes relative directions, vertical layers, hub responsibilities, and the design contract for C01–C24 before small-map and story work.

## 1. Decisions

**Keep all 14 macro regions and 24 inter-region links. Do not delete A3 links solely because its raw degree is high.** Raw degree is not player experience: several A3 links are late shortcuts. The city should teach players to read layered space, not force every journey through one hub.

- A3 is a high-degree early/midgame hub, but not an all-purpose early hub. C10, C16, and C24 must remain closed on first arrival.
- A4 is a gated underground junction. After entering from A3, the player must be able to open an inspection hatch/gate inside A4 to return. C05's initial one-way state must not soft-lock the player.
- A8 handles royal history, vertical tomb routes, and underground transit. A9 handles late-game surface navigation, the royal blockade, rooftops, and drains. C07 and C23 occupy different elevations and must not collapse into one abstract underground portal.
- A11 is narrative depth, not a transit hub. Its entries come from the royal maintenance system and the Church's silent side chapel; control information release after entry.
- A13 keeps one-way endgame entries. C21 and C22 must not become ordinary travel loops.
- No new ability gate is locked in. A grappling hook was only an example, not a map requirement.

## 2. Relative spatial sketch

This is a proposed top-down arrangement, not a scale drawing or proof that scenes are connected. Underground layers should overlap the surface areas they belong beneath.

\`\`\`text
                                  N ↑

        [A1 Frontier Village] — [A2 Mistwood / Bell Tomb / Old Pilgrim Road]
                  \                         \             \
                   \                         \        [A5 Battlefield / Fortress]
                    \                         [A3 Abandoned City] —+
                     \                              |   \          \
                      [A4 Sewers / Old Reservoir] —-+    \      [A6 Monastery / Bell Tower]
                            ║ underground layer     \              |
                            ╚══ royal waterways ══ [A9 Outer Ring] — [A10 Grand Cathedral]
                                                        |                    |
                                                  [A8 Royal Necropolis]  [A12 Palace / Throne]
                                                          \                 /
                                                   [A11 Church Lab → Ancient-God Ruins]
                                                                  ║
                                                            [A13 Deep Dream]
\`\`\`

### Spatial reading

- **Northwest surface: A1 and A2.** The village anchors emotion and supplies; mistwood, bell tomb, and pilgrim road create natural vertical layers. Canopy routes and broken bridges should frame distant city/fortress silhouettes.
- **West to center: A5 and A3.** A5 conveys frontier war through walls, trenches, and elevated fortifications. A3 is the center of route comprehension, not a mandatory geometric center coordinate.
- **Central underground: A4.** Place A4 beneath A3 and extend it toward the royal side. Entrances, maintenance ledges, water levels, and sluice gates need legible elevation changes.
- **Southern power corridor: A6, A7, A10.** Move from public monastery rituals through detention/maintenance spaces toward cathedral authority. A10 may rise visually above some A9 rooftops without forming a straight corridor.
- **East: A8, A9, A12.** A8 is the necropolis/underground junction, A9 the surface outer ring, and A12 the inner city/throne endpoint. Ground, rooftop, and underground layers must explain their adjacency.
- **Cross-region depth: A11 and A13.** A11's human laboratory sits near royal maintenance shafts and Church facilities; deeper ancient-god ruins destabilize spatial logic. A13 is an endgame layer, not a surface district.

The layout may be rotated or stretched, but water should not appear to flow uphill without explanation, maintenance shafts should not span arbitrary distances, and landmarks visible across boundaries must agree.

## 3. Link-by-link audit (C01–C24)

| ID | Link | Decision and implementation constraint |
|---|---|---|
| C01 | A0 → A1 | Keep prologue escape; one-way, not a repeatable farming area. |
| C02 | A1 ↔ A2 | Keep the basic village/wilderness loop; open both ways early and make the entrance legible. |
| C03 | A2 ↔ A3 | Keep canopy/high-road entry; preserve elevated exit and return spawn, not a ground-level dead end. |
| C04 | A2 ↔ A5 | Keep old pilgrim high-road; unlock after reaching A5 so frontier pacing is not bypassed. |
| C05 | A3 → A4, later bidirectional | Keep but flag as the main soft-lock risk; enter from raised pipes and open an inspection gate inside A4 to return. |
| C06 | A4 → A1 | Keep one-way sluice/well return; separate it from H01 to avoid accidental hidden-well entry. |
| C07 | A4 ↔ A8 | Keep middle-level royal waterway; unlock after reaching A8 and separate it from low supply tunnel/high drain. |
| C08 | A3 ↔ A5 | Keep regular city/battlefield route; distinguish it from C04's old high road. |
| C09 | A5 ↔ A6 | Keep elevated fortress-to-monastery route; land on upper wall/parapet. |
| C10 | A6 ↔ A3 | Keep bell-tower shortcut; closed on first arrival at A3, with distinct landing and return spawn. |
| C11 | A6 ↔ A7 | Keep monastery-to-detention route; explain adjacency through maintenance/transport circulation. |
| C12 | A7 ↔ A4 | Keep low prison supply tunnel; use a dedicated low platform distinct from C07/C23. |
| C13 | A7 ↔ A8 | Keep prison/royal-tomb route; explain adjacency through old royal maintenance systems. |
| C14 | A8 ↔ A9 | Keep necropolis/outer-ring link; make underground adjacency understandable. |
| C15 | A8 ↔ A11 | Keep secret royal maintenance shaft; discover only after reaching A8, initially showing human maintenance traces. |
| C16 | A3 ↔ A9 | Keep late high lift; open from A9 and separate from street-level hidden clues. |
| C17 | A9 ↔ A10 | Keep rooftop cathedral approach; distinguish it from ground-level royal service doors. |
| C18 | A9 ↔ A12 | Keep inner-city side gate; open after reaching A12 through A10, never bypassing the cathedral main route. |
| C19 | A10 ↔ A11 | Keep silent side chapel entry; first entry reveals only part of the truth. |
| C20 | A10 ↔ A12 | Keep cathedral-to-palace main route; A11 exploration is not required. |
| C21 | A11 → A13 | Keep ending-state-gated endgame entry; one-way. |
| C22 | A12 → A13 | Keep throne-route endgame entry; one-way, with a distinct entrance state if needed. |
| C23 | A9 ↔ A4 | Keep high royal drain; distinct from C07's middle waterway and C12's low tunnel; open from A9. |
| C24 | A1 ↔ A3 | Keep the low, ground-level old drainage passage after village defense; A1 entry x=100 and A3 return door x=520. Do not label it a rooftop route. |

### Audit outcome

- **No macro link must be deleted.** The main risks concern unlock order, elevation, and player comprehension, not edge count.
- C05 is the key soft-lock risk: it begins as one-way A3-to-A4 travel, so the player must be able to operate an inspection gate inside A4.
- C07, C12, and C23 are distinct underground routes; differentiate them by elevation, material, flow direction, and landing.
- C03, C09, C10, C16, and C17 form a shared visual language for elevated routes, but their entrances and return spawns must not overlap on one plane.
- C15/C19 are the two secret entries to A11. They allow entry from different institutions, but the first information reveal must be controlled.
- C21/C22 are endgame entries, not ordinary bidirectional shortcuts.

## 4. Hub workload and phase availability

| Region | Raw link count | Responsibility | Decision |
|---|---:|---|---|
| A3 Abandoned City | 6 | Early/midgame layered route comprehension | High raw degree, but several shortcuts open later; keep |
| A4 Sewers/Reservoir | 5 | Underground transit and water levels | Must be stratified; avoid a teleport network |
| A9 Outer Royal Ring | 5 | Late-game surface navigation and loops | Unlocks are spread across progression; keep |
| A1 Frontier Village | 4 | Emotion, supplies, and revisits | Do not turn it into a complex transit hub |
| A8 Royal Necropolis | 4 | Historical revelations and vertical transit | Keep main route, waterway, and secret shaft distinct |

**Do not reduce A3's links in this review.** The future map legend should distinguish initially open routes, routes opened after reaching the far side, and ending/state-gated routes. A final-state graph overestimates how freely players can travel early on.

## 5. Hierarchical consistency requirements

The current design data contains 76 subregions, 71 intra-region links, and 8 lift contracts. Matching counts do not prove that playable routes are complete.

Before small-map production:

1. Map every inter-region link to concrete source and target subregions.
2. Both ends of every lift must be existing subregions and match a local lift link with the same unlock condition.
3. Lifts should improve vertical loops, not become the only main-route exit.
4. Every one-way link must document return options, alternate routes, and unlock timing.
5. Hidden-region secondary exits must obey “destination already reached” contracts.
6. Data validation proves structural consistency only. Collisions, jump distances, camera bounds, death recovery, save persistence, and scene transitions still require Godot runtime testing.

## 6. Macro acceptance checklist

- [ ] Players can orient themselves from the village, city tower, fortress, cathedral, and palace.
- [ ] A3's six links occupy streets, upper layers, high roads, and return routes rather than one screen.
- [ ] A4's C05, C07, C12, and C23 occupy distinct elevation/function layers.
- [ ] The player can open the return route after first entering A4.
- [ ] Surface, tomb, and inner-city layers in A8/A9/A12 explain one another.
- [ ] A11 transitions from human facilities to nonhuman space, with controlled information at both entrances.
- [ ] A13 remains an ending-state-driven layer, not an ordinary transit area.
- [ ] Directions, unlock conditions, and return spawns for C01–C24 match the topology contract.
- [ ] All 76 subregions, 71 local links, and 8 lifts map to actual greybox spaces.
- [ ] Godot regression covers travel, gates, lifts, death recovery, and save/load.

## 7. Scope and next-stage entry criteria

This round completes a **macro spatial proposal and connection-contract audit**. No Godot scenes, collision shapes, or transition scripts were changed, and no engine acceptance was run. The map must not be described as implemented and passed.

Before small-map/story work, map A0–A13 to real greybox scenes and transition anchors. If a scene conflicts with the contract, fix the map/topology mapping before writing events that depend on that room. Do not lock story beats to unverified room positions.

## 8. Static review result and acceptance boundary

| Item | Result this round | Evidence boundary |
|---|---|---|
| Macro counts | Static checks confirm 14 primary regions, 24 inter-region links, 76 subregions, 71 local links, and 8 lift contracts | Repository Python validators were not executed |
| Main-route reachability | A custom graph check confirms the initial main route is reachable and all 14 primary regions are reachable in the final graph | Graph reachability does not prove that scenes are traversable |
| C24 low drainage route | Topology, story geography, layer contract, entry/return spawns, and static assertions now agree | Source/data consistency was checked |
| C16 / H05 anchors | C16 door x=2040, return spawn x=1960, and H05 return door x=1870 are synchronized across code, debug marker, and validator | Collision and interaction focus were not tested in-engine |
| Hub workload | Keep A3's six links; three important shortcuts are staged and should not be deleted based on raw degree | Design decision, not proof of player experience |
| Godot runtime | **Pending** | No Godot executable is available here; travel, interaction, collision, death recovery, and save/load regression were not run |

**Conclusion: the macro design contract and the reviewed source coordinates are ready for macro-design review, but full in-engine acceptance has not passed.** Do not treat small-map and story production as the accepted next phase until Godot 4.6.x verifies the main route, C05 return hatch, C24's two-sided gate, C16/H05 interaction spacing, the three distinct A4 underground routes (C07/C12/C23), save/resume, and death recovery.

## 9. Third source-contract review (2026-10-12)

This pass compared macro connection contracts with the graybox exit code again. The static validator still expected the old prompt labels for C09 (A5→A6) and C17 (A9→A10), while the current scenes use explicit high-route wording. Those stale assertions could falsely report the correct implementation as missing. The assertions are now aligned, and the validator pins both elevated door contracts: C09 at A5 x=2250, `floor_y - 90`; C17 at A9 x=2350, `floor_y - 180`. These anchors match the intended elevated route design.

**Boundary:** This is a source/validator contract correction only. The Python validators have not been executed, and Godot movement, collision, interaction, and scene transitions remain unverified.
