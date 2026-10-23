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
var _outline_lines: Array[Line2D] = []
var _head_fill: Polygon2D
var _head_outline: Line2D

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
	_skeleton = $Skeleton2D
	_root = $Skeleton2D/RootBone
	_spine = $Skeleton2D/RootBone/Spine
	_head = $Skeleton2D/RootBone/Spine/Head
	_arm_left = $Skeleton2D/RootBone/Spine/ArmLeft
	_arm_right = $Skeleton2D/RootBone/Spine/ArmRight
	_leg_left = $Skeleton2D/RootBone/LegLeft
	_leg_right = $Skeleton2D/RootBone/LegRight
	_knee_left = $Skeleton2D/RootBone/LegLeft/KneeLeft
	_knee_right = $Skeleton2D/RootBone/LegRight/KneeRight
	_foot_left = $Skeleton2D/RootBone/LegLeft/KneeLeft/FootLeft
	_foot_right = $Skeleton2D/RootBone/LegRight/KneeRight/FootRight
	_cloth_lines = [
		$Skeleton2D/RootBone/Spine/SpineFill,
		$Skeleton2D/RootBone/Spine/ArmLeft/ArmLeftFill,
		$Skeleton2D/RootBone/Spine/ArmRight/ArmRightFill,
		$Skeleton2D/RootBone/LegLeft/LegLeftFill,
		$Skeleton2D/RootBone/LegRight/LegRightFill,
		$Skeleton2D/RootBone/LegLeft/KneeLeft/KneeLeftFill,
		$Skeleton2D/RootBone/LegRight/KneeRight/KneeRightFill,
		$Skeleton2D/RootBone/LegLeft/KneeLeft/FootLeft/FootLeftFill,
		$Skeleton2D/RootBone/LegRight/KneeRight/FootRight/FootRightFill
	]
	_outline_lines = [
		$Skeleton2D/RootBone/Spine/SpineOutline,
		$Skeleton2D/RootBone/Spine/ArmLeft/ArmLeftOutline,
		$Skeleton2D/RootBone/Spine/ArmRight/ArmRightOutline,
		$Skeleton2D/RootBone/LegLeft/LegLeftOutline,
		$Skeleton2D/RootBone/LegRight/LegRightOutline,
		$Skeleton2D/RootBone/LegLeft/KneeLeft/KneeLeftOutline,
		$Skeleton2D/RootBone/LegRight/KneeRight/KneeRightOutline,
		$Skeleton2D/RootBone/LegLeft/KneeLeft/FootLeft/FootLeftOutline,
		$Skeleton2D/RootBone/LegRight/KneeRight/FootRight/FootRightOutline
	]
	_head_fill = $Skeleton2D/RootBone/Spine/Head/HeadFill
	_head_outline = $Skeleton2D/RootBone/Spine/Head/HeadOutline
	_apply_palette()
	_apply_pose()


func _process(delta: float) -> void:
	elapsed += delta
	_apply_pose()


func set_motion_state(next_state: String) -> void:
	motion_state = "run" if next_state == "run" else "idle"


func set_facing(direction: float) -> void:
	facing = -1.0 if direction < 0.0 else 1.0
	if _skeleton != null:
		_skeleton.scale.x = facing


func set_hurt_flash(active: bool) -> void:
	_hurt_flash = active
	_apply_cloth_palette()


func _apply_palette() -> void:
	for line in _outline_lines:
		line.default_color = outline_color
		line.width = outline_width
	for line in _cloth_lines:
		line.width = inner_width
	_head_fill.color = skin_color
	_head_outline.default_color = outline_color
	_head_outline.width = outline_width * 0.7
	_apply_cloth_palette()


func _apply_cloth_palette() -> void:
	for line in _cloth_lines:
		if is_instance_valid(line):
			line.default_color = hurt_color if _hurt_flash else cloth_color


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
