extends Node
class_name RoomTransitionManager
## 管理切换锁，防止玩家在淡出过程中重复触发过渡。

var is_transitioning: bool = false

func begin_transition() -> bool:
	if is_transitioning:
		return false
	is_transitioning = true
	return true

func end_transition() -> void:
	is_transitioning = false
