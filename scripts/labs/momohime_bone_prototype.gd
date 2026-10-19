extends Node2D
## Isolated Momohime-inspired bone-animation study.
## 百姬风格骨骼动画独立研究场景；不替换正式 Hero。

enum Motion { IDLE, WALK, SLASH }

const INK := Color("#211b28")
const HAIR := Color("#211b2a")
const HAIR_LIGHT := Color("#514052")
const CLOTH := Color("#eee3d0")
const RED := Color("#a83c4b")
const SKIN := Color("#e6c2a5")
const STEEL := Color("#d9d4d0")
const GOLD := Color("#c9a96b")

var motion := Motion.IDLE
var elapsed := 0.0
var frame_time := 0.0
var root_bone: Bone2D
var torso: Bone2D
var head: Bone2D
var hair: Bone2D
var arm_near: Bone2D
var arm_far: Bone2D
var hand: Bone2D
var leg_near: Bone2D
var leg_far: Bone2D
var knee_near: Bone2D
var knee_far: Bone2D
var sword: Line2D
var sleeve_near: Polygon2D
var skirt: Polygon2D
var status: Label


func _ready() -> void:
	_build_stage()
	_build_rig()
	_apply_motion()


func _process(delta: float) -> void:
	elapsed += delta
	frame_time += delta
	_apply_motion()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1:
			motion = Motion.IDLE
			elapsed = 0.0
		KEY_2:
			motion = Motion.WALK
			elapsed = 0.0
		KEY_3:
			motion = Motion.SLASH
			elapsed = 0.0
		KEY_SPACE:
			set_process(not is_processing())
		KEY_R:
			elapsed = 0.0
			frame_time = 0.0
		KEY_LEFT, KEY_RIGHT:
			scale.x = -1.0 if event.keycode == KEY_LEFT else 1.0
	_update_status()


func _build_stage() -> void:
	var floor := Line2D.new()
	floor.name = "Ground"
	floor.points = PackedVector2Array([Vector2(-220, 0), Vector2(220, 0)])
	floor.width = 2.0
	floor.default_color = Color("#786b79")
	add_child(floor)
	var camera := Camera2D.new()
	camera.position = Vector2(0, -68)
	camera.zoom = Vector2(2.0, 2.0)
	add_child(camera)
	camera.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	status = Label.new()
	status.position = Vector2(18, 14)
	status.add_theme_font_size_override("font_size", 16)
	status.add_theme_color_override("font_color", Color("#f6ebdb"))
	layer.add_child(status)


func _build_rig() -> void:
	var skeleton := Skeleton2D.new()
	skeleton.name = "MomohimeSkeleton"
	add_child(skeleton)
	root_bone = _bone(skeleton, "Root", Vector2.ZERO)
	torso = _bone(root_bone, "Torso", Vector2(0, -35))
	head = _bone(torso, "Head", Vector2(0, -25))
	hair = _bone(head, "LongHair", Vector2(-1, -2))
	arm_far = _bone(torso, "FarArm", Vector2(-9, 2))
	arm_near = _bone(torso, "NearArm", Vector2(9, 2))
	hand = _bone(arm_near, "SwordHand", Vector2(8, 15))
	leg_far = _bone(root_bone, "FarLeg", Vector2(-5, -1))
	leg_near = _bone(root_bone, "NearLeg", Vector2(5, -1))
	knee_far = _bone(leg_far, "FarKnee", Vector2(0, 14))
	knee_near = _bone(leg_near, "NearKnee", Vector2(0, 14))

	# Layered shapes are attached to bones; each limb can move independently.
	_polygon(torso, "KimonoBody", [Vector2(-9,-8),Vector2(9,-8),Vector2(13,10),Vector2(7,25),Vector2(-8,25),Vector2(-13,10)], CLOTH)
	_line(torso, "CollarRed", [Vector2(-4,-7),Vector2(0,1),Vector2(5,-7)], 3.0, RED)
	_polygon(head, "Face", [Vector2(-6,-7),Vector2(6,-7),Vector2(6,2),Vector2(2,8),Vector2(-4,7),Vector2(-7,1)], SKIN)
	_polygon(hair, "HairMass", [Vector2(-7,-9),Vector2(4,-10),Vector2(9,-3),Vector2(8,11),Vector2(12,25),Vector2(5,20),Vector2(2,7),Vector2(-7,4),Vector2(-10,-2)], HAIR)
	_line(hair, "HairHighlight", [Vector2(4,-6),Vector2(6,4),Vector2(7,15)], 1.5, HAIR_LIGHT)
	_polygon(arm_far, "FarSleeve", [Vector2(-3,-3),Vector2(5,-2),Vector2(10,8),Vector2(4,14),Vector2(-4,8)], RED)
	_polygon(arm_near, "NearSleeve", [Vector2(-3,-3),Vector2(5,-2),Vector2(12,8),Vector2(6,15),Vector2(-5,9)], CLOTH)
	sleeve_near = arm_near.get_node("NearSleeve") as Polygon2D
	_line(arm_near, "SleeveTrim", [Vector2(-4,8),Vector2(7,14),Vector2(12,8)], 2.0, GOLD)
	_polygon(root_bone, "KimonoSkirt", [Vector2(-8,-6),Vector2(8,-6),Vector2(15,17),Vector2(5,22),Vector2(-15,17)], RED)
	skirt = root_bone.get_node("KimonoSkirt") as Polygon2D
	_line(root_bone, "SkirtFold", [Vector2(0,2),Vector2(2,18)], 1.5, GOLD)
	_line(leg_far, "FarLegShape", [Vector2.ZERO,Vector2(0,14)], 5.0, INK)
	_line(knee_far, "FarSock", [Vector2.ZERO,Vector2(1,12)], 4.0, CLOTH)
	_line(leg_near, "NearLegShape", [Vector2.ZERO,Vector2(0,14)], 5.0, INK)
	_line(knee_near, "NearSock", [Vector2.ZERO,Vector2(1,12)], 4.0, CLOTH)
	_line(knee_near, "NearFoot", [Vector2(0,12),Vector2(7,13)], 4.0, INK)
	_line(knee_far, "FarFoot", [Vector2(1,12),Vector2(6,13)], 4.0, INK)
	_line(hand, "Hand", [Vector2.ZERO,Vector2(3,3)], 4.0, SKIN)
	sword = _line(hand, "Katana", [Vector2(1,2),Vector2(28,-5)], 2.2, STEEL)
	_line(hand, "KatanaEdge", [Vector2(2,4),Vector2(28,-3)], 0.8, GOLD)
	_polygon(head, "HairFringe", [Vector2(-7,-8),Vector2(5,-10),Vector2(8,-5),Vector2(1,-1),Vector2(-2,-4),Vector2(-6,0)], HAIR)


