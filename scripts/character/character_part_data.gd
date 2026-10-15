class_name CharacterPartData
extends Resource

## Human-readable label shown in the customization UI.
@export var display_name: String = "Unnamed Part"
## Rectangle in the source atlas, in original texture pixels.
@export var atlas_region: Rect2 = Rect2(0, 0, 64, 64)
## Offset from the owning node / bone anchor.
@export var local_position: Vector2 = Vector2.ZERO
## Fine drawing correction within the Sprite2D.
@export var local_offset: Vector2 = Vector2.ZERO
@export var local_scale: Vector2 = Vector2.ONE
@export var local_rotation: float = 0.0
@export var z_index: int = 0
## Optional: hide this slot when this definition is selected.
@export var enabled: bool = true
