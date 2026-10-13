# Nereis Hero AI Development and Design Principles

## Purpose

This document records the long-term collaboration principles for Nereis Hero development.

---

# 1. Godot 2D Engineering Principles

The project should be developed as a professional Godot 2D production project.

Core rules:

- Prefer Godot native systems when they are stable and maintainable.
- Evaluate community plugins before implementing large infrastructure manually.
- Use plugins when they improve production efficiency, editor workflow, debugging, tooling, dialogue, animation, asset pipeline, or content management.
- Avoid plugin dependency without maintenance value.
- Every external plugin must be evaluated for:
  - maintenance status
  - compatibility with Godot 4.6+
  - license
  - long-term project risk

The goal is not "maximum plugins", but a professional production pipeline.

---

# 2. Game Design Inspiration

The project studies excellent game creators and transforms their advantages into Nereis Hero's own identity.

## Hidetaka Miyazaki inspired principles

Apply:

- environmental storytelling
- fragmented narrative
- item descriptions as historical evidence
- NPC ambiguity and unreliable viewpoints
- ruins, architecture and objects as storytelling tools
- dark fantasy atmosphere with remaining human warmth

Avoid:

- meaningless obscurity
- lore without emotional connection

The player should discover, connect and interpret.

## Hideo Kojima inspired principles

Apply:

- interaction between player psychology and game systems
- meaningful fourth-wall experimentation
- mechanics that support themes
- emotional connection through player actions

Avoid:

- spectacle replacing gameplay

---

# 3. Vanillaware Inspired Visual Direction

Study and absorb:

- European medieval fantasy aesthetics
- mythology and folklore influence
- rich colors
- detailed lighting
- painterly 2D presentation
- elegant character silhouettes
- romantic fantasy atmosphere

Character design principles:

- memorable silhouettes
- strong artistic identity
- expressive animation

Food and daily-life details are important world-building elements.

Food is not only a system feature; it represents:

- human warmth
- civilization
- memories
- contrast against the dark world

---

# 4. Nereis Hero Identity

The final product should combine:

- Soulslike exploration depth
- Hollow Knight style discovery
- Vanillaware artistic romance
- Kojima-like mechanical storytelling
- Lovecraftian mystery

The goal is not imitation. These are design foundations transformed into the unique Nereis universe.

---

# 5. Development Decision Rule

Technical systems, tools, effects and normal gameplay implementation may proceed autonomously.

Stop and return to design discussion for:

- major world structure changes
- Hero/Mite relationship canon
- ending conditions
- core mythology decisions

---

Version: 2026-10-13
