# Hero Skeleton2D Rig / 主角骨骼原型

## Purpose / 目标
This is a rigid cutout prototype built with Godot `Skeleton2D` and `Bone2D`, not a full mesh-deformation rig. The character is rendered from SVG layers authored at a common 192x224 source canvas.

这是基于 Godot `Skeleton2D` 与 `Bone2D` 的分层拼接原型，不是网格变形骨骼。所有角色部件都使用同一张 192x224 原始画布。

## Anchors / 锚点
- Source feet anchor: `(96, 220)`.
- Root scale: `0.5`; each sprite layer preserves its original source coordinates.
- Main pivots: pelvis `(96,156)`; torso `(95,128)`; head/neck `(98,70)`; rear arm `(63,90)`; front arm `(120,91)`; rear leg `(70,160)`; front leg `(119,158)`; weapon hand `(128,111)`.

- 原图脚底锚点：`(96, 220)`。
- 根节点缩放：`0.5`，各部件保留原图相对位置；Sprite2D 的偏移始终为对应关节坐标的负值，避免每个状态单独调整渲染矩形。
- 主关节使用原始画布坐标定义；如更换素材，需保持画布尺寸和这些锚点，或同步更新骨骼坐标。

## Runtime animation / 运行时动作
The controller drives idle breathing, leg/arm swing, jump/fall poses, attacks, grappling, dodging, quick dash, wall-climbing, hurt and death. It only rotates visual bones; CharacterBody2D movement, hitboxes, hurtboxes, stamina, and combat timing remain in `hero.gd`.

动画控制器驱动待机、跑动、跳跃、下落、攻击、钩爪、闪避、快速冲刺、攀墙、受伤和死亡姿态。它只控制视觉骨骼，不改变角色碰撞体和战斗逻辑。

## Source-art decision / 素材取舍
The supplied `153143.png` is a complete-character frame atlas, not separated body pieces, so using it as one Sprite2D would retain the alignment issue and cannot produce useful rigid Bone2D motion. The new rig therefore uses the game's existing dark-knight SVG paths as the first working layered prototype. The two `tex1_...` texture files have not yet been inspected at pixel level; they are not silently treated as bone parts.

你提供的 `153143.png` 是整角色动作图集，并未按头、躯干、四肢分层。直接把整张图作为 Sprite2D 仍然会有偏移，也无法产生有效的刚性骨骼运动。因此本轮先用游戏已有的哥特骑士 SVG 路径制作可运行的分层骨骼原型。两张 `tex1_...` 纹理尚未完成像素级检查，本轮不会擅自将它们当作骨骼部件。
