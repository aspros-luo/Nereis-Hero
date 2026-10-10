# Art Asset Pipeline / 美术素材生产流程

## 中文

### 本轮目标
将《蜜忒之歌-英雄》从程序化几何角色逐步转向统一的高清手绘质感。先接入关键角色和战技样板，同时保留现有玩法。

### 本轮接入
- 主角：长剑与短刃两种角色外观。
- 蜜忒：主线 NPC 与结局共用插画，鸣响阶段叠加克制的异界光效。
- 苦修者：破损长袍、仪式面具、红色眼缝。
- 灰烬骑士：一阶段重甲与二阶段异化外观。
- 战技：断罪斩、残月连斩三段、余响符印、命中火花。
- 资源来源和许可记录：`assets/art/ART_ASSET_LICENSES.md`。

### 临时动作图集 / Temporary animation atlas

为尽快验证动作可读性，本分支暂时使用从用户的 `RPG-Udemy/Assets/Graphics/153143.png` 复制而来的整角色序列图：`assets/art/characters/temp_swordfighter_atlas.png`。图集为 2560×2304，按 10 列 × 9 行、每格 256×256 取帧。现有 `hero.gd` 根据主角动作状态选择待机、移动、攻击、闪避、跳跃/坠落、攀墙、受击和死亡的占位帧；绘制脚本只替换视觉层，碰撞体、命中框、伤害、能力输入与时序保持不变。

这张图集是逐帧序列图，不是骨骼绑定文件。现在使用逐帧切图是为了快速获得明显的挥剑动作；真正的 `Skeleton2D/Bone2D` 版本需要将身体、四肢和武器分离成独立部件后再绑定骨骼。该临时人物外观与 Nereis-Hero 最终哥特骑士风格不一致，因此仅用于动画原型，之后应替换为原创骑士动作帧或分层骨骼素材。

The project temporarily copies the full-character sprite sheet from the user's `RPG-Udemy/Assets/Graphics/153143.png` into `assets/art/characters/temp_swordfighter_atlas.png`. It is a 2560×2304 sheet arranged as 10 columns × 9 rows of 256×256 cells. `hero.gd` picks placeholder frames for idle, movement, attack, dodge, jump/fall, wall climb, hurt and death states. This changes rendering only; collision shapes, hitboxes, damage, ability input and timings remain unchanged.

This is a frame-by-frame sprite sheet, not a skeletal rig. Frame slicing is the fastest way to make the existing sword attacks visibly animate. A future `Skeleton2D/Bone2D` version requires separate body, limb and weapon pieces. The temporary character style does not match the final gothic-knight art direction and must be replaced by original knight animation frames or properly separated rig parts before release.

### 实现约束
- 只替换绘制层；不修改碰撞体、攻击/受击区域、伤害、敌人 AI、移动、体力消耗或战技触发时序。
- SVG 作为可缩放纹理使用；现有脚本仍负责命中判定与技能时序。
- 第三方环境素材尚未导入。需要先核对美术风格、获取方式和完整许可，避免混搭像素风与高清手绘。

### 验证状态
- 静态检查：检查资源路径、脚本结构、绘制函数唯一性、战技 ID 与战斗方法是否保留。
- Godot 运行时：当前维护环境没有 Godot 4.6 可执行程序，实际运行仍待本地验证。重点检查 SVG 导入、纹理加载、缩放、朝向翻转、标签位置和战技可读性。

### 下一步
1. 在 Godot 4.6 运行，验证全部 SVG preload。
2. 调整角色显示尺寸、脚底锚点与头顶标签。
3. 选择并合法获取风格匹配的村庄/教堂场景素材。
4. 将战技扩展为多帧动画或分层效果，再推广到其他敌人、Boss 与灵视变化。

## English

### Goal
Move Nereis Hero away from geometric placeholder characters toward a coherent high-resolution painterly presentation, starting with key characters and combat VFX while preserving gameplay.

### Integrated in this pass
- Hero: long-sword and short-blade appearances.
- Mite: shared main-story/ending illustration with restrained resonance overlays.
- Cultist: ragged robe, ritual mask and red visor slit.
- Ashen Knight: phase-one armor and transformed phase-two appearance.
- VFX: Judgment Slash, three Crescent Combo stages, Eldritch Echo sigil and impact spark.
- Provenance and license notes: `assets/art/ART_ASSET_LICENSES.md`.

