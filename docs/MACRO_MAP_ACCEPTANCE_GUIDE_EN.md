# Macro-Map Acceptance Guide

> Goal: test A0–A13 and H01–H08 directly in Godot, focusing on landings, cross-region connections, hidden-route returns, and actual traversal before investing in complex small-map narrative.

## Launch

1. Pull the latest `development` branch.
2. Open the project in Godot 4.6.1 or a compatible Godot 4.x release and wait for imports to finish.
3. Run the project and open the title menu.
4. Select **“宏观地图验收 / World Map Test”**.
5. Select any region. The launcher lists 14 main regions (A0–A13) and 8 hidden regions (H01–H08).

## Controls

- Move: arrow keys or A/D.
- Jump: Space (subject to the project's current Input Map).
- Interact: press E near a door, checkpoint, or interactable.
- Return to region selection: **F6**.
- Return to title: use the button on the region-selection screen.

The test launcher temporarily primes selected progression flags so doors and return routes can be checked quickly. This does **not** prove that normal narrative progression is correct. Scene changes are logged to Output as `[NEREIS][MAP][NATURAL_TEST]`.

## Save safety

Acceptance mode enables `WorldState.debug_map_test_mode`; `save_game()` does not write to the normal save while this flag is active. Returning to the title reloads the existing save, or restores new-run defaults if no save exists. Do not treat primed test flags as narrative progress.

## Recommended pass order

1. **Main route:** A0 → A1 → A2 → A3 → A5 → A6 → A7 → A8 → A9 → A10 → A12 → A13.
2. **Side routes:** A3 ↔ A4, A9 lift/drain connections, and both A11 entrances.
3. **Hidden regions:** enter H01–H08 from the selector and verify at least one expected return route for each; watch for overlapping doors, floating landings, or unreachable gates.
4. **Report blockers:** region ID, source region, action taken, what happened, a screenshot/video around the spawn point, and Output lines containing `[NEREIS][MAP][SPAWN]`.
5. **Do not assess small-map narrative, final art, or combat balance yet.** This pass is specifically for macro-map traversal.

## Verification boundary

The launcher, region list, and F6 return path have been added and statically cross-checked against repository source. Godot could not be launched in the current environment, so runtime success is **not** claimed. The next local run should prioritize scene parsing, collisions, platform traversal, door interaction, and spawn placement. If startup fails, capture the first error and script line number.
