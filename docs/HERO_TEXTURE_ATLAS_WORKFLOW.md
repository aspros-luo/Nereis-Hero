# Hero Texture Atlas Workflow / 主角纹理图集工作流

## Source priority / 素材优先级

The packed texture atlas is the primary development source:

- `assets/characters/hero/tex1_512x512_4d6c36bcbd5d9ddc_423915aa39e773f2_9.png`
- `assets/characters/hero/tex1_512x512_544f6621d3d7aae2_f32cd14fd4d9e265_9.dds`

`assets/characters/hero/153143.png` is a visual reference only. Do not use it as the animation implementation, frame-selection source, rig artwork, or acceptance dependency.

## Existing infrastructure / 现有基础设施

- `scenes/debug/hero_atlas_inspector.tscn`: existing coordinate/crop inspection tool.
- `scenes/player/hero_skeleton_texture_lab.tscn`: existing atlas and rig comparison lab.
- `scripts/character/character_atlas_texture_factory.gd`: creates `AtlasTexture` wrappers and applies `CharacterPartData` transforms to Sprite2D.
- `scripts/character/character_part_data.gd`: stores atlas region and per-part transform/draw settings.

Do not add another manual atlas inspector unless a concrete missing capability is demonstrated.

## Important limitation / 重要限制

An atlas rectangle is only a crop, not automatically a semantically complete body part. The correct interpretation must be based on the actual pixels, transparency, repeated visual patterns, and compatibility between parts. If the atlas is a UV/material atlas rather than a packed 2D parts atlas, its islands may require the source mesh/UV mapping. Do not fabricate limb shapes by blindly attaching arbitrary rectangles to bones.

## Implementation sequence / 实施顺序

1. Inspect the PNG atlas itself and record true dimensions and alpha properties.
2. Compare the DDS variant for matching dimensions/content and choose a runtime-supported source.
3. Detect candidate opaque islands and bounds; flag merged/touching regions rather than pretending they are cleanly separated.
4. Identify a coherent character set and record exact atlas rectangles and pivots.
5. Attach atlas-backed Sprite2D parts to the existing Bone2D hierarchy using `CharacterPartData` and `CharacterAtlasTextureFactory`.
6. Validate the isolated lab in Godot 4.6.1 before production integration.

## Validation status / 验证状态

The repository has the atlas assets and existing helper infrastructure. Texture-island segmentation, part-to-bone mapping, and runtime visual acceptance remain incomplete. No runtime pass is claimed.
