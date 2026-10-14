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

	if absf(direction) > 0.01:
		set_state(State.RUN)
	else:
		set_state(State.IDLE)


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
		# Future combat states are named now but deliberately have no clips yet.
		State.LONG_SWORD_ATTACK, State.SHORT_BLADE_ATTACK, State.HURT, State.DODGE, State.WITCH_TIME, State.BOSS_ACTION:
			animation_player.stop()


func get_state_name() -> String:
	return State.keys()[current_state]


func _build_prototype_animations() -> void:
	if animation_player == null:
		push_warning("Stickman prototype is missing its AnimationPlayer node.")
		return

	var library := AnimationLibrary.new()
	var idle_result := library.add_animation("Idle", _make_idle_animation())
	var run_result := library.add_animation("Run", _make_run_animation())
	if idle_result != OK or run_result != OK:
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


func _add_rotation_track(animation: Animation, bone_path: String, times: Array, values: Array) -> void:
	var track_index := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, NodePath(bone_path + ":rotation"))
	animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_LINEAR)
	for index in range(times.size()):
		animation.track_insert_key(track_index, times[index], values[index])
