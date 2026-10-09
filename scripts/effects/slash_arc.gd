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
    age = 0.0
    queue_redraw()

func setup_combat_technique(direction: float, technique_id: String, stage: int = 0) -> void:
    facing = direction
    combat_technique = technique_id
    technique_stage = clampi(stage, 0, 2)
    short_blade = technique_id == "technique_crescent_combo"
    lifetime = 0.24 if technique_id == "technique_judgment_slash" else 0.19
    total_lifetime = lifetime
    age = 0.0
    queue_redraw()

func _p(x: float, y: float) -> Vector2:
    return Vector2(x * facing, y)

func _draw_weapon_technique(alpha: float) -> void:
    if combat_technique == "technique_judgment_slash":
        # Heavy, weighty blade: dark ink silhouette, warm steel body and a narrow bright edge.
        var shadow := Color("#201a23")
        shadow.a = alpha * 0.82
        var steel := Color("#c9c1ad")
        steel.a = alpha
        var edge := Color("#fff2d2")
        edge.a = alpha * 0.96
        draw_colored_polygon(PackedVector2Array([
            _p(7.0, -12.0), _p(35.0, -42.0), _p(108.0, -61.0),
            _p(88.0, -42.0), _p(37.0, -23.0), _p(17.0, -7.0)
        ]), shadow)
        draw_colored_polygon(PackedVector2Array([
            _p(12.0, -15.0), _p(39.0, -41.0), _p(101.0, -56.0),
            _p(80.0, -39.0), _p(37.0, -22.0), _p(19.0, -9.0)
        ]), steel)
        draw_line(_p(28.0, -27.0), _p(96.0, -52.0), edge, 3.5)
        draw_line(_p(15.0, -13.0), _p(38.0, -31.0), Color(0.98, 0.78, 0.43, alpha * 0.95), 2.0)
        draw_arc(Vector2(facing * 28.0, -25.0), 73.0, -1.15 if facing > 0.0 else PI - 0.30, 0.26 if facing > 0.0 else PI + 1.15, 24, Color(0.84, 0.69, 0.43, alpha * 0.72), 2.0)
        for index in range(5):
            var t := float(index) / 4.0
            var start := _p(80.0 + t * 22.0, -43.0 - t * 8.0)
            var finish := start + Vector2(facing * (7.0 + float(index % 2) * 4.0), -8.0 - float(index % 3) * 3.0)
            draw_line(start, finish, Color(1.0, 0.82, 0.53, alpha * (1.0 - t * 0.35)), 2.0 if index % 2 == 0 else 1.3)
        return

    if combat_technique == "technique_crescent_combo":
        var stage := technique_stage
        var shadow := Color(0.20, 0.10, 0.18, alpha * 0.86)
        var silver := Color(0.76, 0.84, 0.91, alpha * 0.98)
        var moon_edge := Color(0.97, 0.98, 1.0, alpha)
        if stage == 0:
            # First hit: low, fast, almost horizontal crescent.
            draw_colored_polygon(PackedVector2Array([
                _p(5.0, -11.0), _p(24.0, -34.0), _p(63.0, -47.0),
                _p(49.0, -30.0), _p(22.0, -20.0), _p(10.0, -5.0)
            ]), shadow)
            draw_colored_polygon(PackedVector2Array([
                _p(10.0, -14.0), _p(27.0, -33.0), _p(59.0, -43.0),
                _p(43.0, -29.0), _p(22.0, -20.0), _p(14.0, -9.0)
            ]), silver)
            draw_line(_p(15.0, -16.0), _p(55.0, -39.0), moon_edge, 2.5)
        elif stage == 1:
            # Second hit: an upward cut with a taller silhouette.
            draw_colored_polygon(PackedVector2Array([
                _p(13.0, -8.0), _p(27.0, -35.0), _p(34.0, -66.0),
                _p(47.0, -47.0), _p(38.0, -20.0), _p(22.0, -7.0)
            ]), shadow)
            draw_colored_polygon(PackedVector2Array([
                _p(18.0, -12.0), _p(29.0, -37.0), _p(35.0, -61.0),
                _p(42.0, -44.0), _p(35.0, -21.0), _p(24.0, -11.0)
            ]), silver)
            draw_line(_p(23.0, -17.0), _p(35.0, -57.0), moon_edge, 2.7)
        else:
            # Finisher: broad crossing cut and a brief pale-gold impact edge.
            draw_colored_polygon(PackedVector2Array([
                _p(7.0, -10.0), _p(28.0, -42.0), _p(78.0, -57.0),
                _p(62.0, -37.0), _p(31.0, -22.0), _p(15.0, -4.0)
            ]), shadow)
            draw_colored_polygon(PackedVector2Array([
                _p(12.0, -13.0), _p(32.0, -41.0), _p(73.0, -53.0),
                _p(57.0, -36.0), _p(31.0, -22.0), _p(19.0, -8.0)
            ]), silver)
            draw_line(_p(18.0, -15.0), _p(69.0, -48.0), moon_edge, 3.0)
            draw_line(_p(24.0, -49.0), _p(67.0, -14.0), Color(1.0, 0.83, 0.60, alpha * 0.95), 2.4)
            draw_arc(Vector2(facing * 28.0, -29.0), 48.0, -1.10 if facing > 0.0 else PI - 0.35, 0.36 if facing > 0.0 else PI + 1.10, 20, Color(0.86, 0.70, 0.85, alpha * 0.78), 2.0)
            for index in range(4):
                var origin := _p(58.0 + float(index % 2) * 8.0, -36.0 - float(index) * 3.0)
                draw_line(origin, origin + Vector2(facing * (7.0 + float(index % 2) * 3.0), -7.0 - float(index % 3) * 2.0), Color(1.0, 0.85, 0.65, alpha * 0.9), 1.7)
        return

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
