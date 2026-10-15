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
| C12 | A4 水库 | prison_tunnel | x=960 | -75 |
| C16 | A3 城区 | old_lift | x=1960 | -70 |
| C23 | A4 水库 | royal_drain | x=1540 | -120 |
| C24 | A3 城区 | village_city_cut | x=700 | 0 |
| C24 | A1 村庄 | city_cut_return | x=350 | 0 |
| C17 | A9 → A10 | west | 高位屋顶接近点 x=2350 | -180 |

### 本轮核对结果

- 已核对 C03、C05、C07、C10、C12、C16、C23 的拓扑回程坐标与灰盒出生侧映射。
- 已核对 C24 两端的出生侧命名：A3 使用 `village_city_cut`，村庄使用 `city_cut_return`；村庄控制器将回程放在 x=350 的安全区域。
- 已核对 C17 的城区高位入口仍在 A9 的 x=2350、地面上方 180 像素处，目标场景从 A10 的 west 侧进入。
- 新工具同时检查拓扑记录、代码出生点映射与高位出口的平台支撑，避免只改 JSON 或只改 GDScript 后留下漂移。

### C03 A2 树冠出口修正（2026-10-15）

复核时发现 A2 的 C03 出口调用使用 `map_width - 160`，在当前场景宽度 2600 下实际落在 x=2440；但拓扑锚点和静态路线合同均要求 x=2240，A2 东侧树冠平台也只覆盖 x=2220–2340。出口因此偏离平台，导致玩家可能看到入口标记，却难以在正确的高位路线触发交互。

已将 A2→A3 出口锚点修正为 x=2240，使门与平台、拓扑合同一致。该修改已提交到 `development`。这属于源码几何修复；Godot 运行时仍需确认走上平台后能显示 E 提示并完成转场，不能据此宣称实机验收通过。

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


### Debug 出口标识与交互锚点对齐（2026-10-15）

出口/隐藏门的调试标识原本把箭头尖端放在交互锚点上方约 118px，视觉上容易被误读成“门就在箭头尖端”。现在改为箭头向下指向门节点的真实锚点，并在锚点绘制小圆点；文字仍显示在上方。普通出口标记仍直接读取门节点位置，避免另设一份会漂移的坐标。该标识仅用于灰盒调试，正式美术与地图导航完善后应整体移除或替换，不作为正式 UI 设计。

同时修正静态路线检查对 C03 高位门的支撑容差：门节点锚点位于 y=380，树冠平台顶面位于 y=410，门的交互形状向下偏移，因此这 30px 的高度差是当前门体布局的预期值，不应误报为未承托。验证器源码已调整，但本次环境没有执行 Godot 场景运行；请将静态脚本检查与引擎实测分开记录。


### C13 空间合同与结局入口条件复核（2026-10-15）

- C13 的实体门节点在 A7/A8 分别位于 x=2528/x=72、y_offset=-140；两侧主角出生高度仍为 y_offset=-120，落在 y=420 的承托平台。A7 回程出生点实际使用 `map_width - 260`，当前宽度 2600 时为 x=2340，距离东门 x=2528 为 188px；此前拓扑记录的 x=2440 会让出生点过近，已更正。
- 修正 C12 静态合同中错误的 A4 回程点：实际代码与拓扑均为 x=960、y_offset=-75，不是 x=1090。
- 发现 C21 与 H08 的终局支路仍使用 `physical_union_complete`，这与 `NereisEndingEvaluator` 明确声明的结局原则冲突。现改为由结局评估器判断：候选结局不是“凡人之墓”时开放通往 A13 的可选支路；否则在 Debug 构建显示条件提示。路线依据鸣响、真相锚点与隐藏探索，不以身体亲密作为门槛。

本次源码、拓扑和静态验证器已同步修改；仍需本地 Godot 4.6.x 实机确认 C13 双向落点、交互焦点及 C21/H08 条件切换。尚未在此环境运行 Godot 或实际执行验证器，不能视为运行时验收通过。


### C22 王座厅终局入口与调试虚拟标识（2026-10-15）

C22 原先在 A12 使用 `map_width - 72` 的地面门点，与拓扑中的“王座厅上层”不一致，而且会让玩家从地面直线进入终局层。现将 C22 门点移动到 x=2130、y_offset=-65，落在 A12 的实体上层平台（x=2100–2290、y=475）上。它与地面 H07 镜街入口 x=2250 保持水平和垂直净距，避免两个交互焦点争抢 E 键。尚未满足主线抵达条件时，C22 的调试虚拟标识也使用相同的高位锚点。

统一调整调试锁定标识接口，允许传入可选 y 坐标；C04、C12、C07、C16、C23 等高位/低位路线提示现在与对应门的高度一致，普通地面提示仍默认使用 floor_y。标识只存在于 Debug 构建，用于关卡验证，正式美术与导航方案完成后应移除或替换。


### C11 / C14 / C15 / C19 双端与门槛复核（2026-10-15）

