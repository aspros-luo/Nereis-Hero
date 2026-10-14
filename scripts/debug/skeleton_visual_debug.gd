extends Node2D

# S1.2.2-A2/A3 Skeleton Visual Debug Layer
# Draws a lightweight bone-following reference without replacing production art.

@export var enabled := true

@onready var skeleton: Skeleton2D = get_parent().get_node_or_null("Skeleton2D") as Skeleton2D


func _process(_delta: float) -> void:
    # Bone2D rotations are driven by AnimationPlayer; redraw so the debug rig
    # visibly follows those transforms while the prototype is running.
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
    var leg_l := _bone_position("RootBone/Leg_L")
    var leg_r := _bone_position("RootBone/Leg_R")

    draw_line(root, spine, Color.WHITE, 3.0)
    draw_line(spine, head, Color.WHITE, 3.0)
    draw_line(spine, arm_l, Color.WHITE, 3.0)
    draw_line(spine, arm_r, Color.WHITE, 3.0)
    draw_line(root, leg_l, Color.WHITE, 3.0)
    draw_line(root, leg_r, Color.WHITE, 3.0)
    draw_circle(head, 7.0, Color.WHITE)


func _bone_position(relative_path: String) -> Vector2:
    var bone := skeleton.get_node_or_null(relative_path) as Bone2D
    if bone == null:
        return Vector2.ZERO
    return to_local(bone.global_position)
