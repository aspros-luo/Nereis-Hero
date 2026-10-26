# Nereis-Hero 全项目代码与场景架构审计

- 审计分支：`feature/story-map-progression`
- 基线提交：`1313d25b8976a59426f5aa50fd736589e0838cfd`
- 审计状态：进行中；本文件不是完成报告。
- 强制规则：场景结构必须由可在 Godot 编辑器中查看的 `.tscn` 节点树定义；脚本负责行为、状态与运行时协调。不得以代码生成节点替代编辑器中的场景设计。

## 1. 仓库盘点

基线递归 Git tree 共 544 个文件：130 个 GDScript、155 个 `.tscn`、16 个 Python、183 个 Markdown，以及资源、配置和数据文件。此为目录盘点，不等于逐文件审计完成。

## 2. 已确认的 P0 架构违规

以下结论来自基线分支上的源码读取，需在整改后重新复核：

1. `scripts/levels/greybox_world_region.gd` 约 227 KB，存在大量 `Node.new()` / `add_child()`，负责创建敌人、拾取物、主角、相机、HUD、地板、墙体、出口与房间等。该脚本承担了本应由场景树定义的结构，必须拆分并迁移到真实 `.tscn` 节点。
2. `scenes/escape_prologue.tscn` 目前仅定义根节点 `EscapePrologue` 并挂载脚本；`scripts/levels/escape_prologue.gd` 在运行时创建手术台、主角、相机、敌人、出口触发器、线索、绷带、记录物、休息点、碰撞体和 HUD。打开场景时无法在编辑器中检查这些结构，直接违反强制规则。
3. `scenes/world/world.tscn` 节点结构很薄；`scripts/world/world.gd` 运行时创建玩家、碰撞体、相机、HUD、房间过渡点与门。必须核对职责并迁移场景结构。
4. `scripts/player/hero.gd` 仍在运行时创建攻击/受击盒、部分共鸣目标/墙体及视觉效果。需分类：场景常驻结构应迁移到 `.tscn`；真正瞬时的命中特效等动态对象可保留动态实例化，但优先使用独立可复用场景，不能将动态创建当作常驻结构的替代品。
5. `scripts/levels/a2_room_runtime.gd` 动态创建部分 UI、休息点和过渡区域；需要逐项确认其是否属于场景设计结构，并改为节点树/可复用子场景。

## 3. 高风险复杂度与重复实现候选（尚未判定为冗余）

- `scripts/levels/greybox_world_region.gd`：超大共享区域控制器，可能混合地形生成、敌人、拾取物、UI、房间和出口职责。
- `scripts/player/hero.gd`：约 65 KB，需检查战斗、移动、视觉、共鸣和节点构建职责是否混杂。
- `scripts/core/world_state.gd`：约 50 KB，需检查状态所有权、重复字段和持久化边界。
- `scripts/core/localization.gd`：约 91 KB，需检查数据与逻辑是否混杂；不得仅因文件大而删除内容。
- A2 有六个正式地形场景和六个 runtime 场景；A5 存在多套命名不同的场景目录。需基于引用、入口、合同和测试判断用途，禁止只按文件名删除。
- 角色视觉相关目录分布于 `scripts/character/`、`scripts/characters/` 与 `scripts/player/`，需核实它们是否属于不同系统或存在重复实现。

## 4. 清理与验收顺序

1. 建立完整文件/场景引用清单，确认主入口、自动加载、场景引用、资源引用、脚本继承与测试引用。
2. 先迁移场景常驻节点：保留节点名称与路径兼容性，优先重构 `escape_prologue.tscn`、世界根场景及共享区域场景。
3. 将重复场景构建逻辑迁移为可复用的 `.tscn` 子场景；脚本只绑定行为和配置。
4. 对重复/孤立代码做引用审计后再删除；不删除仍被剧情、存档、地图连接、调试或验收流程引用的代码。
5. 检查所有 `.tscn` 的资源路径、节点路径、脚本绑定、autoload 与输入映射。
6. 运行 Godot 4.6.1 项目导入/解析检查与现有静态验证；再运行场景加载和关键流程 smoke test。静态检查通过不等于运行时通过。
7. 更新 `docs/ACCEPTANCE_REPORT.md` 与本审计报告，明确 PASS / FAIL / BLOCKED；只有所有阻断项关闭后，才允许开始下一阶段地图工作。

