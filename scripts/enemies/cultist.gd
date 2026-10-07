extends CharacterBody2D

var health := 100
var attack_cooldown := 0.0
var hit_flash := 0.0

func _ready() -> void:
    queue_redraw()

func _physics_process(delta: float) -> void:
    attack_cooldown = max(0.0, attack_cooldown - delta)
    hit_flash = max(0.0, hit_flash - delta)

    var hero := get_node_or_null("../Hero")

    if hero:
        var distance := global_position.distance_to(hero.global_position)
        if distance > 90.0:
            velocity.x = sign(hero.global_position.x - global_position.x) * 95.0
        else:
            velocity.x = 0.0
            if attack_cooldown <= 0.0:
                hero.take_damage(12)
                attack_cooldown = 1.1

    move_and_slide()
    queue_redraw()

func take_damage(amount: int) -> void:
    health -= amount
    hit_flash = 0.12
    if health <= 0:
        queue_free()

func _draw() -> void:
    var c := Color("#b44b52") if hit_flash > 0.0 else Color("#55404a")
    draw_circle(Vector2(0, -45), 17, c)
    draw_rect(Rect2(-20, -28, 40, 52), c)
    draw_line(Vector2(-14, -4), Vector2(-46, 18), c, 8.0)
    draw_line(Vector2(14, -4), Vector2(46, 18), c, 8.0)
    draw_string(ThemeDB.fallback_font, Vector2(-48, -72), "CULTIST  %d" % max(0, health), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#b7a09b"))
