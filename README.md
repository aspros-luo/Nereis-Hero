# Nereis Hero

A 2D Soulslike action RPG set in the Nereis universe.

## Current Goal

The project is currently being developed around the smallest playable combat loop:

controllable protagonist → simple level → small enemies → Boss

The default startup scene is res://scenes/combat_demo.tscn.

### Core Combat Demo

- Hero movement / jump with coyote time and jump buffering
- Three-step light-attack rhythm with deliberate windup and recovery
- Dodge / short invulnerability window
- Stamina and combat resource pacing
- Enemy hit-stagger / knockback
- Readable enemy attack telegraphs
- 3 small enemies with different pressure patterns
- Checkpoint and death respawn
- Boss gate and compact boss arena
- Two-phase Ashen Knight with faster Phase 2 tempo
- Boss health HUD
- F3 debug / F9 clean reset

## Current Demo Route

Awakening → Cultist A → Pale Hound → Cultist B → Ash Gate → Ashen Knight

The Boss appears only after all three small enemies are defeated.

## Combat Direction

The current combat direction takes broad inspiration from the responsive 2D action feel of **Hollow Knight** and the heavier, ritualistic presentation of **Blasphemous 2**.

The implementation goal is not to reproduce either game. For this project, the reference points are:

- immediate movement and readable spacing
- attacks with a clear windup, contact window and recovery
- strong enemy telegraphs before damage
- noticeable hit reaction and knockback
- a small number of enemy patterns that are easy to read but punish careless timing
- bosses that change tempo rather than simply gaining more HP
- a dark, sacred, oppressive visual language

The current combat demo is deliberately small so these fundamentals can be tuned before more areas, routes and narrative systems are expanded.

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
