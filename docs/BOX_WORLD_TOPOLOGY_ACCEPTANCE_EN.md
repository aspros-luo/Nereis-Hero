# Box-World Topology Acceptance and Gap Register

> Date: 2026-10-12  
> Status: Design-audit baseline; not accepted through Godot runtime testing  
> Branch: development

## 1. Non-negotiable world-map principles

This project must use a **connected box-world map**, not a linear chain from A0 to A12 with a few side rooms attached.

Acceptance requires all of the following:

1. **Multiple routes:** after progression gates open, major hubs should offer at least two meaningful directions; important areas must not depend on a single correct path.
2. **Loops:** players should be able to circle back to explored areas, approach landmarks from another side, or shorten routes through unlocked doors, lifts, and drops.
3. **Meaningful shortcuts:** a shortcut must reduce backtracking, connect different elevations/layers, or open another side of a hub. Merely connecting two linear scenes is not enough.
4. **Rewarded revisits:** returning with new abilities, Resonance thresholds, opened gates, hidden clues, or routes should create new choices.
5. **Hidden areas are not dead ends:** every H area needs a safe return to its parent. Any secondary exit must document its unlock condition, persistence, and whether it could bypass main progression.
6. **Readable spatial layers:** ground lanes, rooftops, ledges, sewers, and royal drains must be distinguishable through elevation, entrance placement, and return spawn points.
7. **Separate topology from runtime acceptance:** topology proves intended connections only. A playable map is complete only after routes, collisions, interactions, and persistence are verified in Godot.

## 2. Current topology snapshot

The current `tools/world_map_topology.json` contains:

- Primary regions: A0–A13, 14 total. A13 is the ending-anomaly layer; A0–A12 are the main exploration and pre-ending regions.
- Macro connections: 24 total: 10 main, 9 shortcut, 1 underground route, 2 secret, and 2 ending connections.
- Formal hidden regions: H01–H08, 8 total. H09 remains provisional and must not automatically become canon or a required ending gate.
- Explicitly registered macro loops: 3 (Border Loop L01, Mid-Level Loop L02, and Deep Kingdom Loop L03).

These figures show that the design is **not a single path only** and already defines shortcuts and loops. They do not prove that every connection works in-game, nor that the experience already meets the Dark Souls 1-style interconnected-world goal.

## 3. Current structural assessment

### Existing foundation

- A1, A3, A4, A8, and A9 have multiple connections and serve as hubs.
- C04, C06, C07, C10, C12, C16, C18, C23, and C24 are defined as shortcuts.
- L01, L02, and L03 explicitly record border, mid-level, and deep-kingdom loops.
- H01–H08 record their parent region, Resonance threshold, return path, and optional secondary exit.

### What cannot yet be considered complete

- Physical doors, platforms, collisions, and return spawns in A2–A4 still require in-engine verification.
- A5–A8 must prove that the battlefield high road, bell-tower drop, prison low route, and royal-tomb middle passage form player-perceivable cross-links rather than merely data-level connections.
- A9–A12 must prove that rooftops, the cathedral, the inner-city side gate, and the royal drain create meaningful revisiting routes.
- Resonance reveal, interaction, entry/return, secondary exits, rewards, and persistence for H01–H08 have not passed runtime acceptance.
- The three registered macro loops are the minimum explicitly documented set, not a limit. If exploration still feels like “advance in one direction, then backtrack along the same path,” the connections or spatial layout must be strengthened.

## 4. Box-world acceptance gates

Each region must be assessed against these criteria. “Connected in topology” cannot substitute for actual playability.

| Dimension | Passing condition |
|---|---|
| Multiple exits | Except for intentional prologue/endgame exceptions, important regions have at least two meaningful exits or connections |
| Loops | After unlocking, a physically traversable closed loop exists without relying on unimplemented story assumptions |
| Shortcuts | Opening it materially shortens an old route or connects previously separated layers/areas |
| Revisits | At least one reasonable new route, reward, clue, or interaction motivates returning |
| Hidden areas | Resonance conditions are reachable; entrance interaction works; return is safe; state survives transitions, death, and reload |
| Spawn points | Arrival and return land on standable platforms, clear of door triggers and at the correct elevation |
| Persistence | Doors, unlocks, one-time rewards, and region progress remain consistent after leaving, returning, and death recovery |
| Runtime verification | Every route is walked and recorded in Godot 4.6.x; static checks must never be labeled runtime acceptance |

## 5. Execution order

1. Finish spatial and interaction acceptance for the first A2–A4 loop slice.
2. Audit A5–A8, especially whether the mid-level network is more than a linear corridor.
3. Audit A9–A12, especially whether the outer ring, cathedral, inner city, and royal drain create useful revisits.
4. Verify H01–H08 individually; keep H09 provisional.
5. If in-game exploration still feels linear, change connections, shortcut endpoints, or layer layout first. Do not mask the issue by adding region count or meaningless side branches.
6. Mark the map complete and begin large-scale regional narrative filling only after the main route, loops, shortcuts, revisits, and hidden areas pass.

## 6. Current conclusion

**Current conclusion: the topology has a box-world foundation, but the world map cannot yet be called complete or accepted.**

It currently defines 24 connections, 9 shortcuts, 3 explicit loops, and 8 formal hidden areas. The next task is not to inflate those counts, but to verify that the connections form an understandable, traversable, revisitable multi-route network in actual scenes. If runtime exploration still feels linear, the map must be revised; topology counts alone cannot justify completion.
