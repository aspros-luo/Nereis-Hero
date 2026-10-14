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
	WEAPON_TECHNIQUE,
	DODGE,
	QUICK_DASH,
	GRAPPLE,
	WALL_CLIMB,
	HURT,
	DEATH
}

@export var line_width: float = 6.0
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
var weapon_style: String = "long_sword"
var animation_time: float = 0.0
var _neutral_rotations: Dictionary = {}
var _neutral_positions: Dictionary = {}
var _pose_time: float = 0.0
var _head_fill: Polygon2D
var _sword_line: Line2D
var _body_line: Line2D
var _head_line: Line2D
var _left_arm_line: Line2D
var _right_arm_line: Line2D
var _left_leg_line: Line2D
var _right_leg_line: Line2D
var _cape_shape: Polygon2D
var _cape_outline: Line2D


func _ready() -> void:
	_capture_neutral_pose()
	_build_visuals()
	_apply_pose()


func _process(delta: float) -> void:
	animation_time += delta
	_pose_time += delta
	if current_pose == PoseState.RUN and animate_run:
		_apply_pose()
	elif current_pose == PoseState.IDLE and animate_idle:
		_apply_pose()


## Optional presentation adapter entry point. The dictionary is read-only input.
## 可选的表现层适配入口；只读取正式 Hero 提供的状态快照。
func apply_visual_context(context: Dictionary) -> void:
	weapon_style = str(context.get("weapon", "long_sword"))
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
		"grapple":
			next_pose = PoseState.GRAPPLE
		"wall_climb":
			next_pose = PoseState.WALL_CLIMB
		_:
			next_pose = PoseState.IDLE
	var action_kind := str(context.get("action_kind", "none"))
	if next_pose in [PoseState.ATTACK_LONG, PoseState.ATTACK_SHORT] and action_kind in ["judgment_slash", "crescent_combo", "eldritch_echo", "iaijutsu"]:
		next_pose = PoseState.WEAPON_TECHNIQUE
	set_pose(next_pose, int(context.get("combo_step", 1)), float(context.get("facing", 1.0)))


func set_pose(next_pose: PoseState, next_combo_step: int = 1, next_facing: float = 1.0) -> void:
	var next_step := clampi(next_combo_step, 1, 3)
	var next_direction := -1.0 if next_facing < 0.0 else 1.0
	if current_pose != next_pose or combo_step != next_step or not is_equal_approx(facing, next_direction):
		_pose_time = 0.0
	current_pose = next_pose
	combo_step = next_step
	facing = next_direction
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
		_neutral_positions[bone] = bone.position


func _reset_pose() -> void:
	# Always restore every bone before applying a pose: no transform can leak between states.
	for bone in _neutral_rotations:
		var node := bone as Bone2D
		if is_instance_valid(node):
			node.rotation = float(_neutral_rotations[bone])
			node.position = _neutral_positions[bone]
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
		_sword_line.points = PackedVector2Array([Vector2.ZERO, Vector2(19 if weapon_style == "short_blade" else 30, -2 if weapon_style == "short_blade" else -4)])


func _build_visuals() -> void:
	# A5 proportions: shorter torso/head stack, longer legs and arms to avoid the stretched-body silhouette.
	# A5 比例调整：缩短躯干与头部堆叠、加长四肢，避免身体过长、腿部过短。
	_body_line = _add_line(body_bone, [Vector2.ZERO, Vector2(0, 20)], line_width * 1.45, INK)
	_head_fill = _add_filled_circle(head_bone, 6.6, Color("#b7a9a0"))
	_head_line = _add_circle(head_bone, 6.8, maxf(2.8, line_width * 0.55), INK)
	_left_arm_line = _add_line(arm_left_bone, [Vector2.ZERO, Vector2(-17, 10)], line_width * 1.2, INK)
	_right_arm_line = _add_line(arm_right_bone, [Vector2.ZERO, Vector2(17, 10)], line_width * 1.2, INK)
	_left_leg_line = _add_line(leg_left_bone, [Vector2.ZERO, Vector2(1, 24)], line_width * 1.35, CLOTH)
	_right_leg_line = _add_line(leg_right_bone, [Vector2.ZERO, Vector2(-1, 24)], line_width * 1.35, CLOTH)
	# A restrained split cloak restores the protagonist's recognizable silhouette without replacing the rig.
	# 简洁的分叉披风补回主角轮廓特征，不改变骨骼控制结构。
	_cape_shape = Polygon2D.new()
	_cape_shape.name = "CloakSilhouette"
	_cape_shape.color = Color("#302831")
	_cape_shape.polygon = PackedVector2Array([Vector2(-7, -20), Vector2(7, -20), Vector2(13, -5), Vector2(22, 12), Vector2(11, 8), Vector2(5, 15), Vector2(-3, 5), Vector2(-14, 13), Vector2(-11, -5)])
	_cape_shape.z_index = -1
	root_bone.add_child(_cape_shape)
	_cape_outline = _add_line(root_bone, [Vector2(-7, -20), Vector2(7, -20), Vector2(13, -5), Vector2(22, 12), Vector2(11, 8), Vector2(5, 15), Vector2(-3, 5), Vector2(-14, 13), Vector2(-11, -5), Vector2(-7, -20)], maxf(1.5, line_width * 0.42), Color("#6e5966"))
	_cape_outline.z_index = -1
	_sword_line = _add_line(weapon_point, [Vector2.ZERO, Vector2(30, -4)], maxf(2.5, line_width * 0.72), METAL)
	_sword_line.z_index = 2


