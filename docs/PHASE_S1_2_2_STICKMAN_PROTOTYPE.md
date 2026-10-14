# Phase S1.2.2 — Stickman Skeleton Prototype

## S1.2.2-A1 — Skeleton scene
- Added `scenes/characters/stickman_hero.tscn` as a standalone `CharacterBody2D` prototype.
- Bone hierarchy: `Skeleton2D/RootBone`, `Spine`, `Head`, `Arm_L`, `Arm_R`, plus articulated `Leg_L/Knee_L/Foot_L` and `Leg_R/Knee_R/Foot_R` chains.
- Revised proportions after visual review: shortened the torso/head spacing, brought the shoulders closer to the body, and lengthened both leg chains. The renderer stroke widths and head radius were reduced to match the more balanced silhouette.
- Kept `WeaponSocket` and `EffectSocket` as siblings of `Skeleton2D` so later weapon/effect placement is not coupled to a specific bone.

## S1.2.2-A2 — Visual debug layer
- `SkeletonDebug` remains a separate `Node2D` sibling and does not replace the character's production rendering. Press **F3** in the prototype to toggle this technical overlay on/off at runtime without changing the skeleton or animation state.
- Added `StickmanVisual` (`scripts/characters/stickman_visual.gd`) as a separate presentation layer. It follows the same bone transforms but draws a dark outline and warm inner stroke with rounded joints; F3 hides only the white technical overlay, not the character silhouette.
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
- Added first-pass, non-looping `LongSwordAttack`, `ShortBladeAttack`, and `Dodge` clips. The attack poses use different timing profiles: the long sword has a more deliberate anticipation/swing/follow-through/recovery arc, while the short blade is quicker and more compact. These remain rough prototype poses, not final weapon choreography.
- The Space dodge now tests horizontal burst movement in the direction the rig was facing when the action began, in addition to its low evasive pose.
- Facing is now locked for the duration of every attack/dodge action, so pressing the opposite direction cannot flip the rig while the animation or dodge burst is still committed. This is a movement-feel prototype only: it has no collision response tuning, invulnerability frames, stamina cost, or production dodge rules.
- Added temporary prototype controls: **J** = long-sword attack, **K** = short-blade attack, **Space** = dodge. Each action owns its state until its clip duration elapses, then returns to Run or Idle based on horizontal input; movement remains responsive during the pose test.
- Attacks remain visual state tests only: there are no weapon sprites, hitboxes, damage, stamina cost, combo buffering, or Witch Time behavior yet. Holding an attack key may trigger another test after the current clip completes. Dodge now moves horizontally, but its burst distance/speed still needs local feel testing and it has no invulnerability frames or stamina cost.
- `HURT`, `WITCH_TIME`, and `BOSS_ACTION` remain reserved states without authored clips.

### Node responsibilities / 节点职责
- `CharacterBody2D`: movement and collision/physics responsibility.
- `Skeleton2D` + `Bone2D`: skeletal pose transforms only.
- `StickmanVisual`: character-facing line-art presentation, independent from technical debug drawing.
- `AnimationPlayer`: owns and plays the prototype animation clips.
- `SkeletonDebug`: optional bone-following visual debug overlay.
- `WeaponSocket` / `EffectSocket`: reserved attachment points for weapons and effects.

### Follow-up bug fix / 后续错误修复
- A local runtime report showed `get_animation_library("")` emitted an engine error when the default animation library did not yet exist.
- Replaced the unsafe lookup with `has_animation_library("")` before removal. This keeps initialization safe for the current scene, whose `AnimationPlayer` starts without a serialized animation library.

### Verification boundary / 验证范围
- Repository scene/script paths and the current branch contents were inspected.
- The prototype includes a separate outlined character renderer driven by live bone positions, alongside the independently toggleable white debug overlay. The code changes address pose persistence when transitioning from Run back to Idle, set a short blend for Idle/Run transitions, and check `has_animation_library("")` before removing the default library so an absent library is never queried with `get_animation_library("")`.
- The connected GitHub session cannot launch the local Godot 4.6.1 editor/runtime. Therefore, parser/import/playback and physical movement are **not claimed as runtime-tested**; local acceptance below is still required.
- Follow-up fixes: avoid querying a missing default animation library, prevent the debug overlay from requiring a global-transform inverse, keep the preview camera fixed instead of parent-following, support both arrow keys and A/D, add articulated knee/foot joints with an alternating two-segment leg cycle, offset/animate the feet for a more legible walk silhouette, and flip the rig to face left/right movement.

