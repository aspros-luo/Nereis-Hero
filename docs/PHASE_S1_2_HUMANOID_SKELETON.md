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

- HumanoidSkeletonBase foundation.
- Animation state entry points.
- WeaponSocket and EffectSocket preparation.

Next:

- Hero scene Skeleton2D integration.
- AnimationPlayer connection.
- Weapon attachment validation.

## Migration Reason

The previous procedural polygon rendering approach caused runtime triangulation failures in Godot. The new Skeleton2D pipeline improves stability and prepares future character reuse.
