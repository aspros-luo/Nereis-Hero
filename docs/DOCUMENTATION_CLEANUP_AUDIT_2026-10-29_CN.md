# 文档清理审计 — 2026-10-29

> 分支：`feature/story-map-progression`
> 目的：减少重复入口，明确权威文档，避免误删仍被源码、场景、验证器或历史审计引用的文件。
> 本记录区分“已完成的整理”和“尚未满足安全删除条件的候选项”。

## 1. 已完成

- 新建 `docs/MILESTONE_HANDOFF_2026-10-29_CN.md`，作为新里程碑的单一交接入口。
- README 增加当前交接入口与叙事权威文档索引。
- README 移除重复的 `PROJECT_DOCUMENTATION_GOVERNANCE_CN.md` 索引段落。
- `WORLD_BUILDING_BIBLE_CN.md` 增加 2026-10-29 已确认的叙事规则、前期推进条件与地图路线。
- `WORLD_NARRATIVE_CLUE_LEDGER_CN.md` 增加不解释剧情的碎片叙事规则。
- `WORLD_MAP_BRAINMAP_CN.md` 增加最新路线裁定，并警告旧图/拓扑合同仍需工程核查。
- `NARRATIVE_PRESENTATION_AUDIT_AND_MIGRATION_CN.md` 明确当前规则与未完成的源码审计范围。
- `PROTAGONIST_OPENING_NARRATIVE_V1_CN.md` 与 `DIRECTOR_NARRATIVE_PLAN.md` 标记为受最新决策约束的历史/候选设计，不再凌驾于当前规则。
- `ROADMAP.md` 明确旧阶段清单不覆盖当前新里程碑优先级。

## 2. 当前权威文档职责

| 内容 | 权威入口 |
|---|---|
| 本次定稿与新里程碑交接 | `docs/MILESTONE_HANDOFF_2026-10-29_CN.md` |
| 世界观正史、角色边界、待定事项 | `docs/WORLD_BUILDING_BIBLE_CN.md` |
| 碎片叙事方法与线索证据链 | `docs/WORLD_NARRATIVE_CLUE_LEDGER_CN.md` |
| 宏观地图意图 | `docs/WORLD_MAP_BRAINMAP_CN.md`、`docs/FORMAL_WORLD_MAP_DESIGN_BASELINE_CN.md` |
| 结局状态/程序条件 | `docs/ENDING_CONDITION_DESIGN_CN.md` |
| 叙事呈现源码审计 | `docs/NARRATIVE_PRESENTATION_AUDIT_AND_MIGRATION_CN.md` |
| 修改、依赖与验收治理 | `docs/PROJECT_DOCUMENTATION_GOVERNANCE_CN.md` |

## 3. 暂不删除的候选项与原因

本次没有足够证据证明以下类别可以安全删除，因此不将“看起来重复”当作“无用”：

- `STORY.md`、`DIRECTOR_NARRATIVE_PLAN.md`、`PROTAGONIST_OPENING_NARRATIVE_V1_CN.md`：叙事方向有重叠，但包含不同年代的设计假设和可能的实现状态；已标记权威优先级，需逐条迁移有价值内容并检索引用后再考虑删除。
- `WORLD_MAP_BRAINMAP_*.md`、`BOX_WORLD_*.md`、`WORLD_MAP_* / COMPLETE_WORLD_MAP_*`：内容有重叠，但可能分别记录空间意图、验收、版本差异与历史原因；未完成交叉引用和拓扑核查前不删除。
- A0/A1/A2 区域设计、审计、运行时验收和 SVG/JSON 合同：不能因文档多就删除独立验收证据或机器可读合同。
- `tools/` 下的验证器、地图合同、清理/验收清单：不是普通说明文档，可能被开发者、Godot 或静态检查调用，必须先审查依赖。

## 4. 下一轮删除前必须完成

