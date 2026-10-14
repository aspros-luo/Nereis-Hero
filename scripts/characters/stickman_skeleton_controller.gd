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

enum WeaponKind {
	LONG_SWORD,
	SHORT_BLADE
}

@export var move_speed: float = 160.0
@export var prototype_dodge_speed: float = 360.0

var current_state: State = State.IDLE
var equipped_weapon: WeaponKind = WeaponKind.LONG_SWORD
var action_time_remaining: float = 0.0
var action_facing_direction: float = 1.0
var combo_step: int = 0
var combo_input_buffered: bool = false
var active_action_animation: String = ""
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer
@onready var skeleton: Skeleton2D = get_node_or_null("Skeleton2D") as Skeleton2D


func _ready() -> void:
	_build_prototype_animations()
	if animation_player != null and not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)
	set_state(State.IDLE)

func _unhandled_input(event: InputEvent) -> void:
	# Godot's Input singleton has no is_key_just_pressed(keycode) method.
	# Handle discrete key-down events here so holding a key cannot chain actions.
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	match event.keycode:
		KEY_J:
			if current_state == State.LONG_SWORD_ATTACK:
				_try_buffer_combo_input(WeaponKind.LONG_SWORD)
			elif not _is_action_state(current_state):
				set_state(State.LONG_SWORD_ATTACK)
			get_viewport().set_input_as_handled()
		KEY_K:
			if current_state == State.SHORT_BLADE_ATTACK:
				_try_buffer_combo_input(WeaponKind.SHORT_BLADE)
			elif not _is_action_state(current_state):
				set_state(State.SHORT_BLADE_ATTACK)
			get_viewport().set_input_as_handled()
		KEY_SPACE:
			if not _is_action_state(current_state):
				set_state(State.DODGE)
			get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	# CharacterBody2D owns movement; animation only changes Bone2D rotations.
	var direction: float = _get_movement_direction()

	# Capture facing when an action begins. A dodge moves in that direction even
	# if the player releases the movement key, making this a movement test too.
	if current_state == State.DODGE:
		velocity.x = action_facing_direction * prototype_dodge_speed
	else:
		velocity.x = direction * move_speed
	if skeleton != null and not _is_action_state(current_state) and absf(direction) > 0.01:
		# Lock the rig's facing throughout attacks and dodge so the pose and travel
		# direction cannot disagree if the player presses the opposite direction.
		# Flip only the rig, not the CharacterBody2D or its camera.
		skeleton.scale.x = -1.0 if direction < 0.0 else 1.0
	move_and_slide()

	# The animation_finished signal is authoritative; this timer is a defensive
	# fallback in case a clip is stopped or its finish signal is missed.
	if _is_action_state(current_state):
		action_time_remaining -= delta
		if action_time_remaining <= 0.0:
			if combo_input_buffered and combo_step < 3 and (current_state == State.LONG_SWORD_ATTACK or current_state == State.SHORT_BLADE_ATTACK):
				_start_combo_step(combo_step + 1)
			else:
				_finish_action()
		return

	_set_locomotion_state(direction)


func _get_movement_direction() -> float:
	# Support both arrow keys (ui_left/ui_right) and familiar A/D controls
	# without requiring project-wide Input Map changes.
	var direction: float = Input.get_axis("ui_left", "ui_right")
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		return -1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		return 1.0
	return direction


	if String(animation_name) != active_action_animation:
		return
	if current_state == State.LONG_SWORD_ATTACK or current_state == State.SHORT_BLADE_ATTACK:
		if combo_input_buffered and combo_step < 3:
			_start_combo_step(combo_step + 1)
			return
	_finish_action()


func _get_current_action_animation_name() -> String:
	return active_action_animation