### Local acceptance / 本地验收
1. Open the project in Godot 4.6.1, open `res://scenes/characters/stickman_hero.tscn`, and use **Run Current Scene (F6)**. Running the project with F5 still launches `res://scenes/boot.tscn`, not this standalone prototype.
2. Confirm there are no parser/import errors and that `Idle` starts automatically from the controller.
3. Press **F3** and confirm the white technical lines disappear and reappear while the outlined stickman remains visible and movement continues unchanged.
4. Hold Left/Right or A/D: the root `CharacterBody2D` should visibly move across the viewport while the fixed preview camera remains stationary and the stickman silhouette animates through `Run`.
5. Release the key: movement stops, `Idle` resumes, and the legs return to neutral rather than freezing in the last run pose.
6. Press **J** and **K** separately. Confirm the long-sword action feels more deliberate than the compact short-blade action and returns to the correct locomotion pose. These are visual-only tests, not functional combat.
7. Press **Space** while facing left and right. Confirm the character moves in its captured facing direction during the short dodge burst, then returns to normal movement. Tune `prototype_dodge_speed` only after local feel testing.
8. Repeat Run/Idle switching several times and confirm there is no accumulating bone rotation or visible snap beyond the intended short blend.
9. Confirm `StickmanVisual`, `SkeletonDebug`, `Skeleton2D`, `AnimationPlayer`, `WeaponSocket`, and `EffectSocket` coexist without changing the production `hero.gd` rendering path.

## S1.2.2-A5 — Independent character presentation / 独立角色表现层
- `StickmanVisual` reads live bone positions and draws a stylized outlined figure independently from `SkeletonDebug`. Its stroke widths and head radius match the revised, less elongated torso and longer legs.
- F3 toggles only the white technical overlay; the character-facing silhouette should remain visible.
- This is temporary prototype art, not final protagonist art or a replacement for the production Hero rendering path.

## Animation feel principles / 动作手感原则
- Use simple, readable poses inspired by stick-figure action animation; do not copy its high action density or elaborate choreography into this Soulslike prototype.
- Differentiate weapon identity through timing and silhouette before adding more animation states: deliberate long-sword anticipation and follow-through versus compact short-blade execution and recovery.
- Test movement, attack commitment, dodge direction, and recovery in the running scene before adding more bones or building a general animation framework.
- Keep the bone debug overlay a technical aid, not the intended final character rendering. The current white-line rig is not final art.

## Future combat TODO / 后续战斗玩法待办

These are design backlog items only; do not implement them during the current skeleton prototype pass.

- [ ] **Heavy Long Sword / 重长剑**: treat as a later weapon progression or variant, with a heavier silhouette, slower commitment, and stronger impact feedback than the standard long sword.
- [ ] **Weapon Clash / 拼刀**: explore a deliberate clash interaction for selected elite enemies and bosses. Define readable clash windows, opposing-force feedback, and a clear outcome before implementation; do not make every enemy attack clashable by default.
- [ ] **Charged Shield Break / 蓄力破盾**: allow a committed heavy-long-sword charge attack to break or stagger selected shield-bearing enemies. Define charge duration, vulnerability, stamina/cost trade-offs, and enemy recovery window during combat design.
- [ ] **Animation and feel validation / 动作与手感验证**: prototype the heavy weapon's anticipation, impact, follow-through, and recovery using the existing rig before adding more bones or a general-purpose animation framework.

Priority note: keep these items in the backlog until basic locomotion, standard long-sword/short-blade attacks, and dodge feel solid. These are not current-sprint requirements.

## Follow-up / 后续
- Replace the prototype stick figure with authored character art/skin binding after the animation test passes.
- Add authored long-sword and short-blade attacks, Dodge/Witch Time, hit reaction, and boss-specific clips when the combat design is ready.
- Add floor/gravity/collision only when integrating the prototype into a real gameplay scene; this harness currently isolates horizontal movement and skeletal animation.

## Repository permission check
- On 2026-10-14, the connected GitHub API successfully read this private repository and `development`; repository metadata reported `push: true`.
- A documentation write test and subsequent code/documentation commits succeeded on `development`. This confirms connector write capability, not local Godot runtime validity.


