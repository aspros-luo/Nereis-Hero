extends Node2D
class_name HeroSkeletonController

## Phase S1.2.3-A2 skeletal pose prototype.
## Visual-only: never changes gameplay, hitboxes, stamina, damage or progression.
## S1.2.3-A2 骨骼姿势原型。仅控制表现，不修改战斗规则、判定、体力、伤害或进度。

enum PoseState {
	IDLE,
	RUN,
	JUMP,
	FALL,
	ATTACK_LONG,
	ATTACK_SHORT,
	DODGE,
	QUICK_DASH,
	HURT,
	DEATH
}

@export var line_width: float = 4.5
@export var animate_idle: bool = true
@export var animate_run: bool = true

@onready var root_bone: Bone2D = $Skeleton2D/RootBone
@onready var body_bone: Bone2D = $Skeleton2D/RootBone/BodyBone
@onready var head_bone: Bone2D = $Skeleton2D/RootBone/BodyBone/HeadBone
@onready var arm_left_bone: Bone2D = $Skeleton2D/RootBone/BodyBone/ArmLeftBone
@onready var arm_right_bone: Bone2D = $Skeleton2D/RootBone/BodyBone/ArmRightBone
@onready var leg_left_bone: Bone2D = $Skeleton2D/RootBone/LegLeftBone
@onready var leg_right_bone: Bone2D = $Skeleton2D/RootBone/LegRightBone
@onready var weapon_point: Marker2D = $Skeleton2D/RootBone/BodyBone/ArmRightBone/HandRightBone/WeaponPoint

const INK := Color("#211d27")
const CLOTH := Color("#6e5966")
const METAL := Color("#d8c8a9")
const HURT_COLOR := Color("#e06b73")

var current_pose: PoseState = PoseState.IDLE
var combo_step: int = 1
var facing: float = 1.0
var animation_time: float = 0.0
var _neutral_rotations: Dictionary = {}
var _sword_line: Line2D
var _body_line: Line2D
var _head_line: Line2D
var _left_arm_line: Line2D
var _right_arm_line: Line2D
var _left_leg_line: Line2D
var _right_leg_line: Line2D


func _ready() -> void:
	_capture_neutral_pose()
	_build_visuals()
	_apply_pose()


func _process(delta: float) -> void:
	animation_time += delta
	if current_pose == PoseState.RUN and animate_run:
		_apply_pose()
	elif current_pose == PoseState.IDLE and animate_idle:
		_apply_pose()


## Optional presentation adapter entry point. The dictionary is read-only input.
## 可选的表现层适配入口；只读取正式 Hero 提供的状态快照。
func apply_visual_context(context: Dictionary) -> void:
	var state_name := str(context.get("state", "idle"))
	var next_pose := PoseState.IDLE
	match state_name:
		"run":
			next_pose = PoseState.RUN
		"jump":
			next_pose = PoseState.JUMP
		"fall":
			next_pose = PoseState.FALL
		"attack_long":
			next_pose = PoseState.ATTACK_LONG
		"attack_short":
			next_pose = PoseState.ATTACK_SHORT
		"dodge":
			next_pose = PoseState.DODGE
		"quick_dash":
			next_pose = PoseState.QUICK_DASH
		"hurt":
			next_pose = PoseState.HURT
		"death":
			next_pose = PoseState.DEATH
		_:
			next_pose = PoseState.IDLE
	set_pose(next_pose, int(context.get("combo_step", 1)), float(context.get("facing", 1.0)))


func set_pose(next_pose: PoseState, next_combo_step: int = 1, next_facing: float = 1.0) -> void:
	current_pose = next_pose
	combo_step = clampi(next_combo_step, 1, 3)
	facing = -1.0 if next_facing < 0.0 else 1.0
	scale.x = absf(scale.x) * facing
	_apply_pose()


func play_idle() -> void:
	set_pose(PoseState.IDLE, combo_step, facing)


