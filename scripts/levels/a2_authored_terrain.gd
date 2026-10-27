extends Node
## Retired A2 region-wide room assembler.
## A2 旧版区域级房间装配器已停用：固定房间必须由正式 .tscn 场景持有。

## This script intentionally does not preload or instantiate legacy room scenes.
## The playable A2 architecture now enters the six authored runtime room scenes directly.
## 此脚本不再预加载或实例化旧版房间；A2 通过六个正式房间场景独立运行。

func _ready() -> void:
	push_warning("[NEREIS][A2][LEGACY_ASSEMBLER] a2_authored_terrain.gd is retired; use scenes/rooms/a2_fog_forest/runtime/*.tscn")


func configure_platforms(_region: Node) -> void:
	push_error("[NEREIS][A2][LEGACY_ASSEMBLER] runtime platform registration is disabled; author terrain and collision in the room .tscn")
