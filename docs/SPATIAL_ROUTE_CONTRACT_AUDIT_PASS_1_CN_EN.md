# Spatial Route Contract Audit — Pass 1 / 空间路线合同审计（第一轮）

> Branch: `development`  
> Scope: high-value elevated transitions and the post-defense drainage shortcut.  
> Status: source/topology cross-reference only. Godot runtime acceptance remains pending.

## 中文结论

本轮将“箱式地图的高低层路线”从设计说明提升为可重复检查的静态合同。新增工具：

```bash
python3 tools/validate_spatial_route_contracts.py
```

它对照 `tools/world_map_topology.json`、共享灰盒控制器中的出生点映射，以及关键高位出口下方的平台矩形，重点保护以下路线：

| 连接 | 回程区域 | 出生侧 | 目标落点 | 高度偏移 |
|---|---|---|---:|---:|
| C03 | A2 雾林 | east | x=2120 | -140 |
| C05 | A3 城区 | sewer | x=1380 | -115 |
| C07 | A4 水库 | royal_tomb_waterway | x=1260 | -85 |
| C10 | A6 修道院 | bell_drop | x=2100 | -90 |
| C12 | A4 水库 | prison_tunnel | x=1090 | -75 |
| C16 | A3 城区 | old_lift | x=1960 | -70 |
| C23 | A4 水库 | royal_drain | x=1620 | -120 |
| C24 | A3 城区 | village_city_cut | x=700 | 0 |
| C24 | A1 村庄 | city_cut_return | x=350 | 0 |
| C17 | A9 → A10 | west | 高位屋顶接近点 x=2350 | -180 |

### 本轮核对结果

- 已核对 C03、C05、C07、C10、C12、C16、C23 的拓扑回程坐标与灰盒出生侧映射。
- 已核对 C24 两端的出生侧命名：A3 使用 `village_city_cut`，村庄使用 `city_cut_return`；村庄控制器将回程放在 x=350 的安全区域。
- 已核对 C17 的城区高位入口仍在 A9 的 x=2350、地面上方 180 像素处，目标场景从 A10 的 west 侧进入。
- 新工具同时检查拓扑记录、代码出生点映射与高位出口的平台支撑，避免只改 JSON 或只改 GDScript 后留下漂移。

### 验收边界

以上属于静态一致性检查，不代表角色一定能跳到每个栈台，也不代表门的碰撞区、交互焦点和场景切换在实机中正确。Godot 4.6.x 本地走图仍需逐条确认：

1. 从主路线到达高位出口时，主角能实际站上对应平台并触发门。
2. 返回后主角落在正确高度，不会掉回地面、卡进墙体或直接触发另一扇门。
3. 捷径开启状态在切图、死亡、保存与继续游戏后仍保持一致。
4. C24 只有村庄防卫完成后才开放；它不能绕过 A1 的剧情门槛。
5. C17 的屋顶路线不能让玩家绕过大圣堂直接进入王室内城。

## English summary

This pass adds `tools/validate_spatial_route_contracts.py`, a repeatable static check that cross-references selected topology spawn contracts with the actual graybox spawn-side mappings and checks that key elevated door anchors sit on authored platform rectangles.

It covers C03, C05, C07, C10, C12, C16, C17, C23, and both ends of C24. The check protects the intended x/y landing points, the elevated A9-to-A10 approach, and the post-defense-only village drainage shortcut.

This is not a Godot runtime test. Local acceptance must still confirm jump reachability, collision, interaction focus, scene transitions, death recovery, and save/resume behavior.
