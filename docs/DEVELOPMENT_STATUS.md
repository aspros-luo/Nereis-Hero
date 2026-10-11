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


## Map production continuation — 2026-10-11

### Completed in this continuation

- Audited the existing A3 local Resonance Sight bridge against the Hero → WorldState → `resonance_hidden_targets` refresh path. The bridge already receives state changes through `WorldState.refresh_resonance_reveals()`; no duplicate runtime mechanism was added.
- Strengthened `tools/validate_graybox_scene_wiring.py` so future edits must preserve the A3 route ID, resonance threshold (28), bridge coordinates, persistent open-state restoration, collision lifecycle, shared E-focus interaction, and the WorldState reveal dispatch.
- The validator source was re-fetched after its commit and the newly added assertions were checked against the current A3 route and WorldState source text. This is a contract-presence audit only; the Python validator itself was not executed in a local checkout.

### Still outstanding
- Re-audited regional death checkpoints: `_spawn_hero()` already stores the current region spawn as the checkpoint. The continuation now strengthens the static regression contract and avoids adding a duplicate save call; runtime respawn still needs Godot verification.

- Godot 4.6.x runtime acceptance remains pending because no Godot executable is available in the maintainer environment.
- The updated Python validators have not yet been run against a local working tree in this continuation.
- The A0–A12 / H01–H08 platform routes, C01–C24 transitions, save/continue spawn restoration, interaction arbitration, death recovery, and all ending handoffs still need runtime traversal. Do not describe them as runtime-passed.
- Continue by auditing the highest-risk unresolved map contracts and, where practical, improve static tooling before expanding further graybox geometry. Preserve the DS1-style interconnected box-world and Resonance Sight's ability to reveal routes within familiar regions.

### Verification boundary

- **Confirmed:** latest development branch source was fetched; validator assertions were committed; the current checked source strings satisfy the added local-route contracts.
- **Not confirmed:** execution of `python3 tools/validate_world_map_topology.py`, execution of `python3 tools/validate_graybox_scene_wiring.py`, Godot parser/import, collision behavior, player traversal, or frame-level scene changes.
- **Workflow policy:** no GitHub Actions were triggered.
