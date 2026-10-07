extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")
const DEATH_BURST_SCRIPT = preload("res://scripts/effects/death_burst.gd")

signal defeated
signal attack_telegraphed

var health := 170
var attack_cooldown := 0.0
var windup := 0.0
var released := false
var facing := -1.0
var stun_time := 0.0
var hit_flash := 0.0
var animation_time := 0.0
var attack_hitbox: Area2D

func _ready() -> void:
    attack_hitbox = Area2D.new()
    attack_hitbox.set_script(HITBOX_SCRIPT)
    add_child(attack_hitbox)
    attack_hitbox.setup(self, Vector2(92, 62), Vector2(-46, -28))

    var hurtbox := Area2D.new()
    hurtbox.set_script(HURTBOX_SCRIPT)
    add_child(hurtbox)
    hurtbox.setup(self, Vector2(48, 92), Vector2(0, -40))
    queue_redraw()

func _process(delta: float) -> void:
    animation_time += delta
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    windup = maxf(0.0, windup - delta)
    stun_time = maxf(0.0, stun_time - delta)
    hit_flash = maxf(0.0, hit_flash - delta)
    queue_redraw()

func _physics_process(delta: float) -> void:
    if stun_time > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
        move_and_slide()
        return

    var hero := get_node_or_null("../Hero") as Node2D
    if hero:
        var dx := hero.global_position.x - global_position.x
        if not is_zero_approx(dx):
            facing = sign(dx)

        if windup > 0.0:
            velocity.x = 0.0
            if windup <= 0.08 and not released:
                attack_hitbox.position.x = facing * 48.0
                attack_hitbox.activate(22, 0.14)
                released = true
        elif absf(dx) > 132.0:
            velocity.x = facing * 56.0
        elif attack_cooldown <= 0.0:
            windup = 0.52
            attack_cooldown = 1.8
            released = false
            attack_telegraphed.emit()

    move_and_slide()

func receive_damage(amount: int, source: Node = null) -> void:
    health = max(0, health - amount)
    stun_time = 0.15
    hit_flash = 0.1

    var spark: Node2D = HIT_SPARK_SCRIPT.new()
    spark.global_position = global_position + Vector2(0, -40)
    get_parent().add_child(spark)

    if source and source is Node2D:
        velocity.x = sign(global_position.x - source.global_position.x) * 100.0

    if health <= 0:
        var burst: Node2D = DEATH_BURST_SCRIPT.new()
        burst.global_position = global_position + Vector2(0, -40)
        get_parent().add_child(burst)
        burst.call("setup", 20.0)
        defeated.emit()
        queue_free()

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func _draw() -> void:
    var tissue := Color("#6c5a62") if hit_flash <= 0.0 else Color("#d77d78")
    var bone := Color("#b8a69c")
    var shadow := Color("#221c25")
    var pulse := sin(animation_time * 2.1) * 2.0

    draw_circle(Vector2(0, -56 + pulse), 21.0, shadow)
    draw_circle(Vector2(facing * 6, -52 + pulse), 7.0, tissue)
    draw_rect(Rect2(-24, -36 + pulse, 48, 46), tissue)
    draw_line(Vector2(-12, 0 + pulse), Vector2(-55, 14 + pulse), bone, 7.0)
    draw_line(Vector2(12, 0 + pulse), Vector2(50, 12 + pulse), bone, 7.0)
    draw_circle(Vector2(0, -18 + pulse), 9.0, Color("#8f5c6b", 0.34))

    if windup > 0.0:
        draw_arc(Vector2(facing * 24, -26), 42.0, -0.85 if facing > 0 else 3.99, 0.85 if facing > 0 else 5.42, 16, Color("#d56b6a"), 4.0)

    draw_string(ThemeDB.fallback_font, Vector2(-62, -86), "RESEARCH HUSK", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#b7a09b"))
