extends Area2D

signal reached

func _ready() -> void:
    collision_layer = 8
    collision_mask = 1
    monitoring = true
    body_entered.connect(_on_body_entered)
    queue_redraw()

func _on_body_entered(body: Node) -> void:
    if body.name != "Hero":
        return
    if not WorldState.route_memory_seen:
        print("[NEREIS][ROUTE] Route exit blocked: memory echo not resolved")
        return
    WorldState.mark_route_complete()
    print("[NEREIS][ROUTE] Route milestone complete: %s" % WorldState.selected_route)
    reached.emit()
    get_viewport().set_input_as_handled()

func _draw() -> void:
    var c := Color("#d6c7b2") if WorldState.route_complete else Color("#4d454d")
    draw_rect(Rect2(-30, -120, 60, 120), Color("#241d25"))
    draw_line(Vector2(-20, -112), Vector2(-20, -8), c, 4.0)
    draw_line(Vector2(20, -112), Vector2(20, -8), c, 4.0)
    draw_circle(Vector2(0, -78), 11.0, c)
    draw_string(ThemeDB.fallback_font, Vector2(-42, 28), "ROUTE END", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, c)
