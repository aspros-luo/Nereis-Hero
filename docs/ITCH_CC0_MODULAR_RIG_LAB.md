# itch.io CC0 Modular Character Rig Lab

An isolated prototype for evaluating modular external character art before touching the production Hero.

## Source and licence

- Creator page: https://rgsdev.itch.io/free-cc0-modular-animated-vector-characters-2d
- Public raster archive: https://opengameart.org/content/free-cc0-modular-animated-vector-characters-2d
- The creator declares CC0-1.0 for the free raster PNG pack. The installer keeps included license/readme files in the local user-data folder.
- The installer does not commit third-party binary assets into this repository.

This pack is a cartoon character prototype, not the final visual direction of Nereis-Hero. It is used to test external part import, part-to-bone placement, and animation preview. We can replace it later with a more suitable dark-fantasy/ronin art pack without rewriting the rig workflow.

## Install and open

Run from the project root with Godot 4.6.1:

```sh
GODOT="/Users/aspros/Downloads/Godot.app/Contents/MacOS/Godot"
"$GODOT" --headless --path . --script tools/install_itch_cc0_modular_character.gd
"$GODOT" --path . res://scenes/debug/itch_cc0_modular_rig_lab.tscn
```

The installer downloads the public CC0 archive from OpenGameArt, extracts PNGs and license/readme files to the Godot user-data folder at `user://itch_cc0_modular_character/`, and writes `manifest.json`. It does not overwrite any file under `assets/characters/hero/`.

## Controls

- `1`: idle sway
- `2`: walk-cycle pose
- `3`: long-sword-style slash pose
- `4`: dodge-roll pose

## Implementation notes

- The lab searches asset paths for semantic names (body, head, left/right limbs, weapon, etc.) and creates an isolated `Skeleton2D` with `Bone2D` nodes.
- For recognized part paths, it crops transparent bounds while preserving full-canvas-relative placement, then attaches the texture to the corresponding bone.
- If the pack's exact path naming is not recognized, the lab logs selected/missing paths and displays a best-effort idle image next to the bone scaffold. This is a first integration pass, not a claim that every semantic part is already correctly identified.
- Do not merge this prototype into the production Hero until the local preview confirms silhouette, joint pivots, occlusion order and attack motion.

## Validation status

Repository-side scripts and an isolated scene are committed. Download and Godot runtime appearance still need validation on the user's Mac; no runtime pass is claimed.
