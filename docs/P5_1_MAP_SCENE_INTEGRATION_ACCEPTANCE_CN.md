# P5.1 全地图与场景集成验收记录

- 项目：Nereis-Hero
- 分支：development
- 阶段：P5.1 — 全地图与场景集成
- 验收日期：2026-10-16
- 验收口径：严格区分远程源码静态核对、验证器实际执行、Godot 实机执行。未执行的项目不得标记为通过。

## 1. P5.1 任务范围

1. 全地图入口/出口与场景切换
2. 出生点、回程出生点、死亡恢复点与 Continue 恢复位置
3. 捷径、隐藏路线与可探索区域
4. 地图边界、碰撞承托、死角与可能软锁
5. 门交互区域、出生点与相邻门/交互物的净距
6. 死亡、休整、切图、读档后的地图状态
7. 完整自然路线的运行时回归

## 2. 已取得的真实证据

### 2.1 GitHub development 分支

当前 development HEAD：

`f1d42ce32aca41b36c35e3204c2e48bb9ac4e12e`

仓库权限已确认具有 push/admin/maintain 权限。

### 2.2 地图拓扑静态核对

当前拓扑清单声明：

- 14 个正式区域：A0–A13
- 24 条跨区连接：C01–C24
- 8 个正式隐藏区：H01–H08
- 1 个临时候选区：H09（不计入正式验收）
- 11 条局部灵视路线
- 76 个子区域
- 71 条区域内连接
- 8 条升降机合同

已从 development 分支读取并核对拓扑与既有审计记录；A0–A13 的抽象最终可达性、C01–C24 的端点登记、H01–H08 的正式边界、局部灵视路线 ID 对齐均已有源码/数据证据。

### 2.3 场景库存

development 分支中存在 P5.1 正式自然流程所需的：

- A0–A13 对应正式场景
- OB01 王墓 Boss 独立场景
- H01–H08 对应隐藏场景

WorldState 的场景映射已读取并核对；自然测试覆盖表也包含 A0–A13、H01–H08、OB01 共 23 个正式验收标识。

### 2.4 恢复与交互源码

已读取并核对：

- `scripts/core/world_state.gd`
- `scripts/core/scene_transition.gd`
- `scripts/world/level_exit.gd`
- `scripts/world/route_exit.gd`
- `scripts/world/rest_point.gd`
- `scripts/world/checkpoint.gd`
- `scripts/world/interaction_door.gd`
- `scripts/world/resonance_secret_gate.gd`
- `scripts/world/resonance_local_route.gd`
- `scripts/levels/greybox_world_region.gd`

源码层面可以确认：

- Continue 使用 `WorldState.get_resume_scene_path()` 恢复场景。
- `pending_region_spawn_side` / `resume_spawn_side` 被用于跨场景出生侧恢复。
- 休整点要求 Hero 在地面承托状态后才可记录 checkpoint。
- 休整点会恢复玩家状态并保存 checkpoint。
- 地图自然测试拥有 23 个区域/遭遇覆盖目标。
- 局部灵视路线使用独立状态与交互焦点。
- 既有 P1–P4 审计已记录 C11/C13/C14/C15/C19/C21/C22 等高风险连接的空间合同。

## 3. P5.1 静态结论

### 已确认

- [x] development 分支可读且当前项目结构存在。
- [x] 正式地图/隐藏区库存与既有拓扑合同一致。
- [x] A0–A13、H01–H08、OB01 的自然测试映射已登记。
- [x] Continue 场景映射存在。
- [x] 出生侧状态存在并参与恢复流程。
- [x] 休整点不会在源码层面接受明显的空中 checkpoint。
- [x] 既有高风险连接的门、出生点、回程和条件合同已进入静态验收资料。
- [x] P1–P4 期间已修正过的门触发区域高度、C16/H05 锚点、C09/C17 高位出口等静态合同仍在当前资料中。

### 不能冒充“通过”的项目

- [ ] 在本维护环境中执行 `python3 tools/validate_world_map_topology.py`
- [ ] 在本维护环境中执行 `python3 tools/validate_spatial_route_contracts.py`
- [ ] 在本维护环境中执行 `python3 tools/validate_connection_direction_audit.py`
- [ ] 在本维护环境中执行 `python3 tools/validate_graybox_scene_wiring.py`
- [ ] 使用 Godot 4.6.1 导入项目并完成 parser/resource load 检查
- [ ] 使用 Godot 4.6.1 完成无 Debug 自然流程 A0→A13
- [ ] 实机逐条验证 C01–C24 双向/单向行为
- [ ] 实机逐一验证 H01–H08 的首次进入、回程、死亡、切图、Continue
- [ ] 实机验证死亡/休整/Continue 后出生点不会落入门触发区
- [ ] 实机验证高位门的实际碰撞承托和地面绕行风险
- [ ] 实机验证 23/23 自然测试覆盖日志

## 4. 验收阻断条件

P5.1 的最终“实机通过”定义必须同时满足：

1. 四个 Python 验证器全部实际执行并通过；
2. Godot 4.6.1 项目导入、解析和场景加载无阻断错误；
3. 新存档自然流程可以从 A0 连续推进到设计终点；
4. C01–C24 的方向、门槛、出生侧和实际碰撞承托与合同一致；
5. H01–H08 和 OB01 的进入/返回/死亡/Continue 状态正确；
6. 死亡与休整不会造成软锁、悬空出生或门触发循环；
7. 测试结果写回本报告，并保留失败项与复测证据。

## 5. 当前最终结论

**P5.1 当前不能诚实地标记为“全部完成/实机验收通过”。**

原因不是发现了新的 P5.1 阻断 Bug，而是当前维护环境只有 GitHub 远程源码读写能力，没有可执行的 Godot 4.6.1 本地运行环境，也没有执行仓库 Python 验证器的本地 checkout。因此现阶段能够形成的是**有源码证据的静态完成度**，不能把它升级为**运行时验收完成**。

已有项目文档此前已经明确同一验证边界；本报告不重复制造“通过”结论。

## 6. 下一步最小动作

要真正关闭 P5.1，只需要在拥有项目 checkout + Godot 4.6.1 的环境执行上述验证器和自然流程测试，把真实输出/日志带回项目，然后针对实际失败项修复并回归。

**P5.2 暂不启动。** 任何小地图扩张和剧情融入继续等待导演参与。
