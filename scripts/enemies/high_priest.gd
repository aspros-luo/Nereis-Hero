extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")
const DEATH_BURST_SCRIPT = preload("res://scripts/effects/death_burst.gd")

signal defeated
signal attack_telegraphed
signal phase_changed(phase: int)

const MAX_HEALTH := 320
var max_health := MAX_HEALTH
var boss_display_name := "HIGH PRIEST"
const PHASE_TWO_THRESHOLD := 160
const MOVE_SPEED := 72.0

var health := MAX_HEALTH
var phase := 1
var cooldown := 0.0
var windup := 0.0
var released := false
var facing := -1.0
var hit_flash := 0.0
var stun_time := 0.0
var attack_index := 0
var animation_time := 0.0
var attack_hitbox: Area2D

func _ready() -> void:
    _setup_combat()
    queue_redraw()

func _setup_combat() -> void:
    attack_hitbox = Area2D.new()
    attack_hitbox.set_script(HITBOX_SCRIPT)
    add_child(attack_hitbox)
    attack_hitbox.setup(self, Vector2(110, 70), Vector2(-60, -32))

    var hurtbox := Area2D.new()
    hurtbox.set_script(HURTBOX_SCRIPT)
    add_child(hurtbox)
    hurtbox.setup(self, Vector2(44, 86), Vector2(0, -42))

func _process(delta: float) -> void:
    delta *= WorldState.get_combat_enemy_time_scale()
    if WorldState.input_locked:
        return
    if WorldState.input_locked:
        return
    animation_time += delta
    cooldown = maxf(0.0, cooldown - delta)
    windup = maxf(0.0, windup - delta)
    hit_flash = maxf(0.0, hit_flash - delta)
    stun_time = maxf(0.0, stun_time - delta)
    queue_redraw()

func _physics_process(delta: float) -> void:
    delta *= WorldState.get_combat_enemy_time_scale()
    if WorldState.input_locked:
        return
    if WorldState.input_locked:
        return
    if stun_time > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 1100.0 * delta)
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
                var special := phase == 2 and attack_index % 3 == 0
                attack_hitbox.position.x = facing * (60.0 if not special else 82.0)
                attack_hitbox.scale = Vector2(1.65, 1.15) if special else Vector2.ONE
                attack_hitbox.activate(22 if phase == 1 else (46 if special else 34), 0.16 if special else 0.14)
                released = true
        else:
            if absf(dx) > (135.0 if phase == 1 else 155.0):
                velocity.x = facing * (MOVE_SPEED + 26.0 * (phase - 1))
            else:
                velocity.x = 0.0
                if cooldown <= 0.0:
                    attack_index += 1
                    windup = 0.34 if phase == 1 else 0.27
                    cooldown = 1.35 if phase == 1 else 0.92
                    released = false
                    attack_telegraphed.emit()

    move_and_slide()

func receive_damage(amount: int, source: Node = null) -> void:
    health = max(0, health - amount)
    hit_flash = 0.10
    stun_time = 0.08

    var spark: Node2D = HIT_SPARK_SCRIPT.new()
    spark.global_position = global_position + Vector2(0, -40)
    get_parent().add_child(spark)

    if health <= PHASE_TWO_THRESHOLD and phase == 1:
        phase = 2
        phase_changed.emit(2)

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
    var glow := Color("#c75862") if phase == 2 else Color("#9a8275")
    var cloth := Color("#332932") if phase == 1 else Color("#4b2932")
    var sway := sin(animation_time * 2.0) * 1.2

    draw_circle(Vector2(0, -70 + sway), 23.0, Color("#211b25"))
    draw_circle(Vector2(facing * 4.0, -66 + sway), 8.0, glow)
    draw_rect(Rect2(-27, -46 + sway, 54, 56), cloth)
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(-32, 8 + sway),
            Vector2(32, 8 + sway),
            Vector2(48, 15 + sway),
            Vector2(-48, 15 + sway)
        ]),
        Color("#241d27")
    )
    draw_line(Vector2(0, -35 + sway), Vector2(facing * 62.0, 14 + sway), glow, 7.0)
    draw_circle(Vector2(0, -96 + sway), 34.0, Color(glow, 0.12))
    draw_arc(Vector2(0, -70), 28.0, PI, TAU, 22, glow, 3.0)

    if phase == 2:
        for i in range(5):
            var angle := -2.5 + float(i) * 1.25
            var root := Vector2(cos(angle) * 24.0, -32.0 + sin(angle) * 18.0)
            var tip := root + Vector2(cos(angle) * 75.0, sin(angle) * 75.0 - 30.0)
            draw_line(root, tip, Color("#6f3948"), 9.0)
            draw_circle(tip, 4.0, Color("#c36a72"))
        draw_circle(Vector2(0, -100), 43.0, Color("#742f3b", 0.10))
        for i in range(3):
            draw_circle(Vector2(-12.0 + float(i) * 12.0, -102), 3.5, Color("#cf7f78"))

    var label := "HIGH PRIEST  //  PHASE II" if phase == 2 else "HIGH PRIEST"
    draw_string(ThemeDB.fallback_font, Vector2(-72, -112), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#d6c7b2"))
