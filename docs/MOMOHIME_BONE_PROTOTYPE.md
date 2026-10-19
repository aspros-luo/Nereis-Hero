# Momohime-inspired Bone Animation Prototype / 百姬风格骨骼动画原型

Branch: `feature/hero-animation-system`

## Purpose
An isolated `Skeleton2D` / `Bone2D` study to move toward a Momohime-like silhouette and readable sword action. It does not replace the production Hero or alter combat logic.

## Implemented in source
- Bone hierarchy for root, torso, head, long hair, both arms, sword hand, both legs and knees.
- Bone-attached layered Polygon2D/Line2D parts for hair, face, kimono, sleeves, skirt, socks and katana.
- Procedural Idle, Walk and Slash motion curves, including delayed hair/skirt/sleeve motion.
- Slash timing separates anticipation, committed cut, and recovery.
- Keyboard controls: 1 idle, 2 walk, 3 slash, Space pause/resume, Left/Right facing, R restart.

## Scene
Run `res://scenes/labs/momohime_bone_prototype.tscn` with Godot's Run Current Scene (F6).

## Important limits
- This is a hand-authored layered silhouette, not a claim that the source sprite sheet has been automatically rigged.
- It is an isolated visual prototype. Production `hero.gd`, hitboxes, stamina, damage and the rollback path are untouched.
- Godot runtime/parser and visual acceptance must be performed locally before this prototype is considered accepted. If the engine reports a property/API mismatch, fix that before further animation polish.
- The next quality pass should replace rough polygon proportions with approved, properly sliced character parts or a deliberately authored bone-weighted mesh; do not warp the whole sprite-sheet cell as one sprite.