1. 对候选文档检索仓库中的 Markdown 链接、README 索引、脚本路径、场景资源路径、`preload/load`、验证器与动态文件引用。
2. 把仍有效的设计事实迁入权威文档；历史上重要的决定保留简短变更记录。
3. 检查跨语言版本是否仍被维护或链接；不能只删中文/英文其中一份而留下断链。
4. 检查文件是否是运行时、工具或验收输入；对 JSON、SVG、脚本和合同单独审查。
5. 逐文件记录证据和验证结果，再执行删除；无法证明安全的文件保留并标记历史/待审。

## 5. 当前未完成项

- 本轮没有执行全仓库文件级引用图分析。
- 本轮没有删除任何可能仍有设计、历史或工具价值的独立文件。
- 本轮没有修改 `tools/world_map_topology.json`、场景出口或验证器；C04 旧 A2↔A5 合同仍需后续工程审计。
- 本轮没有执行 Godot 运行时验收；文档更新不代表游戏流程已经通过。


---

## 6. 第二轮整理记录 — 2026-11-01

### 已完成

- `README.md` 已重写为短导航页：移除原先混杂的大段剧情、地图、灰盒实现和调试状态清单；只保留项目入口、必读顺序、权威文档职责和工程硬约束。
- `WORLD_BUILDING_BIBLE_CN.md` 已迭代更新蜜忒身份、外神代理关系、无形气味影响村民、后期意识外神化，以及三个结局的最新世界观因果；不再让旧版本的“蜜忒主动组织邪教”或“烈火天罚只打断降临、外神仍存在”与新设定并列。
- `STORY.md` 保留为快速剧情摘要；`DEVELOPER_STORY_MEMORY.md` 保留历史来源，不再作为第二套独立正史。
- `CROSS_GAME_STORY_CANON_CN.md` 只承担 Hero / Lullaby 共同设定，不重复承载完整开发日志。
- `MILESTONE_HANDOFF_2026-10-29_CN.md` 顶部已标记为历史快照，并指向 2026-11-01 现行权威文档；其中旧版蜜忒和结局描述不得作为现行设定。

### 本轮确认的文档职责

| 文件 | 当前职责 | 维护规则 |
|---|---|---|
| `README.md` | 项目导航 | 不写长篇设定或每日进度 |
| `PROJECT_DOCUMENTATION_GOVERNANCE_CN.md` | 文档权威层级与清理规则 | 工程规则变化时更新 |
| `DEVELOPMENT_WORKING_CHARTER_CN_EN.md` | 开发协作与硬约束 | 稳定规则，不追加流水账 |
| `DEVELOPMENT_STATUS.md` | 当前状态、阻塞、近期验证 | 保持摘要化；旧日志迁出或压缩 |
| `WORLD_BUILDING_BIBLE_CN.md` | 世界观唯一主要权威总档 | 迭代现有章节，不另建平行设定文档 |
| `STORY.md` | 快速剧情摘要 | 只保留核心，不重复详细证据链 |
| `DEVELOPER_STORY_MEMORY.md` | 历史讨论追溯 | 保留历史，明确标注被替代内容 |
| `CROSS_GAME_STORY_CANON_CN.md` | 跨作品共同事实 | 不复制单作实现日志 |
| `ENDING_CONDITION_DESIGN_CN.md` | 结局玩法条件合同 | 与世界观解释分离 |
| 区域设计基线 / 验收合同 | 单区域目标与验证 | 不跨区域复制大段全局规则 |

### 发现的待处理项（尚未删除文件）

1. `DEVELOPMENT_STATUS.md` 仍混合当前状态与大量日期日志，需要下一轮整理成“当前状态 + 未完成事项 + 最近验证”，历史记录迁入或压缩到单独归档前，先核对引用。
2. `DEVELOPER_STORY_MEMORY.md` 仍保留大量旧草案。已添加高优先级覆盖，但需要对正文旧段落逐段加 SUPERSEDED / 历史标记，不能仅靠文件末尾覆盖说明。
3. `CORE_CHARACTER_ARCS_V1_CN.md`、`PROTAGONIST_OPENING_NARRATIVE_V1_CN.md`、`DIRECTOR_NARRATIVE_PLAN.md` 与世界观总档存在职责重叠；需逐条迁移已确认内容，再标记候选/历史，不可整篇直接升级为正史。
4. `MILESTONE_HANDOFF_2026-10-29_CN.md` 保留当日路线与工程讨论，暂不删除；它的历史价值与当前权威性已分离。
5. 地图文档存在多个宏观草案、脑图、拓扑、审计与阶段日志。它们可能分别承担设计、机器合同和验收证据，需逐文件做引用/依赖审计，不能按标题相似批量合并。

