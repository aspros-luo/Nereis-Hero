extends Node2D

signal interacted

@export var npc_id: String = ""
@export var display_name: String = ""
@export_multiline var dialogue: String = ""

var cooldown := 0.0
var hero_nearby := false

func _ready() -> void:
    print("[NEREIS][NPC] %s initialized id=%s" % [display_name, npc_id])
    queue_redraw()

func _physics_process(delta: float) -> void:
    cooldown = max(0.0, cooldown - delta)
    var hero: Node2D = get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= 120.0

    if hero_nearby and Input.is_key_pressed(KEY_E) and cooldown <= 0.0:
        cooldown = 0.5
        interacted.emit()
        print("[NEREIS][NPC] Interaction id=%s" % npc_id)

    queue_redraw()

func _draw() -> void:
    draw_circle(Vector2(0, -50), 17.0, Color("#8d7566"))
    draw_rect(Rect2(-18, -32, 36, 32), Color("#49424a"))
    draw_string(ThemeDB.fallback_font, Vector2(-58, -76), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#b7a09b"))
    if hero_nearby:
        draw_string(ThemeDB.fallback_font, Vector2(-50, 28), "E  Speak", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d6c7b2"))