## 5. 验收门槛

- [ ] 逐一盘点并审计全部源码、场景、配置和工具文件。
- [ ] 所有场景结构在编辑器 Scene 面板可见；无通过脚本代建的常驻地形、玩家、敌人、交互点、门、触发器、HUD 或常驻碰撞结构。
- [ ] 仅保留合理的运行时动态对象；优先实例化可复用的独立场景。
- [ ] 删除的代码均有引用证据，且不破坏存档、地图连接、剧情和状态契约。
- [ ] 全部场景资源和脚本引用有效，无解析错误。
- [ ] 静态验证和 Godot 4.6.1 场景加载验证完成；未验证项目明确标记为 BLOCKED。
- [ ] 提交最终审计报告和变更摘要后，再恢复 Hero 地图开发。


## 6. 第二轮源码核查（2026-10-26）

### 已直接确认的结构违规

| 文件 | 观测结果 | 结论 |
|---|---|---|
| `scenes/escape_prologue.tscn` | 只有根节点 `EscapePrologue`，仅挂载 `escape_prologue.gd` | 编辑器中看不到真实场景结构；P0 |
| `scripts/levels/escape_prologue.gd` | 512 行；包含 23 处常见节点类型的 `.new()`，9 处 `add_child()` | 手术台、主角、碰撞、线索、拾取物、休息点、出口、地板、边界、HUD 等由脚本搭建；P0 |
| `scripts/world/world.gd` | 420 行；7 处常见节点类型的 `.new()`，7 处 `add_child()` | 持久主角、碰撞、相机、HUD、过渡门和触发器由脚本搭建；P0 |
| `scripts/levels/greybox_world_region.gd` | 5,253 行；44 处常见节点类型的 `.new()`，8 处 `add_child()` | 单个脚本混合区域几何、主角、敌人、拾取物、门和其他结构；P0 |
| `scripts/levels/a2_room_runtime.gd` | 385 行；6 处常见节点类型的 `.new()`，3 处 `add_child()` | 动态生成调试 UI、休息点和落差触发器；需迁移到场景节点/可复用场景 |
| `scripts/core/boot.gd` | 154 行；通过代码生成菜单控件 | 菜单节点树也应在 `boot.tscn` 中可见 |
| `scripts/core/scene_transition.gd` | 通过代码创建遮罩节点 | 转场遮罩属于常驻结构，建议在转场场景中声明；动画可继续由脚本驱动 |
| `scripts/player/hero.gd` | 1,625 行；动态创建战斗碰撞组件、共鸣墙/锚点及特效 | 需要区分常驻结构与真正瞬时对象；战斗盒和共鸣结构优先场景化，瞬时特效可实例化独立场景 |

以上数量为源码模式计数，统计范围是常见节点类的 `.new()` 与 `add_child()` 调用，不等同于所有节点构建行为的完整语义分析。

### 新增静态审计工具

新增 `tools/audit_scene_authorship.py`，只读检查：
- 场景节点数量与“仅根节点”场景；
- 脚本中的动态节点构建调用及其优先复核分类；
- 超长 GDScript；
- 同一脚本内重复定义的函数名；
- 文本资源中的缺失 `res://` 引用。

用法：

```bash
python3 tools/audit_scene_authorship.py
python3 tools/audit_scene_authorship.py --json reports/scene_authorship_audit.json
```

该工具是静态分诊工具，不会自动删除或重写代码。其结果必须人工复核；最终仍需 Godot 4.6.1 导入、解析和场景加载验证。当前环境仅能通过 GitHub 读取和提交源码，尚未在本轮运行该工具或 Godot，因此这两项状态必须保持为 BLOCKED，不能标为 PASS。

### 接下来的重构批次

