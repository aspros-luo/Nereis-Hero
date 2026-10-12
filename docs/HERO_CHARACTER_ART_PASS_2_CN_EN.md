# Hero 角色美术第二轮 / Hero Character Art Pass 2

**分支 / Branch:** `development`  
**实现提交 / Implementation commit:** `37094121a578645683b346ede7b0da07082fa166`

## 中文

### 本轮实际修改

本轮直接修改 `scripts/player/hero.gd` 的程序化角色绘制，没有切换到 Nereis-Lullaby，也没有调用图片生成。

- **破损分叉披风：** 在原有披风后增加两片不对称破布与缝线高光。待机时轻微摆动，移动时摆幅和频率提高。
- **头盔辨识度：** 增加小型铆钉与窄面甲反光，强化无面骑士的封闭头盔轮廓。
- **灵视／无敌反馈：** 灵视持续期间，面甲出现冷青色脉冲；无敌状态提供更克制的短暂反光。
- **武器刃口层次：** 增加随剑身方向绘制的细刃光，攻击有效帧提高亮度，第三段连击更醒目。

### 安全边界

- 只调整角色的 `_draw()` 表现层；没有更改移动、跳跃、攻击判定、伤害、碰撞体、地图出口、存档或剧情状态。
- 新增动画只依赖现有的 `animation_time`、`resonance_sight_time_remaining`、`invulnerable`、`attack_time`、`attack_windup` 与 `combo_step` 状态。
- 没有引入外部图片、插件或随机逐帧生成逻辑。

### 验收状态

- [x] 已将改动写入 `development` 分支。
- [x] 静态检查：确认新增代码使用文件原有的 Tab 缩进，且插入点位于角色绘制函数内部。
- [ ] Godot 4.6.x 实机视觉验收：当前维护环境无法启动 Godot，尚未验证实际画面、脚本解析与帧率。
- [ ] 本地重点检查：待机披风是否过于抖动；奔跑时披风是否与腿部轮廓混在一起；灵视与受击反馈是否容易区分；三段攻击刃光是否遮挡敌人。

### 下一步

优先继续 Hero 的动作表现，而不是扩张地图美术：检查三段攻击的起手／命中／收招轮廓、闪避拖影、受击闪白与死亡散裂是否在实际游戏缩放下清楚；在确认不影响读图之后，再统一敌人与 Ashen Knight 的轮廓对比。

---

## English

### Implemented

This pass directly updates the procedural character drawing in `scripts/player/hero.gd`. It does not touch Nereis-Lullaby and does not use image generation.

- Added asymmetrical torn cloak tails with subtle idle sway and stronger movement sway.
- Added small helmet rivets and a narrow visor glint to reinforce the closed, faceless knight silhouette.
- Added a restrained cold-cyan visor pulse during Resonance Sight and a subtler glint while invulnerable.
- Added a fine blade-edge glint that becomes brighter during active attack frames, with stronger emphasis on the third combo hit.

### Safety boundary

Only the visual `_draw()` layer changed. Movement, jump, hitboxes, damage, collision, map routing, save state, and narrative flags were not intentionally changed. No external art packs, plugins, or per-frame random generation were introduced.

### Verification

- [x] Committed to `development`.
- [x] Static inspection confirms Tab indentation consistent with the existing script and insertion inside the drawing function.
- [ ] Godot 4.6.x runtime and visual acceptance remain pending because the current maintenance environment cannot launch Godot.

Next, prioritize attack anticipation/impact/recovery readability, dodge afterimages, hurt flash, and death breakup before broadening environmental art.
