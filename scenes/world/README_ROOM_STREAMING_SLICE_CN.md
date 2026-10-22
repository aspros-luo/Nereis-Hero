# 房间流式加载最小切片（A5）

本切片是新架构的独立验证入口，不替换项目现有启动场景。

## 运行方式

1. 使用 Godot 4.6.1 打开项目。
2. 在文件系统中打开 `res://scenes/world/world.tscn`。
3. 按 **F6（运行当前场景）**。
4. 使用现有主角控制方式移动到房间右侧边缘进入第二个房间，再向左返回。

## 本切片包含

- 常驻 `World`、`Player`、`Camera2D`、HUD、`RoomContainer`、过渡管理器和淡入淡出层。
- 两个独立房间场景：`A5-R01`、`A5-R02`。
- 每个房间有 RoomBounds、west/east Marker2D 入口与 Area2D 过渡点。
- `RoomData` Resource 注册房间场景路径与相邻房间。
- 相邻房间使用 `ResourceLoader.load_threaded_request` 预加载。
- `WorldState` 中的探索、捷径、拾取状态保存到独立 `user://room_world_state.json`，不改写旧主线存档结构。

## 验收清单

- [ ] World 启动后只存在一个 Player、Camera2D 和 HUD。
- [ ] 从 A5-R01 向右进入 A5-R02，角色出现在 west 入口。
- [ ] 从 A5-R02 向左返回 A5-R01，角色出现在 east 入口。
- [ ] 每次切换都有淡出、旧房间释放、新房间加载与淡入。
- [ ] 相机边界随房间变化。
- [ ] 运行期间检查 Remote 树：Player/HUD/Camera 不在 RoomContainer 下，只有当前房间在 RoomContainer 下。
- [ ] 重启后 `WorldState.is_room_explored("A5-R01")` 与 `WorldState.is_room_explored("A5-R02")` 保留探索记录。

## 范围说明

这是两个房间的一条双向连接切片；尚未接入完整 A0–A13、C01–C24 拓扑，也没有迁移旧的 A5 地图。运行验证通过后再抽象 JSON 连接注册和全图 RoomData。
