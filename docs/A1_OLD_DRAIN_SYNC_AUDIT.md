# A1 旧排水探索段同步审计

日期：2026-10-19  
目标分支：`feature/story-map-progression`  
来源分支：`development`

## 目标

选择性同步旧排水路线的一组完整功能，不合并整个 `development` 分支，也不覆盖地图分支已有的 A1 NPC、地图扩展或路线合同。

## 同步内容

- 新增 `scenes/old_drain_exploration.tscn` 与 `scripts/levels/old_drain_exploration.gd`。
- 新增低威胁敌人 `scripts/enemies/sewer_rat.gd`。
- A1 村庄排水入口在 `village_defense_survived` 后进入独立探索段。
- 探索段的东侧闸门在 A4 侧连接开启前具有真实碰撞阻挡。
- A4 侧连接通过持久标记 `opened_old_drainage_link_from_A4` 开启；开启后 A3 与 A4 均通过探索段连通。
- A3 的最终落点仍使用 `village_city_cut`（x=700）；返回村庄使用 `city_cut_return`（x=350）；A4 回程使用 `old_drain_link`（x=820）。
- 更新 C24 拓扑，明确旧排水探索场景是中间段，并更新拓扑与空间路线合同验证器。

## 关键约束

- 不覆盖地图分支独有的 NPC 对话、交互流程、地图尺寸或其他 A1 内容。
- 不改变 A2 森林/钟墓路线。
- 不改变 H01 水井与悬崖洞穴入口合同。
- 不合并 `feature/hero-animation-system`，也不向 `development` 写入地图实现。
- C24 的图结构仍为 A1 → A3；A1 防卫后只开放探索段，A3 连接需 A4 侧开闸后才接入。

## 已完成的静态核对

- 相关场景、脚本、敌人、拓扑和验证脚本均已存在于目标分支。
- 检查了入口门槛、实际闸门碰撞体、A3/A4 双端连接条件、持久解锁标记、出生点映射和拓扑中间场景声明。
- 以上检查通过的是对 GitHub 文件内容的静态合同核对，不等于执行了 Python 验证器或 Godot 场景。

## 尚未完成的验收

本轮未在本地 Godot 4.6.1 运行项目，也未执行 Python 验证器。因此暂不声称解析、运行时转场、碰撞、死亡恢复或完整地图验收通过。

下一步必须在本地运行：

1. `python3 tools/validate_old_drainage_connection.py`
2. `python3 tools/validate_world_map_topology.py`
3. `python3 tools/validate_spatial_route_contracts.py`
4. 使用 Godot 4.6.1 执行项目解析与完整路线实测：村庄入口 → 闸门阻挡 → A4 侧开闸 → A3 入口 → A4 回程；并测试死亡恢复与出生点不触发相邻门。