func play_run() -> void:
	set_pose(PoseState.RUN, combo_step, facing)


func play_long_attack(step: int = 1, direction: float = 1.0) -> void:
	set_pose(PoseState.ATTACK_LONG, step, direction)


func play_short_attack(step: int = 1, direction: float = 1.0) -> void:
	set_pose(PoseState.ATTACK_SHORT, step, direction)


func play_dodge(direction: float = 1.0) -> void:
	set_pose(PoseState.DODGE, combo_step, direction)


func play_hurt(direction: float = 1.0) -> void:
	set_pose(PoseState.HURT, combo_step, direction)


func play_death(direction: float = 1.0) -> void:
	set_pose(PoseState.DEATH, combo_step, direction)


func _capture_neutral_pose() -> void:
	for bone in [root_bone, body_bone, head_bone, arm_left_bone, arm_right_bone, leg_left_bone, leg_right_bone]:
		_neutral_rotations[bone] = bone.rotation


func _reset_pose() -> void:
	# Always restore every bone before applying a pose: no transform can leak between states.
	for bone in _neutral_rotations:
		var node := bone as Bone2D
		if is_instance_valid(node):
			node.rotation = float(_neutral_rotations[bone])
	if _body_line:
		_body_line.default_color = INK
	if _head_line:
		_head_line.default_color = INK
	if _left_arm_line:
		_left_arm_line.default_color = INK
	if _right_arm_line:
		_right_arm_line.default_color = INK
	if _left_leg_line:
		_left_leg_line.default_color = CLOTH
	if _right_leg_line:
		_right_leg_line.default_color = CLOTH
	if _sword_line:
		# Restore the neutral long-sword silhouette before each pose applies its own weapon shape.
		# 每次切换姿势先恢复默认长剑轮廓，短刃姿势再显式缩短，避免武器形态残留。
		_sword_line.points = PackedVector2Array([Vector2.ZERO, Vector2(30, -4)])


func _build_visuals() -> void:
	_body_line = _add_line(body_bone, [Vector2.ZERO, Vector2(0, 23)], line_width, INK)
	_head_line = _add_circle(head_bone, 8.0, line_width, INK)
	_left_arm_line = _add_line(arm_left_bone, [Vector2.ZERO, Vector2(-15, 9)], line_width, INK)
	_right_arm_line = _add_line(arm_right_bone, [Vector2.ZERO, Vector2(15, 9)], line_width, INK)
	_left_leg_line = _add_line(leg_left_bone, [Vector2.ZERO, Vector2(1, 20)], line_width, CLOTH)
	_right_leg_line = _add_line(leg_right_bone, [Vector2.ZERO, Vector2(-1, 20)], line_width, CLOTH)
	_sword_line = _add_line(weapon_point, [Vector2.ZERO, Vector2(30, -4)], maxf(2.5, line_width * 0.72), METAL)
	_sword_line.z_index = 2


func _add_line(parent: Node2D, points: Array[Vector2], width: float, color: Color) -> Line2D:
	var line := Line2D.new()
	line.name = "PoseLine"
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.points = PackedVector2Array(points)
	parent.add_child(line)
	return line


func _add_circle(parent: Node2D, radius: float, width: float, color: Color) -> Line2D:
	var points := PackedVector2Array()
	for index in range(17):
		var angle := TAU * float(index) / 16.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	var line := Line2D.new()
	line.name = "HeadOutline"
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.closed = true
	line.points = points
	parent.add_child(line)
	return line


