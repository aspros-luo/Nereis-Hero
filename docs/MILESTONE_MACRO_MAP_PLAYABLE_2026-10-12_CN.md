# 宏观地图可玩基线（回滚点）

- 日期：2026-10-12
- 分支：`milestone/macro-map-playable-2026-10-12`
- 基线来源：`development` 在创建该分支时的提交头
- 状态：用户已完成基本试玩测试，确认该版本可作为地图美术优化前的回滚基线。
- 范围：宏观地图验收入口、A0–A13 与 H01–H08 区域选择、灰盒区域连通与当前剧情/鸣响入口状态。
- 注意：这是 Git 分支回滚点，不代表所有区域出口、隐藏条件和最终剧情均已完成全面运行时验证。

## 如何回滚

在 GitHub 将工作分支切换到 `milestone/macro-map-playable-2026-10-12`，或在本地执行：

```bash
git fetch origin
git switch -c rollback/macro-map-playable-2026-10-12 origin/milestone/macro-map-playable-2026-10-12
```

后续地图美术工作继续提交到 `development`，不修改该基线分支。
