# Testing

## Current Development Acceptance

The project has moved beyond the original Core Combat Demo into the first narrative production pass.

### Default startup

`res://scenes/boot.tscn`

The intended playable flow is now:

**Church surgical ward → escape → village → first Mite interactions → Church / village investigation**

### Development branch

`development`

Do not run or add GitHub Actions for this project.

---

## Fresh-run acceptance

Press **F9** at any time to clear the save and return to the Church escape prologue.

### A. Church Escape

Expected:

- Hero begins in the surgical ward.
- Three Experiment Wardens block the road.
- Hero can move, jump, attack and dodge using the existing combat controls.
- The surgical tray can be examined.
- Examining it records the hidden ancient-god residue clue.
- After all three Wardens are defeated, the road opens.
- Exiting the ward records prologue completion.

### B. Village Opening

After the exit sequence:

- Player enters the Village Hub.
- Mite is present near the small recovery house.
- Mite should appear as an ordinary young woman, not a supernatural boss or obvious villain.
- The first interaction is optional.
- Interactions progress through ordinary companionship rather than an exposed romance meter.

Mite interaction order:

1. First meeting
2. Warm meal
3. Stay a while
4. Return
5. Quiet repeat

The internal state is stored as interaction facts.

### C. Rushed progression / missed connection

If the player enters the Church before reaching the **Stay a while** Mite interaction:

- `WorldState.mite_connection_missed` becomes true.
- Returning to the village no longer produces Mite herself.
- The player instead sees an **empty chair** with a warm cup.

This is deliberately quiet. There is no "romance failed" notification.

### D. Hidden evidence

The following existing clues now contribute hidden resistance evidence:

- ancient research ward
- graveyard bell / gravestone story
- restoration order
- route memory echo

The UI does not present these as "true ending items".

The debug HUD shows the internal artifact count.

### E. Director test scenes

From the Village Hub:

- **F1** → Candidate-driven endgame theater
- **F2** → Eternal Paradise Theater
- **F10** → Ancient Research Ward
- **F11** → Village Defense Theater
- **F12** → Mite Resonance Theater
- **F7** → Church Final Boss Theater
- **F8** → 烈火天罚 / Ending Fire Theater
- **F9** → clean reset to the opening prologue

The test theaters do not require normal story progression.

### F1 — Candidate-driven Endgame Theater

Reads the current hidden state through the ending evaluator:

- no physical union → Church / political ending theater
- physical union without hidden resistance → Eternal Paradise
- physical union with hidden resistance → 烈火天罚

This is a development shortcut. The final game will reach the evaluator through normal progression.

### F6 — Mite Resonance Theater

Tests the relationship-to-resonance turning point in isolation:

- relationship already established
- physical union state
- ancient-god residue awakened
- Outer-God resonance
- corrupted lullaby
- first behavioral drift in Mite

### F7 — Church Final Boss Theater

Sequence:

**High Priest human phase → High Priest ancient-god phase → King**

The King uses a different combat rhythm from the High Priest.

The scene is a combat prototype and not yet the final canonical level.

### F8 — 烈火天罚 Theater

Sequence:

**100 cultists → Mite → waiting / self-sacrifice → city detonation**

The 100-cultist segment is a spectacle.

The Mite segment is the important emotional scene:

- no conventional boss loop
- effectively one decisive action from death
- player may wait
- after approximately 60 seconds, Mite moves toward Hero's weapon
- her death begins the detonation sequence

### F3 / F4 Debug panels / 调试面板

- **F3** toggles the global world-state Debug panel.
- **F4** toggles the Hero-local overlay that follows the protagonist.
- **F5** enables session-only all-protagonist-ability and technique overrides.
- **F6** restores HP/stamina and clears temporary actions/effects.

The global panel exposes internal development state including:

- Hero memory
- humanity
- Mite interaction count
- Mite connection missed flag
- ancient-god residue
- Outer-God resonance
- physical union
- hidden artifact count
- current ending state
- current location

---

## Protagonist debug acceptance / 主角调试验收

