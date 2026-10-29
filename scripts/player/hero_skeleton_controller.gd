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
	LAND,
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
@onready var knee_left_bone: Bone2D = $Skeleton2D/RootBone/LegLeftBone/KneeLeftBone
@onready var knee_right_bone: Bone2D = $Skeleton2D/RootBone/LegRightBone/KneeRightBone
@onready var foot_left_bone: Bone2D = $Skeleton2D/RootBone/LegLeftBone/KneeLeftBone/FootLeftBone
@onready var foot_right_bone: Bone2D = $Skeleton2D/RootBone/LegRightBone/KneeRightBone/FootRightBone
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
var _context_driven: bool = false
var _vertical_velocity: float = 0.0
var _grounded: bool = true
var _received_context: bool = false
var _was_grounded: bool = true
var _landing_time: float = 0.0
var _action_elapsed: float = 0.0
var _action_remaining: float = 0.0
var _windup_remaining: float = 0.0
var _action_kind: String = "none"
var _left_calf_line: Line2D
var _right_calf_line: Line2D
var _left_foot_line: Line2D
var _right_foot_line: Line2D
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
	# Normalize the presentation root before Skeleton2D computes any inverse transforms.
	scale = Vector2.ONE
	_capture_neutral_pose()
	_build_visuals()
	_apply_pose()


func _process(delta: float) -> void:
	animation_time += delta
	_pose_time += delta
	_landing_time = maxf(0.0, _landing_time - delta)
	# Standalone pose gallery drives itself; the production Hero supplies context every frame.
	if not _context_driven:
		_apply_pose()


## Optional presentation adapter entry point. The dictionary is read-only input.
## 可选的表现层适配入口；只读取正式 Hero 提供的状态快照。
func apply_visual_context(context: Dictionary) -> void:
	_context_driven = true
	weapon_style = str(context.get("weapon", "long_sword"))
	_vertical_velocity = float(context.get("vertical_velocity", 0.0))
	_grounded = bool(context.get("grounded", true))
	_action_elapsed = float(context.get("action_elapsed", 0.0))
	_action_remaining = float(context.get("attack_time_remaining", 0.0))
	_windup_remaining = float(context.get("attack_windup_remaining", 0.0))
	_action_kind = str(context.get("action_kind", "none"))
	if not _received_context:
		_received_context = true
		_was_grounded = _grounded
	elif _grounded and not _was_grounded:
		_landing_time = 0.12
	_was_grounded = _grounded
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
	if _landing_time > 0.0 and next_pose in [PoseState.IDLE, PoseState.RUN]:
		next_pose = PoseState.LAND
	set_pose(next_pose, int(context.get("combo_step", 1)), float(context.get("facing", 1.0)))