### Temporary animation atlas

A full-character frame sheet from the user's `RPG-Udemy` repository is temporarily integrated at `assets/art/characters/temp_swordfighter_atlas.png`. The atlas is 10×9 cells at 256×256 each and is used by the existing Hero renderer. It is not a skeletal rig; a real `Skeleton2D/Bone2D` setup would require separated body and limb artwork. This placeholder changes only visuals, and it is not cleared as final release art until the source asset's license is confirmed.

### Constraints
- Rendering-only changes: no edits to collision shapes, hitboxes/hurtboxes, damage, enemy AI, movement, stamina costs or technique timing.
- SVGs are scalable textures; existing scripts remain authoritative for hit detection and timing.
- No third-party environment pack has been imported yet. Verify style, acquisition and full license before mixing external assets into the project.

### Verification
- Static checks cover asset paths, script structure, unique draw functions, retained technique IDs and combat methods.
- The maintainer environment has no Godot 4.6 executable, so runtime validation remains pending. Check SVG import, texture loading, scale, facing flips, label placement and VFX readability locally.

### Next steps
1. Run with Godot 4.6 and verify every SVG preload.
2. Tune sprite scale, foot anchors and floating labels.
3. Select and legally obtain a matching village/church environment pack.
4. Expand VFX into multi-frame animation or layered effects, then extend the style to other enemies, bosses and resonance states.

## Skeleton2D cutout rig / 骨骼分层原型（2026-10-09）

- The live hero renderer now uses `Skeleton2D` + `Bone2D` and source-matched SVG layers under `assets/art/characters/rig_parts/`.
- All layers keep the same 192x224 canvas; the foot anchor is (96, 220), and each `Sprite2D` is offset by the negative of its joint pivot. The previous full-body frame selection is no longer used to draw the hero.
- Idle, movement, jump/fall, attack, grapple, dodge, quick dash, wall-climb, hurt and death poses rotate visual bones only. Collision and combat code remain in `hero.gd`.
- The supplied `153143.png` remains in the repository as a reference asset, not the live rig: it is a complete-character atlas rather than layered limbs. The two `tex1_...` images remain unverified and are not claimed to be rig-ready.

- 当前主角渲染已切换到 `Skeleton2D` + `Bone2D`，分层 SVG 放在 `assets/art/characters/rig_parts/`。
- 所有部件保留同一张 192x224 原始画布，脚底锚点为 (96, 220)，Sprite2D 按关节坐标负偏移，主角不再使用整角色动作图集选帧绘制。
- 待机、移动、跳跃/下落、攻击、钩爪、闪避、快速冲刺、攀墙、受伤和死亡只驱动视觉骨骼；碰撞与战斗逻辑保持不变。
- 你提供的 `153143.png` 保留为参考素材，但当前不作为骨骼渲染源：它是完整角色图集，并未拆出四肢。两张 `tex1_...` 图片尚未验证，本轮不宣称它们已经适配骨骼。

## Polygon2D + UV skeleton prototype / Polygon2D 与 UV 骨骼原型（2026-10-10）

- Replaced the temporary SVG cutout renderer with a texture-atlas renderer based on `Polygon2D`, explicit UVs, `Skeleton2D`, `Bone2D`, and rigid per-vertex weights.
- The atlas uses selected components extracted from the supplied PNG texture. It is a compact prototype atlas, not the unmodified 2048×2048 source.
- The controller drives head, spine, arms, knees, hips, weapon, hair and scabbard in existing gameplay states.

- 本轮将临时 SVG 拼接渲染器替换为基于 `Polygon2D`、明确 UV、`Skeleton2D`、`Bone2D` 和顶点权重的纹理骨骼原型。
- 图集来自用户提供的 PNG 纹理中提取的局部部件，是轻量原型图集，不是未经修改的 2048×2048 原图。
- 动画控制器会驱动头部、脊柱、手臂、膝部、髋部、武器、头发与背部刀鞘。