## S1.2.2-A6 — Silhouette proportion pass / 轮廓比例优化

- Rebalanced the rig around a shorter torso and larger head: the spine anchor moves from -20 to -18, the head offset from -14 to -12, and the head radius increases to 7 world units.
- Narrowed the shoulder span from 26 to 19 units. The visual layer now draws short, rotation-driven arms from the existing shoulder bones, instead of treating each shoulder point as the end of an arm. No elbow bones were added.
- Standardized both thigh anchors and knee offsets to a more even 12 + 10 unit leg chain, with slightly wider foot endpoints for a clear grounded stance.
- Reduced line widths and retained rounded caps/joints. The intent is a bold, minimal silhouette with a strong head read, not a technical skeleton diagram.
- Tuned run swing amplitude for a clear stride while avoiding exaggerated arm flailing. Attack and dodge clips explicitly key foot angles so their recovery poses do not inherit stale foot rotations from locomotion.
- Scope: standalone stickman prototype only; production `hero.gd` rendering and combat behavior are unchanged.

### Local visual acceptance / 本地视觉验收
1. Run `res://scenes/characters/stickman_hero.tscn` with F6.
2. Compare the head-to-body read at the 4× preview zoom; the head should be the first readable shape, without the old stretched-neck impression.
3. Run left/right and inspect shoulder width, arm reach, knee bend, and foot separation in the full run loop.
4. Press J/K while moving and while idle. Arms should extend from the shoulder in the attack direction and legs should settle cleanly at recovery.
5. Press F3: only the white technical overlay should toggle; the refined line-art silhouette remains visible.
6. This change was authored through the GitHub API. The connected session cannot launch the local Godot runtime, so parser/runtime and subjective visual acceptance remain pending local Godot 4.6.1 verification.


## S1.2.2-A7 — Run / attack pose review (2026-10-14)

### Scope and findings / 范围与检查结论
- Re-checked the current stickman scene, live-bone renderer, animation controller, and existing phase notes on the `development` branch.
- Run-cycle code review found that the previous arm swing (±0.58 rad) was comparatively broad while knee flexion peaked at 0.38 rad. This can make the arms dominate the small silhouette while the lower legs read as relatively stiff. This is a source-level assessment; it is not a claim that the local Godot scene was visually run in this session.
- Applied a restrained Run-only curve adjustment: arm swing reduced to ±0.46 rad, thigh swing to ±0.66 rad, and alternating knee flexion increased to 0.46 rad (with the secondary bend at 0.20 rad). This aims to keep the arm rhythm readable while making the running legs articulate more clearly.
- Attack clips (`LongSwordAttack` and `ShortBladeAttack`) were inspected but their curves were deliberately left unchanged until local visual comparison confirms whether arm direction, overlap, and planted-leg poses actually need adjustment. No speculative attack curve edits were made.
- No bones, weapon mechanics, hitboxes, heavy-long-sword progression, or weapon-clash features were added. Production `hero.gd` and its rendering path remain untouched.

### Permission and validation boundary / 权限与验证边界
- GitHub connector successfully found the private repository, located the `development` branch, and read the scene, controller, renderer, and phase documentation. The controller update was accepted by GitHub and produced commit `1b00f6e16c90ddff9d0ac0b94be79d866685fa64`, confirming write capability on this branch.
- The connected session cannot launch the user's local Godot 4.6.1 runtime. GDScript parser/runtime and subjective pose quality therefore remain pending local validation.

### Local acceptance / 本地验收
1. Open `res://scenes/characters/stickman_hero.tscn` and run current scene with F6.
2. Inspect left/right Run at normal speed and with F3 debug overlay toggled. Check whether arm swing remains behind/in front of the torso without swallowing the torso silhouette, and whether alternating knees visibly separate the feet.
3. Press J and K both while idle and while moving. Check anticipation, arm orientation, arm overlap, planted-leg stability, and return to locomotion.
4. If attacks still look unclear, capture a frame or short clip of each attack before changing attack curves; tune the specific phase keys from that evidence rather than adding bones.
5. Confirm no parser errors, stale leg poses after returning to Idle, or changes to the production Hero scene.


