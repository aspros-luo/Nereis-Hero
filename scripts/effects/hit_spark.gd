extends Node2D

var lifetime := 0.19
var age := 0.0
var radius := 8.0
var seed_angle := 0.0
const HIT_SPARK_ART: Texture2D = preload("res://assets/art/vfx/hit_spark.svg")

func _ready() -> void:
    # Per-instance deterministic variation without relying on global random state.
    seed_angle = float(get_instance_id() % 17) * 0.23
    queue_redraw()

func _process(delta: float) -> void:
    age += delta
    lifetime -= delta
    radius += 230.0 * delta
    queue_redraw()
    if lifetime <= 0.0:
        queue_free()

func _draw() -> void:
    var progress := clampf(age / 0.19, 0.0, 1.0)
    var alpha := 1.0 - progress
    draw_texture_rect(HIT_SPARK_ART, Rect2(-radius * 0.9, -radius * 0.9, radius * 1.8, radius * 1.8), false, Color(1.0, 1.0, 1.0, alpha))
    var c := Color("#f4dca4")
    c.a = alpha
    var white := Color("#fff7df")
    white.a = alpha * 0.95
    var shadow := Color("#271c29")
    shadow.a = alpha * 0.8

    # Dark impact core with a bright diamond center.
    draw_circle(Vector2.ZERO, 4.0 + radius * 0.05, shadow)
    draw_colored_polygon(PackedVector2Array([
        Vector2(0.0, -5.0 - progress * 2.0),
        Vector2(4.0 + progress * 2.0, 0.0),
        Vector2(0.0, 5.0 + progress * 2.0),
        Vector2(-4.0 - progress * 2.0, 0.0)
    ]), white)

    # Alternating long and short tapered splinters give impact direction and depth.
    for index in range(9):
        var angle := seed_angle + TAU * float(index) / 9.0
        var direction := Vector2.from_angle(angle)
        var tangent := Vector2(-direction.y, direction.x)
        var inner := direction * (radius * 0.22)
        var outer := direction * (radius * (0.74 if index % 2 == 0 else 0.52))
        var width := 2.0 if index % 3 == 0 else 1.1
        var shard := PackedVector2Array([
            inner - tangent * width,
            outer,
            inner + tangent * width
        ])
        draw_colored_polygon(shard, c)

    # The broken ring contracts in opacity while the splinters expand.
    draw_arc(Vector2.ZERO, radius * 0.48, seed_angle - 0.75, seed_angle + 1.9, 24, c, 1.6)
