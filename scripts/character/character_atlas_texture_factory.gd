class_name CharacterAtlasTextureFactory
extends RefCounted

## Builds runtime AtlasTexture wrappers; source atlas remains one shared texture.
## 运行时创建 AtlasTexture 包装资源；所有部件仍共用同一张原始图集。


static func is_valid_region(atlas: Texture2D, region: Rect2) -> bool:
	if atlas == null:
		return false
	if region.position.x < 0.0 or region.position.y < 0.0:
		return false
	if region.size.x <= 0.0 or region.size.y <= 0.0:
		return false
	var atlas_size := Vector2(atlas.get_width(), atlas.get_height())
	return region.end.x <= atlas_size.x and region.end.y <= atlas_size.y


static func from_part(atlas: Texture2D, part: CharacterPartData) -> AtlasTexture:
	if atlas == null or part == null or not is_valid_region(atlas, part.atlas_region):
		return null
	var result := AtlasTexture.new()
	result.atlas = atlas
	result.region = part.atlas_region
	return result


static func apply_to_sprite(sprite: Sprite2D, atlas: Texture2D, part: CharacterPartData) -> bool:
	if sprite == null or atlas == null or part == null:
		return false
	var part_texture := from_part(atlas, part)
	if part_texture == null:
		push_warning("Rejected invalid atlas region for character part: %s" % part.display_name)
		return false
	sprite.texture = part_texture
	sprite.region_enabled = false
	sprite.centered = true
	sprite.position = part.local_position
	sprite.offset = part.local_offset
	sprite.scale = part.local_scale
	sprite.rotation = part.local_rotation
	sprite.z_index = part.z_index
	sprite.visible = part.enabled
	return true
