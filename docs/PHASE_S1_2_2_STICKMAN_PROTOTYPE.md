# Phase S1.2.2 — Stickman Skeleton Prototype

## S1.2.2-A1 — Skeleton scene
- Added `scenes/characters/stickman_hero.tscn` as a standalone `CharacterBody2D` prototype.
- Bone hierarchy: `Skeleton2D/RootBone`, `Spine`, `Head`, `Arm_L`, `Arm_R`, `Leg_L`, `Leg_R`.
- Kept `WeaponSocket` and `EffectSocket` as siblings of `Skeleton2D` so later weapon/effect placement is not coupled to a specific bone.

## S1.2.2-A2 — Visual debug layer
- `SkeletonDebug` remains a separate `Node2D` sibling and does not replace the character's production rendering.
- The debug overlay reads live `Bone2D.global_position` values and redraws while enabled, following animated bone transforms.

## S1.2.2-A3 — AnimationPlayer & skeletal animation prototype

### Implemented / 已实现
- `AnimationPlayer` is a sibling of the `CharacterBody2D` root and receives a runtime `AnimationLibrary` with looping `Idle` and `Run` clips.
- `Idle`: subtle spine/head/arm sway; both legs are explicitly keyed to neutral rotations so the run pose does not remain after stopping.
- `Run`: alternating arm and leg rotations with a small spine counter-swing and subtle head movement.
- Added a short `Idle` ↔ `Run` blend time to soften movement transitions.
- Built-in `ui_left` / `ui_right` actions move the root and select `Run`; releasing the keys returns to `Idle`. No project-wide Input Map changes are required.
- Future state names are reserved for `LONG_SWORD_ATTACK`, `SHORT_BLADE_ATTACK`, `HURT`, `DODGE`, `WITCH_TIME`, and `BOSS_ACTION`. These states intentionally have no authored clips yet.

### Node responsibilities / 节点职责
- `CharacterBody2D`: movement and collision/physics responsibility.
- `Skeleton2D` + `Bone2D`: skeletal pose transforms only.
- `AnimationPlayer`: owns and plays the prototype animation clips.
- `SkeletonDebug`: optional bone-following visual debug overlay.
- `WeaponSocket` / `EffectSocket`: reserved attachment points for weapons and effects.

### Verification boundary / 验证范围
- Repository scene/script paths and the current branch contents were inspected.
- The code change addresses pose persistence when transitioning from Run back to Idle, and sets a short blend for Idle/Run transitions.
- The connected GitHub session cannot launch the local Godot 4.6.1 editor/runtime. Therefore, parser/import/playback and physical movement are **not claimed as runtime-tested**; local acceptance below is still required.

### Local acceptance / 本地验收
1. Open the project in Godot 4.6.1 and run the project or instantiate `res://scenes/characters/stickman_hero.tscn`.
2. Confirm there are no parser/import errors and that `Idle` starts automatically from the controller.
3. Hold Left/Right (Godot's default `ui_left` / `ui_right`): the root `CharacterBody2D` should move while the debug skeleton loops through `Run`.
4. Release the key: movement stops, `Idle` resumes, and the legs return to neutral rather than freezing in the last run pose.
5. Repeat Run/Idle switching several times and confirm there is no accumulating bone rotation or visible snap beyond the intended short blend.
6. Confirm `SkeletonDebug`, `Skeleton2D`, `AnimationPlayer`, `WeaponSocket`, and `EffectSocket` coexist without changing the production `hero.gd` rendering path.

## Follow-up / 后续
- Replace the prototype stick figure with authored character art/skin binding after the animation test passes.
- Add authored long-sword and short-blade attacks, Dodge/Witch Time, hit reaction, and boss-specific clips when the combat design is ready.
- Add floor/gravity/collision only when integrating the prototype into a real gameplay scene; this harness currently isolates horizontal movement and skeletal animation.

## Repository permission check
- On 2026-10-14, the connected GitHub API successfully read this private repository and `development`; repository metadata reported `push: true`.
- A documentation write test and subsequent code/documentation commits succeeded on `development`. This confirms connector write capability, not local Godot runtime validity.
