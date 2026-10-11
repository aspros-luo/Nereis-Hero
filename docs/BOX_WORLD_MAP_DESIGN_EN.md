# Box-World Map Structure and Acceptance

## Current assessment

During a simple playtest on 2026-10-11, holding Right continuously was enough to reach the “A Grave for Mortals” ending. This is not a testing mistake; it reveals a real graybox presentation issue. Most main-route exits sit on the right edge, and most regions use a single horizontal ground plane. A loop existing in the topology does not automatically make the world feel interconnected during play.

A player-facing world-map overlay has now been added (press **M** to open or close it), and its region nodes have been rearranged from a single row into a layered, loop-oriented spatial graph. It visualizes the main route, loops, and optional A11. This is an aid, not a substitute for physical level design.

First physical-route pass: the A2-to-A3 exit now sits on the eastern canopy ledge (about x=2240, y=380), with a rising chain of platforms. Players must notice and climb the upper route instead of simply walking right along the ground. The ground-level bell-grave anomaly remains a separate choice. F10 navigation was updated; jumping and interaction still require in-engine verification.

## Design principles

1. **Readable progression, not a one-way corridor.** The first route may be clear, but different heights, branches, and landmarks should create spatial choices.
2. **Loops must be physically traversable.** A3–A4–A1, A3–A6–A5, and the royal-depth shortcuts must work in the game, not only in documentation or flags.
3. **Shortcuts should recontextualize old spaces.** A door or lift glimpsed from one side should be opened from the other; the return trip should become noticeably shorter.
4. **Vertical layers must serve gameplay.** Upper routes can provide shortcuts, vantage points, or riskier traversal. Lower routes connect sewers, prison passages, royal tombs, and deep ruins.
5. **Landmarks before quest arrows.** The bell tower, erased street, drainage gates, royal inscriptions, and cathedral should help players remember space. F10 navigation is for acceptance testing, not a normal-play requirement.
6. **A11 and hidden areas remain optional.** The ordinary route may reach the throne and the “A Grave for Mortals” ending. A11 should deepen the world’s meaning, not gate every ending.
7. **Resonance changes how old spaces are read.** High resonance should reveal anomalies and passages within established places, not merely spawn unrelated reward rooms.

## World connections

- **Border loop:** A1 ↔ A2 ↔ A3 ↔ A4 ↔ A1. Once opened, A4 should also connect back toward A7, A8, and A9 through waterway or supply passages.
- **Middle loop:** A3 ↔ A5 ↔ A6 ↔ A3. The C10 bell-tower drop should return from A6 to A3 and noticeably shorten backtracking.
- **Royal-depth loop:** A4 ↔ A8 ↔ A9 ↔ A4. Doors must open from the intended side and retain their state.
- **Main route:** A0 → A1 → A2 → A3 → A5 → A6 → A7 → A8 → A9 → A10 → A12.
- **Deep branch:** Reach A11 through C15 from A8 or C19 from A10. H08 may extend this branch, but the branch must not block the ordinary ending.
- **Anomaly branches:** H01–H08 should branch from established landmarks and retain credible return routes.

## Next physical-layout pass

Prioritize A2, A3, A4, A6, A8, and A9:

- Place main routes, shortcuts, and hidden entrances on upper platforms, descending passages, and mid-level branches; do not make every objective reachable along the same flat ground line.
- Keep the main direction readable while offering high, low, and side routes in key regions; at least one route should reconnect to an old region through a different entrance.
- Use silhouettes of buildings, stairs, shafts, drainage pipes, bell towers, and visible sealed doors to suggest cross-level connections.
- Give each region a clear main route, an optional upper route, and a return shortcut where appropriate; routes should differ in risk, distance, or clues.
- Whenever an exit moves, update spawn-side mapping, F10 target coordinates, platform reachability, and interaction-prompt spacing together.
- Do not change story gates or save fields unless natural-exploration regression demonstrates a structural problem.

## Acceptance criteria

- Holding Right must not be the only meaningful way to read the map. The main route may remain beatable, but branches and vertical connections should be legible from environmental landmarks.
- Traverse A3 to A4 and use a real loop to return to A1 or the old city.
- Traverse C10 from A6 back to A3 and confirm that it meaningfully shortens the return trip.
- Traverse at least one royal-depth loop connecting A4 with A8/A9.
- Spawn points must match incoming direction and avoid doors, NPCs, and enemy collision bodies.
- A11 may be missed without blocking the ordinary ending; players who find it should understand its relationship to church experiments and ancient ruins through C15/C19.
- Validate through natural exploration, not F10 teleportation. The world map can clarify connections, but cannot prove a route was physically traversed.

## Status

- Done: world-map overlay for A0–A12 and discovered hidden areas; M toggles it, Esc closes it, and main routes are visually distinguished from loops.
- Implemented, pending runtime verification: A2-to-A3 now uses a rising canopy route to an eastern raised exit (about x=2240, y=380); A3-to-A5 uses the eastern raised parapet (about x=2240, y=410); H03 sits beside the Third Street clue (about x=1120). F10 navigation and objective text were aligned with these changes.
- Remaining: extend vertical-space and loop readability improvements to A2, A4, A6, A8, and A9, then verify jump reachability and interaction spacing in Godot.
- Not yet runtime-verified: Godot 4.6.x parsing, input-lock behavior, window-size adaptation, and full natural exploration. Static checks are not runtime acceptance.
