extends Node2D
## Experimental Skeleton2D rig lab built from a separately installed CC0 modular character pack.
## Isolated from the production Hero; intended for visual review only.

const ASSET_ROOT := "user://itch_cc0_modular_character"
const MANIFEST_PATH := ASSET_ROOT.path_join("manifest.json")
const DISPLAY_SCALE := 0.085

const PART_RULES := {
	"body": {"terms": ["torso", "body"], "reject": ["body_parts_left", "body_parts_right", "left_body", "right_body", "enemy"]},
	"head": {"terms": ["head"], "reject": ["enemy"]},
	"hair": {"terms": ["hair"], "reject": ["enemy"]},
	"eyes": {"terms": ["eyes", "eye"], "reject": ["enemy"]},
	"mouth": {"terms": ["mouth"], "reject": ["enemy"]},
	"arm_left": {"terms": ["left_arm", "arm_left", "leftarm", "armleft", "left_hand", "hand_left", "leftbodypart", "left_body_part"], "reject": ["leg", "foot", "enemy"]},
	"arm_right": {"terms": ["right_arm", "arm_right", "rightarm", "armright", "right_hand", "hand_right", "rightbodypart", "right_body_part"], "reject": ["leg", "foot", "enemy"]},
	"leg_left": {"terms": ["left_leg", "leg_left", "leftleg", "legleft", "left_foot", "foot_left"], "reject": ["arm", "hand", "enemy"]},
	"leg_right": {"terms": ["right_leg", "leg_right", "rightleg", "legright", "right_foot", "foot_right"], "reject": ["arm", "hand", "enemy"]},
	"weapon": {"terms": ["weapon", "sword", "blade"], "reject": ["enemy"]}
}

var _asset_paths: Array[String] = []
var _part_nodes: Dictionary = {}
var _bones: Dictionary = {}
var _status_label: Label
var _root_bone: Bone2D
var _body_bone: Bone2D
var _head_bone: Bone2D
var _arm_left: Bone2D
var _arm_right: Bone2D
var _leg_left: Bone2D
var _leg_right: Bone2D
var _weapon_bone: Bone2D
var _pose_index := 0
var _clock := 0.0
var _source_canvas := Vector2(2048.0, 2048.0)
var _has_modular_parts := false
var _full_body_fallback: Sprite2D

func _ready() -> void:
	_make_stage()
	_make_status()
	_load_manifest()
	if _asset_paths.is_empty():
		_status_label.text = "CC0 character rig lab\n\nNo asset pack found.\nRun tools/install_itch_cc0_modular_character.gd first."
		return
	_build_rig()
	set_process(true)

func _process(delta: float) -> void:
	_clock += delta
	_apply_demo_pose()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_1: _pose_index = 0
		KEY_2: _pose_index = 1
		KEY_3: _pose_index = 2
		KEY_4: _pose_index = 3
		_: return
	_apply_demo_pose()
	get_viewport().set_input_as_handled()

func _make_stage() -> void:
	var ground := Line2D.new()
	ground.name = "GroundReference"
	ground.points = PackedVector2Array([Vector2(-180, 30), Vector2(180, 30)])
	ground.width = 2.0
	ground.default_color = Color("#68616d")
	add_child(ground)

func _make_status() -> void:
	var layer := CanvasLayer.new()
	layer.name = "RigLabHUD"
	add_child(layer)
	_status_label = Label.new()
	_status_label.position = Vector2(16, 12)
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.add_theme_color_override("font_color", Color("#f1e9dd"))
	_status_label.add_theme_color_override("font_shadow_color", Color("#17151b"))
	_status_label.add_theme_constant_override("shadow_offset_x", 1)
	_status_label.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(_status_label)

func _load_manifest() -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return
	for item in parsed.get("files", []):
		var path := str(item.get("path", ""))
		if path.to_lower().ends_with(".png"):
			_asset_paths.append(path)
	_asset_paths.sort()

