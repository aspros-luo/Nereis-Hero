# Nereis Hero — Development Status

Date: 2026-10-08

## Current direction

The project is now in the first **narrative production pass**, not merely a combat prototype.

Default startup:

`res://scenes/boot.tscn`

Boot resolves to:

- Church escape on a fresh run
- persisted narrative location after the prologue is complete

## Implemented production content

### Opening

- Church surgical ward
- 3 Experiment Wardens
- surgical residue clue
- checkpoint / death reset
- playable escape to village

### Village

- Village Hub
- Mite first meeting
- place-based relationship rhythm
- Mite House chapter
- private-house union trigger after relationship progression
- Tavern Mite interactions
- missed-connection empty-chair scene
- Restoration Camp
- North Gate / Village Defense
- Church / Tavern investigation routes
- Graveyard + Bell Keeper side story
- Ancient Research Ward

### Hidden resistance

Four canonical source arcs currently exist as implementation placeholders:

1. Ancient Research Ward
2. Graveyard Bell story
3. Restoration Order
4. Route Memory Echo

Three of four awaken the hidden resistance anchor.

The UI never tells the player that this is a true-ending requirement.

## Mite progression

Relationship facts:

- first meeting
- meal
- stay a while
- return
- post-resonance dialogue stages

After physical union:

- ancient-god residue awakens
- Outer-God resonance begins
- Mite control stage progresses 0 → 3
- subtle visual changes appear before any explicit monster transformation

Physical union in normal flow is triggered after the relationship has developed and the player rests at the Tavern.

The presentation is non-explicit and relies on fade-to-black and aftermath.

## Three ending theaters

### F1 — Candidate-driven

Uses the ending evaluator.

- no union → 凡人之墓 theater
- union + no resistance → 永恒乐园 theater
- union + hidden resistance → 烈火天罚 theater

### F2 — 永恒乐园

Prototype now includes:

- transformed High Priest
- transformed King
- union with Mite
- dream/paradise visual transition
- final state where no one is lonely / separate

### F4 — Ancient Research Ward

Prototype includes:

- research husk
- black vial
- sealed hair
- vessel ledger
- hidden ancient-god evidence

### F5 — Village Defense

Prototype includes:

- Bandits
- Church Inquisitors
- two attack waves
- Hero protecting the village
- defeat retry loop

### F6 — Mite Resonance

Isolated relationship/resonance prototype.

### F7 — Church Final Boss

Prototype includes:

- High Priest human phase
- High Priest ancient-god phase with area-burst attack
- King intervention
- King phase-two heavy charge
- post-victory epilogue showing the next corrupt order beginning

### F8 — 烈火天罚

Prototype includes:

- 100 nonblocking one-hit cultists
- 60-second true no-input waiting window for Mite
- corrupted lullaby
- Mite final encounter
- true 60-second no-input waiting condition
- Mite throws herself onto Hero's weapon
- restrained camera impact at the self-sacrifice
- city-scale detonation
- heavy camera impact

### F9

Deletes save data and starts the playable prologue.

## Debug shortcut matrix

From Village Hub:

- F1 — Candidate endgame
- F2 — Eternal Paradise
- F3 — Debug HUD
- F4 — Ancient Research Ward
- F5 — Village Defense
- F6 — Mite Resonance
- F7 — Church Final Boss
- F8 — 烈火天罚
- F9 — Reset

## Runtime limitation

The current maintainer environment has no Godot 4.6 executable.

Therefore:

- source structure is checked
- GitHub state is checked
- quote/string boundaries are checked
- major script structures are checked

But actual frame-level Godot runtime acceptance is still pending local execution.

## Important rule

Do not trigger GitHub Actions.

Do not replace the narrative canon with temporary prototype assumptions.

When a future implementation reaches a truly unresolved core story decision, stop that specific story layer and ask the director. Otherwise keep developing autonomously.


## Interaction / flow stabilization

- Unified nearest-interaction focus across Mite, NPCs, clues, doors, exits and rest points.
- Village house entry is now explicit **E** interaction; touching the door no longer transitions scenes.
- Route and interior doors are explicit **E** interactions.
- Completed routes can be replayed instead of auto-returning to the Village Hub.
- Narrative-to-scene transitions now wait on the narrative completion signal instead of a paused SceneTree timer.
- Route exits validate the memory echo belonging to the active route.

## Latest polish

- Shared Boss HUD now reads per-Boss max health, display name and phase.
- Village has subtle procedural firefly ambience.
- After Outer-God resonance, a subset of fireflies becomes synchronized and colder in tone.
- The final Mite waiting scene has 15s / 35s / 50s micro-movements before the 60s decision.
- The final Mite lunge has restrained camera impact; city detonation uses a much heavier impact.


## 2026-10-09 — Protagonist progression pass

