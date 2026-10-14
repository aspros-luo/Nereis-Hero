extends Node2D

# S1.2.2-A5: independent stickman presentation layer.
# This renderer follows the rig but is separate from the technical debug overlay.

@export var outline_color := Color(0.12, 0.11, 0.14, 1.0)
@export var body_color := Color(0.88, 0.86, 0.80, 1.0)
@export var outline_width: float = 7.0
@export var body_width: float = 4.0
@export var head_radius: float = 7.0

@onready var skeleton: Skeleton2D = get_parent().get_node_or_null("Skeleton2D") as Skeleton2D


func _process(_delta: float) -> void:
	# The rig moves every animation frame, so redraw from current bone transforms.
	queue_redraw()


func _draw() -> void:
	if skeleton == null:
		return

	var root := _bone_position("RootBone")
	var spine := _bone_position("RootBone/Spine")
	var head := _bone_position("RootBone/Spine/Head")
	var arm_l := _bone_position("RootBone/Spine/Arm_L")
	var arm_r := _bone_position("RootBone/Spine/Arm_R")
	var hip_l := _bone_position("RootBone/Leg_L")
	var knee_l := _bone_position("RootBone/Leg_L/Knee_L")
	var foot_l := _bone_position("RootBone/Leg_L/Knee_L/Foot_L")
	var hip_r := _bone_position("RootBone/Leg_R")
	var knee_r := _bone_position("RootBone/Leg_R/Knee_R")
	var foot_r := _bone_position("RootBone/Leg_R/Knee_R/Foot_R")

	# Dark outline + warm inner stroke gives the prototype a character silhouette,
	# while the F3 overlay remains a separate, pure-white technical visualization.
	_draw_limb(root, spine)
	_draw_limb(spine, head)
	_draw_limb(spine, arm_l)
	_draw_limb(spine, arm_r)
	_draw_limb(root, hip_l)
	_draw_limb(hip_l, knee_l)
	_draw_limb(knee_l, foot_l)
	_draw_limb(root, hip_r)
	_draw_limb(hip_r, knee_r)
	_draw_limb(knee_r, foot_r)

	draw_circle(head, head_radius + 1.5, outline_color)
	draw_circle(head, head_radius, body_color)


func _draw_limb(start: Vector2, finish: Vector2) -> void:
	draw_line(start, finish, outline_color, outline_width, true)
	draw_line(start, finish, body_color, body_width, true)
	draw_circle(start, outline_width * 0.5, outline_color)
	draw_circle(start, body_width * 0.5, body_color)
	draw_circle(finish, outline_width * 0.5, outline_color)
	draw_circle(finish, body_width * 0.5, body_color)


func _bone_position(relative_path: String) -> Vector2:
	var bone := skeleton.get_node_or_null(relative_path) as Bone2D
	if bone == null:
		return Vector2.ZERO
	return bone.global_position - get_parent().global_position
