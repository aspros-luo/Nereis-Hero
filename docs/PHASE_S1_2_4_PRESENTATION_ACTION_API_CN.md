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

## Local debug testing

Run the project with a debug/editor build and enter a scene containing the production Hero. These shortcuts are handled by the Hero script only when `OS.is_debug_build()` is true:

| Key | Action |
|---|---|
| F9 | Stagger, 0.8 s |
| F10 | Exhausted kneel, 1.2 s |
| F11 | Look back, 1.0 s |
| F12 | Stumble, 0.8 s |
| F13 | Knockdown pose (persistent visual overlay) |
| F14 | Get-up pose, priority 90 |
| F15 | Death pose (visual only; does not set gameplay state to DEAD) |
| Delete | Clear persistent/current presentation overlay |

F13/F15 are visual-only pose tests; they do not change health, collision, death state, or physics. Delete clears the presentation overlay. F8 still switches between skeletal and legacy procedural visuals, so use it to compare silhouette and verify the fallback.

Suggested sequence:
1. Press F9, wait for automatic restoration, then walk/run/jump to check that the live pose resumes.
2. Press F13, then F14 to test higher-priority replacement; press Delete to cancel and restore live context.
3. Press F15, then Delete. Confirm that the gameplay character is not actually dead.
4. Repeat while facing left and right, then repeat during movement/attack to observe interruption behavior.
5. Toggle F8 before and after the same tests to compare skeletal presentation against the fallback.

If WorldState input locking is active, the existing early return in `_input()` prevents these debug shortcuts from firing. Unlock the scene/gameplay input before testing.

## Verification status

Source was committed to `feature/hero-animation-system`. This session did not have a Godot runtime attached to the remote repository operations, so parser/import, scene startup, action completion timing, visual quality, and combat interruption remain **not run**. Do not treat this interface as runtime-accepted until tested in the local Godot 4.6.1 project.
