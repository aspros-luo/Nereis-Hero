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

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
    var base := Color("#7b3944") if phase_two else Color("#2c2932")
    var c := Color("#d35a62") if hit_flash > 0.0 else base
    var pulse: float = sin(animation_time * 4.0) * 2.0
    draw_circle(Vector2(0, -61 + pulse), 22, Color("#141218"))
    draw_circle(Vector2(0, -61 + pulse), 19, c)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-26, -40 + pulse), Vector2(26, -40 + pulse),
        Vector2(32, 8), Vector2(-32, 8)
    ]), c)
    draw_arc(Vector2(0, -55 + pulse), 30.0 if phase_two else 26.0, PI * 0.1, PI * 0.9, 20, Color("#9f806f"), 4.0)
    draw_line(Vector2(-18, -4 + pulse), Vector2(-62, 10), c, 12.0)
    draw_line(Vector2(18, -4 + pulse), Vector2(62, 10), c, 12.0)
    draw_line(Vector2(facing * 8.0, -18 + pulse), Vector2(facing * 92.0, -44 + pulse), Color("#c9baa0"), 10.0)
    if windup > 0.0:
        var telegraph_color := Color("#c44e5a") if phase_two else Color("#9e5961")
        draw_arc(Vector2(0, -34), 68.0 if phase_two else 58.0, 0, TAU, 28, telegraph_color, 5.0)
        draw_line(Vector2(facing * 34.0, -34), Vector2(facing * 102.0, -34), telegraph_color, 4.0)
    draw_string(ThemeDB.fallback_font, Vector2(-72, -94), NereisLocalization.translate_text("ASHEN KNIGHT %d") % max(0, health), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d6c7b2"))
