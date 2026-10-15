# P0 地图总账与一致性审计

> 分支：`development`  
> 基准：`tools/world_map_topology.json`  
> 审计方式：拓扑数据、Godot GDScript、场景清单与静态验证器交叉核对。  
> **验收边界：本文件不宣称已完成 Godot 实机验收。** 代码存在、拓扑可达与实际碰撞/跳跃/转场可玩是三种不同状态。

## 1. P0 结论

- 主地图：**14 个区域（A0–A13）**。
- 宏观连接：**24 条（C01–C24）**。
- 隐藏区域：**8 个正式编号区域（H01–H08）**。
- 宏观环路：**3 条（L01–L03）**。
- 分层地图：**6 个叙事宏区、76 个子区域、71 条区域内连接、8 个升降机契约**。
- 额外候选：H09；候选区不替代 H01–H08 正式编号。
- **H 与 C 没有新旧替代关系**：A/H 是区域，C 是区域间连接；L 是宏观环路，SC 是区域内连接，LFT 是升降机。
- 发现并修正了终局条件验证器与实际剧情代码之间的过期约定；同时把 C02 的村庄防卫前置条件写回拓扑数据。
- C14 的双向源码出口已与拓扑空间锚点对齐：A8 门 x=2528、A9 门 x=72，回程出生点分别为 A8 x=2420、A9 x=180；静态方向审计已补充相应检查。
- 本轮没有声称任何跳跃、碰撞、门触发、存档恢复或全流程转场已在 Godot 运行通过。

## 2. 状态定义

| 状态 | 含义 |
|---|---|
| 设计定义 | 拓扑/分层数据中有记录 |
| 源码已接线（静态） | 能在 GDScript 中找到对应场景转场、门、标记或出生侧映射 |
| 静态验证规则已对齐 | 验证器的期望与当前设计及源码一致；仍需在用户本地运行验证器 |
| 元数据缺口 | 源码存在，但拓扑没有足够的空间/方向字段供一致性验证 |
| 待实机验收 | 需要 Godot 4.6.1 实际运行确认，静态文本不能证明 |
| 候选/临时 | 不属于正式 A/H 编号范围，除非后续设计决议正式纳入 |

## 3. 正式区域清单 A0–A13

| ID | 区域名称 | 拓扑角色 | 场景与源码归属 |
|---|---|---|---|
| A0 | 边境手术所与逃脱通道 | prologue | scenes/escape_prologue.tscn — scripts/levels/escape_prologue.gd |
| A1 | 边境村庄 | hub | scenes/village_hub.tscn — scripts/levels/village_hub.gd |
| A2 | 雾林、钟墓与旧朝圣路 | surface | scenes/ash_forest.tscn — scripts/levels/greybox_world_region.gd (region_id=A2) |
| A3 | 废弃城区 | hub | scenes/forgotten_city.tscn — scripts/levels/greybox_world_region.gd (region_id=A3) |
| A4 | 下水道、沉积大厅与旧水库 | underground_hub | scenes/sewer_reservoir.tscn — scripts/levels/greybox_world_region.gd (region_id=A4) |
| A5 | 旧战场与边境堡垒 | surface | scenes/old_battlefield.tscn — scripts/levels/greybox_world_region.gd (region_id=A5) |
| A6 | 修道院、回廊与钟塔 | vertical_building | scenes/monastery_tower.tscn — scripts/levels/greybox_world_region.gd (region_id=A6) |
| A7 | 监牢、忏悔井与维护竖井 | vertical_underground | scenes/prison_depths.tscn — scripts/levels/greybox_world_region.gd (region_id=A7) |
| A8 | 旧王墓与王室地下道 | underground_hub | scenes/royal_tomb.tscn — scripts/levels/greybox_world_region.gd (region_id=A8) |
| A9 | 王城外环与废弃街区 | hub | scenes/royal_outer_ring.tscn — scripts/levels/greybox_world_region.gd (region_id=A9) |
| A10 | 大圣堂、朝圣阶梯与教会内廷 | mainline | scenes/grand_cathedral.tscn — scripts/levels/greybox_world_region.gd (region_id=A10) |
| A11 | 古神遗迹与深层研究区 | optional_deep | scenes/deep_research_depths.tscn — scripts/levels/greybox_world_region.gd (region_id=A11) |
| A12 | 王室内城与王座区 | mainline_ending | scenes/inner_city.tscn — scripts/levels/greybox_world_region.gd (region_id=A12) |
| A13 | 深层梦境与终局异象 | ending_layer | scenes/terminal_anomaly.tscn — scripts/levels/greybox_world_region.gd (region_id=A13) |

A0 和 A1 由独立关卡脚本实现；A2–A13 共享 `scripts/levels/greybox_world_region.gd`，通过各场景的 `region_id` 分支生成平台、出口、遭遇和线索。共享控制器不代表各区域的空间实现完全相同。

