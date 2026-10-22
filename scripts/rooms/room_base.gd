extends Node2D
class_name RoomBase
## 房间根节点。房间尺寸由 RoomBounds 决定，不假定固定屏幕大小。

@export var room_id: StringName
@export var area_id: StringName
@export var room_bounds: Rect2 = Rect2(0.0, 0.0, 1280.0, 720.0)

func _ready() -> void:
	if room_id.is_empty():
		push_error("RoomBase: room_id 未设置")
		return
	WorldState.mark_room_explored(String(room_id))

func get_entry(entry_id: StringName) -> Marker2D:
	for node: Node in find_children("*", "Marker2D", true, false):
		if node is Marker2D and node.get("entry_id") == entry_id:
			return node as Marker2D
	return null

func get_room_bounds() -> Rect2:
	var bounds_node := get_node_or_null("RoomBounds") as Node2D
	if bounds_node != null and bounds_node.has_method("get_room_rect"):
		return bounds_node.call("get_room_rect")
	return room_bounds
