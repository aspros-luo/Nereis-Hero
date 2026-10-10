# Hero Polygon2D Skeleton Rig / 主角 UV 骨骼绑定

## Implementation / 实现

The live prototype uses a compact atlas derived from the user-provided RPG-Udemy texture. Every visible body part is a `Polygon2D` with explicit UV coordinates into the same texture. Each polygon is assigned to a `Skeleton2D` and a `Bone2D` path with four rigid vertex weights. This is a real texture-mapped skeleton deformation setup, not frame selection or independent whole-image sprites.

当前主角原型使用用户提供的 RPG-Udemy 纹理整理出的轻量部件图集。每个身体部件都是带明确 UV 坐标的 `Polygon2D`，共用同一张纹理，并绑定到 `Skeleton2D` 内对应的 `Bone2D`。每个部件的四个顶点都分配给目标骨骼，权重为 1.0，因此部件会绕关节刚性转动，而不是按整个人物帧图偏移。

## Rig hierarchy / 骨骼层级

- `Pelvis → Spine → Head`
- `Spine → LeftShoulder → LeftElbow → LeftHand`
- `Spine → RightShoulder → RightElbow → RightHand → Weapon`
- `Pelvis → LeftHip → LeftKnee → LeftAnkle → LeftFoot`
- `Pelvis → RightHip → RightKnee → RightAnkle → RightFoot`
- `Scabbard` is parented to the spine; hair follows the head.

## UV / 坐标

The compact source atlas is 112×73 pixels; its regions were mapped from the packed 320×207 working atlas using a fixed scale factor. All polygons use matching geometry/UV vertex order. The skeleton rest pose is captured after creating bones.

图集为 112×73 像素；UV 区域按固定比例从 320×207 工作图集映射而来。多边形几何顶点与 UV 顶点顺序一一对应。所有骨骼创建后都会记录初始 rest pose。

## Animation / 动画

Runtime bone rotations cover idle, move, jump, fall, attack, grapple, dodge, quick dash, wall-climb, hurt and death. The hero movement controller, hitboxes, stamina, damage and combat timings remain in `hero.gd`.

运行时骨骼旋转覆盖待机、移动、跳跃、下落、攻击、钩爪、闪避、快速冲刺、攀墙、受伤和死亡。主角位移、碰撞体、体力、伤害和战斗时序仍由 `hero.gd` 控制。

## Current limitation / 当前限制

This is the first UV/rig binding prototype. It uses rigid per-part weights (not smooth multi-bone skinning) so arms, legs, hair and equipment can pivot without drifting. The compact preview atlas is intentionally lower resolution than the source texture; after verifying the rig in Godot, the atlas can be regenerated at a higher resolution and the UV scale updated.

这是第一版 UV 与骨骼绑定原型。当前每个部件采用单骨骼刚性权重，而不是跨多个骨骼的平滑蒙皮，因此手臂、腿、头发和武器能按关节旋转且避免整体精灵漂移。当前图集分辨率低于原始贴图；待 Godot 实机确认关节位置后，再提升图集分辨率并同步 UV 比例。