### 本轮尚未完成

- 尚未获得可完整枚举仓库目录的工具结果，因此没有声称完成全仓库文件盘点。
- 尚未完成所有 Markdown 链接、脚本/场景资源路径、验证器输入和动态引用的全仓库依赖图。
- 尚未删除任何文档、脚本、场景或资源。
- 尚未运行 Godot；本轮仅进行远程 Markdown 修改与回读核验。

### 正反方裁定

- **正方：** 收敛 README 与世界观权威入口，减少新会话的必读负担，并修正现行蜜忒设定冲突。
- **反方 / 风险：** 过度合并会把区域设计、验收证据和历史决策混成巨型文件；过早删除会丢失设计依据或破坏工具引用。
- **裁定：** 先完成入口和权威内容收敛；下一步优先压缩开发状态与标记历史剧情草案，再开展文件级依赖审计。未证明安全前不删除文件。


---

## 7. 第三轮整理记录 — 2026-11-01

### 已完成

- `DEVELOPMENT_STATUS.md` 从约 26.5 KB 压缩为约 2.8 KB 的当前状态页。保留 A0/A1/A2 当前重点、已知风险、优先待办和验证定义；删除重复的逐日过程叙述。历史细节仍可从 Git 历史追溯，不再要求每次恢复工作时阅读。
- `DEVELOPER_STORY_MEMORY.md` 顶部加入明确警告：该文件是历史讨论档案，不是现行剧情正史；特别指出蜜忒知情程度、邪教主动性、身体结合桥梁和结局条件等旧内容可能与现行设定冲突。正常开发不应默认读取该档案。
- 当前剧情权威入口仍为 `WORLD_BUILDING_BIBLE_CN.md`；快速摘要为 `STORY.md`；结局玩法条件为 `ENDING_CONDITION_DESIGN_CN.md`。
- 没有删除历史记忆正文，避免把用户早期明确表达、助手提案与原型实现混在一起后不可逆丢失；后续若需要进一步瘦身，应按章节识别来源并迁移有价值决策，再移除重复历史。

### 清理效果

| 文件 | 整理前 | 整理后 | 变化 |
|---|---:|---:|---:|
| `DEVELOPMENT_STATUS.md` | 26,518 字符 | 2,845 字符 | 约减少 89% |
| `DEVELOPER_STORY_MEMORY.md` | 48,620 字符 | 48,939 字符 | 正文保留，仅增加档案警告 |

### 正反方评审

- **正方：** 开发状态页只需告诉新会话当前状态和下一步，不应成为不可读的每日流水账；历史记忆不应与现行正史并列。
- **反方 / 风险：** 直接删除状态日志可能丢失未迁移的技术原因、验证输出与阶段背景；大规模改写历史记忆可能误删用户确认与助手提案之间的区别。
- **裁定：** 压缩状态页；历史记忆先隔离、后分段清理。完整历史仍由 Git 提交和历史档案保留，不再复制进当前状态页。

### 本轮边界

- 仅更新 Markdown 文档；没有修改代码、场景、存档或资源。
- 没有删除任何文件。
- 已对修改后的文件进行远程回读核验；未运行 Godot，因为本轮没有引擎内容变更。
- 当前状态页中的 A0 新游戏加载失败事项来自用户最近反馈和已有状态记录；修复前必须取得最新日志并复现，不能仅凭文档推断根因。

## 8. 第四轮整理记录 — 2026-11-02（全量文档树盘点）

### 盘点范围与证据