func _try_buffer_combo_input(weapon: WeaponKind) -> void:
	if combo_step >= 3 or animation_player == null:
		return
	if weapon == WeaponKind.LONG_SWORD and current_state != State.LONG_SWORD_ATTACK:
		return
	if weapon == WeaponKind.SHORT_BLADE and current_state != State.SHORT_BLADE_ATTACK:
		return
	var elapsed: float = animation_player.current_animation_position
	var window_start: float = 0.0
	var window_end: float = 0.0
	if weapon == WeaponKind.LONG_SWORD:
		window_start = 0.38 if combo_step == 1 else 0.34
		window_end = 0.60 if combo_step == 1 else 0.56
	else:
		window_start = 0.13 if combo_step == 1 else 0.11
		window_end = 0.235 if combo_step == 1 else 0.215
	if elapsed >= window_start and elapsed <= window_end:
		combo_input_buffered = true


func _start_combo_step(next_step: int) -> void:
	if animation_player == null or next_step < 1 or next_step > 3:
		_finish_action()
		return
	combo_step = next_step
	combo_input_buffered = false
	var prefix: String = "LongSwordAttack" if current_state == State.LONG_SWORD_ATTACK else "ShortBladeAttack"
	active_action_animation = prefix if next_step == 1 else prefix + str(next_step)
	if not animation_player.has_animation(active_action_animation):
		push_warning("Stickman prototype combo animation is missing: " + active_action_animation)
		_finish_action()
		return
	animation_player.play(active_action_animation)
	action_time_remaining = animation_player.current_animation_length


func _on_animation_finished(animation_name: StringName) -> void:
	if not _is_action_state(current_state):
		return
	if String(animation_name) != active_action_animation:
		return
	if (current_state == State.LONG_SWORD_ATTACK or current_state == State.SHORT_BLADE_ATTACK) and combo_input_buffered and combo_step < 3:
		_start_combo_step(combo_step + 1)
		return
	_finish_action()


func _finish_action() -> void:
	if not _is_action_state(current_state):
		return
	action_time_remaining = 0.0
	combo_input_buffered = false
	combo_step = 0
	active_action_animation = ""
	var direction: float = _get_movement_direction()
	velocity.x = direction * move_speed
	_set_locomotion_state(direction)


func get_combo_step() -> int:
	return combo_step


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
			equipped_weapon = WeaponKind.LONG_SWORD
			_capture_action_facing()
			_start_combo_step(1)
		State.SHORT_BLADE_ATTACK:
			equipped_weapon = WeaponKind.SHORT_BLADE
			_capture_action_facing()
			_start_combo_step(1)
		State.DODGE:
			combo_step = 0
			combo_input_buffered = false
			_capture_action_facing()
			_play_action("Dodge")
		State.HURT, State.WITCH_TIME, State.BOSS_ACTION:
			animation_player.stop()


func _capture_action_facing() -> void:
	if skeleton != null:
		action_facing_direction = -1.0 if skeleton.scale.x < 0.0 else 1.0


func _play_action(animation_name: String) -> void:
	if animation_player == null or not animation_player.has_animation(animation_name):
		push_warning("Stickman prototype action animation is missing: " + animation_name)
		action_time_remaining = 0.0
		active_action_animation = ""
		_set_locomotion_state(_get_movement_direction())
		return
	active_action_animation = animation_name
	animation_player.play(animation_name)
	action_time_remaining = animation_player.current_animation_length


func get_state_name() -> String:
	return State.keys()[current_state]


func get_equipped_weapon_name() -> String:
	return "short_blade" if equipped_weapon == WeaponKind.SHORT_BLADE else "long_sword"


