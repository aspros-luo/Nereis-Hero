# A11 深层研究区与 H08 原初空腔灰盒接线（中文）

> 版本：Graybox A11 / H08 Draft 0.1  
> 分支：development  
> 状态：场景与入口代码已接线；尚未在 Godot 4.6.x 实机验收。  
> 相关脚本：`scripts/levels/greybox_world_region.gd`、`scripts/world/resonance_secret_gate.gd`、`scripts/world/resonance_source_clue.gd`、`scripts/core/world_state.gd`。

## 1. 本轮实现范围

新增两个场景文件，沿用统一的程序化灰盒控制器：

| 区域 | 场景 | 保存位置 ID | 用途 |
|---|---|---|---|
| A11 深层研究区 | `scenes/deep_research_depths.tscn` | `deep_research_depths` | 接收来自旧王墓或大圣堂的隐藏入口；调查 R08；通往 H08 |
| H08 胎宫 / 原初空腔 | `scenes/primordial_hollow.tscn` | `primordial_hollow` | 高门槛的深层隐藏子区；在满足剧情条件时提供额外终局出口 |

两个场景都复用 `scripts/levels/greybox_world_region.gd`，但拥有独立的 `region_id`、标题、平台布局、环境色和绘制地标。它们不是最终美术，也不代表关卡已实机通过。

## 2. A11 的两条入口

A11 有两个不同入口，必须分别保存通路状态；它们共同指向同一个“已发现区域” ID，避免把两扇入口误记为两张地图。

| 入口 | 起点 | 通路 ID | 显现条件 | 目标 |
|---|---|---|---|---|
| 王墓维护竖井 | A8 旧王墓 | `C15` | 灵视激活、鸣响 ≥ 55、古神接触度 ≥ 2，并记录 `anomaly_bell_retiming` 与 `anomaly_erased_royal_name` | A11，出生侧为西 |
| 大圣堂静默侧堂 | A10 大圣堂 | `C19` | 灵视激活、鸣响 ≥ 68、外神接触度 ≥ 12、`outer_god_resonance` 成立，并记录 `anomaly_mirror_street_echo` | A11，出生侧为东 |

入口使用同一个 `resonance_secret_gate.gd`：首次按 E 永久开启，第二次按 E 进入。新增的 `region_record_id = "A11"` 让 `C15` / `C19` 仍各自保留 opened path 状态，同时将玩家已发现和已进入的区域都记录成 A11。

### 防止跳关

- C15 仅出现在 A8；玩家必须先通过旧王墓主路线抵达其附近并完成 R06。
- C19 仅出现在 A10；正常情况下玩家已从 A9 主路抵达大圣堂，而且还需要外神共鸣事实。
- 从 A11 返回 A8 的门仅在 C15 已开启时启用。
- 从 A11 返回 A10 的门仅在 `reached_A10_via_A9` 已记录时启用。
- 两条路径不会因鸣响较高而自动开启；都需要激活灵视、靠近并主动按 E。

## 3. R08：观测者反应

A11 新增一处一次性异常调查 `anomaly_observer_reaction`：

- 地点：A11 观测室附近。
- 鸣响目标：至少 78。
- 古神接触度下限：2。
- 外神接触度增量：+6。
- 记录来源后才可满足 H08 的 R08 前置事实。

外神接触的顺序修复由 `WorldState.mark_outer_god_resonance()` 负责：若外神共鸣先发生，R08 会把接触度从 12 提到 18；若 R08 先记录，后续的外神共鸣剧情事件会直接把接触度补齐到 18。单纯进入 A9 / A11 不会自动建立外神共鸣故事事实。

## 4. H08：胎宫 / 原初空腔

H08 的入口 ID 为 `H08`，目标场景为 `scenes/primordial_hollow.tscn`。入口当前检查：

| 条件 | 要求 |
|---|---|
| 当前激活灵视 | 是 |
| 鸣响 | ≥ 78 |
| 古神接触度 | ≥ 2 |
| 外神接触度 | ≥ 18 |
| 外神共鸣故事事实 | 必须成立 |
| 之前记录的异常来源 | `anomaly_bell_retiming`、`anomaly_erased_street_sign`、`anomaly_old_stone_layer` |

场景用不规则石壁、脉动般的裂痕和偏青灰色调区分于教会实验室。玩家进入后可以通过左侧出口返回 A11。当前 H08 的视觉是灰盒占位，尚未接入最终动画、声音或专属遭遇。

## 5. 结局出口

- A12 王室内城的主线出口调用既有 `EndgameGate.route_candidate()`，依据持久剧情事实选择 `church_final_demo.tscn`、`ending_paradise_demo.tscn` 或 `ending_fire_demo.tscn`。这样普通通关不要求先探索 H08。
- H08 内的额外“最后梦境”出口只在 `WorldState.physical_union_complete` 成立时出现；它再次通过同一结局评估器决定永恒乐园或烈火天罚路线。
- A13 目前仍是世界拓扑中的终局层抽象节点，未建立一个单独的 `a13_final_anomaly.tscn` 场景。终局演出暂时复用已有结局场景。

## 6. 存档 / 继续游戏约定

`WorldState.get_resume_scene_path()` 已加入：

- `deep_research_depths` → `scenes/deep_research_depths.tscn`
- `primordial_hollow` → `scenes/primordial_hollow.tscn`
- `church_final_demo`、`ending_paradise_demo`、`ending_fire_demo` → 各自终局场景

C15 / C19 的通路开启 ID、A11 的区域发现 / 进入 ID、H08 的区域 ID 各自分开保存。旧存档缺少新增的隐藏状态字段时，WorldState 默认恢复为空集合。

## 7. 灰盒验收清单

以下项目仍需在 Godot 4.6.x 实际运行：

- [ ] 从 A8 调查 R06 后，C15 才会在灵视期间显现。
- [ ] 从 A10 调查 R07 并满足外神条件后，C19 才会显现。
- [ ] C15 与 C19 开启后分别保存自己的通路 ID，但都将 A11 记为已发现 / 已进入区域。
- [ ] 从 A11 返回 A8 的门只在 C15 已开启时启用。
- [ ] 从 A11 返回 A10 的门只在 A10 主线到达标记存在时启用。
- [ ] R08 无论在外神共鸣之前还是之后调查，最终接触度都可达到 18。
- [ ] H08 不会在缺少任意一项所需异常 ID 时显现。
- [ ] H08 死亡回程、离开 / 返回和读档后位置及已开通路保持一致。
- [ ] 未完成身体交融的玩家不会在 H08 看到“最后梦境”出口。
- [ ] A12 主线结束出口仍能按结局评估器进入对应结局，不依赖 H08。
- [ ] E 键交互焦点不会同时落在 NPC 与隐藏门上。

**当前结论：A11 / H08 的场景文件、异常来源、两条入口、保存状态和结局出口已完成代码接线；这是一项静态实现里程碑，不是引擎验收通过。**