func _apply_pose() -> void:
	_reset_pose()
	var run_cycle := sin(animation_time * 11.0)
	match current_pose:
		PoseState.IDLE:
			if animate_idle:
				body_bone.rotation = sin(animation_time * 2.8) * 0.025
				head_bone.rotation = sin(animation_time * 2.8 + 0.5) * 0.025
				arm_right_bone.rotation = 0.12
				arm_left_bone.rotation = -0.08
		PoseState.RUN:
			var swing := run_cycle * 0.62 if animate_run else 0.0
			body_bone.rotation = -0.08
			arm_left_bone.rotation = swing
			arm_right_bone.rotation = -swing - 0.18
			leg_left_bone.rotation = -swing * 0.9
			leg_right_bone.rotation = swing * 0.9
		PoseState.JUMP:
			body_bone.rotation = -0.12
			arm_left_bone.rotation = -0.85
			arm_right_bone.rotation = 0.65
			leg_left_bone.rotation = -0.35
			leg_right_bone.rotation = 0.48
		PoseState.FALL:
			body_bone.rotation = 0.28
			arm_left_bone.rotation = -0.5
			arm_right_bone.rotation = 0.45
			leg_left_bone.rotation = 0.25
			leg_right_bone.rotation = -0.2
		PoseState.ATTACK_LONG:
			# Three silhouettes: measured cut, committed cross-cut, heavy finishing strike.
			match combo_step:
				1:
					body_bone.rotation = -0.18
					arm_right_bone.rotation = -0.78
					arm_left_bone.rotation = 0.3
					leg_left_bone.rotation = -0.12
				2:
					body_bone.rotation = -0.42
					arm_right_bone.rotation = -1.42
					arm_left_bone.rotation = 0.68
					leg_left_bone.rotation = -0.3
					leg_right_bone.rotation = 0.22
				3:
					body_bone.rotation = 0.48
					arm_right_bone.rotation = 0.92
					arm_left_bone.rotation = -0.95
					leg_left_bone.rotation = -0.55
					leg_right_bone.rotation = 0.42
			_sword_line.points = PackedVector2Array([Vector2.ZERO, Vector2(36, -5)])
		PoseState.ATTACK_SHORT:
			# Compact, fast wrist-led cuts; the third hit has a low, extended finish.
			match combo_step:
				1:
					body_bone.rotation = -0.08
					arm_right_bone.rotation = -0.38
					arm_left_bone.rotation = 0.12
				2:
					body_bone.rotation = -0.22
					arm_right_bone.rotation = -1.0
					arm_left_bone.rotation = 0.38
					leg_right_bone.rotation = 0.12
				3:
					body_bone.rotation = 0.3
					arm_right_bone.rotation = 0.72
					arm_left_bone.rotation = -0.48
					leg_left_bone.rotation = -0.42
			_sword_line.points = PackedVector2Array([Vector2.ZERO, Vector2(19, -2)])
		PoseState.DODGE:
			body_bone.rotation = -0.55
			head_bone.rotation = 0.3
			arm_left_bone.rotation = 0.95
			arm_right_bone.rotation = -0.72
			leg_left_bone.rotation = 0.82
			leg_right_bone.rotation = -0.9
		PoseState.QUICK_DASH:
			body_bone.rotation = -0.72
			arm_left_bone.rotation = 0.5
			arm_right_bone.rotation = -0.25
			leg_left_bone.rotation = 0.45
			leg_right_bone.rotation = -0.4
		PoseState.HURT:
			body_bone.rotation = 0.42
			head_bone.rotation = -0.22
			arm_left_bone.rotation = -0.88
			arm_right_bone.rotation = 0.92
			leg_left_bone.rotation = 0.16
			leg_right_bone.rotation = -0.18
			_body_line.default_color = HURT_COLOR
			_head_line.default_color = HURT_COLOR
			_left_arm_line.default_color = HURT_COLOR
			_right_arm_line.default_color = HURT_COLOR
		PoseState.DEATH:
			root_bone.rotation = 1.15
			body_bone.rotation = 0.65
			head_bone.rotation = -0.4
			arm_left_bone.rotation = -1.0
			arm_right_bone.rotation = 1.2
			leg_left_bone.rotation = 0.6
			leg_right_bone.rotation = -0.75
			_body_line.default_color = CLOTH
			_head_line.default_color = HURT_COLOR

