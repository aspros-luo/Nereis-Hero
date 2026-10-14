extends Node2D

## Hero visual layer foundation.
## The previous procedural drawing approach is treated as prototype-only.
## This node will host AnimatedSprite2D/Skeleton2D resources in later art passes.
##
## 主角表现层基础节点。
## 旧版 draw_polygon 绘制仅作为原型，不作为正式角色方案。
## 后续接入 AnimatedSprite2D / Skeleton2D。

@export var use_placeholder_visual := true

var visual_state := "idle"

func set_visual_state(state: String) -> void:
	visual_state = state
	# AnimationTree/Skeleton2D switching will be connected here.

func refresh_from_combat_state(combat_state) -> void:
	# Reserved adapter between hero state machine and animation layer.
	pass