1. **批次 A：主入口和菜单** — `boot.tscn` / `boot.gd`，使菜单控件在编辑器中可见。
2. **批次 B：A0 序章** — `escape_prologue.tscn` / `escape_prologue.gd`，先将常驻地形、主角、相机、碰撞、交互物与 HUD 迁移为节点树；伏击敌人可预先放置在场景树中并默认隐藏/禁用，触发时启用，而不是临时用 `.new()` 拼装。
3. **批次 C：世界根节点** — 将 `world.tscn` 中的 Player、Camera、HUD、RoomContainer、TransitionManager 等结构显式化；门和触发器改为可复用场景，由合同数据控制其状态与目标。
4. **批次 D：共享区域控制器** — 将 `greybox_world_region.gd` 按区域场景、敌人/拾取物场景、交互场景和纯行为控制器拆分。保留现有地图合同与节点路径兼容性，分区域迁移并逐次验证。
5. **批次 E：冗余清理** — 完成全项目引用图后，才删除重复或孤立实现；每项删除必须记录引用证据及替代实现。

## 7. 当前状态

- [x] 建立仓库文件基线与重点风险清单。
- [x] 确认多处“场景结构由脚本创建”的 P0 违规。
- [x] 新增只读场景作者性审计工具。
- [ ] 运行静态审计工具并复核所有输出。
- [ ] 完成全部 130 个 GDScript 的职责、重复定义、引用和死代码审计。
- [ ] 完成全部 155 个场景的节点树、资源和脚本引用审计。
- [ ] 完成 P0 场景结构迁移。
- [ ] 删除经引用证明无效的冗余代码。
- [ ] 在 Godot 4.6.1 下完成导入、解析、场景加载和关键流程验收。


## 8. 第一批实际重构：主菜单节点树

已在 `feature/story-map-progression` 完成主菜单结构迁移：

- `scenes/boot.tscn` 现在显式定义 14 个节点（包括根节点）：背景、氛围层、标题、副标题、菜单面板、继续/新游戏/地图验收按钮、语言标签与选项、状态标签、确认对话框和页脚。
- `scripts/core/boot.gd` 不再调用 `.new()` 或 `add_child()` 来搭建菜单；通过 `@onready` 节点路径取得控件，保留原有继续、新游戏、语言选择和地图验收行为。
- 移除了重构后不再需要的节点变量引用。
- 变更提交：`2fecfb0f070f163822f148f403451fd85980b6b3`（场景）与 `55ae380360f158144a0251f2c83456c1b2770d1e`、`5fb18542da8efb744e7412eeb871ed76dc58aaa9`（脚本绑定与清理）。

### 当前验证结果

- [x] 通过 GitHub 重新读取已提交文件，确认 `boot.tscn` 包含 14 个显式节点声明。
- [x] 通过源码模式检查，确认 `boot.gd` 的 `.new()` 调用为 0、`add_child()` 调用为 0。
- [ ] Godot 4.6.1 场景导入/解析：BLOCKED（本轮未连接本地引擎执行环境）。
- [ ] 编辑器实际打开并检查节点树与菜单布局：BLOCKED。
- [ ] 运行新游戏、继续游戏、语言切换和地图验收按钮的 smoke test：BLOCKED。

此批次只完成结构迁移，不代表整个项目审计完成，也不把未运行的测试标记为通过。后续以此模式继续重构 A0 序章与世界根场景。


## 9. 第二批实际重构：转场遮罩与世界根节点

### 转场遮罩

- 新增 `scenes/scene_transition.tscn`，明确声明 CanvasLayer 和全屏 FadeRect。
- `project.godot` 的 SceneTransition autoload 从脚本路径改为该场景路径。
- `scripts/core/scene_transition.gd` 改为通过 `$FadeRect` 取得遮罩，移除 `ColorRect.new()`、`add_child()` 和手动 resize 逻辑；遮罩尺寸改由全屏锚点负责。
- 移除了脚本中与场景属性重复的 layer 设置。
- 提交：`8120dd06c46fff0687303b2b02adcf5e6ad8e5ee`、`3ab21e8fef581d6fada461f62555f758975b7c9e`、`41367f2cfb346da516c3de6cbbc2e18c57996499`、`c4c05f3c802e8e7b86d5583a41d72fd78253030b`。

### 世界根节点

