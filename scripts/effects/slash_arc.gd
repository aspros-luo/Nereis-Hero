extends Node2D

var facing := 1.0
var combo_step := 1
var age := 0.0
var lifetime := 0.16
var short_blade := false
var blood_iaijutsu := false
var technique_variant := ""

func setup(direction: float, combo: int, is_short_blade: bool = false, is_blood_iaijutsu: bool = false, variant: String = "") -> void:
    facing = direction
    combo_step = clampi(combo, 1, 4)
    short_blade = is_short_blade
    blood_iaijutsu = is_blood_iaijutsu
    technique_variant = variant if is_blood_iaijutsu else ""
    lifetime = 0.28 if technique_variant == "black_horizon" else 0.25 if technique_variant == "abyssal" else 0.22 if blood_iaijutsu else 0.12 if short_blade else 0.16
    queue_redraw()

func _process(delta: float) -> void:
    age += delta
    lifetime -= delta
    queue_redraw()
    if lifetime <= 0.0:
        queue_free()

func _draw() -> void:
    var progress: float = clampf(age / maxf(lifetime, 0.01), 0.0, 1.0)
    var alpha: float = 1.0 - progress
    var radius: float = 142.0 if technique_variant == "black_horizon" else 116.0 if technique_variant == "abyssal" else 92.0 if blood_iaijutsu else (35.0 + combo_step * 2.5 if short_blade else 56.0 + combo_step * 5.0)
    var width: float = 13.0 if technique_variant == "black_horizon" else 11.0 if technique_variant == "abyssal" else 10.0 if blood_iaijutsu else (3.0 if short_blade else (7.0 if combo_step == 3 else 5.0))
    var center := Vector2(facing * (30.0 if blood_iaijutsu else 18.0), -24.0)
    var start := -0.72 if blood_iaijutsu and facing > 0.0 else (-2.42 if blood_iaijutsu else (-0.85 if short_blade and facing > 0.0 else (-1.18 if facing > 0.0 else 1.18)))
    var end := 0.72 if blood_iaijutsu and facing > 0.0 else (3.86 if blood_iaijutsu else (0.85 if short_blade and facing > 0.0 else (1.18 if facing > 0.0 else 5.10)))
    var slash_color := Color(0.07, 0.05, 0.10, alpha) if technique_variant == "black_horizon" else Color(0.42, 0.20, 0.72, alpha) if technique_variant == "abyssal" else Color(0.80, 0.12, 0.20, alpha) if blood_iaijutsu else Color(0.90, 0.86, 0.74, alpha)
    draw_arc(center, radius, start, end, 24, slash_color, width)
    if technique_variant == "black_horizon":
        draw_line(Vector2(facing * 8.0, -25.0), Vector2(facing * 178.0, -40.0), Color(0.06, 0.04, 0.09, alpha * 0.9), 8.0)
        draw_arc(center, radius + 15.0, start + 0.08, end - 0.08, 24, Color(0.50, 0.40, 0.66, alpha * 0.55), 3.0)
    elif technique_variant == "abyssal":
        draw_line(Vector2(facing * 10.0, -25.0), Vector2(facing * 156.0, -38.0), Color(0.48, 0.24, 0.76, alpha * 0.85), 6.0)
    elif blood_iaijutsu:
        draw_line(Vector2(facing * 10.0, -25.0), Vector2(facing * 138.0, -36.0), Color(0.86, 0.18, 0.24, alpha * 0.85), 5.0)
    elif not short_blade:
        draw_arc(center, radius + 9.0, start + 0.08, end - 0.08, 16, Color(0.48, 0.43, 0.40, alpha * 0.45), 2.0)
    if combo_step == 3 and not short_blade:
        draw_line(
            Vector2(facing * 18.0, -24.0),
            Vector2(facing * 88.0, -38.0),
            Color(0.95, 0.90, 0.76, alpha * 0.75),
            3.0
        )
    elif combo_step == 4 and short_blade:
        draw_line(
            Vector2(facing * 12.0, -18.0),
            Vector2(facing * 58.0, -44.0),
            Color(0.95, 0.90, 0.76, alpha * 0.8),
            3.0
        )
