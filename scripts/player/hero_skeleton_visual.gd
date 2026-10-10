extends Node2D
# Rigid cutout rig built from source-matched SVG layers.
# 分层骨骼原型：所有部件共享 192x224 画布，关节以原图像素坐标定义。

const CAPE_TEXTURE: Texture2D = preload("res://assets/art/characters/rig_parts/hero_cape.svg")
const REAR_LEG_TEXTURE: Texture2D = preload("res://assets/art/characters/rig_parts/hero_rear_leg.svg")
const FRONT_LEG_TEXTURE: Texture2D = preload("res://assets/art/characters/rig_parts/hero_front_leg.svg")
const TORSO_TEXTURE: Texture2D = preload("res://assets/art/characters/rig_parts/hero_torso.svg")
const REAR_ARM_TEXTURE: Texture2D = preload("res://assets/art/characters/rig_parts/hero_rear_arm.svg")
const FRONT_ARM_TEXTURE: Texture2D = preload("res://assets/art/characters/rig_parts/hero_front_arm.svg")
const HEAD_TEXTURE: Texture2D = preload("res://assets/art/characters/rig_parts/hero_head.svg")
const LONG_WEAPON_TEXTURE: Texture2D = preload("res://assets/art/characters/rig_parts/hero_weapon_long.svg")
const SHORT_WEAPON_TEXTURE: Texture2D = preload("res://assets/art/characters/rig_parts/hero_weapon_short.svg")

const SOURCE_ANCHOR := Vector2(96.0, 220.0)
const RIG_SCALE := 0.5

var skeleton: Skeleton2D
var bones: Dictionary = {}
var part_sprites: Dictionary = {}
var weapon_sprite: Sprite2D
var last_state_name := "IDLE"
var pose_blend := 1.0

func _ready() -> void:
	_build_rig()
	update_pose("IDLE", 0.0, 1.0, Vector2.ZERO, 0.0, false, 0.0, false, false, false)

func _build_rig() -> void:
	skeleton = Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	skeleton.scale = Vector2(RIG_SCALE, RIG_SCALE)
	add_child(skeleton)

	var pelvis := _add_bone("Pelvis", skeleton, Vector2(96, 156), SOURCE_ANCHOR, null, 0)
	var rear_leg := _add_bone("RearLeg", pelvis, Vector2(70, 160), Vector2(96, 156), REAR_LEG_TEXTURE, -3)
	var front_leg := _add_bone("FrontLeg", pelvis, Vector2(119, 158), Vector2(96, 156), FRONT_LEG_TEXTURE, -2)
	var torso := _add_bone("Torso", pelvis, Vector2(95, 128), Vector2(96, 156), TORSO_TEXTURE, -1)
	_add_bone("Cape", torso, Vector2(94, 79), Vector2(95, 128), CAPE_TEXTURE, -4)
	_add_bone("RearArm", torso, Vector2(63, 90), Vector2(95, 128), REAR_ARM_TEXTURE, 0)
	_add_bone("FrontArm", torso, Vector2(120, 91), Vector2(95, 128), FRONT_ARM_TEXTURE, 1)
	_add_bone("Head", torso, Vector2(98, 70), Vector2(95, 128), HEAD_TEXTURE, 2)
	_add_bone("Weapon", bones["FrontArm"], Vector2(128, 111), Vector2(120, 91), LONG_WEAPON_TEXTURE, 3)

	# Root anchor and all joints use the source image's coordinate system.
	assert(rear_leg != null and front_leg != null and torso != null)

func _add_bone(
	bone_name: String,
	parent: Node,
	pivot: Vector2,
	parent_pivot: Vector2,
	texture: Texture2D,
	draw_order: int
) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = pivot - parent_pivot
	parent.add_child(bone)
	bones[bone_name] = bone

	if texture != null:
		var sprite := Sprite2D.new()
		sprite.name = bone_name + "Sprite"
		sprite.texture = texture
		sprite.centered = false
		# Keep each complete source canvas and put its joint at local (0,0).
		sprite.position = -pivot
		sprite.z_index = draw_order
		bone.add_child(sprite)
		part_sprites[bone_name] = sprite
		if bone_name == "Weapon":
			weapon_sprite = sprite
	return bone

