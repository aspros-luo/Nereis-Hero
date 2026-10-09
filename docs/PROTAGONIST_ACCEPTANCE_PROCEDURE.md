# 主角系统验收流程 / Protagonist Acceptance Procedure

日期 / Date: 2026-10-09
分支 / Branch: `feature/protagonist-system`
本轮范围 / Scope: 主角输入、快速冲刺、状态清理、调试热键和回归操作。
明确不包含 / Explicitly excluded: 新剧情、新关卡、新地图和剧情奖励分配。

## 1. 开始前 / Before you start
1. Use Godot 4.6.1 or compatible Godot 4.6.x.
2. Test branch `feature/protagonist-system`, not `main` or the older `development`.
3. Run from the Godot editor. For combat tuning, open `res://scenes/combat_demo.tscn` directly.
4. Do not run GitHub Actions.
5. The Hero-local overlay is enabled by default and exposes development values only.

使用 Godot 4.6.1 或兼容的 4.6.x；从 `feature/protagonist-system` 验收。不要触发 GitHub Actions。

## 2. 操作键位 / Controls
| Key | Action |
|---|---|
| A / D | Move |
| Space / Up | Jump |
| J / Left Mouse | Basic attack |
| K / Shift | Ordinary dodge and precision-dodge window |
| Q | Switch Long Sword / Short Blade |
| F | Weapon-bound technique |
| R | Eldritch Echo |
| L | Legacy iaijutsu prototype |
| X | Quick Dash; requires unlock or F5 override |
| F3 | Existing scene/global debug shortcut, where supported |
| F4 | Toggle Hero-local debug overlay |
| F5 | Toggle session-only special-technique / Quick Dash override |
| F6 | Restore HP/stamina; clear Echo/Dash cooldown and cancel active Hero action |
| F1 / F2 | Existing endgame test theaters |
| F7 / F8 | Existing Church Final Boss / 烈火天罚 theaters |
| F9 | Existing clean reset in Village Hub |
| F10 / F11 / F12 | Ancient Research / Village Defense / Mite Resonance theaters |

## 3. 验收步骤 / Acceptance steps

### A. Debug controls and input isolation
1. Press F4. Expected: Hero-local overlay toggles.
2. Press F5. Expected: temporary override toggles; no persistent ability/achievement/material/story flags are written.
3. Press F6. Expected: HP/stamina restore, Echo/Dash cooldowns clear and active action/hitbox cancel.
4. In the Village Hub, press F10, F11 and F12 separately. Expected: only the corresponding existing test theater opens. F4/F5/F6 must not switch scenes.
5. Open the pause/menu state and press F10-F12. Expected: no theater opens while gameplay input is locked.

### B. Quick Dash / 快速冲刺
1. Enable the F5 override while the Hero is not attacking, dodging, hurt or dead.
2. Press X while facing right and left. Expected: fast horizontal movement in facing direction and a short dash trail.
3. Test on the ground and in the air. Expected: dash begins when state permits; solid collision blocks movement through obstacles.
4. Expected initial values: 24 stamina cost, approximately 0.16 seconds of movement and 1.10-second cooldown. Dash grants no invulnerability.
5. Press X during cooldown or with insufficient stamina. Expected: no new dash and no negative stamina.
6. Disable the F5 override. Unless `quick_dash` is formally unlocked, X must not start the dash.
7. Receive damage during dash, open the menu, die/respawn and use a rest point. Expected: no stale dash state/request or delayed action remains.

### C. Ordinary dodge regression / 普通闪避回归
1. With F5 override OFF, press K/Shift.
2. Confirm the ordinary dodge remains separate and still uses its own invulnerability frames.
3. Confirm only ordinary dodge can trigger precision-dodge riposte; Quick Dash offers no invulnerability.

### D. Weapon and special-technique regression / 武器与战技回归
1. Select Long Sword using Q and press F with F5 ON: expect one Judgment Slash hit window.
2. Switch to Short Blade and press F: expect three independent Crescent Combo hit windows.
3. Press R near enemies: expect Echo pulse, resource cost/cooldown, brief ordinary-enemy stagger and capped boss control.
4. With F5 OFF, techniques without formal unlock records remain unavailable.
5. Perform a precise K/Shift dodge. Only a hit avoided in the opening 0.075-second window should arm a one-hit 1.35x riposte.

### E. State/save/reset regression / 状态、存档和重置回归
1. Start an attack and receive damage. Expected: hitbox closes and no buffered action fires after hitstun.
2. Die/respawn. Expected: attack, dash, dodge, hitbox, combo and air-jump counters reset; formal abilities remain earned.
3. Use a rest point. Expected: HP/stamina and temporary action/cooldown state reset without duplicate unlocks.
4. Save and reload. Expected: persistent unlocks/hidden states remain; F5 override does not persist.
5. Start new game/reset and verify abilities, achievements, materials and hidden state reset.
6. Overlap Mite/door/NPC interaction ranges. Expected: only one actionable E prompt; menu controls do not trigger world interactions.

## 4. 当前静态报告 / Current source-level report
- [x] Quick Dash has its own state, X input, stamina cost, cooldown, lock gate, trail, damage interruption and reset paths.
- [x] Quick Dash requires its persistent unlock record or session-only F5 override.
- [x] F4/F5/F6 require no Ctrl modifier and are consumed by the Hero.
- [x] Existing Village Hub test theaters moved to F10/F11/F12 and reject gameplay input locks.
- [ ] Godot parser and scene startup.
- [ ] Actual movement/collision/damage/resource/cooldown checks.
- [ ] Save/load/reset regression in Godot.
- [ ] Visual readability and performance capture.

**诚实结论 / Honest status:** The source can be statically reviewed, but this environment cannot launch Godot 4.6.1. Unchecked items remain pending, not passed. Record machine/Godot version, branch/commit, scene, steps, expected vs actual, debug values and logs when testing.

## 5. 验收反馈格式 / Report template
```text
Godot version:
OS:
Branch / commit:
Scene:
Test case:
Steps:
Expected:
Actual:
Debug overlay values:
Console log:
Pass / Fail / Blocked:
Screenshot or short clip:
```