func _bone(parent: Node2D, node_name: String, at: Vector2) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = node_name
	bone.position = at
	bone.rest = Transform2D(0.0, at)
	bone.auto_calculate_length_and_angle = false
	parent.add_child(bone)
	return bone


func _polygon(parent: Node2D, node_name: String, points: Array[Vector2], color: Color) -> Polygon2D:
	var shape := Polygon2D.new()
	shape.name = node_name
	shape.polygon = PackedVector2Array(points)
	shape.color = color
	parent.add_child(shape)
	return shape


func _line(parent: Node2D, node_name: String, points: Array[Vector2], width: float, color: Color) -> Line2D:
	var line := Line2D.new()
	line.name = node_name
	line.points = PackedVector2Array(points)
	line.width = width
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(line)
	return line


func _apply_motion() -> void:
	if root_bone == null:
		return
	var wave := sin(elapsed * 7.0)
	root_bone.position.y = 0.0
	root_bone.rotation = 0.0
	torso.rotation = 0.0
	head.rotation = 0.0
	hair.rotation = 0.0
	arm_near.rotation = -0.18
	arm_far.rotation = 0.16
	leg_near.rotation = 0.0
	leg_far.rotation = 0.0
	knee_near.rotation = 0.0
	knee_far.rotation = 0.0
	skirt.rotation = 0.0
	sleeve_near.rotation = 0.0
	sword.points = PackedVector2Array([Vector2(1,2),Vector2(28,-5)])
	match motion:
		Motion.IDLE:
			root_bone.position.y = -absf(sin(elapsed * 2.5)) * 0.8
			torso.rotation = sin(elapsed * 2.5) * 0.025
			head.rotation = sin(elapsed * 2.1 + 0.6) * 0.035
			hair.rotation = sin(elapsed * 2.0 + 0.8) * 0.045
			arm_near.rotation += sin(elapsed * 2.3) * 0.025
			skirt.rotation = sin(elapsed * 2.0) * 0.018
		Motion.WALK:
			root_bone.position.y = -absf(wave) * 1.4
			torso.rotation = -0.035 + sin(elapsed * 7.0) * 0.025
			arm_near.rotation = -0.15 - wave * 0.24
			arm_far.rotation = 0.15 + wave * 0.24
			leg_near.rotation = wave * 0.28
			leg_far.rotation = -wave * 0.28
			knee_near.rotation = maxf(0.0, -wave) * 0.32
			knee_far.rotation = maxf(0.0, wave) * 0.32
			hair.rotation = -0.04 + wave * 0.05
			skirt.rotation = wave * 0.035
		Motion.SLASH:
			var phase: float = fposmod(elapsed, 0.72) / 0.72
			if phase < 0.28:
				var load: float = smoothstep(0.0, 0.28, phase)
				torso.rotation = lerpf(-0.08, -0.48, load)
				arm_near.rotation = lerpf(-0.18, -1.35, load)
				arm_far.rotation = lerpf(0.16, -0.7, load)
				leg_near.rotation = -0.12
				leg_far.rotation = 0.16
			elif phase < 0.48:
				var cut: float = smoothstep(0.28, 0.48, phase)
				torso.rotation = lerpf(-0.48, 0.34, cut)
				arm_near.rotation = lerpf(-1.35, 0.85, cut)
				arm_far.rotation = lerpf(-0.7, -0.25, cut)
				root_bone.position.y = -sin(cut * PI) * 2.0
				leg_near.rotation = -0.24
				leg_far.rotation = 0.3
			else:
				var recover: float = smoothstep(0.48, 1.0, phase)
				torso.rotation = lerpf(0.34, 0.0, recover)
				arm_near.rotation = lerpf(0.85, -0.18, recover)
				arm_far.rotation = lerpf(-0.25, 0.16, recover)
			head.rotation = -torso.rotation * 0.28
			hair.rotation = -torso.rotation * 0.32 + sin(phase * PI) * 0.12
			sleeve_near.rotation = sin(phase * PI) * 0.08
	_update_status()


func _update_status() -> void:
	if status == null:
		return
	var labels: Array[String] = ["待机 Idle", "行走 Walk", "挥刀 Slash"]
	var label: String = labels[int(motion)]
	status.text = "百姬风格骨骼原型 | %s\n1 待机  2 行走  3 挥刀  Space 暂停/继续  ←/→ 朝向  R 重播\n分层部件由 Bone2D 驱动；独立实验，不替换正式 Hero。" % label
