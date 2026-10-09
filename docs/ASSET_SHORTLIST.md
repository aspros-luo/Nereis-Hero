# Art Asset Shortlist / 美术素材候选清单

Updated: 2026-10-09
Branch: development

This is a curated shortlist, not a claim that the assets have already been downloaded or imported. Every pack must be reviewed in-game before replacing existing art.

本清单用于筛选候选素材，并不表示素材已经下载或导入。所有素材都必须经过游戏内审查后，才能替换现有美术。

## Selection criteria / 筛选标准

- Side-scrolling 2D fit; readable silhouettes at 1280×720 gameplay scale.
- Palette can be adapted to charcoal, ash, bone, rust-red and cold supernatural accents.
- Prefer CC0 or clear permission for modification and redistribution.
- Avoid mixing high-detail painted art and tiny pixel art in the same foreground layer.
- Prefer modular backgrounds and props first; character animation replacement has higher integration risk.
- 横版 2D 适配；在 1280×720 实际游玩比例下轮廓清晰。
- 可统一为煤灰、骨白、锈红和冷色超自然点缀。
- 优先 CC0 或明确允许修改、再发布的授权。
- 不在同一前景层混用高细节手绘素材与极小像素图。
- 优先替换可分层背景和场景道具；角色动画替换风险更高。

## Candidate A — Dark Platformer (CC0)

Source: https://opengameart.org/content/dark-platformer
License shown by source: CC0.
Contains: 14 PNG props and three sample backgrounds.
Assessment: **Best low-risk first visual experiment** for testing a dark side-scrolling environment. Review actual images before use; source description is not enough to guarantee a perfect fit.
Potential use: abandoned outskirts, cave route, distant scenery, small environmental props.
Adaptation: grayscale/ash grade, restrained rust-red accents, atmospheric fog overlays and separate parallax planes where the source layers allow it.

来源：Dark Platformer；页面标注 CC0，包含 14 张 PNG 道具图和 3 张示例背景。
评估：适合先做低风险的暗色横版场景实验。仍需检查实际图片，不能只凭介绍断定完全适配。
用途：荒废村外、洞穴路线、远景和小型环境道具。
适配：灰烬色调、克制的锈红点缀、雾层，以及在素材允许时拆分视差层。

## Candidate B — Castle Platformer (CC0)

Source: https://opengameart.org/content/castle-platformer
License shown by source: CC0.
Contains: tiles, parallax backgrounds, a knight and a bat.
Assessment: Strong thematic fit for church ruins and castle passages, but inspect the character art and tile resolution before use.
Potential use: church exterior blockout, ruined corridor, moonlit route background.
Rule: use the environment as modular scenery; do not replace the Hero with this knight unless proportions and combat readability pass review.

来源：Castle Platformer；页面标注 CC0，包含 tiles、视差背景、骑士与蝙蝠。
评估：适合教会废墟和城堡通道，但必须先检查角色风格与图块分辨率。
用途：教会外部、废墟走廊、月光路线背景。
规则：优先将环境作为模块化场景；除非比例与战斗可读性通过验收，否则不直接替换主角。

## Candidate C — Misc. Dark Fantasy Scenery Sprites (CC0)

Source: https://opengameart.org/content/misc-dark-fantasy-scenery-sprites
License shown by source: CC0.
Contains: gothic/horror props such as chains, cages, skulls, candles and stone ornaments.
Assessment: Useful as isolated narrative props and set dressing, not as a complete scene kit.
Potential use: church surgical ward, ancient research lab, graveyard and boss arenas.
Adaptation: selective desaturation and controlled highlights; preserve transparent edges and original proportions.

来源：Misc. Dark Fantasy Scenery Sprites；页面标注 CC0。
包含哥特/恐怖类道具，如锁链、笼子、头骨、蜡烛与石质装饰。
评估：适合独立叙事道具和场景布置，不适合作为完整场景包。
用途：教会手术室、古代研究室、墓园与 Boss 场地。
适配：选择性降低饱和度、控制高光，同时保留透明边缘与原始比例。

## Candidate D — Odin Sphere (reference only by default)

Source: https://www.spriters-resource.com/playstation_2/odinsphere/
Assessment: Strong reference for hand-painted fantasy composition, animation poses and layered scenes. It is commercial game art; availability on a sprite archive does not grant redistribution rights.
Default use: visual reference only.
Direct integration: only after rights/permission are verified for the specific asset.

来源：Odin Sphere 素材库。
评估：适合研究手绘幻想构图、动作关键帧和分层场景。它属于商业游戏素材，出现在素材网站上不代表可以再发布。
默认用途：仅作视觉参考。
直接整合：仅在确认具体素材授权后进行。

## Candidate E — Dark World Asset Pack (CC0, pixel art)

Source: https://kaishido.itch.io/dark-world
License shown by source: CC0 1.0.
Contains: 16×16 tiles, character idle/walk sheet, flora and inventory items.
Assessment: **Not a primary style match** for the current painterly/graphic-novel direction. Consider only for prototyping, small distant details, or if the project deliberately moves toward pixel art as a whole.
Do not mix its character sprites into the current hero/enemy lineup without a unified style pass.

来源：Dark World Asset Pack；页面标注 CC0 1.0。
包含 16×16 图块、角色待机/行走图、植物和物品。
评估：与当前手绘/漫画式方向并非主要风格匹配。仅考虑用于原型、远景小细节，或在项目整体转向像素风时使用。
未经统一风格处理，不将其角色直接混入当前主角和敌人阵容。

## Integration order / 接入顺序

1. Prototype one background/prop set in an isolated scene.
2. Compare contrast and silhouette readability against the current Hero and enemy placeholders.
3. Verify scaling, transparency, collision alignment and parallax.
4. Keep existing procedural art as a fallback.
5. Only then migrate the chosen art into the actual village/church/route scenes.
6. Record exact source URL, asset title, author, license and modifications in `ASSET_CREDITS.md`.

1. 先在独立场景中试用一套背景/道具。
2. 对比现有主角与敌人占位图，检查对比度和轮廓辨识度。
3. 验证缩放、透明通道、碰撞对齐与视差。
4. 保留现有程序化美术作为回退。
5. 通过后才迁移到村庄、教会和路线场景。
6. 在 `ASSET_CREDITS.md` 中记录准确来源、素材名称、作者、授权和修改内容。

## Runtime acceptance / 运行验收

No asset pack should be called integrated until the actual PNG files are present in the repository and the relevant Godot scene has been opened and tested. Runtime acceptance requires Godot 4.6.x.

在 PNG 文件实际进入仓库、对应 Godot 场景打开并测试前，不得称素材已完成整合。运行验收需要 Godot 4.6.x。
