# Nereis Hero

2D Soulslike 动作探索 RPG，属于 Nereis /《蜜忒之歌》世界。

## 项目入口

- Godot 启动场景：`res://scenes/boot.tscn`
- 新游戏序章：`res://scenes/escape_prologue.tscn`
- 引擎：Godot 4.6.x / GDScript / GL Compatibility
- 当前工作分支：`feature/story-map-progression`
- Hero 骨骼动画独立分支：`feature/hero-animation-system`

## 开始任何开发任务前

按以下顺序阅读，不需要先通读所有历史文档：

1. [项目文档治理合同](docs/PROJECT_DOCUMENTATION_GOVERNANCE_CN.md) — 文档权威层级、任务启动、清理和验收规则。
2. [开发协作条约](docs/DEVELOPMENT_WORKING_CHARTER_CN_EN.md) — 工程与叙事硬约束。
3. [当前开发状态](docs/DEVELOPMENT_STATUS.md) — 当前进度、阻塞项与最近验证结果。
4. 按本次任务读取对应的权威设计基线、场景、脚本和验收合同；历史交接、开发日志和旧审计默认不作为启动必读。

## 权威设计文档

### 世界观与叙事

- [世界观总档案](docs/WORLD_BUILDING_BIBLE_CN.md) — 世界事实、人物知识边界、已确认 / 候选 / 待定设定；世界观设定的主要权威来源。
- [剧情基础摘要](docs/STORY.md) — 主线与结局的精简摘要，便于快速恢复上下文；详细裁定以世界观总档案和专门合同为准。
- [开发者剧情记忆](docs/DEVELOPER_STORY_MEMORY.md) — 大型历史讨论档案；仅在追溯明确决策来源时检索，不作为日常启动必读。
- [跨作品剧情基准](docs/CROSS_GAME_STORY_CANON_CN.md) — 仅记录 Hero 与 Lullaby 必须一致的共同设定。
- [结局条件设计合同](docs/ENDING_CONDITION_DESIGN_CN.md) — 结局所需探索事实、道具状态和特殊事件；程序实现状态以开发状态和源码审计为准。
- [世界叙事线索台账](docs/WORLD_NARRATIVE_CLUE_LEDGER_CN.md) — 线索分布、知识权限与证据链。
- [核心人物设计池](docs/CORE_NPC_DESIGN_POOL_CN.md) — 人物候选与设计边界；候选内容不自动成为正史。

### 地图与场景

- [世界地图总规划](docs/WORLD_MAP_MASTER_PLAN_CN.md)
- [世界网络拓扑](docs/WORLD_NETWORK_TOPOLOGY_CN.md)
- [完整世界地图图集](docs/COMPLETE_WORLD_MAP_ATLAS_CN.md)
- [互联箱庭设计原则](docs/INTERCONNECTED_BOX_WORLD_DESIGN_CN.md)
- [A2 雾林与钟墓设计基线](docs/maps/A2_DESIGN_BASELINE_CN.md)

地图设计文件中的草案、旧版灰盒记录和静态验证报告不能替代当前区域设计基线，也不能证明 Godot 实机验收通过。

### 人物与开局设计

- [核心人物设计池](docs/CORE_NPC_DESIGN_POOL_CN.md) — 候选人物资料池，不自动成为正史。
- [核心人物独立人物弧线](docs/CORE_CHARACTER_ARCS_V1_CN.md) — 人物动机与独立生活方向；具体人物事实以世界观总档案为准。
- [主角开局叙事骨架](docs/PROTAGONIST_OPENING_NARRATIVE_V1_CN.md) — A0 开局流程基线；具体场景实现以源码和验收合同为准。

### 文档使用边界

- `DEVELOPER_STORY_MEMORY.md`、历史交接、旧版地图提案和开发日志均为追溯资料，不列入每次任务的默认阅读清单。
- `DIRECTOR_NARRATIVE_PLAN.md` 是候选导演结构，不是世界观正史；与用户确认设定冲突时以世界观总档案为准。
- `WORLD_MAP_MASTER_PLAN_CN.md`、`WORLD_NETWORK_TOPOLOGY_CN.md` 等早期地图草案不自动覆盖完整地图区划、箱庭原则和当前区域基线；冲突项以本次任务对应的当前区域基线及已确认路线裁定为准。

## 核心工程约束

- 地形、固定房间结构必须由 Godot 场景中可见、可编辑的节点构成；不允许运行时代码生成固定地图地形。
- 代码可以改变已存在场景节点的状态，例如开门、移动预制机关或播放动画。
- 叙事优先通过环境、可检查物品、NPC 对话和玩家行为后的世界变化呈现；不使用全知旁白解释剧情。
- 不设置 NPC 好感度数值系统。
- 不修改 `main`，不擅自创建分支，不主动触发 GitHub Actions。
- 文档更新优先迭代既有权威文件；只有职责确实独立时才新增文档。

## 验证原则

必须区分：
- 文档 / 源码静态检查；
- 验证脚本实际执行；
- Godot 4.6.x headless 导入 / 解析；
- 本地实机玩法与视觉验收。

提交代码或文档不等于运行通过。未执行的验证必须明确标记为未验证。

## 历史资料

旧版设计、阶段性日志、已废止方案和历史审计保留在对应目录中，仅用于追溯。它们不得覆盖用户最新确认的设定或当前权威设计合同。具体文件的合并、退役与删除，按文档治理合同先审计依赖再执行。
