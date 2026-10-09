# 首版特殊战技测试报告 / First-pass Special Technique Test Report

Date: 2026-10-09  
Branch: `feature/protagonist-system`

## Scope

- Long Sword — Judgment Slash / 断罪斩
- Short Blade — Crescent Combo / 残月连斩
- Eldritch ability — Eldritch Echo / 余响
- Debug controls: F3 world-state panel, F4 Hero-local panel, F5 session-only all-ability override, F6 resource/cooldown reset

## Static checks performed

- [x] F/R special-technique inputs are ignored during an active attack, dodge, hurt reaction or death state, preventing stale requests from firing after the action ends.

- [x] Judgment Slash and Crescent Combo use dedicated weapon-technique visual effects rather than the generic basic-attack arc.
- [x] Crescent Combo stages have different silhouettes while retaining the same weapon identity.
- [x] Slash effects fade using remaining lifetime, avoiding premature disappearance during the first half of the animation.

- [x] F input is routed to the weapon-bound technique.
- [x] R input is routed to Eldritch Echo.
- [x] Long Sword maps to Judgment Slash; Short Blade maps to Crescent Combo.
- [x] Crescent Combo has three separately timed hit windows and reactivates the hitbox for each stage.
- [x] Technique stamina checks occur before costs are applied.
- [x] Eldritch Echo checks unlock state, stamina and cooldown before activation.
- [x] Echo only checks nearby nodes in the combat-enemy group.
- [x] Cultists receive a short stagger; the Ashen Knight caps the effect to a much shorter duration.
- [x] Debug override is stored on the Hero instance only and does not call WorldState unlock/save methods.
- [x] New ability IDs are accepted by the WorldState unlock registry.
- [x] Technique names and controls exist in Chinese Simplified, Chinese Traditional, English and Japanese.
- [x] Static checks found no duplicate function declarations in `hero.gd`.

## Runtime status

**Not run.** The current execution environment does not have a Godot executable, and the repository cannot be cloned into this environment because outbound DNS/network access is unavailable. No claim is made that the project starts or that the combat has been runtime-verified.

## Manual Godot verification checklist

1. Start the project normally and enter a combat scene.
2. Press F4 to show the Hero-local debug panel, then F5 to enable the all-ability session override.
3. With the Long Sword selected, press F and verify one heavy hit, 20 stamina cost, and the recovery window.
4. Press Q to switch to the Short Blade; press F and verify three distinct hit windows, 16 stamina cost, and no duplicate hits inside a single window.
5. Press R near a cultist and verify the pulse, 28 stamina cost, brief enemy interruption and an approximately 8-second cooldown.
6. Press R near the Ashen Knight and verify the boss is interrupted only briefly rather than being locked down.
7. Press F6 and verify HP/stamina/cooldown reset; verify Witch Time, Grapple, Resonance Sight, current action and hitbox are cleared.
8. Turn off F4 and verify locked techniques stop working. Restart the game and verify the override did not persist.
9. Repeat while receiving damage, opening the menu, dying and changing scenes to ensure no stale hitboxes or queued technique inputs remain.

## Initial tuning values

- Judgment Slash: 20 stamina, 1.6x damage, 0.35s windup, 0.14s hit window.
- Crescent Combo: 16 stamina, 3 hits at 0.08/0.23/0.38s, each initially 0.65x damage.
- Eldritch Echo: 28 stamina, 8s cooldown, 0.16s windup, 185px radius; boss stagger capped to 0.12–0.15s.

These are prototype values and must be adjusted after runtime playtesting.


## 2026-10-09 — Visual polish pass (source-level)

- [x] Rebuilt Judgment Slash as a layered silhouette: ink-dark undercut, warm steel body, bright edge, restrained gold sparks.
- [x] Rebuilt Crescent Combo with three clearly different shapes: low horizontal cut, rising cut, and a broader crossing finisher.
- [x] Reworked Eldritch Echo into expanding broken rings, irregular rune-like spokes, and a visible dark core.
- [x] Reworked hit sparks into a bright diamond core and tapered shards, using deterministic per-instance variation.
- [ ] Runtime art review: verify readability at the actual game camera zoom and on both dark and bright backgrounds.
- [ ] Runtime combat review: confirm the larger silhouettes do not obscure enemy tells or make hitboxes feel larger than they are.

**Verification note:** these are procedural Godot drawing changes, not imported raster assets. Source-level checks are possible here; Godot rendering/runtime review remains pending.


## Character silhouette pass

- [x] Hero renderer now uses layered armor plates, cloak folds, helmet/visor, rivets, gauntlets, boots, and a clearer blade/guard silhouette.
- [ ] In-game review: confirm the new drawing reads at normal camera zoom and remains clear during movement and both weapon stances.


## Enemy silhouette pass

- [x] Cultist: ragged layered robe, hooded ritual mask, red visor, chest seal and telegraph arc.
- [x] Ashen Knight: heavy layered plate armor, helmet visor, greatsword, and a phase-two unnatural crown.
- [ ] Runtime review: verify both enemies remain readable at gameplay scale, especially health labels and wind-up telegraphs.


## 2026-10-09 — Original art integration / 原创美术接入

- [x] Added original scalable SVG sprites for Hero long sword / short blade, Mite, Cultist and both Ashen Knight phases.
- [x] Added authored SVG VFX for Judgment Slash, all three Crescent Combo stages, Eldritch Echo and hit sparks.
- [x] Wired textures into the existing render methods without intentionally changing collision, hitboxes, damage, AI, movement or technique timing.
- [x] Added bilingual art pipeline and provenance/license ledger.
- [x] Source-level consistency checks: preload paths, draw function uniqueness, key combat methods and effect cleanup checked.
- [ ] Godot 4.6 runtime review: SVG import, texture loading, facing flip, sprite anchors, labels, combat readability and scene transitions.

**Runtime status: NOT RUN.** These assets are committed to the feature branch, but the current maintainer environment has no Godot executable. Local playtesting is required before calling the art sample accepted.


## Traversal and perception regression / 位移与感知能力回归

- [x] Quick Dash uses a separate non-invulnerable state and cooldown.
- [x] Witch Time uses enemy-only delta scaling; it does not scale the Hero's physics delta.
- [x] Grapple requires an explicit `grapple_anchors` target and times out/cancels when the target disappears or is reached.
- [x] Wall climb/wall jump require the `wall_climb_surfaces` group.
- [x] Resonance Sight reveals nodes in `resonance_hidden_targets` according to resonance / ancient exposure / outer exposure thresholds.
- [x] PageUp/PageDown chooses one of four iaijutsu forms in-session only while F5 override is enabled.
- [x] Debug iaijutsu abnormal load is session-only; it is never written to the save.
- [ ] Godot runtime: verify enemy windups/movement actually slow under Witch Time and restore afterward.
- [ ] Godot runtime: verify Grapple respects solid collision and cancels cleanly against blocked/removed targets.
- [ ] Godot runtime: verify wall slide/climb/jump does not bypass non-marked walls or scene boundaries.
- [ ] Godot runtime: verify temporary Sight reveals/hides fixtures at timer expiry and never modifies story/save flags.
- [ ] Godot runtime: verify selecting each form changes actual costs, hitbox, damage and VFX as intended.

### Quick test controls

`G` grapple; hold `W` to climb a marked wall; `Space` to wall-jump; `V` Resonance Sight; `X` Quick Dash; `K`/`Shift` ordinary dodge. With F5 enabled, `PageUp`/`PageDown` selects `human_iaijutsu`, `blood`, `abyssal`, or `black_horizon`, then press `L` to use the selected profile. All form selection and load accumulation are session-only.
