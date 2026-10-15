extends Node2D
class_name HumanoidCharacterVisual

## Reusable, gameplay-independent humanoid presentation rig.
## 可复用、与玩法逻辑解耦的人形角色表现骨架。
##
## This component owns only Skeleton2D/Bone2D transforms and Line2D/Polygon2D visuals.
## It does not own movement, collision, combat, dialogue, or interaction state.

@export var outline_color: Color = Color("#211d27")
@export var skin_color: Color = Color("#9c776f")
@export var cloth_color: Color = Color("#49424a")
@export var hurt_color: Color = Color("#c45d65")
@export_range(2.0, 10.0, 0.5) var outline_width: float = 5.5
@export_range(1.0, 5.0, 0.25) var inner_width: float = 2.5

var motion_state: String = "idle"
var facing: float = 1.0
var elapsed: float = 0.0
var _hurt_flash: bool = false
var _cloth_lines: Array[Line2D] = []

var _skeleton: Skeleton2D
var _root: Bone2D
var _spine: Bone2D
var _head: Bone2D
var _arm_left: Bone2D
var _arm_right: Bone2D
var _leg_left: Bone2D
var _leg_right: Bone2D
var _knee_left: Bone2D
var _knee_right: Bone2D
var _foot_left: Bone2D
var _foot_right: Bone2D


func _ready() -> void:
	_build_rig()
	_apply_pose()


func _process(delta: float) -> void:
	elapsed += delta
	_apply_pose()


## Presentation adapter API. Callers pass intent, not gameplay ownership.
## 表现层适配 API：调用方只传递表现意图，不转移玩法逻辑所有权。
func set_motion_state(next_state: String) -> void:
	motion_state = "run" if next_state == "run" else "idle"


func set_facing(direction: float) -> void:
	facing = -1.0 if direction < 0.0 else 1.0
	if _skeleton != null:
		_skeleton.scale.x = facing


func set_hurt_flash(active: bool) -> void:
	_hurt_flash = active
	_apply_cloth_palette()


func _build_rig() -> void:
	_skeleton = Skeleton2D.new()
	_skeleton.name = "Skeleton2D"
	add_child(_skeleton)

	_root = _make_bone(_skeleton, "RootBone", Vector2.ZERO)
	_spine = _make_bone(_root, "Spine", Vector2(0.0, -18.0))
	_head = _make_bone(_spine, "Head", Vector2(0.0, -12.0))
	_arm_left = _make_bone(_spine, "ArmLeft", Vector2(-9.5, 0.0))
	_arm_right = _make_bone(_spine, "ArmRight", Vector2(9.5, 0.0))
	_leg_left = _make_bone(_root, "LegLeft", Vector2(-3.5, 0.0))
	_leg_right = _make_bone(_root, "LegRight", Vector2(3.5, 0.0))
	_knee_left = _make_bone(_leg_left, "KneeLeft", Vector2(0.0, 12.0))
	_knee_right = _make_bone(_leg_right, "KneeRight", Vector2(0.0, 12.0))
	_foot_left = _make_bone(_knee_left, "FootLeft", Vector2(4.5, 10.0))
	_foot_right = _make_bone(_knee_right, "FootRight", Vector2(-4.5, 10.0))

	_add_segment(_spine, [Vector2.ZERO, Vector2(0.0, 18.0)], cloth_color, true)
	_add_head_shape(_head)
	_add_segment(_arm_left, [Vector2.ZERO, Vector2(0.0, 13.5)], cloth_color, true)
	_add_segment(_arm_right, [Vector2.ZERO, Vector2(0.0, 13.5)], cloth_color, true)
	_add_segment(_leg_left, [Vector2.ZERO, Vector2(0.0, 12.0)], cloth_color, true)
	_add_segment(_leg_right, [Vector2.ZERO, Vector2(0.0, 12.0)], cloth_color, true)
	_add_segment(_knee_left, [Vector2.ZERO, Vector2(0.0, 10.0)], cloth_color, true)
	_add_segment(_knee_right, [Vector2.ZERO, Vector2(0.0, 10.0)], cloth_color, true)
	_add_segment(_foot_left, [Vector2.ZERO, Vector2(6.0, 0.0)], cloth_color, true)
	_add_segment(_foot_right, [Vector2.ZERO, Vector2(6.0, 0.0)], cloth_color, true)
	_apply_cloth_palette()


func _make_bone(parent: Node, bone_name: String, bone_position: Vector2) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = bone_position
	parent.add_child(bone)
	return bone


func _add_segment(parent: Node2D, points: Array[Vector2], color: Color, is_cloth: bool) -> void:
	var outline := Line2D.new()
	outline.name = "SegmentOutline"
	outline.points = PackedVector2Array(points)
	outline.width = outline_width
	outline.default_color = outline_color
	outline.antialiased = true
	outline.joint_mode = Line2D.LINE_JOINT_ROUND
	outline.begin_cap_mode = Line2D.LINE_CAP_ROUND
	outline.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(outline)

	var inner := Line2D.new()
	inner.name = "SegmentFill"
	inner.points = PackedVector2Array(points)
	inner.width = inner_width
	inner.default_color = color
	inner.antialiased = true
	inner.joint_mode = Line2D.LINE_JOINT_ROUND
	inner.begin_cap_mode = Line2D.LINE_CAP_ROUND
	inner.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(inner)
	if is_cloth:
		_cloth_lines.append(inner)


func _add_head_shape(parent: Node2D) -> void:
	var fill := Polygon2D.new()
	fill.name = "HeadFill"
	fill.color = skin_color
	var points := PackedVector2Array()
	for index in range(21):
		var angle := TAU * float(index) / 20.0
		points.append(Vector2(cos(angle), sin(angle)) * 6.5)
	fill.polygon = points
	parent.add_child(fill)

	var outline := Line2D.new()
	outline.name = "HeadOutline"
	outline.points = points
	outline.closed = true
	outline.width = outline_width * 0.7
	outline.default_color = outline_color
	outline.antialiased = true
	parent.add_child(outline)


func _apply_pose() -> void:
	if _skeleton == null:
		return
	_skeleton.scale.x = facing
	var phase := elapsed * 9.5
	var swing := sin(phase) * 0.34 if motion_state == "run" else 0.0
	var bounce := absf(sin(phase * 2.0)) * 1.0 if motion_state == "run" else absf(sin(elapsed * 2.0)) * 0.25
	_root.position.y = -bounce
	_spine.rotation = ( -0.04 - absf(sin(phase)) * 0.02) if motion_state == "run" else sin(elapsed * 1.8) * 0.025
	_head.rotation = sin(elapsed * 1.8 + 0.4) * 0.025
	_arm_left.rotation = swing * 0.8 + 0.04
	_arm_right.rotation = -swing * 0.8 - 0.08
	_leg_left.rotation = -swing
	_leg_right.rotation = swing
	_knee_left.rotation = maxf(0.0, sin(phase + PI)) * 0.34 if motion_state == "run" else 0.0
	_knee_right.rotation = maxf(0.0, sin(phase)) * 0.34 if motion_state == "run" else 0.0
	_foot_left.rotation = -_leg_left.rotation * 0.5 - _knee_left.rotation * 0.35
	_foot_right.rotation = -_leg_right.rotation * 0.5 - _knee_right.rotation * 0.35


func _apply_cloth_palette() -> void:
	for line in _cloth_lines:
		if is_instance_valid(line):
			line.default_color = hurt_color if _hurt_flash else cloth_color
