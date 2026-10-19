# Momohime Sprite Prototype / 百姬精灵原型

## Goal / 目标
A standalone Godot 4.6 scene to inspect and play provisional idle, locomotion, and sword-slash sequences from the user-selected Momohime sprite sheet. It does not modify or replace the production Hero.

## Source / 素材
- Page: https://www.spriters-resource.com/wii/muramasathedemonblade/asset/153143/
- Direct image: https://www.spriters-resource.com/media/assets/150/153143.png?updated=1755483767
- Listed size: 2560×2432 PNG.
- Local path expected by the scene: `res://assets/art/hero_sprite_lab/153143.png`
- Download the PNG from the source page and place it at that path. The binary has not been committed by this change.

## Initial grid hypothesis / 初始网格假设
The published preview suggests 10 columns × 8 rows with 256×304 cells (2560×2432). This is a working hypothesis, not a claim that all cells are populated or that each row is a single animation. The scene validates the loaded dimensions before playing.

## Provisional sequence mapping / 暂定动作分类
- Idle: row 0, columns 0–9.
- Walk/motion: row 2, columns 0–5.
- Sword slash: row 4, columns 0–9 (the row visibly containing slash/effect poses).

These are provisional visual groupings from the page preview. Verify the full-resolution source and alpha bounds before treating them as accepted final sequences. If inspection shows different bounds, update the sequence table; do not silently stretch the cells into a false animation.

## Run / 运行
Open `res://scenes/labs/momohime_sprite_prototype.tscn` in Godot 4.6.1 and run it.

- `1`: idle
- `2`: locomotion (provisional)
- `3`: sword slash (provisional)
- `Space`: pause/resume
- `Left/Right`: flip horizontally
- `R`: restart current sequence

## Acceptance gates / 验收条件
- [x] Independent scene and script; production Hero remains untouched.
- [x] Validate source image dimensions before playback.
- [x] Keyboard-selectable provisional sequences and frame stepping.
- [ ] Add the source PNG at the expected project path.
- [ ] Run in Godot 4.6.1; verify GDScript parses and frames render.
- [ ] Inspect each frame's alpha bounds and foot baseline; correct animation labels and sequence ranges.
- [ ] Verify idle, walk and first slash visually before integration.
- [ ] Wire movement and attack animation requests only after visual acceptance.
