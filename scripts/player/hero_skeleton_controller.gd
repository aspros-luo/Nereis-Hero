extends Node2D
class_name HeroSkeletonController

## Phase S1.1 Skeleton2D visual prototype controller.
## This layer only controls visual pose state and does not own gameplay logic.

enum PoseState {
	IDLE,
	RUN,
	ATTACK_LONG,
	ATTACK_SHORT,
	DODGE,
	HURT
}

var current_pose: PoseState = PoseState.IDLE

func set_pose(state: PoseState) -> void:
	current_pose = state
	_apply_pose()

func play_idle() -> void:
	set_pose(PoseState.IDLE)

func play_run() -> void:
	set_pose(PoseState.RUN)

func play_long_attack() -> void:
	set_pose(PoseState.ATTACK_LONG)

func play_short_attack() -> void:
	set_pose(PoseState.ATTACK_SHORT)

func play_dodge() -> void:
	set_pose(PoseState.DODGE)

func play_hurt() -> void:
	set_pose(PoseState.HURT)

func _apply_pose() -> void:
	# Reserved for Skeleton2D/Bone2D transforms.
	# Gameplay state remains in hero.gd.
	pass
