extends Node2D

var age := 0.0
var lifetime := 0.38
var burst_size := 10.0

func setup(size: float = 10.0) -> void:
    burst_size = size
    queue_redraw()

func _process(delta: float) -> void:
    age += delta
    lifetime -= delta
    burst_size += 90.0 * delta
    queue_redraw()
    if lifetime <= 0.0:
        queue_free()

func _draw() -> void:
    var alpha: float = maxf(0.0, lifetime / 0.38)
    var c := Color(0.60, 0.48, 0.50, alpha)
    draw_circle(Vector2.ZERO, burst_size * 0.35, Color(0.12, 0.10, 0.13, alpha * 0.75))
    for i in range(10):
        var angle: float = TAU * float(i) / 10.0
        var start := Vector2.from_angle(angle) * (burst_size * 0.25)
        var end := Vector2.from_angle(angle) * burst_size
        draw_line(start, end, c, 2.0)
