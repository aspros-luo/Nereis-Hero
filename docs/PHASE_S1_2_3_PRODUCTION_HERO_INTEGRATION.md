# Phase S1.2.3 — Production Hero Visual Integration / 正式主角表现层整合

Status: **A1–A6 implementation committed; A1–A5 locally accepted by the user; A6 fuller-stickman/animation runtime check pending**. The procedural renderer remains available as a reversible fallback.

状态：**A1–A5 已由用户本地验收通过；A6 火柴人加粗与动作补强已提交、等待本地运行验收**。原程序绘制仍可通过 Debug F8 回退。

## Goal / 目标

Connect the proven skeletal-animation workflow to the production Hero while keeping the production gameplay controller and world progression authoritative.

将已验证的骨骼动画工作流接入正式 Hero，同时保持正式战斗控制器和世界进度系统为唯一权威来源。

## Repository findings / 仓库核查结果

- `scripts/player/hero.gd` is the production gameplay controller. It already owns movement, jump, 3-step attacks, weapon-specific hitboxes, stamina, dodge invulnerability, perfect-dodge/riposte, hitstun, weapon techniques, ancient-god abilities, traversal, death and respawn interactions.
- `scripts/player/hero_system.gd` owns weapon/profile/progression rules. Do not duplicate these rules in a visual controller.
- `scripts/player/hero_skeleton_controller.gd` now applies presentation-only skeletal poses and is being incrementally refined; it does not own gameplay rules.
- `scenes/player/hero_skeleton.tscn` is the active optional skeletal visual rig. Its pose controller is still a lightweight Line2D/Polygon2D presentation prototype, not a final sprite/animation library.
- `scripts/player/hero_visual_controller.gd` and `hero_visual_states.gd` are also scaffolds, not a completed production adapter.
- `scenes/characters/stickman_combat_test.tscn` and its controller are the validated isolated regression harness. Keep them independent from the production player.

## Non-negotiable boundaries / 不可破坏的边界

1. Do not replace the production combat timings or resource values with prototype values by copy/paste.
2. Do not rewrite the combat state machine, hitbox/hurtbox setup, save progression, ability unlocks, or traversal to make animation work.
3. Do not remove the procedural Hero drawing until the skeleton rig has equivalent readable states and local acceptance passes.
4. The visual layer may read production state and action context, but must not own damage, stamina, invulnerability, combo advancement, or progression.
5. Keep the stickman harness runnable as a regression scene; do not change `project.godot` main scene for prototype testing.

## Incremental implementation sequence / 分步实施

### S1.2.3-A1 — State contract and adapter — initial slice committed

Implemented in the current branch:

- `Hero.get_visual_state_name()` exposes a presentation-only name for every production combat state, including run/jump/fall, weapon-specific basic attacks, dodge, quick dash, grapple, wall climb, hurt and death.
- `Hero.get_visual_context()` returns a read-only-by-convention snapshot of facing, combo step, weapon, action timing, invulnerability and hitstun timing for future visual consumers.
- `HeroVisualStates.resolve_animation()` now maps these canonical presentation states to animation names.
- These methods do not drive gameplay, change attack timing, or instantiate/replace any visual nodes. The current procedural Hero remains unchanged until a later opt-in preview passes local acceptance.

Local acceptance for this slice: run the normal combat demo and confirm movement/combat behavior is unchanged; inspect Output for parser/runtime errors. The connected session can verify source content only, not execute Godot.

### S1.2.3-A1 — Remaining work

- Define a small visual-state contract sourced from production `CombatState` and current action context.
- Map production states to presentation states: idle, run, jump/fall, long-sword attack, short-blade attack, dodge, hurt, and death.
- Carry combo step and facing as presentation metadata; never let the visual layer change them.
- Add a debug-only way to compare the resolved visual state against the controller state without changing gameplay.

Acceptance: every production combat state maps deterministically; missing visual resources fall back safely to current procedural drawing.

### S1.2.3-A2 — Skeleton pose prototype — implementation committed

Implemented in this slice:

- `HeroSkeletonController` now builds a visible Line2D-based stick skeleton from the existing Bone2D hierarchy.
- Added explicit neutral rotation resets before every pose update, plus a neutral weapon-shape reset to prevent short-blade dimensions leaking into the next state.
- Implemented idle, run, jump, fall, long-sword attack, short-blade attack, dodge, quick dash, hurt and death poses.
- Long-sword and short-blade attacks use different weapon lengths and posture. Combo stages 1/2/3 have distinct silhouettes, with a broader committed third-stage finisher.
- Added `apply_visual_context(context)` as a presentation-only adapter for the state snapshot produced by the production Hero.
- Added an isolated pose gallery at `res://scenes/player/hero_skeleton_pose_preview.tscn`; this does not replace or modify the production Hero scene.

