# Connection Wiring Audit — Pass 1 / 地图连接接线审计（第一轮）

> Branch: `development`  
> Scope: static checker reliability and the C01–C24 wiring-audit baseline.  
> Status: source review and patch committed; full local execution and Godot runtime acceptance remain pending.

## 中文

### 本轮发现与修复

在审阅 `tools/validate_graybox_scene_wiring.py` 时，发现一个会阻断整套静态审计的执行顺序问题：拓扑检查在函数局部变量 `region_script` 赋值之前，就读取它来核对 H06 的线索 ID。Python 会因此抛出 `UnboundLocalError`，导致后续的场景路径、出生点、隐藏门和局部灵视路线检查根本无法执行。

已将共享灰盒控制器的读取移动到 `main()` 的初始化阶段，确保拓扑合同检查使用已加载的源码。修改已提交到 `development`。

### 当前审计边界

现有静态检查覆盖了主路线、关键捷径、隐藏区回程、A13 终局汇流、存档出生侧、部分高位门与平台支撑，以及局部灵视路线的 ID、门槛、提示文案和几何关系。它是源码合同检查，不会证明：

- Godot 物理帧中的跳跃可达性与碰撞结果；
- E 交互焦点是否会被邻近 NPC 或门抢占；
- 每条路线在死亡、读档和继续游戏后是否仍然可用；
- 结局切换在实机中是否正确。

本轮没有把静态修复描述为“整套检查通过”：当前执行环境未提供可直接运行的完整本地仓库，修复后的 Python 检查器仍需在仓库根目录执行确认。

### 下一步

1. 对照 C01–C24 逐条核对拓扑端点、真实出口调用、目标场景、目标出生侧、解锁标志和反向入口。
2. 优先检查跨控制器连接：C01/C02/C24（序章与村庄）、C15/C19/C21/C22（深层研究与终局层）。
3. 将静态结果和需要本地实机确认的项目分开记录，不用拓扑连通代替真实可玩性。

## English

### Finding and fix

A source review found an initialization-order defect in `tools/validate_graybox_scene_wiring.py`: the topology audit read the local variable `region_script` before it was assigned, while checking H06 clue IDs. Python would raise `UnboundLocalError`, preventing the remaining scene, spawn, hidden-gate, and local Resonance-route checks from running.

The shared graybox controller is now loaded at the start of `main()`, before topology checks use it. The fix is committed to `development`.

### Verification boundary

The checker contains source-level contracts for the main route, shortcuts, hidden-area returns, A13 convergence, save/resume spawn sides, selected elevated doors and platform support, and local Resonance-route identity, gating, prompts, and geometry. It cannot establish in-engine jump reachability, collision correctness, interaction-focus behavior, persistence after death/reload, or ending transitions.

The checker has **not** been reported as passing: a complete local checkout and executable validation environment were not available during this pass. Run it from the repository root to confirm the repaired script.

### Next pass

1. Audit every C01–C24 edge against its actual exit call, target scene, target spawn side, unlock flag, and reverse entrance.
2. Prioritize cross-controller links: C01/C02/C24 (prologue and village) and C15/C19/C21/C22 (deep research and terminal layer).
3. Keep source-level results separate from the Godot runtime acceptance checklist.
