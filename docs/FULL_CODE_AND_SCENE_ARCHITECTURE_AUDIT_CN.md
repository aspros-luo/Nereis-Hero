# Nereis-Hero 全项目代码与场景架构审计

- 审计分支：`feature/story-map-progression`
- 基线提交：`1313d25b8976a59426f5aa50fd736589e0838cfd`
- 审计状态：进行中；本文件不是完成报告。第 2 节记录最初基线风险，当前状态以第 9 节之后的最新复核为准。
- 强制规则：场景结构必须由可在 Godot 编辑器中查看的 `.tscn` 节点树定义；脚本负责行为、状态与运行时协调。不得以代码生成节点替代编辑器中的场景设计。

## 1. 仓库盘点

最初基线递归 Git tree 共 544 个文件；当前提交递归 Git tree 共 602 个文件（130 个 GDScript、210 个 `.tscn`、17 个 Python、184 个 Markdown，以及资源、配置和数据文件）。不同时间点的新增文件不应与最初基线混为一谈；此为目录盘点，不等于每个文件都已完成语义审计。

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
- `scripts/core/localization.gd`：约 60 KB，主要为多语言文本表；不得将文本数据量误判为冗余业务代码。
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
| `scripts/levels/escape_prologue.gd` | 512 行；包含 23 处常见节点类型的 `.new()`，23 处 `add_child()` | 手术台、主角、碰撞、线索、拾取物、休息点、出口、地板、边界、HUD 等由脚本搭建；P0 |
| `scripts/world/world.gd` | 420 行；7 处常见节点类型的 `.new()`，11 处 `add_child()` | 持久主角、碰撞、相机、HUD、过渡门和触发器由脚本搭建；P0 |
| `scripts/levels/greybox_world_region.gd` | 5,253 行；44 处常见节点类型的 `.new()`，36 处 `add_child()` | 单个脚本混合区域几何、主角、敌人、拾取物、门和其他结构；P0 |
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

- [x] 从 GitHub 重新读取当前版本，确认 `world.tscn` 有 7 个显式节点声明（Player 实例内部的节点另计）。
- [x] 源码模式检查确认 `boot.gd` 与 `scene_transition.gd` 不再调用节点 `.new()` / `add_child()`。
- [ ] Godot 4.6.1 导入和场景解析：BLOCKED。
- [ ] 编辑器节点树与全屏遮罩布局验收：BLOCKED。
- [ ] 世界场景启动、A5-R01 载入、房间切换、存档继续与转场失败恢复 smoke test：BLOCKED。


## 10. 重点脚本职责与冗余复核（源码级）

对 7 个高风险脚本进行了源码读取和函数/节点构建模式计数。该轮没有发现这些文件内部重复定义同名函数；这不代表不存在跨文件重复逻辑或死代码。

| 文件 | 行数 | 常见节点 `.new()` | `add_child()` | 当前判断 |
|---|---:|---:|---:|---|
| `scripts/levels/greybox_world_region.gd` | 5,253 | 44 | 36 | 主要结构生成集中点，必须拆分；内部回调不能仅因同文件调用次数少就删除 |
| `scripts/player/hero.gd` | 1,625 | 8 | 14 | 移动、战斗、共鸣、视觉和调试职责混合，需按组件边界拆分 |
| `scripts/core/world_state.gd` | 1,264 | 1 | 1 | 目前主要是状态/存档职责；需要继续检查字段重复、保存/恢复一致性，暂不建议按文件大小重写 |
| `scripts/core/localization.gd` | 1,386 | 0 | 0 | 主要是多语言文本表与少量静态查询函数；这是数据量，不应误判为冗余业务代码 |
| `scripts/ui/game_hud.gd` | 689 | 31 | 39 | P0 场景结构违规；HUD 主界面和弹层应由场景节点定义，脚本只更新内容、可见性和状态 |
| `scripts/world/world.gd`（根节点迁移后） | 391 | 3 | 7 | 主角/HUD 已迁移；剩余构建主要集中在房间出口和捷径触发器，继续迁移到可复用场景 |
| `scripts/levels/escape_prologue.gd`（迁移前基线） | 512 | 23 | 23 | A0 场景结构违规，列为下一批迁移对象 |

