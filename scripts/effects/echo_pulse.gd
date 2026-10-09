extends Node2D
## Eldritch Echo: a broken, ritual-like resonance ring.
## 余响：具有破碎仪式感的异界共鸣波纹。

var age := 0.0
const LIFETIME := 0.42
const MAX_RADIUS := 190.0
const ECHO_ART: Texture2D = preload("res://assets/art/vfx/eldritch_echo.svg")

func _process(delta: float) -> void:
    age += delta
    queue_redraw()
    if age >= LIFETIME:
        queue_free()

func _draw() -> void:
    var progress := clampf(age / LIFETIME, 0.0, 1.0)
    var eased := 1.0 - pow(1.0 - progress, 2.0)
    var radius := lerpf(12.0, MAX_RADIUS, eased)
    var alpha := pow(1.0 - progress, 1.35)

    # The authored occult sigil rides inside the expanding procedural distortion.
    draw_texture_rect(ECHO_ART, Rect2(-radius, -radius, radius * 2.0, radius * 2.0), false, Color(1.0, 1.0, 1.0, alpha * 0.72))
    var outer := Color("#8b659f")
    outer.a = alpha * 0.72
    var pale := Color("#d7c7e9")
    pale.a = alpha * 0.82
    var dark := Color("#392642")
    dark.a = alpha * 0.76

    # Three broken rings expand at different speeds to imply a distortion, not a simple circle.
    draw_arc(Vector2.ZERO, radius, -PI * 0.88, PI * 0.72, 64, outer, 3.0)
    draw_arc(Vector2.ZERO, radius * 0.83, PI * 0.12, PI * 1.04, 48, pale, 1.6)
    draw_arc(Vector2.ZERO, radius * 0.58, -PI * 0.18, PI * 0.62, 40, dark, 2.0)

    # Broken radial runes. Their spacing is deliberately irregular, like a damaged seal.
    for index in range(9):
        var angle := -PI * 0.88 + float(index) * PI * 0.205
        var inner := Vector2.from_angle(angle) * radius * (0.73 if index % 3 == 0 else 0.82)
        var outer_point := Vector2.from_angle(angle + 0.035) * radius
        var rune_color := pale if index % 3 == 0 else outer
        draw_line(inner, outer_point, rune_color, 1.8 if index % 2 == 0 else 1.1)
        if index % 2 == 0:
            var tangent := Vector2.from_angle(angle + PI * 0.5) * (5.0 + progress * 2.0)
            draw_line(outer_point - tangent, outer_point + tangent, rune_color, 1.2)

    # A small, dark core makes the pulse read clearly against busy backgrounds.
    var core_radius := lerpf(4.0, 25.0, progress)
    draw_circle(Vector2.ZERO, core_radius, Color(0.10, 0.06, 0.14, alpha * 0.34))
    draw_arc(Vector2.ZERO, core_radius + 5.0, 0.0, TAU, 32, pale, 1.5)
    for index in range(6):
        var angle := float(index) * TAU / 6.0 + progress * 0.35
        var direction := Vector2.from_angle(angle)
        draw_line(direction * (core_radius + 8.0), direction * (core_radius + 15.0 + progress * 7.0), Color(0.78, 0.66, 0.90, alpha * 0.9), 1.7)
