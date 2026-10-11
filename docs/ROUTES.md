# Route / Interpretation Foundation

> The Church / Lullaby split is an interpretation layer, not the three-ending selector.
>
> The canonical ending contract is documented in STORY.md and CROSS_GAME_STORY_CANON_CN.md.

## Current implementation foundation

The first player choice can select one of two narrative interpretations.

### Church Route

- State: WorldState.selected_route = "church"
- Scene: res://scenes/routes/church_path.tscn
- Focus: names, records, seals, and the idea that the Church expected Hero to survive.

### Lullaby Route

- State: WorldState.selected_route = "lullaby"
- Scene: res://scenes/routes/lullaby_path.tscn
- Focus: recognition, incomplete memories, and events that feel familiar before they can be explained.

## Design role

The route choice records which interpretation Hero initially trusts; it is not a good/evil score or a direct ending lock. Later evidence can contradict either interpretation.

## Three canonical endings

1. **凡人之墓 / Mortal's Grave** — Hero defeats the Church and King, helping the Restoration Army win. Its later corruption shows that human power repeats itself.
2. **永恒乐园 / Eternal Paradise** — high Resonance plus an Outer-God trace, without enough truth anchors and exploration to preserve Hero's individuality.
3. **烈火天罚 / Blazing Judgment** — high Resonance plus at least three truth-anchor sources and deep exploration preserve enough agency to resist the Outer God, at catastrophic cost.

The ending evaluator uses Hero Resonance, truth-anchor items and entered hidden regions. It must not read physical_union_complete, Mite interaction count, or relationship-missed flags.

## Cross-game continuation

Nereis-Lullaby is primarily told through Mite's perspective. After Mortal's Grave, it may show the Restoration Army gradually becoming a new corrupt institution, Hero compromising and eventually leaving Mite behind, and the Outer God continuing its search for another vessel. This continuation expands the aftermath; it does not erase the RPG's political victory.
