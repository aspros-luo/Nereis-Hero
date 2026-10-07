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
    var c := Color(0.86, 0.78, 0.62, alpha)
    for i in range(6):
        var angle: float = TAU * float(i) / 6.0
        var start := Vector2.from_angle(angle) * (radius * 0.35)
        var end := Vector2.from_angle(angle) * radius
        draw_line(start, end, c, 3.0)
    draw_circle(Vector2.ZERO, 4.0, c)
