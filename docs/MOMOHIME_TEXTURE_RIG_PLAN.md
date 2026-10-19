# Momohime Texture Rig Prototype

## Committed source assets

The source files are now committed in `assets/characters/hero/` on `feature/hero-animation-system`:

- `153143.png` — Momohime animation sprite sheet (2048×1945).
- `tex1_512x512_4d6c36bcbd5d9ddc_423915aa39e773f2_9.png` — packed body-part texture atlas.
- `tex1_512x512_544f6621d3d7aae2_f32cd14fd4d9e265_9.dds` — original DDS texture.

These are source assets, not yet a completed rig. Keep original filenames so texture provenance and future comparisons remain clear.

## Current implementation

- The sprite-sheet lab now loads `res://assets/characters/hero/153143.png`.
- Current frame grid (204×243, 10 columns) is provisional; the frame boundaries and action labels still require visual verification.
- The existing Bone2D prototype is still a procedural placeholder and has not yet been converted to texture parts.

## Next steps

1. Analyze the PNG sprite sheet's alpha bounds and identify exact frame rectangles; don't assume equal-width cells without checking.
2. Inspect the PNG atlas and map candidate rectangles for head/hair, torso, sleeves, hands, skirt, legs, footwear, and weapons.
3. Determine whether the DDS is the same atlas in another format/resolution and inspect alpha/compression before choosing it as runtime source. Prefer PNG for the first Godot iteration.
4. Create atlas-backed `Sprite2D`/region textures and attach parts to bones with intentional pivots, draw order, and overlap.
5. Keep a source-pose sprite animation available as a visual reference for checking the rig.
6. Run the standalone lab in Godot and verify idle, walk, slash, mirroring, and resource loading before integrating into the production Hero.

## Acceptance boundary

Asset presence and script path have been verified from GitHub. No Godot runtime validation or final frame-segmentation validation is claimed yet. Production Hero scenes and combat logic remain unchanged.


## Texture prototype added

A separate texture-backed scene now exists at `res://scenes/labs/momohime_texture_prototype.tscn` with script `scripts/labs/momohime_texture_prototype.gd`. It loads the committed `assets/characters/hero/153143.png` directly and provides keyboard-selectable idle, walk, and slash test sequences. It does not depend on the polygon silhouette rig and does not modify production Hero.

Run this scene with F6. Controls: 1 idle, 2 walk, 3 slash, Space pause/resume, Left/Right facing, R restart.

Important: this is an interim source-texture animation viewer, not yet the requested part-by-part texture bone rig. The equal-cell grid and sequence mapping are still provisional. The next stage is exact alpha-bound segmentation and atlas-part mapping, then replace the placeholder polygon visuals in the bone prototype with texture-backed parts. Godot runtime validation has not been performed by the remote connector.


## Prototype cleanup and automatic analysis

- Removed the duplicate `momohime_sprite_prototype`; `momohime_texture_prototype` is the single sprite-sheet playback preview.
- Removed the duplicate `momohime_atlas_inspector`; use the existing `hero_atlas_inspector` / `hero_skeleton_texture_lab` for atlas inspection.
- Added `tools/analyze_sprite_sheet_alpha.gd`. It scans alpha occupancy and writes a JSON report containing occupied bounds and candidate row/column bands. Run it from the project root with:
  `godot --headless --path . --script res://tools/analyze_sprite_sheet_alpha.gd`
- The analyzer is a measurement aid, not a magical frame recognizer: connected poses and overlapping opaque pixels can merge bands, and it does not assign action labels. The output must be compared with the actual sheet before changing animation regions.
- No Godot runtime execution has been performed through the GitHub connector; the new script still needs a local Godot 4.6.1 run before it is considered validated.
