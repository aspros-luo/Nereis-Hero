extends Node2D
# Polygon2D atlas skin bound to Skeleton2D / Bone2D.
# 使用单张部件图集的 UV 多边形，并通过顶点权重绑定到真实骨骼。

const PARTS_ATLAS: Texture2D = preload("res://assets/art/characters/hero_parts_atlas.webp")

# The reduced atlas was packed from selected pieces in the 320x207 working atlas.
# UV source rectangles below are specified in that working-atlas coordinate system.
const ATLAS_SOURCE_SIZE := Vector2(320.0, 207.0)
const ATLAS_TEXTURE_SIZE := Vector2(112.0, 73.0)
const ATLAS_UV_SCALE := ATLAS_TEXTURE_SIZE / ATLAS_SOURCE_SIZE

const UV_SCABBARD := Rect2(1, 1, 15, 127)
const UV_LIMB := Rect2(20, 1, 25, 69)
const UV_LIMB_UPPER := Rect2(20, 1, 25, 42)
const UV_LIMB_LOWER := Rect2(20, 38, 25, 32)
const UV_HEAD := Rect2(50, 1, 50, 57)
const UV_GREEN_ARMOR := Rect2(159, 1, 41, 51)
const UV_DARK_ARMOR := Rect2(204, 1, 42, 50)
const UV_HAIR := Rect2(251, 1, 50, 49)
const UV_BELT := Rect2(1, 133, 33, 40)
const UV_HAIR_TUFT := Rect2(39, 133, 60, 37)
const UV_RED_CHEST := Rect2(103, 133, 50, 36)
const UV_RED_SLEEVE := Rect2(157, 133, 65, 35)
const UV_RED_SKIRT := Rect2(227, 133, 60, 35)
const UV_CURVED_SWORD := Rect2(1, 177, 76, 26)

var skeleton: Skeleton2D
var bones: Dictionary = {}
var pieces: Dictionary = {}

func _ready() -> void:
	_build_skeleton()
	_capture_rest_pose()
	_build_meshes()
	update_pose("IDLE", 0.0, 1.0, Vector2.ZERO, 0.0, false, 0.0, false, false, false)

func _build_skeleton() -> void:
	skeleton = Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	add_child(skeleton)

	var pelvis := _add_bone("Pelvis", skeleton, Vector2(0.0, -44.0))
	var spine := _add_bone("Spine", pelvis, Vector2(0.0, -21.0))
	var head := _add_bone("Head", spine, Vector2(0.0, -23.0))
	_add_bone("Hair", head, Vector2(0.0, 0.0))

	var left_shoulder := _add_bone("LeftShoulder", spine, Vector2(-10.0, 1.0))
	var left_elbow := _add_bone("LeftElbow", left_shoulder, Vector2(-3.0, 12.0))
	_add_bone("LeftHand", left_elbow, Vector2(-1.0, 9.0))
	var right_shoulder := _add_bone("RightShoulder", spine, Vector2(10.0, 1.0))
	var right_elbow := _add_bone("RightElbow", right_shoulder, Vector2(3.0, 12.0))
	var right_hand := _add_bone("RightHand", right_elbow, Vector2(1.0, 9.0))
	_add_bone("Weapon", right_hand, Vector2(2.0, 0.0))
	_add_bone("Scabbard", spine, Vector2(-12.0, 2.0))

	var left_hip := _add_bone("LeftHip", pelvis, Vector2(-5.0, 0.0))
	var left_knee := _add_bone("LeftKnee", left_hip, Vector2(0.0, 12.0))
	var left_ankle := _add_bone("LeftAnkle", left_knee, Vector2(0.0, 12.0))
	_add_bone("LeftFoot", left_ankle, Vector2(-1.0, 7.0))
	var right_hip := _add_bone("RightHip", pelvis, Vector2(5.0, 0.0))
	var right_knee := _add_bone("RightKnee", right_hip, Vector2(0.0, 12.0))
	var right_ankle := _add_bone("RightAnkle", right_knee, Vector2(0.0, 12.0))
	_add_bone("RightFoot", right_ankle, Vector2(1.0, 7.0))

