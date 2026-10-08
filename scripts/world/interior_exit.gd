extends Area2D

signal reached

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

var hero_nearby := false
var cooldown := 0.0

func _ready() -> void:
    collision_layer = 8
    collision_mask = 1
    monitoring = true
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    queue_redraw()

func _process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    var available := not WorldState.input_locked and hero_nearby and cooldown <= 0.0
    INTERACTION_FOCUS_SCRIPT.sync(self, available)
    queue_redraw()

func _on_body_entered(body: Node) -> void:
    if body.name == "Hero":
        hero_nearby = true
        queue_redraw()

func _on_body_exited(body: Node) -> void:
    if body.name == "Hero":
        hero_nearby = false
        queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if WorldState.input_locked or not hero_nearby or cooldown > 0.0:
        return
    if not INTERACTION_FOCUS_SCRIPT.is_focused(self):
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        cooldown = 0.6
        reached.emit()
        get_viewport().set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(-30, -120, 60, 120), Color("#241d25"))
    if hero_nearby and not WorldState.input_locked and INTERACTION_FOCUS_SCRIPT.is_focused(self):
        draw_string(ThemeDB.fallback_font, Vector2(-48, 24), NereisLocalization.translate_text("E  EXIT"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#d6c7b2"))