- 使用 GitHub 当前分支的递归 Git Tree 获取 docs/ 下全部 Markdown 文件清单：**185 个文件**，树结果未截断。
- 本轮重点复核文档治理合同、开发协作条约、世界观总档案、剧情摘要、跨作品正史、结局条件、人物设计池、人物弧线、开局骨架、叙事迁移审计、地图总纲、世界拓扑、完整地图图集、箱庭原则及 A2 当前基线。
- 本轮没有扫描全部 185 个文件的完整正文，也没有完成所有 Markdown / 源码引用的全仓库依赖审计。因此本节是目录级全量盘点与重点文档审查，不得表述为 185 个文件均已逐篇审定。

### 本轮已完成

- README 不再把 2026-10-29 历史交接列为每次任务的必读项。
- README 将开发者剧情记忆明确为按需追溯档案，不作为日常启动必读。
- README 增加人物与开局设计入口，并明确导演规划、早期地图草案的非正史 / 非最高优先级边界。
- 保留现有权威文档，不新增第二套故事、地图或 NPC 总纲。

### 已确认的文档职责冲突

1. STORY.md 与 WORLD_BUILDING_BIBLE_CN.md 的职责必须保持为“快速剧情摘要”与“世界观详细权威档案”；结局玩法条件单独归 ENDING_CONDITION_DESIGN_CN.md。
2. DEVELOPER_STORY_MEMORY.md 体量较大且含早期互相冲突的提案，必须只用于追溯决策来源。顶部警告已存在，但其内部历史章节仍需要逐段标注来源与被覆盖内容。
3. CORE_NPC_DESIGN_POOL_CN.md 是候选资料池；CORE_CHARACTER_ARCS_V1_CN.md 是人物独立动机与弧线；A1_NPC_DIALOGUE_PROGRESS_DESIGN_CN.md 是 A1 对话阶段机制草案；A1_VILLAGE_STORY_AND_NPC_REDESIGN_V1_CN.md 是村庄叙事重设计资料。四者不能互相冒充最终 NPC 设定或对白脚本。
4. DIRECTOR_NARRATIVE_PLAN.md 自身标记为 proposed production structure，但仍指向历史剧情记忆作为硬正史来源；应修正引用方向或继续保持候选状态，不能作为 NPC 设计裁定依据。
5. WORLD_MAP_MASTER_PLAN_CN.md、WORLD_NETWORK_TOPOLOGY_CN.md 仍保留早期 development 分支和草案状态；不得与后续完整地图图集、箱庭原则及当前 A0/A1/A2 区域基线混作同一版本。
6. FORMAL_WORLD_MAP_DESIGN_BASELINE_CN.md、BOX_WORLD_FINAL_MAP_DESIGN_CN.md 等地图文件仍标记旧分支或早期拓扑来源。必须先核对机器可读拓扑、当前分支路线裁定与场景实现，再决定保留、降级或退役，不能只按文件名中的“FINAL”判断权威性。

### 尚未完成的清理门槛

- 对 185 个 Markdown 文件逐类读取状态、来源、更新时间、内部链接与互相引用。
- 对候选退役文件检索 README、Markdown 相对链接、GDScript / Python 验证器、场景资源和动态路径依赖。
- 对地图文件核对当前 tools/world_map_topology.json、当前分支区域基线及场景；对剧情文件核对用户确认记录和世界观总档案。
- 处理重复英文 / 中文版本、历史灰盒实施计划、过期里程碑交接与重复验收报告；保留仍有独立证据价值的审计记录。
- 对每项退役或删除逐项记录替代文件、引用检查和验证结果。未满足安全条件的文件继续保留并标注历史 / 待审。

### 正反方裁定

- **不采用“按文件名批量删除旧文档”**：可快速减少文件数，但会丢失历史决策原因、独立验收证据和潜在工具引用。
- **采用“少量权威入口 + 明确档案边界 + 逐项退役”**：整理速度稍慢，但可以避免设计来源断裂、NPC 事实漂移和地图拓扑回归。
- 在完成上述引用审计和退役处理前，文档整理状态仍为进行中；NPC 设计继续暂停。
## 9. 第五轮整理记录 — 2026-11-02（地图 / A0-A2 / NPC 文档职责收敛）

### 本轮已修改