## 4. 主线顺序与宏观连接 C01–C24

### 主线顺序

`A0 → A1 → A2 → A3 → A5 → A6 → A7 → A8 → A9 → A10 → A12`

这是主线区域顺序，不代表玩家只能沿直线移动。C04、C06、C07、C10、C12、C16、C18、C23、C24 等连接用于捷径或回环；C15、C19 是不同条件的隐藏研究区入口；C21、C22 是两条独立的终局入口。

### 连接总账

| ID | 端点 | 类型 | 初始拓扑方向 | 最终方向 | 解锁条件 | 从哪一侧开启 | 空间锚点摘要 | 源码/审计状态 |
|---|---|---|---|---|---|---|---|---|
| C01 | A0 → A1 | main | from_to | forward | 无额外解锁条件 | — | 未提供独立 spatial_contract；以 layer_contract 与源码门/出生点映射为准 | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C02 | A1 → A2 | main | both | both | village_defense_survived | A1 | 未提供独立 spatial_contract；以 layer_contract 与源码门/出生点映射为准 | 源码已接线；北门先触发防卫，完成后才由 A1 进入 A2；拓扑已补记条件 |
| C03 | A2 → A3 | main | both | both | 无额外解锁条件 | — | 出：A2@(2240, -160)；入：A3@(180, -130, city_canopy_entry)；返：A2@(2120, -140, east) | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C04 | A2 → A5 | shortcut | blocked | both | reached_A5_and_opened_old_pilgrim_highroad | A5 | 出：A2@(1880, -115)；入：A5@(520, -140, old_pilgrim_highroad)；返：A2@(1750, -140, old_pilgrim_highroad)；反向到达：A5@(650, -85, old_pilgrim_highroad) | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C05 | A3 → A4 | underground_route | from_to | both | opened_sewer_inspection_hatch_from_A4 | A4 | 出：A3@(1600, -115)；入：A4@(180, -115, sewer_upper)；返：A3@(1380, -115)；到达：A4@(180, -95, sewer_upper) | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C06 | A4 → A1 | shortcut | blocked | forward | opened_watergate_and_village_well_exit | A4 | 出：A4@(2220, 0) | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C07 | A4 → A8 | shortcut | blocked | both | reached_A8_via_A7_then_opened_royal_tomb_gate | A8 | 出：A4@(1320, -85)；入：A8@(520, -165, royal_tomb_waterway)；返：A4@(1410, -85, royal_tomb_waterway) | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C08 | A3 → A5 | main | both | both | 无额外解锁条件 | — | 出：A3@(2240, -130)；入：A5@(180, -130, city_highroad)；返：A3@(2360, -130, city_highroad_return)；反向到达：A5@(330, -130, city_highroad) | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C09 | A5 → A6 | main | both | both | 无额外解锁条件 | — | 出：A5@(2250, -90)；入：A6@(160, -90, battlefield_entry)；返：A5@(2165, -55, monastery_return) | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C10 | A6 → A3 | shortcut | blocked | both | opened_bell_tower_drop | A6 | 出：A6@(2230, -55)；入：A3@(1710, 0)；返：A6@(2100, -90) | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C11 | A6 → A7 | main | both | both | 无额外解锁条件 | — | 未提供独立 spatial_contract；以 layer_contract 与源码门/出生点映射为准 | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C12 | A7 → A4 | shortcut | blocked | both | reached_A7_then_opened_supply_tunnel | A7 | 出：A7@(520, 0)；入：A4@(1050, -75)；返：A4@(960, -75)；反向到达：A7@(610, 0, supply_tunnel) | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C13 | A7 → A8 | main | both | both | 无额外解锁条件 | — | 出：A7@(2528, -140, maintenance_shaft_entry)；入：A8@(72, -140, maintenance_shaft_return)；返：A7@(2340, -120, maintenance_shaft_return)；到达：A8@(190, -120, maintenance_shaft_entry) | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C14 | A8 → A9 | main | both | both | 无额外解锁条件 | — | 出：A8@(2528, 0)；入：A9@(72, 0, west)；返：A8@(2420, 0, east)；反向到达：A9@(180, 0, west) | 已按源码边界门与安全出生点补齐 spatial_contract，并增加静态方向审计；仍需实机验收 |
| C15 | A8 → A11 | secret | blocked | both | resonance_sight_active_and_resonance_at_least_55_and_ancient_exposure_at_least_2_and_sources_anomaly_bell_retiming_and_anomaly_erased_royal_name | A8 | 未提供独立 spatial_contract；以 layer_contract 与源码门/出生点映射为准 | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C16 | A3 → A9 | shortcut | blocked | both | reached_A9_via_A8_then_opened_old_lift_from_A9 | A9 | 出：A3@(2040, -70)；入：A9@(520, -110)；返：A3@(1960, -70)；到达：A9@(610, -110) | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C17 | A9 → A10 | main | both | both | 无额外解锁条件 | — | 出：A9@(2350, -180)；入：A10@(180, -180, cathedral_roof)；返：A9@(2450, -180, cathedral_roof_return) | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C18 | A9 → A12 | shortcut | blocked | both | reached_A12_via_A10_then_opened_inner_city_side_gate | A12 | 出：A9@(900, 0, inner_city_side_gate)；入：A12@(520, 0, inner_city_side_gate)；返：A9@(980, 0, inner_city_side_gate)；反向到达：A12@(650, 0, inner_city_side_gate) | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C19 | A10 → A11 | secret | blocked | both | resonance_sight_active_and_resonance_at_least_68_and_outer_exposure_at_least_12_and_outer_god_resonance_and_source_anomaly_mirror_street_echo | A10 | 未提供独立 spatial_contract；以 layer_contract 与源码门/出生点映射为准 | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C20 | A10 → A12 | main | both | both | 无额外解锁条件 | — | 未提供独立 spatial_contract；以 layer_contract 与源码门/出生点映射为准 | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C21 | A11 → A13 | ending | blocked | forward | ending_candidate_is_not_human_grave_based_on_resonance_truth_anchors_and_exploration | A11 | 未提供独立 spatial_contract；以 layer_contract 与源码门/出生点映射为准 | 源码按 NereisEndingEvaluator 判定；旧验证器曾错误要求 physical_union_complete，已修正 |
| C22 | A12 → A13 | ending | from_to | forward | reached_A12_via_A10 | A12 | 出：A12@(2130, -65)；入：A13@(180, 0, west)；到达：A13@(180, 0, west) | 源码按 reached_A12_via_A10 开放；终局方向为单向 |
| C23 | A9 → A4 | shortcut | blocked | both | reached_A9_then_opened_royal_drain_from_outer_ring | A9 | 出：A9@(740, -150)；入：A4@(1650, -105)；返：A4@(1540, -120, royal_drain)；反向到达：A9@(650, -150) | 源码存在对应转场分支；仅静态源码核对，未作 Godot 实机验收 |
| C24 | A1 → A3 | shortcut | blocked | both | village_defense_survived | A1 | 出：A1@(100, 0)；入：A3@(520, 0)；返：A1@(350, 0, city_cut_return)；到达：A3@(700, 0, village_city_cut) | 源码双端按 village_defense_survived 控制；静态验证已有落点约束 |

