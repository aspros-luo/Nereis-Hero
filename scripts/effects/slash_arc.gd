extends Node2D

var facing := 1.0
var combo_step := 1
var age := 0.0
var lifetime := 0.16

func setup(direction: float, combo: int) -> void:
    facing = direction
    combo_step = clampi(combo, 1, 3)
    queue_redraw()

func _process(delta: float) -> void:
    age += delta
    lifetime -= delta
    queue_redraw()
    if lifetime <= 0.0:
        queue_free()

func _draw() -> void:
    var progress: float = clampf(age / 0.16, 0.0, 1.0)
    var alpha: float = 1.0 - progress
    var radius: float = 56.0 + combo_step * 5.0
    var width: float = 7.0 if combo_step == 3 else 5.0
    var center := Vector2(facing * 18.0, -24.0)
    var start := -1.18 if facing > 0.0 else 1.18
    var end := 1.18 if facing > 0.0 else 5.10
    draw_arc(center, radius, start, end, 20, Color(0.90, 0.86, 0.74, alpha), width)
    draw_arc(center, radius + 9.0, start + 0.08, end - 0.08, 16, Color(0.48, 0.43, 0.40, alpha * 0.45), 2.0)
    if combo_step == 3:
        draw_line(
            Vector2(facing * 18.0, -24.0),
            Vector2(facing * 88.0, -38.0),
            Color(0.95, 0.90, 0.76, alpha * 0.75),
            3.0
        )
