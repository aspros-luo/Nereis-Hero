# Nereis Hero

A 2D Soulslike action RPG set in the Nereis universe.

## Current Goal

The project is currently being developed around the smallest playable combat loop:

controllable protagonist → simple level → small enemies → Boss

The default startup scene is res://scenes/combat_demo.tscn.

### Core Combat Demo

- Hero movement / jump
- Attack
- Dodge / invulnerability
- Stamina
- Hurt stun / knockback
- 3 small enemies
- Checkpoint and death respawn
- Boss gate
- Two-phase Ashen Knight
- Boss health HUD
- F3 debug / F9 clean reset

## Current Demo Route

Awakening → Cultist A → Pale Hound → Cultist B → Ash Gate → Ashen Knight

The Boss appears only after all three small enemies are defeated.

## Future Content

The repository also contains the next-stage foundations for:

- Church / Lullaby routes
- Village Hub
- Tavern / Church interiors
- Graveyard
- Humanity
- Memory / Clue systems
- Save / load
- Shared-world NPCs

Those systems are retained, but they are not required for the current Core Combat Demo acceptance.

## Engine

Godot 4.6.x / GDScript / GL Compatibility.

## Runtime Verification

The maintainer environment currently has no Godot Runtime executable, so final runtime acceptance must be performed locally with Godot 4.6.x. Repository code is continuously checked for structural consistency before each iteration.

## Branch

Development happens on development. Main remains the stable branch until the Core Combat Demo passes local acceptance.
