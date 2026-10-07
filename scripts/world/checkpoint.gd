extends Area2D

var active := false

func _ready() -> void:
    active = WorldState.checkpoint_active
    collision_layer = 4
    collision_mask = 1
    monitoring = true
    body_entered.connect(_on_body_entered)
    queue_redraw()

func _on_body_entered(body: Node) -> void:
    if active or body.name != "Hero":
        return
    active = true
    WorldState.set_checkpoint(global_position + Vector2(0, 0))
    print("[NEREIS][WORLD] Hero reached checkpoint")
    queue_redraw()

func _draw() -> void:
    var glow := Color("#8e7777") if not active else Color("#d6c7b2")
    draw_line(Vector2(0, 0), Vector2(0, -92), glow, 5.0)
    draw_circle(Vector2(0, -98), 11.0, glow)
    draw_string(ThemeDB.fallback_font, Vector2(-50, 30), "CHECKPOINT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, glow)
