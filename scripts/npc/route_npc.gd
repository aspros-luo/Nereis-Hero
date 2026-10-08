extends Node2D

signal interacted

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

@export var npc_id: String = ""
@export var display_name: String = ""
@export_multiline var dialogue: String = ""

var cooldown := 0.0
var hero_nearby := false

func _ready() -> void:
    set_meta("interaction_priority", 60)
    print("[NEREIS][NPC] %s initialized id=%s" % [display_name, npc_id])
    queue_redraw()

func _process(delta: float) -> void:
    cooldown = max(0.0, cooldown - delta)
    var hero: Node2D = get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= 100.0
    var available := not WorldState.input_locked and hero_nearby and cooldown <= 0.0 and not display_name.is_empty() and not dialogue.is_empty()
    INTERACTION_FOCUS_SCRIPT.sync(self, available, 60)
    queue_redraw()

func can_interact() -> bool:
    return (
        not WorldState.input_locked
        and hero_nearby
        and cooldown <= 0.0
        and not display_name.is_empty()
        and not dialogue.is_empty()
        and INTERACTION_FOCUS_SCRIPT.is_focused(self)
    )

func _unhandled_input(event: InputEvent) -> void:
    if not can_interact():
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        cooldown = 0.5
        interacted.emit()
        print("[NEREIS][NPC] Interaction id=%s" % npc_id)
        var viewport := get_viewport()
        if viewport:
            viewport.set_input_as_handled()

func _draw() -> void:
    draw_circle(Vector2(0, -50), 17.0, Color("#8d7566"))
    draw_rect(Rect2(-18, -32, 36, 32), Color("#49424a"))
    draw_string(ThemeDB.fallback_font, Vector2(-58, -76), NereisLocalization.translate_text(display_name), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#b7a09b"))
    if can_interact():
        draw_string(ThemeDB.fallback_font, Vector2(-50, 28), NereisLocalization.translate_text("E  Speak"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d6c7b2"))
