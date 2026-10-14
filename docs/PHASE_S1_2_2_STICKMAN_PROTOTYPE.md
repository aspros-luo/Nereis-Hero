# Phase S1.2.2 — Stickman Skeleton Prototype

## S1.2.2-A1 — Skeleton scene
- Added `scenes/characters/stickman_hero.tscn` as a standalone `CharacterBody2D` prototype.
- Bone hierarchy: `Skeleton2D/RootBone`, `Spine`, `Head`, `Arm_L`, `Arm_R`, plus articulated `Leg_L/Knee_L/Foot_L` and `Leg_R/Knee_R/Foot_R` chains.
- Kept `WeaponSocket` and `EffectSocket` as siblings of `Skeleton2D` so later weapon/effect placement is not coupled to a specific bone.

## S1.2.2-A2 — Visual debug layer
- `SkeletonDebug` remains a separate `Node2D` sibling and does not replace the character's production rendering.
- The debug overlay reads live `Bone2D.global_position` values and redraws while enabled, following animated bone transforms. Position conversion uses the shared parent origin rather than `Node2D.to_local()` to avoid a singular-transform inverse in preview setups.

## S1.2.2-A3 — AnimationPlayer & skeletal animation prototype

### Implemented / 已实现
- `AnimationPlayer` is a sibling of the `CharacterBody2D` root and receives a runtime `AnimationLibrary` with looping `Idle` and `Run` clips.
- Added an enabled `Camera2D` to the standalone prototype scene with a 4× preview zoom so the small stick figure is visible when running the scene directly. The camera is `top_level` so it remains fixed while the `CharacterBody2D` moves; otherwise a child camera follows the character and makes movement look stationary.
- `Idle`: subtle spine/head/arm sway; both legs are explicitly keyed to neutral rotations so the run pose does not remain after stopping.
- `Run`: alternating arm and leg rotations with a small spine counter-swing and subtle head movement. Each leg now has a thigh, knee, and lower-leg/foot endpoint, so the debug silhouette reads as two separate legs rather than one vertical line.
- `SkeletonDebug` draws each leg as hip → knee → foot and the run clip bends the knees in alternation for a clearer walking stride. The foot endpoints are offset left/right to read as feet instead of two perfectly vertical lines, with subtle foot-angle keys during the cycle.
- Added a short `Idle` ↔ `Run` blend time to soften movement transitions.
- Built-in `ui_left` / `ui_right` actions plus explicit Left/Right and A/D key polling move the root and select `Run`; releasing the keys returns to `Idle`. The rig flips horizontally to face the current movement direction without flipping the CharacterBody2D or its fixed camera. No project-wide Input Map changes are required.
- Future state names are reserved for `LONG_SWORD_ATTACK`, `SHORT_BLADE_ATTACK`, `HURT`, `DODGE`, `WITCH_TIME`, and `BOSS_ACTION`. These states intentionally have no authored clips yet.

### Node responsibilities / 节点职责
- `CharacterBody2D`: movement and collision/physics responsibility.
- `Skeleton2D` + `Bone2D`: skeletal pose transforms only.
- `AnimationPlayer`: owns and plays the prototype animation clips.
- `SkeletonDebug`: optional bone-following visual debug overlay.
- `WeaponSocket` / `EffectSocket`: reserved attachment points for weapons and effects.

### Follow-up bug fix / 后续错误修复
- A local runtime report showed `get_animation_library("")` emitted an engine error when the default animation library did not yet exist.
- Replaced the unsafe lookup with `has_animation_library("")` before removal. This keeps initialization safe for the current scene, whose `AnimationPlayer` starts without a serialized animation library.

### Verification boundary / 验证范围
- Repository scene/script paths and the current branch contents were inspected.
- The code change addresses pose persistence when transitioning from Run back to Idle, sets a short blend for Idle/Run transitions, and checks `has_animation_library("")` before removing the default library so an absent library is never queried with `get_animation_library("")`.
- The connected GitHub session cannot launch the local Godot 4.6.1 editor/runtime. Therefore, parser/import/playback and physical movement are **not claimed as runtime-tested**; local acceptance below is still required.
- Follow-up fixes: avoid querying a missing default animation library, prevent the debug overlay from requiring a global-transform inverse, keep the preview camera fixed instead of parent-following, support both arrow keys and A/D, add articulated knee/foot joints with an alternating two-segment leg cycle, offset/animate the feet for a more legible walk silhouette, and flip the rig to face left/right movement.

### Local acceptance / 本地验收
1. Open the project in Godot 4.6.1, open `res://scenes/characters/stickman_hero.tscn`, and use **Run Current Scene (F6)**. Running the project with F5 still launches `res://scenes/boot.tscn`, not this standalone prototype.
2. Confirm there are no parser/import errors and that `Idle` starts automatically from the controller.
3. Hold Left/Right or A/D: the root `CharacterBody2D` should visibly move across the viewport while the fixed preview camera remains stationary and the debug skeleton loops through `Run`.
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
