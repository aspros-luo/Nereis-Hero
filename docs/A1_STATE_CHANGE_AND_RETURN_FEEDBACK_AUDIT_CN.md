# A1 地图分支：状态变化与回访反馈差异审计

日期：2026-10-19  
分支：`feature/story-map-progression`  
范围：`village_hub.gd`、`greybox_world_region.gd`、`world_event_director.gd`、`WorldState` 与 A1 设计基线文档。

> 本文区分“源码确认的问题”“已做的安全修复”和“必须等待作者确认的剧情节点”。静态源码核对不等于 Godot 运行时验收。

## 结论摘要

A1 已补上 A2/A3 实际探索后的商人反馈、疯神职人员战败后实际回村的状态链，以及常驻村民在 A1 内状态刷新时重新计算对白的机制。尚未闭环的是没有已确认触发剧情的进度 NPC 到场节点，以及未执行的静态/运行时验收。

## 已修复：疯狂神职人员事件的回村反馈链断裂

### 发现

- A6 的疯狂神职人员战败只写入 `defeated_mad_cleric`。
- A1 崖洞入口却只检查 `returned_to_village_after_mad_cleric`。
- 此前在检查到的战败处理代码中，没有把“击败”转换为“之后实际回到 A1”的状态写入点，因此按当前链路，崖洞入口缺少可靠的解锁事实。
- 战败时还存在强制解释性弹窗，直接解释蜂群与山崖的关联。这与 A1 最新叙事约束——优先让玩家通过环境和回访发现，不由旁白替玩家解释——冲突。

### 处理

- A6 战败只记录 `defeated_mad_cleric`，移除强制解释性弹窗。
- A1 场景实际进入时，若战败事实已成立，则记录并立即保存 `returned_to_village_after_mad_cleric`。
- 崖洞仍只由 `returned_to_village_after_mad_cleric` 控制；不会在 A6 战败现场直接生成，也不改变 H09 内部内容或结局条件。
- A1 静态验证器已增加相应合同。

这实现了“战败 → 离开战斗区域 → 实际回村 → 崖洞入口出现”的状态因果。仍需实机验证完整往返、死亡 / Continue 与旧存档。

## 高优先级差异

### P1 — 区域回访反馈（源码已落地，待测试）

- A2/A3 首次进入写入 `graybox_intro_ash_forest` / `graybox_intro_forgotten_city`。
- 商人对白优先级为：空洞状态 → 实际进入 A3 → 实际进入 A2 → 村庄防卫完成 → 初始对白。它不把路线解锁当作探索事实，也不增加奖励或任务系统。
- 守门人、老婆婆、铁匠和旅行商人现在加入 `a1_baseline_npcs` 组；`refresh_progression_content()` 会根据当前 `WorldState` 重新计算这些常驻 NPC 的对白，避免只在场景创建时决定一次。
- `tools/validate_a1_village_state_contracts.py` 已加入区域回访优先级、常驻 NPC 刷新和事件持久化合同。

### P1 — 事件 / 进度 NPC manifest

`world_event_director.gd` 已有事件分发与持久化接口。当前事件定义包含酒馆声音初访；NPC manifest 已接管朝圣骑士的室内生成：只有 `pilgrim_knight_a1_arrived` 成立时才出现，`pilgrim_knight_at_tavern` 与当前室内位置共同决定唯一出场地点。

**不将“填满 manifest”当作目标本身。** 在复国军营地、朝圣骑士和教堂占用的正式剧情节点没有被确认之前，擅自新增 NPC 或状态效果会制造错误因果。因此，本轮把已确定的酒馆事件作为幂等事件合同加以保护，并把已有朝圣骑士生成条件迁入 manifest；没有增加任何状态写入点，仍需等明确剧情节点。

`refresh_progression_content()` 仍保留 director 管理 NPC 的刷新入口；基础常驻 NPC 的动态对白刷新已独立修复。朝圣骑士现在由酒馆/教堂室内的 director 按同一稳定 ID 管理，避免两份手写分支长期分裂。

### P1 — 复国军营地尚无正式剧情写入点；朝圣骑士已接入 manifest

当前显示逻辑遵守最新设计：
- `restoration_camp_established` 控制营地 POI、营火与标签；
- `pilgrim_knight_a1_arrived` 控制朝圣骑士是否出现；
- `pilgrim_knight_at_tavern` 控制酒馆 / 教堂二选一。

复国军营地标记仍没有已确认的正式剧情写入点。朝圣骑士的生成逻辑现已统一迁入 manifest，但 `pilgrim_knight_a1_arrived` 和 `pilgrim_knight_at_tavern` 仍由正式剧情决定；本轮没有擅自写入它们。它们不能通过村庄防卫胜利、进入教堂或普通对话自动产生。

### P2 — 酒馆声音事件（事件合同已补强，回访仍待运行验收）

酒馆 POI 初次交互会写入 `A1_tavern_sound_noticed`，酒馆值夜人的对白会在后续场景生成时根据此状态变化，这是已有回访反馈的正面例子。

静态验证器现在检查事件只在 `A1_tavern_sound_noticed` 尚不存在时触发、使用 `once: true`，并检查事件标记与效果均保存。仍需在 Godot 中验证首次交互 → 离开 → 回村/再进酒馆的对白变化，以及重复交互不会重复触发。静态合同不等于运行验收。

## 不应擅自自动化的状态

- `church_village_occupied`：教堂空置逻辑已正确依赖此状态，但实际何时占用必须由正式剧情决定。
- `restoration_camp_established`：复国军正式进驻的后续节点尚未确认。
- `pilgrim_knight_a1_arrived` 与 `pilgrim_knight_at_tavern`：朝圣骑士的到场时间、舞台选择及离开规则需要正式剧情因果。
- 商人与金正是否为同一人物仍未确认，不应直接合并 ID 或把金正核心剧情提前接入。

## 推荐执行顺序

1. **已完成本轮修复：** A6 战败不再强制解释；A1 实际回村时写入并保存回村状态；崖洞门按既有条件出现。
2. **已完成源码实现：** 商人回访台词读取 `graybox_intro_forgotten_city` / `graybox_intro_ash_forest`，优先回应玩家实际进入过的 A3 / A2；对应静态合同已加入验证器。未添加奖励，也不把路线解锁当作探索完成。
3. **已实现，待测试：** 常驻 NPC 对话动态刷新；静态合同覆盖守门人、老婆婆、铁匠、商人及商人 A2/A3 回访优先级。
4. **部分完成：** 朝圣骑士已由 manifest 管理；等待剧情确认后再绑定其到场状态写入点，以及复国军营地的正式进驻事件。
5. **最后实机验收：** 首次进入 A1、A6 战败后离开并回村、崖洞开启、酒馆首次 / 再访、跨 A2/A3 返回、死亡和 Continue。

## 本轮验收边界

本轮变更已提交到 `feature/story-map-progression`，但本环境尚未成功执行 Python 静态验证器，也未运行 Godot 4.6.1。提交/源码回读只证明修改已写入，不代表测试通过。剧情节点尚未确认的教堂占用、复国军营地和朝圣骑士状态保持未触发。
