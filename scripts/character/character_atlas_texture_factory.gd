class_name CharacterAtlasTextureFactory
extends RefCounted

## Builds runtime AtlasTexture wrappers; source atlas remains one shared texture.
## 运行时创建 AtlasTexture 包装资源；所有部件仍共用同一张原始图集。


static func from_part(atlas: Texture2D, part: CharacterPartData) -> AtlasTexture:
	if atlas == null or part == null:
		return null
	var result := AtlasTexture.new()
	result.atlas = atlas
	result.region = part.atlas_region
	return result


static func apply_to_sprite(sprite: Sprite2D, atlas: Texture2D, part: CharacterPartData) -> bool:
	if sprite == null or atlas == null or part == null:
		return false
	sprite.texture = from_part(atlas, part)
	sprite.region_enabled = false
	sprite.centered = true
	sprite.position = part.local_position
	sprite.offset = part.local_offset
	sprite.scale = part.local_scale
	sprite.rotation = part.local_rotation
	sprite.z_index = part.z_index
	sprite.visible = part.enabled
	return true
