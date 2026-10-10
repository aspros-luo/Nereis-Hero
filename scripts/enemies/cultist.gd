extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")
const DEATH_BURST_SCRIPT = preload("res://scripts/effects/death_burst.gd")

const MOVE_SPEED := 82.0
const ATTACK_RANGE := 108.0
const ATTACK_COOLDOWN := 1.15
const ATTACK_WINDUP := 0.34

var health := 100
var attack_cooldown := 0.0
var windup := 0.0
var attack_released := false
var hit_flash := 0.0
var stun_time := 0.0
var facing := 1.0
var attack_hitbox: Area2D
var animation_time := 0.0
signal defeated
signal attack_telegraphed

func _ready() -> void:
    add_to_group("combat_enemies")
    _setup_combat_components()
    _log("BOOT", "Cultist initialized")
    queue_redraw()

func _setup_combat_components() -> void:
    attack_hitbox = Area2D.new()
    attack_hitbox.name = "AttackHitbox"
    attack_hitbox.set_script(HITBOX_SCRIPT)
    add_child(attack_hitbox)
    attack_hitbox.setup(self, Vector2(74, 54), Vector2(0, -20))

    var hurtbox := Area2D.new()
    hurtbox.name = "Hurtbox"
    hurtbox.set_script(HURTBOX_SCRIPT)
    add_child(hurtbox)
    hurtbox.setup(self, Vector2(38, 74), Vector2(0, -30))

func _process(delta: float) -> void:
    delta *= WorldState.get_combat_enemy_time_scale()
    if WorldState.input_locked:
        return
    animation_time += delta
    queue_redraw()

func _physics_process(delta: float) -> void:
    delta *= WorldState.get_combat_enemy_time_scale()
    if WorldState.input_locked:
        return
    attack_cooldown = max(0.0, attack_cooldown - delta)
    windup = max(0.0, windup - delta)
    hit_flash = max(0.0, hit_flash - delta)
    stun_time = max(0.0, stun_time - delta)

    if stun_time > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
        _move_and_slide_scaled()
        queue_redraw()
        return

    var hero: Node2D = get_node_or_null("../Hero") as Node2D

    if hero:
        var dx: float = hero.global_position.x - global_position.x
        if dx != 0.0:
            facing = sign(dx)

        if windup > 0.0:
            velocity.x = 0.0
            if windup <= 0.06 and not attack_released:
                attack_hitbox.position.x = facing * 40.0
                attack_hitbox.activate(12, 0.12)
                attack_released = true
                _log("COMBAT", "Cultist attack released")
        else:
            var distance: float = absf(dx)
            if distance > ATTACK_RANGE:
                velocity.x = facing * MOVE_SPEED
            else:
                velocity.x = 0.0
                if attack_cooldown <= 0.0:
                    windup = ATTACK_WINDUP
                    attack_cooldown = ATTACK_COOLDOWN
                    attack_released = false
                    attack_telegraphed.emit()
                    _log("COMBAT", "Cultist attack telegraph")

    _move_and_slide_scaled()
    queue_redraw()

func _spawn_death_burst() -> void:
    var effect: Node2D = DEATH_BURST_SCRIPT.new()
    effect.global_position = global_position + Vector2(0, -34)
    get_parent().add_child(effect)
    effect.call("setup", 14.0)

func _spawn_hit_spark() -> void:
    var effect := Node2D.new()
    effect.set_script(HIT_SPARK_SCRIPT)
    effect.global_position = global_position + Vector2(0, -34)
    get_parent().add_child(effect)

