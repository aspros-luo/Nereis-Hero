# Macro-Map Visual Polish — Phase 1

## Goal

Give A0, A2–A13, and H01–H08 readable environmental depth; A1 Village retains its existing houses, drain, rooftop route, and fireflies as a separate art pass while preserving box-world topology, platform collision, exits, Resonance conditions, and story state. This pass uses native Godot drawing rather than new textures or plugins, keeping iteration fast and avoiding missing-resource risk.

## Implemented in the game

- A0 surgical ward: cold light shafts, suspended cables, lamp halos, and sparse floor seams strengthen the oppressive experimental-facility mood.
- Distant silhouettes: tree crowns / organic ribs, city rooftops, fortress battlements, Gothic spires, tomb walls, or reservoir arches selected by region family.
- Low-contrast haze bands: restrained horizontal color layers add depth without obscuring playable platforms.
- Ground material cues: broken paving seams, sparse rubble, and a subtle floor edge reduce the flat-rectangle graybox appearance.
- Lightweight motion: an independent regional particle layer drifts dust/spores, lets battlefield ash fall, and makes Mirror Street rain rise; particle placement is deterministic to avoid random flicker.
- A13 terminal anomaly: fractured rings, suspended stair fragments, and a central monolith distinguish the ending space from ordinary city or Church architecture.
- Regional palettes: existing background, platform, and atmosphere colors remain distinct; collision and playable geometry are unchanged.
- Static guardrails: tools/validate_graybox_scene_wiring.py now checks that the shared atmosphere and ground-detail layers remain wired.

## Art rules

1. **Readability before detail.** Platform tops and exit interactions must remain more legible than decoration.
2. **Silhouettes must support geography.** Forests use crowns and organic forms; cities use roofs and broken walls; Church spaces use spires and arches; underground spaces use heavy walls, pipes, or ribs.
3. **Resonance is not a generic highlight.** Hidden routes should later use colder, unnatural contours, reflections, or spatial misalignment rather than illuminating every interactable.
4. **Do not change topology to solve an art issue.** Platform coordinates, exits, spawn points, and gate conditions stay fixed in this pass; solve occlusion through draw order or decoration density.
5. **Keep performance predictable.** Decoration uses a small number of deterministic vector primitives, with no per-frame random generation or texture loading.

## Next art pass

1. Have the user check that the shared silhouettes do not obscure platforms, enemies, exit prompts, or HUD.
2. Refine the visual language for A2 Ash Forest, A3 Forgotten City, A4 Old Reservoir, and A6 Monastery first.
3. Add dedicated Resonance visual states to A9 Rainy Outer Ring, A10 Great Cathedral, A11 Deep Research, H07 Mirror Street, and H08 Primordial Hollow.
4. Then refine character/enemy contrast, interaction prompt contrast, and environmental animation; avoid replacing all art assets at once.

## Acceptance boundary

This is the first procedural-art enhancement and has not yet received a local, per-region Godot visual acceptance pass. Use the macro-map test menu to inspect A2, A3, A4, A6, A9, A10, A13, H07, and H08. Report the region ID and screenshot if decoration obscures geometry or flickers.
