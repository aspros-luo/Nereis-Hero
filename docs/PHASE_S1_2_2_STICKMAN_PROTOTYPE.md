# Phase S1.2.2-A1 Stickman Skeleton Scene Prototype

## Goal
Create the first Skeleton2D based Hero prototype while keeping the existing `_draw()` implementation untouched.

## Scope
- Add `stickman_hero.tscn`.
- Add `stickman_skeleton_controller.gd`.
- Validate basic humanoid bone hierarchy.

## Bone Layout
- RootBone
- Spine
- Head
- Arm_L / Arm_R
- Leg_L / Leg_R
- WeaponSocket
- EffectSocket

## Prototype States
Controller placeholder states:
- Idle
- Run
- Attack
- Hurt
- Dodge

## Notes
This phase only establishes the animation skeleton foundation. Existing rendering code remains compatible until Skeleton2D validation is complete.
