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

- Topology marks C21 initially blocked and finally forward-only. Runtime creates the A11→A13 door only when `NereisEndingEvaluator.get_candidate()` returns a non-human ending candidate, based on resonance, truth anchors, and exploration. Intimacy/union state is not the gate.
- A13 does not create an ordinary return door to A11.

### C22 — A12 → A13 terminal entrance

- Topology marks C22 as initially forward-only (`from_to`) and finally forward-only; the door still requires `reached_A12_via_A10`.
- The previous door/landing at y_offset=-65 sat within the Hero's maximum ground-jump collision envelope, so a jump from the continuous floor could overlap its Area2D trigger without using the upper approach.
- The door now sits at y_offset=-140, with its supported landing moved to y_offset=-120. With the current JUMP_VELOCITY=-520 and GRAVITY=1400, the maximum jump height is about 96.6px; including the 24px half-height, the Hero's top is about y_offset=-120.6. The trigger bottom is y_offset=-135, leaving about 14px of vertical clearance from a ground jump while a Hero on the raised landing overlaps the trigger.
- A12 now enters A13; A13 delegates ending selection to the shared ending evaluator and does not create an ordinary return door to A12. This remains a geometric source check until verified in Godot.

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

## Phase A closure checklist — 2026-10-15

### Static source review completed

- [x] C13 endpoint targets, upper-platform markers, and floor_y - 120 arrival mappings are present on both sides.
- [x] C15 requires Resonance Sight through the shared gate, resonance 55, ancient exposure 2, and both anomaly_bell_retiming and anomaly_erased_royal_name.
- [x] C19 requires resonance 68, outer exposure 12, outer_god_resonance, and anomaly_mirror_street_echo.
- [x] C15 and C19 each use their own persistent open flag for A11 return doors.
- [x] C21 is only spawned when the shared ending evaluator selects a non-human route from resonance, truth anchors, and exploration; C22 enters A13 only after the A10→A12 main-route flag is recorded.
- [x] A13's ordinary exit is the shared ending-evaluator candidate; no A11/A12 return door is authored in the A13 branch.
- [x] Removed redundant ending-candidate calculation from A12; A13 remains the single ending-evaluation layer.
- [x] The focused source checker compares C15/C19/C21/C22 topology unlock conditions with runtime markers, checks gate-specific requirements/returns, verifies C13 and C22 upper-platform geometry against the Hero's jump envelope, and scopes A13 checks to the actual exit-wiring function.

### Required Godot 4.6.1 runtime acceptance — still pending

Run these in the project, using a debug save or controlled debug state as appropriate. Do not count a source-marker match as a runtime pass.

1. **C13 traversal and bypass**
   - Enter A7 from A6; walk to the C13 east side without jumping. The C13 interaction prompt must not be usable from the floor.
   - Traverse the authored two-step/platform approach and confirm the Hero can stand on the upper landing and interact with the C13 door.
   - Transition to A8; confirm the arrival is supported on the upper west platform and does not overlap the return-door focus radius.
   - Return to A7; confirm the Hero arrives on the upper maintenance ledge.
   - Repeat while deliberately staying on the ground lane to confirm there is no unintended ground-level transition around the high gate.

2. **C15/C19 isolation and persistence**
   - With all requirements absent, confirm neither gate reveals (unless the debug override is deliberately enabled for a separate debug-only test).
   - Satisfy C15's requirements only; confirm C15 can be revealed/opened, the state survives a scene reload, and A11's tomb-side return appears.
   - Confirm this does not enable the A10/cathedral return associated with C19.
   - Satisfy C19's requirements only; confirm C19 can be revealed/opened and its return appears, without enabling the C15 return.
   - Verify the evidence source IDs and outer-god fact independently; test the thresholds just below and at the required values.

3. **C21/C22 terminal direction**
   - With the ending evaluator selecting the human ending candidate, confirm A11 does not spawn C21.
   - With enough resonance/truth anchors/exploration for a non-human candidate, confirm C21 enters A13.
   - Enter A13 through C22 from A12 and confirm it uses the same terminal layer.
   - In A13, check both ends and the whole floor route: no ordinary door returns to A11 or A12; the only ordinary exit advances to the selected ending route.
   - Reload the scene/save and confirm the terminal direction remains unchanged.

4. **Main-route ground bypass sweep**
   - Walk along the ground floor of A6/A7 (C11), A7/A8 (C13), and A8/A9 (C14) without using their intended doors; confirm no transition happens merely by reaching a region edge.
   - Repeat at elevated cross-region doors C03 (A2/A3 canopy), C08 (A3/A5 highroad), C09 (A5/A6 monastery approach), C10 (A6/A3 shortcut), C13 (A7/A8 maintenance shaft), and C17 (A9/A10 cathedral roof).
   - At every elevated door and adjacent ledge, check jump reachability, landing collision, door focus distance, and the exact transition destination; specifically confirm the ground lane cannot trigger a door intended to be reached from above.
   - Also inspect any adjacent shortcut/secret door in the same area so its interaction radius does not accidentally capture the main-route prompt.

### Execution boundary

The GitHub connector can inspect and commit source files but does not run the project in the user's local Godot editor. No Godot runtime acceptance is claimed here. Phase A is therefore **source-review complete, runtime acceptance outstanding**; the first small-map prototype may proceed with these connections marked as runtime-pending, but their geometry should not be frozen until the checks above are performed.

