# 主角系统静态检查报告 / Protagonist Static Review Report

日期 / Date: 2026-10-09
分支 / Branch: `feature/protagonist-system`

## 结论 / Summary

源码层面已接入双武器战斗差异、隐藏状态存档、第一项异变战技与 HUD 修正。**这不是运行时通过报告**：当前执行环境未安装 Godot，无法验证场景启动或实际碰撞行为。

## 静态检查 / Static checks

- [x] 所有新增的主角战斗调用均有对应的 `HeroSystem` 方法。
- [x] 命中框提供动态尺寸更新，短刃不再使用长剑的大命中框。
- [x] `WorldState` 保存、加载、重置均覆盖主角隐藏状态字段。
- [x] 古神残留觉醒会记录隐藏接触状态；旧存档进行兼容迁移。
- [x] 正式 HUD 隐藏人性标签、进度条与背景；调试面板默认关闭。
- [x] Q / L 控制提示已覆盖简体中文、繁体中文、英文、日文。
- [x] 未主动触发 GitHub Actions。

## Prologue encounter reset / 序章遭遇重置

- [x] Source fix: when the Hero dies, the three Wardens are respawned and the escape gate is disabled again.
- [x] The basic iaijutsu story reward is intentionally persistent; a death does not remove an already-earned ability.
- [ ] Godot runtime regression: defeat all three Wardens, verify the gate opens; die before exiting, verify the gate closes and Wardens return; defeat them again and verify the gate reopens without duplicate unlock effects.

This check was added after finding that the gate's enabled state could remain open while the encounter reset.

## Altered Iaijutsu progression / 异变拔刀战技进展

- [x] Source code now checks Blood → Abyssal → Black Horizon in order, preventing later forms from skipping earlier understanding.
- [x] L selects the highest form already understood; each form has a distinct initial damage multiplier, cost, reach, hitbox, hit duration, windup, and visual treatment.
- [x] Technique discovery messages are queued so multiple unlocks do not overwrite each other in the same frame.
- [x] The three forms retain hidden-state conditions; story triggers remain unchanged. Abnormal-load stamina-regeneration penalties now have explicit thresholds and recovery behavior; Debug accumulation stays session-only.
- [ ] Verify in Godot that each form unlocks only after its conditions are met and that the discovery messages play in order.
- [ ] Verify hitbox placement, damage, health/stamina costs, visual readability, and attack interruption for all three forms.
- [ ] Trace normal story events to confirm whether outer exposure and humanity conditions are reachable in a standard playthrough.

The new combat values are initial tuning values only. Static source inspection does not establish that they are balanced or that the project parses successfully in Godot.

### Narrative trigger trace / 剧情触发链核查

- [x] The prologue surgical-tray clue calls `WorldState.mark_ancient_residue_awakened()`, which establishes the minimum ancient exposure and resonance for Blood Iaijutsu.
- [x] The Mite House aftermath calls `mark_physical_union_complete()`, `mark_ancient_residue_awakened()`, and `mark_outer_god_resonance()`.
- [ ] The current `mark_outer_god_resonance()` implementation records the narrative fact but does not itself increase `outer_exposure` or raise `hero_resonance` to the Abyssal threshold.
- [ ] Trace every normal-story write to `outer_exposure` and `hero_resonance` before changing values or adding progression triggers.
- [ ] Director input is required before deciding which later story beat should deepen Outer-God exposure enough to unlock Abyssal Iaijutsu and Black Horizon. Do not attach those gains to a new scene or interaction without approval.

This is intentionally a story/level design gate, not permission to invent a new relationship beat or hidden progression reward.


## Layered progression foundation / 分层成长基础

- [x] Save data now supports ability unlock records with source type and source ID.
- [x] Save data now supports idempotent achievement flags and a material inventory with safe spend checks.
- [x] Basic iaijutsu has a distinct combat profile with no HP cost and no abnormal-load increase.
- [x] The prologue's final Warden encounter grants basic iaijutsu as the first story reward; legacy completed-prologue saves are migrated.
- [x] Basic iaijutsu appears in the character/technique details in all four supported languages.
- [x] Added `double_jump` and `quick_dash` to the persistent ability registry alongside Witch Time, grapple and wall climb.\n- [x] Implemented one additional mid-air jump when `double_jump` is unlocked; the ability remains locked by default.
- [x] Blood Iaijutsu now requires the basic form plus the planned sewer-aberrant achievement and aberrant-gland material, preventing an early mutation from hidden values alone.
- [ ] Implement the Royal City Sewer encounter, achievement/material reward calls and the associated narrative/art clues; Blood Iaijutsu is intentionally unavailable until that content exists.
- [ ] In Godot, test double jump only works after the unlock record, allows exactly one extra air jump, and resets after landing/death/rest.\n- [ ] Source implementation now exists for Quick Dash, Witch Time, Grapple, Wall Climb/Wall Jump and Resonance Sight, including session-only Debug fixtures; normal story reward placement remains deferred.\n- [ ] Godot runtime test all movement/perception abilities, including enemy time dilation, collision, cancellation and menu/death/scene cleanup.
- [ ] Verify old-save migration, save/load persistence and new-game reset for ability records, achievements and materials.

