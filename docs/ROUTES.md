# Route / Interpretation Foundation

> **Important:** the Church / Lullaby split described here is an existing implementation foundation, not the final three-ending structure.
>
> The canonical ending design is in [DEVELOPER_STORY_MEMORY.md](./DEVELOPER_STORY_MEMORY.md).
>
> Future narrative work must not treat "Church route" or "Lullaby route" as the equivalent of the three canonical endings.

## Current implementation foundation

After Vertical Slice 001, the first player choice can currently select one of two narrative interpretations.

## Church Route

State:

WorldState.selected_route = "church"

Scene:

res://scenes/routes/church_path.tscn

Perspective:

The Hero follows institutional memory toward the old church. The route emphasizes names, records, seals, and the idea that the church expected the Hero to survive.

Shared-world NPC:

**Amnesiac Youth** — the same type of character that can appear in Nereis Lullaby, but encountered here through the Hero's perspective.

## Lullaby Route

State:

WorldState.selected_route = "lullaby"

Scene:

res://scenes/routes/lullaby_path.tscn

Perspective:

The Hero follows the song toward village lights. The route emphasizes recognition, incomplete memories, and events that feel familiar before they can be explained.

Shared-world NPC:

**Traveling Merchant** — his knowledge of the Hero is intentionally different from the church's records.

## Design Role

The route choice is not currently treated as a simple good/evil morality score.

It records which interpretation the Hero chose to trust:

- Church alignment
- Lullaby resonance

Later story events can contradict either interpretation.

## Future narrative direction

The final game should use these choices as **evidence / interpretation layers**, not as permanent binary factions.

The ultimate endings are:

1. **凡人之墓** — the visible political conflict is resolved through the rebels, but the human cycle of corruption repeats.
2. **永恒乐园** — Hero fully accepts Mite and becomes the Outer God's vessel.
3. **烈火天罚** — Hero joins with Mite but hidden knowledge lets him retain enough selfhood to choose annihilation.

Therefore:

- Church evidence does not automatically lead to 凡人之墓.
- Lullaby evidence does not automatically lead to 永恒乐园.
- Discovering hidden clues is not a "secret route" by itself.
- The final ending should emerge from the total playthrough state.

The existing Church/Lullaby implementation may be retained as a narrative delivery mechanism until the final story structure is designed.
