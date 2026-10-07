extends Area2D

signal reached

func _ready() -> void:
    collision_layer = 8
    collision_mask = 1
    monitoring = true
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if body.name != "Hero":
        return
    reached.emit()
    get_viewport().set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(-30, -120, 60, 120), Color("#241d25"))
    draw_string(ThemeDB.fallback_font, Vector2(-48, 24), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#d6c7b2"))
