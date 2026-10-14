extends Node
class_name HeroVisualStates

## Temporary visual state bridge.
## Keeps gameplay state independent from future Sprite/Skeleton implementation.

const STATES := {
	"idle": "idle",
	"move": "run",
	"jump": "jump",
	"attack_long": "attack_long_sword",
	"attack_short": "attack_short_blade",
	"dodge": "dodge",
	"hurt": "hurt",
	"dead": "death"
}

func resolve_animation(combat_state: String) -> String:
	return STATES.get(combat_state, "idle")
