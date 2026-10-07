# Nereis Hero

A 2D Soulslike action RPG set in the Nereis universe.

## Vision

A dark fantasy / cosmic horror action RPG told from the hero's perspective. The game explores the conflict between survival, faith, memory, and humanity.

The game is designed as a shared-universe counterpart to **Nereis Lullaby**: that project follows Mite/Nereis and the village, while **Nereis Hero** follows the amnesiac Hero through the church, ruined roads, settlements, and the forces behind the disappearances.

## Current Phase

**Vertical Slice 001 — playable systems foundation**

Current slice route:

Awakening → Old Hunter → First Memory → Checkpoint → Cultist → Ash Gate → Ashen Knight → First Choice → Exit

The slice now includes:

- Hero movement, jump, attack and dodge
- Combat state machine foundation
- Reusable Hitbox / Hurtbox system
- Enemy AI and Mini Boss
- Horizontal camera-driven level
- NPC interaction and narrative event
- Checkpoint + death respawn
- Boss gate progression
- Post-boss narrative choice
- Automatic save/load
- Runtime diagnostic logging and F3 debug overlay
- F9 clean-run reset for local testing

## Engine

Godot 4.6.x / GDScript / GL Compatibility.

## Repository

Development happens on the `development` branch in small, reviewable commits. `main` is kept as the stable branch while the vertical slice is being built.
