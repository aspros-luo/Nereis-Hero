# Asset Credits / 美术素材署名

## Original project artwork / 项目原创美术

### Ashen Road — Painterly Layered Backdrop
- File: `assets/backgrounds/ashen_road_painterly.svg`
- Creator: Nereis-Hero project artwork (original vector illustration authored for this project)
- License: Project original; intended for use and modification within Nereis-Hero.
- Changes: Initial authored landscape with moonlit mountains, distant gothic church silhouettes, abandoned village roofs, twisted foreground branches, mist, and grain texture.
- Notes: Inspired by broad hand-painted 2D fantasy composition and layered theatrical staging. It does not reuse Odin Sphere sprites or backgrounds.

### 灰烬之路——绘制感分层背景
- 文件：`assets/backgrounds/ashen_road_painterly.svg`
- 作者：Nereis-Hero 项目原创美术（为本项目编写的原创矢量插画）
- 授权：项目原创，供 Nereis-Hero 项目内使用和修改。
- 修改记录：首版原创风景，包括月光群山、远处哥特式教会剪影、荒废村庄屋顶、扭曲前景枝干、雾气与颗粒纹理。
- 说明：参考手绘 2D 奇幻构图与舞台式分层，不复用《奥丁领域》的精灵图或背景。

## External candidates not yet integrated / 尚未整合的外部候选

External asset packs listed in `docs/ASSET_SHORTLIST.md` remain candidates until their files are downloaded, reviewed, and integrated. A source appearing in the shortlist does not mean its art is part of the game.


## Original Ashen Road scenic layers / 灰烬之路原创场景分层

These SVG assets were created specifically for Nereis-Hero and contain no third-party art:
- `assets/backgrounds/ashen_road_painterly.svg` — base illustration / 底层场景插画
- `assets/backgrounds/ashen_road_far_mist.svg` — distant mist and sparse atmospheric flecks / 远景雾气与稀疏氛围颗粒
- `assets/backgrounds/ashen_road_midground.svg` — broken monastery walls and ruined spires / 破败修道院墙体与尖塔
- `assets/backgrounds/ashen_road_foreground.svg` — thorn framing, ruined fence, gravestones, and sparse embers / 荆棘框景、残破围栏、墓碑与少量余烬

License / 授权: original project-authored assets, no external asset license required.  
Integration / 接入位置: `scripts/core/world.gd`, drawn at different camera-relative scroll factors.  
Status / 状态: source files committed; Godot runtime visual acceptance still pending / 源文件已提交，仍待 Godot 实机视觉验收。

### A0 Prologue Cliff — Painterly Backdrop
- File: `assets/art/backdrops/prologue_cliff_backdrop.svg`
- Creator: Nereis-Hero project artwork (original SVG authored for the A0 exterior scene).
- License: Project original; intended for use and modification within Nereis-Hero.
- Changes: Added layered mountain ridges, atmospheric gorge, subdued moon haze, distant ruined silhouettes, and low-contrast grain for the prologue cliff path.
- Integration: `scripts/levels/prologue_exterior.gd`; replaces only the sky/ridge backdrop drawing. Cliff boundary, ground collision, encounter timer, boss spawn, and rescue transition remain logic-controlled.
- Status: Source integration committed to `development`; Godot 4.6.1 runtime visual acceptance pending.

### A0 序章悬崖——绘制感背景
- 文件：`assets/art/backdrops/prologue_cliff_backdrop.svg`
- 作者：Nereis-Hero 项目原创 SVG，为 A0 洞外场景绘制。
- 授权：项目原创，供 Nereis-Hero 项目内使用和修改。
- 内容：分层山脊、带空气透视的河谷、克制的月光雾、远处废墟剪影与低对比颗粒。
- 接入：`scripts/levels/prologue_exterior.gd`；只替换天空/山脊背景绘制，悬崖边界、地面碰撞、遭遇计时、Boss 出生点与救援转场仍由逻辑控制。
- 状态：已写入 `development`，仍待 Godot 4.6.1 实机视觉验收。

### A0 Surgery Foreground Props
- File: `assets/art/backdrops/surgery_foreground_props.svg`
- Creator: Nereis-Hero project artwork (original SVG authored for the A0 surgery ward).
- License: Project original; intended for use and modification within Nereis-Hero.
- Contents: Operating table, snapped restraint straps, instrument trolley, wall-mounted tools, suspended lamp, specimen jars, and cracked tile chips.
- Integration: `scripts/levels/escape_prologue.gd`; visual-only texture layer. Existing CharacterBody2D/StaticBody2D collision, pickup locations, interaction focus, catwalks, and progress barriers remain separately controlled.
- Status: Source integration committed to `development`; Godot 4.6.1 runtime visual and import acceptance pending.

### A0 手术室前景道具
- 文件：`assets/art/backdrops/surgery_foreground_props.svg`
- 作者：Nereis-Hero 项目原创 SVG。
- 授权：项目原创，供 Nereis-Hero 项目内使用和修改。
- 内容：手术台、断裂束缚带、器械推车、墙面工具架、悬挂灯、标本瓶与碎裂地砖。
- 接入：`scripts/levels/escape_prologue.gd`；仅作为视觉纹理层。现有角色/静态物理碰撞、拾取点、交互焦点、高路平台与进度闸门仍独立控制。
- 状态：已写入 `development`；仍待 Godot 4.6.1 实机视觉与导入验收。
