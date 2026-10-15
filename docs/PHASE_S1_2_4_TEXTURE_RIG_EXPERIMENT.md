# S1.2.4-B1 — Atlas inspection before character assembly

## Purpose / 目的

The supplied texture atlas contains many mixed character parts (heads, hairstyles, clothing, armor, hands, legs, and weapons). Do not infer a coherent character by selecting arbitrary rectangular crops. The first task is to identify compatible pieces and record their exact atlas bounds.

提供的纹理图集混合了多组角色零件（头部、发型、服装、护甲、手部、腿部和武器）。禁止继续通过猜测矩形坐标来拼装角色。第一步应先识别相互匹配的零件并记录准确边界。

## Local-only asset / 本地素材

Copy the atlas locally to:

`res://assets/art/hero_sprite_lab/muramasa_texture_atlas.png`

Do not commit the third-party atlas to GitHub. This helper intentionally references the local path only.

## Run / 运行

1. Open `res://scenes/debug/hero_atlas_inspector.tscn`.
2. Press **F6**.
3. Use the mouse wheel to zoom; right-click resets the view.
4. Drag with the left mouse button around one part. The selection rectangle shows its bounds; the Output panel prints the original 2048×2048 crop as `Rect2(x, y, width, height)`.
5. Use the grid and drag rectangles tightly around candidate parts. Record which pieces belong to one coherent character before editing the texture rig.

## Controls / 操作

- Mouse wheel: zoom in/out / 滚轮缩放
- Left drag: select a part and print crop bounds / 左键拖框选择零件并输出裁切边界
- Right click: reset zoom / 右键重置缩放

## Next stage / 下一阶段

Once matching head, torso, arms, legs, and weapon regions are identified, assemble a static character first. Prefer Polygon2D with explicitly traced UV regions when a piece is irregular; use rigid Sprite2D parts for equipment or pieces that should not deform. Only after the silhouette and proportions look coherent should parts be attached to the existing Bone2D rig.

确认同一角色的头部、躯干、手臂、腿部和武器区域后，先制作静态拼装。形状不规则的部件优先使用 Polygon2D 和明确勾勒的 UV 区域；不需要变形的装备可继续使用独立 Sprite2D。静态轮廓和比例通过验收后，再绑定现有 Bone2D 骨骼。

## Validation status / 验证状态

- Repository source files created and committed.
- Godot runtime validation has **not** been performed by the connected session. Run this scene locally in Godot 4.6.1 and check Output for parse/runtime errors.
