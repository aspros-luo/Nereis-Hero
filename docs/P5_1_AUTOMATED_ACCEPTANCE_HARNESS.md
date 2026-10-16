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

- 玩家真实跳跃/移动路径；
- 自动击杀 Boss；
- 自动剧情推进；
- 正式存档写入；
- H09 临时候选区；
- P5.2 剧情设计。
