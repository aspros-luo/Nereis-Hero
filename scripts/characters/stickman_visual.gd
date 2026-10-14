extends Node2D

# S1.2.2-A6: silhouette-first line-art presentation.
# The renderer deliberately uses a small number of rounded strokes instead of
# adding more joints or decorative anatomy. Bone transforms drive the pose.

@export var outline_color := Color(0.12, 0.11, 0.14, 1.0)
@export var body_color := Color(0.88, 0.86, 0.80, 1.0)
@export var outline_width: float = 5.0
@export var body_width: float = 2.6
@export var head_radius: float = 7.0
@export var arm_length: float = 10.5

@onready var skeleton: Skeleton2D = get_parent().get_node_or_null("Skeleton2D") as Skeleton2D


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if skeleton == null:
		return

	var root := _bone_position("RootBone")
	var spine := _bone_position("RootBone/Spine")
	var head := _bone_position("RootBone/Spine/Head")
	var arm_l_bone := _get_bone("RootBone/Spine/Arm_L")
	var arm_r_bone := _get_bone("RootBone/Spine/Arm_R")
	var arm_l := _bone_position("RootBone/Spine/Arm_L")
	var arm_r := _bone_position("RootBone/Spine/Arm_R")
	var hip_l := _bone_position("RootBone/Leg_L")
	var knee_l := _bone_position("RootBone/Leg_L/Knee_L")
	var foot_l := _bone_position("RootBone/Leg_L/Knee_L/Foot_L")
	var foot_l_bone := _get_bone("RootBone/Leg_L/Knee_L/Foot_L")
	var hip_r := _bone_position("RootBone/Leg_R")
	var knee_r := _bone_position("RootBone/Leg_R/Knee_R")
	var foot_r := _bone_position("RootBone/Leg_R/Knee_R/Foot_R")
	var foot_r_bone := _get_bone("RootBone/Leg_R/Knee_R/Foot_R")

	# Core silhouette: compact torso, readable shoulder span, and longer legs.
	_draw_limb(root, spine)
	_draw_limb(spine, head)
	_draw_limb(spine, arm_l)
	_draw_limb(spine, arm_r)
	_draw_limb(arm_l, _arm_tip(arm_l, arm_l_bone))
	_draw_limb(arm_r, _arm_tip(arm_r, arm_r_bone))
	_draw_limb(root, hip_l)
	_draw_limb(hip_l, knee_l)
	_draw_limb(knee_l, foot_l)
	_draw_foot(foot_l, foot_l_bone)
	_draw_limb(root, hip_r)
	_draw_limb(hip_r, knee_r)
	_draw_limb(knee_r, foot_r)
	_draw_foot(foot_r, foot_r_bone)

	# A restrained shoulder bridge keeps the upper body readable without
	# turning the prototype into a detailed anatomy diagram.
	_draw_limb(arm_l, arm_r)
	draw_circle(head, head_radius + 1.2, outline_color)
	draw_circle(head, head_radius, body_color)


func _arm_tip(shoulder: Vector2, arm_bone: Bone2D) -> Vector2:
	if arm_bone == null:
		return shoulder + Vector2(0.0, arm_length)
	# The existing arm bone rotation controls the direction; no extra elbow bones.
	var arm_direction := arm_bone.global_transform.basis_xform(Vector2(0.0, arm_length))
	return shoulder + arm_direction


func _draw_foot(ankle: Vector2, foot_bone: Bone2D) -> void:
	if foot_bone == null:
		return
	var toe_direction := foot_bone.global_transform.basis_xform(Vector2(6.0, 0.0))
	var toe := ankle + toe_direction
	_draw_limb(ankle, toe)


func _draw_limb(start: Vector2, finish: Vector2) -> void:
	draw_line(start, finish, outline_color, outline_width, true)
	draw_line(start, finish, body_color, body_width, true)
	draw_circle(start, outline_width * 0.5, outline_color)
	draw_circle(start, body_width * 0.5, body_color)
	draw_circle(finish, outline_width * 0.5, outline_color)
	draw_circle(finish, body_width * 0.5, body_color)


func _get_bone(relative_path: String) -> Bone2D:
	return skeleton.get_node_or_null(relative_path) as Bone2D


func _bone_position(relative_path: String) -> Vector2:
	var bone := _get_bone(relative_path)
	if bone == null:
		return Vector2.ZERO
	return bone.global_position - get_parent().global_position