func _build_rig() -> void:
	var selected: Dictionary = {}
	for part_name in PART_RULES:
		var candidate := _find_part_path(part_name)
		if not candidate.is_empty():
			var info := _inspect_part(candidate)
			if not info.is_empty():
				selected[part_name] = info
	_has_modular_parts = selected.has("body") and selected.has("head") and (selected.has("arm_left") or selected.has("arm_right"))

	var skeleton := Skeleton2D.new()
	skeleton.name = "ImportedCC0Skeleton"
	add_child(skeleton)
	_root_bone = _new_bone("RootBone", skeleton, Vector2.ZERO)
	_body_bone = _new_bone("BodyBone", _root_bone, Vector2.ZERO)
	_head_bone = _new_bone("HeadBone", _body_bone, Vector2(0, -18))
	_arm_left = _new_bone("ArmLeftBone", _body_bone, Vector2(-10, -3))
	_arm_right = _new_bone("ArmRightBone", _body_bone, Vector2(10, -3))
	_weapon_bone = _new_bone("WeaponBone", _arm_right, Vector2(8, 12))
	_leg_left = _new_bone("LegLeftBone", _root_bone, Vector2(-6, 12))
	_leg_right = _new_bone("LegRightBone", _root_bone, Vector2(6, 12))
	_bones = {
		"body": _body_bone, "head": _head_bone, "hair": _head_bone,
		"eyes": _head_bone, "mouth": _head_bone, "arm_left": _arm_left,
		"arm_right": _arm_right, "leg_left": _leg_left, "leg_right": _leg_right,
		"weapon": _weapon_bone
	}

	if _has_modular_parts:
		_assemble_selected_parts(selected)
	else:
		_add_full_body_fallback()
		_status_label.text += "\n\nPart-name match was incomplete. Showing best full-body idle candidate plus bone scaffold."
		_status_label.text += "\nSee output log for selected paths and missing semantic slots."

	scale = Vector2.ONE * DISPLAY_SCALE
	_log_selected_parts(selected)

func _new_bone(bone_name: String, parent: Node, local_position: Vector2) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = local_position
	parent.add_child(bone)
	return bone

func _find_part_path(part_name: String) -> String:
	var rule: Dictionary = PART_RULES[part_name]
	var best_path := ""
	var best_score := -99999
	for relative_path in _asset_paths:
		var lower := relative_path.to_lower().replace(" ", "_").replace("-", "_")
		var matches := false
		for term in rule.terms:
			if lower.contains(str(term)):
				matches = true
				break
		if not matches and part_name in ["arm_left", "arm_right"] and lower.contains("body_part"):
			matches = lower.contains("left") if part_name == "arm_left" else lower.contains("right")
		if not matches:
			continue
		var rejected := false
		for term in rule.reject:
			if lower.contains(str(term)):
				rejected = true
				break
		if rejected:
			continue
		var score := 0
		if lower.contains("character_1") or lower.contains("character1"):
			score += 20
		if lower.contains("idle") or lower.contains("stand"):
			score += 10
		if lower.contains("enemy") or lower.contains("character_2") or lower.contains("character2"):
			score -= 20
		if lower.get_file().begins_with("0") or lower.get_file().contains("0001"):
			score += 2
		if lower.contains("part"):
			score += 2
		if score > best_score:
			best_score = score
			best_path = relative_path
	return best_path

func _inspect_part(relative_path: String) -> Dictionary:
	var full_path := ASSET_ROOT.path_join(relative_path)
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(full_path)) != OK:
		return {}
	var bounds := image.get_used_rect()
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		return {}
	_source_canvas = Vector2(image.get_width(), image.get_height())
	return {
		"path": relative_path,
		"image": image,
		"bounds": bounds,
		"canvas_size": Vector2(image.get_width(), image.get_height()),
		"center": Vector2(bounds.position) + Vector2(bounds.size) * 0.5,
		"size": Vector2(bounds.size)
	}

