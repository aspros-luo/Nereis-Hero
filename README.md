# Nereis Hero

A 2D Soulslike action RPG in the Nereis / 蜜忒之歌 universe.

## Current playable direction

Development has moved beyond the original Core Combat Demo into the first narrative production pass.

The current default flow is:

**Church surgical ward → escape → remote village → Mite → Church / village investigation**

Default startup:

`res://scenes/escape_prologue.tscn`

The original combat demo remains available at:

`res://scenes/combat_demo.tscn`

## Current narrative foundation

Canonical story memory:

`docs/DEVELOPER_STORY_MEMORY.md`

World map master plan (Chinese draft):

`docs/WORLD_MAP_MASTER_PLAN_CN.md`

Phase I level topology (Chinese draft):

`docs/LEVEL_TOPOLOGY_PHASE_1_CN.md`

Full world network topology (Chinese draft):

`docs/WORLD_NETWORK_TOPOLOGY_CN.md`

Director plan:

`docs/DIRECTOR_NARRATIVE_PLAN.md`

Short story foundation:

`docs/STORY.md`

The three canonical endings are:

- **凡人之墓**
- **永恒乐园**
- **烈火天罚**

The Hero / Mite relationship is a central emotional axis.

Mite is genuinely pure and initially unaware of the Outer God's larger reality.

Hero never knowingly learns her true identity during the main story.

The Church's ancient-god experimentation leaves residue inside Hero.

Much later, Hero and Mite's physical relationship becomes the bridge between the ancient-god residue and the Outer-God influence.

## Current implemented production work

### Opening

- Playable Church surgical ward escape
- Three Experiment Wardens
- Surgical residue clue
- Prologue checkpoint
- Transition into the village

### Village / Mite

- Playable Village Hub
- First Mite meeting
- Mite interaction progression
- Hidden relationship facts instead of a visible romance meter
- Rushed mainline progression can cause the Mite connection to be missed
- Missed connection returns as a quiet empty-chair scene
- Procedural lullaby motif tied to the village

### Hidden investigation

- Persistent hidden artifact evidence state
- Four independent hidden story sources can assemble the resistance anchor
- Ancient research ward
- Graveyard bell story
- Restoration order
- Route memory echo
- Evidence is not exposed as a "true ending checklist"

### Combat

- Weighty 2D action foundation
- Three-step attack rhythm
- Dodge / invulnerability
- Stamina
- Hit-stagger
- Hitstop feedback
- Cultist / Pale Hound pressure patterns
- Two-phase Ashen Knight
- Procedural combat audio

### Director test theaters

**F7 — Church Final Boss Theater**

High Priest human phase → ancient-god phase → King.

**F8 — 烈火天罚 Theater**

100 cultists → Mite → waiting / self-sacrifice → city detonation.

The 100 cultist count is intentionally a spectacle. Future crowdfunding can optionally turn the crowd into supporter cameos.

### Debug

- F1 — candidate-driven endgame theater
- F2 — Eternal Paradise Theater
- F3 — debug overlay
- F4 — Ancient Research Ward
- F5 — Village Defense Theater
- F6 — Mite Resonance Theater
- F7 — Church Final Boss Theater
- F8 — 烈火天罚 Theater
- F9 — clean reset

## Narrative style

The game favors discovery rather than exposition.

The main references are:

- Dark Souls
- Bloodborne
- Blasphemous 2
- The Song of Saya
- Neon Genesis Evangelion
- Biblical Eden imagery
- Lovecraftian cosmic horror

These are reference influences, not content to copy.

The intended narrative language is:

**items as evidence + environment as narrative + NPCs as biased witnesses + contradictory memories + recurring symbols + emotional subtext**

## Save / Resume

The default startup goes through:

`res://scenes/boot.tscn`

A completed prologue resumes from the last persisted story location. F9 clears the run and starts the prologue again.

## Engine

Godot 4.6.x / GDScript / GL Compatibility.

## Runtime verification

The maintainer environment does not contain a Godot executable, so interactive frame-level runtime acceptance must still be performed locally with Godot 4.6.x.

Repository structure and source changes are continuously checked.

## Branch

Development happens on:

`development`

Do not add or trigger GitHub Actions for this project.

## Production rule

When implementation reaches a major unresolved story decision — especially Hero/Mite history, the four hidden resistance side stories, the final antagonist's political motive, the Outer God's identity, or the exact ending condition — stop coding that story layer and return to story design.

For ordinary gameplay, combat, UI, effects, technical systems and presentation, development can proceed autonomously.
