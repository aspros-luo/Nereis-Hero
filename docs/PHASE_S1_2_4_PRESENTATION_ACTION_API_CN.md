# S1.2.4 — Formal Hero Presentation Action API

Date: 2026-10-19
Branch: `feature/hero-animation-system`

## Goal

Provide a small public presentation-only action interface for narrative beats without allowing story code to mutate the production rig's bones or gameplay state.

## Public Hero boundary

In `scripts/player/hero.gd`:

- `request_hero_presentation_action(action_name, duration = 0.65, priority = -1) -> bool`
- `clear_hero_presentation_action()`
- signal `presentation_action_finished(action_name)`

The request returns false when the skeletal visual is unavailable or the action name is unsupported. It returns true when accepted. Completion is emitted by the Hero boundary after the visual action expires naturally. Explicit clear/cancel does not emit a completion signal.

This API is presentation-only: it does not pause physics, lock player input, change hitboxes, alter damage/invulnerability, or change the Hero combat state. Narrative orchestration must explicitly own any gameplay input lock and release it on every success/cancel/scene-exit path.

## Supported action names

| Name | Purpose | Default priority |
|---|---|---:|
| `look_back` | Brief glance / hesitation | 10 |
| `exhausted_kneel` / `kneel` | Exhaustion or surrender beat | 30 |
| `stumble` | Loss of balance and recovery | 40 |
| `stagger` | Stronger recoil | 50 |
| `get_up` | Rise from a knocked-down pose | 70 |
| `knockdown` / `fall_down` | Collapse to the ground | 80 |
| `death` | Death presentation | 100 |

Higher-priority active actions reject a lower-priority request. Equal or higher priority may replace the active action. Pass an explicit priority to override defaults where the narrative contract needs a deliberate ordering.

A positive duration expires automatically and restores the latest live Hero-derived base pose. A duration of zero or less keeps the action active until `clear_hero_presentation_action()` is called. Persistent actions still advance their internal pose time so settle/rise animations can complete visually.

## Integration notes

- The adapter stores the latest live context pose as its base layer; a presentation action temporarily overlays it. Clearing or naturally completing the action returns to the latest base pose, not a stale pose from when the action began.
- The visual action does not move the `CharacterBody2D`, alter collision, or make the character physically kneel/lie down. If a scene requires the physical body to change location or collider, that must be a separately designed gameplay/cutscene operation.
- This first pass uses scripted bone poses, not AnimationPlayer clips. Do not drive the same bones through an AnimationPlayer at the same time.
- The production Hero retains the F8 legacy visual fallback until local runtime acceptance.

## Verification status

Source was committed to `feature/hero-animation-system`. This session did not have a Godot runtime attached to the remote repository operations, so parser/import, scene startup, action completion timing, visual quality, and combat interruption remain **not run**. Do not treat this interface as runtime-accepted until tested in the local Godot 4.6.1 project.
