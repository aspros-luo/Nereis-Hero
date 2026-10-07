extends StaticBody2D

var open_progress := 0.0
var opening := false
var animation_time := 0.0

func _process(delta: float) -> void:
    animation_time += delta
    if opening:
        open_progress = minf(1.0, open_progress + delta / 0.35)
        if open_progress >= 1.0:
            queue_free()
    queue_redraw()

func _ready() -> void:
    collision_layer = 1
    collision_mask = 0

    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(42, 170)
    shape.shape = rectangle
    shape.position = Vector2(0, -85)
    add_child(shape)
    queue_redraw()

func open() -> void:
    if opening:
        return
    opening = true
    collision_layer = 0
    print("[NEREIS][WORLD] Boss gate opened")

func _draw() -> void:
    var openness: float = 1.0 - open_progress
    var drift: float = sin(animation_time * 5.0) * 2.0
    draw_rect(Rect2(-21, -170 * openness, 42, 170 * openness), Color("#302833", 0.92))
    draw_line(Vector2(-12, -160 * openness), Vector2(-12, -12), Color("#796d67", 0.9), 4.0)
    draw_line(Vector2(0, -160 * openness), Vector2(0, -12), Color("#796d67", 0.9), 4.0)
    draw_line(Vector2(12, -160 * openness), Vector2(12, -12), Color("#796d67", 0.9), 4.0)
    draw_circle(Vector2(0, -128 * openness + drift), 9.0 + open_progress * 8.0, Color("#b95d67", 0.7 - open_progress * 0.5))
    draw_string(ThemeDB.fallback_font, Vector2(-58, 24), "ASH GATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#796d67", 1.0 - open_progress))
