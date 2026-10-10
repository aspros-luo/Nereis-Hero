# A9–A12 主线路径与 H07 镜街灰盒（中文）

> 分支：development  
> 版本：Graybox Extension 0.1  
> 状态：代码与场景接线已提交；尚未在 Godot 4.6.x 中实机验收。  
> 目标：继续接通 A8 旧王墓 → A9 王城外环 → A10 大圣堂 → A12 王室内城的普通主线路径，同时把 H07 镜街挂在 A9。H07 的远端捷径必须等玩家先抵达 A12，并从 A12 侧打开镜街门后才开放。

## 1. 新增场景

| 区域 | 场景文件 | 位置 ID | 职责 |
|---|---|---|---|
| A9 王城外环 | `scenes/royal_outer_ring.tscn` | `royal_outer_ring` | A8 后的主线枢纽；R07 倒影调查；H07 灵视入口 |
| A10 大圣堂 | `scenes/grand_cathedral.tscn` | `grand_cathedral` | 主线从外环进入教会内廷 |
| A12 王室内城 | `scenes/inner_city.tscn` | `inner_city` | 普通主线的终局前区域 |
| H07 镜街：雨幕背后 | `scenes/mirror_street.tscn` | `mirror_street` | 需要外神剧情事实与灵视条件的隐藏子区 |

这些场景继续复用 `scripts/levels/greybox_world_region.gd`，使用同一套角色、相机、HUD、剧情提示、碰撞平台与出口交互逻辑。

## 2. 连续主线路线

~~~text
A8 旧王墓
  → A9 王城外环
       ├─ R07：积水中的镜街倒影（鸣响至少 68）
       └─ 主路 → A10 大圣堂 → A12 王室内城
~~~

普通主线不需要 H07，可以从 A8 直接经过 A9、A10 抵达 A12。H07 是可选路径，不应成为王座区的硬门槛，也不应用它跳过大圣堂。

## 3. R07 与 H07 的双重条件

### R07 — 积水里的第二条街

A9 主路线的积水里映出一条多出一盏路灯的街。调查 `anomaly_mirror_street_echo` 后，将鸣响提高到至少 68，并永久记录这条异常来源。

这次调查**不会自动授予外神接触度**。如果玩家没有经历外神相关剧情，鸣响虽然可能达到 68，但 H07 仍然不会变成可用入口。

### H07 — 镜街：雨幕背后

A9 的灵视门使用：

- 鸣响至少 68；
- 外神接触度至少 12；
- `WorldState.outer_god_resonance` 必须为真；
- 已记录 `anomaly_mirror_street_echo`；
- 灵视正在激活。

第一次 E 调查永久发现并开启 H07；第二次 E 才进入镜街。外神共鸣剧情负责把外神接触度提升到至少 12；R07 只在剧情标记成立时才会应用其接触度下限，因此不参与该路线的玩家不会被地图事件自动污染。

## 4. 镜街的第二出口由王室内城侧解锁

1. 玩家必须先通过 A10 主线抵达 A12，记录 `reached_A12_via_A10`。
2. 如果 H07 已在 A9 开启，A12 才生成通往镜街的侧门。
3. 从 A12 侧第一次按 E，只打开 `opened_mirror_street_side_gate`；第二次按 E 才进入 H07。
4. 在 H07 内，只有当这个内城侧门已从 A12 开启后，通往 A12 的出口才可用。
5. 返回 A9 使用专门的 `mirror` 出生侧，让主角出现在镜街入口附近，而不是地图最边缘。
6. H07 的发现、开启和进入状态使用现有的 `discovered_hidden_regions`、`opened_hidden_paths`、`entered_hidden_regions`，不会因为鸣响下降、死亡或切图重锁。

这样玩家可以先在 A9 发现隐藏空间，但不能凭借镜街提前绕过 A10；到达 A12 后，镜街才变成真正的跨区捷径。

## 5. 机器可读拓扑与场景状态

- A9 / A10 / A12 的场景恢复映射已加入 `WorldState.get_resume_scene_path()`。
- H07 共享固定 ID：`H07`，不是另外创建一份隐藏地图计数。
- 主线入口采用现有 `interaction_door.gd`；隐藏入口使用 `resonance_secret_gate.gd`。
- R07 由 `resonance_source_clue.gd` 实现。外神接触度下限会检查 `outer_god_resonance`，与隐藏门使用相同剧情条件。
- 静态接线检查脚本现覆盖 A2–A12 及 H01 / H07：`tools/validate_graybox_scene_wiring.py`。

在仓库根目录可运行：

~~~bash
python3 tools/validate_world_map_topology.py
python3 tools/validate_graybox_scene_wiring.py
~~~

以上是静态检查工具；它们不会模拟 Godot 的实际平台碰撞、相机移动、输入焦点或场景切换。

## 6. Godot 实机验收清单

- [ ] 从 A8 进入 A9，确认主路出口不会与 R07 调查点或 H07 门重叠。
- [ ] 调查 R07，确认鸣响至少为 68，重复调查不会二次奖励。
- [ ] 未经历外神共鸣：灵视激活时 H07 仍不出现可用提示。
- [ ] 外神共鸣事实成立且其他门槛满足后，灵视显现 H07；第一次 E 永久开启，第二次 E 进入。
- [ ] 关闭灵视并重新回到 A9，已打开 H07 仍保持开启。
- [ ] 未进入 A12 前，H07 的 A12 出口不可用。
- [ ] 经 A10 进入 A12 后，H07 已开启时才生成内城侧门；第一次 E 开门，第二次 E 进入镜街。
- [ ] 从镜街返回 A9 时出现在入口附近；内城侧门开启后，才可经 H07 返回 A12。
- [ ] 退出继续游戏后，当前位置、R07 来源、H07 开启标记、内城侧门开启标记都正确恢复。

**当前状态仍是代码接线已提交、静态结构已复核；Godot 4.6.x 实机验收尚未执行。**
