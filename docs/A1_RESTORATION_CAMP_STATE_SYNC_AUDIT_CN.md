# A1 复国军营地状态同步审计

日期：2026-10-19  
目标分支：`feature/story-map-progression`  
设计基线：`docs/A1_VILLAGE_STORY_AND_NPC_REDESIGN_V1_CN.md`

## 结论

村庄防卫完成与复国军进入村庄是两个不同的剧情事实，不能合并成一个旗标。

- `village_defense_survived`：记录村庄防卫结果；驱动北门与旧排水通道的既有开放状态。
- `restoration_camp_established`：记录复国军在后续明确剧情节点进入并建立常驻营地。
- 初次进入 A1 以及仅完成村庄防卫后，不应自动出现复国军营地。
- 营地交互 POI、营火和标签视觉必须共用 `restoration_camp_established`，防止场景出现“看得见但不能交互”或“能交互但看不见”的状态分裂。

## 源码核对

`scripts/levels/village_hub.gd` 当前已满足上述显示门槛：

1. `_spawn_village_pois()` 仅在 `restoration_camp_established` 成立时生成 `rebel_camp` POI。
2. 营地建筑、营火与“复国军营地”标签也使用同一旗标。
3. 北门与旧排水通道仍独立使用 `village_defense_survived`，没有把营地出现绑定到防卫结果。

因此，本次不需要为了“统一状态”而将两个旗标合并；那会违反最新 A1 设计约束。

## 尚未指定的剧情写入点

目前代码中没有发现 `restoration_camp_established` 的剧情写入点。设计文档明确要求该旗标必须来自一个已确认的后续剧情节点，且不能简单以“完成村庄防卫”代替。

在该剧情节点尚未确认前，保持营地未出现是正确的安全默认值。本次不擅自新增触发事件、不推定复国军到场时机，也不补写未确认的剧情内容。待该节点在正式剧情中确定后，再把持久旗标写入对应的事件效果，并补充触发条件、重复触发与回访验收。

## 静态防回归

`tools/validate_a1_village_state_contracts.py` 已增加合同检查，要求：

- 营地 POI 使用独立的 `restoration_camp_established`；
- 营地视觉继续使用同一旗标；
- 营地生成逻辑不得改用 `village_defense_survived`。

这只是验证器源码已更新；当前会话未执行该 Python 验证器，也未在 Godot 4.6.1 中进行运行时验收。