**关于方向字段：** `initial_access` / `final_direction` 描述宏观拓扑图中的方向模型；带剧情事件门的路线还必须读取 `unlock_condition` 和 `progression_gate`。这不是 Godot 物理门碰撞已经验收的证明。

## 5. 正式隐藏区域 H01–H08

| ID | 名称 | 父区域 | 场景 | 门槛（共鸣 / 古神暴露 / 外神暴露） | 需要灵视 | 必需线索来源 | 次级出口 | 次级出口条件 | 拓扑实现标记 |
|---|---|---|---|---|---|---|---|---|---|
| H01 | 井底回声层 | A1 | scenes/hidden_well.tscn | 12 / 0 / 0 | 是 | 无 | A4 | reached_A4_via_A3_and_H01_opened_from_either_side | graybox_scene_and_gate_wired_runtime_unverified |
| H02 | 倒响钟室 | A2 | scenes/hidden_bell_chamber.tscn | 18 / 0 / 0 | 是 | 无 | A5 | reached_A5_then_opened_old_bell_tower_connection | graybox_scene_and_gate_wired_runtime_unverified |
| H03 | 被删去的第三街 | A3 | scenes/erased_third_street.tscn | 28 / 0 / 0 | 是 | 无 | A9 | reached_A9_then_opened_old_service_door | graybox_scene_and_gate_wired_runtime_unverified |
| H04 | 水面背后的楼梯 | A4 | scenes/reflected_stairwell.tscn | 36 / 1 / 0 | 是 | 无 | A8 | reached_A8_via_A7_then_opened_royal_tomb_side_door | graybox_scene_and_gate_wired_runtime_unverified |
| H05 | 无声钟室 | A6 | scenes/silent_bell_room.tscn | 42 / 1 / 0 | 是 | 无 | A3 | reached_A6_then_opened_bell_tower_drop_to_A3 | graybox_scene_and_gate_wired_runtime_unverified |
| H06 | 王名抹除廊 | A8 | scenes/erased_royal_name_corridor.tscn | 55 / 2 / 0 | 是 | anomaly_bell_retiming, anomaly_erased_royal_name | A9 | reached_A9_via_A8_then_opened_royal_transport_side_door | graybox_scene_and_gate_wired_runtime_unverified |
| H07 | 镜街：雨幕背后 | A9 | scenes/mirror_street.tscn | 68 / 0 / 12 | 是 | anomaly_mirror_street_echo | A12 | reached_A12_via_A10_then_opened_mirror_street_side_gate | graybox_scene_and_gate_wired_runtime_unverified |
| H08 | 胎宫 / 原初空腔 | A11 | scenes/primordial_hollow.tscn | 78 / 2 / 18 | 是 | anomaly_bell_retiming, anomaly_erased_street_sign, anomaly_old_stone_layer | A13 | ending_candidate_is_not_human_grave_based_on_resonance_truth_anchors_and_exploration | graybox_scene_and_gate_wired_runtime_unverified |

