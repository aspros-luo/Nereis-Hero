# Phase S1.2 - Humanoid Skeleton Base Integration

## Status

In progress.

## Goal

Replace fragile procedural character rendering with a reusable Skeleton2D based visual pipeline.

## Architecture

Gameplay remains separated from visual presentation:

- Character gameplay scripts own movement, combat, stamina and damage.
- HumanoidSkeletonBase owns reusable humanoid visual state and attachment points.
- Hero, important NPCs, elite humanoid enemies and bosses can reuse the same foundation.

## Current Progress

Completed:

- Hero's production visual uses the authored `Skeleton2D` hierarchy in `scenes/player/hero_skeleton.tscn`.
- Gameplay state remains owned by `scripts/player/hero.gd`; the skeleton controller consumes its visual context.
- Walking and running now have separate gameplay states (`MOVE` and `RUN`) as well as separate visual poses: brief directional input selects a compact upright walk; holding direction past the existing 0.22-second threshold transitions the state machine to `RUN` and selects a stronger run gait.
- Running gait uses stronger hip swing, counter-swinging arms, knee recovery, foot lift/plant, torso lean and head counter-balance.
- Long and short attacks revised to include weight shift, bracing legs, anticipation/recoil and follow-through.
- The independent stickman combat test remains a diagnostic sandbox, not a second gameplay controller.

Still to verify in Godot 4.6.1:

- Tune stride and attack timing against the actual in-game scale and frame rate.
- Confirm the state log visibly transitions `IDLE -> MOVE -> RUN` when holding a direction, and returns to `IDLE` on release.
- Confirm the new gait reads as a human walk/run rather than a mechanical cycle.
- Confirm long/short attack follow-through reads clearly at gameplay camera zoom.
- Decide whether any animation should migrate to AnimationPlayer after the visual pass; do not add a second source of truth for gameplay state.

Validation note: these changes have been committed to the feature branch, but no local Godot runtime test was performed by the assistant. In-game feel still requires user-side playtesting.

## Migration Reason

The previous procedural polygon rendering approach caused runtime triangulation failures in Godot. The new Skeleton2D pipeline improves stability and prepares future character reuse.
