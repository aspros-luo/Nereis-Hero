extends CharacterBody2D
class_name StickmanSkeletonController

# S1.2.2-A1 prototype controller.
# Only validates Skeleton2D structure and animation states.
# Gameplay systems remain outside this prototype.

enum State {
    IDLE,
    RUN,
    ATTACK,
    HURT,
    DODGE
}

var current_state: State = State.IDLE

func set_state(next_state: State) -> void:
    current_state = next_state

func get_state_name() -> String:
    return State.keys()[current_state]

func _ready() -> void:
    set_state(State.IDLE)