## 尚未验证 / Not yet verified

- [ ] Godot 4.6.1 脚本解析、场景启动与资源加载。
- [ ] 实际碰撞范围、连击窗口、体力数值与敌人受击反馈。
- [ ] 血色拔刀斩的实际命中、代价、隐藏负荷写入与存档恢复。
- [ ] 既有剧情场景、NPC 交互、Boss 与死亡重生回归。

## 风险与后续 / Risks and follow-up

1. 异常负荷现在会分段降低体力恢复；阈值/惩罚强度仍需在 Godot 实机调校，且不应进一步引入未经设计的即时伤害或剧情惩罚。
2. 武器平衡目前按距离、连击节奏与单套输出做了初始配置，仍需通过实战打桩和敌人测试调整。
3. 代码静态检查不能替代 Godot 运行测试。合并前必须执行 `docs/HERO_SYSTEM.md` 中的验收清单。


## 菜单与战斗状态回归 / Menu and combat-state regression

- [x] 菜单打开时不再设置 `SceneTree.paused = true`；只设置运行时输入锁，世界继续模拟。
- [x] 菜单打开时屏蔽新输入与移动输入，但既有攻击窗口、敌人行动和计时器继续推进。
- [x] 菜单提供当前武器与已理解战技摘要；隐藏成长数值仍不显示。
- [x] Hitbox 增加显式 deactivate 方法，供受击、死亡、恢复等状态转换取消命中窗口。
- [ ] 在 Godot 4.6.1 实测打开菜单时被敌人命中、Boss 继续攻击、体力恢复计时、ESC 关闭菜单与输入不穿透。
- [ ] 实测受击打断攻击、死亡复位、休息点完全恢复不会遗留旧攻击窗口。

> 仍然是静态修改记录，未执行 Godot 运行时测试；不得把未勾选项目视为通过。


## Technique discovery feedback / 战技理解反馈

- [x] `HeroSystem` emits a signal when a new technique is learned successfully.
- [x] HUD listens for the signal and shows a brief narrative cue for the three defined altered techniques.
- [x] Cue text is localized in all four supported languages and does not expose hidden numerical conditions.
- [ ] In Godot, trigger ancient-residue awakening and verify the cue appears once when Blood Iaijutsu is first learned.
- [ ] Verify loading a save with an already learned technique does not replay the discovery cue.


## Interaction focus and menu input isolation / 交互焦点与菜单输入隔离

- [x] Shared interaction focus rejects targets while the menu input lock is active.
- [x] Clue prompt appears only when the clue is the focused interaction target.
- [x] Character details now include Black Horizon and its localized name.
- [ ] In the village, overlap the interaction ranges of Mite, the house door, and an NPC; confirm only one actionable E prompt appears.
- [ ] Open the menu and press E; confirm no NPC, door, clue, or rest-point interaction fires. Close the menu and confirm interaction resumes.
- [ ] With Black Horizon learned, open character details and verify the name is displayed without exposing hidden values.

Source-level checks only; Godot runtime regression remains pending.


## Story reward and mutation gate / 剧情奖励与异变门槛

- [x] Defeating all three prologue Wardens unlocks `iaijutsu_basic` with source `story:prologue_warden_clear`.
- [x] The narrative reward frames it as recovered knightly muscle memory, not an occult power.
- [x] Completed-prologue legacy saves receive a migration record for the basic move.
- [x] Blood Iaijutsu's gate now checks basic iaijutsu, hidden resonance/exposure, `sewer_aberrant_defeated`, and at least one `aberrant_gland`.
- [ ] Verify the unlock appears exactly once, L is enabled afterward, and death/re-entry cannot duplicate or remove the unlock.
- [ ] Add and verify the future sewer quest's achievement/material award calls when that level is implemented.
- [ ] The subtle tentacle-like icon evolution is a documented art rule only; a dedicated skill icon system does not yet exist.

Source-level checks do not replace Godot 4.6.1 parser and runtime tests.


## Movement ability foundation / 移动能力基础