- `scenes/world/world.tscn` 现在显式声明 Player、CollisionShape2D、Camera2D、HUD、RoomContainer、TransitionManager 与场景内房间切换用 FadeLayer。
- `scripts/world/world.gd` 改为通过节点路径引用 Player、Camera2D 和 HUD，并删除创建常驻 Player/HUD 的两个构建函数。
- 保留 A5 合同解析、房间装配、房间边界相机配置与房间内过渡流程。
- 提交：`cf88bfd77ad7d59bf8e798b8254135e37c1d6cc7`、`68900b401acd6437f689be2cdc9b3df7f5091bdd`、`707119a55a8f998d0e0f15620895b888ed014231`、`4dbb47e36a5be3b1759dd99b946a08e9acddceea`。

### 尚未关闭的世界结构问题

`world.gd` 仍会在运行时创建房间过渡点和捷径交互点；这些对象需要迁移为可复用的独立场景，由合同数据配置实例属性。Hero 自身也会在 `hero.gd` 中创建战斗盒和 HeroSystem，HUD 仍在 `game_hud.gd` 中构建大量界面节点；这两项属于后续 P0/P1 迁移范围，不能因根场景已改造就视为全部符合规则。

### 验证状态

- [x] 从 GitHub 重新读取文件，确认 `world.tscn` 有 9 个显式节点声明。
- [x] 源码模式检查确认 `boot.gd` 与 `scene_transition.gd` 不再调用节点 `.new()` / `add_child()`。
- [ ] Godot 4.6.1 导入和场景解析：BLOCKED。
- [ ] 编辑器节点树与全屏遮罩布局验收：BLOCKED。
- [ ] 世界场景启动、A5-R01 载入、房间切换、存档继续与转场失败恢复 smoke test：BLOCKED。


## 10. 重点脚本职责与冗余复核（源码级）

对 7 个高风险脚本进行了源码读取和函数/节点构建模式计数。该轮没有发现这些文件内部重复定义同名函数；这不代表不存在跨文件重复逻辑或死代码。

| 文件 | 行数 | 常见节点 `.new()` | `add_child()` | 当前判断 |
|---|---:|---:|---:|---|
| `scripts/levels/greybox_world_region.gd` | 5,253 | 44 | 8 | 主要结构生成集中点，必须拆分；内部回调不能仅因同文件调用次数少就删除 |
| `scripts/player/hero.gd` | 1,625 | 8 | 11 | 移动、战斗、共鸣、视觉和调试职责混合，需按组件边界拆分 |
| `scripts/core/world_state.gd` | 1,264 | 1 | 1 | 目前主要是状态/存档职责；需要继续检查字段重复、保存/恢复一致性，暂不建议按文件大小重写 |
| `scripts/core/localization.gd` | 1,386 | 0 | 0 | 主要是多语言文本表与少量静态查询函数；这是数据量，不应误判为冗余业务代码 |
| `scripts/ui/game_hud.gd` | 689 | 29 | 23 | P0 场景结构违规；HUD 主界面和弹层应由场景节点定义，脚本只更新内容、可见性和状态 |
| `scripts/world/world.gd`（根节点迁移后） | 391 | 3 | 5 | 主角/HUD 已迁移；剩余构建主要集中在房间出口和捷径触发器，继续迁移到可复用场景 |
| `scripts/levels/escape_prologue.gd`（迁移前基线） | 512 | 23 | 9 | A0 场景结构违规，列为下一批迁移对象 |

### 关于冗余代码的删除标准

函数出现次数、命名相似或文件很大，都不足以证明代码无用。下列情况必须继续查证后才能删除：
- 信号回调可能由 `.tscn` 的连接或 `connect(Callable)` 调用；
- 公共方法可能由其他脚本通过 `call()`、属性方法检查或组查询调用；
- 场景/资源路径可能只出现在 JSON 合同、存档恢复映射或验收脚本；
- 看似重复的房间/运行时场景可能承担不同入口、出生点或碰撞合同。

目前已安全移除的重复实现仅限：主菜单原有的节点构建函数整体删除、未使用的菜单节点变量删除，以及转场遮罩重复设置的 layer 属性删除。尚未对未知引用的业务函数做批量删除。

### 静态审计工具修正

`tools/audit_scene_authorship.py` 已修正资源路径匹配和 `static func` 识别规则。该工具尚未在完整工作树中运行，因此其实际输出和误报率仍待本地运行复核。