隐藏区域入口、发现、开启和实际进入是不同状态；请继续保留 `discovered_hidden_regions`、`opened_hidden_paths`、`entered_hidden_regions` 的区分。C15 与 C19 是进入 A11 的不同入口，不应共用同一个门 ID 或解锁标记。

## 6. 宏观环路 L01–L03

| ID | 名称 | 路径 | 所需条件 |
|---|---|---|---|
| L01 | 边境环路 | A1 → A2 → A3 → A4 → A1 | opened_sewer_inspection_hatch_from_A4, opened_watergate_and_village_well_exit |
| L02 | 中层环路 | A3 → A5 → A6 → A3 | opened_bell_tower_drop |
| L03 | 王国深层环路 | A4 → A8 → A9 → A4 | reached_A8_via_A7_then_opened_royal_tomb_gate, reached_A9_then_opened_royal_drain_from_outer_ring |

这些是**条件性环路**，不是新游戏一开始就全部开放。实际验收需在条件达成后分别走正向与反向，并检查回程出生点是否承托、是否落在门触发区内。

## 7. 六个叙事宏区 M1–M6

| ID | 名称 | 包含区域 |
|---|---|---|
| M1 | 边境村庄与荒野 | A1, A2, A5 |
| M2 | 废弃城区与地下水系 | A3, A4 |
| M3 | 教会边陲与圣堂领地 | A0, A6, A7, A10 |
| M4 | 王城与王室墓地 | A8, A9, A12 |
| M5 | 教会秘密研究区与古神遗迹 | A11 |
| M6 | 深层梦境与终局异象 | A13 |

## 8. 子区域清单（76 项）

