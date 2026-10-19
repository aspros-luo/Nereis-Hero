# S1.2.5 — Locomotion Animation Pass (CN)

Date: 2026-10-19
Branch: `feature/hero-animation-system`

## Scope

This pass improves the existing procedural skeleton gait without changing gameplay movement:
- The Hero supplies its live horizontal velocity to the presentation adapter.
- Direction input begins with a short, low-speed walk (`118 px/s`); holding it for `0.22 s` targets the existing run speed (`260 px/s`).
- Run-cycle phase advances according to actual horizontal speed, using a slower cadence and smaller limb range during walking, then a faster cadence, longer stride, and stronger body lean while running.
- When the Hero has effectively stopped, the gait phase stops advancing instead of continuing to run in place.
- The run-to-idle transition reuses a decaying gait weight for residual leg, knee, foot, arm, and torso motion, reducing a hard snap to the neutral pose.
- Landing compression now peaks at floor contact and eases out over a short 0.18-second visual recovery window, rather than reaching its maximum halfway through recovery.
- The existing live grounded/vertical-velocity context continues to select jump, fall, and landing poses.

## Ownership boundaries

- `hero.gd` remains authoritative for CharacterBody2D velocity, floor contact, jump physics, combat timing, and hitboxes.
- `hero_skeleton_controller.gd` reads a context snapshot and changes only visual bones/lines.
- This change does not add input locks, alter movement constants, change attack hit windows, or replace the F8 visual fallback.
- Do not let AnimationPlayer/AnimationTree and the procedural controller write the same bone transforms concurrently. The current rig remains procedural until a clip-driven migration is separately implemented and runtime-accepted.

## In-game acceptance checklist

Run the project in Godot 4.6.1 and test the production Hero in a scene with walkable ground and a wall:
1. Tap left/right briefly: the Hero should make a small, controlled walking step. Hold the direction for more than 0.22 seconds: movement should transition to the existing 260 px/s run speed, with a visibly longer stride and stronger lean.
2. Check that attacking still uses the existing slower attack-movement speed and does not accelerate into a run.
3. Push against a wall: the Hero should not keep cycling its legs at full running cadence while horizontal velocity is zero.
4. Start and release movement repeatedly: the gait should ease into and out of idle without a hard leg/arm snap; inspect whether the current procedural easing feels too soft or too stiff.
5. Jump, reach the apex, fall, and land: check that jump/fall poses align with velocity and floor contact, and that landing compression begins on contact and recovers without visible foot penetration.
6. Attack while moving, switch weapon, dodge, and use F8 to compare the skeletal rig with the legacy fallback.
7. Confirm collision, stamina, damage, and hitbox timing are unchanged. Movement speed is intentionally changed only for ordinary directional movement.

## Verification status

The branch source edits were committed through GitHub. No Godot parser/import, scene startup, or in-game animation test was run in this session. This pass is source-reviewed only and is not yet runtime-accepted. Next pass: implement distinct start/stop/turn anticipation and recovery, then tune jump takeoff/apex/fall/landing transitions. Only after those are stable should the rig migrate to editable AnimationPlayer/AnimationTree clips.
