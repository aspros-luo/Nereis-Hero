# 美术资源接入阶段 1 / Art Asset Integration — Phase 1

**分支 / Branch:** `development`  
**目标 / Goal:** Make the playable world read as a dark-fantasy game at first launch, without changing map logic.

## 中文

### 本阶段已写入仓库

- 新增 `assets/art/backdrops/forest_backdrop.svg`：雾林、树冠、近远景剪影。
- 新增 `assets/art/backdrops/ruins_backdrop.svg`：破败城区、堡垒、拱窗和残墙。
- 新增 `assets/art/backdrops/church_backdrop.svg`：哥特尖塔、尖拱窗、冷色圣堂剪影。
- 新增 `assets/art/backdrops/eldritch_backdrop.svg`：终局异象、非欧几何环与虚空层。
- 新增 `assets/art/backdrops/stone_floor_strip.svg`：石板、裂缝、磨损和地面边缘。
- 修改 `scripts/levels/greybox_world_region.gd`：根据区域 ID 选择背景，并将平坦地面替换为纹理地面。背景仅负责绘制，不创建碰撞体、不移动出口、不改变出生点或存档标记。

这些 SVG 是为本项目绘制的可替换视觉资源，不是外部游戏的拆包素材。它们是第一轮场景底图，不代表角色、敌人和动画美术已完成。

### 外部素材候选

优先选用许可清楚、能直接打包进项目的素材：

- [0x72 — 16x16 Dungeon Tileset (CC0)](https://0x72.itch.io/16x16-dungeon-tileset)：地牢、角色和武器资源。
- [Kaishido — Dark World Asset Pack (CC0)](https://kaishido.itch.io/dark-world)：暗色环境、树木、蘑菇和角色 idle/walk 精灵表。
- [Zoltan Kosina — 16x16 Dark Dungeon Tileset (CC0)](https://kosinaz.itch.io/16x16-dark-dungeon-tileset)：更暗的地牢地面、墙体和陷阱。
- [TPC — 2D Medieval Castle Dungeon Tileset](https://thepixelistcreator.itch.io/2d-medieval-castle-dungeon-tileset)：免费城堡地牢平台与火把动画；导入前复核其页面当前说明和署名要求。
- [The Spriters Resource](https://www.spriters-resource.com/)：仅作动画参考或在明确适用的非商业原型中临时使用；该站说明素材属于原始权利人，不能默认用于商业发行。

**资源状态说明：** 上述外部资源目前是已检索的候选清单，不声称其 PNG/ZIP 已经下载或导入。当前实际接入的是本仓库里的原创 SVG 背景与地面纹理。

### 下一步

1. 先接入一套可合法使用的主角动画与敌人精灵表，验证方向翻转、帧尺寸、攻击判定和受击状态。
2. 为地面平台加入可重复拼接的边缘/侧壁纹理；不改变平台碰撞形状。
3. 给森林、城市、地下遗迹、教会四类区域建立素材映射表，逐区替换而非一次性重写。
4. 在 Godot 4.6.1 实际运行并检查 SVG 导入、画面缩放、远景层级、平台可读性和帧率。

### 验收状态

- 代码和资源已提交到 `development`。
- 当前环境没有运行 Godot，因此**尚未完成实机验收**；请勿将静态代码修改等同于运行通过。
- 地图拓扑、碰撞、出口、隐藏路径和存档逻辑没有被有意修改；仍需实机回归确认。

---

## English

### Committed in this phase

- `forest_backdrop.svg`: misty forest, canopy silhouettes, layered depth.
- `ruins_backdrop.svg`: broken city walls, fortress silhouettes, arched windows.
- `church_backdrop.svg`: Gothic spires, lancet windows, sacred architecture.
- `eldritch_backdrop.svg`: terminal anomaly, non-Euclidean rings, void atmosphere.
- `stone_floor_strip.svg`: worn flagstones, cracks, seams, and a readable ground edge.
- `scripts/levels/greybox_world_region.gd` now selects a backdrop by region ID and draws a textured floor strip. These are visual-only changes: no collision bodies, exits, spawn positions, or save flags are intentionally changed.

These SVGs are original project artwork, not ripped game assets. They establish a first environmental art pass; character sprites, enemy sprites, and animation replacement remain unfinished.

### External asset candidates

- [0x72 — 16x16 Dungeon Tileset (CC0)](https://0x72.itch.io/16x16-dungeon-tileset): dungeon, character, and weapon sprites.
- [Kaishido — Dark World Asset Pack (CC0)](https://kaishido.itch.io/dark-world): dark environment, trees, mushrooms, and idle/walk character sheet.
- [Zoltan Kosina — 16x16 Dark Dungeon Tileset (CC0)](https://kosinaz.itch.io/16x16-dark-dungeon-tileset): dark floor/walls and traps.
- [TPC — 2D Medieval Castle Dungeon Tileset](https://thepixelistcreator.itch.io/2d-medieval-castle-dungeon-tileset): free castle-dungeon platforms and animated torches; re-check current attribution terms before integration.
- [The Spriters Resource](https://www.spriters-resource.com/): useful for animation research or temporary prototypes only where permitted. Its own guidance says the assets remain the property of their original rights holders; commercial use must not be assumed.

**Asset status:** external packs above are researched candidates only. Their PNG/ZIP files have not yet been downloaded or imported. The assets actually integrated in this commit are the original SVG backdrops and floor strip stored in this repository.

### Next steps

1. Integrate a permitted hero animation sheet and enemy sprites; validate facing, frame size, attack hitboxes, and hurt states.
2. Add reusable platform edge and side-wall textures without changing collision geometry.
3. Map assets by forest, city, underground ruin, and church biome instead of rewriting all levels at once.
4. Run the project in Godot 4.6.1 and verify SVG import, scaling, layer order, platform readability, and frame rate.

### Acceptance status

- Code and SVG assets are committed to `development`.
- Godot runtime verification has **not** been performed in the current environment.
- No map topology, collision, exit, hidden-route, or save logic was intentionally changed; runtime regression testing is still required.