| 子区域 ID | 父区域 | 名称 | 层级 | 作用 |
|---|---|---|---|---|
| A0-S01 | A0 | 手术室 | interior | 序章起点 |
| A0-S02 | A0 | 观察廊 | upper | 俯视实验区域 |
| A0-S03 | A0 | 排污井 | underground | 单向逃脱落差 |
| A1-S01 | A1 | 村庄主街 | ground | 初始导航轴 |
| A1-S02 | A1 | 民居后巷 | ground | NPC与支路 |
| A1-S03 | A1 | 屋顶木栈道 | upper | 可选屋顶探索路线；C24不经过此处 |
| A1-S04 | A1 | 老井平台 | ground | 井口与安全交互点 |
| A1-S05 | A1 | 井底回声层入口 | deep | H01发现点 |
| A2-S01 | A2 | 雾林地面 | ground | 主路与狭窄遭遇 |
| A2-S02 | A2 | 钟墓外圈 | ground | 绕行和墓坑入口 |
| A2-S03 | A2 | 钟墓坑底 | underground | H02关联的低位空间 |
| A2-S04 | A2 | 树冠栈道 | upper | C03高路 |
| A2-S05 | A2 | 旧朝圣高路 | upper | C04远端捷径 |
| A3-S01 | A3 | 西侧城区入口 | ground | C03落点 |
| A3-S02 | A3 | 旧市场街 | ground | H03线索锚点 |
| A3-S03 | A3 | 东侧街巷 | ground | 地面回环 |
| A3-S04 | A3 | 屋顶连廊 | upper | C16高位落点与屋顶探索；C24不经过此处 |
| A3-S05 | A3 | 抬高管线 | upper | C05入口 |
| A3-S06 | A3 | 钟塔落差平台 | upper | C10落点 |
| A3-S07 | A3 | 地下检查口 | underground | 通往A4的下行口 |
| A4-S01 | A4 | 上层检查廊 | upper | C05/C23高位交通 |
| A4-S02 | A4 | 沉积大厅 | ground | 主识别空间与战斗区 |
| A4-S03 | A4 | 中层水道 | underground | C07王墓水道 |
| A4-S04 | A4 | 旧水库边缘 | ground | 水位机关 |
| A4-S05 | A4 | 低位淹水沟 | underground | C12补给道 |
| A4-S06 | A4 | 水库底层井道 | deep | C06回村与H04邻接 |
| A4-S07 | A4 | 水闸机房 | underground | 控制回村捷径 |
| A5-S01 | A5 | 战壕地面 | ground | 主战斗路径 |
| A5-S02 | A5 | 坍塌城墙 | upper | 可攀登的中间层 |
| A5-S03 | A5 | 堡垒城墙 | upper | C09与C04连接点 |
| A5-S04 | A5 | 瞭望箭楼 | tower | 远景与高风险支路 |
| A5-S05 | A5 | 断桥绞盘 | upper | 开启A2高路回环 |
| A6-S01 | A6 | 下层回廊 | ground | A7主线入口 |
| A6-S02 | A6 | 修道院庭院 | ground | 区域识别中心 |
| A6-S03 | A6 | 上层廊桥 | upper | 俯视庭院的侧路 |
| A6-S04 | A6 | 钟塔中层 | tower | 塔内垂直穿行 |
| A6-S05 | A6 | 钟塔顶 | tower | C10落差起点 |
| A6-S06 | A6 | 无声窗口 | deep | H05入口 |
| A7-S01 | A7 | 监牢走廊 | ground | 主线推进 |
| A7-S02 | A7 | 下层囚室 | underground | 高风险支路 |
| A7-S03 | A7 | 忏悔井 | deep | 垂直下降空间 |
| A7-S04 | A7 | 维护竖井上缘 | upper | A8入口侧 |
| A7-S05 | A7 | 维护竖井底部 | underground | C12低位补给口 |
| A7-S06 | A7 | 供给隧道闸门 | underground | 可从监牢侧开启 |
| A8-S01 | A8 | 王墓入口平台 | ground | A7进入点 |
| A8-S02 | A8 | 王族墓室 | ground | 主路与王权线索 |
| A8-S03 | A8 | 中层墓道水渠 | underground | C07连接点 |
| A8-S04 | A8 | 深层铭文廊 | deep | H06线索 |
| A8-S05 | A8 | 王室维护井 | deep | C15秘密入口 |
| A8-S06 | A8 | 升降平台井 | vertical | 王墓内部垂直捷径 |
| A9-S01 | A9 | 外环下层街巷 | ground | A8进入点 |
| A9-S02 | A9 | 外环广场 | ground | 导航中心 |
| A9-S03 | A9 | 屋顶步道 | upper | C16/C17高路 |
| A9-S04 | A9 | 王室高位排水道 | upper | C23入口 |
| A9-S05 | A9 | 旧升降机下站 | vertical | C16升降机下站 |
| A9-S06 | A9 | 内城服务门 | ground | C18回环点 |
| A9-S07 | A9 | 积水镜街入口 | deep | H07入口 |
| A10-S01 | A10 | 朝圣阶梯 | ground | 主路外部入口 |
| A10-S02 | A10 | 大圣堂主堂 | ground | 主要仪式空间 |
| A10-S03 | A10 | 侧廊 | ground | 环绕主堂的支路 |
| A10-S04 | A10 | 唱诗席高廊 | upper | C17进入点 |
| A10-S05 | A10 | 静默侧礼拜堂 | deep | C19秘密入口 |
| A10-S06 | A10 | 教会维护梯井 | vertical | 高廊与下层维护空间 |
| A11-S01 | A11 | 王室维护井出口 | underground | C15进入点 |
| A11-S02 | A11 | 教会实验层 | ground | 研究设施与线索 |
| A11-S03 | A11 | 古神遗留层 | deep | 空间异常加剧 |
| A11-S04 | A11 | 胎宫外缘 | deep | H08前置空间 |
| A11-S05 | A11 | 原初空腔 | deep | 终局异象连接 |
| A12-S01 | A12 | 内城服务街 | ground | C18回返落点 |
| A12-S02 | A12 | 王室庭院 | ground | 王权主路线 |
| A12-S03 | A12 | 城墙步道 | upper | 侧向高路 |
| A12-S04 | A12 | 王座厅上层 | tower | 结局前空间 |
| A12-S05 | A12 | 城墙货运井 | vertical | 内城垂直运输点 |
| A13-S01 | A13 | 梦境边界 | deep | 按结局改变入口 |
| A13-S02 | A13 | 记忆回廊 | deep | 结局专属空间 |
| A13-S03 | A13 | 终局场域 | deep | 不同结局的战斗/叙事结构 |

## 9. 区域内连接清单（71 项）

