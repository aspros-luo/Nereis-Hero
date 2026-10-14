# Nereis-Hero Character Rendering Pipeline / 角色渲染管线

## Decision

Nereis-Hero uses a hybrid character rendering strategy.

- Skeleton2D: Hero, major NPCs, bosses, elite enemies with complex animation requirements.
- Sprite/AnimationPlayer: common enemies, background NPCs, disposable characters.

## Reason

A full Skeleton2D pipeline for every character increases production cost unnecessarily. However, important characters need reusable animation, weapon attachment, phase changes and expressive movement.

## Categories

### Skeleton2D

- Hero protagonist
- Main story NPCs
- Boss characters
- Selected elite enemies

Benefits:

- Weapon socket support
- Reusable humanoid rig
- Better attack and hurt animation control
- Easier boss phase transformation

### Sprite based

- Common monsters
- Background villagers
- One-time narrative characters

Benefits:

- Lower art cost
- Faster iteration
- Suitable for high quantity assets

## Base Rig Direction

The Hero skeleton should be designed as a reusable humanoid base rather than a one-off character rig.

Future reusable targets:

- Church knights
- Human bosses
- Important NPCs
- Elite humanoid enemies

## Migration Order

1. Complete Hero Skeleton2D integration.
2. Stabilize humanoid rig structure.
3. Add weapon attachment points.
4. Reuse rig for important characters.
5. Keep ordinary enemies on lightweight pipeline.
