# ALL ENDINGS GUIDE

This guide describes the current development build behavior. It is intended for acceptance/testing before the final shipping flow is wired into the main story.

## Ending rules

The current ending evaluator uses three facts:

- No physical union -> 凡人之墓
- Physical union + fewer than 3 hidden artifact sources -> 永恒乐园
- Physical union + at least 3 hidden artifact sources -> 烈火天罚

Physical union happens when Mite has four unique relationship interactions recorded and the Hero rests at Mite's house.

## 1. 凡人之墓

Goal: finish the visible political story without reaching the physical union.

Recommended path:

1. Start a new game.
2. Meet Mite and interact with her fewer than four times.
3. Do not trigger the bed scene in Mite's house.
4. Avoid entering the Church before mite_stay_a_while if you still want Mite to remain present.
5. Progress the visible Church / Restoration conflict.
6. Return to the Village Hub.
7. In the current development build, press F1 in the Village Hub. The evaluator will choose 凡人之墓 because physical_union_complete is false.
8. The ending theater runs the High Priest -> Ancient God -> King sequence.

The important acceptance point is that you never complete the physical union.

## 2. 永恒乐园

Goal: complete the relationship, but do not awaken the hidden resistance anchor.

Recommended path:

1. Start a new game.
2. Reach Mite and complete four unique interactions:
   - mite_first_meeting
   - mite_meal
   - mite_stay_a_while
   - mite_return
3. The Mite interaction system normally allows only one new interaction per location, so leave the Village and return between interactions when necessary.
4. Enter Mite's house.
5. Rest at the bed after the four interactions.
6. The game records:
   - physical_union_complete = true
   - ancient_residue_awakened = true
   - outer_god_resonance = true
7. Do not collect three hidden artifact sources.
8. Return to the Village Hub and press F1.
9. The evaluator will choose 永恒乐园.

For a clean test run, avoid examining:
- the Weathered Stone in the graveyard;
- the Unsent Order in the Restoration Camp;
- the Ancient Research Ward clues / Research Husk;
- the route memory echo.

## 3. 烈火天罚

Goal: complete the relationship after awakening the hidden resistance anchor.

Collect any three of the following four hidden sources:

| Source | How to record it |
| --- | --- |
| ancient_lab | Examine any Ancient Research Ward clue, or defeat the Research Husk |
| graveyard_bell | Examine the Weathered Stone after entering the graveyard |
| rebel_order | Examine the Unsent Order in the Restoration Camp |
| memory_echo | Examine a route memory echo on the Church or Lullaby route |

Three unique sources are enough. The fourth is optional.

Then:

1. Complete the four unique Mite interactions.
2. Enter Mite's house.
3. Rest at the bed.
4. Confirm the state reaches hidden_artifact_pieces >= 3 and physical_union_complete = true.
5. Return to the Village Hub.
6. Press F1.
7. The evaluator will choose 烈火天罚.
8. The ending theater then presents the 100-cultist set piece, Mite's final encounter, the city destruction, and the final fire sequence.

## Recommended acceptance order

Because the current build uses a single save slot, the easiest testing order is:

凡人之墓 -> 永恒乐园 -> 烈火天罚

Start a new game between each run.

For the Fire run, the most reliable three-source combination is:

Ancient Research Ward + Graveyard Weathered Stone + Restoration Camp Unsent Order

This avoids depending on route selection just to unlock the hidden resistance.

## Developer shortcuts

These are still development/director controls, not shipping player-facing features:

- F1: evaluate current state and open the candidate ending theater.
- F2: open Eternal Paradise theater directly.
- F4: open Ancient Research Ward.
- F5: open Village Defense theater.
- F6: open Mite Resonance theater.
- F7: open Church final boss theater.
- F8: open Blazing Judgment theater.
- F9: delete the current save and restart the prologue.

The final release should eventually replace the F1 ending shortcut with the real mainline endgame gate while keeping the evaluator and state facts unchanged.
