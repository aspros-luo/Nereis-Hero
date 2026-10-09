extends Node2D

var facing := 1.0
var combo_step := 1
var age := 0.0
var lifetime := 0.16
var total_lifetime := 0.16
var short_blade := false
var blood_iaijutsu := false
var technique_variant := ""
var combat_technique := ""
var technique_stage := 0

func setup(direction: float, combo: int, is_short_blade: bool = false, is_blood_iaijutsu: bool = false, variant: String = "") -> void:
    facing = direction
    combo_step = clampi(combo, 1, 4)
    short_blade = is_short_blade
    blood_iaijutsu = is_blood_iaijutsu
    technique_variant = variant if is_blood_iaijutsu else ""
    lifetime = 0.28 if technique_variant == "black_horizon" else 0.25 if technique_variant == "abyssal" else 0.22 if blood_iaijutsu else 0.12 if short_blade else 0.16
    total_lifetime = lifetime
    queue_redraw()

func setup_combat_technique(direction: float, technique_id: String, stage: int = 0) -> void:
    facing = direction
    combat_technique = technique_id
    technique_stage = clampi(stage, 0, 2)
    short_blade = technique_id == "technique_crescent_combo"
    lifetime = 0.20 if technique_id == "technique_judgment_slash" else 0.15
    total_lifetime = lifetime
    age = 0.0
    queue_redraw()

func _draw_weapon_technique(alpha: float) -> void:
    if combat_technique == "technique_judgment_slash":
        var center := Vector2(facing * 20.0, -26.0)
        var start := -1.28 if facing > 0.0 else PI - 0.42
        var finish := 0.42 if facing > 0.0 else PI + 1.28
        draw_arc(center, 102.0, start, finish, 30, Color(0.92, 0.87, 0.73, alpha), 11.0)
        draw_arc(center, 89.0, start + 0.10, finish - 0.10, 26, Color(0.68, 0.72, 0.76, alpha * 0.78), 3.0)
        draw_line(Vector2(facing * 14.0, -22.0), Vector2(facing * 112.0, -46.0), Color(0.98, 0.95, 0.86, alpha * 0.88), 4.0)
        return

    if combat_technique == "technique_crescent_combo":
        var center := Vector2(facing * (12.0 + float(technique_stage) * 4.0), -25.0)
        var radius := 43.0 + float(technique_stage) * 8.0
        var start := -1.50 + float(technique_stage) * 0.18 if facing > 0.0 else PI - 0.18 - float(technique_stage) * 0.18
        var finish := 0.30 + float(technique_stage) * 0.18 if facing > 0.0 else PI + 1.50 - float(technique_stage) * 0.18
        var slash_color := Color(0.84, 0.89, 0.94, alpha)
        draw_arc(center, radius, start, finish, 20, slash_color, 4.0)
        if technique_stage == 0:
            draw_line(Vector2(facing * 10.0, -12.0), Vector2(facing * 53.0, -51.0), Color(0.94, 0.96, 1.0, alpha * 0.9), 3.0)
        elif technique_stage == 1:
            draw_line(Vector2(facing * 18.0, -48.0), Vector2(facing * 64.0, -12.0), Color(0.94, 0.96, 1.0, alpha * 0.9), 3.0)
        else:
            draw_arc(center, radius + 10.0, start + 0.10, finish - 0.10, 18, Color(0.94, 0.96, 1.0, alpha * 0.65), 2.0)
            draw_line(Vector2(facing * 12.0, -16.0), Vector2(facing * 70.0, -47.0), Color(1.0, 0.94, 0.80, alpha), 4.0)

func _process(delta: float) -> void:
    age += delta
    lifetime -= delta
    queue_redraw()
    if lifetime <= 0.0:
        queue_free()

func _draw() -> void:
    var alpha: float = clampf(lifetime / maxf(total_lifetime, 0.01), 0.0, 1.0)
    if not combat_technique.is_empty():
        _draw_weapon_technique(alpha)
        return
    var radius: float = 142.0 if technique_variant == "black_horizon" else 116.0 if technique_variant == "abyssal" else 104.0 if technique_variant == "human_iaijutsu" else 92.0 if blood_iaijutsu else (35.0 + combo_step * 2.5 if short_blade else 56.0 + combo_step * 5.0)
    var width: float = 13.0 if technique_variant == "black_horizon" else 11.0 if technique_variant == "abyssal" else 7.0 if technique_variant == "human_iaijutsu" else 10.0 if blood_iaijutsu else (3.0 if short_blade else (7.0 if combo_step == 3 else 5.0))
    var center := Vector2(facing * (30.0 if blood_iaijutsu else 18.0), -24.0)
    var start := -0.72 if blood_iaijutsu and facing > 0.0 else (-2.42 if blood_iaijutsu else (-0.85 if short_blade and facing > 0.0 else (-1.18 if facing > 0.0 else 1.18)))
    var end := 0.72 if blood_iaijutsu and facing > 0.0 else (3.86 if blood_iaijutsu else (0.85 if short_blade and facing > 0.0 else (1.18 if facing > 0.0 else 5.10)))
    var slash_color := Color(0.07, 0.05, 0.10, alpha) if technique_variant == "black_horizon" else Color(0.42, 0.20, 0.72, alpha) if technique_variant == "abyssal" else Color(0.78, 0.84, 0.90, alpha) if technique_variant == "human_iaijutsu" else Color(0.80, 0.12, 0.20, alpha) if blood_iaijutsu else Color(0.90, 0.86, 0.74, alpha)
    draw_arc(center, radius, start, end, 24, slash_color, width)
    if technique_variant == "black_horizon":
        draw_line(Vector2(facing * 8.0, -25.0), Vector2(facing * 178.0, -40.0), Color(0.06, 0.04, 0.09, alpha * 0.9), 8.0)
        draw_arc(center, radius + 15.0, start + 0.08, end - 0.08, 24, Color(0.50, 0.40, 0.66, alpha * 0.55), 3.0)
    elif technique_variant == "abyssal":
        draw_line(Vector2(facing * 10.0, -25.0), Vector2(facing * 156.0, -38.0), Color(0.48, 0.24, 0.76, alpha * 0.85), 6.0)
    elif technique_variant == "blood":
        draw_line(Vector2(facing * 10.0, -25.0), Vector2(facing * 138.0, -36.0), Color(0.86, 0.18, 0.24, alpha * 0.85), 5.0)
    elif technique_variant == "human_iaijutsu":
        draw_line(Vector2(facing * 10.0, -25.0), Vector2(facing * 120.0, -34.0), Color(0.82, 0.88, 0.94, alpha * 0.75), 3.0)
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
