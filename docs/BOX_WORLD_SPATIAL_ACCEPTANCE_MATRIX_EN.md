# Box-World Spatial Acceptance Matrix and Cross-Project Narrative Constraints

> Date: 2026-10-12  
> Status: Working checklist; not a runtime pass report  
> Branch: development  
> Validation boundary: compiled from the current topology JSON, graybox scripts, and existing audit notes. Godot was not launched while this document was created.

## 1. Immediate objective

Make the first A2–A4 box-world slice explicitly testable, then apply the same audit to A5–A8 and A9–A12. Acceptance does not mean “platforms exist in the scene.” It means players can understand how the main route, upper traversal, underground branches, shortcuts, and return paths relate spatially.

## 2. First-pass A2–A4 acceptance matrix

| Region / connection | Intent | Required checks | Acceptance criteria |
|---|---|---|---|
| A2: Mistwood, Bell Tomb, Old Pilgrim Road | Main path and canopy route coexist | Elevated C03 exit; return spawn; accidental ground-level activation | The exit is reached from its intended upper route; return spawn lands on walkable platform space outside the door trigger |
| A2 → A5 | Old Pilgrim Road shortcut unlocked after reaching the battlefield | C04 initial lock, far-side unlock, bidirectional return | Cannot pass before unlock; opens from A5 and works both ways afterward; does not bypass required mainline events |
| A3: Abandoned City | Street, raised pipe-walk, and eastern upper lift form distinct layers | C05, C10, C16; H03 / H05 entrances and return spawns | Each route has a readable spatial purpose; elevated doors cannot be activated from the continuous floor; spawns do not compete with hidden entrances |
| A3 → A4 | Enter the sewer / reservoir hub from the raised pipe-walk | C05 entrance height, A4 spawn side, A3 return height | The entrance is discoverable from the pipe-walk; transitions do not place the Hero below the required ledge or inside a door trigger |
| A4 → A1 | Late watergate / village-well shortcut | C06 unlock condition, well exit, persistent state | Remains locked until requirements are met; works after opening; is not confused with H01's hidden well route |
| A4 → A8 | Mid-level loop opened from the royal-tomb side | C07 middle waterway ledge, A8 spawn, both door states | Spatially distinct from the prison's low supply tunnel and the royal high drain; return does not land at the wrong elevation |
| A3 ↔ A5 | Main route from the abandoned city into the old battlefield | C08 doors on both sides, spawn positions, progression | Both doors agree; entering A5 preserves progression; returning to A3 does not accidentally focus another exit |

## 3. Shared acceptance contract for every map connection

Each connection must be checked at every layer below. One layer cannot substitute for another:

1. **Topology:** connection ID, source, destination, unlock condition, direction, and return definition agree.
2. **Scene:** physical door, collision shape, platform elevation, spawn point, and topology anchors agree.
3. **Interaction:** the door interaction appears at the correct location; the Hero cannot activate it from the wrong elevation or side.
4. **State:** unlock state persists across scenes; death, load, and re-entry do not reset it incorrectly.
5. **Experience:** the main route is readable; optional routes offer risk, reward, shortcuts, or narrative value; meaningless collision walls are not added just to imitate a box-world.
6. **Runtime:** movement, jumps, interactions, transitions, death, and return routes are tested in Godot 4.6.x. Static script checks must never be labeled as runtime acceptance.

## 4. Keep Resonance hidden-region states separate

For H01–H08, verify these states independently rather than collapsing them into one Boolean:

- Undiscovered
- Anomaly perceived
- Entrance revealed / opened
- Entered
- Reward or environmental evidence collected
- Return route / shortcut unlocked

Check consistency when entering from different map sides, persistence after leaving, one-time reward protection, and conflicts between hidden entrances and ordinary door interactions.

H09 remains provisional. It is excluded from formal map acceptance and must not be a hard prerequisite for any ending.

## 5. Shared-world synchronization with Nereis Lullaby

The games share world facts, but retain independent gameplay, viewpoints, and reveal pacing. Mark the status of every narrative change.

### Confirmed direction
- Mite's innocence and emotions are genuine; she does not consciously understand her relationship to the Outer God in ordinary human terms.
- The Church, the Kingdom's faith system, ancient-god residue, and Outer-God influence are distinct layers, not a simple good-versus-evil alignment.
- Villagers have individual lives, relationships, and motives; participating in an anomaly does not mean everyone understands the ritual.
- Hero and Mite may know different things. Information available to the player does not automatically become character knowledge.
- The games need not repeat the same scenes, but must not contradict each other.

### Proposal / unresolved
- Whether the ritual center is inside the village, in the forest, or distributed across both.
- Whether villagers collectively become cultists to protect Mite, when this occurs, and which ending it belongs to.
- Hero's and Mite's eventual fates, cross-game causal chains, and whether the restoration army becomes corrupt.
- H09's relic, specimen, and narrative relevance.
- Final trigger conditions and full causal chains for the three endings. Nothing not explicitly approved by the user may be treated as final canon.

## 6. Next execution order

1. Compare every physical exit in A2–A4 against its topology anchor.
2. Fix spatial positions, spawns, door triggers, and state mismatches supported by source evidence.
3. Apply the same audit to A5–A8's battlefield upper route, bell-tower drop, prison low route, and royal-tomb loop.
4. Audit rooftops, cathedral entrance, inner-city side gate, and shortcuts in A9–A12.
5. Run the repository's existing static validators and record the actual results. Only local Godot runtime testing can promote runtime acceptance to “passed.”
6. Once the map is stable, populate environmental narrative from the shared confirmed world facts while keeping unresolved story ideas labeled as proposals.

## 7. Current status

This document is an executable acceptance matrix, not proof that all listed scenes have passed. The map remains in structural review and code-fix work; Godot runtime acceptance is pending.
