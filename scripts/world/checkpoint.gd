extends Area2D

var active := false
var animation_time := 0.0

func _process(delta: float) -> void:
    animation_time += delta
    queue_redraw()

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
    var pulse: float = (sin(animation_time * 4.0) + 1.0) * 0.5
    var glow := Color("#8e7777") if not active else Color("#d6c7b2")
    var radius: float = 11.0 + (6.0 * pulse if active else 2.0 * pulse)
    draw_line(Vector2(0, 0), Vector2(0, -92), glow, 5.0)
    draw_circle(Vector2(0, -98), radius + 8.0, Color(glow.r, glow.g, glow.b, 0.10))
    draw_circle(Vector2(0, -98), radius, glow)
    draw_string(ThemeDB.fallback_font, Vector2(-50, 30), NereisLocalization.translate_text("CHECKPOINT"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, glow)