func update_pose(
	state_name: String,
	elapsed: float,
	facing: float,
	velocity: Vector2,
	move_ratio: float,
	attack_windup: bool,
	attack_progress: float,
	short_blade: bool,
	hurt: bool,
	hit_flash: bool
) -> void:
	if skeleton == null:
		return

	var facing_sign := -1.0 if facing < 0.0 else 1.0
	var local_motion := clampf((velocity.x * facing_sign) / 260.0, -1.0, 1.0)
	# Keep the rig anchored to the feet. Compression changes limb posture, not the world anchor.
	# 骨架始终以脚底为锚点；压缩只影响姿势，不改变世界锚点。
	skeleton.scale = Vector2(RIG_SCALE * facing_sign, RIG_SCALE)
	skeleton.rotation = 0.0
	if state_name != last_state_name:
		pose_blend = 0.0
		last_state_name = state_name
	pose_blend = minf(1.0, pose_blend + 0.16)
	modulate = Color("#d98f99") if hurt else Color("#f3e6d4") if hit_flash else Color.WHITE

	for bone_value in bones.values():
		var bone := bone_value as Bone2D
		if bone != null:
			bone.rotation = 0.0

	if weapon_sprite != null:
		weapon_sprite.texture = SHORT_WEAPON_TEXTURE if short_blade else LONG_WEAPON_TEXTURE

	var run_phase := elapsed * 13.0
	match state_name:
		"IDLE":
			_set_rotation("Torso", sin(elapsed * 1.7) * 0.012)
			_set_rotation("Head", sin(elapsed * 1.55) * 0.018)
			_set_rotation("Cape", sin(elapsed * 2.0) * 0.035)
			_set_rotation("RearArm", sin(elapsed * 1.3) * 0.012)
			_set_rotation("FrontArm", sin(elapsed * 1.4) * -0.010)
		"MOVE":
			_set_rotation("RearLeg", sin(run_phase) * 0.44 * maxf(move_ratio, 0.5))
			_set_rotation("FrontLeg", sin(run_phase + PI) * 0.44 * maxf(move_ratio, 0.5))
			_set_rotation("RearArm", -sin(run_phase) * 0.16)
			_set_rotation("FrontArm", sin(run_phase) * 0.10)
			_set_rotation("Torso", -0.025 * clampf(move_ratio, 0.0, 1.0))
			_set_rotation("Cape", sin(run_phase) * 0.04)
		"JUMP":
			_set_rotation("Torso", -local_motion * 0.055)
			_set_rotation("RearLeg", -0.30)
			_set_rotation("FrontLeg", 0.28)
			_set_rotation("RearArm", -0.38)
			_set_rotation("FrontArm", -0.22)
			_set_rotation("Cape", 0.10)
		"FALL":
			_set_rotation("Torso", -local_motion * 0.045)
			_set_rotation("RearLeg", -0.12)
			_set_rotation("FrontLeg", 0.34)
			_set_rotation("RearArm", -0.50)
			_set_rotation("FrontArm", -0.28)
			_set_rotation("Cape", -0.08)
		"ATTACK":
			var strike := clampf(attack_progress, 0.0, 1.0)
			if attack_windup:
				_set_rotation("Torso", -0.075)
				_set_rotation("FrontArm", -0.22)
				_set_rotation("Weapon", -0.48)
				_set_rotation("RearArm", -0.12)
				_set_rotation("Cape", 0.08)
			else:
				# Three distinct arcs prevent every combo hit from reading as the same swing.
				# 三段连击采用不同挥动弧线，避免每一击看起来都相同。
				var combo_phase: int = mini(int(floor(strike * 3.0)), 2)
				var local_phase: float = fposmod(strike * 3.0, 1.0)
				var torso_end: float = [0.12, -0.10, 0.18][combo_phase]
				var arm_start: float = [-0.20, 0.18, -0.32][combo_phase]
				var arm_end: float = [0.32, -0.24, 0.42][combo_phase]
				var weapon_start: float = [-0.55, 0.62, -0.78][combo_phase]
				var weapon_end: float = [1.18, -0.92, 1.32][combo_phase]
				_set_rotation("Torso", lerpf(-0.06, torso_end, strike))
				_set_rotation("FrontArm", lerpf(arm_start, arm_end, local_phase))
				_set_rotation("Weapon", lerpf(weapon_start, weapon_end, local_phase))
				_set_rotation("RearArm", lerpf(-0.12, 0.18, strike))
				_set_rotation("Cape", sin(strike * PI) * 0.10)
		"GRAPPLE":
			_set_rotation("Torso", -0.06)
			_set_rotation("FrontArm", -0.85)
			_set_rotation("Weapon", -0.20)
			_set_rotation("RearArm", 0.22)
			_set_rotation("Cape", -0.12)
		"DODGE":
			skeleton.scale.y = RIG_SCALE * 0.84
			_set_rotation("Torso", 0.16)
			_set_rotation("RearLeg", -0.48)
			_set_rotation("FrontLeg", 0.35)
			_set_rotation("RearArm", -0.50)
			_set_rotation("FrontArm", 0.34)
			_set_rotation("Cape", 0.18)
		"QUICK_DASH":
			skeleton.scale.y = RIG_SCALE * 0.76
			_set_rotation("Torso", 0.20)
			_set_rotation("RearLeg", -0.36)
			_set_rotation("FrontLeg", 0.22)
			_set_rotation("RearArm", -0.40)
			_set_rotation("FrontArm", 0.28)
			_set_rotation("Cape", 0.20)
		"WALL_CLIMB":
			_set_rotation("Torso", -0.08)
			_set_rotation("RearArm", -0.65 + sin(elapsed * 12.0) * 0.035)
			_set_rotation("FrontArm", -0.75 - sin(elapsed * 12.0) * 0.035)
			_set_rotation("RearLeg", 0.28)
			_set_rotation("FrontLeg", -0.32)
			_set_rotation("Cape", -0.10)
		"HURT":
			_set_rotation("Torso", -0.18)
			_set_rotation("Head", 0.12)
			_set_rotation("RearArm", -0.25)
			_set_rotation("FrontArm", 0.35)
			_set_rotation("Cape", -0.10)
		"DEAD":
			_set_rotation("Torso", 0.42)
			_set_rotation("Head", 0.12)
			_set_rotation("RearLeg", -0.18)
			_set_rotation("FrontLeg", 0.36)
			_set_rotation("RearArm", -0.36)
			_set_rotation("FrontArm", 0.40)
			_set_rotation("Cape", -0.22)
		_:
			pass

func _set_rotation(bone_name: String, angle: float) -> void:
	var bone := bones.get(bone_name) as Bone2D
	if bone != null:
		# Blend state changes instead of snapping joints between unrelated poses.
		# 状态切换时平滑过渡关节，避免动作姿势突然跳变。
		bone.rotation = lerp_angle(bone.rotation, angle, pose_blend)
