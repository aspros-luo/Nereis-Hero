# LEVEL 002 — Royal City Sewer / 第二关：王城下水道

> Status / 状态：Design specification only. Not implemented or runtime-tested. / 仅为设计稿，尚未实现或运行验收。

## Purpose / 关卡目的

This is the first exploration-focused level after the village introduction. It gives the player a fair, observable path to Blood Iaijutsu without exposing hidden resonance or exposure values.

这是村庄序章之后第一张以探索为主的关卡。玩家通过环境线索、遭遇与奖励，自然获得第一项异变武技“血色拔刀斩”；游戏不显示共鸣、接触度等隐藏数值。

## Narrative premise / 剧情前提

The Church uses the royal sewer to move contaminated research waste and bodies from an underground laboratory. The sewer was originally ordinary kingdom infrastructure, secretly repurposed for the Church's experiments. Horror comes from discovering that everyday civic systems now serve forbidden research.

教会利用王城下水道转运受污染的研究废料与地下实验室的尸体。这里原本是旧王国的基础设施，被教会悄悄改造成实验运输线。主角不会在本关得知阴谋全貌，只通过损毁的运输账册、封存标记和失控隔离舱发现物证。

## Route structure / 路线结构

1. **Drain entrance / 排水入口** — safe traversal; teach ladder and ledge reading; reveal a sealed sluice.
2. **Maintenance gallery / 维护廊道** — one basic enemy group and a clearly telegraphed hazard.
3. **Flooded junction / 积水岔道** — optional clue branch that loops back; no required ability gate.
4. **Waste-transfer station / 废料转运站** — evidence of human experimentation and a checkpoint/rest point.
5. **Containment chamber / 隔离舱** — Sewer Aberrant elite encounter with readable lunge telegraphs and enough room for both weapons.
6. **Service exit / 检修出口** — after victory, award the gland and achievement; open a shortcut to a previously seen route.

## Encounter rules / 遭遇原则

- Teach at most one new combat rule per encounter.
- Telegraph hazards before damage through animation, sound, lighting, and placement.
- Reward optional exploration with evidence or materials, not mandatory power.
- The elite tests dodge timing and weapon choice; it must not require a hidden technique.
- Keep shared Hero movement, hitboxes, damage rules, and weapon tuning unchanged in the first layout pass.

- 每场遭遇最多教授一个新规则；环境危险必须先提示再造成伤害。
- 可选支路奖励探索，不发放通关必需的数值优势。
- 精英战考验闪避时机与武器选择，不要求提前拥有隐藏战技。
- 第一轮布局不修改主角移动、命中框、伤害规则或武器参数。

## Blood Iaijutsu reward contract / 血色拔刀斩奖励条件

The existing progression expects: basic iaijutsu unlocked in the prologue; achievement sewer_aberrant_defeated; at least one aberrant_gland material; resonance at least 12; ancient exposure at least 1. The prologue residue clue can establish the minimum resonance/exposure prerequisites. The sewer encounter must explicitly write the achievement and material through existing WorldState APIs. Guard rewards against duplication on re-entry and save/load.

现有成长系统预期条件：序章已解锁普通拔刀斩；成就 sewer_aberrant_defeated 已记录；异形腺体材料至少一个；共鸣至少 12；古神接触至少 1。序章残留线索可以提供最低共鸣与接触前置。下水道遭遇必须通过现有 WorldState API 写入成就与材料，并防止重进关卡或读档重复发奖。

After victory, use a short non-numeric narrative cue and distinct audiovisual feedback. Do not show a skill-tree panel or hidden requirement list. Reuse the existing localized narrative-feedback path if available.

击败精英后使用简短、不含数值的叙事提示和独立视听反馈。不显示技能树或隐藏条件清单；优先复用现有多语言叙事提示机制。

## Checkpoint and return loop / 检查点与回路

- Death returns the Hero to the latest checkpoint.
- Follow existing boss reset conventions rather than inventing a separate rule.
- The return route should be shorter than the initial route and open a service door seen earlier.
- Do not require replaying the entire level after a reward has been earned.

- 死亡后返回最近检查点；Boss 重置遵循项目既有规则。
- 回程应短于初次探索，并打开之前见过的检修门。
- 已领取的奖励不能要求玩家重新完整通关才能保留。

## Implementation sequence / 实施顺序

1. Inspect and reuse current scene-transition, checkpoint, achievement, and material APIs.
2. Build the layout with existing placeholder visuals first.
3. Implement the Sewer Aberrant through existing combat interfaces; do not modify shared Hero combat to accommodate it.
4. Add one-time reward guards, clue, and shortcut.
5. Update save/load and regression docs.
6. Run static checks, then Godot 4.6.1 runtime tests. Do not mark runtime acceptance before actual execution.

1. 检查并复用现有场景切换、检查点、成就和材料 API。
2. 先用现有占位画面建立关卡布局。
3. 使用现有战斗接口实现下水道异形，不为单个敌人修改共享主角战斗逻辑。
4. 添加一次性奖励保护、线索和捷径。
5. 更新存档与回归文档。
6. 先静态检查，再使用 Godot 4.6.1 实测；实际运行前不得标记通过。

## Acceptance checklist / 验收清单

- [ ] Long sword can complete the level; short blade is a viable alternative.
- [ ] Optional branch returns to the main route without soft-locks.
- [ ] Checkpoint behavior follows existing save rules.
- [ ] Elite telegraphs are readable at normal gameplay zoom.
- [ ] Victory grants exactly one gland and records the achievement.
- [ ] Re-entry and save/load do not duplicate rewards.
- [ ] Blood Iaijutsu becomes available only when all current conditions are met.
- [ ] Player can infer the reward from world feedback without seeing hidden values.
- [ ] Shared movement, collision, hitboxes, and damage rules remain unchanged.
- [ ] Godot 4.6.1 parses and runs the route without script/resource errors.
- [ ] Regression covers prologue escape, village entry, weapon switching, checkpoint death loop, and reward persistence.

- [ ] 长剑可以完成关卡，短刃也有可行打法。
- [ ] 可选支路能回主路且不会软锁。
- [ ] 检查点遵循现有存档规则。
- [ ] 普通游戏缩放下可读懂精英攻击前摇。
- [ ] 胜利只发放一个腺体并记录成就。
- [ ] 重进关卡和读档不会重复发奖。
- [ ] 只有满足全部现有条件时才能理解血色拔刀斩。
- [ ] 玩家可从世界反馈理解奖励，而不查看隐藏数值。
- [ ] 主角移动、碰撞、命中框和伤害规则保持不变。
- [ ] Godot 4.6.1 无脚本或资源错误地解析并运行关卡。
- [ ] 回归覆盖序章逃脱、进入村庄、武器切换、检查点死亡循环与奖励持久化。
