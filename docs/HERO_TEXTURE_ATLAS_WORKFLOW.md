# Hero Texture Atlas Workflow / 主角纹理图集工作流

## Current decision / 当前决策

`assets/art/hero_sprite_lab/muramasa_texture_atlas.png` is treated as a **surface/UV atlas**, not as a conventional animation sprite sheet. The atlas inspection scene therefore does not crop arbitrary rectangles and attach them to bones as if each crop were a complete limb.

将 `assets/art/hero_sprite_lab/muramasa_texture_atlas.png` 视为**模型表面/UV 纹理图集**，而不是普通动画精灵表。因此检查场景不会再把任意矩形裁片当成完整四肢，直接挂到骨骼上。

## What the inspection scene does / 检查场景功能

- Reuses `scenes/player/hero_skeleton.tscn` and its current `Skeleton2D` hierarchy.
- Keeps the procedural line-art visible by default, so atlas inspection never hides the only known character silhouette.
- Displays the source atlas beside the rig with a 64-pixel coordinate grid.
- Clicking a cell reports the exact source rectangle (`x`, `y`, `width`, `height`) in the original 2048×2048 atlas and shows a nearest-filter magnified crop for inspection.
- Is a development-only lab; it does not replace the production Hero scene or change gameplay.

- 复用现有骨骼层级，默认保留线稿作视觉对照。
- 在骨骼旁显示原始图集和每格 64 像素的坐标网格。
- 点击网格可读取原始 2048×2048 图集中的准确矩形坐标。
- 仅用于开发检查，不替换正式 Hero 场景，也不修改玩法。

## Why arbitrary crops are not accepted / 为什么不接受猜测裁片

A UV atlas stores texture fragments laid out for particular mesh surfaces. The correct mapping from an atlas island to a visible body surface depends on the source mesh and UV coordinates. A crop may contain only part of a sleeve, armor panel, or folded cloth; drawing it as a whole arm or torso creates a visibly incorrect result.

UV 图集中的纹理岛是为特定模型表面排布的。纹理岛与可见身体部位之间的对应关系依赖原模型网格和 UV 坐标。一个矩形可能只包含袖子、护甲板或衣褶的一小部分，把它当作整条手臂或整个躯干会导致明显错误。

## Next production path / 后续可行路径

1. Locate the original mesh/scene and UV mapping data, if they exist in the supplied assets. Prefer this route because it preserves the intended texture layout.
2. If no usable mesh exists, author a new 2D character silhouette and hand-drawn key poses; use the atlas only as a color/material reference, not as a source of guessed full-body sprites.
3. Bind verified 2D body-part artwork to the existing bone pivots, then inspect idle, walk/run, jump/fall, attacks, dodge, and death in Godot before considering production integration.

1. 若已有素材中包含原始模型/场景和 UV 映射，优先找回并复用。
2. 若没有可用模型，则重新绘制适合 2D 的角色轮廓和关键帧，把图集作为配色与材质参考，而不是猜测完整身体精灵。
3. 将经过确认的 2D 部件绑定到现有骨骼轴点，并在 Godot 中检查站立、走跑、跳跃、攻击、闪避和死亡后，再考虑接入正式角色。

## Sprite-sheet reference / 动画精灵表参考

The user-provided reference page is [Momohime (2/2) on The Spriters Resource](https://www.spriters-resource.com/wii/muramasathedemonblade/asset/153143/). The page identifies the asset as a PNG sprite sheet from *Muramasa: The Demon Blade*, 2560×2432 pixels, uploaded 24 April 2021, with no animation metadata listed. Visual inspection shows character poses arranged in rows on a transparent background, including locomotion and sword-action poses. This is a different kind of source from the UV texture atlas above: individual sprite poses can be selected as animation frames, provided their actual cell bounds and transparent padding are measured rather than guessed.

该链接页面标注的素材是《胧村正》中的 **Momohime (2/2)**，PNG 尺寸为 2560×2432，页面没有提供动画元数据；从图像可见，多个角色姿势按行排列，包含移动和刀剑动作。这与上文的 UV 纹理图集是两种不同素材：精灵表可以提取为动画帧，但必须先实测每帧边界和透明留白，不能仅凭猜测套用统一裁切尺寸。

**Character direction / 角色方向:** treat this sheet as a *motion and visual-style reference*, not as the final identity of Nereis-Hero's male Chinese swordsman. Preserve the project's own character identity and avoid silently replacing the protagonist with Momohime.

**Implementation gate / 实装前置条件:**
- [ ] Confirm the downloaded source image is present in the project and record its exact path and dimensions.
- [ ] Measure row/column frame bounds from the actual image; do not assume a uniform 256×256 grid.
- [ ] Group verified frames into idle, walk/run, sword attack, and recovery sequences.
- [ ] Preview each sequence at runtime and correct foot-origin alignment before binding it to the current rig or replacing the rig's visual layer.

## Acceptance status / 验收状态

- [x] Restore the atlas-based workflow; remove the incorrect requirement for separate `head.png`, `body.png`, and other guessed part files.
- [x] Keep the existing line-art visible while inspecting the atlas by default.
- [x] Provide a clickable source-coordinate grid.
- [x] Show a magnified, nearest-filter preview of the selected atlas cell.
- [ ] Verify the scene in Godot 4.6.1 on the local project.
- [ ] Identify source mesh/UV files or approve a new hand-drawn 2D silhouette workflow.
- [ ] Complete and visually accept the textured rig.

- [x] 恢复图集工作流，移除对独立部件 PNG 的错误依赖。
- [x] 默认保留现有线稿作对照。
- [x] 提供可点击的原图坐标网格。
- [x] 显示选中图集单元的最近邻放大预览。
- [ ] 在本地 Godot 4.6.1 项目中实际运行验证。
- [ ] 找到原模型/UV 文件，或确认改用重新绘制的 2D 轮廓。
- [ ] 完成纹理骨骼拼装并通过视觉验收。
