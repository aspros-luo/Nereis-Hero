extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")
const DEATH_BURST_SCRIPT = preload("res://scripts/effects/death_burst.gd")

var health := 240
var attack_cooldown := 0.0
var windup := 0.0
var hit_flash := 0.0
var stun_time := 0.0
var facing := -1.0
var attack_released := false
var phase_two := false
var attack_hitbox: Area2D
var animation_time := 0.0
signal defeated
signal phase_changed(phase: int)
signal attack_telegraphed

func _ready() -> void:
    add_to_group("combat_enemies")
    _setup_combat_components()
    _log("BOSS", "Ashen Knight initialized; hp=240")
    queue_redraw()

func _setup_combat_components() -> void:
    attack_hitbox = Area2D.new()
    attack_hitbox.name = "AttackHitbox"
    attack_hitbox.set_script(HITBOX_SCRIPT)
    add_child(attack_hitbox)
    attack_hitbox.setup(self, Vector2(120, 72), Vector2(facing * 64.0, -34.0))

    var hurtbox := Area2D.new()
    hurtbox.name = "Hurtbox"
    hurtbox.set_script(HURTBOX_SCRIPT)
    add_child(hurtbox)
    hurtbox.setup(self, Vector2(48, 94), Vector2(0, -38))

func _process(delta: float) -> void:
    if WorldState.input_locked:
        return
    animation_time += delta
    queue_redraw()

func _physics_process(delta: float) -> void:
    if WorldState.input_locked:
        return
    attack_cooldown = max(0.0, attack_cooldown - delta)
    hit_flash = max(0.0, hit_flash - delta)
    windup = max(0.0, windup - delta)
    stun_time = max(0.0, stun_time - delta)

    if not phase_two and health <= 120:
        phase_two = true
        attack_cooldown = 0.2
        windup = 0.0
        _log("BOSS", "Ashen Knight entered Phase 2")
        phase_changed.emit(2)
        queue_redraw()

    if stun_time > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
        move_and_slide()
        queue_redraw()
        return

    var hero: Node2D = get_node_or_null("../Hero") as Node2D
    if hero:
        var delta_x: float = hero.global_position.x - global_position.x
        if abs(delta_x) > 165.0 and windup <= 0.0:
            facing = sign(delta_x)
            velocity.x = facing * (98.0 if phase_two else 64.0)
        elif windup > 0.0:
            velocity.x = move_toward(velocity.x, 0.0, 1600.0 * delta)
            facing = sign(delta_x) if delta_x != 0.0 else facing
            if windup <= 0.06 and not attack_released:
                attack_released = true
                attack_hitbox.position.x = facing * (72.0 if phase_two else 64.0)
                var attack_damage := 36 if phase_two else 24
                var attack_range := 132.0 if phase_two else 120.0
                attack_hitbox.activate(attack_damage, 0.18 if phase_two else 0.16)
                velocity.x = facing * (155.0 if phase_two else 85.0)
                _log("COMBAT", "Ashen Knight heavy attack released; damage=%d range=%.0f" % [attack_damage, attack_range])
        else:
            velocity.x = 0.0
            facing = sign(delta_x) if delta_x != 0.0 else facing
            if attack_cooldown <= 0.0:
                windup = 0.30 if phase_two else 0.42
                attack_cooldown = 0.82 if phase_two else 1.55
                attack_released = false
                attack_telegraphed.emit()
                _log("BOSS", "Ashen Knight attack telegraph phase=%d" % (2 if phase_two else 1))

    move_and_slide()
    queue_redraw()

func _spawn_death_burst() -> void:
    var effect: Node2D = DEATH_BURST_SCRIPT.new()
    effect.global_position = global_position + Vector2(0, -44)
    get_parent().add_child(effect)
    effect.call("setup", 26.0)

func _spawn_hit_spark() -> void:
    var effect := Node2D.new()
    effect.set_script(HIT_SPARK_SCRIPT)
    effect.global_position = global_position + Vector2(0, -34)
    get_parent().add_child(effect)