On the current `feature/protagonist-system` branch, the Hero-local debug overlay is enabled by default. It follows the Hero and shows current HP/stamina, weapon, combat state/action, combo index, invulnerability, special-technique cooldown, hidden resonance/exposure/humanity/abnormal-load values, and extra-air-jump count. Hidden values are shown only in this debug overlay, not the normal HUD.

- **F4**: toggle the Hero-local debug overlay.
- **F5**: toggle the session-only all-protagonist-ability / technique override. It creates temporary grapple anchors, hidden traces and marked climbing walls; it is not saved and does not grant story progression.
- **F6**: refill Hero HP/stamina, clear temporary ability effects/cooldowns and cancel the current Hero action/hitbox. This is session-only.
- **Space twice before landing** with F5 enabled: test the extra air jump. Exactly one additional jump should be available; landing resets the counter.
- **X**: attempt Quick Dash. It requires the saved `quick_dash` ability record, unless the temporary F5 override is enabled.
- **G**: grapple to a temporary/test anchor; press G again to cancel.
- **W**: climb a marked wall; releasing W slides down slowly. Press Space against a marked wall to wall-jump.
- **V**: Resonance Sight, 10 stamina / 4.5 seconds / 6-second cooldown; reveals eligible hidden-target components.
- **PageUp / PageDown** while F5 is enabled: select Human / Blood / Abyssal / Black Horizon iaijutsu; press L to test the selected form.
- A precise dodge (K/Shift) starts Witch Time while unlocked or F5 is enabled; enemies slow for about 2.4 seconds while Hero control remains responsive.
- Debug form abnormal load accumulates only in memory; turning F5 off or pressing F6 clears it without writing progression to the save.
- F4/F5/F6 are consumed by the Hero input layer. The existing Ancient Research / Village Defense / Mite Resonance test theaters now use F10/F11/F12.

Use the overlay to report the exact combat state and resource values when an issue occurs. The override is only a test convenience; acceptance must also be repeated with it disabled.

主角调试覆盖层在当前开发分支默认开启，跟随主角显示生命/体力、武器、战斗状态与动作、连击段数、无敌状态、战技冷却、隐藏共鸣/接触/人性/异常负荷，以及额外空中跳跃次数。隐藏数值只在调试覆盖层中显示，不进入正式 HUD。

- **F4**：显示/隐藏主角本地调试覆盖层。
- **F5**：切换本次运行有效的全部主角能力/战技覆盖，并生成临时锚点、隐藏痕迹与攀爬墙；不写入能力解锁或剧情进度。
- **F6**：恢复主角生命/体力、清除临时能力效果与冷却，并取消当前动作和命中框，仅影响当前运行。
- **X**：尝试快速冲刺；需要正式的 `quick_dash` 解锁记录，或在本次运行中打开 F5 覆盖。
- **G**：钩爪；再次按下 G 可以取消。
- **W**：靠近标记墙时攀爬，松开后缓慢滑落；贴墙按 Space 可蹬墙跳。
- **V**：共鸣视野，消耗 10 体力，持续 4.5 秒，冷却 6 秒。
- **PageUp / PageDown**：F5 打开时选择人类、血色、深渊或黑色天际拔刀形态，按 L 测试。
- 精准闪避（K/Shift）在能力已解锁或 F5 覆盖时触发约 2.4 秒魔女时间，减慢敌人而不减慢主角。
- F5 下异常负荷仅存在于内存，关闭 F5 或按 F6 会清除。
- F4/F5/F6 由主角输入层消费；原有古代研究、村庄防守、蜜忒共鸣测试剧场改用 F10/F11/F12。

发现问题时请记录覆盖层中的战斗状态与资源数值。调试覆盖关闭后仍必须重复验收，不能只凭调试模式通过就认为正常流程通过。

---

## Original combat regression

The previous Core Combat Demo remains in:

`res://scenes/combat_demo.tscn`

It still covers:

**Hero → Cultist A → Pale Hound → Cultist B → Ash Gate → Ashen Knight**

