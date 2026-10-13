extends Node
class_name DebugDrawManager

## Development-only drawing registry.
## Keeps debug visualization away from gameplay rendering.

var enabled: bool = true
var shapes: Array = []

func clear() -> void:
    shapes.clear()

func register_shape(shape: Dictionary) -> void:
    if not enabled:
        return
    shapes.append(shape)

func unregister_all() -> void:
    clear()

func get_shapes() -> Array:
    return shapes.duplicate()