### 关于冗余代码的删除标准

函数出现次数、命名相似或文件很大，都不足以证明代码无用。下列情况必须继续查证后才能删除：
- 信号回调可能由 `.tscn` 的连接或 `connect(Callable)` 调用；
- 公共方法可能由其他脚本通过 `call()`、属性方法检查或组查询调用；
- 场景/资源路径可能只出现在 JSON 合同、存档恢复映射或验收脚本；
- 看似重复的房间/运行时场景可能承担不同入口、出生点或碰撞合同。

目前已安全移除的重复实现仅限：主菜单原有的节点构建函数整体删除、未使用的菜单节点变量删除，以及转场遮罩重复设置的 layer 属性删除。尚未对未知引用的业务函数做批量删除。

### 静态审计工具修正

`tools/audit_scene_authorship.py` 已修正资源路径匹配和 `static func` 识别规则。该工具尚未在完整工作树中运行，因此其实际输出和误报率仍待本地运行复核。


## 11. A0 序章场景结构迁移

- `scenes/escape_prologue.tscn` 已从只有根节点的场景，改为显式定义 32 个节点：地板、左右边界、手术台、六段可选高路、Hero 与碰撞体/相机、线索、两件拾取物、休息点与视觉子场景、出口与交互提示、HUD。
- `scripts/levels/escape_prologue.gd` 已删除常驻节点的 `.new()` 构建代码，改为引用 `$Hero`、`$HUD`、`$VillageRoadExit` 和 `$SurgicalMark`；平台绘制矩形由实际平台节点和碰撞形状读取，避免代码与场景重复维护六段平台坐标。
- 伏击守卫与战斗封锁体分别通过 `scenes/enemies/experiment_warden.tscn`、`scenes/rooms/prologue_progress_barrier.tscn` 实例化，避免用代码直接构建其根节点与主碰撞体。
- 序章控制器当前没有常见节点类 `.new()` 调用；剩余的两个 `add_child()` 调用用于把预制场景实例加入场景树，这是运行时生成敌人/封锁体的正常实例化流程。
- 提交：`736dd1d5ebff4e687009b148934fb9567f343464`、`9ac2c815ea2ca2c43191c261bb32f15f1355585f`、`9add5002675fdd1fc975d71c4d00bf73be1b53c6`、`f54ffa872c6906d4163d8796e71bf0a084767442`。

### A0 仍未完全合规的子系统

- 当前 `game_hud.gd` 不再使用 `.new()` 或 `add_child()` 搭建 HUD；`game_hud.tscn` 已有 40 个显式节点。
- 当前 `hero.tscn` 已显式包含 HeroSystem、AttackHitbox、Hurtbox 与 HeroCamera；`hero.gd` 剩余的 `add_child()` 用于实例化骨骼视觉、命中特效、抓钩锚点、共鸣目标、调试墙和死亡转场等预制场景，仍需逐项判断哪些应改为常驻节点，哪些确属运行时对象。
- `experiment_warden.gd` 当前没有常见节点类 `.new()` 调用，但会实例化战斗组件；需核对 `experiment_warden.tscn` 的节点树和这些组件是否应常驻预置。
- Godot 4.6.1 导入/解析与 A0 实机流程均尚未执行，状态为 BLOCKED。


## 12. 全部 GDScript 第一轮静态扫描（当前提交 bad696dda96502bbe1c48ac827029183dd983808）

本轮逐个读取了仓库当前版本的 130 个 `.gd` 文件，并对常见的节点构造调用、`add_child()`、`PackedScene.instantiate()` 和同文件重复函数声明做了模式扫描。

### 扫描结果

- [x] 130/130 个 GDScript 已进行模式扫描。
- [x] 未发现同一脚本内重复定义的同名函数。
- [x] Git tree 中未发现文件内容 SHA 完全相同的重复文件组。
- [ ] 这不代表没有跨文件重复逻辑、死代码或功能重复；需要结合所有调用方、场景绑定、合同、存档路径和调试入口继续确认。
- [ ] 未执行 Godot 4.6.1 导入或运行，因此解析和运行时验收仍为 BLOCKED。

