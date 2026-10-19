# Texture-Driven Bone Rig Prototype / 纹理驱动骨骼原型

Branch: `feature/hero-animation-system`

## Purpose

Use the existing Skeleton2D/Bone2D hierarchy as a motion rig, with the committed texture atlas as the primary source for visible character parts. The Momohime sprite sheet is visual reference only and must not be used to build the character or animation frames.

## Current state

- The scene `res://scenes/labs/momohime_bone_prototype.tscn` contains a hand-authored procedural placeholder using Polygon2D and Line2D.
- It demonstrates rough idle, walk and slash motion timing, but it is not a texture-backed character and should not be treated as final art.
- Existing atlas support is available through `CharacterPartData`, `CharacterAtlasTextureFactory`, and `hero_skeleton_texture_lab.tscn`.

## Next work

1. Analyze the actual atlas PNG and DDS rather than the sprite-sheet reference.
2. Determine whether the atlas contains separable 2D character parts or requires original mesh/UV data.
3. Record verified texture regions and pivots.
4. Replace placeholder visuals progressively with atlas-backed Sprite2D parts attached to the appropriate bones.
5. Validate silhouette, overlap, pivots and idle/walk/slash motion in Godot before considering production integration.

## Safety boundary

This prototype is isolated. Production Hero scenes, combat, hitboxes, stamina and damage logic remain unchanged. Godot runtime validation and visual acceptance have not yet been performed.
