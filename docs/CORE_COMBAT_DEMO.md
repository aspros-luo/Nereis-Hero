# Core Combat Demo

The default startup scene is now:

res://scenes/combat_demo.tscn

## Goal

Validate the game's minimum playable core before adding more content:

controllable Hero → simple horizontal level → small enemies → Boss

The demo intentionally ignores route/story progression on startup.

## Encounter flow

Awakening
→ Cultist A
→ Pale Hound
→ Cultist B
→ Ash Gate
→ Ashen Knight

The Boss does not spawn until all three small enemies are defeated.

## Controls

- A / D — move
- Space — jump
- J / Left Mouse — attack
- K / Shift — dodge
- F3 — toggle debug
- F9 — clean reset

## Combat direction

The combat pass is intentionally guided by two broad references:

**Hollow Knight** — responsive horizontal movement, deliberate spacing, compact attack ranges, quick dodge/position correction, and enemies that communicate their attack timing clearly.

**Blasphemous 2** — heavier attack commitment, stronger hit presentation, dark religious silhouettes, and boss encounters that become more aggressive through phase changes.

For Nereis Hero, these references are translated into a small original ruleset: three-step hero attacks, short attack windups, enemy telegraphs, hit-stagger, knockback, dodge invulnerability, and a two-phase boss.

The goal is to make every successful hit feel intentional before the project grows beyond the current single combat route.

## Acceptance

1. Move left/right and jump.
2. Attack small enemies.
3. Dodge incoming attacks.
4. Receive damage and die.
5. Respawn from the checkpoint.
6. Defeat three small enemies.
7. See the Ash Gate open.
8. Fight the Ashen Knight.
9. Defeat the Boss.
10. See CORE COMBAT DEMO COMPLETE.

## Runtime limitation

The current maintainer environment does not have Godot Runtime available, so code-level and repository-level checks are performed here. Local Godot 4.6.x execution remains the final acceptance gate.
