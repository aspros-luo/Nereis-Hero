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
- **F4** → Ancient Research Ward
- **F5** → Village Defense Theater
- **F6** → Mite Resonance Theater
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

### F3 debug

F3 toggles the debug overlay.

It exposes internal development state including:

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

On the development branch, the Hero-local debug overlay is enabled by default. It follows the Hero and shows current HP/stamina, weapon, combat state/action, combo index, invulnerability, special-technique cooldown, hidden resonance/exposure/humanity/abnormal-load values, and extra-air-jump count. Hidden values are shown only in this debug overlay, not the normal HUD.

- **F3**: toggle debug overlay visibility.
- **Ctrl+F4**: toggle session-only weapon-technique unlock override. This is not saved and does not grant narrative progression.
- **Ctrl+F5**: refill Hero HP/stamina and clear the Eldritch Echo cooldown for repeated combat checks. This is session-only.
- **F4/F5 without Ctrl** remain available to existing scene/theater shortcuts.

Use the overlay to report the exact combat state and resource values when an issue occurs. The override is only a test convenience; acceptance must also be repeated with it disabled.

主角调试覆盖层在当前开发分支默认开启，跟随主角显示生命/体力、武器、战斗状态与动作、连击段数、无敌状态、战技冷却、隐藏共鸣/接触/人性/异常负荷，以及额外空中跳跃次数。隐藏数值只在调试覆盖层中显示，不进入正式 HUD。

- **F3**：显示/隐藏调试覆盖层。
- **Ctrl+F4**：切换本次运行有效的武器战技解锁覆盖，不写入存档，也不会授予剧情成长。
- **Ctrl+F5**：恢复主角生命/体力并清空回声战技冷却，便于重复战斗测试，仅影响当前运行。
- 不带 Ctrl 的 **F4/F5** 仍保留原有场景/剧场快捷键。

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
