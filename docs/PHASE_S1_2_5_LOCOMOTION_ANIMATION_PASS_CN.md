# S1.2.5 — Locomotion Animation Pass (CN)

Date: 2026-10-19
Branch: `feature/hero-animation-system`

## Scope

This pass improves the existing procedural skeleton gait without changing gameplay movement:
- The Hero supplies its live horizontal velocity to the presentation adapter.
- Run-cycle phase advances according to actual horizontal speed, using a slower cadence during reduced-speed movement and a faster cadence near full speed.
- When the Hero has effectively stopped, the gait phase stops advancing instead of continuing to run in place.
- The existing live grounded/vertical-velocity context continues to select jump, fall, and landing poses.

## Ownership boundaries

- `hero.gd` remains authoritative for CharacterBody2D velocity, floor contact, jump physics, combat timing, and hitboxes.
- `hero_skeleton_controller.gd` reads a context snapshot and changes only visual bones/lines.
- This change does not add input locks, alter movement constants, change attack hit windows, or replace the F8 visual fallback.
- Do not let AnimationPlayer/AnimationTree and the procedural controller write the same bone transforms concurrently. The current rig remains procedural until a clip-driven migration is separately implemented and runtime-accepted.

## In-game acceptance checklist

Run the project in Godot 4.6.1 and test the production Hero in a scene with walkable ground and a wall:
1. Hold left/right at normal speed: leg cadence should follow movement speed, not a fixed wall-clock loop.
2. Push against a wall: the Hero should not keep cycling its legs at full running cadence while horizontal velocity is zero.
3. Start and release movement repeatedly: check for visually harsh gait stopping or leg snapping.
4. Jump, reach the apex, fall, and land: check that existing jump/fall/landing poses align with real floor contact.
5. Attack while moving, switch weapon, dodge, and use F8 to compare the skeletal rig with the legacy fallback.
6. Confirm collision, position, stamina, damage, and hitbox timing are unchanged.

## Verification status

The branch source edits were committed through GitHub. No Godot parser/import, scene startup, or in-game animation test was run in this session. This pass is source-reviewed only and is not yet runtime-accepted. If the gait appears too stiff, the next pass should add an explicit locomotion blend (start/stop/turn) before converting the rig to AnimationPlayer/AnimationTree clips.