func _add_bone(bone_name: String, parent: Node2D, local_position: Vector2) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = local_position
	bone.set_autocalculate_length_and_angle(false)
	parent.add_child(bone)
	bones[bone_name] = bone
	return bone

func _capture_rest_pose() -> void:
	# Bone2D rest transforms are relative to each bone's parent.
	for value in bones.values():
		var bone := value as Bone2D
		bone.rest = bone.transform

func _build_meshes() -> void:
	# Back equipment and rear silhouette.
	_add_piece("Scabbard", UV_SCABBARD, Rect2(-25.0, -84.0, 5.5, 42.0), "Scabbard", -4, true)
	_add_piece("BackHair", UV_HAIR_TUFT, Rect2(-14.0, -104.0, 28.0, 25.0), "Hair", 0, true)

	# Legs are separate UV polygons so knees and ankles can rotate independently.
	_add_piece("LeftUpperLeg", UV_LIMB_UPPER, Rect2(-11.0, -47.0, 8.5, 18.0), "LeftHip", 1)
	_add_piece("LeftLowerLeg", UV_DARK_ARMOR, Rect2(-11.0, -31.5, 8.5, 17.0), "LeftKnee", 2)
	_add_piece("LeftBoot", UV_DARK_ARMOR, Rect2(-13.0, -16.0, 12.0, 7.0), "LeftFoot", 3)
	_add_piece("RightUpperLeg", UV_LIMB_UPPER, Rect2(2.5, -47.0, 8.5, 18.0), "RightHip", 4, true)
	_add_piece("RightLowerLeg", UV_DARK_ARMOR, Rect2(2.5, -31.5, 8.5, 17.0), "RightKnee", 5, true)
	_add_piece("RightBoot", UV_DARK_ARMOR, Rect2(1.0, -16.0, 12.0, 7.0), "RightFoot", 6, true)

	# Waist, torso armor and layered cloth. Overlapping pieces hide most cut edges.
	_add_piece("OuterSkirt", UV_RED_SKIRT, Rect2(-16.0, -57.0, 32.0, 16.0), "Pelvis", 3)
	_add_piece("WaistBand", UV_BELT, Rect2(-10.0, -57.0, 20.0, 9.0), "Pelvis", 5)
	_add_piece("ChestCloth", UV_RED_SLEEVE, Rect2(-14.0, -77.0, 28.0, 25.0), "Spine", 4)
	_add_piece("ChestPlate", UV_DARK_ARMOR, Rect2(-11.0, -75.0, 22.0, 23.0), "Spine", 6)
	_add_piece("ChestAccent", UV_RED_CHEST, Rect2(-7.0, -70.0, 14.0, 12.0), "Spine", 7)

	# Arms: the same packed limb component is cropped at UV level for upper/lower pieces.
	_add_piece("LeftUpperArm", UV_LIMB_UPPER, Rect2(-17.5, -68.0, 8.5, 16.0), "LeftShoulder", 6)
	_add_piece("LeftForearm", UV_LIMB_LOWER, Rect2(-20.0, -56.0, 8.5, 15.0), "LeftElbow", 7)
	_add_piece("LeftGauntlet", UV_GREEN_ARMOR, Rect2(-21.0, -49.0, 10.0, 9.0), "LeftHand", 8)
	_add_piece("RightUpperArm", UV_LIMB_UPPER, Rect2(9.0, -68.0, 8.5, 16.0), "RightShoulder", 8, true)
	_add_piece("RightForearm", UV_LIMB_LOWER, Rect2(11.5, -56.0, 8.5, 15.0), "RightElbow", 9, true)
	_add_piece("RightGauntlet", UV_GREEN_ARMOR, Rect2(12.0, -49.0, 10.0, 9.0), "RightHand", 10, true)

	# Head / hair, then the curved blade at the weapon-hand pivot.
	_add_piece("HairCap", UV_HAIR, Rect2(-13.0, -106.0, 26.0, 25.0), "Hair", 8, true)
	_add_piece("Face", UV_HEAD, Rect2(-10.5, -103.0, 21.0, 24.0), "Head", 9)
	_add_piece("ShoulderOrnamentL", UV_GREEN_ARMOR, Rect2(-18.0, -73.0, 10.0, 12.0), "LeftShoulder", 9)
	_add_piece("ShoulderOrnamentR", UV_GREEN_ARMOR, Rect2(8.0, -73.0, 10.0, 12.0), "RightShoulder", 10, true)
	_add_piece("CurvedBlade", UV_CURVED_SWORD, Rect2(10.0, -52.0, 38.0, 12.0), "Weapon", 12)

