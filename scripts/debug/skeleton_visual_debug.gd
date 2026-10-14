extends Node2D

# S1.2.2-A2 Skeleton Visual Debug Layer
# Draws a lightweight reference skeleton without replacing final character art.

@export var enabled := true

func _draw() -> void:
    if not enabled:
        return

    draw_circle(Vector2.ZERO, 8.0, Color.WHITE)
    draw_line(Vector2.ZERO, Vector2(0, -32), Color.WHITE, 2.0)
    draw_line(Vector2(0, -32), Vector2(-18, -32), Color.WHITE, 2.0)
    draw_line(Vector2(0, -32), Vector2(18, -32), Color.WHITE, 2.0)
    draw_line(Vector2.ZERO, Vector2(-10, 20), Color.WHITE, 2.0)
    draw_line(Vector2.ZERO, Vector2(10, 20), Color.WHITE, 2.0)

func _ready() -> void:
    queue_redraw()
