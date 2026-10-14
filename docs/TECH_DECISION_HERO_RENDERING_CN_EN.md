# Hero Rendering Migration / Hero 渲染迁移

## Status

Phase S1.1 - Skeleton2D migration foundation.

## Problem

The previous Hero visual prototype relied on procedural polygon rendering through `_draw()`.
Godot runtime reported polygon triangulation failures during rendering:

`Invalid polygon data, triangulation failed`

This made the visual layer fragile.

## Decision

Move Hero visual presentation toward a Skeleton2D / Bone2D based pipeline.

Old:

```
Hero
 └── hero.gd
      └── _draw()
           └── draw_polygon()
```

New direction:

```
Hero
 └── Skeleton2D
      ├── Bone2D
      ├── visual attachments
      └── animation controller
```

## Responsibility split

Gameplay:

- movement
- stamina
- combat state
- hit detection
- damage

remain owned by Hero gameplay scripts.

Visual layer:

- pose
- animation
- bone transforms
- weapon attachment

is controlled separately.

## Next implementation steps

1. Replace remaining Hero body rendering dependencies.
2. Add Skeleton2D node into the playable Hero scene.
3. Attach weapon visuals through bones.
4. Convert attack/dodge/hurt states into animation-driven poses.
5. Remove obsolete polygon drawing paths after runtime verification.

## 验收目标

- 游戏启动无 draw_polygon 三角化错误。
- Hero 可以保持移动、攻击、闪避逻辑不变。
- 后续可以扩展长剑、短刃和动作动画。
