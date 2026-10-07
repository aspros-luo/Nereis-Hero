# Nereis Hero

A 2D Soulslike action RPG set in the Nereis universe.

## Vision

A dark fantasy / cosmic horror action RPG told from the Hero's perspective. The game explores survival, faith, memory, selfhood, and the cost of knowing the truth.

**Nereis Hero** is the shared-world counterpart to **Nereis Lullaby**:

- Nereis Lullaby follows Mite/Nereis and the village/tavern.
- Nereis Hero follows the amnesiac Hero through roads, the church, the village, ruins, and the forces behind the disappearances.
- Shared events can have different interpretations depending on whose perspective is being followed.

## Current Development

The `development` branch now contains a playable systems-first chapter foundation:

### Combat

- Hero combat state machine foundation
- Movement, jump, attack and dodge
- Stamina and recovery rhythm
- Hurt stun and knockback
- Reusable Hitbox / Hurtbox system
- Hit sparks
- Two-phase Ashen Knight Mini Boss
- Pale Hound encounter
- Bell Wraith aerial/ranged encounter
- Boss health HUD

### Progression

- Checkpoints
- Death respawn
- Persistent save/load
- Weapon level 2 upgrade
- Humanity as a selfhood axis
- Memory progression
- Church alignment / Lullaby resonance
- Route selection

### Story

- Old Hunter
- First memory event
- First meaningful choice
- Church Route
- Lullaby Route
- Shared-world Amnesiac Youth
- Shared-world Traveling Merchant
- Route-specific memory echoes
- Humanity-sensitive dialogue
- Tavern / Church clues
- Village Graveyard clue + Bell event

### World

- Horizontal camera-driven level
- Village Hub
- Tavern Interior
- Church Interior
- Village Graveyard
- Scene fade transitions
- Tavern rest point
- Persistent location resume
- Fixed HUD + F3 debug overlay
- F9 clean test reset

## Current chapter route

`Awakening → Old Hunter → First Memory → Checkpoint → Pale Hound → Cultist → Ash Gate → Ashen Knight → First Choice → Church/Lullaby Route → Village Hub → Tavern/Church/Graveyard`

## Engine

Godot 4.6.x / GDScript / GL Compatibility.

The project deliberately avoids unnecessary dependencies while the gameplay foundation is being validated.

## Runtime Verification

The maintainer environment currently cannot execute Godot Runtime or reach the official Godot download host. The project therefore includes detailed `[NEREIS][...]` runtime logging and `docs/TESTING.md` acceptance procedures.

Run locally with Godot 4.6.x and send the complete Output log from the first `[NEREIS][BOOT]` marker through any error for debugging.

## Branching

Development happens on `development`. `main` remains the stable branch until the first local runtime acceptance pass is completed.
