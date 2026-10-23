# Hero Texture Atlas Workflow / 主角纹理图集工作流

## Art source strategy / 美术素材策略

The existing packed texture atlas remains available as an optional source for future matching and UV research:

- `assets/characters/hero/tex1_512x512_4d6c36bcbd5d9ddc_423915aa39e773f2_9.png`
- `assets/characters/hero/tex1_512x512_544f6621d3d7aae2_f32cd14fd4d9e265_9.dds`

The reference image `assets/characters/hero/153143.png` is the visual prototype for silhouette, proportions, and movement language. It is not required to be the runtime texture or the only source of body parts.

The alternate-source experiment is documented in `docs/ITCH_CC0_MODULAR_RIG_LAB.md`. It installs a creator-declared CC0 modular character pack into Godot's user-data folder and builds an isolated `Skeleton2D` preview. This lets the rigging workflow be proven with external art rather than being blocked by the current atlas. The prototype pack's cartoon style is for workflow verification, not the final Nereis-Hero art direction.

## Existing infrastructure / 现有基础设施

- `scenes/debug/hero_atlas_inspector.tscn`: existing coordinate/crop inspection tool.
- `scenes/player/hero_skeleton_texture_lab.tscn`: existing atlas and rig comparison lab.
- `scripts/character/character_atlas_texture_factory.gd`: creates `AtlasTexture` wrappers and applies `CharacterPartData` transforms to Sprite2D.
- `scripts/character/character_part_data.gd`: stores atlas region and per-part transform/draw settings.

## Automatic candidate export / 自动候选素材导出

To avoid manually searching a large atlas, run from the repository root using the project's Godot 4.6.1 executable:

```sh
godot --headless --path . --script tools/split_hero_texture_atlas.gd
```

The script reads only the committed protagonist texture atlas PNG and writes files to Godot's user data directory under `hero_texture_parts/`. It does not modify the source asset.

Output layout:

- `components/component_001.png...`: crops around 4-connected opaque/partially opaque pixel components, sorted by pixel area.
- `grid/grid_0001.png...`: overlapping 64x64 crops, with 8 pixels of overlap, to expose details that touch or are not separated by transparency.
- `manifest.json`: source dimensions, exact source-space bounds, crop paths, component area and limitations.

Open the printed absolute output path after running the script. Use the component crops first for separated islands; use grid crops when an island is merged, touches another region, or appears to be part of a continuous texture. The grid deliberately overlaps so details near crop boundaries are not silently lost.

The component count is data-driven and should be read from the generated manifest; no count or semantic classification is claimed before the script is run. Crop bounding boxes can contain multiple visual details. These outputs are candidate regions, not automatically identified head/torso/arm/leg labels. Preserve the manifest coordinates when selecting regions so they can later be referenced by an atlas-backed part or polygon UV.

## Important limitation / 重要限制

An atlas rectangle is only a crop, not automatically a semantically complete body part. Correct interpretation should use actual pixels, transparency, repeated visual patterns, symmetry, and compatibility between parts. If the atlas is a UV/material atlas rather than a packed 2D parts atlas, its islands may require the source mesh/UV mapping. Do not fabricate limb shapes by blindly attaching arbitrary rectangles to bones.

## Existing analyzer / 原分析工具

For alpha statistics, connected-component bounds and PNG/DDS decoded-pixel comparison, run:

```sh
godot --headless --path . --script tools/analyze_hero_texture_atlas.gd
```

It writes `user://hero_texture_atlas_analysis.json`. The DDS is compared only if Godot can decode it and dimensions match; no resampling-based equivalence claim is made.

## Implementation sequence / 实施顺序

1. Run the candidate exporter and inspect component crops and overlapping grid crops.
2. Select plausible pieces by ID and source bounds; record semantic labels only after visual confirmation.
3. Decide whether the atlas is a packed 2D part atlas or a UV/material atlas. If it's the latter, search for original model/UV coordinates rather than guessing.
4. Build a static character assembly scene with movable/rotatable/scalable parts; do not replace the production Hero yet.
5. Once the silhouette and piece selection are confirmed, connect parts to the existing Bone2D hierarchy or construct Polygon2D contours/UVs for the pieces that need deformation.
6. Validate the isolated lab in Godot 4.6.1 before production integration.

## Validation status / 验证状态

The repository tree contains the PNG/DDS textures and existing 2D bone rig, but no source mesh/model or UV-coordinate asset was found in the inspected character-art paths. The candidate-export script has been committed, but it has not been executed in Godot in this environment. Therefore the generated crops, actual candidate count, semantic part selection, part-to-bone mapping, and runtime visual acceptance remain unverified. No runtime pass is claimed.