It can be opened directly from the Godot editor.

---

## Runtime limitation

The maintainer environment does not contain a Godot runtime, so interactive frame-level execution cannot be claimed here.

Repository changes are checked structurally after each implementation pass.

Final acceptance should be performed on Godot 4.6.x.



## Ending CG acceptance

Each of the three endings must finish with a dedicated full-screen cinematic CG, not only a text card.

- **凡人之墓**: lone Hero / surviving kingdom / the world continuing without divine salvation.
- **永恒乐园**: Hero and Mite together inside the dream-like eternal paradise.
- **烈火天罚**: the ruined city, the final separation of Hero and Mite, and the fire that remains.

The current development build uses replaceable SVG key art with animated fade / camera-push treatment. Final production art can replace these assets without changing ending state logic.

## Menu / narrative acceptance pass

The development build now includes:

- Bottom narrative panels pause the SceneTree, so Hero and enemies stop together.
- While a narrative panel is visible, E, Space, Enter, Escape, or left mouse click immediately closes it.
- Esc opens the in-game pause menu when no narrative is active.
- The pause menu provides Resume, Save, New Game, Return to Title, and four-language selection.
- The title screen provides Continue, New Game, and four-language selection.
- Supported languages: Simplified Chinese, Traditional Chinese, English, Japanese.

## Interaction acceptance pass

- Only one nearby interaction prompt may be visible at a time.
- Interaction focus is resolved by distance; when two targets are nearly tied, the target priority breaks the tie deterministically.
- An NPC remains visible even when it currently has no usable interaction, but its **E / Speak** prompt is hidden.
- Mite, doors, POIs, and route memory objects follow the same focus arbitration.
- The Village Hub should never show two competing E prompts that both appear actionable.
- The Lullaby Path / Church Road must restore Hero input immediately after scene transition, including when the previous scene ended during narrative presentation.
- A stale SceneTree pause state must not leave the Hero frozen after entering a route scene.


## Quick Dash prototype acceptance / 快速冲刺原型验收

This is a movement-system test only; it adds no level, map, encounter, or story unlock.
本节仅验收移动机制，不增加任何关卡、地图、遭遇或剧情解锁。

1. Enter combat and press F4 to show the Hero-local overlay.
2. Press F5 once, then press X while facing right and left. Expected: a fast horizontal dash follows facing direction and does not grant invulnerability.
3. Check initial values: 24 stamina, about 0.16 seconds duration, 1.10-second cooldown. X during cooldown or with insufficient stamina must not start a dash.
4. Turn F5 override OFF. Unless `quick_dash` is formally unlocked, X must not start a dash.
5. Open the menu during a dash and take damage during a dash. Expected: no stale dash state or delayed action remains.
6. Press F6. Expected: HP/stamina restored, temporary ability effects/cooldowns clear, current Hero action/hitbox cancelled without writing ability/story flags.
7. Die/respawn and use a rest point; confirm dash state/request reset and ordinary K/Shift dodge still works independently.

预期结果：快速冲刺独立于 K/Shift 普通闪避；冲刺本身无无敌帧，有独立体力消耗与冷却；受击、菜单、死亡和休息不会残留动作状态。


## Protagonist ability lab / 主角能力独立测试

This pass implements ability mechanics before story/map reward placement. F5 is a session-only test override, and its grapple anchors, hidden traces, marked walls, selected iaijutsu form and test-only abnormal load do not persist.

In a playable scene, enable F5 and test G (grapple), W (wall climb), Space while touching a marked wall (wall jump), V (Resonance Sight), X (Quick Dash), precise K/Shift dodge (Witch Time), and PageUp/PageDown then L (iaijutsu profile). Q switches between Long Sword and Short Blade; F executes the selected weapon-bound technique; R triggers Eldritch Echo.

The implementation is committed at source level, but Godot 4.6 runtime validation remains **NOT RUN** in the maintainer environment. Do not treat this as a runtime pass until scene startup, collision boundaries, effect cleanup, action interruption and save/reset isolation are verified in Godot.