| ID | 端点 | 类型 | 方向 | 初始状态 | 解锁条件 | 设计备注 |
|---|---|---|---|---|---|---|
| SC001 | A0-S01 → A0-S02 | walk | both | open | — | — |
| SC002 | A0-S02 → A0-S03 | drop | one_way | open | — | — |
| SC003 | A1-S01 → A1-S02 | walk | both | open | — | — |
| SC004 | A1-S01 → A1-S03 | walk | both | open | — | — |
| SC005 | A1-S03 → A1-S04 | walk | both | open | — | — |
| SC006 | A1-S04 → A1-S05 | resonance | both | locked | resonance_12 | — |
| SC007 | A2-S01 → A2-S02 | walk | both | open | — | — |
| SC008 | A2-S02 → A2-S03 | drop | both | open | — | — |
| SC009 | A2-S01 → A2-S04 | climb | both | open | — | — |
| SC010 | A2-S04 → A2-S05 | walk | both | open | — | — |
| SC011 | A2-S02 → A2-S04 | loop | both | locked | opened_forest_rope_bridge | — |
| SC012 | A3-S01 → A3-S02 | walk | both | open | — | — |
| SC013 | A3-S02 → A3-S03 | walk | both | open | — | — |
| SC014 | A3-S01 → A3-S04 | climb | both | open | — | — |
| SC015 | A3-S04 → A3-S05 | walk | both | open | — | — |
| SC016 | A3-S04 → A3-S06 | drop | both | locked | opened_bell_tower_drop | — |
| SC017 | A3-S03 → A3-S07 | hatch | both | open | — | — |
| SC018 | A4-S01 → A4-S02 | stairs | both | open | — | — |
| SC019 | A4-S02 → A4-S03 | ladder | both | open | — | — |
| SC020 | A4-S03 → A4-S04 | walk | both | open | — | — |
| SC021 | A4-S04 → A4-S05 | drop | both | open | — | — |
| SC022 | A4-S05 → A4-S06 | shaft | both | open | — | — |
| SC023 | A4-S02 → A4-S07 | walk | both | open | — | — |
| SC024 | A4-S07 → A4-S06 | gate | both | locked | opened_watergate | — |
| SC025 | A5-S01 → A5-S02 | climb | both | open | — | — |
| SC026 | A5-S02 → A5-S03 | walk | both | open | — | — |
| SC027 | A5-S03 → A5-S04 | ladder | both | open | — | — |
| SC028 | A5-S03 → A5-S05 | winch | both | locked | opened_pilgrim_highroad | — |
| SC029 | A6-S01 → A6-S02 | walk | both | open | — | — |
| SC030 | A6-S02 → A6-S03 | stairs | both | open | — | — |
| SC031 | A6-S03 → A6-S04 | ladder | both | open | — | — |
| SC032 | A6-S04 → A6-S05 | ladder | both | open | — | — |
| SC033 | A6-S05 → A6-S06 | resonance | both | locked | resonance_42 | — |
| SC034 | A7-S01 → A7-S02 | walk | both | open | — | — |
| SC035 | A7-S02 → A7-S03 | drop | both | open | — | — |
| SC036 | A7-S03 → A7-S05 | shaft | both | open | — | — |
| SC037 | A7-S01 → A7-S04 | stairs | both | open | — | — |
| SC038 | A7-S05 → A7-S06 | gate | both | locked | opened_supply_tunnel | — |
| SC039 | A8-S01 → A8-S02 | walk | both | open | — | — |
| SC040 | A8-S02 → A8-S03 | stairs | both | open | — | — |
| SC041 | A8-S03 → A8-S04 | ladder | both | open | — | — |
| SC042 | A8-S04 → A8-S05 | hatch | both | locked | discovered_royal_maintenance_shaft | — |
| SC043 | A8-S02 → A8-S06 | lift | both | locked | powered_royal_tomb_lift | — |
| SC044 | A8-S06 → A8-S03 | loop | both | locked | opened_tomb_platform_loop | — |
| SC045 | A9-S01 → A9-S02 | walk | both | open | — | — |
| SC046 | A9-S02 → A9-S03 | climb | both | open | — | — |
| SC047 | A9-S03 → A9-S04 | crawl | both | open | — | — |
| SC048 | A9-S01 → A9-S05 | lift | both | locked | opened_old_lift | — |
| SC049 | A9-S05 → A9-S03 | lift | both | locked | opened_old_lift | — |
| SC050 | A9-S01 → A9-S06 | gate | both | locked | opened_inner_city_side_gate | — |
| SC051 | A9-S01 → A9-S07 | resonance | both | locked | resonance_68 | — |
| SC052 | A10-S01 → A10-S02 | walk | both | open | — | — |
| SC053 | A10-S02 → A10-S03 | walk | both | open | — | — |
| SC054 | A10-S03 → A10-S04 | stairs | both | open | — | — |
| SC055 | A10-S04 → A10-S05 | resonance | both | locked | discovered_silent_side_chapel | — |
| SC056 | A10-S03 → A10-S06 | ladder | both | open | — | — |
| SC057 | A11-S01 → A11-S02 | walk | both | open | — | — |
| SC058 | A11-S02 → A11-S03 | drop | both | open | — | — |
| SC059 | A11-S03 → A11-S04 | hatch | both | locked | resonance_78 | — |
| SC060 | A11-S04 → A11-S05 | anomaly | one_way | locked | ending_state_allows_deep_dream_entry | — |
| SC061 | A12-S01 → A12-S02 | walk | both | open | — | — |
| SC062 | A12-S02 → A12-S03 | stairs | both | open | — | — |
| SC063 | A12-S03 → A12-S04 | lift | both | locked | opened_throne_service_lift | — |
| SC064 | A12-S01 → A12-S05 | lift | both | locked | opened_inner_city_cargo_lift | — |
| SC065 | A12-S05 → A12-S03 | lift | both | locked | opened_inner_city_cargo_lift | — |
| SC066 | A13-S01 → A13-S02 | walk | both | open | — | — |
| SC067 | A13-S02 → A13-S03 | walk | both | open | — | — |
| SC068 | A2-S01 → A2-S04 | lift | both | locked | repaired_forest_counterweight | 对应 elevators 中的实体升降机合同；未解锁时仍须存在替代通路。 |
| SC069 | A4-S01 → A4-S06 | lift | both | locked | restored_reservoir_power | 对应 elevators 中的实体升降机合同；未解锁时仍须存在替代通路。 |
| SC070 | A6-S02 → A6-S05 | lift | both | locked | opened_bell_tower_mechanism | 对应 elevators 中的实体升降机合同；未解锁时仍须存在替代通路。 |
| SC071 | A7-S01 → A7-S05 | lift | both | locked | released_prison_counterweight | 对应 elevators 中的实体升降机合同；未解锁时仍须存在替代通路。 |

