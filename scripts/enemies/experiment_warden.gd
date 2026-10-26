extends CharacterBody2D

const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")
const DEATH_BURST_SCRIPT = preload("res://scripts/effects/death_burst.gd")

signal defeated
signal attack_telegraphed

const MOVE_SPEED := 88.0
const GRAVITY := 1400.0
const ATTACK_RANGE := 118.0
const VERTICAL_ATTACK_TOLERANCE := 62.0
const ATTACK_COOLDOWN := 1.45
const ATTACK_WINDUP := 0.42

var health := 120
var cooldown := 0.0
var windup := 0.0
var released := false
var facing := -1.0
var hit_flash := 0.0
var stun_time := 0.0
var animation_time := 0.0
var attack_effect_time := 0.0
var attack_hitbox: Area2D

func _ready() -> void:
    add_to_group("combat_enemies")
    # Stagger the ambush so the player can read attacks instead of facing a synchronized volley.
    # 错开伏击者的首轮攻击，避免三名敌人同时出招。
    if name == "Warden_Right":
        cooldown = 0.65
    elif name == "Warden_Drop":
        cooldown = 1.15
    attack_hitbox = Area2D.new()
    attack_hitbox.set_script(HITBOX_SCRIPT)
    add_child(attack_hitbox)
    attack_hitbox.setup(self, Vector2(92, 60), Vector2(-52, -28))

    var hurtbox := Area2D.new()
    hurtbox.set_script(HURTBOX_SCRIPT)
    add_child(hurtbox)
    hurtbox.setup(self, Vector2(42, 78), Vector2(0, -38))
    queue_redraw()

func _process(delta: float) -> void:
    delta *= WorldState.get_combat_enemy_time_scale()
    if WorldState.input_locked:
        return
    animation_time += delta
    attack_effect_time = maxf(0.0, attack_effect_time - delta)
    cooldown = maxf(0.0, cooldown - delta)
    hit_flash = maxf(0.0, hit_flash - delta)
    stun_time = maxf(0.0, stun_time - delta)
    queue_redraw()

func _physics_process(delta: float) -> void:
    delta *= WorldState.get_combat_enemy_time_scale()
    if WorldState.input_locked:
        return

    # Falling enemies must obey the same floor collision as the Hero.
    # 坠落敌人使用正常重力与地面碰撞，避免悬停在生成点。
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    else:
        velocity.y = 0.0

    var hero := get_node_or_null("../Hero") as CharacterBody2D
    if not is_instance_valid(hero):
        velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
        _move_and_slide_scaled()
        return

    var dx: float = hero.global_position.x - global_position.x
    var dy: float = hero.global_position.y - global_position.y
    var horizontal_distance: float = absf(dx)
    var same_level: bool = absf(dy) <= VERTICAL_ATTACK_TOLERANCE

    # Lock facing during a telegraphed strike; otherwise face the target without jitter.
    # 攻击前摇期间锁定朝向，平时再追踪玩家，避免攻击判定临时转向。
    if windup <= 0.0 and horizontal_distance > 10.0:
        facing = signf(dx)

    if stun_time > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 1050.0 * delta)
        _move_and_slide_scaled()
        return

    if windup > 0.0:
        windup = maxf(0.0, windup - delta)
        velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
        if windup <= 0.08 and not released:
            if horizontal_distance <= ATTACK_RANGE + 18.0 and same_level:
                attack_hitbox.position.x = facing * 52.0
                attack_hitbox.activate(15, 0.13)
                attack_effect_time = 0.22
            released = true
    elif not is_on_floor() or not same_level or horizontal_distance > ATTACK_RANGE:
        # Approach only while grounded; the falling ambusher lands before engaging.
        velocity.x = move_toward(velocity.x, facing * MOVE_SPEED, 700.0 * delta) if is_on_floor() else 0.0
    else:
        # Stop inside attack range even while the cooldown is running.
        velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
        if cooldown <= 0.0 and not _nearby_enemy_is_winding_up():
            windup = ATTACK_WINDUP
            cooldown = ATTACK_COOLDOWN
            released = false
            attack_telegraphed.emit()

    _move_and_slide_scaled()


func _nearby_enemy_is_winding_up() -> bool:
    for candidate in get_tree().get_nodes_in_group("combat_enemies"):
        if candidate == self or not is_instance_valid(candidate) or not candidate is Node2D:
            continue
        if candidate.get_script() != get_script():
            continue
        var other := candidate as Node2D
        if absf(other.global_position.x - global_position.x) > 180.0:
            continue
        if absf(other.global_position.y - global_position.y) > VERTICAL_ATTACK_TOLERANCE:
            continue
        var other_windup: Variant = candidate.get("windup")
        if (other_windup is float or other_windup is int) and float(other_windup) > 0.0:
            return true
    return false

func receive_damage(amount: int, source: Node = null) -> void:
    health = max(0, health - amount)
    hit_flash = 0.12
    stun_time = 0.12

    var spark: Node2D = HIT_SPARK_SCRIPT.new()
    spark.global_position = global_position + Vector2(0, -36)
    get_parent().add_child(spark)

    if source and source is Node2D:
        velocity.x = sign(global_position.x - source.global_position.x) * 150.0

    if health <= 0:
        var burst: Node2D = DEATH_BURST_SCRIPT.new()
        burst.global_position = global_position + Vector2(0, -36)
        get_parent().add_child(burst)
        burst.call("setup", 14.0)
        defeated.emit()
        queue_free()

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func _draw() -> void:
    var sway := sin(animation_time * 3.0) * 1.2
    var steel := Color("#81757b") if hit_flash <= 0.0 else Color("#d3b8b2")
    var cloth := Color("#29232b")

    draw_circle(Vector2(0, -54 + sway), 19.0, Color("#19171d"))
    draw_circle(Vector2(facing * 5.0, -51 + sway), 6.0, Color("#8f4650"))
    draw_rect(Rect2(-22, -34 + sway, 44, 42), steel)
    draw_rect(Rect2(-29, -4 + sway, 58, 18), cloth)
    draw_line(Vector2(-14, -2 + sway), Vector2(-46, 12 + sway), steel, 7.0)
    draw_line(Vector2(14, -2 + sway), Vector2(46, 12 + sway), steel, 7.0)

    if windup > 0.0:
        var telegraph_color := Color("#ffd0b5")
        draw_arc(Vector2(facing * 32.0, -27), 42.0, -0.95 if facing > 0 else 2.2, 0.95 if facing > 0 else 4.1, 18, telegraph_color, 5.0)
        draw_line(Vector2(facing * 25.0, -26), Vector2(facing * 94.0, -26), telegraph_color, 4.0)
    if attack_effect_time > 0.0:
        var slash_alpha := clampf(attack_effect_time / 0.22, 0.0, 1.0)
        draw_line(Vector2(facing * 22.0, -62.0), Vector2(facing * 94.0, -8.0), Color(1.0, 0.88, 0.72, slash_alpha), 9.0)
        draw_line(Vector2(facing * 32.0, -70.0), Vector2(facing * 104.0, -18.0), Color(1.0, 0.46, 0.40, slash_alpha), 3.0)

    draw_string(ThemeDB.fallback_font, Vector2(-66, -82), "EXPERIMENT WARDEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#b7a09b"))


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
