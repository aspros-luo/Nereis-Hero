extends Node2D
## Explicit grapple point. Levels can add this script or join the grapple_anchors group.
## 明确标记的钩爪锚点；正式关卡可以挂载此脚本或加入 grapple_anchors 组。

@export var debug_fixture := false
@export var anchor_label := "ANCHOR"

func _ready() -> void:
    add_to_group("grapple_anchors")
    queue_redraw()

func _draw() -> void:
    var tint := Color("#8bd0bd") if debug_fixture else Color("#c8b79d")
    draw_circle(Vector2.ZERO, 5.0, tint)
    draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 28, Color(tint.r, tint.g, tint.b, 0.9), 2.0)
    draw_arc(Vector2.ZERO, 23.0, 0.28, TAU - 0.28, 28, Color(tint.r, tint.g, tint.b, 0.35), 1.0)
    if debug_fixture:
        draw_string(ThemeDB.fallback_font, Vector2(20.0, 4.0), anchor_label, HORIZONTAL_ALIGNMENT_LEFT, 120.0, 10, tint)
