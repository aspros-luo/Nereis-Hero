extends "res://scripts/player/hero_skeleton_controller.gd"
class_name HeroSkeletonTextureLab

## Texture-part preview for the existing Bone2D rig.
## Uses explicit per-part files instead of guessed atlas rectangles.
## 现有 Bone2D 骨骼的分部纹理预览；使用独立部件文件，不再猜测图集切片坐标。

const PARTS_DIR := "res://assets/art/hero_sprite_lab/parts/"

@export var use_texture_parts: bool = true
@export_range(0.01, 2.0, 0.01) var part_scale: float = 0.12
@export_file("*.png") var head_texture_path: String = PARTS_DIR + "head.png"
@export_file("*.png") var body_texture_path: String = PARTS_DIR + "body.png"
@export_file("*.png") var arm_texture_path: String = PARTS_DIR + "arm.png"
@export_file("*.png") var leg_texture_path: String = PARTS_DIR + "leg.png"
@export_file("*.png") var weapon_texture_path: String = PARTS_DIR + "weapon.png"
@export_file("*.png") var cloak_texture_path: String = PARTS_DIR + "cloak.png"

## Fine-tune pivots after real artwork is selected; offsets are in source texture pixels.
@export var head_offset: Vector2 = Vector2.ZERO
@export var body_offset: Vector2 = Vector2.ZERO
@export var arm_offset: Vector2 = Vector2.ZERO
@export var leg_offset: Vector2 = Vector2.ZERO
@export var weapon_offset: Vector2 = Vector2.ZERO
@export var cloak_offset: Vector2 = Vector2.ZERO

var _textured_parts: Array[Sprite2D] = []
var _atlas_status: Label


func _ready() -> void:
	super._ready()
	_hide_line_art()
	_build_status_label()
	if not use_texture_parts:
		_show_fallback("Texture mode disabled / 已关闭纹理模式。")
		return

	var paths := {
		"head": head_texture_path,
		"body": body_texture_path,
		"arm": arm_texture_path,
		"leg": leg_texture_path,
		"weapon": weapon_texture_path,
	}
	var textures: Dictionary = {}
	var missing: Array[String] = []
	for part_name in paths:
		var path := str(paths[part_name])
		if path.is_empty() or not ResourceLoader.exists(path):
			missing.append(part_name + ": " + (path if not path.is_empty() else "(not assigned)"))
			continue
		var texture := load(path) as Texture2D
		if texture == null:
			missing.append(part_name + ": failed to load " + path)
			continue
		textures[part_name] = texture

	# Do not display a half-assembled character. Missing required parts keep the known rig visible.
	if not missing.is_empty():
		_show_fallback(
			"Missing required character parts / 缺少必要角色部件：\n"
			+ "\n".join(missing)
			+ "\nAdd licensed or original PNGs under assets/art/hero_sprite_lab/parts/.")
		return

	_add_part(head_bone, textures["head"], head_offset, 3, "HeadTexture")
	_add_part(body_bone, textures["body"], body_offset, 0, "BodyTexture")
	_add_part(arm_left_bone, textures["arm"], arm_offset, 1, "LeftArmTexture")
	_add_part(arm_right_bone, textures["arm"], arm_offset, 2, "RightArmTexture")
	_add_part(leg_left_bone, textures["leg"], leg_offset, 0, "LeftLegTexture")
	_add_part(leg_right_bone, textures["leg"], leg_offset, 1, "RightLegTexture")
	_add_part(weapon_point, textures["weapon"], weapon_offset, 4, "WeaponTexture")

	if not cloak_texture_path.is_empty() and ResourceLoader.exists(cloak_texture_path):
		var cloak_texture := load(cloak_texture_path) as Texture2D
		if cloak_texture != null:
			_add_part(body_bone, cloak_texture, cloak_offset, -1, "CloakTexture")

	_atlas_status.text = (
		"Separate-part skeletal preview / 分部纹理骨骼预览\n"
		+ "Adjust part offsets and scale after checking the actual artwork.\n"
		+ "请根据实际素材调整部件偏移与缩放。"
	)


func _hide_line_art() -> void:
	for node in find_children("*", "Line2D", true, false):
		(node as CanvasItem).visible = false
	for node in find_children("*", "Polygon2D", true, false):
		(node as CanvasItem).visible = false


func _build_status_label() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TextureLabOverlay"
	add_child(layer)
	_atlas_status = Label.new()
	_atlas_status.position = Vector2(16, 12)
	_atlas_status.add_theme_font_size_override("font_size", 15)
	_atlas_status.add_theme_color_override("font_color", Color("#f4ead9"))
	layer.add_child(_atlas_status)


func _show_fallback(message: String) -> void:
	# Keep the procedural rig available when art files have not been imported.
	# 尚未导入素材时恢复程序化线稿，仍可检查骨骼动作。
	for sprite in _textured_parts:
		if is_instance_valid(sprite):
			sprite.queue_free()
	_textured_parts.clear()
	for node in find_children("*", "Line2D", true, false):
		(node as CanvasItem).visible = true
	for node in find_children("*", "Polygon2D", true, false):
		(node as CanvasItem).visible = true
	_atlas_status.text = message + "\nLine-art fallback active / 当前使用线稿回退。"


func _add_part(parent: Node2D, texture: Texture2D, offset: Vector2, layer: int, node_name: String) -> void:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.centered = true
	sprite.offset = offset
	sprite.position = Vector2.ZERO
	sprite.scale = Vector2.ONE * part_scale
	sprite.z_index = layer
	parent.add_child(sprite)
	_textured_parts.append(sprite)