- `README.md`：去掉重复 NPC 入口；地图区分全局原则、宏观脑图、区划提案、区域图谱与 A2 房间基线；补齐 A1 村庄与 NPC 对话设计入口。
- `A1_VILLAGE_STORY_AND_NPC_REDESIGN_V1_CN.md`：限定为 A1 村庄阵容、空间和普通事件提案；明确人物正史、全局人物弧线与对白机制各自的来源。
- `A1_NPC_DIALOGUE_PROGRESS_DESIGN_CN.md`：限定为对话阶段、事件触发、知识权限和对白交付；明确守门人首轮设计不等于其他 NPC 的通用对白模板。
- `A1_NPC_EVENT_REDESIGN_PREP_CN.md`：标为系统接口与源码状态的历史前置审计快照，避免误当成最终剧情方案。
- `CORE_NPC_DESIGN_POOL_CN.md`：明确是候选池而非最终阵容；修正旧的“结局由 Resonance、真相锚点道具和探索决定”表述，改为引用当前结局条件合同。
- `A2_LOCAL_PLAYTEST_CHECKLIST_CN.md`：移除与独立房间真实转场相矛盾的“六房间同一张连续大地图、不切图”验收说明。
- A0/A1 旧资料：将 A0 旧美术接入、编辑器布局、跳跃审计、旧序章提案，以及 A1 多峰后山 / 二段跳路线提案标为历史快照；当前固定地形节点化和独立悬崖场景方向优先。
- 世界地图结构：`BOX_WORLD_HIERARCHY_CN.md` 的旧五宏区表已与当前 JSON 的 M1–M6 六宏区对齐；`INTERCONNECTED_BOX_WORLD_DESIGN_CN.md`、`COMPLETE_WORLD_MAP_ATLAS_CN.md`、中英文 `BOX_WORLD_FINAL_MAP_DESIGN` 与 `FORMAL_WORLD_MAP_DESIGN_BASELINE_CN.md` 已明确各自的参考 / 历史边界。

### 当前机器可读拓扑核验

- `tools/world_map_topology.json` 当前记录 A0–A13 共 14 个区域、C01–C24 共 24 条跨区连接、M1–M6 共 6 个宏观区域、78 个子区域、73 条区域内连接、8 部升降机、H01–H08 共 8 个隐藏区域。
- JSON 顶层状态为 `design_baseline_not_runtime_verified`；数据自身明确不证明场景、碰撞、存档、死亡恢复或转场已通过实机验收。
- 该 JSON 可作为结构化 ID / 连接数据来源，但不能替代用户最新设计决策或当前房间场景合同。

### 仍存在的阻断冲突

- **A2 的 C04 状态不一致。** `docs/maps/A2_DESIGN_BASELINE_CN.md` 的 2026-10-29 注释称 A2→A5 的旧朝圣高路连接不再有效、需经 A3；但当前 `tools/world_map_topology.json` 仍将 C04 定义为 A2↔A5、由 A5 开启的双向捷径，且保留 A2/A5 出生点合同。两者不能同时作为当前事实。未擅自修改任一方；需要在后续路线合同审计中根据用户最后确认、场景和验证器完成裁定。任何依赖 C04 的 A2/A5 NPC 事件先不要定稿。
- `COMPLETE_WORLD_MAP_ATLAS_CN.md`、`BOX_WORLD_FINAL_MAP_DESIGN_CN.md` 和 `WORLD_REGION_ATLAS_CN.md` 仍有不同年代的宏观空间描述。已明确机器数据与区域合同优先边界，但完整宏观路线仍需逐条对齐，不应声称全局地图文档已完全统一。

### 退役 / 删除决策

- 本轮**没有删除文件**。当前 GitHub 搜索未返回可用的引用命中，不能据此证明无引用；而治理合同要求同时检查 Markdown 链接、源码字符串、`res://`、`preload/load`、场景资源和验证器依赖。尚未取得足够完整的依赖证据。
- 已过期但仍有历史决策价值的 A0/A1/A2 审计保留为历史快照；后续如有可证明无依赖且信息已迁移的纯重复文件，再逐项删除。

### 当前结论

