extends Node2D

signal examined

@export var clue_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var humanity_delta: int = 0

var consumed := false
var hero_nearby := false
var cooldown := 0.0

func _ready() -> void:
    consumed = clue_id in WorldState.interior_clues_seen
    print("[NEREIS][STORY] Interior clue initialized id=%s consumed=%s" % [clue_id, consumed])
    queue_redraw()

func _physics_process(delta: float) -> void:
    cooldown = max(0.0, cooldown - delta)
    if consumed:
        return

    var hero: Node2D = get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= 120.0

    if hero_nearby and Input.is_key_pressed(KEY_E) and cooldown <= 0.0:
        cooldown = 0.5
        consumed = true
        WorldState.record_interior_clue(clue_id)
        examined.emit()
        print("[NEREIS][STORY] Interior clue examined id=%s" % clue_id)
        queue_redraw()

func _draw() -> void:
    var glow := Color("#d6c7b2") if not consumed else Color("#4d454d")
    draw_circle(Vector2.ZERO, 14.0, Color("#28222a"))
    draw_circle(Vector2.ZERO, 6.0, glow)
    if hero_nearby and not consumed:
        draw_string(ThemeDB.fallback_font, Vector2(-45, 34), "E  Examine", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, glow)
