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

const JUDGMENT_ART: Texture2D = preload("res://assets/art/vfx/judgment_slash.svg")
const CRESCENT_ONE_ART: Texture2D = preload("res://assets/art/vfx/crescent_1.svg")
const CRESCENT_TWO_ART: Texture2D = preload("res://assets/art/vfx/crescent_2.svg")
const CRESCENT_THREE_ART: Texture2D = preload("res://assets/art/vfx/crescent_3.svg")

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
    var texture: Texture2D
    var rect: Rect2
    if combat_technique == "technique_judgment_slash":
        texture = JUDGMENT_ART
        rect = Rect2(0.0, -80.0, 150.0, 94.0)
    elif technique_stage == 0:
        texture = CRESCENT_ONE_ART
        rect = Rect2(0.0, -52.0, 106.0, 62.0)
    elif technique_stage == 1:
        texture = CRESCENT_TWO_ART
        rect = Rect2(0.0, -94.0, 82.0, 100.0)
    else:
        texture = CRESCENT_THREE_ART
        rect = Rect2(0.0, -78.0, 130.0, 92.0)

    # Original illustrated sprites provide the blade silhouette; timing remains driven by combat code.
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
    draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, alpha))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _process(delta: float) -> void:
    age += delta
    lifetime -= delta
    queue_redraw()
    if lifetime <= 0.0:
        queue_free()

func _draw() -> void:
    # Ease the fade so the slash has a readable bright core and a softer trailing edge.
    # 使用缓出淡化，让刀光核心清晰、尾迹柔和。
    var alpha: float = clampf(lifetime / maxf(total_lifetime, 0.01), 0.0, 1.0)
    alpha = alpha * alpha * (3.0 - 2.0 * alpha)
    if not combat_technique.is_empty():
        _draw_weapon_technique(alpha)
        return
    var radius: float = 142.0 if technique_variant == "black_horizon" else 116.0 if technique_variant == "abyssal" else 104.0 if technique_variant == "human_iaijutsu" else 92.0 if blood_iaijutsu else (35.0 + combo_step * 2.5 if short_blade else 56.0 + combo_step * 5.0)
    var width: float = 13.0 if technique_variant == "black_horizon" else 11.0 if technique_variant == "abyssal" else 7.0 if technique_variant == "human_iaijutsu" else 10.0 if blood_iaijutsu else (3.0 if short_blade else (7.0 if combo_step == 3 else 5.0))
    var center := Vector2(facing * (30.0 if blood_iaijutsu else 18.0), -24.0)
    var start := -0.72 if blood_iaijutsu and facing > 0.0 else (-2.42 if blood_iaijutsu else (-0.85 if short_blade and facing > 0.0 else (-1.18 if facing > 0.0 else 1.18)))
    var end := 0.72 if blood_iaijutsu and facing > 0.0 else (3.86 if blood_iaijutsu else (0.85 if short_blade and facing > 0.0 else (1.18 if facing > 0.0 else 5.10)))
    var slash_color := Color(0.07, 0.05, 0.10, alpha) if technique_variant == "black_horizon" else Color(0.42, 0.20, 0.72, alpha) if technique_variant == "abyssal" else Color(0.78, 0.84, 0.90, alpha) if technique_variant == "human_iaijutsu" else Color(0.80, 0.12, 0.20, alpha) if blood_iaijutsu else Color(0.90, 0.86, 0.74, alpha)
    # Layered strokes create a restrained glow without relying on screen-wide bloom.
    # 多层线条形成克制的刀光层次，不依赖全屏泛光。
    var glow_color := Color(slash_color.r, slash_color.g, slash_color.b, alpha * 0.18)
    var core_color := Color(
        minf(1.0, slash_color.r * 1.12 + 0.12),
        minf(1.0, slash_color.g * 1.08 + 0.10),
        minf(1.0, slash_color.b * 1.04 + 0.08),
        alpha * 0.72
    )
    draw_arc(center, radius, start, end, 36, glow_color, width * 2.8, true)
    draw_arc(center, radius, start, end, 36, slash_color, width, true)
    if width >= 5.0:
        draw_arc(center, radius - 3.0, start + 0.06, end - 0.06, 30, core_color, maxf(1.0, width * 0.28), true)

    # A few directional flecks sell motion, while remaining deterministic and inexpensive.
    # 少量定向碎光强调挥砍速度，且不使用随机粒子，成本稳定。
    if not short_blade and combo_step >= 2:
        for fleck_index in range(3):
            var t: float = float(fleck_index + 1) / 4.0
            var angle: float = lerpf(start, end, t)
            var inner_point := center + Vector2(cos(angle), sin(angle)) * (radius - 8.0)
            var outer_point := center + Vector2(cos(angle), sin(angle)) * (radius + 5.0 + float(combo_step))
            draw_line(inner_point, outer_point, Color(core_color.r, core_color.g, core_color.b, alpha * 0.48), 1.5, true)

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
