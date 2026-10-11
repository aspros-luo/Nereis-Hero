# 主角能力独立 Debug 指南 / Protagonist Ability Debug Guide

日期 / Date: 2026-10-09  
分支 / Branch: development  
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
| T（仅 F5 开启时） | 直接触发 2.4 秒魔女时间，用于单独验证敌人减速 / Force Witch Time for 2.4 seconds to test enemy slowdown independently |

## 地图灰盒验收扩展 / Map Graybox Acceptance Extension

地图验收时运行整个项目（启动场景为 `res://scenes/boot.tscn`），不要只运行独立的 `combat_demo.tscn`。

1. 在开发分支按 **F5** 启用会话级能力覆盖，再按 **V** 激活共鸣视野。隐藏入口会临时忽略鸣响 / 接触度门槛，便于检查入口显现、交互焦点与碰撞位置。
2. 仍按正常流程 **第一次 E 开门、第二次 E 进入**。这样可以测试真实的门状态、场景切换和出生点，而不是用调试按钮直接传送。
3. F5 覆盖状态由 WorldState 在当前运行会话中保留，跨地图切换仍有效；它不写入存档，新游戏重置会清除它。
4. 第一次 E 正常开门会把永久通路状态写入存档。请使用专用测试存档，验收后清理；不要把 Debug 绕过门槛的结果记作自然门槛验收通过。
5. 关闭 F5 后，重新按正常鸣响、接触度和来源条件测试入口。只有正常条件也能显现时，才能把门槛行为记为通过。

For map acceptance, run the whole project (startup scene: `res://scenes/boot.tscn`), not only the standalone `combat_demo.tscn`.

1. Press **F5** to enable the session-only ability override, then **V** to activate Resonance Sight. Hidden gates temporarily ignore resonance/exposure thresholds so their reveal, focus, and collision can be inspected.
2. Keep the real interaction sequence: **first E opens the gate; second E enters**. This exercises gate state, scene transition, and spawn-side logic rather than teleporting directly.
3. WorldState retains the F5 override across scene changes for the current session. It is not saved, and a new-game reset clears it.
4. The first normal E interaction persists the opened-gate state. Use a dedicated test save and clean it after acceptance. Do not count a Debug-bypassed reveal as a natural threshold pass.
5. Turn F5 off and retest the normal resonance, exposure, and source requirements before marking the gate thresholds as passed.

## 分项测试 / Test cases

### 1. 跳跃与位移 / Jump and mobility

- F5 开启后，从地面跳起，在空中再次按 Space：额外空中跳应恰好生效一次；落地后计数重置。
- 连按 X：第一次冲刺需要消耗 24 体力；1.10 秒冷却内不应再次冲刺；冲刺持续约 0.16 秒，碰到实体墙应停下，且冲刺期间可以被命中。
- 正常 K / Shift 闪避仍提供自身短暂无敌；它和 X 冲刺应互不替代。

After F5, Space should allow exactly one extra jump before landing. Quick Dash costs 24 stamina, lasts 0.16 seconds, has a 1.10-second cooldown, cannot pass through solids, and does not grant invulnerability.

### 2. 精准闪避与魔女时间 / Precision dodge and Witch Time

**先独立验证减速与音效：** 开启 F5 后按 **T**。预期控制台出现 `Witch Time test triggered via T`，并听到一次约 0.62 秒的原创入场音：低频脉冲、下滑水晶泛音和渐起的气流尾音；F4 面板的“魔女”倒计时开始下降，主角周围出现紫色环，敌人的移动、攻击前摇、动画和敌方攻击命中框计时一起变慢；主角不变慢。等待约 2.4 秒，或按 F5 关闭覆盖，预期减速与画面效果恢复正常。音效应清晰但不盖住敌人攻击提示，也不应有钟表滴答。

**再验证正常玩法触发：** 靠近敌人，观察敌人起手提示，在敌方命中框即将接触主角时按 K / Shift。成功避开开头 0.075 秒精准窗口内的攻击后，预期控制台出现 `Perfect dodge! Next hit bonus armed` 和 `Witch Time active`，并启动约 2.4 秒魔女时间。只按 T 成功，不能代替这一项正常触发验收。

- 对着敌方攻击起手按 K / Shift，并在开头 0.075 秒内成功避开：应触发约 2.4 秒魔女时间，下一次真正命中的攻击获得一次 1.35 倍伤害。
- 魔女时间应同时减慢敌人的实际移动、攻击前摇计时与动画，主角自身移动不减速。
- 在精准窗口外闪避虽然仍可能无敌，但不触发魔女时间/精准反击。



### 魔女时间视觉与音效 / Witch Time Visual and Audio Feedback

魔女时间触发时会出现很短的屏幕边缘放射光线与稀疏晶体闪点，同时播放一段原创程序合成音：低频脉冲、水晶泛音下滑以及倒吸气般渐起的气流尾音。持续期间，画面边缘有轻微紫黑色压暗与细微时间环，HUD 保持清晰。音效不使用钟表滴答、不循环，也不在魔女时间持续期间每次再次触发时重复播放。

On activation, a brief radial streak and sparse crystal glints accompany an original procedural cue: a low pulse, descending crystal-like partials, and a reverse-breath swell. During Witch Time, a restrained violet-black vignette and fine temporal rings identify the state while keeping the HUD readable. The sound uses no clock ticks, does not loop, and does not replay on every re-trigger while the state is already active.

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


### 中断状态补充 / Action interruption addendum

在剧情输入锁期间，跳跃缓存、精准闪避/反击窗口与无效动作状态会被清理；暂停菜单打开时 W 不会继续触发墙攀。受击、死亡、休息与 F6 会清除墙攀标记和残留镜头反馈。上述中断路径仍须在 Godot 实机逐项复测。


### 新游戏重置 / New-game reset

在共鸣视野或魔女时间激活时按 F9 重置/重载场景。预期：WorldState 清除魔女时间剩余时间与敌方倍率、关闭共鸣视野并刷新隐藏目标显隐，同时恢复全局 hitstop 的时间倍率。Debug 覆盖仍属于 Hero 当前会话状态；重载场景后应重新开启 F5 才能使用。


### 冲刺与受击输入缓存 / Dash and damage input-buffer regression

同时按 X 与 J/G/V 应只启动冲刺；冲刺期间不得残留攻击、钩爪或共鸣视野请求并在冲刺结束后突然执行。受击时，跳跃缓存、钩爪、共鸣视野、快速冲刺和战技请求应在受击回调中立即清除。
