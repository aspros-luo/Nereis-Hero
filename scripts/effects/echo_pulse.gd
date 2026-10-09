extends Node2D
## A short, restrained distortion pulse for Eldritch Echo.
## 余响使用的短暂空间扭曲波纹。

var age := 0.0
const LIFETIME := 0.34
const MAX_RADIUS := 190.0

func _process(delta: float) -> void:
    age += delta
    queue_redraw()
    if age >= LIFETIME:
        queue_free()

func _draw() -> void:
    var progress := clampf(age / LIFETIME, 0.0, 1.0)
    var radius := lerpf(18.0, MAX_RADIUS, progress)
    var alpha := (1.0 - progress) * 0.72
    var color := Color(0.48, 0.34, 0.70, alpha)
    draw_arc(Vector2.ZERO, radius, -PI * 0.82, PI * 0.82, 48, color, 3.0)
    draw_arc(Vector2.ZERO, radius * 0.78, -PI * 0.30, PI * 0.62, 36, Color(0.72, 0.66, 0.88, alpha * 0.55), 1.5)
    for index in range(5):
        var angle := -PI * 0.7 + float(index) * PI * 0.35
        var inner := Vector2(cos(angle), sin(angle)) * radius * 0.72
        var outer := Vector2(cos(angle + 0.08), sin(angle + 0.08)) * radius
        draw_line(inner, outer, Color(0.32, 0.20, 0.48, alpha * 0.7), 2.0)
