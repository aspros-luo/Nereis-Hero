extends Node
class_name HeroVisualStates

## Presentation-only state mapping. Gameplay state remains owned by hero.gd.
## 仅负责表现状态映射；游戏状态仍由 hero.gd 管理。

const STATES := {
	"idle": "idle",
	"run": "run",
	"jump": "jump",
	"fall": "fall",
	"attack_long": "attack_long_sword",
	"attack_short": "attack_short_blade",
	"dodge": "dodge",
	"quick_dash": "quick_dash",
	"grapple": "grapple",
	"wall_climb": "wall_climb",
	"hurt": "hurt",
	"death": "death"
}


func resolve_animation(visual_state: String) -> String:
	return STATES.get(visual_state, "idle")
