extends Node2D

signal interacted

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

@export var echo_id: String = ""
@export var display_name: String = ""
@export_multiline var dialogue: String = ""
@export var humanity_delta: int = 0

var cooldown := 0.0
var hero_nearby := false
var consumed := false

func _ready() -> void:
    consumed = WorldState.route_memory_seen and WorldState.route_memory_id == echo_id
    set_meta("interaction_priority", 30)
    print("[NEREIS][STORY] Route echo initialized id=%s consumed=%s" % [echo_id, consumed])
    queue_redraw()

func _process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    if consumed:
        hero_nearby = false
        INTERACTION_FOCUS_SCRIPT.sync(self, false, 30)
        queue_redraw()
        return

    var hero: Node2D = get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= 120.0
    var available := not WorldState.input_locked and not consumed and hero_nearby and cooldown <= 0.0
    INTERACTION_FOCUS_SCRIPT.sync(self, available, 30)
    queue_redraw()

func can_interact() -> bool:
    return not WorldState.input_locked and not consumed and hero_nearby and cooldown <= 0.0 and INTERACTION_FOCUS_SCRIPT.is_focused(self)

func _unhandled_input(event: InputEvent) -> void:
    if not can_interact():
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        cooldown = 0.5
        consumed = true
        interacted.emit()
        WorldState.record_hidden_artifact_source("route_echo_" + echo_id)
        print("[NEREIS][STORY] Route echo interacted id=%s" % echo_id)
        var viewport := get_viewport()
        if viewport:
            viewport.set_input_as_handled()
        queue_redraw()

func _draw() -> void:
    var glow := Color("#9e5961") if not consumed else Color("#4d454d")
    draw_circle(Vector2(0, -22), 14.0, Color("#302833"))
    draw_circle(Vector2(0, -22), 6.0, glow)
    draw_line(Vector2(0, -8), Vector2(0, 20), glow, 3.0)
    if can_interact():
        draw_string(ThemeDB.fallback_font, Vector2(-45, 44), "E  Examine", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d6c7b2"))
