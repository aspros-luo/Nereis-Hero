# Texture-Driven Hero Rig Plan

## Primary source of development

The primary source for character assembly is the committed texture atlas:

- `assets/characters/hero/tex1_512x512_4d6c36bcbd5d9ddc_423915aa39e773f2_9.png`
- `assets/characters/hero/tex1_512x512_544f6621d3d7aae2_f32cd14fd4d9e265_9.dds`

The image `assets/characters/hero/153143.png` is reference material for visual style and motion only. It must not drive development frame selection, animation playback, rig assembly, or acceptance tests.

## Current implementation state

- `scenes/labs/momohime_bone_prototype.tscn` is the isolated bone-motion experiment, but its current body parts are procedural Polygon2D/Line2D placeholders. It is not the desired final implementation.
- `scenes/player/hero_skeleton_texture_lab.tscn` and `scripts/character/character_atlas_texture_factory.gd` are existing atlas inspection / texture-part infrastructure and should be reused rather than duplicated.
- `scripts/character/character_part_data.gd` already stores atlas region, local pivot offsets, scale, rotation, draw order and enable state.
- The redundant sprite-sheet playback prototype and its alpha-band analyzer were removed. The sprite sheet remains reference-only; it is not a development dependency.

## Next implementation path

1. Inspect the PNG atlas dimensions, alpha channel, color regions and candidate texture islands directly. Check whether the DDS is the same texture and whether Godot can load it reliably.
2. Build an atlas-first analysis report for the texture atlas, not the reference sprite sheet. Detect candidate connected regions where alpha separation makes this meaningful; retain a confidence/ambiguity note for touching islands.
3. Visually identify compatible pieces and record exact source rectangles. Do not label arbitrary rectangles as complete limbs without evidence.
4. Use `CharacterPartData` and `CharacterAtlasTextureFactory` to render selected regions on bone-attached Sprite2D nodes. Set pivots and draw order deliberately.
5. Keep the existing skeleton motion study as a rig test, replacing procedural body-color shapes incrementally with atlas-backed parts. Avoid replacing all parts at once before checking silhouette and pivot alignment.
6. Run the isolated scene in Godot 4.6.1 and inspect idle, walk, slash, facing direction, texture loading and draw order before considering production integration.

## Acceptance boundary

No claim is made that the atlas has already been semantically segmented or that a texture-driven rig has passed runtime validation. Production Hero scenes and combat logic remain unchanged until the isolated texture rig is visually accepted.
