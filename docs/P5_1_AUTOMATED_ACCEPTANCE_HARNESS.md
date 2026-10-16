# P5.1 Automated Acceptance Harness

## 目的

将 World Map Test 从人工传送与自然路线指引工具升级为可重复执行的 Godot 运行时验收入口。

Harness 不替代玩家体验测试，也不宣称通过未执行的项目。它在 Godot 4.6.1 中实际实例化正式地图场景并执行各场景的 _ready()，检查运行时生成的 Hero、出口/隐藏门、目标场景、出生侧与平台承托。

## 执行

在 Nereis-Hero 项目根目录：

~~~bash
"/Users/aspros/Downloads/Godot.app/Contents/MacOS/Godot" \
  --headless \
  --path . \
  --script res://tools/p5_1_acceptance_harness.gd
~~~

Godot 官方命令行支持 --headless、--path 与 --script；脚本可以继承 SceneTree 或 MainLoop。

## 自动检查范围

- A0–A13、OB01、H01–H08 正式场景实际加载/实例化。
- Hero 与 CollisionShape2D。
- 默认出生点是否由地面或灰盒平台承托。
- 运行时出口/隐藏门是否生成。
- 出口目标场景与拓扑目标一致。
- spawn_side 存在并能由真实灰盒 _spawn_x_for_side() / _spawn_y_for_side() 解析。
- C13 两端高位门的实际运行时高度均为地面上方 180px，并验证门下方 20px 的上层平台是否承托。
- C22 终局门的实际运行时高度与上层王座平台承托合同；静态验证器另外计算 48px Hero 碰撞包络与地面最大跳跃之间的间隙。
- 真实物理帧地面起跳探针：从 C13 A7/A8 两端及 C22 A12 的高门正下方起跳，核对实际跳跃高度、Area2D 触发/交互可用状态，并确认主角落回连续地面。
- C21 动态结局门探针：先在 A11 以“凡人之墓”候选进入，随后模拟 A11 观测者异常把候选切换为非凡人结局，验证 C21 在同一场景内即时生成，而不要求离开并重新进入。
- 目标出生点是否落在真实 floor/platform 合同上。
- H01–H08 父区入口。
- topology loops 的运行时边。
- 输出 user://p5_1_automated_acceptance_report.json。
- 全部通过返回退出码 0；存在失败返回退出码 1。

## 与 World Map Test 的分工

World Map Test 继续负责人工直接进入区域、自然探索指引、测试状态预置与正式存档保护。

Harness 负责机器执行可机械验证的运行时契约。

最终 P5.1 仍分为：

1. Python 静态验证器；
2. Godot Automated Harness；
3. 玩家自然游玩回归。

三者不能互相冒充。

## 当前不覆盖

- C11/C14/C15/C19/C21/C22 的真实键盘按键完整转场链仍未由 Harness 逐扇门自动操作；除新增 C21 候选变化探针外，方向和出生点主要按实际场景合同检查。

- 玩家按键驱动的完整跳跃路线、横向绕行、连续平台攀登与真实转场；当前物理探针直接给 Hero 施加一次最大地面起跳速度，只验证高门下方的碰撞/交互隔离。
- 自动击杀 Boss；
- 自动剧情推进；
- 正式存档写入；
- H09 临时候选区；
- P5.2 剧情设计。
