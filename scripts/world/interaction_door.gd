extends Area2D

signal interacted

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

@export var prompt_text: String = "E  Enter"
@export var enabled := true

var hero_nearby := false
var cooldown := 0.0

func _ready() -> void:
    collision_layer = 8
    collision_mask = 1
    monitoring = true
    set_meta("interaction_priority", 100)
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    queue_redraw()

func _process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    if hero_nearby and WorldState.input_locked:
        hero_nearby = false
    var available := enabled and not WorldState.input_locked and hero_nearby and cooldown <= 0.0
    INTERACTION_FOCUS_SCRIPT.sync(self, available, 100)
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
    if WorldState.input_locked or not hero_nearby or cooldown > 0.0 or not INTERACTION_FOCUS_SCRIPT.is_focused(self):
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        cooldown = 0.6
        interacted.emit()
        var viewport := get_viewport()
        if viewport:
            viewport.set_input_as_handled()

func _draw() -> void:
    if hero_nearby and not WorldState.input_locked and INTERACTION_FOCUS_SCRIPT.is_focused(self):
        draw_string(
            ThemeDB.fallback_font,
            Vector2(-54, 30),
            NereisLocalization.translate_text(prompt_text),
            HORIZONTAL_ALIGNMENT_LEFT,
            -1,
            16,
            Color("#d6c7b2")
        )
