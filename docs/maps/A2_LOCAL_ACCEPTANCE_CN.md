# A2 本地实机验收清单

分支：`feature/story-map-progression`

## 本轮改动

- A2 由六个可编辑房间场景组成，场景仍由 `ash_forest.tscn` 作为区域入口装配，不需要单独打开六个场景。
- 地图宽度为 3600；东侧主路出口位于 x=3400，最东侧实体平台到 x=3480。
- 三段地面碰撞分别是 x=0–860、1060–2420、2660–3600；钟墓坑口和东侧沟壑保持真实断口。
- 钟墓坑底增加了可见的石质落脚台。
- 启动后会打印六个房间的实体平台数量与地图边界校验结果。

## 拉取与启动

在项目仓库执行：

```bash
git switch feature/story-map-progression
git pull origin feature/story-map-progression
```

然后用 Godot 4.6.1 打开项目，按 F6 不要单独运行房间场景；请按 **F5 运行项目主场景**，从正常的继续游戏流程进入 A2。

## 预期日志

应该能看到每个房间的数量：

- `A2R01ForestCrossroads platforms=12`
- `A2R02CanopyBridge platforms=7`
- `A2R03BellTombGallery platforms=9`
- `A2R04FloodedCrypt platforms=6`
- `A2R05OldPilgrimHighroad platforms=13`
- `A2R06EasternRavine platforms=24`

汇总行应为：

```text
[NEREIS][A2][VERIFY] PASS rooms=6/6 platforms=71/71 right_edge=3480.0 map_width=3600.0 ground_spans=3
```

如果出现 `[NEREIS][A2][VERIFY][FAIL]`，或汇总行没有出现，请先保留完整的启动日志，不要继续走地图。

## 实机路线检查

1. **西侧入口与林间阶梯**：从出生点向右，确认平台有可见的石面、碰撞和连续的上升/下降路线。
2. **树冠高路**：沿高处平台探索，确认镜头可向东跟随主角，最东端不被屏幕或边界截断。
3. **钟墓坑口**：在 x≈860–1060 的地面断口处下落，确认不会穿过坑底石台；尝试通过两侧石沿返回上层。
4. **旧朝圣高路**：检查 x≈1585–2300 的上下两层平台，确认落差可以通过跳跃与下落切换。
5. **东侧沟壑**：在 x≈2420–2660 确认地表确实中断；检查高路与下层石沿，并确认可以回到主路。
6. **跨区出口**：确认最东侧树冠出口可见、可互动；返回村庄的西侧出口仍然可用。

## 当前验收边界

这份检查表和运行时校验用于准备本地验收，不代表已经在开发者机器上运行过 Godot。通过汇总日志只说明六个房间和主要边界成功装配；可玩性、碰撞手感、镜头与跨区转场仍需在本地实机确认。
