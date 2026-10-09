extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")
const DEATH_BURST_SCRIPT = preload("res://scripts/effects/death_burst.gd")

signal defeated
signal attack_telegraphed

const MOVE_SPEED := 105.0
const ATTACK_RANGE := 94.0

var health := 90
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
    attack_hitbox.setup(self, Vector2(76, 54), Vector2(-42, -22))

    var hurtbox := Area2D.new()
    hurtbox.set_script(HURTBOX_SCRIPT)
    add_child(hurtbox)
    hurtbox.setup(self, Vector2(40, 72), Vector2(0, -30))
    queue_redraw()

func _process(delta: float) -> void:
    delta *= WorldState.get_combat_enemy_time_scale()
    if WorldState.input_locked:
        return
    if WorldState.input_locked:
        return
    animation_time += delta
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    windup = maxf(0.0, windup - delta)
    stun_time = maxf(0.0, stun_time - delta)
    hit_flash = maxf(0.0, hit_flash - delta)
    queue_redraw()

func _physics_process(delta: float) -> void:
    delta *= WorldState.get_combat_enemy_time_scale()
    if WorldState.input_locked:
        return
    if WorldState.input_locked:
        return
    if stun_time > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 1050.0 * delta)
        move_and_slide()
        return

    var hero := get_node_or_null("../Hero") as Node2D
    if hero:
        var dx := hero.global_position.x - global_position.x
        if not is_zero_approx(dx):
            facing = sign(dx)

        if windup > 0.0:
            velocity.x = 0.0
            if windup <= 0.07 and not released:
                attack_hitbox.position.x = facing * 42.0
                attack_hitbox.activate(14, 0.13)
                released = true
        elif absf(dx) > ATTACK_RANGE:
            velocity.x = facing * MOVE_SPEED
        elif attack_cooldown <= 0.0:
            velocity.x = 0.0
            windup = 0.30
            attack_cooldown = 1.15
            released = false
            attack_telegraphed.emit()

    move_and_slide()

func receive_damage(amount: int, source: Node = null) -> void:
    health = max(0, health - amount)
    stun_time = 0.12
    hit_flash = 0.1

    var spark: Node2D = HIT_SPARK_SCRIPT.new()
    spark.global_position = global_position + Vector2(0, -30)
    get_parent().add_child(spark)

    if source and source is Node2D:
        velocity.x = sign(global_position.x - source.global_position.x) * 145.0

    if health <= 0:
        var burst: Node2D = DEATH_BURST_SCRIPT.new()
        burst.global_position = global_position + Vector2(0, -30)
        get_parent().add_child(burst)
        burst.call("setup", 13.0)
        defeated.emit()
        queue_free()

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func _draw() -> void:
    var cloth := Color("#45333b") if hit_flash <= 0.0 else Color("#c45d65")
    var skin := Color("#9c776f")
    var sway := sin(animation_time * 5.0) * 1.4
    draw_circle(Vector2(0, -48 + sway), 16.0, Color("#231c24"))
    draw_circle(Vector2(facing * 4.0, -44 + sway), 7.0, skin)
    draw_rect(Rect2(-20, -30 + sway, 40, 36), cloth)
    draw_line(Vector2(-12, -1 + sway), Vector2(-48, 12 + sway), cloth, 7.0)
    draw_line(Vector2(12, -1 + sway), Vector2(48, 12 + sway), cloth, 7.0)
    if windup > 0.0:
        draw_arc(Vector2(facing * 20.0, -22), 34.0, -0.85 if facing > 0 else 3.99, 0.85 if facing > 0 else 5.42, 14, Color("#d17b72"), 4.0)
    draw_string(ThemeDB.fallback_font, Vector2(-50, -72), NereisLocalization.translate_text("BANDIT"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#b7a09b"))
