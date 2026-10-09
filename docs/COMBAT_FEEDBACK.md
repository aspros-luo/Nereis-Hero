# Combat Feedback / 战斗反馈

## English

### Witch Time
- Press **K** to dodge during a nearby enemy's visible attack telegraph.
- A well-timed dodge within 190 world units activates Witch Time once the 1.45-second trigger cooldown permits it.
- Hostile actors slow to 24% speed for about half a second. A short procedural glassy chime and a restrained violet screen tint/label confirm the trigger.
- Witch Time and ordinary hitstop share a time-scale coordinator: a hit can still create a sharper impact pause without prematurely cancelling the remaining Witch Time.
- The sound is synthesized at runtime; it adds no third-party audio asset or license dependency.

### Controls
- **A / D** or arrow keys: move.
- **Space / Up**: jump.
- **J** or left mouse button: attack.
- **K** or **Shift**: dodge.
- **F4**: toggle debug overlay.
- **F9**: reset the current run.

### Acceptance checklist
1. Wait until a Cultist, Pale Hound, or Ashen Knight begins its attack telegraph.
2. Press K close to that enemy. Confirm the violet tint, “WITCH TIME” label, and chime.
3. Confirm movement and enemy attacks slow briefly, then return to normal speed.
4. Land a hit during Witch Time. Confirm hitstop still feels sharper and does not permanently freeze time.
5. Dodge outside a telegraph or far away from enemies. Confirm it remains a normal dodge.
6. Confirm F4 toggles debug information and F9 still resets the run.

## 中文

### 魔女时间
- 在附近敌人出现明确攻击前摇时按 **K** 闪避。
- 当敌人处于攻击预警状态且距离不超过 190 个世界单位时，成功触发闪避即可进入魔女时间；两次触发之间有 1.45 秒冷却。
- 周围时间会短暂减速至正常速度的 24%，持续约半秒，并通过轻微紫色屏幕染色、“WITCH TIME”字样和短促的空灵音效提供反馈。
- 魔女时间与普通命中停顿共用时间缩放协调逻辑。魔女时间内命中敌人仍可产生更强的打击停顿，且不会提前取消剩余的魔女时间。
- 音效由运行时合成，不需要额外第三方音频素材，也没有新增素材授权依赖。

### 操作
- **A / D** 或方向键：移动。
- **Space / Up**：跳跃。
- **J** 或鼠标左键：攻击。
- **K** 或 **Shift**：闪避。
- **F4**：显示/隐藏调试面板。
- **F9**：重置当前流程。

### 验收清单
1. 等待苦修者、苍白猎犬或灰烬骑士出现攻击前摇。
2. 靠近敌人按 K，确认出现紫色染色、“WITCH TIME”字样和提示音。
3. 确认主角与敌人的动作短暂减速，随后恢复正常。
4. 在魔女时间内命中敌人，确认命中停顿更强烈，但不会导致游戏永久卡在慢速。
5. 在没有攻击前摇或距离较远时闪避，确认只执行普通闪避。
6. 确认 F4 仍能切换调试面板，F9 仍能重置流程。
