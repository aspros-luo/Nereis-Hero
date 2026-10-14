extends Node2D

# S1.2.2-A2/A4 Skeleton Visual Debug Layer
# Draws the articulated prototype rig without replacing production character art.

@export var enabled := true

@onready var skeleton: Skeleton2D = get_parent().get_node_or_null("Skeleton2D") as Skeleton2D


func _process(_delta: float) -> void:
	# Follow live Bone2D transforms so the overlay shows the complete walk cycle.
	if enabled:
		queue_redraw()


func _draw() -> void:
	if not enabled or skeleton == null:
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

	draw_line(root, spine, Color.WHITE, 3.0)
	draw_line(spine, head, Color.WHITE, 3.0)
	draw_line(spine, arm_l, Color.WHITE, 3.0)
	draw_line(spine, arm_r, Color.WHITE, 3.0)

	# Draw two actual leg segments per side, rather than a single pelvis-to-hip stub.
	draw_line(root, hip_l, Color.WHITE, 3.0)
	draw_line(hip_l, knee_l, Color.WHITE, 3.0)
	draw_line(knee_l, foot_l, Color.WHITE, 3.0)
	draw_line(root, hip_r, Color.WHITE, 3.0)
	draw_line(hip_r, knee_r, Color.WHITE, 3.0)
	draw_line(knee_r, foot_r, Color.WHITE, 3.0)

	draw_circle(head, 7.0, Color.WHITE)


func _bone_position(relative_path: String) -> Vector2:
	var bone := skeleton.get_node_or_null(relative_path) as Bone2D
	if bone == null:
		return Vector2.ZERO
	# Use the shared parent origin to avoid inverting a possibly singular debug transform.
	return bone.global_position - get_parent().global_position
