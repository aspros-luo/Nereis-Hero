# Art Asset Pipeline / 美术素材整合流程

Updated: 2026-10-09

## Goal / 目标

Replace the most visually expensive procedural placeholders in Nereis-Hero with cohesive 2D assets while preserving the existing combat, interaction, narrative, and scene-transition systems.

在不破坏现有战斗、交互、叙事和场景切换系统的前提下，优先替换视觉效果最差的程序化占位素材，并统一游戏的 2D 美术风格。

## Visual target / 视觉目标

- Hand-painted dark fantasy with strong silhouette readability.
- Muted charcoal, ash, bone, rust-red and restrained cold supernatural accents.
- Characters and enemies must remain readable against backgrounds during attacks.
- The game's original lore and character identity take precedence over copying another game's designs.
- 目标为手绘感暗黑幻想、清晰剪影、克制的灰黑/骨白/锈红配色；超自然效果使用少量冷色点缀。
- 战斗时主角、敌人与攻击特效必须能从背景中清晰区分。
- 保留 Nereis-Hero 自己的世界观与角色辨识度，不直接照搬其他游戏的角色设计。

## Asset priority / 素材优先级

1. Hero combat silhouette and animation readability.
2. First common enemy and its hit/death feedback.
3. Village exterior and interior background layers.
4. Mite and important NPC portraits/silhouettes.
5. Mini-boss / boss silhouettes and telegraphed attacks.
6. Combat VFX, props, UI icons and ambience.

优先级依次为：主角战斗表现、基础敌人、村庄场景、蜜忒与重要 NPC、Boss、战斗特效及 UI。

## Candidate reference source / 候选参考来源

- The Spriters Resource — Odin Sphere: https://www.spriters-resource.com/playstation_2/odinsphere/
- Use this source first for studying sprite-sheet organization, layered fantasy backgrounds, animation poses, and effects.
- Do not assume that assets ripped from a commercial game are licensed for redistribution or commercial use. Before importing any third-party sheet into a distributable build, verify its license and usage permissions. If permission is unclear, use it only as a private visual reference and create/use original or explicitly licensed alternatives.
- Spriters Resource — Odin Sphere 可用于研究精灵图组织方式、分层幻想场景、动作关键帧和特效设计。网站上可下载不代表获得再发布或商业使用授权；授权不明确时，只作为私人参考，不将其直接打包发布，改用原创或明确授权的替代素材。

## Import and adaptation rules / 导入与适配规则

1. Keep original downloads outside the runtime asset folders until reviewed.
2. Record source URL, creator/submitter, license/permission status, and intended use in an asset ledger.
3. Preserve transparency; remove only unwanted background pixels, never erase antialiased character edges blindly.
4. Crop sprite sheets into frames only after confirming frame boundaries and animation order.
5. Prefer lossless PNG for pixel/sprite assets. Avoid automatic smoothing that blurs outlines.
6. Normalize character feet/pivot points and frame dimensions so animation does not jitter.
7. Use separate layers for background, gameplay collision, foreground occlusion, and parallax.
8. Recolor, crop, compose, or add masks only when the source license permits modification.
9. Test each imported asset in the actual Godot scene at gameplay zoom before replacing the existing fallback.
10. Keep a working fallback until the replacement passes visual and runtime checks.

1. 下载素材后先放在运行时目录之外审查。
2. 素材台账记录来源 URL、作者/上传者、授权状态与用途。
3. 保留透明通道；不要粗暴擦除抗锯齿边缘。
4. 确认帧边界和动画顺序后再拆分精灵图。
5. 精灵素材优先使用无损 PNG，避免平滑过滤造成轮廓模糊。
6. 统一角色脚底锚点与帧尺寸，避免动画抖动。
7. 背景、碰撞、前景遮挡和视差层分开处理。
8. 仅在授权允许时进行调色、裁切、拼接或遮罩修改。
9. 必须在 Godot 实际游戏缩放下检查素材，再替换占位图。
10. 新素材通过视觉与运行检查前保留旧素材作为回退方案。

## Godot integration checklist / Godot 集成验收

- [ ] Hero idle / run / jump / attack / dodge / hurt / death are visually distinguishable.
- [ ] Attack timing and hitboxes remain unchanged after art replacement.
- [ ] Enemy telegraphs are readable against every background.
- [ ] Sprite pivots, collision shapes, and ground contact are stable.
- [ ] Scene transitions, interactions, and debug shortcuts still work.
- [ ] No missing texture, script, or shader resources.
- [ ] No GitHub Actions workflows are added or triggered.
- [ ] 主角待机、移动、跳跃、攻击、闪避、受击、死亡动作清晰可辨。
- [ ] 更换美术后不改变既有攻击时序与判定框。
- [ ] 敌人攻击前摇在各类背景下都清晰可见。
- [ ] 锚点、碰撞形状和落地位置稳定。
- [ ] 场景切换、交互和调试快捷键保持正常。
- [ ] 不存在缺失的纹理、脚本或 Shader 资源。
- [ ] 不新增或触发 GitHub Actions 工作流。

## Current limitation / 当前限制

Repository review and source planning can be performed remotely, but Godot frame-level validation requires running the project in Godot 4.6.x. Do not report runtime validation as passed until it has actually been run.

目前可以远程检查仓库和制定素材接入方案，但逐帧运行验收需要在 Godot 4.6.x 中实际运行项目。未运行前不得宣称运行验收通过。
