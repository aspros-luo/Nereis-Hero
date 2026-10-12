# 临时网络美术资源目录 / Temporary Online Art Source Catalog

> 用途：为宏观地图灰盒后的美术原型阶段建立候选素材来源。网络素材仅作为可替换的临时资源；导入前仍应保存来源、作者、原始页面、许可说明和下载日期。后续原创美术应通过同一套资源目录替换，而不改关卡逻辑。

## 当前阶段的资源策略

1. **优先使用可下载到仓库的本地文件**，不让运行中的关卡依赖外网 URL。
2. 纹理、背景、装饰物放在独立的 `assets/temp_external/` 目录，并使用统一的资源清单；不要把图片硬编码进地图逻辑。
3. 外部素材只用于背景、远景和非碰撞装饰。平台、敌人、出口、交互提示和 HUD 必须保持清晰。
4. 先挑选少量风格接近的资源建立视觉样板，再扩展到其余区域；不要将多个画风差异很大的包直接拼在同一屏。
5. 本阶段没有改动地图拓扑、碰撞、出生点、出口位置、鸣响门槛或存档逻辑。

## 候选资源

| 资源 | 适用方向 | 来源 |
|---|---|---|
| Forest and Dungeon Tilesets from Eman Quest | 死林、洞穴、地下遗迹的色彩/图块候选；CC0 | https://opengameart.org/content/forest-and-dungeon-tilesets-from-eman-quest |
| 32x32 Dungeon Tileset by stealthix | 地下砖墙、洞穴装饰原型；CC0 | https://opengameart.org/content/32x32-dungeon-tileset |
| 2D Medieval Castle Dungeon Tileset by TPC | 城堡、牢狱、火把、石墙候选；页面标注免费 | https://thepixelistcreator.itch.io/2d-medieval-castle-dungeon-tileset |
| Dark Fantasy Pixel Art World – DEMO by Marco Brito | 森林、地牢、墓园、道具的统一风格候选；页面说明可用于个人和商业项目 | https://marcomyly.itch.io/dark-fantasy-pixel-art-world-demo-tiles-props |
| DARK FANTASY SIDE-SCROLLER TILESET by SakPix | 哥特城堡、墓室、诅咒森林；可先评估免费 Demo | https://sakpix.itch.io/dark-fantasy-side-scroller-tileset |
| Dark Castle Tileset by Fabian Fuchs | 城堡内外环境候选；页面说明可用于商业与非商业项目 | https://fabian-fuchs.itch.io/dark-castle-tileset |
| Free dark-fantasy tileset directory | 持续发现同风格免费图块 | https://itch.io/game-assets/free/tag-dark-fantasy/tag-tileset |

## 区域映射建议

- **A2 灰烬森林 / H01 林间隐道**：死林树冠、根系、苔藓和稀疏孢子。背景不能覆盖平台边缘。
- **A3 被遗忘城区 / A9 王城外环**：破损石墙、屋顶轮廓、城门和稀疏窗光。
- **A4 旧水库 / A11 深层研究区**：湿石、拱券、管道、积水反光；水面效果只作装饰。
- **A5 旧战场 / A7 牢狱深处 / A8 王陵**：灰烬、断矛、铁栅、墓碑和低饱和石砖。
- **A6 修道院塔 / A10 大圣堂 / A12 内城**：尖塔、彩窗、拱券和宗教雕像；避免过亮的彩色装饰削弱压迫感。
- **A13 终局异象 / H08 原初空腔**：暂时保留程序化异象轮廓，不急于套用常规图块，避免削弱空间“不可能性”。
- **A0 手术所**：保留冷色程序化灯光和线缆；后续可替换为医疗器械、铁床、玻璃容器等独立装饰。

## 导入检查清单

- [ ] 记录原始页面、作者、许可和下载日期。
- [ ] 原图复制到 `assets/temp_external/<pack_name>/`，不直接覆盖原创资源。
- [ ] 检查透明通道、像素密度、过滤模式和缩放比例。
- [ ] 以独立背景/装饰节点接入，不改碰撞层和导航/出口节点。
- [ ] 在 Godot 中检查导入、运行和切场景后无缺失资源。
- [ ] 检查角色、敌人、出口提示与 HUD 的对比度。
- [ ] 原创替换时只改资源映射，不重写地图拓扑。

## 当前执行限制

当前工作环境无法直接下载外部二进制素材并把它们写入 Git 仓库，因此本提交先把来源与区域映射固化为清单；它**不代表上述素材已经导入游戏**。下一步应在可联网的开发环境下载所选资源，再执行实际的 Godot 导入与逐区域视觉验收。

---

# English

This catalog records candidate online art packs for the temporary visual-prototype phase. It does **not** claim that any listed binary asset has already been imported into the game.

- Prefer local project files over runtime URL dependencies.
- Keep third-party assets under `assets/temp_external/`; never overwrite original assets.
- Use external artwork for backgrounds and non-colliding decoration only. Keep platforms, enemies, exits, prompts, and HUD readable.
- Preserve each source page, author, license statement, and download date.
- Replace temporary artwork through resource mappings without changing level topology, collision, spawn points, exits, Resonance gates, or save logic.

The candidate links and region mapping above are shared with the Chinese section. The current environment cannot fetch external binary files into the repository, so downloading, Godot import, and runtime visual acceptance remain pending.
