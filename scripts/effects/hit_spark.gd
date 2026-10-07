extends Node2D

var lifetime := 0.16
var age := 0.0
var radius := 8.0

func _ready() -> void:
    queue_redraw()

func _process(delta: float) -> void:
    age += delta
    lifetime -= delta
    radius += 180.0 * delta
    queue_redraw()
    if lifetime <= 0.0:
        queue_free()

func _draw() -> void:
    var alpha: float = maxf(0.0, lifetime / 0.16)
    var c := Color(0.92, 0.84, 0.68, alpha)
    draw_circle(Vector2.ZERO, 4.0 + radius * 0.08, Color(0.12, 0.10, 0.13, alpha * 0.7))
    draw_circle(Vector2.ZERO, 3.0, c)
    for i in range(8):
        var angle: float = TAU * float(i) / 8.0
        var start := Vector2.from_angle(angle) * (radius * 0.28)
        var end := Vector2.from_angle(angle) * radius
        draw_line(start, end, c, 3.0 if i % 2 == 0 else 2.0)
    draw_arc(Vector2.ZERO, radius * 0.62, 0.0, TAU, 20, c, 2.0)