func _build_prototype_animations() -> void:
	if animation_player == null:
		push_warning("Stickman prototype is missing its AnimationPlayer node.")
		return

	var library := AnimationLibrary.new()
	var idle_result := library.add_animation("Idle", _make_idle_animation())
	var run_result := library.add_animation("Run", _make_run_animation())
	var long_attack_result := library.add_animation("LongSwordAttack", _make_long_sword_attack_animation())
	var long_attack_2_result := library.add_animation("LongSwordAttack2", _make_combo_attack_animation(false, 2))
	var long_attack_3_result := library.add_animation("LongSwordAttack3", _make_combo_attack_animation(false, 3))
	var short_attack_result := library.add_animation("ShortBladeAttack", _make_short_blade_attack_animation())
	var short_attack_2_result := library.add_animation("ShortBladeAttack2", _make_combo_attack_animation(true, 2))
	var short_attack_3_result := library.add_animation("ShortBladeAttack3", _make_combo_attack_animation(true, 3))
	var dodge_result := library.add_animation("Dodge", _make_dodge_animation())
	if idle_result != OK or run_result != OK or long_attack_result != OK or long_attack_2_result != OK or long_attack_3_result != OK or short_attack_result != OK or short_attack_2_result != OK or short_attack_3_result != OK or dodge_result != OK:
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
	# Smooth locomotion transitions, with shorter transitions into/out of actions.
	animation_player.set_blend_time("Idle", "Run", 0.10)
	animation_player.set_blend_time("Run", "Idle", 0.10)
	var action_names := ["LongSwordAttack", "LongSwordAttack2", "LongSwordAttack3", "ShortBladeAttack", "ShortBladeAttack2", "ShortBladeAttack3", "Dodge"]
	for locomotion in ["Idle", "Run"]:
		for action in action_names:
			animation_player.set_blend_time(locomotion, action, 0.04)
			animation_player.set_blend_time(action, locomotion, 0.07)
	for first_action in action_names:
		for second_action in action_names:
			if first_action != second_action:
				animation_player.set_blend_time(first_action, second_action, 0.025)


func _make_idle_animation() -> Animation:
	var animation := Animation.new()
	animation.resource_name = "Idle"
	animation.length = 1.6
	animation.loop_mode = Animation.LOOP_LINEAR

	_add_position_track(animation, "Skeleton2D/RootBone", [0.0, 0.8, 1.6], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
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
	animation.length = 0.72
	animation.loop_mode = Animation.LOOP_LINEAR
	var times := [0.0, 0.18, 0.36, 0.54, 0.72]
	# Opposing hips, alternating knee flex, counter-swinging arms and subtle pelvis bounce.
	_add_position_track(animation, "Skeleton2D/RootBone", times, [Vector2.ZERO, Vector2(0, -1.6), Vector2.ZERO, Vector2(0, -1.6), Vector2.ZERO])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine", times, [0.035, -0.025, 0.035, -0.025, 0.035])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Head", times, [0.0, 0.012, 0.0, -0.012, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_L", times, [-0.52, 0.42, -0.52, 0.42, -0.52])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_R", times, [0.52, -0.42, 0.52, -0.42, 0.52])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L", times, [0.62, 0.0, -0.62, 0.0, 0.62])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R", times, [-0.62, 0.0, 0.62, 0.0, -0.62])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L/Knee_L", times, [0.08, 0.46, 0.04, 0.18, 0.08])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R/Knee_R", times, [0.46, 0.04, 0.18, 0.08, 0.46])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L/Knee_L/Foot_L", times, [-0.16, 0.12, 0.06, -0.10, -0.16])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R/Knee_R/Foot_R", times, [0.12, -0.16, -0.10, 0.06, 0.12])
	return animation


