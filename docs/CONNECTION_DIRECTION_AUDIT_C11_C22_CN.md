# Connection direction audit — C11/C13/C14/C15/C19/C21/C22

> Branch: `development`  
> Scope: source-level review of connection topology, scene transitions, secret-gate persistence, and terminal direction.  
> Status: source contracts reviewed; Godot runtime acceptance remains pending.

## Findings

### C11 — A6 ↔ A7

- Topology declares an always-available bidirectional main connection.
- The shared graybox controller spawns the A6→A7 and A7→A6 transitions.
- The exit is on the ground lane; this is consistent with the current connection contract, not an elevated gate.

### C13 — A7 ↔ A8

- Topology declares a bidirectional main connection.
- The prison-side exit is placed at the east edge on an elevated approach; A7 has a two-step approach platform and an upper landing.
- The A8 reverse door and arrival spawn use the upper maintenance-shaft platform, rather than intentionally routing the Hero to the ground lane.
- Source layout supports the design intent, but collision-backed jump reachability and whether the player can bypass the intended approach must be checked in Godot.

### C14 — A8 ↔ A9

- Topology declares a bidirectional main connection.
- The controller wires both endpoints to the matching regional scenes and return sides.
- Both endpoints are ordinary main-route transitions; no separate unlock flag is applied.

### C15 — A8 → A11 secret entrance

- The gate is a persistent `resonance_secret_gate.gd` instance with ID `C15`, recording the discovered/entered region as A11.
- It requires Resonance Sight, resonance ≥ 55, ancient exposure ≥ 2, and the bell-retiming plus erased-royal-name evidence sources.
- A11's return door to A8 is only spawned after the persistent C15 path has been opened. Opening and entering are separate E interactions.
- This per-gate return lock is important: the C19 route must not implicitly enable C15's return.

### C19 — A10 → A11 secret entrance

- The gate has its own persistent ID `C19`, records A11 as the discovered/entered region, and uses the chapel-side arrival.
- It requires Resonance Sight, resonance ≥ 68, outer exposure ≥ 12, the outer-god resonance story fact, and the mirror-street evidence source.
- A11's return door to A10 is only spawned after C19 itself has been opened. Reaching A10 through the main route alone is not sufficient.
- C15 and C19 therefore share a destination but not an unlock/return state.

### C21 — A11 → A13 terminal entrance

- Topology marks C21 initially blocked and finally forward-only, unlocked by `physical_union_complete`.
- Runtime creates the A11→A13 door only when that story fact is true.
- A13 does not create an ordinary return door to A11.

### C22 — A12 → A13 terminal entrance

- Topology marks C22 as initially forward-only (`from_to`) and finally forward-only.
- A12's main route enters the A13 terminal scene; A13 then delegates ending selection to the shared ending evaluator.
- A13 does not create an ordinary return door to A12.
- The A12 branch contains legacy local variables that compute an ending scene/location before the actual C22 transition; the transition now targets A13, so those locals appear redundant. They are not a demonstrated routing failure and were not removed in this audit.

## Ground bypass and platform findings

The shared graybox controller creates one continuous ground collision floor per region. Exit doors are interaction triggers, not physical barrier walls. Consequently, source inspection alone cannot prove that a player cannot walk or fall around an intended elevated route: that depends on platform collision, jump trajectory, edge geometry, and the actual door interaction radius in Godot.

Static source evidence confirms the C13 upper platforms and spawn mappings are authored, but does **not** establish in-engine reachability or rule out every unintended ground-level bypass. This remains a mandatory runtime acceptance item rather than being marked as passed.

## Static regression checker

Added `tools/validate_connection_direction_audit.py`. It checks:

- C11/C13/C14 direction and endpoint wiring contracts;
- C15/C19 gate IDs, progression requirements, evidence IDs, and per-gate persistent return locks;
- C21/C22 one-way terminal topology and the absence of A11/A12 return doors from A13;
- the continuous-floor limitation so source checks are not misrepresented as runtime proof.

Run from the repository root:

```bash
python3 tools/validate_connection_direction_audit.py
python3 tools/validate_world_map_topology.py
python3 tools/validate_spatial_route_contracts.py
python3 tools/validate_graybox_scene_wiring.py
```

## Acceptance boundary

This pass reviewed the current `development` source and added a focused static regression checker. The checker has not been executed against a local checkout in this session, and Godot 4.6.x runtime tests have not been run. Do not mark collision, door focus, ground bypass, transition, save/resume, or terminal behavior as runtime-accepted until those checks are performed in-engine.
