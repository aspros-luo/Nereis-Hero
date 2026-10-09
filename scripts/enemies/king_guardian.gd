extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")
const DEATH_BURST_SCRIPT = preload("res://scripts/effects/death_burst.gd")

signal defeated
signal attack_telegraphed
signal phase_changed(phase: int)

const MAX_HEALTH := 360
var max_health := MAX_HEALTH
var boss_display_name := "THE KING"
const PHASE_TWO_THRESHOLD := 180

var health := MAX_HEALTH
var phase := 1
var cooldown := 0.0
var windup := 0.0
var released := false
var facing := -1.0
var hit_flash := 0.0
var stun_time := 0.0
var animation_time := 0.0

func _ready() -> void:
    add_to_group("combat_enemies")
    var hitbox := Area2D.new()
    hitbox.set_script(HITBOX_SCRIPT)
    add_child(hitbox)
    hitbox.setup(self, Vector2(128, 76), Vector2(-70, -36))
    set_meta("attack_hitbox", hitbox)

    var hurtbox := Area2D.new()
    hurtbox.set_script(HURTBOX_SCRIPT)
    add_child(hurtbox)
    hurtbox.setup(self, Vector2(50, 96), Vector2(0, -46))
    queue_redraw()

func _process(delta: float) -> void:
    delta *= WorldState.get_combat_enemy_time_scale()
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
    if stun_time > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
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
                var hitbox: Area2D = get_meta("attack_hitbox")
                var heavy := phase == 2 and int(animation_time * 10.0) % 3 == 0
                hitbox.position.x = facing * (70.0 if not heavy else 100.0)
                hitbox.scale = Vector2(1.0, 1.0)
                hitbox.activate(28 if phase == 1 else (48 if heavy else 40), 0.17 if heavy else 0.15)
                if heavy:
                    velocity.x = facing * 260.0
                released = true
        elif absf(dx) > (150.0 if phase == 1 else 170.0):
            velocity.x = facing * (54.0 if phase == 1 else 84.0)
        elif cooldown <= 0.0:
            velocity.x = 0.0
            windup = 0.48 if phase == 1 else 0.34
            cooldown = 1.7 if phase == 1 else 1.08
            released = false
            attack_telegraphed.emit()

    _move_and_slide_scaled()

func receive_damage(amount: int, _source: Node = null) -> void:
    health = max(0, health - amount)
    hit_flash = 0.12
    stun_time = 0.10

    var spark: Node2D = HIT_SPARK_SCRIPT.new()
    spark.global_position = global_position + Vector2(0, -42)
    get_parent().add_child(spark)

    if health <= PHASE_TWO_THRESHOLD and phase == 1:
        phase = 2
        phase_changed.emit(2)

    if health <= 0:
        var burst: Node2D = DEATH_BURST_SCRIPT.new()
        burst.global_position = global_position + Vector2(0, -44)
        get_parent().add_child(burst)
        burst.call("setup", 24.0)
        defeated.emit()
        queue_free()

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func _draw() -> void:
    var metal := Color("#b4a49b") if hit_flash <= 0.0 else Color("#e3cdc1")
    var cloth := Color("#29242d") if phase == 1 else Color("#442f37")
    var pulse := 1.0 + sin(animation_time * 1.5) * 0.04
    draw_circle(Vector2(0, -72), 24.0 * pulse, Color("#211c24"))
    draw_rect(Rect2(-31, -48, 62, 60), cloth)
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(-40, 10),
            Vector2(40, 10),
            Vector2(54, 18),
            Vector2(-54, 18)
        ]),
        Color("#201b23")
    )
    draw_line(Vector2(facing * 24, -28), Vector2(facing * 86, 18), metal, 9.0)
    draw_arc(Vector2(0, -72), 32.0, PI, TAU, 22, metal, 4.0)
    draw_circle(Vector2(0, -101), 5.0, Color("#cfaa66"))

    if phase == 2:
        for i in range(6):
            var x := -30.0 + float(i) * 12.0
            draw_line(Vector2(x, -108), Vector2(x + sin(animation_time + i) * 6.0, -155.0), Color("#6e3d48"), 7.0)
        draw_circle(Vector2(0, -70), 58.0, Color("#7a3d49", 0.08))
        draw_circle(Vector2(facing * 4.0, -105), 4.0, Color("#c87876"))

    draw_string(ThemeDB.fallback_font, Vector2(-64, -114), "THE KING  //  PHASE %d" % phase, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#d6c7b2"))


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