Local preview controls:

- Open `res://scenes/player/hero_skeleton_pose_preview.tscn` and press **F6**.
- `1` idle, `2` run, `3` long-sword attack, `4` short-blade attack, `5` dodge, `6` hurt, `7` death.
- `Z/X/C` selects combo stage 1/2/3; Left/Right flips facing.
- Switch from short-blade attack back to idle/run and confirm the sword returns to its neutral length. Cycle through every pose and return to idle to check for residual rotations.

Acceptance remains pending Godot runtime validation. The connected repository session can verify source commits, but cannot honestly claim the scene has been run in Godot 4.6.1.

### S1.2.3-A3 — Opt-in production preview — implementation committed

Implemented in this slice:

- `Hero` has an exported `use_skeleton_visual` switch, defaulting to `false`. The normal game therefore keeps the existing procedural renderer.
- When enabled, the production Hero instantiates `hero_skeleton.tscn` and passes `get_visual_context()` to the skeletal controller each rendered frame. Combat state, damage, stamina, invulnerability, hitboxes and progression remain owned by the production controller/system.
- The procedural `_draw()` output is skipped only while the explicit opt-in flag is enabled, avoiding double-rendering without deleting the fallback.
- The skeleton consumes the production weapon metadata for its idle weapon silhouette and maps grapple, wall-climb and weapon-technique action contexts to presentation poses.
- `combat_demo.gd` exposes a preview-only switch, defaulting to `false`; the new `res://scenes/player/hero_skeleton_combat_preview.tscn` enables it. The default boot scene and regular combat demo behavior are unchanged.

Local acceptance — open `res://scenes/player/hero_skeleton_combat_preview.tscn`, press **F6**, then verify:

1. Walk, run, jump and land; facing changes should flip the skeleton without changing movement.
2. Use the normal three-hit combo with both weapons; confirm the third strike is distinct and the short blade remains visually shorter.
3. Test dodge/quick dash and take a hit; confirm the correct pose appears and returns to neutral without residual rotation.
4. Check stamina costs and recovery against the regular combat demo.
5. Press **Q** to switch weapons and use the normal weapon-technique input; visual changes must not change hit results.
6. Compare attack reach and target damage with the regular `res://scenes/combat_demo.tscn` by repeating the same attack spacing.
7. Check Godot Output for parser/runtime errors.

The code and scene were committed and read back through GitHub. The user has confirmed the full A3 local acceptance passed.

### S1.2.3-A4 — Controlled rollout — implementation committed

Implemented:

- Added the session-only `WorldState.hero_skeleton_visual_enabled` flag, defaulting to `true`. Because production scenes create the same `hero.gd` controller dynamically, this rolls the skeletal presentation into the actual game without editing every scene's spawn routine.
- The production Hero now resolves its initial visual path from the global rollout flag or the scene's explicit `use_skeleton_visual` opt-in. The procedural renderer is still present and remains mutually exclusive with the skeleton renderer.
- In debug builds, press **F8** to toggle the current Hero between skeletal visuals and the original procedural drawing. The setting is session-only and is not written to saves. Newly spawned Heroes inherit the global switch; an explicit preview-scene opt-in still starts that scene with the skeleton enabled.
- The default boot scene and story flow remain unchanged; only the Hero presentation path changes. Combat state, collisions, hitboxes, stamina and progression remain in their existing owners.
- The A19–A22 stickman harness and the A3 skeletal preview scenes remain available for regression.

A4 local rollout acceptance — in Godot 4.6.1:

1. Launch the normal game with **F5** and enter the opening prologue. Confirm the Hero uses the skeletal visual.
2. Press **F8**. Confirm the skeleton disappears and the original procedural Hero appears without a movement/combat reset; press **F8** again to restore the skeleton.
3. Test movement, jumping, both weapons, three-hit combos, dodge and a hit reaction in each visual mode. Confirm stamina and hit results remain unchanged.
4. Transition to the village and one greybox region. Confirm newly spawned Heroes follow the current global visual switch.
5. In `res://scenes/combat_demo.tscn`, verify the normal combat demo still runs; use F8 to compare both visual paths. No Ashen Knight victory is required for this visual-layer check.
6. Inspect Output for parser/runtime errors.

