# S1.2.2-A8 — Basic Action Quality / 基础动作质量

Date: 2026-10-14  
Branch: `development`

## Priority / 本轮优先级

Keep the prototype focused on the readability and coordination of three basic actions:
1. Run
2. Standard long-sword attack
3. Short-blade attack

Do not add heavy-long-sword progression, weapon clash, charged shield break, hitboxes, damage, stamina, or combo systems in this pass.

## Change in this pass / 本轮改动

- Prototype action inputs now use `Input.is_key_just_pressed()` for J, K, and Space. Holding a key no longer automatically queues/retriggers another action as soon as the current non-looping clip ends. Release and press again to test a new action.
- Existing action timings remain deliberately different: the long-sword clip has a longer anticipation/swing/follow-through/recovery arc; the short-blade clip remains quicker and more compact.
- No speculative attack-curve changes were made without a local visual reference. The next animation tuning should be based on side-by-side local playback, not source-code guesswork.
- Production `hero.gd` rendering and combat behavior remain untouched.

## Local acceptance / 本地验收

Open `res://scenes/characters/stickman_hero.tscn` in Godot 4.6.1 and run the current scene with F6.

1. Hold Left/Right or A/D: confirm the root moves and the alternating leg cycle remains readable.
2. Release movement: confirm the character settles into Idle with neutral legs.
3. Tap J: compare the longer anticipation, committed swing, follow-through, and recovery.
4. Tap K: confirm a visibly quicker, tighter action distinct from the long-sword silhouette.
5. Hold J or K across the end of the clip: confirm it does not automatically repeat. Release and tap again to play another strike.
6. Test both attacks while idle and while moving; inspect arm overlap, torso counter-rotation, head direction, and whether the legs appear planted rather than flailing.
7. Press F3 to compare the production-style outline with the technical bone overlay.
8. Repeat transitions Run → Attack → Run/Idle. Check for stale rotations or sudden pose snapping.

## Verification boundary / 验证边界

- GitHub connector writes are used to commit the source/documentation changes on `development`.
- This session cannot launch the local Godot 4.6.1 runtime, so parser/runtime success and subjective visual quality are not claimed as tested. Local playback is required before tuning attack curves further.
- This is an input reliability improvement and an acceptance checkpoint, not a declaration that final combat animation quality is complete.

## Next work / 下一步

Prioritize a side-by-side visual review of Run, LongSwordAttack, and ShortBladeAttack. Only then tune the specific phase curves and weapon/arm silhouette. Keep the stickman prototype isolated from the production Hero renderer until its movement and attack poses read clearly.
