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

