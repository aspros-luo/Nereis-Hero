# Rendering / Draw Audit — Nereis-Hero

Date: 2026-10-15  
Branch: `development`  
Scope: source-level inventory of GDScript files that define `func _draw()`. This is a classification pass, not a runtime scene-instance count.

## Summary / 摘要

- The repository currently contains **103 GDScript files**.
- **65 scripts define `_draw()`**. This does **not** mean 65 scenes must be converted to sprites or skeletal rigs.
- The production Hero already defaults to the skeletal renderer. The old Hero illustration remains in `scripts/player/hero.gd::_draw()` as an explicit rollback path; the same method also keeps the shadow, HP/stamina readout, combo readout, invulnerability hint, resonance marker and combat feedback arcs.
- The correct policy is to migrate character-body placeholders and large environment greyboxes when proper art assets are ready, while retaining lightweight procedural drawing for transient effects, debug overlays, world markers and simple interaction affordances.

## Inventory by responsibility / 按职责分类

| Category | Scripts with `_draw()` | Count | Recommended treatment |
|---|---|---:|---|
| Hero legacy body + retained HUD/combat overlay | `scripts/player/hero.gd` | 1 | **Already bypassed during normal play** because the skeletal renderer is enabled by default. Keep as rollback only through the current local acceptance checkpoint; remove the old body block after the new presentation passes full gameplay acceptance. Keep UI/feedback in a separate visual component when that cleanup happens. |
| Enemy placeholder bodies | `scripts/enemies/ashen_knight.gd`, `bell_wraith.gd`, `church_inquisitor.gd`, `cultist.gd`, `experiment_warden.gd`, `final_cultist.gd`, `high_priest.gd`, `king_guardian.gd`, `pale_hound.gd`, `research_husk.gd` | 10 | Replace incrementally by enemy archetype with reusable visual scenes/rigs or authored sprites. Do not rewrite enemy AI/combat scripts merely to change rendering. |
| NPC placeholder bodies | `scripts/npc/bell_keeper.gd`, `final_mite.gd`, `mite.gd`, `old_hunter.gd` | 4 | Migrate to reusable character presentation scenes; keep schedule, dialogue and interaction logic separate from appearance. |
| Migrated body with retained UI/telegraph drawing | `scripts/enemies/bandit_raider.gd`, `scripts/npc/route_npc.gd` | 2 | Their character silhouettes now come from `scenes/characters/humanoid_character_visual.tscn`; `_draw()` remains only for the combat telegraph/label or NPC name/interaction prompt. These are the first reusable-rig migration pilots. |
| Character prototype / target / weapon presentation | `scripts/characters/stickman_skeleton_controller.gd`, `stickman_training_dummy.gd`, `stickman_visual.gd`, `stickman_weapon_visual.gd` | 4 | Prototype-only. Keep isolated from the production Hero. Replace the prototype dummy only when the combat-test scene receives production training-target art. |
| Environment and level composition | `scripts/core/world.gd`; `scripts/levels/ancient_research_lab.gd`, `church_final_demo.gd`, `combat_demo.gd`, `ending_fire_demo.gd`, `ending_paradise_demo.gd`, `escape_prologue.gd`, `greybox_world_region.gd`, `interior_scene.gd`, `mite_house.gd`, `mite_resonance_demo.gd`, `rebel_camp.gd`, `route_scene.gd`, `village_defense_demo.gd`, `village_graveyard.gd`, `village_hub.gd` | 16 | These are mostly procedural backgrounds, architecture and greybox set dressing. Migrate per region to TileMapLayer/scene props/parallax textures as environment art is approved. Keep geometry/collision separate from decorative art. `greybox_world_region.gd` is especially large and should be split by responsibility before replacing its drawing. |
| Transient effects / ambience | `scripts/effects/ash_particles.gd`, `death_burst.gd`, `echo_pulse.gd`, `hit_spark.gd`, `region_ambience.gd`, `slash_arc.gd`, `village_fireflies.gd` | 7 | **Keep for now.** These are procedural, short-lived or low-cost effects; replace only when an authored effect provides a clear quality/performance benefit. |
| Debug visualization | `scripts/debug/hero_atlas_inspector.gd`, `scripts/debug/skeleton_visual_debug.gd`, `scripts/systems/debug_traversal_wall.gd` | 3 | Keep debug-only and ensure they are not accidentally enabled in normal release scenes. |
| UI / map overlay | `scripts/ui/world_map_overlay.gd` | 1 | Keep custom drawing unless the map UI is deliberately migrated to reusable Control nodes. |
| World props, interactables and hidden-route markers | `scripts/systems/grapple_anchor.gd`, `resonance_hidden_target.gd`; `scripts/world/boss_gate.gd`, `checkpoint.gd`, `interaction_door.gd`, `interior_clue.gd`, `interior_exit.gd`, `level_exit.gd`, `resonance_local_route.gd`, `resonance_secret_gate.gd`, `resonance_source_clue.gd`, `rest_point.gd`, `route_exit.gd`, `route_memory_echo.gd`, `third_cord_fragment.gd`, `village_poi.gd`, `world_clue.gd` | 17 | Usually acceptable for simple interaction markers, gates and clue glyphs. Convert complex permanent architecture to reusable scenes/art; do not turn every marker into a texture asset without a need. |