## S1.2.2-A8 — Animation readability and pose synchronization
- Refined the run cycle into a 0.72-second stride with opposite thigh swings, alternating knee flex, counter-swinging arms, subtle pelvis bounce, and foot counter-rotation.
- Extended the long-sword attack to 0.68 seconds with six authored beats: neutral, deliberate load, committed cut, follow-through, recovery, and neutral. The torso/arms and leg counterpose have a broader silhouette than the short blade.
- Tightened the short-blade attack to 0.28 seconds with a small preparation, sharp extension, and quick recoil/recovery.
- Added explicit RootBone position tracks to every clip and neutral end keys for articulated joints, preventing pelvis bob from persisting across Run, Idle, attacks, and Dodge.
- Added short blend times between locomotion and action clips to soften transitions without blurring weapon identity.
- Improved production line art and the optional debug overlay to draw matching shoulder-to-arm segments, arm tips, and foot/toe direction from the same live Bone2D transforms. Debug rendering remains read-only and F3 only toggles its own overlay.
- Verification boundary: source-level checks confirm the intended tracks and shared bone-derived endpoints. Run the scene in Godot 4.6.1 to judge animation feel and confirm there are no runtime animation-track/path warnings.


## S1.2.2-A9 — Mirrored bone endpoint correction / 镜像骨骼端点修正

- Corrected arm-tip and toe endpoint calculations in both `StickmanVisual` and `SkeletonDebug`: use each bone's global transform basis rather than only its global rotation angle.
- This preserves the endpoint direction under the rig's horizontal scale flip, so turning left/right should mirror the short arm strokes and toe direction consistently with the animated bones.
- Both layers use the same transform-derived method; the debug overlay remains read-only and F3 still only toggles its visibility.
- Verification boundary: source-level endpoint logic was updated. Godot 4.6.1 runtime parsing and left/right visual acceptance still require local validation.


## S1.2.2-A10 — Weapon silhouette and animation linkage / 武器轮廓与动作联动

- Added `scripts/characters/stickman_weapon_visual.gd` and attached it as the separate `WeaponVisual` presentation node in `stickman_hero.tscn`.
- The weapon grip follows the live right-arm bone endpoint, and blade direction is calculated relative to the live arm direction rather than as an unrelated screen-space angle. A small attack-timing offset curve gives the long sword a deliberate load/sweep/follow-through arc and the short blade a faster, tighter thrust/slash profile; the offset is mirrored with the facing direction.
- Added an explicit prototype `WeaponKind` selection to the controller. Pressing **J** selects the long sword and attacks; pressing **K** selects the short blade and attacks. The chosen weapon remains visible through locomotion and dodge until the other attack key selects the alternate weapon.
- Long sword and short blade have distinct lengths, blade widths, guard sizes, and grip proportions. Both use a restrained outline/metal highlight so they remain legible at the prototype's 4× preview zoom.
- Scope remains visual-only: no hitboxes, damage, stamina, clash, shield-break, or production Hero integration was added. `WeaponSocket` remains reserved for later effect/weapon attachment work; this prototype renderer follows the hand bone directly.
- Source-level checks are required for the new node path, scene resource count, controller weapon selection, and both attack curves. Godot 4.6.1 parsing and visual feel still require local runtime validation.

### Local acceptance / 本地验收
1. Run `res://scenes/characters/stickman_hero.tscn` with **F6**.
2. Press **J**: a longer, broader long sword should be visible at the hand and its direction should move through anticipation, swing, follow-through, and recovery.
3. Press **K**: the shorter blade should replace the long sword and show a quicker, more compact trajectory.
4. Walk/run and dodge after selecting each weapon. The chosen weapon should remain equipped and follow the hand while the character faces both left and right.
5. Toggle **F3**. Only the white skeleton debug overlay should change; the character and weapon presentation should remain visible.
6. Check the Godot Output panel for parser errors, missing node paths, or invalid drawing calls. This has not been runtime-tested by the connected session.




## S1.2.2-A11 — Timed weapon swing trails / 武器挥砍轨迹

