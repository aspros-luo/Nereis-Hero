# Phase S1.2.2 — Stickman Skeleton Prototype

## S1.2.2-A1 — Skeleton scene
- Added `scenes/characters/stickman_hero.tscn` as a standalone `CharacterBody2D` prototype.
- Bone hierarchy: `Skeleton2D/RootBone`, `Spine`, `Head`, `Arm_L`, `Arm_R`, `Leg_L`, `Leg_R`.
- Kept `WeaponSocket` and `EffectSocket` as siblings of `Skeleton2D` so later weapon/effect placement is not coupled to a specific bone.

## S1.2.2-A2 — Visual debug layer
- `SkeletonDebug` remains a separate `Node2D` sibling and does not replace the character's production rendering.
- Updated the debug overlay to read the live `Bone2D.global_position` values and redraw while enabled. It now follows the animated bone transforms instead of showing a static, non-animated stick figure.

## S1.2.2-A3 — AnimationPlayer integration test

### Implemented
- Added an `AnimationPlayer` sibling to the `CharacterBody2D` root.
- The controller builds a small runtime `AnimationLibrary` containing looping `Idle` and `Run` clips. Keeping the test clips generated in code avoids committing opaque editor-generated animation data; these can later be replaced with authored clips without changing the scene hierarchy.
- `Idle`: subtle spine, head, and arm movement.
- `Run`: alternating arm/leg rotation with a small spine counter-swing.
- `ui_left` / `ui_right` move the root `CharacterBody2D`; the controller selects `Run` while moving and `Idle` when released. These are Godot's built-in UI actions, so no global Input Map changes are needed.
- `Attack`, `Hurt`, and `Dodge` remain reserved states and do not yet have clips.

### Node responsibilities
- `CharacterBody2D`: root movement/state harness.
- `Skeleton2D` + `Bone2D`: bone transforms animated by value tracks.
- `AnimationPlayer`: owns and plays the prototype clips.
- `SkeletonDebug`: bone-following visual overlay used only for validation.
- `WeaponSocket` / `EffectSocket`: retained for later sword, short-blade, dodge, and boss effect work.

### Verification boundary
The scene hierarchy and script paths were checked against the current repository files. This connector session cannot launch the local Godot 4.6.1 editor/runtime, so an actual import/parser/playback test still needs to be run locally. This commit should be treated as an animation pipeline prototype, not final combat animation.

### Local acceptance
1. Open the project in Godot 4.6.1 and run the project or instantiate `res://scenes/characters/stickman_hero.tscn`.
2. Confirm there are no parser/import errors and that the initial Idle clip starts.
3. Hold Left/Right (the default `ui_left` / `ui_right` bindings): the CharacterBody2D root should move and the debug skeleton should visibly loop through Run.
4. Release the key: movement stops and Idle resumes.
5. Confirm the `SkeletonDebug`, `Skeleton2D`, `AnimationPlayer`, `WeaponSocket`, and `EffectSocket` coexist without changing the existing `hero.gd` rendering path.

## Follow-up
- Replace the prototype stick figure with authored character art/skin binding after the animation test passes.
- Add dedicated animation clips and state priorities for long-sword attack, short-blade attack, Dodge/Witch Time, hit reaction, and boss actions.
- Add floor/gravity/collision only when integrating the prototype into a real gameplay scene; this harness intentionally tests horizontal movement and skeleton animation in isolation.

## Repository permission check
- On 2026-10-14, the connected GitHub API successfully read this private repository and the `development` branch; repository metadata reports `push: true` for the active connection.
- A documentation update was successfully committed to `development` to verify write access. This confirms connector write capability; it does not substitute for running the Godot project locally.
