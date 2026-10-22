# A5 房间流式加载接入审计

分支：`feature/story-map-progression`

## 目标

将已经通过用户实机体验的 `scenes/world/world.tscn` 两房间切片，逐步接入 A5 现有的 22 房间设计；不替换或破坏世界拓扑 C04/C08/C09，不把“资源可加载”误报为“整条路线可玩”。

## 审计结论（基于当前分支代码）

### 已有能力

- `World` 常驻，玩家、Camera2D、HUD 不随房间释放。
- `RoomContainer` 只承载当前房间；切换流程包含淡出、实例化、入口定位、相机边界更新和淡入。
- `RoomData` 保存 room_id、area_id、scene_path、entry_ids 和相邻房间。
- `TransitionPoint` 支持目标房间与入口 ID；`RoomTransitionManager` 防止重复触发。
- `WorldState` 为探索记录、捷径和房间物品提供独立存档文件，避免直接改变旧战役存档结构。
- 相邻房间使用 `ResourceLoader.load_threaded_request` 预加载。

### 必须处理的集成断层

1. **两套房间资源不一致**：演示资源 `resources/rooms/a5_room_01.tres`、`a5_room_02.tres` 指向 `scenes/rooms/a5/` 下的独立演示场景；A5 正式房间合同指向 `scenes/a5_rooms/a5_r01.tscn` 至 `a5_r22.tscn`。
2. **根节点类型不一致**：演示房间根节点挂载 `RoomBase`；合同中的 A5 房间根节点挂载 `greybox_world_region.gd`，因此不能直接强制转换成 `RoomBase`。
3. **A5 子房间已有专用装配模式**：`assembly_child_mode` 会只创建房间地形，避免生成第二个 Hero/HUD；接入时必须保留该约定，不能让每个房间再次初始化整套游戏状态。
4. **合同连接尚未变成实体连接**：22 房间合同中包含主路、单向落差、捷径、电梯、隐藏支路、能力门和共鸣捷径。不能把所有边都做成无条件双向门；blocked 状态必须保留解锁条件。
5. **跨区连接必须维持现有语义**：C08 是 A5 入口，C09 是主线出口，C04 是从 A5 开启的可选捷径。房间切换层不能自行重写这些世界级连接条件。
6. **入口 ID 必须明确**：每条实体连接需要确定源端和目标端的 entry_id，并检查单向落差的返回规则；不得用“进入任意房间都从 west 出生”的临时假设替代合同。
7. **相机边界与房间坐标需统一**：旧 A5 房间的宽高来自各场景的 map_width/room_height；房间装配合同中的 screen 尺寸只是设计网格，接入前要明确实际世界坐标和边界来源。

## 接入顺序

1. 以 `tools/a5_room_assembly_contract.json` 为唯一连接数据源，生成/校验每个房间的 RoomData 索引；先校验 22 个场景都存在、ID 唯一、连接端点合法。
2. 给流式加载器增加对 A5 旧房间根节点的适配，不强行把旧根节点改成 RoomBase；进入子房间时设置 `assembly_child_mode=true`，只实例化地形。
3. 从合同生成房间入口 Marker2D 与 TransitionPoint；初期只启用 `initial_state=open` 的连接，blocked 边不创建可通行触发器。
4. 将 shortcut / elevator / hidden / ability_gate / resonance_shortcut 的解锁状态接入 WorldState；状态持久化后，回访时恢复。
5. C08/C09/C04 继续走既有跨区门与出生点合同；在 A5 房间系统验收前不替换其现有实现。
6. 添加静态验收：22/22 场景可解析、全部连接端点存在、单向边没有反向触发器、blocked 边默认不可通行、所有开放主路从 R01 可达、R20 对应 C09。
7. Godot 4.6.1 实机验证后，再将 World 场景设为主流程入口；在此之前，World 流式切片只作为独立测试场景。

## 验收标准

- 单个时刻 `RoomContainer` 下恰好只有一个当前房间。
- 切房间不重新创建 Player/HUD/Camera。
- 每条连接抵达正确 entry_id，不在门内循环触发。
- 摄像机不越过当前房间边界；宽房间与竖井房间均正常。
- 主路可从 R01 走到 R20；SC01/SC02/LIFT01 和隐藏/能力/共鸣边在解锁前不可通过，解锁后改变实际路线。
- 死亡/回访不丢失探索、捷径与已收集物品状态。
- C08、C09、C04 的世界级合同与原有方向审计保持一致。

## 当前状态

### 已完成的第一轮接入

- `scripts/world/world.gd` 不再硬编码两个演示房间；改为读取本合同引用的 `tools/a5_room_assembly_contract.json`，登记全部 22 个正式 A5 房间和 26 条内部连接。
- 实例化旧 A5 场景时，使用 `assembly_child_mode` 复用原有房间地形脚本，并避免每个房间重复创建主角/HUD。
- 根据合同连接生成房间过渡触发器；单向边只建立前向连接。
- `shortcut` 与 `elevator` 类型的锁定边新增场景内交互提示：玩家靠近后按 E 持久开启；开启后刷新连接，回访仍保留开启状态。该交互目前仅针对 SC01、SC02、LIFT01 这类快捷连接。
- 保留玩家、相机、HUD 常驻；切换时更新相机边界、记录探索状态，并对相邻房间执行线程预加载。
- 新增 `tools/validate_a5_room_streaming.py`，用于检查 22 个房间场景、连接端点、关键脚本接线与 C04/C08/C09 宏观绑定。

### 仍未完成

- 这是第一轮代码接入，尚未声称 22 个房间已经通过 Godot 解析或完整路线实机测试。
- `hidden`、`ability_gate`、`resonance_shortcut` 仍需接入各自的剧情/能力/神识条件；当前默认保持封闭。
- SC01、SC02、LIFT01 已有按 E 开启与持久化逻辑，但尚未在 Godot 中验证触发区位置、交互输入冲突及开门后的真实路线变化。
- C08 入口、C09 主线出口和 C04 可选捷径仍需把新 World 流式系统与原跨区域转场契约衔接起来。
- 各房间真实出口位置、单向落差、承托、碰撞与出生点仍需逐一在 Godot 4.6.1 中验证。

先运行 `python3 tools/validate_a5_room_streaming.py` 与 `python3 tools/validate_a5_room_assembly_contract.py`，再在 `scenes/world/world.tscn` 按 F6 走完整条 A5 主路；静态检查通过不等于实机验收通过。
