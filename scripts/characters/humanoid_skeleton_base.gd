extends Node2D
class_name HumanoidSkeletonBase

## Shared humanoid Skeleton2D visual foundation.
## This layer is intentionally separated from gameplay logic.
## Hero, important NPCs, elite humanoid enemies and bosses can reuse this pipeline.

@export var skeleton_path: NodePath
@export var weapon_socket_path: NodePath
@export var effect_socket_path: NodePath

var current_animation_state: String = "idle"

func set_animation_state(state_name: String) -> void:
	current_animation_state = state_name
	_apply_visual_state()

func set_idle() -> void:
	set_animation_state("idle")

func set_run() -> void:
	set_animation_state("run")

func set_attack() -> void:
	set_animation_state("attack")

func set_hurt() -> void:
	set_animation_state("hurt")

func set_dodge() -> void:
	set_animation_state("dodge")

func attach_weapon(weapon: Node2D) -> void:
	var socket := get_node_or_null(weapon_socket_path)
	if socket != null:
		socket.add_child(weapon)

func _apply_visual_state() -> void:
	# Reserved for Skeleton2D / AnimationPlayer integration.
	# Combat state remains owned by character gameplay scripts.
	pass