### 高优先级场景结构风险

以下场景的当前 `.tscn` 仅有根节点，节点由对应脚本创建。它们必须迁移为编辑器可见节点树，或者在证明完全不再使用后整体删除；不能保留“空场景 + 大量代码搭建”的形式：

| 场景 | 绑定脚本 | 源码扫描观察 |
|---|---|---|
| `scenes/ancient_research_lab.tscn` | `scripts/levels/ancient_research_lab.gd` | 约 20 处常见节点 `.new()`、16 处 `add_child()` |
| `scenes/church_final_demo.tscn` | `scripts/levels/church_final_demo.gd` | 约 27 处 `.new()`、23 处 `add_child()` |
| `scenes/ending_fire_demo.tscn` | `scripts/levels/ending_fire_demo.gd` | 约 28 处 `.new()`、24 处 `add_child()` |
| `scenes/ending_paradise_demo.tscn` | `scripts/levels/ending_paradise_demo.gd` | 约 25 处 `.new()`、22 处 `add_child()` |
| `scenes/royal_tomb_boss.tscn` | `scripts/levels/royal_tomb_boss.gd` | 约 16 处 `.new()`、12 处 `add_child()` |
| `scenes/mite_resonance_demo.tscn` | `scripts/levels/mite_resonance_demo.gd` | 约 14 处 `.new()`、11 处 `add_child()` |

这些是代码生成节点的明确候选，不应仅凭文件名就删除。下一步必须先确认它们是否由主菜单、剧情、结局评估、测试工具或存档恢复引用，再决定“场景化”还是“安全删除”。

### 其他重要发现

- `scripts/core/world_map_test_menu.gd` 原本动态创建背景、布局、地图预览、24 个入口按钮和页脚按钮；本轮已将这组结构迁移到 `scenes/world_map_test_menu.tscn`。
- `scripts/core/world_map_test_menu.gd` 目前不再调用节点 `.new()`、`add_child()` 或 `instantiate()`；入口按钮在场景树中预先存在，脚本只将按钮与入口数据绑定。
- `scripts/levels/contract_room_region.gd`、`scripts/levels/room_world_prototype.gd` 和 `scripts/levels/route_scene.gd` 没有同名的 `.tscn`；这可能表示它们是继承脚本、由其他场景复用的脚本或孤立旧代码，需要检查引用后再判断。
- 多个调试预览脚本仍会创建临时 UI/预览节点。调试工具也应优先使用编辑器可见的场景节点；如果仅为编辑器临时工具，需明确标注用途并与游戏运行场景分开。
- `scripts/levels/greybox_world_region.gd` 当前 5,166 行、约 226 KB；脚本不再大量调用 `Node.new()`，但仍通过多处 `PackedScene.instantiate()` / `add_child()` 装配敌人、拾取物、Hero、HUD、地板、墙、门、区域房间与交互物。后续应拆分职责并让固定地形和常驻对象直接存在于对应场景树中；只保留确实由世界状态/玩家行为决定的动态实例化。

## 13. 第三批实际重构：宏观地图验收菜单

### 已修改

- `scenes/world_map_test_menu.tscn` 从只有一个根节点，扩展为 38 个显式节点：背景、边距容器、标题与说明、宏观地图预览、滚动容器、24 个区域入口按钮、重置测试状态按钮和返回主菜单按钮。
- `scripts/core/world_map_test_menu.gd` 从 164 行缩减到 92 行；删除整段 `_build_ui()` 及所有运行时控件构建逻辑。
- 脚本通过 `@onready` 获取 RegionGrid、ResetButton、BackButton，并把预置按钮绑定到入口数据；保留原有测试标志、区域启动与返回主菜单行为。
- 最新提交：场景 `1e23da59a8ba231645a63ed7f8fc2265eebd2f55`；脚本 `bad696dda96502bbe1c48ac827029183dd983808`。

### 源码级验证

