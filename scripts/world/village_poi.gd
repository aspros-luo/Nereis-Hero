extends Node2D

signal interacted

@export var poi_id: String = ""
@export var display_name: String = ""
@export_multiline var dialogue: String = ""

var cooldown := 0.0
var hero_nearby := false

func _ready() -> void:
    queue_redraw()

func _physics_process(delta: float) -> void:
    cooldown = max(0.0, cooldown - delta)
    var hero := get_node_or_null("../Hero")
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= 140.0

    if hero_nearby and Input.is_key_pressed(KEY_E) and cooldown <= 0.0:
        cooldown = 0.5
        interacted.emit()
        print("[NEREIS][VILLAGE] POI interacted id=%s" % poi_id)

    queue_redraw()

func _draw() -> void:
    draw_circle(Vector2(0, -70), 10.0, Color("#8e7777"))
    if hero_nearby:
        draw_string(ThemeDB.fallback_font, Vector2(-54, 20), "E  Examine", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d6c7b2"))
