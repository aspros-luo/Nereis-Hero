# ALL ENDINGS GUIDE

> **Authoritative design contract:** [ENDING_CONDITION_DESIGN_CN.md](./ENDING_CONDITION_DESIGN_CN.md). The threshold rules below are historical prototype behavior, not the final story contract.

Endings must be resolved from facts the player actually establishes: explored routes, key-item acquisition / current possession / use, and completed special story or combat events. Mite relationship interactions may be prerequisites for obtaining certain items or scenes, but relationship state itself is not an ending switch. Physical intimacy is never required.

## Intended routes

- **凡人之墓 — Mortal's Grave:** The player mainly follows the normal route, does not discover / enter critical hidden areas, and consequently misses the key items and special scenes that expose the cosmic route.
- **永恒乐园 — Eternal Paradise:** The player explores enough to obtain some key items and trigger some special scenes, but does not complete the deeper exploration or the full resistance chain. One example is missing the third umbilical cord or a later required event.
- **烈火天罚 — Blazing Judgment:** The player completes the deep hidden route, the required key-item state, and designated story / co-op events. Examples include defeating the Church monster with the Pilgrim Knight and defeating the cult ritual leader deep in the forest together.

These are route intentions, not a claim that every condition is already implemented. The final mapping must identify real item IDs, whether each item must be acquired / currently held / used, and the actual event flags in source. Topological connectivity, seeing an entrance, or loading a scene does not count as completed exploration.

## Relationship dependency

A Mite interaction can open the only or one of several paths to a key item. Its effect on ending selection is indirect: the player may or may not obtain the item and complete its follow-up event. Do not use romance scores, meeting status, missed-relationship status, or physical intimacy as direct ending criteria. Ending presentation may adapt to the relationship events actually recorded.

## Legacy prototype behavior — not authoritative

The current `scripts/core/ending_evaluator.gd` still checks:

- `hero_resonance >= 68`;
- Blazing Judgment: at least 3 anchor sources and at least 2 hidden regions entered;
- Eternal Paradise: `anomaly_observer_reaction` plus at least 1 hidden region entered, unless Blazing Judgment matches;
- otherwise Mortal's Grave.

This prototype does not explicitly check the third umbilical cord, inventory possession / item use, the Pilgrim Knight co-op fights, or completion of the relevant special scenes. It must be replaced only after mapping the actual content flags and building positive / negative regression cases; do not guess identifiers or treat the prototype as V2-compliant.

## Developer shortcuts

- F1: evaluate the current state
- F2: Eternal Paradise director test
- F4: Ancient Research Ward
- F5: Village Defense theater
- F6: Mite Resonance theater
- F7: Church final boss theater
- F8: Blazing Judgment director test
- F9: delete save and restart

These are developer tools, not player-facing features or proof of full-route acceptance.