- [x] 从 GitHub 重新读取提交后的场景，确认共有 38 个显式节点声明。
- [x] 从 GitHub 重新读取脚本，确认节点 `.new()`、`add_child()` 和 `.instantiate()` 调用均为 0。
- [ ] Godot 4.6.1 导入/解析：BLOCKED。
- [ ] 编辑器中检查 24 个按钮、地图预览与滚动布局：BLOCKED。
- [ ] 实际点击所有入口、重置测试状态和返回主菜单：BLOCKED。

## 14. 当前下一步顺序

1. 继续检查根节点场景仍由脚本构建的旧 Demo/结局场景；先做引用图，再决定迁移或删除。
2. 审计 `scripts/levels/greybox_world_region.gd` 的所有 `PackedScene.instantiate()` 调用点，按固定地形、常驻对象、条件对象和瞬时效果分类。
3. 对 Hero 与敌人的碰撞组件、骨骼视觉、死亡转场等节点，逐个确认应由 `.tscn` 常驻声明还是作为独立场景动态实例化。
4. 对所有被标记为“可能冗余”的脚本和场景进行引用闭包检查后再删；不得仅凭文件名、体积或未找到同名场景就删除。
5. 完成静态检查后，在 Godot 4.6.1 下逐批执行导入、解析、关键场景加载和功能 smoke test。


## 15. 第四批实际重构：古代研究所场景与休整点

### 场景结构迁移

- 新增 `scenes/enemies/research_husk.tscn`，显式定义 ResearchHusk 根节点、主碰撞体、AttackHitbox 和 Hurtbox；敌人脚本不再需要由区域脚本用 `CharacterBody2D.new()` 临时拼装敌人主体与碰撞结构。
- `scenes/ancient_research_lab.tscn` 从只有根节点扩展为 16 个显式节点：地板与碰撞、左右边界与碰撞、Hero、ResearchHusk、三个调查点、休整点、出口、Narrative 和 HUD。
- `scripts/levels/ancient_research_lab.gd` 从 210 行缩减为 121 行，删除运行时创建地板、边界、主角、线索、休整点、出口、HUD 与 Narrative 的代码；改为使用 `@onready` 节点引用并连接信号。
- 主角死亡后 ResearchHusk 仍需恢复，因此脚本只通过 `RESEARCH_HUSK_SCENE.instantiate()` 重生预制敌人场景，不再通过 `CharacterBody2D.new()` 和脚本赋值来构造对象。
- `scripts/world/rest_point.gd` 删除运行时补建 `RestVisual` 子节点的后备逻辑。休整点的视觉节点必须由 `scenes/world/rest_point.tscn` 声明，缺少节点时应暴露场景合同错误，而不是静默生成替代结构。
- 提交：ResearchHusk 场景 `75bc61cc18fe83b2ac22877555ad367d69490194`；研究所场景 `12712a2714616fcdcf77bf95464dad45c12a2fb1`；研究所脚本 `16739ce287dc210443c81325a4e3ab2608b09635`；休整点行为清理 `08f61d37b86ef31788e0529ca022aff8225c7d12`。

### 源码级复核

- [x] 当前研究所场景声明 16 个节点；所有外部场景和脚本资源路径均在当前 Git tree 中存在。
- [x] ResearchHusk 场景声明 4 个节点，包含主碰撞、攻击盒和受击盒；其依赖的 hitbox/hurtbox 子场景路径均存在。
- [x] `ancient_research_lab.gd` 常见节点 `.new()` 调用为 0；只保留一次预制敌人场景实例化和一次 `add_child()`，用于死亡后的敌人重生。
- [x] `rest_point.gd` 的 `.new()`、`instantiate()` 和 `add_child()` 调用均为 0。
- [ ] Godot 4.6.1 导入/解析：BLOCKED。
- [ ] 研究所场景在编辑器中的节点树与布局检查：BLOCKED。
- [ ] 调查三个线索、休息存档、敌人死亡、主角死亡后敌人重生、出口切换：BLOCKED。

### 当前仍需注意

