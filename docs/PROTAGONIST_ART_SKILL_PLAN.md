# 主角美术与战斗技能整合计划 / Protagonist Art & Combat Skill Integration Plan

> 工作分支 / Working branch: `feature/art-skill-integration`
> 基线 / Base: `feature/protagonist-system`
> 本文件是实施计划，不代表已完成游戏内集成或通过 Godot 运行测试。
> This is an implementation plan, not a claim of completed in-game integration or passing Godot runtime tests.

## 1. 当前基线 / Current baseline

- 主角逻辑集中在 `scripts/player/hero.gd`，当前约 1,355 行。
- 战斗判定由 `scripts/combat/hitbox.gd` 负责。
- 现有斩击视觉由 `scripts/effects/slash_arc.gd` 绘制。
- 角色规则集中在 `scripts/player/hero_system.gd`。
- 当前分支已经有基础连击、Judgment Slash、Crescent Combo、Eldritch Echo、闪避与 Quick Dash 等逻辑；新增技能必须复用这些入口，不另建互不相容的战斗系统。
- 当前仓库包含主角长剑/短刃 SVG 资源；新增视觉必须与现有黑暗奇幻美术保持一致。

## 2. 素材策略 / Asset strategy

1. 保留用户提供的原始 PNG/DDS，不直接覆盖或破坏源文件。
2. 先核验实际尺寸、透明通道、图集布局与授权/来源说明；不要假设 DDS 可直接作为 Godot 运行时纹理。
3. 将角色动作帧、刀刃/装饰部件和技能残影分开评估。只把可辨识且适合主角风格的元素纳入运行时资源。
4. 优先建立可编辑的 SVG/PNG 派生资源与 SpriteFrames/AtlasTexture 引用；明确记录原始来源、裁切区域、缩放、滤色和导出参数。
5. 不把参考骨骼图误当成可直接导入的骨骼工程。若没有 rig 元数据，先采用逐帧动画或程序化弧线；后续再决定是否需要骨骼绑定。

## 3. 实施顺序 / Implementation sequence

### P0 — 兼容性与战斗可靠性 / Compatibility and combat reliability

- 审计状态切换、攻击中断、受击/死亡时 hitbox 清理、连击窗口、技能成本与冷却。
- 统一普通攻击、武器技与特殊技能的视觉生成入口，确保表现层不负责决定伤害。
- 对同一目标的单次攻击防止重复命中；确认命中反馈不会在取消/死亡后残留。
- 保留当前 F4 调试覆盖层及 F5/F6 调试行为，不引入 Ctrl 组合快捷键。

### P1 — 技能表现 / Skill presentation

首个交付目标是“弧月连斩”视觉升级：
- 起手：短暂蓄势和武器方向提示。
- 斩击：沿 facing 与攻击阶段绘制弧线/刀光，区分长剑和短刃。
- 命中：复用现有命中火花，不把视觉碰撞当作伤害判定。
- 收招：快速淡出残影，避免高频攻击时屏幕持续堆积效果。
- 取消：受击、死亡或动作取消时停止过期效果/攻击窗口。

### P2 — 美术一致性 / Art consistency

- 统一轮廓、色值、亮度层级、残影生命周期和命中特效强度。
- 限制屏幕特效密度；强技能可更亮，但普通连击必须清晰可读。
- 将长剑与短刃的攻击弧线、范围和节奏区别化，避免只有颜色不同。
- 任何新素材先在隔离分支验证，不直接覆盖现有角色 SVG。

## 4. 正反方评审 / Pro-con review

**正方：** 复用现有 hitbox、combo 与特效脚本，能保持技能与伤害规则一致，降低重复实现；程序化弧线便于缩放、翻转和适配不同武器。

**反方：** 纯程序化特效可能显得过于干净、缺乏手绘质感；若直接将图集裁成帧，容易裁错透明边缘、帧间对齐不稳，DDS 转换也可能改变颜色/Alpha；把全部行为继续塞进大型 hero.gd 会加重耦合。

**决策：** 先以小型效果脚本和既有战斗入口交付可验证原型；图集只在布局确认后使用；新增逻辑保持窄接口，不为视觉效果重写战斗状态机。

## 5. 验证清单 / Validation checklist

- [ ] 普通连击每段只扣一次资源，命中/未命中都不会重复扣费。
- [ ] 受击、死亡、闪避和场景切换时，攻击判定能正确关闭。
- [ ] 取消的技能不会延迟命中；特效不会留在场景中无限累积。
- [ ] 长剑与短刃均有可辨识的动作节奏与视觉轮廓。
- [ ] 低体力、冷却中、连续输入、攻击空挥和同时受击场景可预测。
- [ ] F4/F5/F6 原有调试行为保持不变。
- [ ] 静态源码检查与 Godot 实机测试分开记录；未实机运行不得标记为通过。
- [ ] 中文/English 说明和素材来源台账同步更新。

## 6. 本轮边界 / Scope boundary

本轮先稳定主角与战斗表现，不扩展剧情、关卡或新武器系统。不会触发 GitHub Actions。所有变更仅提交到 `feature/art-skill-integration`，验收后再决定是否合并。
