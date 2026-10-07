# Route System

After Vertical Slice 001, the first player choice selects one of two narrative routes.

## Church Route

State:

`WorldState.selected_route = "church"`

Scene:

`res://scenes/routes/church_path.tscn`

Perspective:

The Hero follows institutional memory toward the old church. The route emphasizes names, records, seals, and the idea that the church expected the Hero to survive.

Shared-world NPC:

**Amnesiac Youth** — the same type of character that can appear in Nereis Lullaby, but encountered here through the Hero's perspective.

## Lullaby Route

State:

`WorldState.selected_route = "lullaby"`

Scene:

`res://scenes/routes/lullaby_path.tscn`

Perspective:

The Hero follows the song toward village lights. The route emphasizes recognition, incomplete memories, and events that feel familiar before they can be explained.

Shared-world NPC:

**Traveling Merchant** — his knowledge of the Hero is intentionally different from the church's records.

## Design Rule

The route choice is not currently treated as a simple good/evil morality score.

It records which interpretation the Hero chose to trust:

- Church alignment
- Lullaby resonance

Later story events can contradict either interpretation.