## 10. 升降机契约（8 项）

| ID | 名称 | 端点 | 类型 | 初始状态 | 解锁条件 | 操作方式 | 安全约束 |
|---|---|---|---|---|---|---|---|
| LFT01 | 雾林绞盘升降台 | A2-S01 ↔ A2-S04 | counterweight_platform | broken | repaired_forest_counterweight | 上下站均有手动绞盘；第一次修复后永久可用 | 平台停靠时才允许上下；井道内设置可辨识的横梁和落差 |
| LFT02 | 沉积大厅维护笼 | A4-S01 ↔ A4-S06 | caged_service_lift | unpowered | restored_reservoir_power | 先在机房恢复供能，再在上下站分别呼叫 | 未供能时使用梯子/坡道作为基础通路，不以升降机故障软锁玩家 |
| LFT03 | 钟塔配重梯 | A6-S02 ↔ A6-S05 | counterweight_lift | locked | opened_bell_tower_mechanism | 庭院侧解锁，塔顶可反向召回 | 与C10落差捷径分离；电梯提供安全回程，落差提供快速但有风险的路线 |
| LFT04 | 监牢维护吊笼 | A7-S01 ↔ A7-S05 | cage_lift | locked | released_prison_counterweight | 可从走廊或竖井底部操作 | 不替代C12低位补给隧道，二者提供不同风险与落点 |
| LFT05 | 王墓石台 | A8-S02 ↔ A8-S06 | stone_platform_lift | sealed | powered_royal_tomb_lift | 以墓室侧机关启动；可从中层水道回召 | 升降平台连接墓室与中层水道，不直接跳过王墓主线门 |
| LFT06 | 外环旧货梯 | A9-S01 ↔ A9-S05 | freight_lift | locked | opened_old_lift | 外环下层开闸后可往返屋顶站；跨区C16另行接入A3屋顶 | 停靠动画/声音应能被附近玩家感知，避免无反馈传送 |
| LFT07 | 内城货运升降机 | A12-S01 ↔ A12-S05 | royal_service_lift | locked | opened_inner_city_cargo_lift | 从服务街和城墙维护点双向操作 | 为高低层回环服务，不作为王座厅的强制捷径 |
| LFT08 | 王座厅配重梯 | A12-S03 ↔ A12-S04 | counterweight_lift | locked | opened_throne_service_lift | 从城墙步道侧开启后可在王座厅上层召回 | 只改变进入高度，不改变结局判定 |

升降机是区域内部垂直交通契约，不取代 C 系列跨区域门。未解锁的升降机不能成为主线软锁点；基础通路和落点安全需要单独验收。

## 11. 临时候选区域

| ID | 名称 | 父区域 | 场景 | 状态 |
|---|---|---|---|---|
| H09 | 临时候选：崖下实验窟 | A1 | scenes/cliff_cave_experiment.tscn | implemented_graybox_candidate_runtime_unverified |

H09「崖下实验窟」当前是临时候选区域，代码已有灰盒场景，但正式 H 编号基线仍是 H01–H08。除非另有设计决议，不要把 H09 计入正式隐藏区域数量，也不要让它改变 H01–H08 的编号。

## 12. 本轮发现与修正

### P0-01：C02 村庄北门的剧情门槛缺失于拓扑（已修正元数据）

源码行为：
- A1 的 `north_gate` 交互在 `village_defense_survived` 未记录时，会进入 `village_defense_demo.tscn`。
- 防卫结束后记录 `village_defense_survived` 并返回 A1。
- 再次互动北门，才进入 A2（`ash_forest.tscn`）。
- A2 的西侧出口将玩家送回 A1 的 `north_gate` 出生侧。

