# C11/C13/C14/C15/C19/C21/C22 出生点、门交互与恢复审计

- 分支：development
- 日期：2026-10-15
- 状态：源码审计与针对性修复已提交；静态验证器待在完整 checkout 中执行；Godot 4.6.1 运行时验收待完成。
- 重要边界：以下坐标与条件来自源码。距离是基于当前触发器尺寸的几何估算，不代表物理模拟或运行时验收。

## 门与交互机制基线

- 普通出口由 `_spawn_exit_door()` 创建，Area2D 的 RectangleShape2D 为 110×80，形状偏移 (0,-35)。在地面 y=540 的门，触发区约为 y=465..545；高位门 y=420 的触发区约为 y=345..425。
- 普通门的交互还需要进入 Area2D 并赢得共享 interaction focus；普通门优先级 100。
- 灵视秘密门使用 80px 的径向距离判定，焦点优先级 25。门不是实体阻挡墙；高位路线仍需在 Godot 中实测是否可从地面绕行。
- 区域有连续地面碰撞体，平台使用 one-way collision。

## 逐条审计

| 连接 | 源码条件与方向 | 两端出生点 / 承托 | 结果与风险 |
|---|---|---|---|
| C11 A6↔A7 | A6 东门到 A7/west；A7 西门到 A6/east；双向，无额外解锁条件。 | west/east 默认出生 x=180/2420、y=floor_y；距离边界门 x=72/2528 均为 108px。 | 坐标上不在普通门 55px 半宽触发区内；地面路线。运行时仍需检查焦点和切图。 |
| C13 A7↔A8 | A7 东门到 A8/maintenance_shaft_entry；A8 西门到 A7/maintenance_shaft_return；两端门高为 floor_y−120。 | A8 出生 (190,420)，由 Rect2(80,420,150,18) 与 Rect2(240,420,170,18) 承托；A7 回程出生从 `map_width−160` 调整为 `map_width−260`（当前地图宽 2600 时 x=2340），由 Rect2(2200,420,370,18) 承托。 | A7 出生到门 x=2528 的中心距由 88px 增至 188px；扣除 55px 触发半宽和 18px 角色半径，理论水平净距约 115px。高门触发区底部约 y=425，地面主角胶囊顶部约 y=492，因此源码坐标不显示可从地面直接触发；跳跃/绕行仍待实测。 |
| C14 A8↔A9 | A8 东门到 A9/west；A9 西门到 A8/east；双向。 | 默认 west/east 出生 x=180/2420、y=floor_y；距边界门 108px。 | 坐标上不与边界门触发区重叠。拓扑缺少 C14 专用 spatial_contract，路线层的设计精度低于 C13。 |
| C15 A8→A11 | gate ID=C15；A11/west；要求灵视、resonance≥55、ancient exposure≥2、来源 anomaly_bell_retiming 与 anomaly_erased_royal_name。A11 回 A8 仅在 is_hidden_path_opened("C15") 时启用。 | A8 门 x=2310；A11 west 出生 x=180，A11 返回门 x=72。A11 回 A8 使用 east 出生 x=2420，距 C15 门中心 110px。 | 80px 径向门范围外约 30px。C15 与 A8 边界 C14 门中心相隔 218px，普通门矩形间约留 108px。与 H06 保持独立。 |
| C19 A10→A11 | gate ID=C19；A11/chapel_entry；要求灵视、resonance≥68、outer exposure≥12、outer_god_resonance 与 anomaly_mirror_street_echo。A11 回 A10 仅由 C19 自身打开状态启用。 | A11 chapel_entry 出生 x=1900、地面；A11 东侧回程门 x=2528，相距 628px。 | 源码状态锁与 C15 独立；实际进入后仍需检查焦点、存档/读档和回程门状态。 |
| C21 A11→A13 | topology 为 blocked→forward，要求 physical_union_complete；运行时仅在该标记为 true 时生成入口；A13 不创建普通 A11 回程门。 | A11 门 x=2050；A13 west 出生默认 x=180；A13 结局出口约 x=2510。 | 源码方向符合单向设计；需运行时确认 A13 没有意外回程或死亡/读档绕回。 |
| C22 A12→A13 | topology 为 from_to→forward，要求 reached_A12_via_A10；A12 在东侧生成 A13 入口；A13 无普通 A12 回程门。 | A13 west 出生 x=180；A13 结局出口约 x=2510；A12 返回大圣堂门 x=72，与 C22 入口 x=2528 分离。 | 源码方向符合单向设计；需运行时验收终局门与结局评估器。 |

