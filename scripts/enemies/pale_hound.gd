extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")

const SPEED := 155.0
const ATTACK_RANGE := 118.0
const ATTACK_COOLDOWN := 1.45
const ATTACK_WINDUP := 0.30
const POUNCE_DURATION := 0.24
const POUNCE_SPEED := 320.0

var health := 70
var attack_timer := 0.0
var attack_windup := 0.0
var pounce_timer := 0.0
var attack_released := false
var facing := 1.0
var hit_flash := 0.0
var stun_time := 0.0
var attack_hitbox: Area2D
var animation_time := 0.0
signal defeated
signal attack_telegraphed

func _ready() -> void:
    _setup_combat_components()
    _log("ENEMY", "Pale Hound initialized; hp=70")
    queue_redraw()

func _setup_combat_components() -> void:
    attack_hitbox = Area2D.new()
    attack_hitbox.name = "AttackHitbox"
    attack_hitbox.set_script(HITBOX_SCRIPT)
    add_child(attack_hitbox)
    attack_hitbox.setup(self, Vector2(92, 58), Vector2(facing * 46.0, -26.0))

    var hurtbox := Area2D.new()
    hurtbox.name = "Hurtbox"
    hurtbox.set_script(HURTBOX_SCRIPT)
    add_child(hurtbox)
    hurtbox.setup(self, Vector2(52, 48), Vector2(0, -24))

func _process(delta: float) -> void:
    animation_time += delta
    queue_redraw()

func _physics_process(delta: float) -> void:
    attack_timer = max(0.0, attack_timer - delta)
    attack_windup = max(0.0, attack_windup - delta)
    pounce_timer = max(0.0, pounce_timer - delta)
    hit_flash = max(0.0, hit_flash - delta)
    stun_time = max(0.0, stun_time - delta)

    if stun_time > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
        if not is_on_floor():
            velocity.y += 1400.0 * delta
        move_and_slide()
        queue_redraw()
        return

    var hero: Node2D = get_node_or_null("../Hero") as Node2D
    if hero:
        var dx: float = hero.global_position.x - global_position.x
        if dx != 0.0:
            facing = sign(dx)

        if attack_windup > 0.0:
            velocity.x = 0.0
            if attack_windup <= 0.05 and not attack_released:
                attack_released = true
                pounce_timer = POUNCE_DURATION
                attack_hitbox.position.x = facing * 46.0
                attack_hitbox.activate(18, 0.18)
                velocity.y = -190.0
                _log("COMBAT", "Pale Hound pounce released; damage=18")
        elif pounce_timer > 0.0:
            velocity.x = facing * POUNCE_SPEED
        else:
            var distance: float = absf(dx)
            if distance > ATTACK_RANGE:
                velocity.x = facing * SPEED
            else:
                velocity.x = 0.0
                if attack_timer <= 0.0:
                    attack_windup = ATTACK_WINDUP
                    attack_timer = ATTACK_COOLDOWN
                    attack_released = false
                    attack_telegraphed.emit()
                    _log("COMBAT", "Pale Hound pounce telegraph")

    if not is_on_floor():
        velocity.y += 1400.0 * delta

    move_and_slide()
    queue_redraw()

func receive_damage(amount: int, source: Node = null) -> void:
    health = max(0, health - amount)
    _spawn_hit_spark()
    hit_flash = 0.12
    stun_time = 0.10
    if source and source is Node2D:
        velocity.x = sign(global_position.x - source.global_position.x) * 150.0
    var source_name: String = source.name if source else "Unknown"
    _log("COMBAT", "%s -> Pale Hound damage=%d hp=%d" % [source_name, amount, health])
    if health <= 0:
        _spawn_death_burst()
        _log("ENEMY", "Pale Hound defeated")
        defeated.emit()
        queue_free()

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func _spawn_death_burst() -> void:
    var effect := Node2D.new()
    effect.set_script("res://scripts/effects/death_burst.gd")
    effect.global_position = global_position + Vector2(0, -18)
    get_parent().add_child(effect)
    effect.setup(16.0)

func _spawn_hit_spark() -> void:
    var effect := Node2D.new()
    effect.set_script(HIT_SPARK_SCRIPT)
    effect.global_position = global_position + Vector2(0, -24)
    get_parent().add_child(effect)

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
    var crouch: float = 3.0 if pounce_timer > 0.0 else 0.0
    var run: float = sin(animation_time * 15.0) * 3.0 if abs(velocity.x) > 20.0 else 0.0
    var c := Color("#d0a09b") if hit_flash > 0.0 else Color("#343039")
    var mane := Color("#201c24")
    _draw_body_ellipse(Vector2(run * 0.3, crouch), Vector2(32, 18 + crouch), c)
    draw_circle(Vector2(facing * 27.0 + run, -25 - crouch), 11.0, mane)
    draw_circle(Vector2(facing * 30.0 + run, -27 - crouch), 4.0, Color("#d36a67"))
    draw_line(Vector2(-18, -9 + crouch), Vector2(-34, 14 + run), c, 6.0)
    draw_line(Vector2(18, -9 + crouch), Vector2(34, 14 - run), c, 6.0)
    draw_line(Vector2(-8, -7 + crouch), Vector2(-18, 18 - run), c, 6.0)
    draw_line(Vector2(8, -7 + crouch), Vector2(18, 18 + run), c, 6.0)
    if attack_windup > 0.0:
        draw_line(
            Vector2(facing * 24.0, -32),
            Vector2(facing * 72.0, -44),
            Color("#c44e5a"),
            5.0
        )
    draw_string(ThemeDB.fallback_font, Vector2(-55, -52), "PALE HOUND %d" % max(0, health), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#b7a09b"))

func _draw_body_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(24):
        var angle := TAU * float(i) / 24.0
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    draw_colored_polygon(points, color)
