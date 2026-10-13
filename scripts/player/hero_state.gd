class_name HeroState
extends RefCounted

## Hero runtime state container.
## Keeps movement/combat state separated from the character controller.
## Future weapon skills, dodge timing and ancient-god abilities can consume this layer.

signal state_changed(previous: String, current: String)

const IDLE := "idle"
const MOVE := "move"
const ATTACK := "attack"
const DODGE := "dodge"
const HIT := "hit"
const DEAD := "dead"

var current: String = IDLE
var previous: String = IDLE

var can_move := true
var can_attack := true
var can_dodge := true

func change(next_state: String) -> void:
	if current == next_state:
		return
	previous = current
	current = next_state
	state_changed.emit(previous, current)

func is_combat_locked() -> bool:
	return current in [ATTACK, DODGE, HIT, DEAD]

func reset() -> void:
	change(IDLE)
	can_move = true
	can_attack = true
	can_dodge = true
