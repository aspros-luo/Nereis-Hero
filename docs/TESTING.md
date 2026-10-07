# Testing

## Current Acceptance Gate

The authoritative acceptance target for the current development milestone is the **Core Combat Demo**.

The default startup scene is:

res://scenes/combat_demo.tscn

The active branch is:

development

## Runtime

Use Godot 4.6.x with the standard GDScript build. The project does not require the .NET build.

Godot 4.6.1 is an official stable maintenance release for the 4.6 series. Later 4.6.x maintenance releases are also intended to remain compatible with this project.

## Core Route

Hero → Cultist A → Pale Hound → Cultist B → Ash Gate → Ashen Knight

The Ashen Knight must not spawn before all three small enemies are defeated.

## Manual Acceptance

1. Start the project. The Core Combat Demo must open directly.
2. Move left/right, jump, and pass the first checkpoint.
3. Attack with J / Left Mouse. Verify the three-step attack rhythm, clear windup, contact window and recovery.
4. Hit an enemy. Verify hit spark, HIT <damage>, small hero recoil and enemy hit-stagger.
5. Press K / Shift while an enemy attacks. Verify each press triggers one dodge and the short invulnerability window prevents damage.
6. Take enough damage to die. Verify the Hero returns with full HP and stamina. Before the Boss has spawned, the small-enemy wave must reset.
7. Defeat Cultist A, Pale Hound and Cultist B. The HUD must advance from 0 / 3 to 3 / 3.
8. Confirm the Ash Gate opens and a Boss approach checkpoint is activated. The Ashen Knight must spawn only after 3 / 3.
9. Fight the Ashen Knight. Verify its heavy-attack telegraph is clearly visible before damage is applied.
10. Reduce the Boss to 120 HP or lower. Verify THE ASHEN KNIGHT // PHASE II appears once, movement pressure increases, attack cooldown shortens, and Phase II damage rises to 36.
11. Defeat the Ashen Knight. Verify CORE COMBAT DEMO COMPLETE appears and the Boss HUD disappears.
12. Die during Boss combat once. Verify the next respawn occurs at the Boss approach checkpoint instead of the beginning of the road.
13. Press F9. Verify the save is deleted and the Core Combat Demo starts cleanly again.
14. Press F3. Verify the debug panel can be toggled without affecting combat.

## Expected Feedback

Successful Hero hit:

HIT <damage>

Hero defeat:

DEFEATED // RETURNING TO CHECKPOINT

Boss Phase II:

THE ASHEN KNIGHT // PHASE II

Demo completion:

CORE COMBAT DEMO COMPLETE

## Combat Tuning Baseline

Hero:

- HP: 100
- Stamina: 100
- Attack cost: 12
- Dodge cost: 28
- Base attack damage: 34
- Three-step combo multipliers: 1.00 / 1.18 / 1.50
- Dodge duration: 0.18s
- Dodge invulnerability: active for the dodge window

Small enemies:

- Cultist HP: 100
- Pale Hound HP: 70
- Both have readable attack windups and brief hit-stagger

Boss:

- Ashen Knight HP: 240
- Phase II threshold: 120 HP
- Phase I heavy attack: 24 damage
- Phase II heavy attack: 36 damage

## Retained Regression Systems

The repository still contains the later Vertical Slice foundations for:

- Old Hunter / memory
- Church and Lullaby routes
- Village Hub
- Tavern / Church interiors
- Graveyard
- Humanity
- Memory / clue persistence
- Save / load
- Scene transitions

Those systems are not part of the current startup acceptance gate, but should remain structurally intact while the Core Combat Demo is developed.

## Runtime Limitation

The maintainer container currently has no Godot executable and cannot reach the official download host, so interactive execution cannot be performed here.

Static repository checks are performed after each iteration. Final acceptance still requires running the project with Godot 4.6.x in a local runtime environment.