- Added a lightweight arc trail to `StickmanWeaponVisual`, drawn only during the committed swing window of the corresponding attack state. The trail fades in toward the strike and fades out during follow-through; it is not visible during locomotion or dodge.
- The long sword uses a wider, longer-lived pale arc plus a subtle inner echo to suggest weight. The short blade uses a tighter, thinner, quicker arc to preserve its compact identity.
- Trail timing is aligned to the existing attack clips: long sword approximately 0.16–0.49 s in the 0.68 s clip; short blade approximately 0.045–0.19 s in the 0.28 s clip. These are presentation windows only, not hit-confirm windows.
- The trail is drawn behind the weapon silhouette and follows the current hand-relative weapon direction. It uses no particles, hitboxes, damage, stamina, or enemy interaction.

### Local acceptance / 本地验收
1. Open `res://scenes/characters/stickman_hero.tscn` and run current scene with **F6**.
2. Press **J** repeatedly with a pause between attacks: a broad long-sword arc should appear briefly around the committed swing, then disappear completely.
3. Press **K**: the short blade should produce a tighter, quicker arc with less visual weight than the long sword.
4. Verify no trail appears while idle, running, or dodging, and that the weapon silhouette is drawn clearly in front of the trail.
5. Repeat while facing both directions; the arc should follow the hand/weapon orientation without remaining on the wrong side of the character.
6. Check the Godot Output panel for parser or drawing errors. Source changes were committed through GitHub; local Godot runtime verification remains pending.

## S1.2.2-A12 — Action input lock and recovery safety / 动作输入锁与恢复保护

- Attack and dodge inputs are now ignored while a prototype action state is active. This prevents repeated key-down events or cross-weapon presses from replacing an in-progress clip halfway through its authored timing; the next action can begin after the current action returns to locomotion.
- Added a defensive fallback for a missing action animation: emit a warning and return to the current locomotion state rather than leaving the controller stuck in an action state indefinitely.
- Horizontal movement remains available during attacks as a prototype movement test, while rig facing stays captured for the duration of the action. Dodge continues to use its captured facing direction.
- This remains a controller-stability pass only. No hitboxes, damage, stamina, enemy reactions, heavy weapon, clash, or shield-break logic was introduced.

### Local acceptance / 本地验收
1. Run `res://scenes/characters/stickman_hero.tscn` with **F6**.
2. Press **J**, then immediately press **K** during the long-sword swing. The long-sword action should finish its clip; the short blade should be selected only when the next eligible attack starts.
3. Repeat with **K** then **J**, and press **Space** during each attack. Neither input should cancel the current attack.
4. Press **Space** to dodge, then quickly press **J/K**. The dodge should finish before the next attack begins.
5. Hold movement during an attack, release movement before the clip ends, and verify the rig keeps its action-facing direction until recovery, then resumes the correct Idle/Run state based on current input.
6. Check the Output panel for warnings/errors. The missing-animation fallback is defensive and should not emit a warning in the normal scene, where the controller builds all prototype clips during startup.
7. Godot runtime validation is still required locally; this commit is confirmed by repository read-back, not by launching the editor in this session.

## S1.2.2-A13 — Animation-driven action recovery / 动画驱动的动作恢复

- Action recovery now listens to `AnimationPlayer.animation_finished` and only accepts the finish event matching the active action state (`LongSwordAttack`, `ShortBladeAttack`, or `Dodge`). A stale or unrelated animation-finished event cannot end another action.
- The existing duration countdown remains as a defensive fallback if an action clip is stopped or its completion signal is missed. Both paths share one idempotent recovery function, which resets the timer and returns to Idle/Run based on current movement input.
- Movement-direction reading is centralized so A/D and arrow-key behavior stays consistent when an action ends. This change does not alter the existing action lock or weapon selection behavior.
- This is a lifecycle robustness improvement only; no combat hit resolution or new gameplay mechanics were added.

### Local acceptance / 本地验收
1. Run `res://scenes/characters/stickman_hero.tscn` with **F6** and watch the Output panel.
2. Repeatedly alternate **J** and **K**, waiting for each attack to finish. Every action should return to locomotion without freezing or leaving limbs in an attack pose.
3. Start an attack while holding **A/D** or the arrow keys, then release or reverse movement before the clip ends. Recovery should select Idle or Run from the current input.
4. Test **Space** dodge with and without movement input. Dodge should complete once, then return to the correct locomotion state.
5. Confirm no warnings/errors appear and that the A11 swing trails still disappear when the action finishes.
6. Repository read-back confirms the source and documentation updates; Godot runtime validation remains pending locally.
