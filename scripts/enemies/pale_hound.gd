extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")

const SPEED := 155.0
const ATTACK_RANGE := 105.0
const ATTACK_COOLDOWN := 1.35
const POUNCE_DURATION := 0.24
const POUNCE_SPEED := 320.0

var health := 70
var attack_timer := 0.0
var pounce_timer := 0.0
var facing := 1.0
var hit_flash := 0.0
var attack_hitbox: Area2D
signal defeated

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

func _physics_process(delta: float) -> void:
    attack_timer = max(0.0, attack_timer - delta)
    pounce_timer = max(0.0, pounce_timer - delta)
    hit_flash = max(0.0, hit_flash - delta)

    var hero := get_node_or_null("../Hero")
    if hero:
        var dx := hero.global_position.x - global_position.x
        if dx != 0.0:
            facing = sign(dx)

        if pounce_timer > 0.0:
            velocity.x = facing * POUNCE_SPEED
        else:
            var distance := abs(dx)
            if distance > ATTACK_RANGE:
                velocity.x = facing * SPEED
            else:
                velocity.x = 0.0
                if attack_timer <= 0.0:
                    pounce_timer = POUNCE_DURATION
                    attack_timer = ATTACK_COOLDOWN
                    attack_hitbox.position.x = facing * 46.0
                    attack_hitbox.activate(18, 0.18)
                    velocity.y = -190.0
                    _log("COMBAT", "Pale Hound pounce; damage=18")

    if not is_on_floor():
        velocity.y += 1400.0 * delta

    move_and_slide()
    queue_redraw()

func receive_damage(amount: int, source: Node = null) -> void:
    health = max(0, health - amount)
    _spawn_hit_spark()
    hit_flash = 0.12
    var source_name := source.name if source else "Unknown"
    _log("COMBAT", "%s -> Pale Hound damage=%d hp=%d" % [source_name, amount, health])
    if health <= 0:
        _log("ENEMY", "Pale Hound defeated")
        defeated.emit()
        queue_free()

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func _spawn_hit_spark() -> void:
    var effect := Node2D.new()
    effect.set_script(HIT_SPARK_SCRIPT)
    effect.global_position = global_position + Vector2(0, -24)
    get_parent().add_child(effect)

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
    var c := Color("#bd8e86") if hit_flash > 0.0 else Color("#41383f")
    draw_ellipse(Vector2.ZERO, Vector2(32, 18), c)
    draw_circle(Vector2(facing * 26.0, -24), 11.0, c)
    draw_line(Vector2(-18, -10), Vector2(-34, 14), c, 6.0)
    draw_line(Vector2(18, -10), Vector2(34, 14), c, 6.0)
    draw_line(Vector2(-8, -6), Vector2(-18, 18), c, 6.0)
    draw_line(Vector2(8, -6), Vector2(18, 18), c, 6.0)
    draw_string(ThemeDB.fallback_font, Vector2(-55, -52), "PALE HOUND %d" % max(0, health), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#b7a09b"))

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(24):
        var angle := TAU * float(i) / 24.0
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    draw_colored_polygon(points, color)