### Implemented on `feature/protagonist-system`

- The Hero can learn the three defined altered iaijutsu forms in order: Blood → Abyssal → Black Horizon.
- L selects the strongest form actually understood by the Hero.
- Each form now has its own initial damage, HP/stamina cost, abnormal-load increase, reach, hitbox, hit window, windup and slash presentation.
- HUD discovery cues queue instead of overwriting each other when several progression conditions become true close together.
- `HERO_SYSTEM.md` and `PROTAGONIST_TEST_REPORT.md` document the new flow and the remaining runtime checks.

### Current verification status

- GitHub source-level consistency checks passed for progression order, combat profile use, hitbox profile use, visual variants, cue queueing, balanced braces/parentheses, and menu simulation behavior.
- Godot runtime parsing, scene launch, combat tuning, hitbox placement and save/load behavior remain unverified in this execution environment.
- No GitHub Actions workflow was intentionally triggered.

### Next work

1. Trace normal-story writes to hidden exposure/resonance values without inventing new story triggers.
2. Continue technical regression review for combat state cleanup, menu input isolation, and save/load.
3. Pause only the unresolved narrative trigger decision and bring the Director concrete options before adding any new story/level reward.


## 2026-10-09 — Layered progression foundation

### Implemented on `feature/protagonist-system`

- Added persistent, data-driven ability unlock records with allowed source categories: story, exploration, achievement, resonance, and material.
- Added persistent achievement flags and material inventory helpers, including duplicate-safe achievement recording and checked material spending.
- Added a basic iaijutsu combat profile: no HP sacrifice, no abnormal-load gain, shorter reach and lower damage than altered forms, with a neutral slash visual.
- Basic iaijutsu is not auto-unlocked. Its story trigger remains a director-owned narrative/level decision.
- Reserved ability IDs for Witch Time, grapple, and wall climb; these are not represented as implemented mechanics yet.

### Review decision

- Story unlocks teach core actions.
- Exploration reveals altered techniques, traversal routes and relics.
- Achievements can gate selected mastery upgrades.
- Resonance is an understanding threshold, not a visible XP bar.
- Materials support upgrades/equipment without charging the player again for a learned basic move.
- Avoid stacking every requirement on every ability; use multi-condition gates only for deliberate special abilities.

### Verification status

- Source-level checks are required for save/load/reset symmetry, source validation, material underflow protection, and the base iaijutsu profile.
- Godot parser/runtime validation remains pending; no GitHub Actions workflow was intentionally triggered.

### Next work

1. Re-fetch and verify all changed scripts after the progression edits.
2. Continue technical work on dodge-state timing and combat interruption without adding unapproved story triggers.
3. Ask the Director to choose the exact story beat for basic iaijutsu before connecting the unlock call.
4. Design Witch Time's timing and world-slow implementation separately before enabling it in normal play.


## 2026-10-09 — Story reward and mutation gates

### Implemented on `feature/protagonist-system`

- Connected the first human iaijutsu unlock to the prologue's three-Warden clear and escape-road reveal.
- Added a legacy-save migration so saves that already completed the prologue are not stranded without the basic move.
- Added the basic iaijutsu name to character details in Simplified Chinese, Traditional Chinese, English and Japanese.
- Registered `double_jump` and `quick_dash` in the persistent ability ledger; dodge remains a baseline action.
- Gated Blood Iaijutsu behind the basic move, hidden resonance/exposure, a future sewer-aberrant achievement flag and an aberrant-gland material. This prevents the prologue surgical-tray clue alone from immediately mutating the move.

### Design decision

- Basic iaijutsu is the first story reward: the Hero remembers a human technique after the final prologue encounter.
- Blood Iaijutsu is the first occult mutation, planned for the Royal City Sewer quest. It must be supported by an actual encounter, item, and narrative clue before becoming reachable.
- Skills should keep their silhouette and gain only subtle tentacle-like details as they mutate. A dedicated skill-icon asset/UI system does not yet exist, so this remains an art-direction constraint rather than a claimed implementation.
- Mobility ability IDs are records only; double jump, quick dash, grapple, wall climb and Witch Time still need their actual movement/state implementations and level-boundary tests.

### Verification status

- Source updates were committed to the feature branch. Static consistency review remains necessary after the final edits.
- Godot parser, scene launch, combat and save migration runtime tests are not available in this execution environment.
- No GitHub Actions workflow was intentionally triggered.

### Next technical work

1. Verify code paths for base iaijutsu unlock, mutation gates, HUD display, and save migration.
2. Audit dodge/jump state transitions and design a movement ability interface without enabling unimplemented traversal mechanics.
3. Keep sewer encounter implementation and other major narrative/level nodes as a future director checkpoint; proceed autonomously on reusable technical foundations.
