class_name CustomizableCharacter
extends Node2D

signal appearance_changed(slot: StringName, index: int)

const DEFAULT_ATLAS_PATH := "res://assets/art/hero_sprite_lab/muramasa_texture_atlas.png"

@export var atlas_texture: Texture2D
@export var hair_options: Array[CharacterPartData] = []
@export var clothes_options: Array[CharacterPartData] = []
@export var face_options: Array[CharacterPartData] = []
@export var accessory_options: Array[CharacterPartData] = []

@export_group("Default regions (temporary examples; replace with measured atlas coordinates)")
@export var default_body_region := Rect2(0, 0, 64, 96)
@export var default_head_region := Rect2(0, 0, 64, 64)
@export var default_hair_region := Rect2(0, 0, 64, 64)
@export var default_clothes_region := Rect2(0, 0, 64, 96)
@export var default_face_region := Rect2(0, 0, 64, 64)
@export var default_accessory_region := Rect2(0, 0, 32, 32)
@export var default_arm_region := Rect2(0, 0, 32, 64)
@export var default_leg_region := Rect2(0, 0, 32, 64)

@onready var body_sprite: Sprite2D = get_node_or_null("Rig/RootBone/BodyBone/BodySprite") as Sprite2D
@onready var clothes_sprite: Sprite2D = get_node_or_null("Rig/RootBone/BodyBone/ClothesSprite") as Sprite2D
@onready var head_sprite: Sprite2D = get_node_or_null("Rig/RootBone/BodyBone/HeadBone/HeadSprite") as Sprite2D
@onready var face_sprite: Sprite2D = get_node_or_null("Rig/RootBone/BodyBone/HeadBone/FaceSprite") as Sprite2D
@onready var hair_back_sprite: Sprite2D = get_node_or_null("Rig/RootBone/BodyBone/HeadBone/HairBackSprite") as Sprite2D
@onready var hair_front_sprite: Sprite2D = get_node_or_null("Rig/RootBone/BodyBone/HeadBone/HairFrontSprite") as Sprite2D
@onready var accessory_sprite: Sprite2D = get_node_or_null("Rig/RootBone/BodyBone/HeadBone/AccessorySprite") as Sprite2D
@onready var left_arm_sprite: Sprite2D = get_node_or_null("Rig/RootBone/BodyBone/LeftArmBone/ArmSprite") as Sprite2D
@onready var right_arm_sprite: Sprite2D = get_node_or_null("Rig/RootBone/BodyBone/RightArmBone/ArmSprite") as Sprite2D
@onready var left_leg_sprite: Sprite2D = get_node_or_null("Rig/RootBone/LeftLegBone/LegSprite") as Sprite2D
@onready var right_leg_sprite: Sprite2D = get_node_or_null("Rig/RootBone/RightLegBone/LegSprite") as Sprite2D

var current_hair := -1
var current_clothes := -1
var current_face := -1
var current_accessory := -1
var _fallback_nodes: Array[Polygon2D] = []


func _ready() -> void:
	if atlas_texture == null and ResourceLoader.exists(DEFAULT_ATLAS_PATH):
		atlas_texture = load(DEFAULT_ATLAS_PATH) as Texture2D
	if atlas_texture == null:
		push_warning("No atlas assigned. Copy the local atlas to: " + DEFAULT_ATLAS_PATH)
	for sprite in _all_slots():
		if sprite == null:
			continue
		sprite.texture = atlas_texture
		sprite.region_enabled = true
		sprite.centered = true
	_build_fallback_silhouette()
	_apply_default_regions()
	if not hair_options.is_empty():
		change_hair(0)
	if not clothes_options.is_empty():
		change_clothes(0)
	if not face_options.is_empty():
		change_face(0)
	if not accessory_options.is_empty():
		change_accessory(0)


func _all_slots() -> Array[Sprite2D]:
	return [body_sprite, clothes_sprite, head_sprite, face_sprite, hair_back_sprite, hair_front_sprite, accessory_sprite, left_arm_sprite, right_arm_sprite, left_leg_sprite, right_leg_sprite]


func _apply_default_regions() -> void:
	_apply_region(body_sprite, default_body_region, Vector2.ZERO, 0)
	_apply_region(head_sprite, default_head_region, Vector2(0, -20), 2)
	_apply_region(clothes_sprite, default_clothes_region, Vector2.ZERO, 1)
	_apply_region(face_sprite, default_face_region, Vector2.ZERO, 3)
	_apply_region(hair_back_sprite, default_hair_region, Vector2(0, -2), 1)
	_apply_region(hair_front_sprite, default_hair_region, Vector2(0, -2), 4)
	_apply_region(accessory_sprite, default_accessory_region, Vector2.ZERO, 5)
	_apply_region(left_arm_sprite, default_arm_region, Vector2(0, 8), 1)
	_apply_region(right_arm_sprite, default_arm_region, Vector2(0, 8), 1)
	_apply_region(left_leg_sprite, default_leg_region, Vector2(0, 10), 0)
	_apply_region(right_leg_sprite, default_leg_region, Vector2(0, 10), 0)
	# Keep Sprite2D containers visible for their fallback Polygon2D children, but clear the
	# texture so guessed placeholder rectangles are never rendered as character art.
	for sprite in _all_slots():
		if sprite != null:
			sprite.texture = null
			sprite.visible = true


