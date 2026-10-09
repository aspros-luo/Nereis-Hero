# Art Direction / 美术方向

## Target / 目标

Hand-painted 2D dark fantasy with graphic-novel readability. The game should feel like a tragic illustrated chronicle rather than generic pixel art.

手绘感 2D 暗黑幻想，兼顾漫画式可读性。整体应像一部悲剧性的绘本，而不是通用像素风游戏。

## Principles / 原则

- Strong silhouettes and readable combat poses.
- Restrained palette: charcoal, ash, bone, rust-red, and cold supernatural accents.
- Heavy environmental shadows, layered backgrounds, selective fog, and restrained lighting.
- Organic corruption rather than generic gore.
- Human faces and body language remain important even when supernatural elements appear.
- Horror should often be implied before it is shown.
- Combat readability outranks decorative detail.
- 清晰的角色剪影与战斗姿势。
- 克制配色：煤灰、灰烬、骨白、锈红和少量冷色超自然光。
- 厚重环境阴影、分层背景、选择性雾效和克制照明。
- 采用有机腐化而非泛化血腥。
- 即使出现超自然变化，也要保留人物表情和肢体语言的重要性。
- 恐怖应先暗示，再揭示。
- 战斗可读性优先于装饰细节。

## Current implementation / 当前实现

Many characters and environment elements are still drawn procedurally in GDScript. These are functional placeholders, not the intended final art quality. Do not treat the existing primitive geometry as the final visual style.

目前不少角色和场景元素仍由 GDScript 程序化绘制。这些是可运行的占位美术，不是最终目标。不要将现有几何图形视为最终视觉风格。

## Asset sourcing policy / 素材来源策略

1. Prefer verified CC0 or clearly licensed assets that allow modification and redistribution.
2. Use licensed external art for backgrounds, set dressing, and props before replacing core character animations.
3. Use commercial game sprite archives such as Odin Sphere as visual reference only unless rights for the specific asset are verified.
4. Recolor and composite only after confirming the asset license permits derivatives.
5. Keep a record of source, author, license, attribution, and changes in `docs/ASSET_CREDITS.md`.
6. Avoid mixing pixel-art character sprites with the current non-pixel, painterly direction unless a deliberate whole-game style conversion is approved.
7. Prefer a cohesive scene set over individually attractive but stylistically incompatible assets.

1. 优先使用已确认 CC0 或明确允许修改、再发布的素材。
2. 先用授权素材替换背景、场景布置和道具，再替换核心角色动画。
3. Odin Sphere 等商业游戏精灵图网站默认只作视觉参考，除非确认具体素材的使用权。
4. 确认授权允许衍生作品后，才进行调色和合成。
5. 在 `docs/ASSET_CREDITS.md` 记录来源、作者、授权、署名与修改。
6. 除非明确决定全游戏转为像素风，否则不要把像素角色直接混入当前非像素手绘方向。
7. 优先追求整套场景风格统一，而不是拼接风格不兼容但单张好看的素材。

## Production order / 制作顺序

1. Background and environment props — strongest immediate visual gain, low combat risk.
2. Hero combat animation — high value, requires frame/pivot review.
3. First common enemy — attack telegraph, hit reaction, death feedback.
4. Mite and key NPCs — narrative silhouette and emotional readability.
5. Bosses and ending sequences — distinctive silhouette and phase language.
6. Combat VFX, audio-visual sync, UI icons.

1. 背景与环境道具：视觉收益高、战斗风险低。
2. 主角战斗动画：价值高，但需要仔细检查帧和锚点。
3. 第一种普通敌人：攻击前摇、受击和死亡反馈。
4. 蜜忒与关键 NPC：叙事剪影和情绪表达。
5. Boss 与结局演出：独特剪影和阶段语言。
6. 战斗特效、音画同步与 UI 图标。

## Acceptance / 验收

- The Hero and enemy remain distinguishable at actual gameplay zoom.
- Enemy wind-up and active attack frames are visually distinct.
- New sprites preserve foot baseline, pivot, collision alignment, and animation timing.
- Scene transitions and debug shortcuts continue to work.
- No missing textures, shaders, or script resources.
- Do not claim runtime acceptance until the project has been launched in Godot 4.6.x.

- 实际游戏缩放下主角与敌人仍然容易区分。
- 敌人前摇与攻击生效帧视觉差异明确。
- 新精灵保持脚底基线、锚点、碰撞对齐和动画时序。
- 场景切换与调试快捷键继续正常。
- 不存在缺失的纹理、Shader 或脚本资源。
- 未在 Godot 4.6.x 实际运行前，不得宣称通过运行验收。
