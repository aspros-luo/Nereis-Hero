extends Node2D

signal interacted

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

var interaction_cooldown := 0.0
var hero_nearby := false

func _ready() -> void:
    _log("BOOT", "Old Hunter initialized")
    queue_redraw()

func _process(delta: float) -> void:
    interaction_cooldown = max(0.0, interaction_cooldown - delta)
    var hero: Node2D = get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= 115.0
    var available := not WorldState.input_locked and hero_nearby and interaction_cooldown <= 0.0
    INTERACTION_FOCUS_SCRIPT.sync(self, available)
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if WorldState.input_locked or not hero_nearby or interaction_cooldown > 0.0:
        return
    if not INTERACTION_FOCUS_SCRIPT.is_focused(self):
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        interaction_cooldown = 0.5
        interacted.emit()
        _log("NPC", "Old Hunter interaction requested")
        get_viewport().set_input_as_handled()

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
    draw_circle(Vector2(0, -48), 17, Color("#8d7566"))
    draw_rect(Rect2(-19, -30, 38, 30), Color("#4b4640"))
    draw_line(Vector2(-12, -4), Vector2(30, 8), Color("#74695f"), 5.0)
    draw_string(ThemeDB.fallback_font, Vector2(-58, -76), NereisLocalization.translate_text("OLD HUNTER"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#b7a09b"))
    if hero_nearby and not WorldState.input_locked and INTERACTION_FOCUS_SCRIPT.is_focused(self):
        draw_string(ThemeDB.fallback_font, Vector2(-72, 38), NereisLocalization.translate_text("E  Speak"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d6c7b2"))
