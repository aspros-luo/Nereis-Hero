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
    consumed = clue_id in WorldState.world_clues_seen
    queue_redraw()

func _physics_process(delta: float) -> void:
    cooldown = max(0.0, cooldown - delta)
    if consumed:
        return

    var hero: Node2D = get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= 120.0

    if hero_nearby and Input.is_key_pressed(KEY_E) and cooldown <= 0.0:
        cooldown = 0.5
        consumed = WorldState.record_world_clue(clue_id, humanity_delta)
        examined.emit()
        print("[NEREIS][STORY] World clue examined id=%s" % clue_id)
        queue_redraw()

func _draw() -> void:
    var glow := Color("#d6c7b2") if not consumed else Color("#4d454d")
    draw_rect(Rect2(-14, -18, 28, 18), Color("#332c34"))
    draw_line(Vector2(-10, 0), Vector2(10, 0), glow, 3.0)
    if hero_nearby and not consumed:
        draw_string(ThemeDB.fallback_font, Vector2(-45, 30), "E  Examine", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, glow)
