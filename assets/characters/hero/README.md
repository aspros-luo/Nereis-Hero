# Hero Temporary Visual Pipeline

## Purpose

Temporary character presentation before final art production.

The project uses a stick-figure style placeholder to validate:

- movement
- combat timing
- weapon readability
- dodge animation
- hit reaction

## Planned Structure

```
hero/
├── idle/
├── run/
├── jump/
├── attack_long_sword/
├── attack_short_blade/
├── dodge/
├── hurt/
└── death/
```

## Migration Goal

Current prototype rendering will be replaced by:

- AnimatedSprite2D
- AnimationTree
- Skeleton2D (future)

Gameplay code must not depend on visual implementation.
