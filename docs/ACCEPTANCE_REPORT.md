# Nereis Hero — Development Acceptance Report

Date: 2026-10-07

## Current milestone

The project has moved from the original Core Combat Demo into the first narrative production pass.

Current default scene:

    res://scenes/escape_prologue.tscn

Active development branch:

    development

## Production flow

    Church surgical ward
        ↓
    Escape
        ↓
    Village
        ↓
    Mite relationship layer
        ↓
    Church / Tavern / Graveyard investigation
        ↓
    Restoration Camp
        ↓
    Director test theaters for future endgame states

## Implemented in this milestone

### Playable opening

- Church surgical ward
- Three Experiment Wardens
- Surgical residue clue
- Checkpoint
- Exit sequence
- Prologue completion persistence
- Transition into Village Hub

### Village / Mite

- Mite NPC foundation
- First meeting
- Four staged interactions
- Quiet repeat interaction
- No visible romance meter
- Press-driven interaction input
- Rushed Church progression can mark the connection as missed
- Missed connection becomes an empty-chair scene
- Mite can also appear in the Tavern
- Procedural lullaby motif

### World / investigation

- Tavern
- Church
- Graveyard
- Restoration Camp
- Church / Tavern investigation doors into the existing route scenes
- Persistent world/interior clue state
- Hidden artifact source provenance
- Resume-state support for new locations

### Ending state foundation

- Ending evaluator prototype
- 凡人之墓 candidate when no physical union occurs
- 永恒乐园 candidate when union occurs without enough resistance evidence
- 烈火天罚 candidate when union occurs with at least the current provisional resistance threshold
- The exact final story thresholds remain intentionally easy to revise

### Director theaters

**F6 — Mite Resonance Theater**

Tests:

- physical union state
- ancient-god residue awakening
- Outer-God resonance
- corrupted lullaby
- first visible behavioral influence on Mite

**F7 — Church Final Boss Theater**

Tests:

- High Priest human phase
- High Priest ancient-god phase
- King intervention
- political / tragic final-boss tone

**F8 — 烈火天罚 Theater**

Tests:

- 100 cultist spectacle
- one-hit crowd clearing
- Mite final encounter
- waiting window of approximately 60 seconds
- Mite self-sacrifice into Hero's weapon
- city-destruction finale
- corrupted lullaby

**F9 — clean reset**

Returns the player to:

    res://scenes/escape_prologue.tscn

## Original combat system

The existing Core Combat Demo remains intact:

    Hero
      → Cultist A
      → Pale Hound
      → Cultist B
      → Ash Gate
      → Ashen Knight

It remains useful as a combat regression scene.

## Runtime limitation

The maintainer environment does not contain a Godot executable.

Therefore this report does **not** claim:

- actual Godot startup
- frame-level combat timing
- real collision/hitbox behavior
- final visual quality
- actual 60-second idle timing in runtime
- real 100-enemy performance
- actual scene-transition behavior

Those require local Godot 4.6.x execution.

## Current development status

**Narrative foundation implemented / director theaters implemented / static repository review ongoing / runtime acceptance pending.**

No GitHub Actions workflow was added or triggered during this milestone.

