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
