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
    if not WorldState.boss_defeated:
        print("[NEREIS][WORLD] Exit blocked: Ashen Knight remains")
        return
    if not WorldState.first_choice_made:
        print("[NEREIS][WORLD] Exit blocked: first choice not resolved")
        return
    WorldState.slice_complete = true
    print("[NEREIS][WORLD] Vertical Slice 001 complete")
    reached.emit()
    get_viewport().set_input_as_handled()

func _draw() -> void:
    var c := Color("#d6c7b2") if WorldState.boss_defeated and WorldState.first_choice_made else Color("#4d454d")
    draw_rect(Rect2(-30, -120, 60, 120), Color("#241d25"))
    draw_line(Vector2(-20, -112), Vector2(-20, -8), c, 4.0)
    draw_line(Vector2(20, -112), Vector2(20, -8), c, 4.0)
    draw_circle(Vector2(0, -78), 12.0, c)
    draw_string(ThemeDB.fallback_font, Vector2(-45, 28), NereisLocalization.translate_text("EXIT"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, c)
