extends Node2D
class_name RoomBounds
## Rect2 使用房间根节点的局部坐标；相机边界允许任意宽高。

@export var bounds: Rect2 = Rect2(0.0, 0.0, 1280.0, 720.0)

func get_room_rect() -> Rect2:
	return bounds