func _make_long_sword_attack_animation() -> Animation:
	var animation := Animation.new()
	animation.resource_name = "LongSwordAttack"
	animation.length = 0.68
	animation.loop_mode = Animation.LOOP_NONE
	# Six beats: neutral, deliberate load, committed cut, follow-through, recovery, neutral.
	var times := [0.0, 0.12, 0.25, 0.40, 0.54, 0.68]
	_add_position_track(animation, "Skeleton2D/RootBone", times, [Vector2.ZERO, Vector2(0, 1.0), Vector2(0, 0.4), Vector2(0, -0.3), Vector2(0, 0.2), Vector2.ZERO])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine", times, [0.0, -0.42, -0.18, 0.58, 0.30, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Head", times, [0.0, 0.08, 0.02, -0.12, -0.04, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_L", times, [-0.1, -1.10, -0.86, 0.82, 0.40, -0.025])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_R", times, [0.1, -1.30, -1.02, 0.96, 0.46, 0.025])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L", times, [0.0, -0.28, -0.18, 0.20, 0.10, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R", times, [0.0, 0.18, 0.12, -0.22, -0.10, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L/Knee_L", times, [0.0, 0.16, 0.12, 0.24, 0.10, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R/Knee_R", times, [0.0, 0.08, 0.04, -0.06, 0.0, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L/Knee_L/Foot_L", times, [0.0, -0.10, -0.04, 0.08, 0.03, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R/Knee_R/Foot_R", times, [0.0, 0.05, 0.02, -0.05, -0.02, 0.0])
	return animation


func _make_short_blade_attack_animation() -> Animation:
	var animation := Animation.new()
	animation.resource_name = "ShortBladeAttack"
	animation.length = 0.28
	animation.loop_mode = Animation.LOOP_NONE
	# Compact thrust/slash: short preparation, sharp extension, immediate recoil.
	var times := [0.0, 0.035, 0.095, 0.17, 0.28]
	_add_position_track(animation, "Skeleton2D/RootBone", times, [Vector2.ZERO, Vector2(0, 0.4), Vector2(0, -0.5), Vector2(0, 0.2), Vector2.ZERO])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine", times, [0.0, 0.18, -0.34, -0.10, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Head", times, [0.0, -0.04, 0.08, 0.025, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_L", times, [-0.025, -0.48, 0.54, 0.16, -0.025])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_R", times, [0.025, -0.86, 0.76, 0.20, 0.025])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L", times, [0.0, -0.10, 0.16, 0.04, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R", times, [0.0, 0.10, -0.12, -0.03, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L/Knee_L", times, [0.0, 0.06, 0.18, 0.06, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R/Knee_R", times, [0.0, 0.02, -0.08, 0.0, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L/Knee_L/Foot_L", times, [0.0, -0.05, 0.07, 0.02, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R/Knee_R/Foot_R", times, [0.0, 0.025, -0.035, 0.0, 0.0])
	return animation


func _make_dodge_animation() -> Animation:
	var animation := Animation.new()
	animation.resource_name = "Dodge"
	animation.length = 0.36
	animation.loop_mode = Animation.LOOP_NONE
	# The dodge is a short evasive burst with a low silhouette, not a roll.
	var times := [0.0, 0.07, 0.20, 0.29, 0.36]
	_add_position_track(animation, "Skeleton2D/RootBone", times, [Vector2.ZERO, Vector2(0, 1.5), Vector2(0, 0.8), Vector2(0, 0.2), Vector2.ZERO])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine", times, [0.0, -0.48, -0.30, -0.12, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Head", times, [0.0, 0.18, 0.10, 0.04, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_L", times, [-0.025, -0.72, -0.52, -0.22, -0.025])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_R", times, [0.025, -0.72, -0.52, -0.22, 0.025])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L", times, [0.0, 0.52, -0.30, -0.12, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R", times, [0.0, -0.28, 0.48, 0.16, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L/Knee_L", times, [0.0, 0.22, 0.32, 0.12, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R/Knee_R", times, [0.0, 0.12, 0.26, 0.10, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L/Knee_L/Foot_L", times, [0.0, 0.12, 0.06, 0.02, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R/Knee_R/Foot_R", times, [0.0, -0.08, -0.03, 0.0, 0.0])
	return animation


func _make_combo_attack_animation(is_short_blade: bool, step: int) -> Animation:
	var animation := Animation.new()
	var prefix: String = "ShortBladeAttack" if is_short_blade else "LongSwordAttack"
	animation.resource_name = prefix + str(step)
	animation.length = 0.34 if is_short_blade else 0.62
	animation.loop_mode = Animation.LOOP_NONE
	var times: Array
	var spine_values: Array
	var left_arm_values: Array
	var right_arm_values: Array
	var left_leg_values: Array
	var right_leg_values: Array
	if is_short_blade:
		times = [0.0, 0.045, 0.11, 0.19, 0.27, 0.34]
		if step == 2:
			spine_values = [0.0, -0.12, 0.38, 0.16, -0.08, 0.0]
			left_arm_values = [-0.025, 0.22, 0.72, 0.38, 0.05, -0.025]
			right_arm_values = [0.025, 0.82, -0.72, -0.28, 0.04, 0.025]
		else:
			spine_values = [0.0, 0.28, -0.52, -0.22, 0.10, 0.0]
			left_arm_values = [-0.025, -0.55, 0.88, 0.32, -0.02, -0.025]
			right_arm_values = [0.025, -0.92, 0.92, 0.22, 0.03, 0.025]
		left_leg_values = [0.0, -0.08, 0.14, 0.04, 0.0, 0.0]
		right_leg_values = [0.0, 0.08, -0.14, -0.03, 0.0, 0.0]
	else:
		times = [0.0, 0.10, 0.22, 0.36, 0.49, 0.62]
		if step == 2:
			spine_values = [0.0, 0.32, 0.12, -0.60, -0.26, 0.0]
			left_arm_values = [-0.025, 0.72, 0.52, -0.92, -0.40, -0.025]
			right_arm_values = [0.025, 0.88, 0.62, -1.02, -0.44, 0.025]
		else:
			spine_values = [0.0, -0.48, -0.24, 0.72, 0.32, 0.0]
			left_arm_values = [-0.025, -1.02, -0.82, 0.96, 0.42, -0.025]
			right_arm_values = [0.025, -1.22, -0.94, 1.10, 0.48, 0.025]
		left_leg_values = [0.0, -0.22, -0.14, 0.22, 0.08, 0.0]
		right_leg_values = [0.0, 0.16, 0.10, -0.24, -0.08, 0.0]
	if is_short_blade:
		_add_position_track(animation, "Skeleton2D/RootBone", times, [Vector2.ZERO, Vector2(0, 0.3), Vector2(0, -0.5), Vector2(0, 0.2), Vector2(0, 0.1), Vector2.ZERO])
	else:
		_add_position_track(animation, "Skeleton2D/RootBone", times, [Vector2.ZERO, Vector2(0, 0.8), Vector2(0, 0.2), Vector2(0, -0.4), Vector2(0, 0.2), Vector2.ZERO])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine", times, spine_values)
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Head", times, [0.0, 0.04, -0.06, 0.08, 0.02, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_L", times, left_arm_values)
	_add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_R", times, right_arm_values)
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L", times, left_leg_values)
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R", times, right_leg_values)
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L/Knee_L", times, [0.0, 0.08, 0.16, 0.10, 0.04, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R/Knee_R", times, [0.0, 0.04, -0.08, -0.04, 0.0, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L/Knee_L/Foot_L", times, [0.0, -0.04, 0.06, 0.02, 0.0, 0.0])
	_add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R/Knee_R/Foot_R", times, [0.0, 0.03, -0.03, 0.0, 0.0, 0.0])
	return animation


func _add_position_track(animation: Animation, bone_path: String, times: Array, values: Array) -> void:
	var track_index := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, NodePath(bone_path + ":position"))
	animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_LINEAR)
	for index in range(times.size()):
		animation.track_insert_key(track_index, times[index], values[index])


func _add_rotation_track(animation: Animation, bone_path: String, times: Array, values: Array) -> void:
	var track_index := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, NodePath(bone_path + ":rotation"))
	animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_LINEAR)
	for index in range(times.size()):
		animation.track_insert_key(track_index, times[index], values[index])