The source and documentation have been committed and read back from GitHub. The user subsequently confirmed the A4/A5 local acceptance passed. Godot runtime validation cannot be executed from this connected session.

## Production combat values remain authoritative / 正式战斗参数保持权威

The stickman harness values are test values only. Production currently uses its own values in `scripts/player/hero.gd`, including `ATTACK_STAMINA_COST`, `DODGE_STAMINA_COST`, `STAMINA_REGEN_DELAY`, `STAMINA_REGEN_RATE`, `DODGE_DURATION`, and `PERFECT_DODGE_WINDOW`. Balance changes must be made deliberately in the production controller/system and verified in its own gameplay context, not inherited accidentally from the harness.

火柴人测试场景中的参数只用于原型验证。正式角色在 `scripts/player/hero.gd` 中拥有独立参数，例如攻击/闪避体力消耗、体力恢复延迟与速率、闪避时长、精准闪避窗口。平衡调整必须在正式控制器/系统中有意识地进行，并在正式游戏场景验证，不能从测试场景意外继承。

## Local validation policy / 本地验收原则

Repository reads and commits do not equal Godot runtime validation. For each integration slice, run the new preview scene and the existing combat demo in Godot 4.6.1. Report parser/runtime errors verbatim and fix them before moving to the next slice. No claim of runtime success should be made without an actual engine run.


### S1.2.3-A5 — Proportion and feedback pass — implementation committed

Implemented:

- Shortened the torso/head stack and lengthened the legs and arms to address the earlier stretched-body / short-leg silhouette.
- Added a restrained split-cloak silhouette behind the rig to recover part of the Hero's recognizable outline while retaining the lightweight line-art direction.
- Preserved the floor alignment by keeping the leg endpoints near the existing Hero drawing's ground baseline.
- Fixed a visual integration gap: while the skeletal body is active, the production Hero now still draws its grounding shadow, health/stamina display, combo indicator, invulnerability cue, resistance marker and attack/hit-confirm feedback. The procedural body itself remains hidden to prevent double rendering.
- No combat state, damage, attack timing, hitbox, stamina cost or progression logic was changed.

本轮补强：

- 缩短躯干与头部的纵向堆叠、加长腿部和手臂，针对此前“身体过长、腿太短”的比例问题。
- 在骨骼后方增加克制的分叉披风轮廓，补回部分主角识别度，同时保持轻量线稿方向。
- 保持脚部接近正式 Hero 原有绘制的地面基线。
- 修复骨骼模式下的表现缺失：继续显示落地阴影、生命/体力条、连击数字、无敌提示、隐藏抵抗标记以及攻击/命中反馈；只隐藏旧角色主体，避免两套身体重叠。
- 没有修改战斗状态、伤害、攻击时序、命中框、体力消耗或进度逻辑。

A4/A5 local acceptance — Godot 4.6.1:

1. Launch with F5 and enter the prologue. Confirm skeletal visuals appear.
2. Press F8 twice and confirm skeletal/procedural modes switch both ways. Check that position, health, stamina and current action are not reset.
3. Confirm the Hero's feet align with the ground, torso no longer looks excessively long, legs are visibly longer, and the split cloak does not obscure the weapon.
4. Confirm health/stamina UI, shadow, combo indicator, attack arc/hit feedback and invulnerability cue remain visible in skeletal mode.
5. Test both weapons, all three combo stages, jump/fall, dodge, hit reaction and death/respawn.
6. Enter the village and one greybox region; check newly spawned Heroes use the current global visual setting.
7. Check Godot Output for parse/runtime errors.

Source files and documentation have been committed and read back from GitHub. The user confirmed the A4/A5 local acceptance passed on 2026-10-14. Runtime validation for the new A6 visual changes remains local; this connected session has not executed Godot.

### S1.2.3-A6 — Fuller stickman and animation pass — implementation committed

Implemented:

- Increased torso, arm and leg stroke widths independently and enabled rounded line caps/joints, so the silhouette reads as a fuller stickman rather than thin wireframe limbs.
- Added a filled head silhouette with a restrained light value against the dark outline.
- Relaxed the neutral arm angle from a wide, almost T-shaped spread to a natural downward angle, and moved the hand/weapon socket to match the new wrist endpoint.
- Added a small idle breathing/weight-shift loop and a more readable run swing/bounce.
- Added short visual-only follow-through arcs for long-sword attacks, short-blade attacks and weapon techniques, plus subtle movement in jump/fall and hitstun. Grapple and wall-climb now cycle their limbs; dodge/quick-dash ease out of their compressed pose; death animates into its collapse pose.
- Pose time resets only when the presentation state, combo stage or facing changes. It never drives combat timing, damage, hitboxes, stamina or progression.
- Expanded the isolated F6 pose gallery so every current movement/combat presentation state can be checked directly.

