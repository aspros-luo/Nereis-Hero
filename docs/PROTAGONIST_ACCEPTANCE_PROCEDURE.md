# 主角系统验收流程 / Protagonist Acceptance Procedure

日期 / Date: 2026-10-09
分支 / Branch: `feature/protagonist-system`
本轮范围 / Scope: 主角能力、战斗、Debug 独立测试、状态清理与存档隔离。
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
| G | Grapple to a marked anchor in `grapple_anchors` |
| W | Climb or slide along marked `wall_climb_surfaces` |
| Space | Wall jump while touching a marked wall |
| V | Resonance Sight: 10 stamina, 4.5s duration, 6s cooldown |
| PageUp / PageDown | Select iaijutsu form while F5 is ON; press L to test |
| F3 | Global world-state Debug panel |
| F4 | Toggle Hero-local debug overlay |
| F5 | Toggle session-only all-protagonist-ability override; creates temporary anchors, hidden traces and marked walls |
| F6 | Restore HP/stamina; clear temporary ability effects/cooldowns and cancel active action/hitbox |
| F1 / F2 | Existing endgame test theaters |
| F7 / F8 | Existing Church Final Boss / 烈火天罚 theaters |
| F9 | Existing clean reset in Village Hub |
| F10 / F11 / F12 | Ancient Research / Village Defense / Mite Resonance theaters |

## 3. 验收步骤 / Acceptance steps

### A. Debug controls and input isolation
1. Press F4. Expected: Hero-local overlay toggles.
2. Press F5. Expected: temporary override toggles; no persistent ability/achievement/material/story flags are written.
3. Press F6. Expected: HP/stamina restore, Echo/Dash/Grapple/Sight state resets and the active action/hitbox cancels.
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

### C. Traversal and perception / 位移与感知
1. Turn F5 ON and press G. Expected: the Hero pulls toward a temporary grapple anchor; solid collision blocks travel; reaching or timing out ends the action.
2. Touch a temporary marked wall. Hold W to climb, release W to slide slowly, then press Space to wall-jump away. Unmarked walls must not enable this action.
3. With F5 enabled, press Space twice before landing. Expected: exactly one extra air jump; a third jump is unavailable, and landing resets the counter.
4. Press V to enable Resonance Sight. Temporary hidden traces should be visible while the ability is active, then hide when it expires.
5. Press PageUp/PageDown to select each iaijutsu form; press L and inspect HP/stamina cost, abnormal-load feedback, hit range and matching VFX. Selection and load accumulated under Debug must not be saved.
6. Trigger a precise dodge against an enemy with F5 ON. Expected: enemies slow for about 2.4 seconds while the Hero stays responsive. Receive damage, open menu and change scene to verify cleanup.

### D. Ordinary dodge regression / 普通闪避回归
1. With F5 override OFF, press K/Shift.
2. Confirm the ordinary dodge remains separate and still uses its own invulnerability frames.
3. Confirm only ordinary dodge can trigger precision-dodge riposte; Quick Dash offers no invulnerability.

### E. Weapon and special-technique regression / 武器与战技回归
1. Select Long Sword using Q and press F with F5 ON: expect one Judgment Slash hit window.
2. Switch to Short Blade and press F: expect three independent Crescent Combo hit windows.
3. Press R near enemies: expect Echo pulse, resource cost/cooldown, brief ordinary-enemy stagger and capped boss control.
4. With F5 OFF, techniques without formal unlock records remain unavailable.
5. Perform a precise K/Shift dodge. Only a hit avoided in the opening 0.075-second window should arm a one-hit 1.35x riposte.

### F. State/save/reset regression / 状态、存档和重置回归
1. Start an attack and receive damage. Expected: hitbox closes and no buffered action fires after hitstun.
2. Die/respawn. Expected: attack, dash, dodge, hitbox, combo and air-jump counters reset; formal abilities remain earned.
3. Use a rest point. Expected: HP/stamina and temporary action/cooldown state reset without duplicate unlocks.
4. Save and reload. Expected: persistent unlocks/hidden states remain; F5 override does not persist.
5. Start new game/reset and verify abilities, achievements, materials and hidden state reset.
6. Overlap Mite/door/NPC interaction ranges. Expected: only one actionable E prompt; menu controls do not trigger world interactions.

### G. Abnormal load and progression isolation / 异常负荷与成长隔离
1. With F5 ON, test the human, blood, abyssal and black-horizon forms. Expected abnormal-load gains: 0 / 10 / 18 / 28.
2. Check the stamina regeneration multiplier at effective load thresholds 20 / 40 / 65 / 85.
3. Use a rest point. Normal persisted load should decrease by 35 (minimum zero).
4. Perform a non-human Debug form, press F6, and restart the game. Expected: the session-only load, selected Debug form, override and temporary fixtures do not persist.

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


## 6. Additional regression after the 2026-10-09 Debug pass / 本轮 Debug 修正后的补充回归

1. **Witch Time / 魔女时间** — Enable F5, then dodge an enemy attack inside the first 0.075 seconds of K/Shift. Observe the enemy's actual horizontal/vertical movement, attack windup, and animation slow together while the Hero remains responsive. When the 2.4-second effect ends (or F5 is turned off), enemy movement and timers must return to normal immediately.
2. **Static grapple fixtures / 固定钩爪锚点** — Enable F5 and confirm the four labeled anchors stay at the positions where they spawned; they must not follow the Hero when walking away. G should select the nearest reachable marked anchor; G cancels a pull; no target in range should leave the Hero in place. An intervening solid must block traversal rather than teleporting through it.
3. **Bound hidden visuals / 绑定隐藏视觉节点** — For any real scene fixture, set reveal_target_path to a visual CanvasItem. The component hides it on ready, shows it only while Resonance Sight is active and conditions (or Debug override) allow it, and hides it again at expiry/cancel. The default empty path must retain current marker-only behavior.
4. **F5 / F6 lifecycle** — F5 OFF clears Witch Time and cancels an active Quick Dash; F6 restores HP/stamina and clears action/hitbox/cooldowns/sight/grapple/wall state. Restart the game and confirm temporary fixtures, selected iaijutsu form, Debug abnormal-load bonus and override are not saved.

补充说明：当前环境不能启动 Godot。上面是交付给本地的执行清单，不代表已经运行通过。
