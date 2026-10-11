# ALL ENDINGS GUIDE

Current contract: endings are determined by Resonance, truth-anchor items and exploration. Physical intimacy with Mite is not an ending condition.

## Rules

The evaluator in scripts/core/ending_evaluator.gd uses these prototype thresholds:

- Cosmic Resonance: hero_resonance >= 68.
- Eternal Paradise: Resonance >= 68, the anomaly_observer_reaction source is recorded, at least one hidden region is entered, and Blazing Judgment requirements are not met.
- Blazing Judgment: Resonance >= 68, at least 3 unique truth-anchor sources, and at least 2 hidden regions entered.
- Mortal's Grave: all other combinations.

The evaluator does not read physical_union_complete, mite_connection_missed, Mite interaction count, or outer_god_resonance.

## 凡人之墓 — Mortal's Grave

Hero defeats the Church's leadership and the King. The Restoration Army removes the Church's immediate control and claims victory. The epilogue shows the army later reproducing the same patterns of authority and corruption.

Keep Resonance below 68, or reach high Resonance without the exploration / exposure facts required for either cosmic ending. Mite relationship scenes can be present or absent.

## 永恒乐园 — Eternal Paradise

Hero's Resonance becomes a signal the Outer God can answer. Exploration exposes him to an Outer-God trace, but he has not assembled enough truth anchors and explored enough hidden regions to preserve his individuality.

Required: hero_resonance >= 68, anomaly_observer_reaction is present in resonance_sources, entered_hidden_regions.size() >= 1, and Blazing Judgment requirements not both met.

Physical intimacy with Mite is not required. The ending theater must not mark physical_union_complete as a side effect.

## 烈火天罚 — Blazing Judgment

Hero has enough Resonance to draw the cosmic threat near, and has assembled a multi-part truth anchor while exploring deeply enough to preserve agency.

Required: hero_resonance >= 68, hidden_artifact_pieces >= 3, entered_hidden_regions.size() >= 2.

Four canonical sources: ancient_lab, graveyard_bell, rebel_order, memory_echo. Three unique sources are sufficient; the fourth provides additional context. The ending remains tragic and does not promise that Hero can save Mite or the city.

## Acceptance matrix

| Resonance | Observer Reaction recorded | Truth anchors | Hidden regions entered | Expected ending |
|---:|---:|---:|---:|---|
| 0–67 | Any | Any | Any | 凡人之墓 |
| 68+ | Yes | 0–2 | 1+ | 永恒乐园 |
| 68+ | Any | 3+ | 2+ | 烈火天罚 |
| 68+ | No | 0–2 | Any | 凡人之墓 |

Blazing Judgment has priority when both cosmic routes appear plausible.

## Developer shortcuts

- F1: evaluate current state and open the candidate ending theater.
- F2: open Eternal Paradise theater directly.
- F4: open Ancient Research Ward.
- F5: open Village Defense theater.
- F6: open Mite Resonance theater.
- F7: open Church final boss theater.
- F8: open Blazing Judgment director theater.
- F9: delete the current save and restart the prologue.

These are developer shortcuts, not shipping player-facing features.
