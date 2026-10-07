extends CharacterBody2D

const SPEED := 260.0
const JUMP_VELOCITY := -520.0
const GRAVITY := 1400.0
const DODGE_SPEED := 620.0

var health := 100
var facing := 1.0
var attack_time := 0.0
var dodge_time := 0.0
var invulnerable := false

func _ready() -> void:
    queue_redraw()

func _physics_process(delta: float) -> void:
    if attack_time > 0.0:
        attack_time -= delta
    if dodge_time > 0.0:
        dodge_time -= delta
        velocity.x = facing * DODGE_SPEED
        move_and_slide()
        queue_redraw()
        return

    if not is_on_floor():
        velocity.y += GRAVITY * delta

    var direction := Input.get_axis("move_left", "move_right")
    if direction != 0.0:
        facing = sign(direction)
        velocity.x = move_toward(velocity.x, direction * SPEED, 1800.0 * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, 2200.0 * delta)

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    if Input.is_action_just_pressed("attack") and attack_time <= 0.0:
        attack_time = 0.28
        var hitbox := get_node_or_null("../Cultist")
        if hitbox and global_position.distance_to(hitbox.global_position) < 125.0:
            hitbox.take_damage(34)

    if Input.is_action_just_pressed("dodge") and dodge_time <= 0.0:
        dodge_time = 0.18
        invulnerable = true
        get_tree().create_timer(0.18).timeout.connect(_end_dodge)

    move_and_slide()
    position.y = min(position.y, 520.0)
    queue_redraw()

func _end_dodge() -> void:
    invulnerable = false

func take_damage(amount: int) -> void:
    if invulnerable:
        return
    health = max(0, health - amount)
    if health == 0:
        health = 100
        position = Vector2(320, 500)

func _draw() -> void:
    var body := Color("#c8b59b")
    var cloak := Color("#433a42")
    draw_circle(Vector2(0, -52), 18, body)
    draw_rect(Rect2(-18, -34, 36, 60), cloak)
    draw_line(Vector2(0, -8), Vector2(facing * 58, -22), Color("#b7a48c"), 7.0)
    if attack_time > 0.0:
        draw_arc(Vector2(facing * 26, -24), 64, -1.2 if facing > 0 else 1.2, 1.2 if facing > 0 else 5.2, 20, Color("#d9d0bf"), 5.0)
    draw_string(ThemeDB.fallback_font, Vector2(-40, -82), "HERO  %d" % health, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d6c7b2"))