func set_pose(next_pose: PoseState, next_combo_step: int = 1, next_facing: float = 1.0) -> void:
	var next_step := clampi(next_combo_step, 1, 3)
	var next_direction := -1.0 if next_facing < 0.0 else 1.0
	if current_pose != next_pose or combo_step != next_step or not is_equal_approx(facing, next_direction):
		_pose_time = 0.0
	current_pose = next_pose
	combo_step = next_step
	facing = next_direction
	# Reassert a non-zero unit magnitude every time facing changes; never inherit a zero scale.
	scale = Vector2(facing, 1.0)
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
	for bone in [root_bone, body_bone, head_bone, arm_left_bone, arm_right_bone, leg_left_bone, leg_right_bone, knee_left_bone, knee_right_bone, foot_left_bone, foot_right_bone]:
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
	for line in [_left_calf_line, _right_calf_line, _left_foot_line, _right_foot_line]:
		if line:
			line.default_color = CLOTH
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
	_left_arm_line = _add_line(arm_left_bone, [Vector2.ZERO, Vector2(-8, 16)], line_width * 1.2, INK)
	_right_arm_line = _add_line(arm_right_bone, [Vector2.ZERO, Vector2(8, 16)], line_width * 1.2, INK)
	_left_leg_line = _add_line(leg_left_bone, [Vector2.ZERO, Vector2(0, 12)], line_width * 1.35, CLOTH)
	_right_leg_line = _add_line(leg_right_bone, [Vector2.ZERO, Vector2(0, 12)], line_width * 1.35, CLOTH)
	_left_calf_line = _add_line(knee_left_bone, [Vector2.ZERO, Vector2(1, 12)], line_width * 1.22, CLOTH)
	_right_calf_line = _add_line(knee_right_bone, [Vector2.ZERO, Vector2(-1, 12)], line_width * 1.22, CLOTH)
	_left_foot_line = _add_line(foot_left_bone, [Vector2.ZERO, Vector2(6, 0)], line_width * 0.9, CLOTH)
	_right_foot_line = _add_line(foot_right_bone, [Vector2.ZERO, Vector2(6, 0)], line_width * 0.9, CLOTH)
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
	var run_phase := animation_time * 11.5
	var run_cycle := sin(run_phase)
	var opposite_cycle := sin(run_phase + PI)
	var run_bounce := absf(sin(run_phase * 2.0)) * 3.2
	match current_pose:
		PoseState.IDLE:
			if animate_idle:
				var breath := sin(animation_time * 2.4)
				root_bone.position.y -= absf(breath) * 1.1
				body_bone.rotation = breath * 0.075
				head_bone.rotation = sin(animation_time * 2.4 + 0.55) * 0.05
				arm_right_bone.rotation = 0.16 + breath * 0.055
				arm_left_bone.rotation = -0.12 - breath * 0.045
				leg_left_bone.rotation = sin(animation_time * 1.6) * 0.045
				leg_right_bone.rotation = -sin(animation_time * 1.6) * 0.045
		PoseState.RUN:
			# Keep the hip swing narrow; the separated knee/calf chains provide stride without legs crossing.
			var swing := run_cycle * 0.62 if animate_run else 0.0
			var left_knee := maxf(0.0, opposite_cycle) * 0.62
			var right_knee := maxf(0.0, run_cycle) * 0.62
			root_bone.position.y -= run_bounce
			body_bone.rotation = -0.12 - absf(run_cycle) * 0.05
			arm_left_bone.rotation = swing * 0.95 + 0.08
			arm_right_bone.rotation = -swing * 0.95 - 0.20
			leg_left_bone.rotation = -swing
			leg_right_bone.rotation = swing
			knee_left_bone.rotation = left_knee
			knee_right_bone.rotation = right_knee
			foot_left_bone.rotation = -leg_left_bone.rotation * 0.55 - knee_left_bone.rotation * 0.4
			foot_right_bone.rotation = -leg_right_bone.rotation * 0.55 - knee_right_bone.rotation * 0.4
		PoseState.JUMP:
			# Arms lead the launch; legs tuck progressively less as upward velocity fades.
			var launch := clampf((-_vertical_velocity - 160.0) / 360.0, 0.0, 1.0)
			root_bone.position.y -= launch * 1.4
			body_bone.rotation = -0.12 - launch * 0.08
			head_bone.rotation = -0.08
			arm_left_bone.rotation = -0.65 - launch * 0.35
			arm_right_bone.rotation = 0.55 + launch * 0.25
			leg_left_bone.rotation = -0.18 - launch * 0.18
			leg_right_bone.rotation = 0.22 + launch * 0.14
			knee_left_bone.rotation = 0.28 + launch * 0.22
			knee_right_bone.rotation = 0.22 + launch * 0.2
			foot_left_bone.rotation = -0.1
			foot_right_bone.rotation = 0.12
		PoseState.FALL:
			# Open the silhouette on descent instead of repeating the jump pose.
			var fall_weight := clampf(_vertical_velocity / 520.0, 0.0, 1.0)
			body_bone.rotation = 0.18 + fall_weight * 0.12
			head_bone.rotation = 0.06
			arm_left_bone.rotation = -0.5 - fall_weight * 0.18
			arm_right_bone.rotation = 0.42 + fall_weight * 0.18
			leg_left_bone.rotation = 0.18
			leg_right_bone.rotation = -0.22
			knee_left_bone.rotation = 0.18 + fall_weight * 0.16
			knee_right_bone.rotation = 0.12 + fall_weight * 0.12
			foot_left_bone.rotation = -0.16
			foot_right_bone.rotation = 0.18
		PoseState.LAND:
			# Brief impact compression and recovery; no gameplay or collision timing is changed.
			var land := clampf(_landing_time / 0.12, 0.0, 1.0)
			var impact := sin((1.0 - land) * PI) if land > 0.0 else 0.0
			root_bone.position.y += impact * 2.0
			body_bone.rotation = impact * 0.12
			head_bone.rotation = impact * -0.08
			arm_left_bone.rotation = -0.25 - impact * 0.12
			arm_right_bone.rotation = 0.28 + impact * 0.12
			leg_left_bone.rotation = -0.12
			leg_right_bone.rotation = 0.12
			knee_left_bone.rotation = impact * 0.32
			knee_right_bone.rotation = impact * 0.32
			foot_left_bone.rotation = 0.04
			foot_right_bone.rotation = -0.04
		PoseState.ATTACK_LONG:
			# A four-beat cut: load, accelerate through target, follow through, then recover.
			var duration := maxf(0.01, _action_elapsed + _action_remaining)
			var phase := clampf(_action_elapsed / duration, 0.0, 1.0)
			var step_bias := 0.12 if combo_step == 1 else (0.28 if combo_step == 2 else -0.22)
			var loaded_body := -0.52 + step_bias
			var strike_body := 0.28 if combo_step == 3 else 0.12
			var loaded_arm := -1.45 + step_bias
			var strike_arm := 0.72 if combo_step == 3 else 0.35
			if phase < 0.25:
				var load := smoothstep(0.0, 0.25, phase)
				body_bone.rotation = lerpf(-0.12, loaded_body, load)
				arm_right_bone.rotation = lerpf(0.15, loaded_arm, load)
				arm_left_bone.rotation = lerpf(-0.08, 0.68, load)
			elif phase < 0.62:
				var strike := smoothstep(0.25, 0.62, phase)
				body_bone.rotation = lerpf(loaded_body, strike_body, strike)
				arm_right_bone.rotation = lerpf(loaded_arm, strike_arm, strike)
				arm_left_bone.rotation = lerpf(0.68, -0.32, strike)
			else:
				var recover := smoothstep(0.62, 1.0, phase)
				body_bone.rotation = lerpf(strike_body, 0.0, recover)
				arm_right_bone.rotation = lerpf(strike_arm, 0.12, recover)
				arm_left_bone.rotation = lerpf(-0.32, -0.08, recover)
			leg_left_bone.rotation = -0.22 - (1.0 - smoothstep(0.62, 1.0, phase)) * 0.08
			leg_right_bone.rotation = 0.18 + smoothstep(0.62, 1.0, phase) * 0.04
			knee_left_bone.rotation = 0.16
			knee_right_bone.rotation = 0.08
			_sword_line.points = PackedVector2Array([Vector2.ZERO, Vector2(38, -5)])
		PoseState.ATTACK_SHORT:
			# Compact wrist-led slashes: faster extension, little torso travel, immediate recoil.
			var duration := maxf(0.01, _action_elapsed + _action_remaining)
			var phase := clampf(_action_elapsed / duration, 0.0, 1.0)
			var strike := sin(clampf(phase / 0.72, 0.0, 1.0) * PI)
			body_bone.rotation = -0.08 - strike * 0.18
			arm_right_bone.rotation = lerpf(-0.22, 0.86, smoothstep(0.05, 0.32, phase))
			arm_right_bone.rotation = lerpf(arm_right_bone.rotation, -0.12, smoothstep(0.52, 1.0, phase))
			arm_left_bone.rotation = 0.08 + strike * 0.18
			leg_left_bone.rotation = -0.08
			leg_right_bone.rotation = 0.12
			knee_left_bone.rotation = 0.08
			knee_right_bone.rotation = 0.04
			_sword_line.points = PackedVector2Array([Vector2.ZERO, Vector2(19, -2)])
		PoseState.WEAPON_TECHNIQUE:
			var duration := maxf(0.01, _action_elapsed + _action_remaining)
			var phase := clampf(_action_elapsed / duration, 0.0, 1.0)
			match _action_kind:
				"iaijutsu":
					# Draw-and-cut: stillness, a compressed draw, then a long low finishing line.
					var draw := smoothstep(0.12, 0.48, phase)
					body_bone.rotation = lerpf(-0.38, 0.34, draw)
					arm_right_bone.rotation = lerpf(-1.2, 0.82, draw)
					arm_left_bone.rotation = lerpf(0.58, -0.32, draw)
					leg_left_bone.rotation = -0.28
					leg_right_bone.rotation = 0.22
					_sword_line.points = PackedVector2Array([Vector2.ZERO, Vector2(42, -3)])
				"judgment_slash":
					# Heavy overhead technique: deep load then a committed downward strike.
					var strike := smoothstep(0.32, 0.74, phase)
					body_bone.rotation = lerpf(-0.48, 0.58, strike)
					arm_right_bone.rotation = lerpf(-1.65, 1.05, strike)
					arm_left_bone.rotation = lerpf(0.82, -0.48, strike)
					leg_left_bone.rotation = -0.36
					leg_right_bone.rotation = 0.32
					knee_left_bone.rotation = 0.18
					knee_right_bone.rotation = 0.14
					_sword_line.points = PackedVector2Array([Vector2.ZERO, Vector2(43, 5)])
				"crescent_combo":
					# Three rapid cuts alternate direction rather than holding a single static pose.
					var wave := sin(phase * TAU * 1.5)
					body_bone.rotation = wave * 0.42
					arm_right_bone.rotation = wave * 0.88
					arm_left_bone.rotation = -wave * 0.42
					leg_left_bone.rotation = -0.2 - maxf(0.0, wave) * 0.12
					leg_right_bone.rotation = 0.18 + maxf(0.0, -wave) * 0.12
					_sword_line.points = PackedVector2Array([Vector2.ZERO, Vector2(35, -8)])
				"eldritch_echo":
					# A brief opening pose, as if the character is bracing against an unseen force.
					var pulse := sin(phase * PI)
					body_bone.rotation = -0.22 + pulse * 0.26
					arm_right_bone.rotation = -0.65 + pulse * 0.95
					arm_left_bone.rotation = 0.62 - pulse * 0.9
					leg_left_bone.rotation = -0.32
					leg_right_bone.rotation = 0.28
					_sword_line.points = PackedVector2Array([Vector2.ZERO, Vector2(34, -14)])
				_:
					body_bone.rotation = -0.32
					arm_right_bone.rotation = -1.15
					arm_left_bone.rotation = 0.62
					leg_left_bone.rotation = -0.28
					leg_right_bone.rotation = 0.26
			# Weapon skills use a visibly wider brace than ordinary attacks.
			arm_left_bone.rotation += 0.06 * sin(phase * PI)
		PoseState.GRAPPLE:
			var grapple_swing := sin(animation_time * 4.5)
			body_bone.rotation = -0.2 + grapple_swing * 0.045
			arm_left_bone.rotation = -1.0 + grapple_swing * 0.08
			arm_right_bone.rotation = -0.9 - grapple_swing * 0.08
			leg_left_bone.rotation = 0.25 + grapple_swing * 0.12
			leg_right_bone.rotation = -0.22 - grapple_swing * 0.12
			knee_left_bone.rotation = 0.2
			knee_right_bone.rotation = 0.3
		PoseState.WALL_CLIMB:
			var climb_cycle := sin(animation_time * 6.5)
			body_bone.rotation = -0.18
			arm_left_bone.rotation = -1.2 + climb_cycle * 0.18
			arm_right_bone.rotation = -0.8 - climb_cycle * 0.18
			leg_left_bone.rotation = -0.35 - climb_cycle * 0.2
			leg_right_bone.rotation = 0.45 + climb_cycle * 0.2
			knee_left_bone.rotation = maxf(0.0, climb_cycle) * 0.45
			knee_right_bone.rotation = maxf(0.0, -climb_cycle) * 0.45
		PoseState.DODGE:
			# One compact shoulder roll over the production dodge window. This is visual-only.
			var phase := clampf(_pose_time / 0.18, 0.0, 1.0)
			var tuck := sin(phase * PI)
			root_bone.rotation = TAU * smoothstep(0.0, 1.0, phase)
			body_bone.rotation = -0.58 + tuck * 0.12
			head_bone.rotation = 0.28
			arm_left_bone.rotation = 0.95
			arm_right_bone.rotation = -0.72
			leg_left_bone.rotation = 0.68
			leg_right_bone.rotation = -0.68
			knee_left_bone.rotation = 0.62
			knee_right_bone.rotation = 0.62
			foot_left_bone.rotation = -0.18
			foot_right_bone.rotation = 0.18
		PoseState.QUICK_DASH:
			var dash_phase := clampf(_pose_time / 0.16, 0.0, 1.0)
			var dash_recovery := smoothstep(0.55, 1.0, dash_phase)
			body_bone.rotation = lerpf(-0.72, -0.08, dash_recovery)
			arm_left_bone.rotation = lerpf(0.5, -0.12, dash_recovery)
			arm_right_bone.rotation = lerpf(-0.25, 0.18, dash_recovery)
			leg_left_bone.rotation = 0.34
			leg_right_bone.rotation = -0.3
		PoseState.HURT:
			var recoil := exp(-_pose_time * 7.0)
			body_bone.rotation = 0.42 * recoil
			head_bone.rotation = -0.22 * recoil
			arm_left_bone.rotation = -0.88 * recoil
			arm_right_bone.rotation = 0.92 * recoil
			leg_left_bone.rotation = 0.16
			leg_right_bone.rotation = -0.18
			_body_line.default_color = HURT_COLOR
			_head_line.default_color = HURT_COLOR
			_left_arm_line.default_color = HURT_COLOR
			_right_arm_line.default_color = HURT_COLOR
		PoseState.DEATH:
			var collapse := smoothstep(0.0, 0.48, _pose_time)
			root_bone.rotation = 1.15 * collapse
			body_bone.rotation = 0.65 * collapse
			head_bone.rotation = -0.4 * collapse
			arm_left_bone.rotation = -1.0 * collapse
			arm_right_bone.rotation = 1.2 * collapse
			leg_left_bone.rotation = 0.6 * collapse
			leg_right_bone.rotation = -0.75 * collapse
			knee_left_bone.rotation = 0.22 * collapse
			knee_right_bone.rotation = 0.3 * collapse
			_body_line.default_color = CLOTH
			_head_line.default_color = HURT_COLOR

	# Small overshoot and recoil are presentation-only; gameplay timing stays in hero.gd.
	var action_arc := sin(clampf(_pose_time / 0.32, 0.0, 1.0) * PI)
	match current_pose:
		PoseState.ATTACK_LONG:
			body_bone.rotation += action_arc * 0.06
			arm_right_bone.rotation += action_arc * 0.12
		PoseState.ATTACK_SHORT:
			body_bone.rotation += action_arc * 0.035
			arm_right_bone.rotation += action_arc * 0.08
		PoseState.WEAPON_TECHNIQUE:
			body_bone.rotation += action_arc * 0.08
			arm_right_bone.rotation += action_arc * 0.14
		PoseState.HURT:
			body_bone.rotation += sin(_pose_time * 36.0) * 0.025