本轮实现：

- 分别加粗躯干、手臂和腿部线条，并启用圆角端点/连接点，让轮廓更接近饱满火柴人，而不是细线骨架。
- 为头部增加填充剪影，深色描边保持整体哥特线稿风格。
- 将待机手臂从近似横向张开的姿势调整为自然下垂，并同步手部/武器插槽位置，避免“四仰八叉”的轮廓。
- 待机加入轻微呼吸与重心变化，跑步加入更清楚的摆臂、摆腿和起伏。
- 为长剑、短刃和武器战技增加短促的视觉蓄势/回弹；跳跃、下落和受击加入轻微动态；抓钩/攀墙加入交替肢体循环，闪避/快速冲刺加入收势，死亡会逐步倒下。
- 只有表现状态、连击段或朝向发生变化时才重置表现计时；该计时不参与正式战斗时序、伤害、判定、体力或进度。
- 扩展独立 F6 姿势预览，覆盖当前所有动作状态，便于逐一验收。

Local preview acceptance — Godot 4.6.1:

1. Open `res://scenes/player/hero_skeleton_pose_preview.tscn` and press **F6**.
2. Keys: `1` idle, `2` run, `3` jump, `4` fall, `5` long-sword attack, `6` short-blade attack, `7` weapon technique, `8` dodge, `9` quick dash, `0` grapple, `G` wall climb, `H` hurt, `D` death.
3. `Z/X/C` selects combo stage 1/2/3; Left/Right flips facing.
4. Confirm limbs look fuller without merging into an unreadable blob; idle arms should rest downward rather than forming a T-shape; idle/run feel alive, each action remains distinct, and returning to idle leaves no residual pose.
5. Open `res://scenes/player/hero_skeleton_combat_preview.tscn` with **F6** and test the real production Hero. Compare against `res://scenes/combat_demo.tscn` and inspect Output for parser/runtime errors.

The user-referenced Muramasa: The Demon Blade heroine texture sheet was not available as a readable asset in the current repository or accessible file payload during this pass, so no guessed texture was imported and no existing project art was overwritten. Keep texture/atlas experimentation as a separate follow-up once the exact source image is accessible. The current work deliberately improves the native Godot skeleton path first.

胧村正女主纹理图在本轮可访问的仓库文件和文件载荷中未能定位到可读取的原始素材，因此没有猜测图片、没有导入不确定的纹理，也没有覆盖项目已有美术。待能读取确切原图后，再单独建立纹理/图集实验场景；当前优先把 Godot 原生骨骼表现做好。

Source and documentation are committed and read back from GitHub. Godot runtime validation remains local; this connected session has not executed the Godot engine.

## S1.2.4-A1 — Isolated sprite-sheet animation lab / 独立序列帧实验场景

Status: **scene and script committed; runtime validation pending**. The production Hero is not replaced.

状态：**独立场景和脚本已提交，等待本地运行验收**。正式 Hero 未被替换。

### Asset inspection / 素材检查

- The uploaded reference animation sheet is 2048×1945 RGBA PNG, with alpha values from 0–255. The uploaded texture atlas is 2048×2048 RGBA PNG.
- A quick occupancy scan shows ten populated cells in rows 1–7 and four populated cells in row 8 when provisionally divided into 204×243 cells. This is a working hypothesis, not a final verified animation layout.
- The actual uploaded image is not present in the Git repository yet. To keep repository source self-contained and avoid silently copying art with unverified distribution rights, place the provided sheet locally at `res://assets/art/hero_sprite_lab/muramasa_reference_sheet.png` only for private prototype testing. The lab will show a clear message if the file is absent.
- The texture atlas is intentionally not wired as a character material: its UV/material mapping is unknown, and it may belong to a different rendering/rig setup.

- 上传的动作序列图为 2048×1945 RGBA PNG，Alpha 范围为 0–255；纹理图集为 2048×2048 RGBA PNG。
- 按 204×243 像素暂定网格扫描后，前七行各有十个非空格，第八行有四个非空格。这只是切片假设，尚未逐帧确认动作语义和边界。
- 原始图片尚未加入 Git 仓库。为避免在授权不明时直接把第三方美术复制进项目，私下原型测试时可将你提供的序列帧放到 `res://assets/art/hero_sprite_lab/muramasa_reference_sheet.png`。图片缺失时，实验场景会显示明确提示。
- 暂不将纹理图集直接接到角色材质上：当前未知其 UV/材质映射方式，也可能来自另一套模型或渲染管线。