func _add_line(parent: Node2D, points: Array[Vector2], width: float, color: Color) -> Line2D:
	var line := Line2D.new()
	line.name = "PoseLine"
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.points = PackedVector2Array(points)
	parent.add_child(line)
	return line


func _add_filled_circle(parent: Node2D, radius: float, color: Color) -> Polygon2D:
	var shape := Polygon2D.new()
	shape.name = "FilledHeadSilhouette"
	shape.color = color
	var points := PackedVector2Array()
	for index in range(20):
		var angle := TAU * float(index) / 20.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	shape.polygon = points
	parent.add_child(shape)
	return shape


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
				# Quiet breathing, relaxed shoulders and a tiny weight shift keep the silhouette alive.
				var breath := sin(animation_time * 2.4)
				body_bone.rotation = breath * 0.035
				head_bone.rotation = sin(animation_time * 2.4 + 0.55) * 0.025
				arm_right_bone.rotation = 0.12 + breath * 0.025
				arm_left_bone.rotation = -0.08 - breath * 0.02
				leg_left_bone.rotation = sin(animation_time * 1.6) * 0.018
				leg_right_bone.rotation = -sin(animation_time * 1.6) * 0.018
		PoseState.RUN:
			var swing := run_cycle * 0.72 if animate_run else 0.0
			var bounce := absf(sin(animation_time * 11.0))
			body_bone.rotation = -0.12 - bounce * 0.035
			arm_left_bone.rotation = swing + 0.08
			arm_right_bone.rotation = -swing - 0.2
			leg_left_bone.rotation = -swing * 1.05
			leg_right_bone.rotation = swing * 1.05
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
		PoseState.WEAPON_TECHNIQUE:
			# A committed, open silhouette for weapon skills; combat timing remains in hero.gd.
			body_bone.rotation = -0.5 if combo_step < 3 else 0.62
			arm_right_bone.rotation = -1.35 if combo_step < 3 else 1.05
			arm_left_bone.rotation = 0.72
			leg_left_bone.rotation = -0.32
			leg_right_bone.rotation = 0.3
			var technique_length := 26.0 if weapon_style == "short_blade" else 40.0
			_sword_line.points = PackedVector2Array([Vector2.ZERO, Vector2(technique_length, -7)])
		PoseState.GRAPPLE:
			body_bone.rotation = -0.2
			arm_left_bone.rotation = -1.0
			arm_right_bone.rotation = -0.9
			leg_left_bone.rotation = 0.25
			leg_right_bone.rotation = -0.22
		PoseState.WALL_CLIMB:
			body_bone.rotation = -0.18
			arm_left_bone.rotation = -1.2
			arm_right_bone.rotation = -0.8
			leg_left_bone.rotation = -0.35
			leg_right_bone.rotation = 0.45
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

	# Short follow-through arcs add anticipation/recoil without owning combat timing.
	# 短促的蓄势与回弹只影响视觉，不改变正式战斗计时。
	var action_arc := sin(clampf(_pose_time / 0.32, 0.0, 1.0) * PI)
	match current_pose:
		PoseState.ATTACK_LONG:
			body_bone.rotation += action_arc * (0.10 if combo_step < 3 else 0.16)
			arm_right_bone.rotation += action_arc * 0.16
		PoseState.ATTACK_SHORT:
			body_bone.rotation += action_arc * 0.07
			arm_right_bone.rotation += action_arc * 0.12
		PoseState.WEAPON_TECHNIQUE:
			body_bone.rotation += action_arc * 0.12
			arm_right_bone.rotation += action_arc * 0.2
		PoseState.JUMP:
			arm_left_bone.rotation += sin(animation_time * 5.0) * 0.035
			arm_right_bone.rotation -= sin(animation_time * 5.0) * 0.035
		PoseState.FALL:
			arm_left_bone.rotation += sin(animation_time * 4.0) * 0.045
			arm_right_bone.rotation -= sin(animation_time * 4.0) * 0.045
		PoseState.DODGE, PoseState.QUICK_DASH:
			body_bone.rotation += sin(animation_time * 20.0) * 0.025
		PoseState.HURT:
			body_bone.rotation += sin(_pose_time * 36.0) * 0.035