| 连接 | 源码核对结果 | 状态 |
|---|---|---|
| C11 A6↔A7 | 两端实体门都在地面主路，目标出生侧使用默认安全落点；没有将高位出口误放到地面的问题。 | 静态核对一致 |
| C14 A8↔A9 | 王墓东侧与外环西侧均为地面主路门，双向目标场景与默认出生侧相符。 | 静态核对一致 |
| C15 A8→A11 | A8 的灵视门要求鸣响≥55、古神暴露≥2、铃声重排与王名抹除两条线索；永久开启后，A11 的王室竖井回门才启用。目标出生侧为 A11 的 west。 | 静态核对一致 |
| C19 A10→A11 | 大圣堂侧门要求鸣响≥68、外神暴露≥12、外神共鸣事实及镜街回声线索；永久开启后，A11 的大圣堂回门才启用。目标出生侧为 A11 的 chapel_entry。 | 静态核对一致 |

以上结论来自源码与拓扑的静态对照。它们没有证明两条隐藏入口在实际游玩时都容易发现，也没有证明角色碰撞、灵视显示、按 E 开门、第二次按 E 转场和存档持久化已经通过实机验收。


### 死亡恢复、休整点与相邻交互焦点复核（2026-10-15）

本轮发现并修正三处出生点净距问题，并收紧休整点记录检查点的条件：

- **C07：A8 → A4 王墓水道。** A4 出生点原为 x=1260，距离 x=1320 门中心仅 60px。门的 Area2D 水平半宽为 55px，主角碰撞半径为 18px，因此出生时会与门触发区重叠。现在将落点移至 x=1410、y_offset=-85，仍在 A4 的 x=1260–1450、顶面 y=455 平台上，并留出 17px 的水平净距。
- **C23：A9 → A4 王城排水道。** A4 出生点原为 x=1570，距离 x=1650 门中心 80px，按当前门触发区与主角碰撞体计算只剩 7px 净距。现在移至 x=1540、y_offset=-120，仍由 x=1530–1600、顶面 y=420 的平台承托，水平净距增加到 37px。
- **C18：A12 → A9 内城侧门。** A9 出生点原为 x=1000，虽未进入 x=900 门的 Area2D，但距 x=1100 休整点只有 100px；休整点会在 110px 内获得交互焦点，导致刚落地就显示休整提示。现在移至 x=980，门触发区净距为 7px，且在休整点交互半径之外 10px。
- **休整点安全门槛。** 之前只按主角与休整点的直线距离判断可交互，可能在跳跃中或临近高台时保存空中/高层坐标作为检查点。现在要求主角处于 CharacterBody2D.is_on_floor() 状态、水平距离不超过 90px、垂直差不超过 32px 后，才允许休整和保存当前出生位置。
- **死亡恢复。** 共享区域控制器在死亡后锁定输入、清除旧交互焦点、恢复到当前区域的检查点，再清除焦点并解锁输入；每次进入共享区域时也会将入口出生点设为该区域检查点，避免复用上个区域的坐标。

验证器新增检查：C07/C23 出生点是否与实际平台顶面对齐、C07/C18/C23 与门触发区/休整焦点的净距、休整点是否要求落地，以及死亡恢复是否清理焦点并使用区域检查点。

**验收边界：** 本次修改与文档/验证器已提交，但此环境尚未实际执行 python3 tools/validate_spatial_route_contracts.py，也未运行 Godot 4.6.x。上述是源码和拓扑的静态审计结论；仍需实机确认角色胶囊与 Area2D 的实际重叠、落地帧的 is_on_floor() 状态、死亡后焦点刷新和双向转场。

### Death Recovery, Rest Points, and Interaction Focus Review (2026-10-15)

This pass fixes three arrival-clearance issues and tightens checkpoint activation:

- **C07, A8 → A4:** the old A4 arrival at x=1260 overlapped the x=1320 door trigger (60px center distance versus a 73px combined half-width). It now lands at x=1410 / y_offset=-85 on the same y=455 platform, leaving 17px of horizontal clearance.
- **C23, A9 → A4:** the old x=1570 arrival had only 7px of horizontal clearance from the x=1650 door trigger. It now lands at x=1540 / y_offset=-120 on the y=420 support lip, increasing clearance to 37px.
- **C18, A12 → A9:** the old x=1000 arrival was inside the x=1100 rest point's 110px focus radius. It now lands at x=980, outside the rest focus radius and outside the x=900 door trigger.
- **Rest-point checkpoint safety:** rest interaction now requires a grounded CharacterBody2D, within 90px horizontally and 32px vertically. This prevents saving an airborne or nearby upper-platform position as a death checkpoint.
- **Death recovery:** the shared-region controller locks input and clears stale focus before recovery, restores the Hero at the region-local checkpoint, then clears focus again before unlocking input. Entering each shared region initializes its checkpoint at the incoming spawn.

The static validator now checks platform support, the three arrival clearances, grounded rest-point activation, and the death-recovery focus/checkpoint path.

**Acceptance boundary:** The changes and checks are committed, but python3 tools/validate_spatial_route_contracts.py has not been executed in this environment, and Godot 4.6.x has not been run. These are source/topology audit results only; in-engine acceptance must still verify capsule/Area2D overlap, is_on_floor() timing on landing, post-death focus refresh, and bidirectional transitions.
