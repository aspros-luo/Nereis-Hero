extends CharacterBody2D
class_name StickmanSkeletonController

# S1.2.2-A3: minimal AnimationPlayer + Skeleton2D integration test.
# This controller is a prototype harness, not the final gameplay controller.

enum State {
	IDLE,
	RUN,
	LONG_SWORD_ATTACK,
	SHORT_BLADE_ATTACK,
	HURT,
	DODGE,
	WITCH_TIME,
	BOSS_ACTION
}

@export var move_speed: float = 160.0

var current_state: State = State.IDLE
var action_time_remaining: float = 0.0
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer
@onready var skeleton: Skeleton2D = get_node_or_null("Skeleton2D") as Skeleton2D


func _ready() -> void:
	_build_prototype_animations()
	set_state(State.IDLE)


func _physics_process(_delta: float) -> void:
	# Support both arrow keys (ui_left/ui_right) and familiar A/D controls.
	# The prototype intentionally avoids project-wide Input Map changes.
	# CharacterBody2D owns movement; animation only changes Bone2D rotations.
	var direction := Input.get_axis("ui_left", "ui_right")
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction = -1.0
	elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction = 1.0
	velocity.x = direction * move_speed
	if skeleton != null and absf(direction) > 0.01:
		# Flip only the rig, not the CharacterBody2D or its camera.
		skeleton.scale.x = -1.0 if direction < 0.0 else 1.0
	move_and_slide()

	# Temporary action states own playback until their non-looping clip ends.
	if _is_action_state(current_state):
		action_time_remaining -= _delta
		if action_time_remaining <= 0.0:
			_set_locomotion_state(direction)
		return

	# Prototype controls: J = long sword, K = short blade, Space = dodge.
	# These are animation/timing tests only: no hitboxes, damage, or invulnerability.
	if Input.is_key_pressed(KEY_J):
		set_state(State.LONG_SWORD_ATTACK)
		return
	if Input.is_key_pressed(KEY_K):
		set_state(State.SHORT_BLADE_ATTACK)
		return
	if Input.is_key_pressed(KEY_SPACE):
		set_state(State.DODGE)
		return

	_set_locomotion_state(direction)


func _set_locomotion_state(direction: float) -> void:
	set_state(State.RUN if absf(direction) > 0.01 else State.IDLE)


func _is_action_state(state: State) -> bool:
	return state == State.LONG_SWORD_ATTACK or state == State.SHORT_BLADE_ATTACK or state == State.DODGE


func set_state(next_state: State) -> void:
	if current_state == next_state:
		# _ready() starts in IDLE; ensure the first idle clip actually begins.
		if animation_player != null and not animation_player.is_playing():
			if next_state == State.IDLE or next_state == State.RUN:
				animation_player.play("Idle" if next_state == State.IDLE else "Run")
		return

	current_state = next_state
	if animation_player == null:
		return

	match current_state:
		State.IDLE:
			animation_player.play("Idle")
		State.RUN:
			animation_player.play("Run")
		State.LONG_SWORD_ATTACK:
			_play_action("LongSwordAttack")
		State.SHORT_BLADE_ATTACK:
			_play_action("ShortBladeAttack")
		State.DODGE:
			_play_action("Dodge")
		State.HURT, State.WITCH_TIME, State.BOSS_ACTION:
			animation_player.stop()


func _play_action(animation_name: String) -> void:
	if animation_player == null or not animation_player.has_animation(animation_name):
		return
	animation_player.play(animation_name)
	action_time_remaining = animation_player.current_animation_length


func get_state_name() -> String:
	return State.keys()[current_state]


func _build_prototype_animations() -> void:
	if animation_player == null:
		push_warning("Stickman prototype is missing its AnimationPlayer node.")
		return

	var library := AnimationLibrary.new()
	var idle_result := library.add_animation("Idle", _make_idle_animation())
	var run_result := library.add_animation("Run", _make_run_animation())
	var long_attack_result := library.add_animation("LongSwordAttack", _make_long_sword_attack_animation())
	var short_attack_result := library.add_animation("ShortBladeAttack", _make_short_blade_attack_animation())
	var dodge_result := library.add_animation("Dodge", _make_dodge_animation())
	if idle_result != OK or run_result != OK or long_attack_result != OK or short_attack_result != OK or dodge_result != OK:
		push_error("Could not build stickman prototype animation library.")
		return

	# Avoid get_animation_library("") when the default library is absent:
	# Godot reports an engine error for that lookup even if we only check null.
	if animation_player.has_animation_library(""):
		animation_player.remove_animation_library("")
	var result := animation_player.add_animation_library("", library)
	if result != OK:
		push_error("Could not register stickman prototype animation library.")
		return

	animation_player.root_node = NodePath("..")
	animation_player.set_blend_time("Idle", "Run", 0.12)
	animation_player.set_blend_time("Run", "Idle", 0.12)


