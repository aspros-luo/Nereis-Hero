extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")

var health := 240
var attack_cooldown := 0.0
var windup := 0.0
var hit_flash := 0.0
var stun_time := 0.0
var facing := -1.0
var attack_released := false
var phase_two := false
var attack_hitbox: Area2D
signal defeated
signal phase_changed(phase: int)

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

func _physics_process(delta: float) -> void:
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
                _log("BOSS", "Ashen Knight attack telegraph phase=%d" % (2 if phase_two else 1))

    move_and_slide()
    queue_redraw()

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
        _log("BOSS", "Ashen Knight defeated")
        WorldState.mark_boss_defeated()
        defeated.emit()
        queue_free()

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
    var base := Color("#6f3941") if phase_two else Color("#332d34")
    var c := Color("#c44e5a") if hit_flash > 0.0 else base
    draw_circle(Vector2(0, -60), 21, c)
    draw_rect(Rect2(-25, -40, 50, 40), c)
    draw_line(Vector2(-18, -4), Vector2(-62, 10), c, 11.0)
    draw_line(Vector2(18, -4), Vector2(62, 10), c, 11.0)
    draw_line(Vector2(facing * 8.0, -18), Vector2(facing * 84.0, -42), Color("#b7a48c"), 9.0)
    if windup > 0.0:
        var telegraph_color := Color("#c44e5a") if phase_two else Color("#9e5961")
        draw_arc(Vector2(0, -34), 68.0 if phase_two else 58.0, 0, TAU, 28, telegraph_color, 5.0)
        draw_line(Vector2(facing * 34.0, -34), Vector2(facing * 102.0, -34), telegraph_color, 4.0)
    draw_string(ThemeDB.fallback_font, Vector2(-72, -94), "ASHEN KNIGHT %d" % max(0, health), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d6c7b2"))
