# 主角能力系统合并记录 / Protagonist Ability Integration Record

日期：2026-10-10

## 目标 / Goal

将 `feature/protagonist-system` 中主角能力开发阶段的玩法代码移植到日常开发分支 `development`，不合并整条分支，不引入角色骨骼绑定和角色美术重构。

Source checkpoint: `5de1ab24601e1e38c8be44a936232539804d58d5`.

## 移植内容 / Integrated gameplay

- 双武器差异：长剑三段连击、短刃四段连击。
- 基础拔刀术与逐步理解的异变拔刀形态。
- 二段跳、快速冲刺、精准闪避与魔女时间。
- 钩爪、标记墙攀爬 / 蹬墙跳、限时共鸣视野。
- 断罪斩、残月连斩、余响脉冲与敌人硬直。
- 主角隐藏成长状态、能力解锁、战技理解、材料 / 成就与存档字段。
- 敌人时间缩放和能力调试入口。
- 能力相关中英文 / 多语言文案、调试指南与验收清单。

## 美术边界 / Art boundary

- 主角、苦修者和灰烬骑士的绘制函数保留 `development` 当前的程序化简化表现。
- 不合并 `Skeleton2D` / `Bone2D` 角色骨骼绑定，不合并分层角色 SVG。
- 只加入招式 / 共鸣效果所需的轻量 VFX 资源；它们服务于技能辨识，不代表恢复角色美术重构计划。

## 验证状态 / Verification status

- 已通过 GitHub 源码与依赖路径检查，确认移植代码不再引用 `assets/art/characters` 角色资源。
- 未在当前执行环境运行 Godot；GDScript 解析、场景启动、碰撞、存档往返、死亡 / 休息清理、性能和实际手感均仍需本地 Godot 4.6.x 验收。
- 本次不新增、不主动触发 GitHub Actions。
- 验收入口与键位见 `PROTAGONIST_ABILITY_DEBUG_GUIDE.md`。

## Recommended local acceptance

1. Run `res://scenes/combat_demo.tscn`.
2. Use F3 / F4 for diagnostics, F5 for session-only ability overrides, and F6 to clear transient combat state.
3. Test double jump, X dash, precision dodge / T Witch Time, G grapple, W wall climb, V Resonance Sight, Q weapon switching, F weapon technique, R Eldritch Echo, and L iaijutsu.
4. Verify enemies slow down during Witch Time while Hero remains responsive.
5. Verify the game opens without missing-resource or parse errors; then test death, rest, scene transition, save/load, and new-game reset.
