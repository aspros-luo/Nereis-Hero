extends Area2D
class_name TransitionPoint
## 玩家进入触发区后请求切换到指定房间和入口。

signal transition_requested(target_room_id: StringName, target_entry_id: StringName)

@export var connection_id: StringName
@export var target_room_id: StringName
@export var target_entry_id: StringName = &"default"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not target_room_id.is_empty():
		transition_requested.emit(target_room_id, target_entry_id)