原拓扑 C02 没有记录该条件，容易让总账误以为它是新游戏即刻开放的普通地面门。本轮已在 C02 加入 `unlock_condition`、`opens_from` 和 `progression_gate` 说明。宏观图仍保留 A1↔A2 的双向结构；实际首进 A2 由村庄防卫事件门控制。

### P0-02：C21 / H08 的终局条件验证规则过期（已修正静态规则）

实际源码在 A11 的 C21 与 H08 的终局入口都使用：

`NereisEndingEvaluator.get_candidate() != "凡人之墓"`

其意图是按共鸣、真相锚点与探索结果判断可否进入终局层，而不是使用 `physical_union_complete` 作为路线门槛。拓扑数据已经表达这一设计，但三个静态验证器仍要求旧的亲密关系标记，形成设计、源码、验证规则之间的冲突。本轮已将：
- `tools/validate_world_map_topology.py`
- `tools/validate_connection_direction_audit.py`
- `tools/validate_graybox_scene_wiring.py`

对齐到当前评估器语义。**验证器文件已修改，但本轮环境没有本地检出仓库，因此没有声称已执行并通过这些脚本。**

### P0-03：C14 空间契约已补齐（静态已对齐，实机待验收）

根据源码中的门创建与默认出生侧映射，C14 使用 A8 东侧边界门 `map_width - 72`（当前地图宽度下 x=2528）和 A9 西侧边界门 x=72。A8 的 `east` 到达点为 `map_width - 180`（x=2420），A9 的 `west` 到达点为 x=180。已将这些值写入 C14 的 `spatial_contract`，并在 `validate_connection_direction_audit.py` 中加入拓扑字段与源码映射检查。源码文本只能证明坐标约定，不能证明落地承托和交互净距在运行时一定正确。

### P0-04：宏观拓扑不等于可游玩验证（保留为待验收）

以下内容不能仅靠 JSON 或 GDScript 文本证明：
- 连续地面能否绕过高位门或被锁门；
- 跳跃弧线是否能到达预定平台；
- 角色是否在转场后立即重新触发同一扇门；
- 出生点是否有承托、是否与休整点/其他交互焦点重叠；
- 死亡恢复、读档继续和隐藏门状态是否保持一致；
- A0→A1→A2 主线在全新存档下是否完整可玩。

## 13. 静态检查清单与命令

在仓库根目录执行：

```bash
python3 tools/validate_world_map_topology.py
python3 tools/validate_spatial_route_contracts.py
python3 tools/validate_connection_direction_audit.py
python3 tools/validate_graybox_scene_wiring.py
```

预期职责：
- `validate_world_map_topology.py`：编号、宏观图可达性、主线顺序、环路、分层拓扑。
- `validate_spatial_route_contracts.py`：高位门、平台承托、出生点净距、休整点与死亡恢复。
- `validate_connection_direction_audit.py`：指定连接方向、隐藏门条件、C15/C19 独立回程、终局入口。
- `validate_graybox_scene_wiring.py`：场景文件、脚本转场、隐藏区域和存档/剧情接线。

运行后若有失败，应先修复拓扑/源码/验证规则之间的真实差异；不要为了让检查通过而把错误条件重新写回游戏代码。

## 14. Godot 4.6.1 实机验收清单

- [ ] 新存档：A0 完成逃脱进入 A1。
- [ ] A1 首次互动北门触发村庄防卫；失败/重试流程不丢失进度。
- [ ] 防卫胜利返回 A1；北门第二次互动进入 A2。
- [ ] A2 西侧门返回 A1 后，出生位置安全且不会自动触发北门。
- [ ] 按主线顺序走通 A2→A3→A5→A6→A7→A8→A9→A10→A12。
- [ ] 条件满足后分别验证 L01、L02、L03 的双向回路。
- [ ] 分别验证 H01–H08 的发现、开门、进入、回程、存档和死亡恢复。
- [ ] 验证 C15 与 C19 进入 A11 的条件独立。
- [ ] 验证 C21、C22、H08 三条终局入口都进入 A13，再由终局评估器选择结局。
- [ ] 检查高位门、低位门和连续地面之间不存在未设计的绕行。
- [ ] 验收 C14 两端门和出生点的高度、承托与触发净距。

## 15. P0 完成状态

- [x] A/H/C/L/SC/LFT 编号体系与数量已盘点。
- [x] A0–A13 场景归属、C01–C24 端点/方向/解锁条件已汇总。
- [x] H01–H08 条件与次级出口已汇总；H09 保留为候选。
- [x] 6 个宏区、76 个子区域、71 条区域内连接、8 个升降机契约已纳入总账。
- [x] C02 的村庄防卫门槛已写入拓扑数据。
- [x] C21/H08 静态验证规则已对齐当前结局评估器。
- [x] C14 地面双向门的空间锚点已按源码坐标补齐，并加入静态方向审计。
- [ ] 本地运行四个 Python 静态验证器（需在实际仓库工作区执行）。
- [ ] Godot 4.6.1 实机验收（需运行游戏验证）。
