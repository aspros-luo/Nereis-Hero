# Nereis Hero — Development Status

Date: 2026-10-08

## Current direction

The current protagonist combat pass adds three prototype special techniques to the existing combat architecture:
- Long Sword: Judgment Slash (weapon-bound heavy hit)
- Short Blade: Crescent Combo (three independently timed hit windows)
- Eldritch ability: Eldritch Echo (stamina cost, cooldown, short enemy stagger with boss resistance)

Debug controls: F3 opens the panel; while it is open, F4 toggles session-only special-technique override and F5 restores HP/stamina and Echo cooldown. A visual pass now gives Judgment Slash a heavier steel/gold arc and each Crescent Combo stage a distinct silhouette; slash effects fade over their full lifetime. F/R inputs are ignored while another locked combat action is active, preventing delayed accidental technique casts. Static structural checks passed; runtime Godot testing is still required before marking the techniques as accepted.


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


## Movement progression foundation

- Implemented the first dormant traversal mechanic: one additional air jump is available only if the saved `double_jump` ability record exists. It resets on landing, death respawn and full restoration.
- Ordinary jump and coyote-time jump remain unchanged. The new ability is not granted automatically, so no current level becomes dependent on an unearned move.
- `quick_dash` remains a registered progression ID only. Before implementation, define whether it is a separate input from dodge and its own stamina/cooldown/invulnerability rules.
- Runtime verification remains pending; the next review should specifically test air-jump count transitions and input buffering.


## 2026-10-09 — Prologue reset regression fix

- Fixed the prologue death handler so the escape gate closes when the three-Warden encounter is reset; previously the gate could remain enabled after the Wardens respawned.
- Kept earned story progression persistent: dying after unlocking basic iaijutsu does not revoke the ability, but the encounter must be cleared again to reopen the exit.
- Added the corresponding source-level and pending runtime regression cases to `PROTAGONIST_TEST_REPORT.md`.
- Static review of the changed handler confirms the gate is disabled before the Wardens are cleared and respawned. Godot startup/runtime was not tested because the current execution environment has no Godot executable and cannot download one; no GitHub Actions workflow was triggered.

### Next

1. Continue source-level regression review around save/load and scene transitions.
2. Keep progression rewards idempotent across death, scene re-entry and save migration.
3. Implement new traversal abilities only after their input and combat-state contracts are explicit; keep sewer mutation content gated until its encounter and reward calls exist.


## 2026-10-09 — Ability-first development workflow

### Director decision

The protagonist's complete ability/technique set must be designed and validated before distributing unlocks across story chapters and maps.

### Added

- Added `docs/HERO_ABILITY_DESIGN.md` as the first consolidated ability design baseline.
- Separated core combat, traversal, iaijutsu mutations, Debug all-capabilities mode, shared validation matrix, and the later story/map distribution phase.
- Marked each ability honestly as implemented, partially implemented, or design-only; a reserved ability ID is not considered a completed mechanic.
- Specified that Debug overrides must be session-only and must not mutate formal unlock records, achievements, materials, story flags, or saves.

### Next sequence

1. Review/freeze the ability catalogue and input contracts.
2. Implement Debug all-capabilities override plus individual iaijutsu-form selection.
3. Implement missing movement mechanics and validate ability combinations in a dedicated test area.
4. Balance combat and resource costs.
5. Only after the ability set passes validation, assign ability rewards to levels, bosses, quests, and story beats.

### Test integrity

The design document was committed to the feature branch. This was a documentation-only change; Godot runtime tests were not run and no GitHub Actions workflow was intentionally triggered.


## 2026-10-09 — Combat VFX art pass

- Replaced thin generic-looking technique strokes with layered, tapered silhouettes and restrained edge highlights.
- Judgment Slash now reads as a heavy warm-steel cut; Crescent Combo has low / rising / crossing-finisher silhouettes; Eldritch Echo uses broken ritual rings and rune-like radial fragments.
- Hit sparks now have a dark impact core, bright diamond flash and tapered splinters.
- These effects are drawn procedurally in GDScript, so no image-generation quota or external asset import is required.
- Static source review only; Godot rendering, scale, and frame-timing still need in-game verification.


## 2026-10-09 — Hero silhouette pass

- Replaced the Hero's basic circles/rectangles with layered knight armor, cloak folds, helmet/visor, rivets, gauntlets, boots and a more readable weapon silhouette.
- Kept the existing CharacterBody2D movement, collision, weapon switching, technique state, and HUD logic unchanged; this is a renderer-only change.
- Runtime rendering has not been verified in Godot yet. Check normal camera scale, both facing directions, movement bob, and short-blade/long-sword silhouettes.


## 2026-10-09 — Enemy silhouette pass

- Cultist rendering now has a ragged layered robe, hooded ritual mask, red visor slit and chest seal.
- Ashen Knight rendering now has layered plate armor, a heavier greatsword silhouette and a phase-two crown that visually signals the transformation.
- Combat logic, hitboxes, damage, AI and collision were left unchanged.
- Runtime art review remains pending in Godot; check readability of enemy telegraphs and floating health labels.
