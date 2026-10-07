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
    animation_time += delta
    queue_redraw()

func _physics_process(delta: float) -> void:
    attack_cooldown = max(0.0, attack_cooldown - delta)
    windup = max(0.0, windup - delta)
    hit_flash = max(0.0, hit_flash - delta)
    stun_time = max(0.0, stun_time - delta)

    if stun_time > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
        move_and_slide()
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

    move_and_slide()
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

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
    var sway: float = sin(animation_time * 5.0) * 1.5
    var c := Color("#c8565f") if hit_flash > 0.0 else Color("#4e3a43")
    var hood := Color("#211c24")
    draw_circle(Vector2(0, -46 + sway), 18, hood)
    draw_circle(Vector2(facing * 4.0, -44 + sway), 8, c)
    draw_rect(Rect2(-19, -28 + sway, 38, 30), c)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-20, -27 + sway), Vector2(20, -27 + sway),
        Vector2(25, 8), Vector2(-25, 8)
    ]), Color("#362b35"))
    draw_line(Vector2(-14, -4 + sway), Vector2(-46, 10), c, 7.0)
    draw_line(Vector2(14, -4 + sway), Vector2(46, 10), c, 7.0)
    if windup > 0.0:
        draw_arc(Vector2(facing * 22.0, -24), 34.0, -0.85 if facing > 0 else 3.99, 0.85 if facing > 0 else 5.42, 14, Color("#c44e5a"), 4.0)
    draw_string(ThemeDB.fallback_font, Vector2(-48, -72), "CULTIST %d" % max(0, health), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#b7a09b"))
