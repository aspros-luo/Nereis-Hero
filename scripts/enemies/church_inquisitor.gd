extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")
const DEATH_BURST_SCRIPT = preload("res://scripts/effects/death_burst.gd")

signal defeated
signal attack_telegraphed

const MOVE_SPEED := 62.0
const ATTACK_RANGE := 128.0

var health := 145
var attack_cooldown := 0.0
var windup := 0.0
var released := false
var facing := -1.0
var stun_time := 0.0
var hit_flash := 0.0
var animation_time := 0.0
var attack_hitbox: Area2D

func _ready() -> void:
    add_to_group("combat_enemies")
    attack_hitbox = Area2D.new()
    attack_hitbox.set_script(HITBOX_SCRIPT)
    add_child(attack_hitbox)
    attack_hitbox.setup(self, Vector2(102, 62), Vector2(-56, -27))

    var hurtbox := Area2D.new()
    hurtbox.set_script(HURTBOX_SCRIPT)
    add_child(hurtbox)
    hurtbox.setup(self, Vector2(44, 84), Vector2(0, -38))
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
        velocity.x = move_toward(velocity.x, 0.0, 920.0 * delta)
        _move_and_slide_scaled()
        return

    var hero := get_node_or_null("../Hero") as Node2D
    if hero:
        var dx := hero.global_position.x - global_position.x
        if not is_zero_approx(dx):
            facing = sign(dx)

        if windup > 0.0:
            velocity.x = 0.0
            if windup <= 0.08 and not released:
                attack_hitbox.position.x = facing * 56.0
                attack_hitbox.activate(20, 0.14)
                released = true
        elif absf(dx) > ATTACK_RANGE:
            velocity.x = facing * MOVE_SPEED
        elif attack_cooldown <= 0.0:
            velocity.x = 0.0
            windup = 0.45
            attack_cooldown = 1.55
            released = false
            attack_telegraphed.emit()

    _move_and_slide_scaled()

func receive_damage(amount: int, source: Node = null) -> void:
    health = max(0, health - amount)
    stun_time = 0.14
    hit_flash = 0.12

    var spark: Node2D = HIT_SPARK_SCRIPT.new()
    spark.global_position = global_position + Vector2(0, -38)
    get_parent().add_child(spark)

    if source and source is Node2D:
        velocity.x = sign(global_position.x - source.global_position.x) * 115.0

    if health <= 0:
        var burst: Node2D = DEATH_BURST_SCRIPT.new()
        burst.global_position = global_position + Vector2(0, -38)
        get_parent().add_child(burst)
        burst.call("setup", 17.0)
        defeated.emit()
        queue_free()

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func _draw() -> void:
    var robe := Color("#514653") if hit_flash <= 0.0 else Color("#c55d67")
    var metal := Color("#ad9b91")
    var sway := sin(animation_time * 2.5) * 1.2
    draw_circle(Vector2(0, -56 + sway), 19.0, Color("#1f1a22"))
    draw_circle(Vector2(facing * 5.0, -52 + sway), 6.0, Color("#8e565c"))
    draw_rect(Rect2(-22, -34 + sway, 44, 44), robe)
    draw_line(Vector2(0, -2 + sway), Vector2(facing * 62.0, 14 + sway), metal, 8.0)
    draw_arc(Vector2(facing * 27.0, -26), 38.0, -0.85 if facing > 0 else 3.99, 0.85 if facing > 0 else 5.42, 14, Color("#9d5860"), 3.0)
    draw_string(ThemeDB.fallback_font, Vector2(-62, -80), "INQUISITOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#b7a09b"))


func _move_and_slide_scaled() -> void:
    # CharacterBody2D.move_and_slide() uses engine physics delta; scale velocity during the actual move.
    # CharacterBody2D.move_and_slide() 使用引擎物理步长，因此只在位移调用期间缩放速度。
    var enemy_time_scale: float = WorldState.get_combat_enemy_time_scale()
    if enemy_time_scale >= 0.999:
        move_and_slide()
        return
    velocity *= enemy_time_scale
    move_and_slide()
    velocity /= enemy_time_scale
