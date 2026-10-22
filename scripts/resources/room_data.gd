extends Resource
class_name RoomData
## 房间的静态定义；运行时探索状态由 WorldState 持久化。

@export var room_id: StringName
@export var area_id: StringName
@export var scene_path: String
@export var entry_ids: PackedStringArray = ["default"]
@export var adjacent_room_ids: Array[StringName] = []
