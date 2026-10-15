extends "res://scripts/player/hero_skeleton_controller.gd"
class_name HeroSkeletonTextureLab

## Temporary texture-atlas assembly layered onto the existing Bone2D rig.
## 临时纹理拼装层，复用现有 Bone2D 骨骼；不改变正式 Hero 逻辑。

const ATLAS_PATH := "res://assets/art/hero_sprite_lab/muramasa_texture_atlas.png"

@export var use_texture_atlas: bool = true
@export var atlas_scale: float = 0.42

var _atlas: Texture2D
var _textured_parts: Array[Sprite2D] = []
var _atlas_status: Label


func _ready() -> void:
	super._ready()
	_hide_line_art()
	_build_status_label()
	if not use_texture_atlas:
		_show_fallback("Texture mode disabled. / 已关闭纹理模式。")
		return
	if not ResourceLoader.exists(ATLAS_PATH):
		_show_fallback("Texture atlas missing / 未找到纹理图集：\n" + ATLAS_PATH + "\nCopy the 2048×2048 PNG here for local testing.\n请将 2048×2048 PNG 放到此本地路径。")
		return
	_atlas = load(ATLAS_PATH) as Texture2D
	if _atlas == null:
		_show_fallback("Texture atlas failed to load. / 纹理图集加载失败。")
		return
	_build_textured_parts()
	_atlas_status.text = "Texture rig preview / 骨骼纹理拼装预览\nAtlas pieces are rough placeholders; edit region rectangles after visual inspection.\n目前为粗略拼装，后续可按实际素材调整切片区域。"


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
	# Keep the rig and poses visible if the local third-party atlas is absent.
	# 缺少本地素材时恢复线稿，保证场景仍可用于检查骨骼动作。
	for node in find_children("*", "Line2D", true, false):
		(node as CanvasItem).visible = true
	for node in find_children("*", "Polygon2D", true, false):
		(node as CanvasItem).visible = true
	_atlas_status.text = message + "\nLine-art fallback active / 当前使用线稿回退。"


func _build_textured_parts() -> void:
	# Rectangles are provisional crops based on the supplied atlas preview.
	# Coordinates refer to the original 2048×2048 atlas, not its thumbnail.
	# 切片矩形为初始估值，坐标对应 2048×2048 原图，而非预览缩略图。
	_add_part(head_bone, Rect2(270, 35, 150, 155), Vector2(0, 0), Vector2(0.5, 0.85), 3)
	_add_part(body_bone, Rect2(1360, 710, 125, 180), Vector2(0, 5), Vector2(0.5, 0.45), 0)
	_add_part(arm_left_bone, Rect2(1410, 400, 105, 170), Vector2(-2, 7), Vector2(0.5, 0.08), 1)
	_add_part(arm_right_bone, Rect2(1410, 400, 105, 170), Vector2(2, 7), Vector2(0.5, 0.08), 1)
	_add_part(leg_left_bone, Rect2(1110, 370, 95, 180), Vector2(0, 10), Vector2(0.5, 0.05), 0)
	_add_part(leg_right_bone, Rect2(1110, 370, 95, 180), Vector2(0, 10), Vector2(0.5, 0.05), 0)
	_add_part(weapon_point, Rect2(0, 0, 470, 95), Vector2(15, -2), Vector2(0.05, 0.5), 4)
	# Keep original cloak silhouette hidden for now; the atlas's matching piece is not yet confidently identified.


func _add_part(parent: Node2D, region: Rect2, offset: Vector2, pivot: Vector2, layer: int) -> void:
	var sprite := Sprite2D.new()
	sprite.name = "AtlasPart_" + str(_textured_parts.size())
	sprite.texture = _atlas
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = true
	sprite.offset = offset
	sprite.position = Vector2.ZERO
	sprite.scale = Vector2.ONE * atlas_scale
	sprite.z_index = layer
	parent.add_child(sprite)
	_textured_parts.append(sprite)