func receive_damage(amount: int, source: Node = null) -> void:
    health = max(0, health - amount)
    _spawn_hit_spark()
    hit_flash = 0.12
    stun_time = 0.11
    if source and source is Node2D:
        velocity.x = sign(global_position.x - source.global_position.x) * 125.0
    var source_name: String = source.name if source else "Unknown"
    _log("COMBAT", "%s -> Cultist damage=%d hp=%d" % [source_name, amount, health])
    if health <= 0:
        _spawn_death_burst()
        _log("COMBAT", "Cultist defeated")
        defeated.emit()
        queue_free()

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func apply_echo_stagger(duration: float) -> bool:
    if health <= 0 or is_queued_for_deletion():
        return false
    stun_time = maxf(stun_time, clampf(duration, 0.0, 0.45))
    windup = 0.0
    attack_released = true
    hit_flash = maxf(hit_flash, 0.12)
    velocity.x *= 0.25
    _log("COMBAT", "Cultist staggered by Eldritch Echo for %.2fs" % stun_time)
    return true

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
    var sway: float = sin(animation_time * 4.6) * 1.8
    var hit := hit_flash > 0.0
    var robe := Color("#a94b55") if hit else Color("#30252f")
    var robe_light := Color("#d05b61") if hit else Color("#57404b")
    var robe_shadow := Color("#17151d")
    var bone := Color("#e0d0b5")
    var iron := Color("#8e7779")
    var hood := Color("#17151d")

    # Ground shadow, then a layered, ragged robe silhouette.
    _draw_shadow_ellipse(Vector2(0, 2), 27.0, 6.0, Color(0.03, 0.02, 0.04, 0.5))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-13, -43 + sway), Vector2(13, -43 + sway),
        Vector2(22, -12), Vector2(31, 9), Vector2(15, 7),
        Vector2(6, 13), Vector2(-5, 8), Vector2(-21, 12),
        Vector2(-30, 5), Vector2(-22, -15)
    ]), robe_shadow)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-12, -42 + sway), Vector2(12, -42 + sway),
        Vector2(18, -14), Vector2(25, 4), Vector2(12, 7),
        Vector2(4, 3), Vector2(-5, 9), Vector2(-19, 6),
        Vector2(-24, 1), Vector2(-18, -17)
    ]), robe)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-9, -38 + sway), Vector2(0, -40 + sway),
        Vector2(7, -13), Vector2(2, 5), Vector2(-7, 6),
        Vector2(-14, -11)
    ]), robe_light)
    draw_line(Vector2(12, -34 + sway), Vector2(17, -9), Color("#7b5961", 0.8), 2.0)
    draw_line(Vector2(-15, -13), Vector2(-23, 4), Color("#76505b", 0.75), 2.0)

    # Long sleeves and crooked hands; the weapon arm leads the telegraph.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-12, -36 + sway), Vector2(-21, -33 + sway),
        Vector2(-35, -10), Vector2(-29, -5), Vector2(-15, -21)
    ]), robe_shadow)
    draw_colored_polygon(PackedVector2Array([
        Vector2(11, -36 + sway), Vector2(20, -31 + sway),
        Vector2(34, -13), Vector2(29, -7), Vector2(15, -22)
    ]), robe_light)
    draw_line(Vector2(-31, -8), Vector2(-35, 0), bone, 3.0)
    draw_line(Vector2(31, -10), Vector2(36, -2), bone, 3.0)

    # Hood rim and an expressionless bone mask instead of a flat face circle.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-19, -52 + sway), Vector2(-15, -68 + sway),
        Vector2(-4, -77 + sway), Vector2(10, -72 + sway),
        Vector2(20, -56 + sway), Vector2(15, -43 + sway),
        Vector2(-13, -42 + sway)
    ]), hood)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-11, -61 + sway), Vector2(-7, -69 + sway),
        Vector2(5, -70 + sway), Vector2(12, -60 + sway),
        Vector2(9, -49 + sway), Vector2(-8, -48 + sway)
    ]), bone if not hit else Color("#f1a0a0"))
    draw_line(Vector2(-8, -59 + sway), Vector2(-2, -57 + sway), robe_shadow, 3.0)
    draw_line(Vector2(3, -57 + sway), Vector2(9, -59 + sway), robe_shadow, 3.0)
    draw_line(Vector2(-2, -54 + sway), Vector2(1, -50 + sway), Color("#88736e"), 1.5)
    draw_line(Vector2(-15, -48 + sway), Vector2(14, -47 + sway), iron, 2.0)

    # A broken prayer medallion hangs over the chest, faintly rust-red.
    draw_line(Vector2(0, -43 + sway), Vector2(1, -27 + sway), Color("#8c6b6d"), 2.0)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-5, -30 + sway), Vector2(1, -36 + sway),
        Vector2(7, -29 + sway), Vector2(1, -21 + sway)
    ]), Color("#a64c56") if not hit else Color("#e0b8a0"))
    draw_line(Vector2(1, -32 + sway), Vector2(1, -25 + sway), bone, 1.5)

    if windup > 0.0:
        var pulse: float = 1.0 + sin(animation_time * 18.0) * 0.18
        draw_arc(Vector2(facing * 22.0, -24), 34.0 * pulse, -0.85 if facing > 0 else 3.99, 0.85 if facing > 0 else 5.42, 16, Color("#c44e5a"), 4.0)
        draw_line(Vector2(facing * 28.0, -21), Vector2(facing * 54.0, -34), Color("#d36a67"), 3.0)
        draw_circle(Vector2(facing * 55.0, -35), 3.0, Color("#d36a67"))

    draw_string(ThemeDB.fallback_font, Vector2(-48, -86), "CULTIST %d" % max(0, health), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#b7a09b"))


func _draw_shadow_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(24):
        var angle := TAU * float(i) / 24.0
        points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
    draw_colored_polygon(points, color)

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
