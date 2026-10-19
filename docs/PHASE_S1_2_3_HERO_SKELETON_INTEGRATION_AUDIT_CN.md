# S1.2.3 — Formal Hero Skeleton Integration Audit

Date: 2026-10-19
Branch: `feature/hero-animation-system`
Audited revision: `593e4928bf238c240df6c38bc18bb3a835e8ae53`

## Scope

Source-level audit of the production Hero controller, its skeletal presentation scene/controller, and the isolated stickman/AnimationPlayer prototype. This document records source findings only; it is not a Godot runtime acceptance report.

## Current architecture confirmed in source

- `scripts/player/hero.gd` remains the authority for movement, collision, stamina, attack windows/hitboxes, dodge invulnerability, damage interruption, death, grappling and wall traversal.
- The production Hero enables `res://scenes/player/hero_skeleton.tscn` by default through `use_skeleton_visual = true`. F8 is retained as a debug rollback switch to the legacy procedural body.
- The production visual rig is a `Skeleton2D` / `Bone2D` hierarchy rendered by `Line2D` and `Polygon2D` nodes created in `scripts/player/hero_skeleton_controller.gd`.
- The Hero supplies a read-only state snapshot through `get_visual_context()`; `HeroSkeletonController.apply_visual_context()` maps movement/combat state to visual poses. The adapter reads gameplay state and does not own gameplay rules.
- The standalone `scenes/characters/stickman_hero.tscn` prototype has a sibling `AnimationPlayer`, runtime Idle/Run animation library and rough one-shot weapon/dodge clips. It is a separate `CharacterBody2D` prototype and is not the production Hero scene.

## Findings and risks

### F1 — Two animation implementations are currently separate

The formal Hero uses scripted bone posing in `HeroSkeletonController._apply_pose()`; the AnimationPlayer clips described in the stickman prototype documentation belong to `StickmanHero`. Do not infer that the prototype's AnimationPlayer clips are playing on the production Hero.

**Impact:** production visuals can be state-driven, but clip authoring/blending and animation completion callbacks are not yet a shared production pipeline.

### F2 — The presentation adapter is state-snapshot driven

The Hero calls `apply_visual_context(get_visual_context())` each rendered frame. Direct calls such as `play_hurt()` or `play_death()` on the visual controller are not a stable external cutscene API while context-driven updates are active, because the next snapshot can select another pose.

**Impact:** story/map code must not manipulate internal bones or call prototype-only pose methods. A stable public action API needs explicit ownership, interruption priority, completion and restoration semantics before the story branch consumes it.

### F3 — Visual state is narrower than gameplay state

The visual snapshot exposes movement/combat state, facing, weapon, action timing, grounded/vertical velocity and selected combat flags. It does not expose a public action lifecycle or completion signal for bespoke story beats. Landing is currently inferred by the visual controller from the grounded transition rather than being a separate authoritative gameplay state.

**Impact:** short visual beats can be approximated from state, but choreography that depends on exact action completion should not rely on inferred timing.

### F4 — F8 fallback must remain until local acceptance

The old `hero.gd::_draw()` still contains the legacy body and additional HUD/combat feedback. The skeletal presentation is the normal body path, but the fallback and its related drawing code are intentionally retained for rollback.

**Impact:** do not delete the fallback or split the remaining draw responsibilities until the production rig passes local gameplay acceptance.

## Next implementation order

1. Keep `hero.gd` authoritative; do not duplicate physics, damage, stamina, invulnerability or hitbox logic in the rig.
2. Define a public, presentation-only Hero action contract for story beats (candidate semantics: stagger, exhausted/kneel, look back, stumble/fall, death/knockdown, get up). Specify who locks gameplay input, which gameplay events can interrupt an action, and how the visual returns to the live state.
3. Implement the action contract on the production visual adapter, not on the isolated stickman prototype. Keep the API callable through the Hero boundary; story code must not address Bone2D internals.
4. Decide deliberately whether production clips remain procedural poses or migrate to AnimationPlayer. Avoid having AnimationPlayer and per-frame pose code write the same bone properties simultaneously.
5. Only after the contract is stable, connect it to the story/map branch by a separately reviewed interface. Do not merge branches automatically.

## Verification boundary

- Confirmed by remote source inspection: file contents, node hierarchy, adapter call path, and ownership comments.
- Not run in this session: Godot parser/import, scene startup, physics, visual playback, input/cutscene interruption, collision/hitbox behavior, or frame timing.
- No Godot runtime test is claimed as passed. Local Godot 4.6.1 acceptance remains required before removing the rollback path or claiming animation quality is complete.
