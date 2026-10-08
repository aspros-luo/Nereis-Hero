extends Node2D

signal examined

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

@export var clue_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var humanity_delta: int = 0

var consumed := false
var hero_nearby := false
var cooldown := 0.0

func _ready() -> void:
    consumed = clue_id in WorldState.world_clues_seen
    queue_redraw()

func _process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    if consumed:
        hero_nearby = false
        INTERACTION_FOCUS_SCRIPT.sync(self, false)
        queue_redraw()
        return

    var hero: Node2D = get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= 120.0
    var available := not WorldState.input_locked and hero_nearby and cooldown <= 0.0 and not consumed
    INTERACTION_FOCUS_SCRIPT.sync(self, available)
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if WorldState.input_locked or consumed or not hero_nearby or cooldown > 0.0 or not INTERACTION_FOCUS_SCRIPT.is_focused(self):
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        cooldown = 0.5
        consumed = WorldState.record_world_clue(clue_id, humanity_delta)
        if consumed and clue_id == "graveyard_hero_gravestone":
            WorldState.record_hidden_artifact_source(clue_id)
        examined.emit()
        print("[NEREIS][STORY] World clue examined id=%s" % clue_id)
        get_viewport().set_input_as_handled()

func _draw() -> void:
    var glow := Color("#d6c7b2") if not consumed else Color("#4d454d")
    draw_rect(Rect2(-14, -18, 28, 18), Color("#332c34"))
    draw_line(Vector2(-10, 0), Vector2(10, 0), glow, 3.0)
    if hero_nearby and not consumed:
        draw_string(ThemeDB.fallback_font, Vector2(-45, 30), NereisLocalization.translate_text("E  Examine"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, glow)
