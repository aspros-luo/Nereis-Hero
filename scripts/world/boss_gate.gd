extends StaticBody2D

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
    print("[NEREIS][WORLD] Boss gate opened")
    queue_free()

func _draw() -> void:
    draw_rect(Rect2(-21, -170, 42, 170), Color("#302833"))
    draw_line(Vector2(-12, -160), Vector2(-12, -12), Color("#796d67"), 4.0)
    draw_line(Vector2(0, -160), Vector2(0, -12), Color("#796d67"), 4.0)
    draw_line(Vector2(12, -160), Vector2(12, -12), Color("#796d67"), 4.0)
    draw_circle(Vector2(0, -128), 9.0, Color("#9e5961"))
    draw_string(ThemeDB.fallback_font, Vector2(-58, 24), "ASH GATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#796d67"))
