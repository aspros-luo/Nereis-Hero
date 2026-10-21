# 场景盘点与世界拓扑映射（第一轮）

分支：`feature/story-map-progression`  
基于提交：`a9c14ac52f2f8ab640323237360064f3cffce28d` 之后的 `feature/story-map-progression` 当前树。  
状态：仓库静态盘点；未运行 Godot，未声称路线已通过实机。

## 1. 当前实际场景清单与区域映射

当前 `scenes/` 根目录有 39 个 `.tscn`。其中一些是可运行的大区域灰盒，一些是隐藏空间/支线场景，还有一些是演示、入口或测试场景。不能把 39 个场景直接当作 39 个完整探索区。

| 分类 | 场景文件 | 当前解释 | 后续动作 |
|---|---|---|---|
| 大区域灰盒 | `ash_forest.tscn` | A2 雾林、钟墓与旧朝圣路 | 重做内部拓扑，评估是否拆分多个连续场景 |
| 大区域灰盒 | `forgotten_city.tscn` | A3 废弃城区 | 需按街巷、屋顶、管线、钟塔落差拆分评估 |
| 大区域灰盒 | `sewer_reservoir.tscn` | A4 下水道与旧水库 | 需区分上层检查廊、中层水道、低位淹水沟和深层井道 |
| 大区域灰盒 | `old_battlefield.tscn` | A5 旧战场与边境堡垒 | 需区分战壕、坍塌城墙、堡垒高路、瞭望塔 |
| 大区域灰盒 | `monastery_tower.tscn` | A6 修道院、回廊与钟塔 | 垂直建筑候选：庭院、廊桥、钟塔中层/塔顶 |
| 大区域灰盒 | `prison_depths.tscn` | A7 监牢与维护竖井 | 垂直地下候选：囚室、忏悔井、竖井上下层 |
| 大区域灰盒 | `royal_tomb.tscn` | A8 王墓与地下道 | 地面墓室、中层墓道、深层铭文廊及升降井 |
| 大区域灰盒 | `royal_outer_ring.tscn` | A9 王城外环 | 街巷、广场、屋顶、王室排水道和货梯候选 |
| 大区域灰盒 | `grand_cathedral.tscn` | A10 大圣堂与教会内廷 | 主堂、侧廊、高廊、维护梯井候选 |
| 大区域灰盒 | `deep_research_depths.tscn` | A11 深层研究区与古神遗迹 | 研究设施与古神遗迹需有不同的空间识别 |
| 大区域灰盒 | `inner_city.tscn` | A12 王室内城与王座区 | 服务街、庭院、城墙、王座厅上层和货运井候选 |
| 大区域灰盒 | `terminal_anomaly.tscn` | A13 深层梦境与终局异象 | 终局条件驱动的独立空间 |
| A0/A1 主线分段 | `escape_prologue.tscn`, `prologue_exterior.tscn`, `mite_house.tscn`, `village_hub.tscn` | 序章逃脱到村庄的分段路线；C01 不是单门直连 | 保留 staged route，核对每段返回/单向语义 |
| A1 支线/事件 | `village_graveyard.tscn`, `village_defense_demo.tscn`, `old_drain_exploration.tscn` | 村庄墓地、防卫章节、旧排水探索 | 需标注哪些是剧情章节场景，哪些属于连续地理 |
| H01–H08 隐藏空间 | `hidden_well.tscn` (H01), `hidden_bell_chamber.tscn` (H02), `erased_third_street.tscn` (H03), `reflected_stairwell.tscn` (H04), `silent_bell_room.tscn` (H05), `erased_royal_name_corridor.tscn` (H06), `mirror_street.tscn` (H07), `primordial_hollow.tscn` (H08) | 可选/隐藏空间，部分有二次出口 | 保留独立身份，但要通过实际入口/出口把它们融入世界，不当作孤立菜单关卡 |
| 其他内容/实验 | `ancient_research_lab.tscn`, `cliff_cave_experiment.tscn`, `rebel_camp.tscn`, `royal_tomb_boss.tscn`, `combat_demo.tscn`, `church_final_demo.tscn`, `ending_fire_demo.tscn`, `ending_paradise_demo.tscn`, `mite_resonance_demo.tscn`, `world_map_test_menu.tscn`, `boot.tscn`, `main.tscn` | 实验场景、Boss/结局演示、启动入口、地图测试菜单 | 不能默认算作已完成的世界探索地图；逐个确认用途、是否仍被引用及最终保留方式 |

## 2. 当前拓扑结构的已知规模

`tools/world_map_topology.json` 当前登记：

- 14 个大区域：A0–A13。
- 6 个宏区：M1–M6。
- 78 个子区域。
- 24 条跨区连接：C01–C24。
- 73 条区域内连接：SC 连接。
- 8 条升降机合同：LFT01–LFT08。
- 8 个隐藏空间：H01–H08。

注意：拓扑登记、场景文件存在、地形代码存在和实机可通行是四个不同状态。升降机合同中已有明确标为 deferred 的项目；不能把设计合同算成已实现内容。

## 3. 重要的结构性发现

### 当前“子区域”与“场景”不是一一对应

拓扑将 A2 分成 7 个子区域，但目前 A2 的主场景文件是单个 `ash_forest.tscn`，实际绘制由 `greybox_world_region.gd` 生成。A3–A12 等多个区域也采用相同的单场景灰盒脚本模式。

这并不自动意味着每个子区域都要拆成一个场景。正确问题是：哪些地方在空间和运行时上应保持连续，哪些地方需要真正的场景边界，以及边界处怎样保持玩家的方向感。

### 当前世界有不少“图上连接”，需要逐一核对真实入口

例如 C03/C04、C05/C07/C08、C10/C12/C13 等连接定义了不同高度的到达点与返回点。必须核对：
- 门触发器是否真实存在；
- 出生点是否落在承托平台上；
- 到达点是否避开门触发器，避免重复切场景；
- 场景切换后是否仍位于约定的上层/中层/深层；
- 单向坠落、双向通道、远端解锁捷径是否按合同实现。

### A2 不能用横向扩宽替代探索网络

A2 的七个子区域应作为空间拓扑重审的第一样板。重点是分叉、回返、可辨认地标、死路、上下层穿插和远端出口，不是增加平台数或地图宽度。

## 4. 实施判定矩阵

每条连接在项目追踪中都应分开标记以下状态：

1. **设计登记**：拓扑 JSON 中有合同。
2. **场景登记**：入口两侧的场景和子区域已明确。
3. **代码实现**：门/通道/出生点/地形已存在。
4. **静态核对**：路径引用、区域 ID、锚点和必要承托通过静态检查。
5. **Godot 实机通过**：主角确实可以按合同通过，且返回行为正确。

没有完成第 5 项，不得写成“已验收”。

## 5. 下一项工作

1. 完成 `SC001–SC073` 区域内连接到子区域的映射审计。
2. 完成 `C01–C24` 的场景边界、入口出口和返回出生点审计。
3. 在不改动已约定的主线/可选门槛前提下，提出每个大区域的实际场景拆分方案。
4. 先重构 A2 的地形拓扑和必要的场景边界，再用同一套规则扩展其余区域。
5. 暂不系统填充敌人与收集品，直到灰盒可通行验收达到门槛。

本文件是基于仓库静态内容的第一轮盘点；未运行 Python 验证器或 Godot，因此不代表任何连接已通过实机。