- 研究所场景的视觉背景仍由根脚本的 `_draw()` 绘制；本批次只将游戏对象与碰撞结构迁移为显式节点，未重做美术层。
- `ResearchHusk` 的攻击盒和受击盒使用可复用子场景；这些是场景资源实例，不是用 `Node.new()` 创建节点树。
- 不应将本批次的源码级检查误报为 Godot 实机通过。完整验证仍需本地 Godot 4.6.1。


## 16. 第五批实际重构：50 个合同房间改为显式节点树

### 完成的架构变更

- 新增 `scenes/world/contract_room_exit.tscn`，作为合同房间的可复用出口预制场景；包含 Area2D、76×100 碰撞形状与 Prompt 子场景。
- 将 `tools/room_spatial_contracts_a1_a3.json` 中的 50 个房间空间合同序列化为 50 个正式 `.tscn` 节点树。节点直接保存在场景文件中，不再依赖运行时 GDScript 创建地形和出口。
- 50 个房间合计显式声明 **1,395 个节点**：50 个根节点、523 个地形 StaticBody2D、523 个地形 CollisionShape2D、149 个出口场景实例，以及每个房间预置的 Hero、Narrative、HUD（各 50 个）。
- 375 个 one-way 地形碰撞也在各自场景中设置；场景树中的地形名称与合同的 terrain ID 对齐。
- `scripts/levels/contract_room_region.gd` 移除了 `_build_terrain()`、`_build_exits()`、`_spawn_hero()`、`_spawn_ui()`、`_add_character_collision()` 以及相应节点构造常量。当前控制器不再调用 `.new()`、`add_child()` 或 `PackedScene.instantiate()`，只读取现有节点、核对合同、绑定行为和绘制当前视觉层。
- 控制器现在在 `_enter_tree()` 中提前准备 WorldState，确保预置子节点执行 `_ready()` 前共享运行状态已经复位。
- `scripts/world/interaction_door.gd` 不再在缺少 Prompt 时静默创建替代节点；Prompt 必须由 `interaction_door.tscn` 或 `contract_room_exit.tscn` 显式提供。

### 源码级验证

- [x] 50 个房间全部匹配到空间合同和目标场景路径。
- [x] 50/50 个场景通过节点数量、terrain ID、exit ID、父节点路径与资源引用静态检查；场景结构在移除临时模式开关时没有变化。
- [x] 抽查 A0-R01、A1-R01、H08-R01：地形、出口、Hero、Narrative、HUD 均直接存在于 `.tscn` 中。
- [x] `contract_room_region.gd` 当前 385 行，节点 `.new()`、`add_child()`、`.instantiate()` 调用均为 0；旧场景构建函数已移除。
- [x] `interaction_door.gd` 当前节点 `.new()`、`add_child()`、`.instantiate()` 调用均为 0。
- [ ] Godot 4.6.1 项目导入与脚本解析：BLOCKED。
- [ ] 50 个场景逐个打开、碰撞形状检查与房间间转场实测：BLOCKED。
- [ ] 确认所有 one-way 平台、出口条件、出生点、HUD 与存档恢复：BLOCKED。

### 重要边界

这一步只把已有空间合同中的节点结构写入场景文件，**没有重新设计房间地形，也不代表这些房间已经达到最终《空洞骑士》式地图品质**。现有 `_draw()` 仍负责绘制背景、地形表面与区域剪影；之后的地图设计工作应另行审计视觉层和真实地形职责，不应把这批节点迁移误认为地图最终完成。

## 17. 最新状态与下一批

- 最新已提交分支：`feature/story-map-progression`
- 最新已确认提交：`6a85b9b9e8a24d9123e1e305ddd4bacfc814a914`
- 当前完成：宏观地图验收菜单、古代研究所场景、休整点与门的 Prompt 子节点合同，以及 50 个合同房间的显式节点树迁移。
- 当前未完成：旧 Demo/结局场景、`greybox_world_region.gd` 的运行时装配、`route_scene.gd`、角色预览/调试场景及其他脚本中的节点创建行为审计。
- 下一批优先检查 `scripts/levels/route_scene.gd` 和仍只有根节点的教堂/结局 Demo：先判定它们的真实引用关系，再把常驻地形、主角、NPC、出口、检查点、HUD 与 Narrative 迁移到场景树。不可只按文件名删除。
