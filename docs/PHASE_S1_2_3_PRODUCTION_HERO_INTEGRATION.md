# Phase S1.2.3 — Production Hero Visual Integration / 正式主角表现层整合

Status: **Planning + integration contract**. The A19–A22 stickman combat harness has passed user-side local acceptance. This document defines the next safe step; it does not claim that the production skeleton has already replaced the current Hero visuals.

状态：**整合计划与接口约定**。A19–A22 火柴人战斗测试场景已由用户本地验收通过。本文件定义下一阶段的安全实施边界，不代表正式角色骨骼已经替换现有表现层。

## Goal / 目标

Connect the proven skeletal-animation workflow to the production Hero while keeping the production gameplay controller and world progression authoritative.

将已验证的骨骼动画工作流接入正式 Hero，同时保持正式战斗控制器和世界进度系统为唯一权威来源。

## Repository findings / 仓库核查结果

- `scripts/player/hero.gd` is the production gameplay controller. It already owns movement, jump, 3-step attacks, weapon-specific hitboxes, stamina, dodge invulnerability, perfect-dodge/riposte, hitstun, weapon techniques, ancient-god abilities, traversal, death and respawn interactions.
- `scripts/player/hero_system.gd` owns weapon/profile/progression rules. Do not duplicate these rules in a visual controller.
- `scripts/player/hero_skeleton_controller.gd` is currently a visual-state scaffold; its `_apply_pose()` is a no-op.
- `scenes/player/hero_skeleton.tscn` is an unintegrated skeletal rig scaffold. It has no complete production animation library and is not currently the active visual of `hero.gd`.
- `scripts/player/hero_visual_controller.gd` and `hero_visual_states.gd` are also scaffolds, not a completed production adapter.
- `scenes/characters/stickman_combat_test.tscn` and its controller are the validated isolated regression harness. Keep them independent from the production player.

## Non-negotiable boundaries / 不可破坏的边界

1. Do not replace the production combat timings or resource values with prototype values by copy/paste.
2. Do not rewrite the combat state machine, hitbox/hurtbox setup, save progression, ability unlocks, or traversal to make animation work.
3. Do not remove the procedural Hero drawing until the skeleton rig has equivalent readable states and local acceptance passes.
4. The visual layer may read production state and action context, but must not own damage, stamina, invulnerability, combo advancement, or progression.
5. Keep the stickman harness runnable as a regression scene; do not change `project.godot` main scene for prototype testing.

## Incremental implementation sequence / 分步实施

### S1.2.3-A1 — State contract and adapter — initial slice committed

Implemented in the current branch:

- `Hero.get_visual_state_name()` exposes a presentation-only name for every production combat state, including run/jump/fall, weapon-specific basic attacks, dodge, quick dash, grapple, wall climb, hurt and death.
- `Hero.get_visual_context()` returns a read-only-by-convention snapshot of facing, combo step, weapon, action timing, invulnerability and hitstun timing for future visual consumers.
- `HeroVisualStates.resolve_animation()` now maps these canonical presentation states to animation names.
- These methods do not drive gameplay, change attack timing, or instantiate/replace any visual nodes. The current procedural Hero remains unchanged until a later opt-in preview passes local acceptance.

Local acceptance for this slice: run the normal combat demo and confirm movement/combat behavior is unchanged; inspect Output for parser/runtime errors. The connected session can verify source content only, not execute Godot.

### S1.2.3-A1 — Remaining work

- Define a small visual-state contract sourced from production `CombatState` and current action context.
- Map production states to presentation states: idle, run, jump/fall, long-sword attack, short-blade attack, dodge, hurt, and death.
- Carry combo step and facing as presentation metadata; never let the visual layer change them.
- Add a debug-only way to compare the resolved visual state against the controller state without changing gameplay.

Acceptance: every production combat state maps deterministically; missing visual resources fall back safely to current procedural drawing.

### S1.2.3-A2 — Skeleton pose prototype

- Build the visual skeleton using the existing `Bone2D` hierarchy.
- Implement idle/run/attack/dodge/hurt poses with explicit neutral keys/reset behavior so a previous pose cannot leak into the next.
- Distinguish long-sword commitment from short-blade speed; third combo step must have a clearly different silhouette.
- Keep the weapon and effects aligned to the facing/weapon presentation, without using visual positions as hit detection.

Acceptance: poses are readable at the actual game camera scale; no bone drift or residual pose after returning to idle.

### S1.2.3-A3 — Opt-in production preview

- Add an isolated preview scene that uses the production Hero controller and an opt-in skeletal visual layer.
- Initially keep the existing procedural renderer available as a fallback.
- Validate all production mechanics in the preview: move/jump, 3-step attack, dodge, hit reaction, stamina, weapon switch and weapon techniques.
- Compare hitbox behavior before/after visual integration; visual work must not change hit results.

Acceptance: all checklist items pass locally in Godot 4.6.1 and Output contains no parser/runtime errors.

### S1.2.3-A4 — Controlled rollout

- Enable the skeleton visual in the intended production scene only after preview acceptance.
- Keep a reversible fallback flag for at least one regression pass.
- Retain the A19–A22 stickman test scene for future combat-controller changes.

## Production combat values remain authoritative / 正式战斗参数保持权威

The stickman harness values are test values only. Production currently uses its own values in `scripts/player/hero.gd`, including `ATTACK_STAMINA_COST`, `DODGE_STAMINA_COST`, `STAMINA_REGEN_DELAY`, `STAMINA_REGEN_RATE`, `DODGE_DURATION`, and `PERFECT_DODGE_WINDOW`. Balance changes must be made deliberately in the production controller/system and verified in its own gameplay context, not inherited accidentally from the harness.

火柴人测试场景中的参数只用于原型验证。正式角色在 `scripts/player/hero.gd` 中拥有独立参数，例如攻击/闪避体力消耗、体力恢复延迟与速率、闪避时长、精准闪避窗口。平衡调整必须在正式控制器/系统中有意识地进行，并在正式游戏场景验证，不能从测试场景意外继承。

## Local validation policy / 本地验收原则

Repository reads and commits do not equal Godot runtime validation. For each integration slice, run the new preview scene and the existing combat demo in Godot 4.6.1. Report parser/runtime errors verbatim and fix them before moving to the next slice. No claim of runtime success should be made without an actual engine run.