- 本轮完成了重要入口、人物文档职责、A2 实机清单和地图层级的冲突修正；但不能宣称 185 份文件已逐篇审完或所有地图合同无冲突。
- NPC 设计的**人物正史入口、全局人物弧线参考、A1 村庄提案和对话机制文档**现在已区分清楚。尚需处理的 C04 / 全局地图宏观冲突不会阻止先做不依赖这些路线的 A1 NPC 人物设计，但相关跨区事件必须保持未定。
- 文档清理总任务仍进行中；下一轮应继续审查 A0/A1/A2 的实现审计、地图验收、灰盒历史和测试报告，并逐项核对引用后再决定退役。
## 10. 第六轮整理记录 — 2026-11-02（A1 NPC 设计入口与旧地图合同清理）

### A1 NPC 文档链核对

- `WORLD_BUILDING_BIBLE_CN.md`：人物事实 / 知识边界 / 结局世界观权威来源。
- `CORE_CHARACTER_ARCS_V1_CN.md`：人物独立动机与弧线参考，不等同于最终事件或对白。
- `CORE_NPC_DESIGN_POOL_CN.md`：全游戏核心 NPC 候选池；已修正旧版把 Resonance 当结局选择器的错误描述。候选阵容不自动成为正史。
- `A1_VILLAGE_STORY_AND_NPC_REDESIGN_V1_CN.md`：A1 常驻阵容、村庄空间、普通事件和出场层级提案；已修正旧版守门人 x=650 坐标，并将已确认的蜜忒 / 金正 / 朝圣骑士事实与未定命运分开。
- `A1_NPC_DIALOGUE_PROGRESS_DESIGN_CN.md`：A1 对话阶段、知识权限、事件触发和守门人对白合同；明确第 12–15 节覆盖早期章节的旧执行顺序。
- `A1_NPC_EVENT_REDESIGN_PREP_CN.md`：只保留为系统接口历史快照，不作为人物设定或对白来源。
- `WORLD_NARRATIVE_CLUE_LEDGER_CN.md`：已纠正旧版烈火天罚的“杀死 100 名教徒 / 杀死蜜忒”流程与当前世界观冲突，并移除未经确认的“交付道具给蜜忒”硬步骤；世界观和结局玩法条件分别回归各自权威文件。

### 当前 A1 源码结构静态抽查（仅文件读取，不是运行测试）

- `scenes/regions/village_hub.tscn` 中存在 `village_gatekeeper`、`village_grandmother`、`village_blacksmith`、`traveling_merchant`；守门人节点位置为 `(2740, 520)`。
- `scripts/levels/village_hub.gd` 中存在蜜忒对白结束后调用 `WorldState.record_mite_interaction()` 的流程；对白完成事件与关系状态提交点可追踪。
- `scripts/core/world_event_director.gd` 中存在朝圣骑士 A1 manifest 条件，分别读取 `pilgrim_knight_a1_arrived` 与 `pilgrim_knight_at_tavern` 状态。
- `scripts/core/dialogue_progression_manager.gd` 中存在 `village_gatekeeper` 的通用对话进度配置。
- 本次只读取远程源码并核对文本 / 节点 ID；没有运行 Python 验证器、Godot headless 或本地实机。蜜忒错过会面触发源、朝圣骑士正式剧情节点和互动中断存档行为仍须后续核验。

### NPC 设计启动门槛判定

- **通过：** NPC 设计的权威资料职责已分离，世界观事实、全局人物弧线、候选池、A1 阵容提案和对话机制不再互相冒充。
- **通过：** 已确认的人物事实与待定内容有清楚边界；蜜忒不使用好感度数值，关系不能直接作为结局开关；普通 NPC 不能获得全知知识。
- **通过：** A1 当前角色节点、稳定 ID、守门人位置和朝圣骑士进度型生成入口已做远程源码静态抽查。
- **限制：** NPC 设计不能依赖未经确认的 A2→A5 C04 旧路线；与 A2/A5 跨区事件相关的人物相遇、协同战斗或捷径对白必须等路线合同与实现统一后再定稿。
- **限制：** 本轮没有完成全部 185 份 Markdown 正文逐篇审定，也没有删除任何文件；清理总任务继续进行。