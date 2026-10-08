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
    var available := (
        not WorldState.input_locked
        and hero_nearby
        and cooldown <= 0.0
        and WorldState.boss_defeated
        and WorldState.first_choice_made
    )
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

    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        if not INTERACTION_FOCUS_SCRIPT.is_focused(self):
            return
        cooldown = 0.7
        WorldState.slice_complete = true
        print("[NEREIS][WORLD] Vertical Slice 001 complete")
        reached.emit()
        get_viewport().set_input_as_handled()

func _draw() -> void:
    var ready := WorldState.boss_defeated and WorldState.first_choice_made
    var c := Color("#d6c7b2") if ready else Color("#4d454d")
    draw_rect(Rect2(-30, -120, 60, 120), Color("#241d25"))
    draw_line(Vector2(-20, -112), Vector2(-20, -8), c, 4.0)
    draw_line(Vector2(20, -112), Vector2(20, -8), c, 4.0)
    draw_circle(Vector2(0, -78), 12.0, c)
    if hero_nearby and ready and not WorldState.input_locked and INTERACTION_FOCUS_SCRIPT.is_focused(self):
        draw_string(ThemeDB.fallback_font, Vector2(-42, 28), NereisLocalization.translate_text("E  EXIT"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, c)
