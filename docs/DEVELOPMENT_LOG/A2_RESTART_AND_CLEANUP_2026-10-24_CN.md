# A2 重启与仓库清理开发记录（2026-10-24）

## 本轮范围

- 目标分支：feature/story-map-progression。
- 先建立文档权威层级与 A2 设计基线，再审计当前六个场景及过期验证器；尚未迁移 A1 入口或房间运行时。

## 文档治理变更

- 新建 docs/PROJECT_DOCUMENTATION_GOVERNANCE_CN.md，并在开发协作条约与 README 中建立入口。
- 新建 docs/maps/A2_DESIGN_BASELINE_CN.md，登记区域草图、R01/R02 和 R03 候选 Canva 记录。
- 新建 docs/maps/A2_SCENE_GEOMETRY_AUDIT_2026-10-24_CN.md，记录六房间当前父场景偏移和局部坐标范围。
- 新建 docs/REPOSITORY_CLEANUP_AUDIT_2026-10-24_CN.md，记录删除/保留决定与尚未完成的依赖审计。
- 更新 A2 架构与验收文档，废止“六房间只作为同一张连续地图的拼装件、暂不做房间转场”的旧决定。

## 已清理文件

- 删除 docs/ARCHITECTURE_0_1.md、docs/LEVEL_001.md、docs/TEST_CASES_PHASE_0_1.md、docs/PHASE_0_1_DELIVERY.md：早期阶段文档已过时且未被 README 引用。
- 删除 scenes/main.tscn 与 scripts/core/world.gd：项目默认启动入口为 scenes/boot.tscn；主要继续游戏路由、README 和地图测试菜单未引用旧入口，旧 core/world.gd 仅由该场景挂载。
- 删除 tools/validate_a2_platform_reachability.py：它解析的是旧 greybox_world_region.gd 中的程序化 A2 平台分支，不再代表六个编辑器场景。
- 新建 tools/validate_a2_room_scene_geometry.py，检查六个 .tscn 中平台/碰撞/可视节点和父场景引用。该工具尚未执行；它不验证跳跃可达性。

## 已确认的 A2 实现事实

- A1 北门仍指向 scenes/ash_forest.tscn。
- scenes/ash_forest.tscn 仍将 R01–R06 作为同一张大地图的场景实例装配。
- 六房间当前 StaticBody2D 根节点数量为 12/7/9/9/13/24，总计 74；旧日志中的 71/70 与当前场景不符，已修正 a2_authored_terrain.gd 汇总日志的总数。
- R01/R02/R03 当前场景局部坐标范围与 Canva 标注存在明显尺度差异；父场景位置仍决定它们在 A2 连续地图中的实际关系。
- R04–R06 Canva 创建尝试返回 quota_exceeded，本轮未创建成功；不再重试。

## 正反方裁定

**正方：** 先清理冲突文档、校正静态工具和平台总数，能降低后续房间重构时把旧实现误当成设计基线的风险。

**反方：** 当前还没有足够证据安全删除所有候选代码，也没有 R04–R06 的独立 Canva 图；立即将 A1 入口改到裸房间 .tscn 会因缺少 Hero/Camera/HUD/跨区逻辑而破坏游戏流程。

**裁定：** 不做一行式入口切换。A2 重新开发从逐房间几何校准和连接合同开始，再实现共享房间运行时；所有跨区/存档/死亡恢复合同保留。其余代码清理继续按引用证据推进，不批量删除。

## 验证状态

- GitHub 文档和文件操作均已返回提交 SHA。
- 未运行新 Python 验证器。
- 未运行 Godot 4.6.1；房间转场、碰撞、跳跃、C03/C04/H02、存档恢复均未验收。
- Canva R04–R06 设计未创建成功。