func receive_damage(amount: int, source: Node = null) -> void:
    health = max(0, health - amount)
    _spawn_hit_spark()
    hit_flash = 0.12
    stun_time = 0.08 if phase_two else 0.12
    if source and source is Node2D:
        velocity.x = sign(global_position.x - source.global_position.x) * (95.0 if phase_two else 75.0)
    var source_name: String = source.name if source else "Unknown"
    _log("BOSS", "%s -> Ashen Knight damage=%d hp=%d" % [source_name, amount, health])
    if health <= 0:
        _spawn_death_burst()
        _log("BOSS", "Ashen Knight defeated")
        WorldState.mark_boss_defeated()
        defeated.emit()
        queue_free()

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func apply_echo_stagger(duration: float) -> bool:
    if health <= 0 or is_queued_for_deletion():
        return false
    # Bosses resist the full control effect; Echo can interrupt a tell but never lock the boss down.
    # Boss 对控制效果有抗性：余响可打断起手，但不能长时间压制。
    var capped_duration := minf(duration, 0.12 if phase_two else 0.15)
    stun_time = maxf(stun_time, capped_duration)
    windup = 0.0
    attack_released = true
    hit_flash = maxf(hit_flash, 0.10)
    velocity.x *= 0.35
    _log("BOSS", "Eldritch Echo caused brief stagger %.2fs (phase=%d)" % [capped_duration, 2 if phase_two else 1])
    return true

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
    var base := Color("#7b3944") if phase_two else Color("#2c2932")
    var armor := Color("#d35a62") if hit_flash > 0.0 else base
    var pulse: float = sin(animation_time * 4.0) * 2.0
    var steel := Color("#9f806f")
    var bright_steel := Color("#c9baa0")
    var shadow := Color("#141218")
    var chest_y := -43.0 + pulse

    # Heavy greaves and boots establish a much larger silhouette than ordinary enemies.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-24, -11 + pulse), Vector2(-5, -10 + pulse),
        Vector2(-8, 10), Vector2(-25, 14), Vector2(-30, 5)
    ]), shadow)
    draw_colored_polygon(PackedVector2Array([
        Vector2(5, -10 + pulse), Vector2(24, -11 + pulse),
        Vector2(30, 5), Vector2(25, 14), Vector2(8, 10)
    ]), shadow)
    draw_line(Vector2(-25, 5), Vector2(-10, 3), steel, 3.0)
    draw_line(Vector2(10, 3), Vector2(25, 5), steel, 3.0)
    draw_line(Vector2(-28, 13), Vector2(-10, 12), bright_steel, 2.0)
    draw_line(Vector2(10, 12), Vector2(28, 13), bright_steel, 2.0)

    # Split plate skirt and dark under-armor.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-25, -42 + pulse), Vector2(25, -42 + pulse),
        Vector2(34, -9), Vector2(18, 2), Vector2(0, -5),
        Vector2(-18, 2), Vector2(-34, -9)
    ]), shadow)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-23, -39 + pulse), Vector2(23, -39 + pulse),
        Vector2(28, -12), Vector2(15, -3), Vector2(0, -9),
        Vector2(-15, -3), Vector2(-28, -12)
    ]), armor)
    draw_line(Vector2(-21, -13), Vector2(-11, -6), steel, 2.0)
    draw_line(Vector2(21, -13), Vector2(11, -6), steel, 2.0)
    draw_line(Vector2(0, -8), Vector2(0, 0), bright_steel, 1.5)

    # Breastplate: layered rim, ribbed center and a cracked seal that changes in phase two.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-27, -49 + pulse), Vector2(-18, -61 + pulse),
        Vector2(0, -66 + pulse), Vector2(18, -61 + pulse),
        Vector2(27, -49 + pulse), Vector2(22, -28 + pulse),
        Vector2(0, -20 + pulse), Vector2(-22, -28 + pulse)
    ]), shadow)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-22, -48 + pulse), Vector2(-15, -57 + pulse),
        Vector2(0, -61 + pulse), Vector2(15, -57 + pulse),
        Vector2(22, -48 + pulse), Vector2(17, -31 + pulse),
        Vector2(0, -25 + pulse), Vector2(-17, -31 + pulse)
    ]), armor)
    draw_line(Vector2(-15, -53 + pulse), Vector2(-10, -34 + pulse), steel, 2.0)
    draw_line(Vector2(15, -53 + pulse), Vector2(10, -34 + pulse), steel, 2.0)
    draw_line(Vector2(0, -58 + pulse), Vector2(0, -29 + pulse), Color("#b65b65") if phase_two else steel, 2.0)
    draw_arc(Vector2(0, -44 + pulse), 8.0 if phase_two else 6.0, 0.0, TAU, 18, Color("#d85e70") if phase_two else bright_steel, 2.0)
    draw_circle(Vector2(-16, -49 + pulse), 2.0, bright_steel)
    draw_circle(Vector2(16, -49 + pulse), 2.0, bright_steel)

    # Shoulder pauldrons and layered helmet; phase two exposes an unnatural crown.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-31, -46 + pulse), Vector2(-23, -55 + pulse),
        Vector2(-14, -50 + pulse), Vector2(-17, -37 + pulse),
        Vector2(-29, -35 + pulse)
    ]), Color("#51414a"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(31, -46 + pulse), Vector2(23, -55 + pulse),
        Vector2(14, -50 + pulse), Vector2(17, -37 + pulse),
        Vector2(29, -35 + pulse)
    ]), Color("#51414a"))
    draw_line(Vector2(-29, -44 + pulse), Vector2(-19, -47 + pulse), bright_steel, 2.0)
    draw_line(Vector2(29, -44 + pulse), Vector2(19, -47 + pulse), bright_steel, 2.0)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-19, -62 + pulse), Vector2(-15, -77 + pulse),
        Vector2(-3, -82 + pulse), Vector2(10, -78 + pulse),
        Vector2(19, -64 + pulse), Vector2(13, -48 + pulse),
        Vector2(0, -43 + pulse), Vector2(-13, -48 + pulse)
    ]), shadow)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-14, -63 + pulse), Vector2(-10, -73 + pulse),
        Vector2(0, -76 + pulse), Vector2(10, -70 + pulse),
        Vector2(14, -62 + pulse), Vector2(10, -51 + pulse),
        Vector2(0, -47 + pulse), Vector2(-10, -52 + pulse)
    ]), armor)
    draw_line(Vector2(-13, -61 + pulse), Vector2(13, -62 + pulse), bright_steel, 2.0)
    draw_line(Vector2(-8, -57 + pulse), Vector2(8, -58 + pulse), Color("#19151c"), 4.0)
    draw_line(Vector2(-5, -57 + pulse), Vector2(5, -58 + pulse), Color("#d85e70") if phase_two else Color("#b6a28a"), 1.4)
    if phase_two:
        draw_colored_polygon(PackedVector2Array([
            Vector2(-13, -72 + pulse), Vector2(-25, -86 + pulse),
            Vector2(-20, -67 + pulse), Vector2(-12, -61 + pulse)
        ]), Color("#7b3944"))
        draw_colored_polygon(PackedVector2Array([
            Vector2(13, -72 + pulse), Vector2(25, -86 + pulse),
            Vector2(20, -67 + pulse), Vector2(12, -61 + pulse)
        ]), Color("#7b3944"))
        draw_line(Vector2(-4, -73 + pulse), Vector2(0, -80 + pulse), Color("#cf687b"), 2.0)
        draw_line(Vector2(0, -80 + pulse), Vector2(4, -73 + pulse), Color("#cf687b"), 2.0)

    # A long, readable greatsword with a crossguard and a dark, heavy edge.
    var sword_start := Vector2(facing * 13.0, -22.0 + pulse)
    var sword_tip := Vector2(facing * 112.0, -48.0 + pulse)
    draw_line(sword_start, sword_tip, shadow, 14.0)
    draw_line(sword_start, sword_tip, bright_steel, 8.0)
    draw_line(sword_start + Vector2(0, -2), sword_tip + Vector2(0, -2), Color("#e2d8c4"), 2.0)
    draw_line(sword_start + Vector2(-facing * 9.0, -3), sword_start + Vector2(facing * 8.0, 2), shadow, 7.0)
    draw_line(sword_start + Vector2(-facing * 8.0, -3), sword_start + Vector2(facing * 7.0, 1), steel, 3.0)

    if windup > 0.0:
        var telegraph_color := Color("#e16b7b") if phase_two else Color("#9e5961")
        draw_arc(Vector2(0, -34), 72.0 if phase_two else 58.0, 0, TAU, 32, telegraph_color, 4.0)
        draw_arc(Vector2(0, -34), 62.0 if phase_two else 50.0, PI * 0.18, PI * 1.32, 24, Color(0.82, 0.53, 0.57, 0.55), 1.5)
        draw_line(Vector2(facing * 34.0, -34), Vector2(facing * 108.0, -34), telegraph_color, 3.0)
    draw_string(ThemeDB.fallback_font, Vector2(-72, -100), NereisLocalization.translate_text("ASHEN KNIGHT %d") % max(0, health), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d6c7b2"))
