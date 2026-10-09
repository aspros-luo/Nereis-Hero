# 主角能力独立 Debug 指南 / Protagonist Ability Debug Guide

日期 / Date: 2026-10-09  
分支 / Branch: feature/protagonist-system  
范围 / Scope: 独立测试主角能力，不添加剧情、正式地图、奖励点或存档成长。

## 快速开始 / Quick start

1. 在 Godot 4.6.x 中打开本分支项目，直接运行 res://scenes/combat_demo.tscn。
2. F3 打开/关闭屏幕右上角的世界 Debug 面板；F4 打开/关闭跟随主角的状态面板。
3. 按 **F5** 开启本次运行的全部主角能力覆盖。场景会生成临时的固定钩爪锚点、隐藏痕迹和标记攀爬墙。
4. 按 **F6** 恢复 HP / 体力，并清除临时动作、命中框、冷却、魔女时间、钩爪和共鸣视野。
5. 关闭 F5 会撤除测试设施，并清除魔女时间、Debug 异常负荷与仍在执行的快速冲刺。Debug 状态不写入成长/存档。

Open the project in Godot 4.6.x and run res://scenes/combat_demo.tscn directly. F3 toggles the screen-space world panel, F4 toggles the Hero-following panel, F5 enables session-only ability overrides and test fixtures, and F6 resets combat state/resources. No Debug unlock or selected form is persisted.

## 键位 / Controls

| 键位 / Key | 功能 / Action |
|---|---|
| A / D | 移动 / Move |
| Space / Up | 普通跳跃、二段跳；贴住标记墙时蹬墙跳 / Jump, double jump, wall jump |
| W | 贴住标记墙时攀爬；松开后缓慢下滑 / Climb or slide on a marked wall |
| J / 鼠标左键 | 普通攻击 / Basic attack |
| K / Shift | 闪避；最初 0.075 秒为精准窗口 / Dodge; first 0.075 s is the precision window |
| Q | 长剑 / 短刃切换 / Switch weapon |
| X | 快速冲刺；不带无敌帧 / Quick Dash; no invulnerability |
| G | 钩爪到最近的标记锚点；飞行中按 G 取消 / Grapple nearest marked anchor; press again to cancel |
| V | 共鸣视野：10 体力、4.5 秒、6 秒冷却 / Resonance Sight |
| F | 武器绑定战技：长剑断罪斩，短刃残月连斩 / Weapon-bound technique |
| R | 余响：范围脉冲与短暂硬直 / Eldritch Echo pulse and brief stagger |
| L | 拔刀斩形态测试 / Iaijutsu form test |
| PageUp / PageDown | F5 开启时切换拔刀斩形态 / Choose form while F5 is ON |
| F3 / F4 / F5 / F6 | 世界面板 / 主角面板 / 全能力临时覆盖 / 恢复复位 / Global panel / Hero panel / Override / Reset |

## 分项测试 / Test cases

### 1. 跳跃与位移 / Jump and mobility

- F5 开启后，从地面跳起，在空中再次按 Space：额外空中跳应恰好生效一次；落地后计数重置。
- 连按 X：第一次冲刺需要消耗 24 体力；1.10 秒冷却内不应再次冲刺；冲刺持续约 0.16 秒，碰到实体墙应停下，且冲刺期间可以被命中。
- 正常 K / Shift 闪避仍提供自身短暂无敌；它和 X 冲刺应互不替代。

After F5, Space should allow exactly one extra jump before landing. Quick Dash costs 24 stamina, lasts 0.16 seconds, has a 1.10-second cooldown, cannot pass through solids, and does not grant invulnerability.

### 2. 精准闪避与魔女时间 / Precision dodge and Witch Time

- 对着敌方攻击起手按 K / Shift，并在开头 0.075 秒内成功避开：应触发约 2.4 秒魔女时间，下一次真正命中的攻击获得一次 1.35 倍伤害。
- 魔女时间应同时减慢敌人的实际移动、攻击前摇计时与动画，主角自身移动不减速。
- 在精准窗口外闪避虽然仍可能无敌，但不触发魔女时间/精准反击。

### 3. 钩爪与攀墙 / Grapple and wall traversal

- G 连接最近的可见测试锚点；主角应沿碰撞移动前往锚点，不允许瞬移穿墙。飞行中再按 G 可取消，目标被移除或超时应正常结束。
- 走离所有锚点超过 440 像素后按 G，不应发生移动。
- 贴近绿色 Debug 标记墙，按住 W 上爬，松开 W 缓慢下滑，按 Space 蹬墙跳。普通未标记墙面不应启动攀爬。

### 4. 共鸣视野 / Resonance Sight

- V 消耗 10 体力，显示满足条件的隐藏痕迹 4.5 秒；冷却 6 秒。
- 默认可复用组件仅画出隐藏标记。若关卡节点需要一起显隐，把它的视觉 CanvasItem 路径配置到 reveal_target_path。
- F5 测试覆盖可以忽略测试对象的共鸣门槛，但不会改写 WorldState 或存档。

### 5. 武器和战技 / Weapons and techniques

- 长剑使用 3 段连击；短刃使用 4 段连击。Q 切换后分别测试 J。
- F 测长剑断罪斩、短刃残月连斩；R 测余响脉冲、敌人硬直、Boss 控制上限。
- F5 开启后，用 PageUp / PageDown 按顺序选择 human_iaijutsu、blood、abyssal、black_horizon，再按 L。
- 每种形态的配置不同：人类形态不付生命/负荷代价；血色/深渊/黑色天际依次提高伤害与范围，也分别付出 8/10/14 HP、26/30/36 体力和 10/18/28 异常负荷。以上为原型调校值。

### 6. 清理与存档隔离 / Cleanup and save isolation

- 在攻击、冲刺、钩爪、视野或魔女时间中分别按 F6；不应留下旧命中框、缓冲输入或残留时间效果。
- F5 开启时测试招式、关闭 F5，再尝试使用未正式解锁的能力；它们应恢复锁定状态。
- 重启后检查 F5 覆盖、测试锚点/墙/痕迹、所选拔刀形态和 Debug 异常负荷都没有写入存档。
- 休息点应恢复 HP / 体力并减少正式异常负荷 35 点（最低为 0）。

## 当前验证边界 / Verification boundary

源码已完成相应接线与静态修正，但本执行环境没有 Godot 运行时，尚不能确认项目解析、实际动画、碰撞与游戏手感。**请将本指南作为本地验收步骤，不要将未执行项目标记为通过。** 正式奖励点和剧情/地图布置继续留到本阶段全部能力通过验收后。