## 死亡恢复与休整点

- `_spawn_hero()` 在每个区域入口将检查点设为主角实际出生坐标。
- 死亡时 Hero 脚本先发出 defeated 并立即把主角传送到 checkpoint；区域脚本随后等待 0.75 秒，再重设速度、再次传送到 checkpoint，并调用 restore_full()。本轮已在等待期间锁定 `WorldState.input_locked`，在恢复开始/结束清理共享交互焦点，降低主角在两阶段之间移动、门焦点残留或重复交互的风险。仍需运行时检查动画、无敌时间与物理同步。
- 休整点位于 (rest_x,floor_y)，交互半径 110px；使用后恢复状态、把检查点保存为主角当前位置并写入存档。
- 七个目标区域休整点：A6 x=1300、A7 x=1320、A8 x=1150、A9 x=1100、A10 x=1200、A11 x=1050、A12 x=1360。源码坐标上，它们没有与 C11/C13/C14/C15/C19/C21/C22 门同点；A8 休整点距 x=930 的王墓侧门约 220px，距 C15 x=2310 很远。
- C13 的入口检查点在高位平台上，平台坐标与出生点吻合；后续若调整平台，必须同步检查点支持。普通地面休整点由连续地面承托。
- 目前不能仅凭源码确认实际角色碰撞形状、焦点竞争、死亡瞬间的物理帧或存档恢复时机。

## 静态验证器执行状态

本轮更新了 `tools/validate_connection_direction_audit.py`，新增 C13 出生净距、死亡恢复输入锁/焦点清理、C22 主线前置条件，以及 C21/C22/H08 三个 A13 入口的静态契约检查。当前会话仍未提供可执行仓库脚本的本地 checkout/Python 环境，因此本轮**尚未执行**以下脚本，不能将其报告为通过：

```bash
python3 tools/validate_connection_direction_audit.py
python3 tools/validate_a8_spatial_boss_contract.py
python3 tools/validate_spatial_route_contracts.py
python3 tools/validate_graybox_scene_wiring.py
python3 tools/validate_world_map_topology.py
```

## 本轮源码修复记录

- C13：A7 回程出生偏移改为 `map_width - 260.0`，在当前 2600px 地图宽度下把出生点从 x=2440 移至 x=2340。
- 死亡恢复/切图：区域控制器在恢复等待期间锁定输入，恢复开始/结束清理共享交互焦点；转场前清理旧场景焦点。
- C22：A12 侧的 A13 入口现在要求 `reached_A12_via_A10`；不满足时显示锁定路线提示。
- 静态验证器新增对应断言，并明确列出 A13 三个允许入口：C21、C22、H08。
- 以上是源码/静态契约修复；没有声称已通过 Godot 运行时验收。

## Godot 4.6.1 运行时验收

1. C11/C13/C14 两端从地面与设计路径分别接近；确认地面不能触发 C13 高位门，平台能承托出生，且切图后不会立刻聚焦第二个门。
2. C13 特别检查 A7 的 x=2440 出生点与 x=2528 门的 88px 中心距、门触发范围、跳跃落地和地面绕行。
3. 分别只满足 C15 或 C19 条件，测试阈值以下/刚达阈值、灵视开关、独立回程锁、切图与存档恢复。
4. C21 在 physical_union_complete=false/true 两种状态下测试；C22 测试主线进 A13；确认 A13 没有普通回程门。
5. 在 A6/A7/A8/A9/A10/A11/A12 分别休整后死亡，检查复活点不在门触发区内、不悬空；保存后重启继续，重复检查。
6. 检查 Godot 输出中的焦点跳变、重复切图、碰撞告警，并将实际结果单独记录，不能把源代码审计当成运行时通过。
