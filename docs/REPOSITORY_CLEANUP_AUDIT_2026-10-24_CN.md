# 仓库清理审计记录（2026-10-24）

> 分支：feature/story-map-progression
> 状态：第一轮文档清理完成；代码/场景依赖审计仍在进行。此报告不宣称全仓清理已完成。

## 已执行

| 路径/范围 | 处置 | 依据 |
|---|---|---|
| docs/ARCHITECTURE_0_1.md | 删除 | 早期 0.1 架构摘要，无 README 引用；当前架构/协作规范已覆盖其稳定原则。 |
| docs/LEVEL_001.md | 删除 | 早期线性单场景关卡方案，与当前非线性互通世界设计冲突；无 README 引用。 |
| docs/TEST_CASES_PHASE_0_1.md | 删除 | 早期启动/玩家冒烟测试清单已由当前测试与 P5.1 验收资料替代；无 README 引用。 |
| docs/PHASE_0_1_DELIVERY.md | 删除 | 早期阶段交付占位记录，已不代表当前阶段；无 README 引用。 |
| docs/DEVELOPMENT_WORKING_CHARTER_CN_EN.md | 更新 | 加入必读文档、同步义务、旧文档处置和暂停条件。 |
| docs/SCENE_ARCHITECTURE_AND_A2_ROOM_REFACTOR_CN.md | 更新 | 明确废止“六房间仅拼成连续大地图、暂不做转场”的旧决定。 |
| docs/A2_SIX_ROOM_CANVA_TERRAIN_BLUEPRINTS_CN.md | 更新 | 标记旧 Canva 状态，指向当前 A2 基线。 |
| docs/A2_LOCAL_PLAYTEST_CHECKLIST_CN.md | 更新 | 标记与独立房间目标冲突的旧验收架构说明。 |
| docs/maps/A2_LOCAL_ACCEPTANCE_CN.md | 更新 | 标记连续大地图验收说明已过期。 |
| docs/A2_TERRAIN_REWORK_RUNTIME_ACCEPTANCE_CN.md | 更新 | 保留 C03/C04/H02 与碰撞/持久状态历史证据，但不再定义房间架构。 |
| A2 旧拓扑/灰盒文档（6 份） | 标记历史权威性 | 保留仍可能有价值的拓扑与空间约束；当前目标冲突时以 A2_DESIGN_BASELINE_CN.md 为准。 |

## 尚未删除的代码/场景候选

| 候选 | 当前判断 | 下一步证据要求 |
|---|---|---|
| scenes/main.tscn + scripts/core/world.gd | **已删除** | project.godot 默认入口为 scenes/boot.tscn；README、boot.gd、WorldState 的继续游戏路由和地图测试菜单均未将其列为入口；仓库代码搜索未发现 main.tscn 引用；该场景只挂载早期 core/world.gd。历史可由 Git 恢复。 |
| scripts/levels/room_world_prototype.gd | 不能删除：surface_hub.tscn、canopy_crossing.tscn、undercity_descent.tscn 仍显式引用它。 | 如要退役，必须先迁移/删除这些原型场景并更新对应验收资料。 |
| scenes/cliff_cave_experiment.tscn | 不能删除：scripts/levels/cliff_exploration.gd 引用它，且其 H09 状态/奖励逻辑仍存在。 | 需结合 A1 后山/H09 设计合同和世界拓扑审计。 |
| scenes/ash_forest.tscn 与六个 A2 房间 | 不删除。父场景目前仍承载 A2 区域控制器、跨区出口、检查点与持久状态。 | 先完成房间运行时架构迁移并验证 A1→R01、C03/C04/H02 后，才评估退役父场景或将其转为兼容入口。 |
| docs/A2_PLATFORM_GEOMETRY_ATLAS.svg | 暂留。它反映旧连续地图几何，可能对比当前实现有用，但不能作为目标地图基线。 | 新的六房间坐标/连接图完成后，替换或明确归档此图。 |

## 重要发现

- A2 当前有六个独立可编辑 .tscn，但仍由 scenes/ash_forest.tscn 装配成同一张区域地图；A1 北门仍以 ash_forest.tscn 为目标。
- 初步坐标审计发现 R01/R02/R03 的现有平台范围与 Canva 坐标标注存在明显尺度差异。只加转场不能解决设计偏差，必须先核对每张房间图与实际平台几何。
- 当前房间场景只有地形节点，不包含完整的 Hero、Camera、HUD、跨房间转场运行时；直接把 A1 出口改为某个房间 .tscn 会导致不完整场景，因此不能做这种单行路由修改。
- Canva 当前可确认有区域关系草图、R01、R02 与 R03 候选设计记录。尝试创建 R04/R05/R06 独立 Canva 图时返回 quota_exceeded；根据工具限制不再重试。三张缺失图是设计资源阻塞项，不得伪报已创建。

## 清理原则

- 删除只限已证实过时、无有效引用且其信息已被当前资料覆盖的文件。
- 旧记录若仍包含独立的空间/拓扑证据，应先标记历史状态而不是直接删除。
- 不因“搜索不到”就删除代码；动态 load/preload、存档路径、调试入口和外部场景引用必须纳入检查。
- 下一轮继续做全仓引用盘点，特别是孤立场景、旧控制器和重复地图验证器；完成依赖证据前保留候选文件。

## 本轮验收边界

- 已确认文档与文件删除操作均返回 GitHub 提交 SHA。
- 额外删除 scenes/main.tscn 与 scripts/core/world.gd：这是未被项目启动、继续游戏路由、README 或地图测试菜单引用的旧垂直切片入口；删除前核对了当前项目启动配置与主要路由来源。
- 未执行 Godot 运行时测试；未声称 A2 房间转场、坐标还原或实机可玩性通过。
- 本报告记录清理进度，不替代后续代码引用审计和 Godot 4.6.1 本地验收。