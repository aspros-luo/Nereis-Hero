extends Node2D

# S1.2.2-A11: weapon silhouettes and lightweight swing trails.
# Presentation-only: no hitboxes, damage, stamina, or combat resolution.

@export var long_sword_length: float = 24.0
@export var short_blade_length: float = 13.0
@export var outline_color := Color(0.12, 0.11, 0.14, 1.0)
@export var blade_color := Color(0.72, 0.75, 0.73, 1.0)
@export var hilt_color := Color(0.48, 0.34, 0.22, 1.0)
@export var long_trail_color := Color(0.86, 0.88, 0.82, 0.78)
@export var short_trail_color := Color(0.72, 0.84, 0.88, 0.72)
@export var arm_length: float = 10.5

@onready var controller: StickmanSkeletonController = get_parent() as StickmanSkeletonController
@onready var skeleton: Skeleton2D = get_parent().get_node_or_null("Skeleton2D") as Skeleton2D
@onready var animation_player: AnimationPlayer = get_parent().get_node_or_null("AnimationPlayer") as AnimationPlayer


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if controller == null or skeleton == null:
		return

	var hand_bone := skeleton.get_node_or_null("RootBone/Spine/Arm_R") as Bone2D
	if hand_bone == null:
		return

	var grip_global: Vector2 = hand_bone.global_position + hand_bone.global_transform.basis_xform(Vector2(0.0, arm_length))
	var grip: Vector2 = grip_global - get_parent().global_position
	var facing := -1.0 if skeleton.scale.x < 0.0 else 1.0
	var is_short_blade := controller.get_equipped_weapon_name() == "short_blade"
	var weapon_length: float = short_blade_length if is_short_blade else long_sword_length
	var arm_direction: Vector2 = hand_bone.global_transform.basis_xform(Vector2(0.0, 1.0)).normalized()
	var angle_offset := _get_weapon_angle_offset(is_short_blade)
	# Rotate relative to the live arm direction; invert the offset when mirrored.
	var direction: Vector2 = arm_direction.rotated(angle_offset * facing).normalized()
	var tip: Vector2 = grip + direction * weapon_length
	var blade_base: Vector2 = grip + direction * (3.0 if is_short_blade else 4.0)
	var guard_center: Vector2 = grip + direction * 2.0
	var guard_half_span := 3.0 if is_short_blade else 5.0
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x)

	_draw_swing_trail(grip, direction, weapon_length, is_short_blade)

	# Blade silhouette first, then a narrow metal highlight.
	draw_line(blade_base, tip, outline_color, 4.0 if is_short_blade else 5.2, true)
	draw_line(blade_base, tip, blade_color, 1.8 if is_short_blade else 2.4, true)
	# Small crossguard and warm grip keep the two weapon profiles distinct.
	draw_line(guard_center - perpendicular * guard_half_span, guard_center + perpendicular * guard_half_span, outline_color, 3.2, true)
	draw_line(grip - direction * 4.0, grip + direction * 1.0, outline_color, 4.0, true)
	draw_line(grip - direction * 3.5, grip + direction * 0.5, hilt_color, 2.0, true)


func _draw_swing_trail(grip: Vector2, direction: Vector2, weapon_length: float, is_short_blade: bool) -> void:
	if animation_player == null:
		return

	var state_name: String = controller.get_state_name()
	var elapsed: float = animation_player.current_animation_position
	var phase_start: float
	var phase_end: float
	var peak_time: float
	var arc_span: float
	var trail_width: float
	var trail_color: Color

	if state_name == "LONG_SWORD_ATTACK":
		phase_start = 0.16
		peak_time = 0.34
		phase_end = 0.49
		arc_span = 0.62
		trail_width = 3.0
		trail_color = long_trail_color
	elif state_name == "SHORT_BLADE_ATTACK":
		phase_start = 0.045
		peak_time = 0.105
		phase_end = 0.19
		arc_span = 0.38
		trail_width = 1.8
		trail_color = short_trail_color
	else:
		return

	if elapsed < phase_start or elapsed > phase_end:
		return

	var fade_in: float = inverse_lerp(phase_start, peak_time, elapsed)
	var fade_out: float = inverse_lerp(phase_end, peak_time, elapsed)
	var strength: float = clampf(minf(fade_in, fade_out), 0.0, 1.0)
	trail_color.a *= strength
	var radius: float = weapon_length * (0.72 if is_short_blade else 0.84)
	var center_angle: float = direction.angle()
	var start_angle: float = center_angle - arc_span
	var end_angle: float = center_angle + arc_span
	var point_count: int = 12 if is_short_blade else 18
	draw_arc(grip, radius, start_angle, end_angle, point_count, trail_color, trail_width, true)
	# A short inner echo makes the long-sword sweep feel weightier without particles.
	if not is_short_blade:
		var echo_color: Color = trail_color
		echo_color.a *= 0.42
		draw_arc(grip, radius - 3.0, start_angle + 0.08, end_angle - 0.08, point_count, echo_color, 1.2, true)


func _get_weapon_angle_offset(is_short_blade: bool) -> float:
	var state_name := controller.get_state_name()
	if animation_player == null:
		return -2.65

	if state_name == "LONG_SWORD_ATTACK":
		return _sample_curve(
			animation_player.current_animation_position,
			[0.0, 0.12, 0.25, 0.40, 0.54, 0.68],
			[-2.65, -2.40, -2.05, -1.80, -2.20, -2.65]
		)
	if state_name == "SHORT_BLADE_ATTACK":
		return _sample_curve(
			animation_player.current_animation_position,
			[0.0, 0.035, 0.095, 0.17, 0.28],
			[-2.65, -2.45, -2.00, -2.30, -2.65]
		)
	if state_name == "DODGE":
		return -2.55

	# Locomotion keeps the blade forward of the hand without a swing arc.
	return -2.55 if is_short_blade else -2.65


func _sample_curve(time: float, key_times: Array, key_values: Array) -> float:
	if time <= key_times[0]:
		return key_values[0]
	for index in range(key_times.size() - 1):
		var start_time: float = key_times[index]
		var end_time: float = key_times[index + 1]
		if time <= end_time:
			var weight := (time - start_time) / maxf(end_time - start_time, 0.001)
			return lerpf(key_values[index], key_values[index + 1], weight)
	return key_values[key_values.size() - 1]