func _assemble_selected_parts(selected: Dictionary) -> void:
	var body_info: Dictionary = selected.get("body", {})
	if body_info.is_empty():
		return
	var canvas_center := _source_canvas * 0.5
	var body_center: Vector2 = body_info.center
	_body_bone.position = body_center - canvas_center
	_add_part_sprite("body", body_info, _body_bone, body_center)

	var head_info: Dictionary = selected.get("head", {})
	var head_anchor_canvas := body_center + Vector2(0, -18)
	if not head_info.is_empty():
		var head_bounds: Rect2i = head_info.bounds
		head_anchor_canvas = Vector2(head_info.center.x, head_bounds.end.y)
		_head_bone.position = head_anchor_canvas - body_center
		_add_part_sprite("head", head_info, _head_bone, head_anchor_canvas)
	for related in ["hair", "eyes", "mouth"]:
		var info: Dictionary = selected.get(related, {})
		if not info.is_empty():
			_add_part_sprite(related, info, _head_bone, head_anchor_canvas)

	for limb_name in ["arm_left", "arm_right", "leg_left", "leg_right"]:
		var info: Dictionary = selected.get(limb_name, {})
		if info.is_empty():
			continue
		var bounds: Rect2i = info.bounds
		var anchor_canvas: Vector2
		match limb_name:
			"arm_left":
				anchor_canvas = Vector2(bounds.end.x, bounds.position.y + bounds.size.y * 0.18)
				_arm_left.position = anchor_canvas - body_center
			"arm_right":
				anchor_canvas = Vector2(bounds.position.x, bounds.position.y + bounds.size.y * 0.18)
				_arm_right.position = anchor_canvas - body_center
			"leg_left":
				anchor_canvas = Vector2(bounds.get_center().x, bounds.position.y)
				_leg_left.position = anchor_canvas - canvas_center
			"leg_right":
				anchor_canvas = Vector2(bounds.get_center().x, bounds.position.y)
				_leg_right.position = anchor_canvas - canvas_center
		_add_part_sprite(limb_name, info, _bones[limb_name], anchor_canvas)

	var weapon_info: Dictionary = selected.get("weapon", {})
	if not weapon_info.is_empty():
		var weapon_anchor := Vector2(weapon_info.bounds.position) + Vector2(weapon_info.bounds.size) * 0.5
		_add_part_sprite("weapon", weapon_info, _weapon_bone, weapon_anchor)

	var palette := {
		"body": Color("#ded6c9"), "head": Color("#e8dfd0"), "hair": Color("#4c3c43"),
		"eyes": Color("#342d35"), "mouth": Color("#7e5960"),
		"arm_left": Color("#ded6c9"), "arm_right": Color("#ded6c9"),
		"leg_left": Color("#b6aab4"), "leg_right": Color("#b6aab4"),
		"weapon": Color("#c5c3c9")
	}
	for part_name in _part_nodes:
		var sprite := _part_nodes[part_name] as Sprite2D
		sprite.modulate = palette.get(part_name, Color.WHITE)
		if part_name == "weapon":
			sprite.z_index = 3
	_status_label.text = "ITCH.IO CC0 MODULAR RIG LAB\nRGS_Dev · CC0-1.0 · isolated prototype\n1 Idle   2 Walk   3 Long slash   4 Dodge\n\nDetected semantic parts: %d / %d" % [selected.size(), PART_RULES.size()]

func _add_part_sprite(part_name: String, info: Dictionary, parent_bone: Bone2D, anchor_canvas: Vector2) -> void:
	var source_image := info.image as Image
	var bounds: Rect2i = info.bounds
	var cropped := source_image.get_region(bounds)
	var sprite := Sprite2D.new()
	sprite.name = "Part_" + part_name
	sprite.texture = ImageTexture.create_from_image(cropped)
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(info.center) - anchor_canvas
	parent_bone.add_child(sprite)
	_part_nodes[part_name] = sprite