- [x] Ordinary jump and coyote-time jump remain available without progression flags.
- [x] Double jump checks the persistent `double_jump` ability record and allows one additional air jump only.
- [x] Air-jump count resets on landing, death respawn and full restoration.
- [ ] Godot runtime test: locked state cannot double-jump; unlocked state allows exactly one extra jump; landing resets it.
- [ ] Quick Dash has its own X input, state and no-invulnerability rule; ordinary K/Shift dodge remains separate.\n- [ ] Verify in Godot that Quick Dash cannot cross solids and remains independent of ordinary dodge.


## Debug acceptance overlay / 验收调试覆盖层

- [x] The Hero-local overlay is enabled by default and toggled with F4; the former Ctrl requirement has been removed.
- [x] F5 toggles all protagonist ability/technique overrides for this run and spawns temporary test fixtures; F6 restores HP/stamina and clears temporary movement/sight/time effects, cooldowns and current hitbox.
- [x] F4/F5/F6 are consumed by the Hero input layer. Existing Village Hub test theaters moved to F10/F11/F12 to prevent shortcut collisions.
- [x] F5 override remains on the Hero instance only; the code path does not grant persistent ability records or call a save method.
- [x] Quick Dash has a separate X input, state, stamina cost, cooldown, visual trail, unlock gate, damage interruption and reset paths for input lock, menu, death/rest and debug refill.
- [x] The extra `queue_redraw()` in `_process` remains removed; the physics update path requests redraws.
- [ ] Godot runtime: verify overlay readability, shortcut consumption, Quick Dash motion/collision, cooldown/resource values, override isolation and progression with override disabled.

**Status:** source-level assertions only; no Godot runtime test was performed in this environment.

## Precision dodge / 精准闪避反击

- [x] Source implementation: ordinary dodge has a 0.075-second precision window at its start.
- [x] A hit avoided inside that window arms a one-use 1.35x damage bonus for the next confirmed basic attack or weapon-bound technique hit.
- [x] The bonus is consumed by the first hit window and cleared by confirmed damage, death reset, and full restoration.
- [ ] Godot runtime: test attacks arriving inside/outside the precision window; verify ordinary invulnerability does not arm the bonus.
- [ ] Godot runtime: verify the bonus applies once to long sword, short blade, Judgment Slash, and Crescent Combo; confirm no save persistence.

**Status:** source implementation committed; Godot parser/runtime verification remains pending. No GitHub Actions were triggered.


## Quick Dash prototype / 快速冲刺原型 — 2026-10-09

- [x] Locked unless the persistent `quick_dash` ability record or session-only override is active.
- [x] Distinct `QUICK_DASH` state and X input; ordinary dodge remains K / Shift.
- [x] Uses 24 stamina, a 0.16-second movement window and a 1.10-second cooldown; it grants no invulnerability frames.
- [x] Damage interrupts dash; input-lock, menu, death/reset, rest and F6 clear active dash/request; death/rest/F6 also clear its cooldown.
- [x] Clears buffered attacks/techniques/jump input at dash start so they cannot fire unexpectedly afterward.
- [x] F4 overlay, F5 temporary override and F6 resource reset require no Ctrl modifier; theater shortcuts moved to F10/F11/F12.
- [ ] Godot 4.6.1 parser/startup, real movement/collision and frame-timing checks.
- [ ] Test left/right facing, ground/air, collision boundaries, insufficient stamina, cooldown, damage interruption, menu, death/rest and override ON/OFF.
- [ ] Confirm no double shortcut handling in the Village Hub and no save-state mutation.
  
**Runtime status: NOT RUN.** Static source checks only. No GitHub Actions workflow was triggered.


## Debug-first ability delivery / 先完成能力、后安排剧情地图

- [x] Temporary debug anchors, hidden traces and climbing surfaces can be enabled by F5 without adding authored map content.
- [x] Witch Time is implemented as enemy-specific delta scaling; Hero motion remains on normal delta.
- [x] Grapple supports G toggle/cancel, range, max duration, target-reached and target-lost termination.
- [x] Wall climb/slide/jump only responds to explicitly marked wall surfaces.
- [x] Resonance Sight reveals hidden-target components while active and when thresholds are met (F5 can force-reveal debug fixtures).
- [x] PageUp/PageDown selects one of four iaijutsu profiles for the current session while F5 is enabled.
- [x] Session-only iaijutsu abnormal load is never written to WorldState or save files.
- [ ] Godot parser/project startup test.
- [ ] Runtime movement/collision, enemy timing, hitbox, VFX and input-lock regression.
- [ ] Save/load and new-game isolation regression for Debug override and temporary fixtures.

**Status:** source implementation only. Do not accept the protagonist feature set until Godot 4.6.x runtime checks are completed.
