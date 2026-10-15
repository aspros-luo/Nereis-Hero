class_name CustomizableCharacter
extends Node2D

signal appearance_changed(slot: StringName, index: int)

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

@onready var body_sprite: Sprite2D = get_node_or_null("Rig/RootBone/BodyBone/BodySprite") as Sprite2D
@onready var clothes_sprite: Sprite2D = get_node_or_null("Rig/RootBone/BodyBone/ClothesSprite") as Sprite2D
@onready var head_sprite: Sprite2D = get_node_or_null("Rig/RootBone/BodyBone/HeadBone/HeadSprite") as Sprite2D
@onready var face_sprite: Sprite2D = get_node_or_null("Rig/RootBone/BodyBone/HeadBone/FaceSprite") as Sprite2D
@onready var hair_back_sprite: Sprite2D = get_node_or_null("Rig/RootBone/BodyBone/HeadBone/HairBackSprite") as Sprite2D
@onready var hair_front_sprite: Sprite2D = get_node_or_null("Rig/RootBone/BodyBone/HeadBone/HairFrontSprite") as Sprite2D
@onready var accessory_sprite: Sprite2D = get_node_or_null("Rig/RootBone/BodyBone/HeadBone/AccessorySprite") as Sprite2D

var current_hair := -1
var current_clothes := -1
var current_face := -1
var current_accessory := -1


func _ready() -> void:
	for sprite in _all_slots():
		if sprite == null:
			continue
		sprite.texture = atlas_texture
		sprite.region_enabled = true
		sprite.centered = true
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
	return [body_sprite, clothes_sprite, head_sprite, face_sprite, hair_back_sprite, hair_front_sprite, accessory_sprite]


func _apply_default_regions() -> void:
	_apply_region(body_sprite, default_body_region, Vector2.ZERO, 0)
	_apply_region(head_sprite, default_head_region, Vector2(0, -20), 2)
	_apply_region(clothes_sprite, default_clothes_region, Vector2.ZERO, 1)
	_apply_region(face_sprite, default_face_region, Vector2.ZERO, 3)
	_apply_region(hair_back_sprite, default_hair_region, Vector2(0, -2), 1)
	_apply_region(hair_front_sprite, default_hair_region, Vector2(0, -2), 4)
	_apply_region(accessory_sprite, default_accessory_region, Vector2.ZERO, 5)
	# Placeholder regions are intentionally hidden until real atlas bounds are configured.
	for sprite in _all_slots():
		if sprite != null:
			sprite.visible = false


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