func _add_full_body_fallback() -> void:
	var best_path := ""
	var best_score := -999
	for relative_path in _asset_paths:
		var lower := relative_path.to_lower().replace(" ", "_")
		if not (lower.contains("idle") or lower.contains("stand")):
			continue
		if lower.contains("enemy") or lower.contains("head") or lower.contains("hair") or lower.contains("eye") or lower.contains("mouth") or lower.contains("weapon"):
			continue
		var score := 0
		if lower.contains("character_1") or lower.contains("character1"):
			score += 20
		if lower.contains("full") or lower.contains("complete") or lower.contains("premade"):
			score += 5
		if score > best_score:
			best_score = score
			best_path = relative_path
	if best_path.is_empty():
		for relative_path in _asset_paths:
			var lower := relative_path.to_lower()
			if lower.contains("enemy") or lower.contains("head") or lower.contains("hair") or lower.contains("weapon"):
				continue
			best_path = relative_path
			break
	if best_path.is_empty():
		return
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(ASSET_ROOT.path_join(best_path))) != OK:
		return
	var used := image.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return
	_full_body_fallback = Sprite2D.new()
	_full_body_fallback.name = "FullBodyReferenceFallback"
	_full_body_fallback.texture = ImageTexture.create_from_image(image.get_region(used))
	_full_body_fallback.centered = true
	_full_body_fallback.position = Vector2(used.get_center()) - Vector2(image.get_width(), image.get_height()) * 0.5
	_full_body_fallback.modulate = Color("#e3d8c8")
	_root_bone.add_child(_full_body_fallback)
	print("Fallback display asset: ", best_path)

func _log_selected_parts(selected: Dictionary) -> void:
	print("=== CC0 modular rig candidate selection ===")
	for part_name in PART_RULES:
		if selected.has(part_name):
			print("%s -> %s" % [part_name, selected[part_name].get("path", "")])
		else:
			print("%s -> MISSING (no filename match)" % part_name)
	print("Modular assembly selected: ", _has_modular_parts)

func _apply_demo_pose() -> void:
	if _bones.is_empty():
		return
	for node_variant in _bones.values():
		var bone := node_variant as Bone2D
		if is_instance_valid(bone):
			bone.rotation = 0.0
	_root_bone.rotation = 0.0
	_root_bone.position.y = 0.0
	var wave := sin(_clock * 5.0)
	match _pose_index:
		0:
			_body_bone.rotation = sin(_clock * 2.2) * 0.025
			_head_bone.rotation = sin(_clock * 2.4 + 0.4) * 0.025
			_arm_left.rotation = -0.08 + wave * 0.025
			_arm_right.rotation = 0.12 - wave * 0.025
		1:
			_root_bone.position.y = absf(sin(_clock * 10.0)) * -1.8
			_body_bone.rotation = -0.06
			_arm_left.rotation = 0.12 + wave * 0.22
			_arm_right.rotation = -0.12 - wave * 0.22
			_leg_left.rotation = wave * 0.35
			_leg_right.rotation = -wave * 0.35
		2:
			var strike := sin(clampf(fmod(_clock, 0.72) / 0.72, 0.0, 1.0) * PI)
			_body_bone.rotation = -0.14 + strike * 0.30
			_arm_left.rotation = 0.28 - strike * 0.45
			_arm_right.rotation = -1.1 + strike * 1.8
			_weapon_bone.rotation = -0.28 + strike * 0.7
			_leg_left.rotation = -0.16
			_leg_right.rotation = 0.18
		3:
			var dodge := sin(clampf(fmod(_clock, 0.9) / 0.9, 0.0, 1.0) * PI)
			_root_bone.rotation = TAU * smoothstep(0.0, 1.0, dodge)
			_body_bone.rotation = -0.55 + dodge * 0.12
			_arm_left.rotation = 0.85
			_arm_right.rotation = -0.7
			_leg_left.rotation = 0.48
			_leg_right.rotation = -0.48
