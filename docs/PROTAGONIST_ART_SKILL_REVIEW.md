# 主角美术与战斗表现审查 / Protagonist Art & Combat Presentation Review

## 本轮已完成 / Completed in this iteration

- 已确认仓库 `aspros-luo/Nereis-Hero` 的连接权限为 admin/push/pull。
- 已创建隔离分支 `feature/art-skill-integration`，基于 `feature/protagonist-system`。
- 已新增 `docs/PROTAGONIST_ART_SKILL_PLAN.md`。
- 已增强 `scripts/effects/slash_arc.gd`：淡出使用平滑缓动；普通斩击增加柔和底光、清晰核心线和少量定向碎光；保留原有特殊技 SVG 纹理与战斗脚本调用签名。
- 已确认技能纹理资源存在：`judgment_slash.svg`、`crescent_1.svg`、`crescent_2.svg`、`crescent_3.svg`，以及主角长剑/短刃 SVG。

## 正方评审 / Pro review

- 继续复用既有 `slash_arc.gd` 与 `setup_combat_technique()`，不重复造技能管线。
- 特效层只负责呈现，不决定伤害、资源消耗或敌人受击。
- 碎光采用确定性几何绘制，没有新增逐帧节点或随机粒子，避免引入额外生命周期管理。

## 反方评审 / Con review

- 新的多层绘制会增加每个特效的 draw calls；目前每个效果只绘制少量曲线与线段，仍需在大量敌人/特效场景下做帧率观察。
- 平滑淡出与碎光的视觉质感尚未经过 Godot 实机观察；不同背景亮度可能影响对比度。
- 用户上传的 PNG/DDS/动作参考图目前尚未作为二进制资源提交到本仓库。本轮没有假称已导入这些文件；后续必须先核验原图布局、透明通道和许可/来源，再生成派生资产。

## 当前验证状态 / Validation status

- [x] GitHub 仓库与写权限确认
- [x] 工作分支创建
- [x] 修改现有斩击表现脚本
- [x] 核对已有技能 SVG 路径可读取
- [ ] Godot 4.6.x 脚本解析 / headless import
- [ ] 本地实机观察长剑、短刃、Judgment Slash 与三段 Crescent Combo
- [ ] 高密度战斗帧率观察
- [ ] 对用户提供的 PNG/DDS 完成实际裁切、导入和来源记录

当前执行环境无法启动 Godot，因此未完成项不能标记为通过。

## 下一轮 / Next iteration

1. 静态审计 `hero.gd` 的攻击窗口、受击取消、死亡清理和资源扣除。
2. 检查技能纹理在不同 facing 下的变换、定位与长宽比。
3. 如能读取到用户原始图集的真实二进制文件，制作单独的派生资源，不覆盖现有 SVG。
4. 完成静态审查后，整理最小实机验收清单；不触发 GitHub Actions。