func _make_idle_animation() -> Animation:
	var animation := Animation.new()
	animation.resource_name = "Idle"
	animation.length = 1.6
	animation.loop_mode = Animation.LOOP_LINEAR

	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine", [0.0, 0.8, 1.6], [0.0, 0.018, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Head", [0.0, 0.8, 1.6], [0.0, -0.025, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_L", [0.0, 0.8, 1.6], [-0.025, -0.01, -0.025])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_R", [0.0, 0.8, 1.6], [0.025, 0.01, 0.025])
	# Neutral thigh/knee keys reset the complete two-segment legs after running.
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L", [0.0, 0.8, 1.6], [0.0, 0.0, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R", [0.0, 0.8, 1.6], [0.0, 0.0, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L/Knee_L", [0.0, 0.8, 1.6], [0.0, 0.0, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R/Knee_R", [0.0, 0.8, 1.6], [0.0, 0.0, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L/Knee_L/Foot_L", [0.0, 0.8, 1.6], [0.0, 0.0, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R/Knee_R/Foot_R", [0.0, 0.8, 1.6], [0.0, 0.0, 0.0])
	return animation


func _make_run_animation() -> Animation:
	var animation := Animation.new()
	animation.resource_name = "Run"
	animation.length = 0.8
	animation.loop_mode = Animation.LOOP_LINEAR

	var times := [0.0, 0.2, 0.4, 0.6, 0.8]
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine", times, [0.04, -0.04, 0.04, -0.04, 0.04])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Head", times, [0.0, 0.015, 0.0, -0.015, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_L", times, [-0.65, 0.65, -0.65, 0.65, -0.65])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_R", times, [0.65, -0.65, 0.65, -0.65, 0.65])
	# Opposing hip swings create a readable stride; knee bends lift the trailing foot.
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L", times, [0.62, -0.62, 0.62, -0.62, 0.62])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R", times, [-0.62, 0.62, -0.62, 0.62, -0.62])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L/Knee_L", times, [0.0, 0.45, 0.0, 0.12, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R/Knee_R", times, [0.45, 0.0, 0.12, 0.0, 0.45])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L/Knee_L/Foot_L", times, [-0.12, 0.18, -0.12, 0.08, -0.12])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R/Knee_R/Foot_R", times, [0.18, -0.12, 0.08, -0.12, 0.18])
	return animation


func _make_long_sword_attack_animation() -> Animation:
	var animation := Animation.new()
	animation.resource_name = "LongSwordAttack"
	animation.length = 0.42
	animation.loop_mode = Animation.LOOP_NONE
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine", [0.0, 0.12, 0.28, 0.42], [0.0, -0.28, 0.42, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_L", [0.0, 0.12, 0.28, 0.42], [-0.1, -1.0, 0.75, -0.025])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_R", [0.0, 0.12, 0.28, 0.42], [0.1, -1.15, 0.9, 0.025])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L", [0.0, 0.12, 0.28, 0.42], [0.0, -0.18, 0.12, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R", [0.0, 0.12, 0.28, 0.42], [0.0, 0.12, -0.12, 0.0])
	return animation


func _make_short_blade_attack_animation() -> Animation:
	var animation := Animation.new()
	animation.resource_name = "ShortBladeAttack"
	animation.length = 0.3
	animation.loop_mode = Animation.LOOP_NONE
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine", [0.0, 0.08, 0.18, 0.3], [0.0, 0.18, -0.24, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_L", [0.0, 0.08, 0.18, 0.3], [-0.025, -0.65, 0.4, -0.025])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_R", [0.0, 0.08, 0.18, 0.3], [0.025, -0.85, 0.55, 0.025])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L", [0.0, 0.08, 0.18, 0.3], [0.0, -0.08, 0.08, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R", [0.0, 0.08, 0.18, 0.3], [0.0, 0.08, -0.08, 0.0])
	return animation


func _make_dodge_animation() -> Animation:
	var animation := Animation.new()
	animation.resource_name = "Dodge"
	animation.length = 0.36
	animation.loop_mode = Animation.LOOP_NONE
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine", [0.0, 0.1, 0.24, 0.36], [0.0, -0.42, -0.2, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Head", [0.0, 0.1, 0.24, 0.36], [0.0, 0.16, 0.08, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_L", [0.0, 0.1, 0.24, 0.36], [-0.025, -0.8, -0.5, -0.025])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_R", [0.0, 0.1, 0.24, 0.36], [0.025, -0.8, -0.5, 0.025])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L", [0.0, 0.1, 0.24, 0.36], [0.0, 0.5, -0.3, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R", [0.0, 0.1, 0.24, 0.36], [0.0, -0.3, 0.5, 0.0])
	return animation


func _add_rotation_track(animation: Animation, bone_path: String, times: Array, values: Array) -> void:
	var track_index := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, NodePath(bone_path + ":rotation"))
	animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_LINEAR)
	for index in range(times.size()):
		animation.track_insert_key(track_index, times[index], values[index])
