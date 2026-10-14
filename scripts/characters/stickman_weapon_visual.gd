extends Node2D

# S1.2.2-A10: lightweight weapon silhouette driven by the live hand bone.
# This is presentation-only: it creates no hitboxes and applies no damage.

@export var long_sword_length: float = 24.0
@export var short_blade_length: float = 13.0
@export var outline_color := Color(0.12, 0.11, 0.14, 1.0)
@export var blade_color := Color(0.72, 0.75, 0.73, 1.0)
@export var hilt_color := Color(0.48, 0.34, 0.22, 1.0)
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

	var grip_global := hand_bone.global_position + hand_bone.global_transform.basis_xform(Vector2(0.0, arm_length))
	var grip := grip_global - get_parent().global_position
	var facing := -1.0 if skeleton.scale.x < 0.0 else 1.0
	var is_short_blade := controller.get_equipped_weapon_name() == "short_blade"
	var weapon_length := short_blade_length if is_short_blade else long_sword_length
	var angle := _get_weapon_angle(is_short_blade)
	var direction := Vector2(cos(angle) * facing, sin(angle)).normalized()
	var tip := grip + direction * weapon_length
	var blade_base := grip + direction * (3.0 if is_short_blade else 4.0)
	var guard_center := grip + direction * 2.0
	var guard_half_span := 3.0 if is_short_blade else 5.0
	var perpendicular := Vector2(-direction.y, direction.x)

	# Blade silhouette first, then a narrow metal highlight.
	draw_line(blade_base, tip, outline_color, 4.0 if is_short_blade else 5.2, true)
	draw_line(blade_base, tip, blade_color, 1.8 if is_short_blade else 2.4, true)
	# Small crossguard and warm grip keep the two weapon profiles distinct.
	draw_line(guard_center - perpendicular * guard_half_span, guard_center + perpendicular * guard_half_span, outline_color, 3.2, true)
	draw_line(grip - direction * 4.0, grip + direction * 1.0, outline_color, 4.0, true)
	draw_line(grip - direction * 3.5, grip + direction * 0.5, hilt_color, 2.0, true)


func _get_weapon_angle(is_short_blade: bool) -> float:
	var state_name := controller.get_state_name()
	if animation_player == null:
		return -1.1

	if state_name == "LONG_SWORD_ATTACK":
		return _sample_curve(
			animation_player.current_animation_position,
			[0.0, 0.12, 0.25, 0.40, 0.54, 0.68],
			[-1.10, -2.15, -1.85, 0.22, 0.72, -1.10]
		)
	if state_name == "SHORT_BLADE_ATTACK":
		return _sample_curve(
			animation_player.current_animation_position,
			[0.0, 0.035, 0.095, 0.17, 0.28],
			[-0.95, -1.70, -0.22, 0.18, -0.95]
		)
	if state_name == "DODGE":
		return -1.15

	# In locomotion, keep the weapon angled forward without an idle swing arc.
	return -0.95 if is_short_blade else -1.10


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