The counts above sum to 65 scripts with `_draw()`.

## Recommended migration order / 建议迁移顺序

1. **Hero (current checkpoint):** keep the skeletal renderer as the only normal-play character body. Complete local acceptance for idle/run/jump/fall/land, dodge/dash, both weapons, weapon techniques, grapple/wall climb, hurt/death, facing both directions, hitboxes and UI. Until that passes, retain the old body only as rollback.
2. **Separate rendering from gameplay:** when the Hero rollback is removed, move HUD/combat-feedback drawing out of `hero.gd` into a presentation component rather than leaving presentation code in the gameplay controller.
3. **Enemy/NPC visual architecture:** a reusable `HumanoidCharacterVisual` scene and `Skeleton2D`/`Bone2D`/`Line2D` presentation component now exist. The route NPC and bandit raider are the first pilots; their gameplay logic, hitboxes, interaction flow and combat telegraphs remain in their owning scripts. Extend the same component to other humanoid NPCs/enemies only after local visual acceptance.
4. **Environment greyboxes:** migrate one region at a time. Use TileMapLayer/scene props/parallax assets for persistent geometry and scenery; retain collision/navigation ownership in the level/world layer. Prioritize the oversized `greybox_world_region.gd` for decomposition.
5. **Leave purposeful drawing alone:** UI overlays, hit sparks, slash arcs, fireflies, resonance glyphs and debug guides are not legacy character renderers. They do not need blanket replacement.

## Current migration checkpoint / 当前迁移节点

- Added `scripts/characters/humanoid_character_visual.gd` and `scenes/characters/humanoid_character_visual.tscn` as a reusable, gameplay-independent rig. It builds its silhouette from bone-attached `Line2D` segments and a `Polygon2D` head; the body renderer itself does not define `_draw()`.
- Migrated `scripts/npc/route_npc.gd` and `scripts/enemies/bandit_raider.gd` to instantiate that rig. Their `_draw()` methods retain only labels/interaction prompts and the bandit's windup telegraph.
- This is a source-level pilot only. Godot 4.6.1 parser/runtime validation and the combat/interaction smoke test remain outstanding.

## Acceptance gates / 验收门槛

- Godot 4.6.1 project opens with no parser errors.
- Production Hero is visible in the default boot path and no duplicate body is rendered.
- All movement, combat, traversal, invulnerability and respawn behavior remains unchanged.
- HP/stamina/combo display, hit-confirm feedback, resonance marker and swing feedback remain visible.
- The old procedural body can be removed only after the above has been confirmed locally; no source-only check should be reported as a runtime pass.
- The audit count is source-based. A script may be used by multiple scenes, so it is not a count of unique runtime scene instances.
