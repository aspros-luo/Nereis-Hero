extends Node2D

signal interacted

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

@export var poi_id: String = ""
@export var display_name: String = ""
@export_multiline var dialogue: String = ""

var cooldown := 0.0
var hero_nearby := false

func _ready() -> void:
    queue_redraw()

func _process(delta: float) -> void:
    cooldown = max(0.0, cooldown - delta)
    var hero: Node2D = get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= 140.0
    var available := not WorldState.input_locked and hero_nearby and cooldown <= 0.0 and not display_name.is_empty() and not dialogue.is_empty()
    INTERACTION_FOCUS_SCRIPT.sync(self, available)
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
        print("[NEREIS][VILLAGE] POI interacted id=%s" % poi_id)
        get_viewport().set_input_as_handled()

func _draw() -> void:
    draw_circle(Vector2(0, -70), 10.0, Color("#8e7777"))
    if can_interact():
        draw_string(ThemeDB.fallback_font, Vector2(-54, 20), "E  Examine", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d6c7b2"))