### Run and controls / 运行与操作

Open `res://scenes/player/hero_sprite_animation_lab.tscn` and press F6. This is a standalone test and does not affect the production Hero.

打开 `res://scenes/player/hero_sprite_animation_lab.tscn` 并按 F6。此场景独立运行，不会影响正式 Hero。

- `1–8`: select a row; `↑/↓`: previous/next row.
- `Space`: play/pause; `←/→`: step through frames (pauses playback); `R`: restart.
- Grid assumption: 204×243 pixels, 10 columns × 8 rows, with 4 frames in the final row. Confirm visual alignment before building named animations.

- `1–8`：选择行；`↑/↓`：切换上一行/下一行。
- `Space`：播放/暂停；`←/→`：逐帧查看（自动暂停）；`R`：重播。
- 暂定网格为 204×243 像素、10 列×8 行，最后一行 4 帧。需要先本地确认切片是否对齐，再建立正式命名动画。

### Next acceptance gate / 下一验收门槛

1. Verify frame alignment, especially action transitions in rows 3–7.
2. Identify which rows correspond to idle, movement, attacks, dodge and recovery; do not assign names from guesses.
3. Confirm character feet align consistently with the ground guide.
4. Only after this lab passes should a separate opt-in adapter map production Hero visual states to sprite animations. Keep the existing procedural/skeleton path as fallback until production combat regression passes.

1. 检查每帧边界，尤其是第 3–8 行中的动作切换。
2. 确认各行对应待机、移动、攻击、闪避、收势等哪类动作，不凭猜测直接命名。
3. 确认角色脚底与地面参考线对齐。
4. 本实验通过后，再单独开发可选的正式 Hero 状态适配器。生产战斗回归通过前，原程序绘制/骨骼方案继续保留为回退路径。

Godot has not been run in this connected session; runtime acceptance remains local.
本轮连接环境没有实际运行 Godot；运行验收仍需本地完成。


### S1.2.4-B — Skeletal texture assembly lab / 骨骼纹理拼装实验

Status: isolated preview committed; local Godot runtime validation pending. This is a rough atlas-region prototype, not a production art replacement.

状态：独立预览已提交，等待本地 Godot 运行验收。这是粗略图集切片原型，不是正式美术替换。

- Reuses the existing `HeroSkeletonController` and its Bone2D pose rig; it does not use the sprite animation sheet.
- Adds `res://scenes/player/hero_skeleton_texture_lab.tscn` and `scripts/player/hero_skeleton_texture_lab.gd`.
- The atlas remains local-only at `res://assets/art/hero_sprite_lab/muramasa_texture_atlas.png`. Create the directory and copy the user's 2048×2048 texture atlas there for private testing. Do not commit the third-party art asset until distribution rights are confirmed.
- If the atlas is missing, the scene reports the expected path and restores the existing line-art rig. Production Hero scenes are untouched.
- Initial region rectangles and scale are provisional. Expect to adjust crop coordinates, pivots, size and layer ordering after inspecting the local result. The current atlas includes many separated parts, and rough crops may not yet align cleanly.

本轮复用现有 `HeroSkeletonController` 与 Bone2D 姿势骨架，不使用动作序列图。新增独立场景和脚本。图集只在本地放入指定路径；未确认发行授权前不提交第三方美术。缺少图集时会提示路径并恢复线稿。当前切片坐标、缩放、轴心与图层均为初始估值，需要本地观察后逐步校准。

Local acceptance:
1. Copy the 2048×2048 atlas to `res://assets/art/hero_sprite_lab/muramasa_texture_atlas.png`.
2. Open `res://scenes/player/hero_skeleton_texture_lab.tscn` and press F6.
3. Confirm the scene loads, the texture pieces follow the existing head/body/arm/leg/weapon bones, and the pose-gallery controls still work.
4. If crops look incorrect or the parser reports an error, send the exact Godot Output text and a screenshot. Do not switch the production Hero to this lab yet.

本地验收：将图集放入指定路径，打开新场景按 F6，检查纹理是否跟随头部/躯干/四肢/武器骨骼运动，以及原有姿势控制是否有效。切片可能需要继续校准；出现报错时请提供完整 Output 与截图。当前不要将实验场景切换为正式 Hero。
