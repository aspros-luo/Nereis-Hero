# Momohime Texture Rig Prototype

## Source asset intake

The uploaded source set is intended for `assets/art/hero_sprite_lab/`:

- `153143.png` — full sprite sheet, 2048×1945 RGBA.
- `momohime_texture_atlas.png` — packed body-part texture atlas, 2048×2048 RGBA.
- `momohime_texture_atlas_original.dds` — original DDS texture, 1024×1024, DXT3.

The sprite animation lab now expects the true uploaded sprite-sheet dimensions and uses a provisional 204×243 grid. This is only a first-pass grid: row/column boundaries and the idle/walk/slash labels must be visually verified against the source art before being considered final.

## Rig strategy

1. Use the sprite sheet to verify reference poses and timing for idle, walk, and slash.
2. Inspect the packed atlas and map individual head/hair, torso, sleeve, hand, skirt, leg, footwear, and weapon pieces.
3. Build a texture-backed rig in the isolated lab scene. Keep layers separate and set pivots/overlap deliberately.
4. Compare the rig against source poses. If a body part cannot be isolated cleanly, prefer sprite-frame animation for that motion over stretching a badly cut texture.
5. Do not replace the production Hero until the standalone scene has passed visual and runtime acceptance.

## Binary file status

The binary files were received in the conversation, but the available GitHub connector can only write UTF-8 text and cannot upload arbitrary binary blobs from those local attachments. Therefore, do not assume the three images are already committed. Copy the three files from the provided asset bundle into the directory above and commit them on `feature/hero-animation-system`. The original DDS is retained separately from the PNG because the dimensions and compression differ.