func _add_piece(
	piece_name: String,
	source_rect: Rect2,
	target_rect: Rect2,
	bone_name: String,
	draw_order: int,
	flip_horizontal: bool = false
) -> Polygon2D:
	var bone := bones.get(bone_name) as Bone2D
	if bone == null:
		push_warning("Skeleton atlas piece has no bone: " + piece_name + " -> " + bone_name)
		return null

	var uv_rect := Rect2(source_rect.position * ATLAS_UV_SCALE, source_rect.size * ATLAS_UV_SCALE)
	var uv_left := uv_rect.position.x
	var uv_right := uv_rect.end.x
	var uv_top := uv_rect.position.y
	var uv_bottom := uv_rect.end.y
	var uv_points: PackedVector2Array
	if flip_horizontal:
		uv_points = PackedVector2Array([
			Vector2(uv_right, uv_top),
			Vector2(uv_left, uv_top),
			Vector2(uv_left, uv_bottom),
			Vector2(uv_right, uv_bottom)
		])
	else:
		uv_points = PackedVector2Array([
			Vector2(uv_left, uv_top),
			Vector2(uv_right, uv_top),
			Vector2(uv_right, uv_bottom),
			Vector2(uv_left, uv_bottom)
		])

	var polygon := Polygon2D.new()
	polygon.name = piece_name
	polygon.texture = PARTS_ATLAS
	polygon.antialiased = true
	polygon.polygon = PackedVector2Array([
		target_rect.position,
		Vector2(target_rect.end.x, target_rect.position.y),
		target_rect.end,
		Vector2(target_rect.position.x, target_rect.end.y)
	])
	polygon.uv = uv_points
	polygon.z_index = draw_order
	add_child(polygon)

	# Polygon2D uses the sibling Skeleton2D and stores four normalized rigid weights.
	polygon.skeleton = polygon.get_path_to(skeleton)
	polygon.add_bone(skeleton.get_path_to(bone), PackedFloat32Array([1.0, 1.0, 1.0, 1.0]))
	pieces[piece_name] = polygon
	return polygon

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
	var squat_scale := 1.0
	if state_name == "DODGE":
		squat_scale = 0.84
	elif state_name == "QUICK_DASH":
		squat_scale = 0.76
	scale = Vector2(facing_sign, squat_scale)
	modulate = Color("#d98f99") if hurt else Color("#f3e6d4") if hit_flash else Color.WHITE

	for value in bones.values():
		var bone := value as Bone2D
		bone.rotation = 0.0

	var run_phase := elapsed * 13.0
	var local_motion := clampf(velocity.x * facing_sign / 260.0, -1.0, 1.0)
	match state_name:
		"IDLE":
			_set_rotation("Spine", sin(elapsed * 1.7) * 0.012)
			_set_rotation("Head", sin(elapsed * 1.55) * 0.018)
			_set_rotation("Hair", sin(elapsed * 2.0) * 0.025)
			_set_rotation("LeftShoulder", sin(elapsed * 1.3) * 0.015)
			_set_rotation("RightShoulder", sin(elapsed * 1.4) * -0.012)
		"MOVE":
			_set_rotation("LeftHip", sin(run_phase) * 0.44 * maxf(move_ratio, 0.5))
			_set_rotation("RightHip", sin(run_phase + PI) * 0.44 * maxf(move_ratio, 0.5))
			_set_rotation("LeftKnee", maxf(0.0, sin(run_phase + PI)) * 0.25)
			_set_rotation("RightKnee", maxf(0.0, sin(run_phase)) * 0.25)
			_set_rotation("LeftShoulder", -sin(run_phase) * 0.18)
			_set_rotation("LeftElbow", 0.12)
			_set_rotation("RightShoulder", sin(run_phase) * 0.18)
			_set_rotation("RightElbow", -0.10)
			_set_rotation("Hair", sin(run_phase) * 0.05)
		"JUMP":
			_set_rotation("Spine", -local_motion * 0.055)
			_set_rotation("LeftHip", -0.30)
			_set_rotation("RightHip", 0.28)
			_set_rotation("LeftKnee", 0.12)
			_set_rotation("RightKnee", -0.18)
			_set_rotation("LeftShoulder", -0.38)
			_set_rotation("RightShoulder", -0.22)
			_set_rotation("Hair", 0.10)
		"FALL":
			_set_rotation("Spine", -local_motion * 0.045)
			_set_rotation("LeftHip", -0.12)
			_set_rotation("RightHip", 0.34)
			_set_rotation("LeftShoulder", -0.50)
			_set_rotation("RightShoulder", -0.28)
			_set_rotation("Hair", -0.08)
		"ATTACK":
			if attack_windup:
				_set_rotation("Spine", -0.06)
				_set_rotation("RightShoulder", -0.26)
				_set_rotation("RightElbow", -0.20)
				_set_rotation("Weapon", -0.35)
				_set_rotation("LeftShoulder", -0.08)
			else:
				var strike := clampf(attack_progress, 0.0, 1.0)
				_set_rotation("Spine", lerpf(-0.07, 0.04, strike))
				_set_rotation("RightShoulder", lerpf(-0.35, 0.30, strike))
				_set_rotation("RightElbow", lerpf(-0.20, 0.42, strike))
				_set_rotation("Weapon", lerpf(-0.45, 0.95, strike))
				_set_rotation("LeftShoulder", lerpf(-0.10, 0.08, strike))
		"GRAPPLE":
			_set_rotation("Spine", -0.06)
			_set_rotation("RightShoulder", -0.75)
			_set_rotation("RightElbow", -0.20)
			_set_rotation("Weapon", -0.16)
			_set_rotation("LeftShoulder", 0.22)
			_set_rotation("Hair", -0.12)
		"DODGE":
			_set_rotation("Spine", 0.16)
			_set_rotation("LeftHip", -0.48)
			_set_rotation("RightHip", 0.35)
			_set_rotation("LeftShoulder", -0.50)
			_set_rotation("RightShoulder", 0.34)
			_set_rotation("Hair", 0.18)
		"QUICK_DASH":
			_set_rotation("Spine", 0.20)
			_set_rotation("LeftHip", -0.36)
			_set_rotation("RightHip", 0.22)
			_set_rotation("LeftShoulder", -0.40)
			_set_rotation("RightShoulder", 0.28)
			_set_rotation("Hair", 0.20)
		"WALL_CLIMB":
			_set_rotation("Spine", -0.08)
			_set_rotation("LeftShoulder", -0.65 + sin(elapsed * 12.0) * 0.035)
			_set_rotation("RightShoulder", -0.75 - sin(elapsed * 12.0) * 0.035)
			_set_rotation("LeftHip", 0.28)
			_set_rotation("RightHip", -0.32)
			_set_rotation("Hair", -0.10)
		"HURT":
			_set_rotation("Spine", -0.18)
			_set_rotation("Head", 0.12)
			_set_rotation("LeftShoulder", -0.25)
			_set_rotation("RightShoulder", 0.35)
			_set_rotation("Hair", -0.10)
		"DEAD":
			_set_rotation("Spine", 0.42)
			_set_rotation("Head", 0.12)
			_set_rotation("LeftHip", -0.18)
			_set_rotation("RightHip", 0.36)
			_set_rotation("LeftShoulder", -0.36)
			_set_rotation("RightShoulder", 0.40)
			_set_rotation("Hair", -0.22)
		_:
			pass

func _set_rotation(bone_name: String, angle: float) -> void:
	var bone := bones.get(bone_name) as Bone2D
	if bone != null:
		bone.rotation = angle
