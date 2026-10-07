extends Node2D

signal interacted

var interaction_cooldown := 0.0
var hero_nearby := false

func _ready() -> void:
    _log("BOOT", "Old Hunter initialized")
    queue_redraw()

func _physics_process(delta: float) -> void:
    interaction_cooldown = max(0.0, interaction_cooldown - delta)
    var hero: Node2D = get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= 115.0

    if hero_nearby and (Input.is_key_pressed(KEY_E) or Input.is_action_just_pressed("ui_accept")) and interaction_cooldown <= 0.0:
        interaction_cooldown = 0.5
        interacted.emit()
        _log("NPC", "Old Hunter interaction requested")

    queue_redraw()

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
    draw_circle(Vector2(0, -48), 17, Color("#8d7566"))
    draw_rect(Rect2(-19, -30, 38, 30), Color("#4b4640"))
    draw_line(Vector2(-12, -4), Vector2(30, 8), Color("#74695f"), 5.0)
    draw_string(ThemeDB.fallback_font, Vector2(-58, -76), "OLD HUNTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#b7a09b"))
    if hero_nearby:
        draw_string(ThemeDB.fallback_font, Vector2(-72, 38), "E  Speak", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d6c7b2"))