func _apply_region(sprite: Sprite2D, region: Rect2, local_position: Vector2, layer: int) -> void:
	if sprite == null:
		return
	sprite.texture = atlas_texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = true
	sprite.position = local_position
	sprite.offset = Vector2.ZERO
	sprite.z_index = layer


func _apply_part(sprite: Sprite2D, options: Array[CharacterPartData], index: int) -> bool:
	if sprite == null:
		push_warning("Character appearance slot node is missing.")
		return false
	if atlas_texture == null:
		push_warning("Assign the local atlas texture in the Character inspector.")
		return false
	if index < 0 or index >= options.size():
		push_warning("Invalid character part index: %d" % index)
		return false
	var part := options[index]
	if part == null:
		push_warning("Character part resource at index %d is empty." % index)
		return false
	sprite.texture = atlas_texture
	sprite.region_enabled = true
	sprite.region_rect = part.atlas_region
	sprite.centered = true
	sprite.position = part.local_position
	sprite.offset = part.local_offset
	sprite.scale = part.local_scale
	sprite.rotation = part.local_rotation
	sprite.z_index = part.z_index
	sprite.visible = part.enabled
	_set_fallback_visible_for_slot(sprite, false)
	return true


func change_hair(index: int) -> void:
	if index < 0 or index >= hair_options.size():
		return
	var part := hair_options[index]
	var success := _apply_part(hair_front_sprite, hair_options, index)
	if success:
		_apply_part(hair_back_sprite, hair_options, index)
		current_hair = index
		appearance_changed.emit(&"hair", index)


func change_clothes(index: int) -> void:
	if _apply_part(clothes_sprite, clothes_options, index):
		current_clothes = index
		appearance_changed.emit(&"clothes", index)


func change_face(index: int) -> void:
	if _apply_part(face_sprite, face_options, index):
		current_face = index
		appearance_changed.emit(&"face", index)


func change_accessory(index: int) -> void:
	if _apply_part(accessory_sprite, accessory_options, index):
		current_accessory = index
		appearance_changed.emit(&"accessory", index)


func set_accessory_visible(enabled: bool) -> void:
	if accessory_sprite != null:
		accessory_sprite.visible = enabled and current_accessory >= 0

func _build_fallback_silhouette() -> void:
	# Clearly visible construction mannequin while no real atlas parts have been configured.
	# 真实图集部件尚未配置时，显示跟随骨骼运动的简易人形。
	_add_fallback_polygon("Rig/RootBone/BodyBone/BodySprite", PackedVector2Array([
		Vector2(-9, -13), Vector2(9, -13), Vector2(11, 10), Vector2(-11, 10)
	]), Color("#777985"))
	_add_fallback_polygon("Rig/RootBone/BodyBone/HeadBone/HeadSprite", PackedVector2Array([
		Vector2(-9, -10), Vector2(9, -10), Vector2(10, 1), Vector2(5, 10), Vector2(-5, 10), Vector2(-10, 1)
	]), Color("#c7a58b"))
	_add_fallback_polygon("Rig/RootBone/BodyBone/LeftArmBone/ArmSprite", PackedVector2Array([
		Vector2(-4, -2), Vector2(4, -2), Vector2(4, 17), Vector2(-4, 17)
	]), Color("#b9a18f"))
	_add_fallback_polygon("Rig/RootBone/BodyBone/RightArmBone/ArmSprite", PackedVector2Array([
		Vector2(-4, -2), Vector2(4, -2), Vector2(4, 17), Vector2(-4, 17)
	]), Color("#b9a18f"))
	_add_fallback_polygon("Rig/RootBone/LeftLegBone/LegSprite", PackedVector2Array([
		Vector2(-4, 0), Vector2(4, 0), Vector2(5, 20), Vector2(-5, 20)
	]), Color("#575963"))
	_add_fallback_polygon("Rig/RootBone/RightLegBone/LegSprite", PackedVector2Array([
		Vector2(-4, 0), Vector2(4, 0), Vector2(5, 20), Vector2(-5, 20)
	]), Color("#575963"))
	# Simple front hair and tunic silhouettes make the mannequin readable.
	_add_fallback_polygon("Rig/RootBone/BodyBone/HeadBone/HairFrontSprite", PackedVector2Array([
		Vector2(-10, -9), Vector2(8, -10), Vector2(10, -2), Vector2(2, -5), Vector2(-4, 0), Vector2(-10, -1)
	]), Color("#28232d"))
	_add_fallback_polygon("Rig/RootBone/BodyBone/ClothesSprite", PackedVector2Array([
		Vector2(-10, -12), Vector2(10, -12), Vector2(13, 9), Vector2(8, 13), Vector2(-8, 13), Vector2(-13, 9)
	]), Color("#762f3b"))


func _add_fallback_polygon(node_path: NodePath, points: PackedVector2Array, color: Color) -> void:
	var parent := get_node_or_null(node_path)
	if parent == null:
		return
	var polygon := Polygon2D.new()
	polygon.name = "FallbackSilhouette"
	polygon.polygon = points
	polygon.color = color
	polygon.z_index = -1
	parent.add_child(polygon)
	_fallback_nodes.append(polygon)


func _set_fallback_visible_for_slot(_sprite: Sprite2D, _enabled: bool) -> void:
	# Keep the mannequin behind configured atlas parts for now; it is useful for alignment.
	# 后续可按部件槽精确隐藏对应占位轮廓。
	pass
