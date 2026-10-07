extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")

const MOVE_SPEED := 75.0
const ATTACK_RANGE := 250.0
const ATTACK_COOLDOWN := 1.8
const MAX_HEALTH := 85

var health := MAX_HEALTH
var attack_timer := 0.0
var hover_time := 0.0
var hit_flash := 0.0
var facing := 1.0
var attack_hitbox: Area2D
signal defeated

func _ready() -> void:
    _setup_combat_components()
    hover_time = randf() * TAU
    _log("ENEMY", "Bell Wraith initialized; hp=%d" % MAX_HEALTH)
    queue_redraw()

func _setup_combat_components() -> void:
    attack_hitbox = Area2D.new()
    attack_hitbox.name = "SonicPulseHitbox"
    attack_hitbox.set_script(HITBOX_SCRIPT)
    add_child(attack_hitbox)
    attack_hitbox.setup(self, Vector2(74, 74), Vector2.ZERO)

    var hurtbox := Area2D.new()
    hurtbox.name = "Hurtbox"
    hurtbox.set_script(HURTBOX_SCRIPT)
    add_child(hurtbox)
    hurtbox.setup(self, Vector2(48, 70), Vector2(0, -8))

func _physics_process(delta: float) -> void:
    attack_timer = max(0.0, attack_timer - delta)
    hit_flash = max(0.0, hit_flash - delta)
    hover_time += delta

    var hero := get_node_or_null("../Hero")
    if hero:
        var delta_to_hero := hero.global_position - global_position
        if delta_to_hero.x != 0.0:
            facing = sign(delta_to_hero.x)

        var target_velocity := Vector2(
            clamp(delta_to_hero.x * 1.6, -MOVE_SPEED, MOVE_SPEED),
            clamp(delta_to_hero.y * 1.2, -55.0, 55.0)
        )
        velocity = velocity.move_toward(target_velocity, 260.0 * delta)

        if abs(delta_to_hero.x) <= ATTACK_RANGE and attack_timer <= 0.0:
            attack_timer = ATTACK_COOLDOWN
            attack_hitbox.position = Vector2(facing * min(abs(delta_to_hero.x), 190.0), clamp(delta_to_hero.y, -70.0, 70.0))
            attack_hitbox.activate(15, 0.12)
            _log("COMBAT", "Bell Wraith sonic pulse; damage=15")

    move_and_slide()
    queue_redraw()

func receive_damage(amount: int, source: Node = null) -> void:
    health = max(0, health - amount)
    _spawn_hit_spark()
    hit_flash = 0.12
    var source_name := source.name if source else "Unknown"
    _log("COMBAT", "%s -> Bell Wraith damage=%d hp=%d" % [source_name, amount, health])
    if health <= 0:
        _log("ENEMY", "Bell Wraith defeated")
        defeated.emit()
        queue_free()

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func _spawn_hit_spark() -> void:
    var effect := Node2D.new()
    effect.set_script(HIT_SPARK_SCRIPT)
    effect.global_position = global_position
    get_parent().add_child(effect)

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
    var hover := sin(hover_time * 2.0) * 6.0
    var c := Color("#d2a7a8") if hit_flash > 0.0 else Color("#51414e")
    draw_circle(Vector2(0, hover - 12), 18.0, c)
    draw_rect(Rect2(-20, hover + 0, 40, 30), c)
    draw_circle(Vector2(0, hover + 30), 11.0, Color("#28222a"))
    draw_line(Vector2(-15, hover + 6), Vector2(-28, hover + 34), c, 5.0)
    draw_line(Vector2(15, hover + 6), Vector2(28, hover + 34), c, 5.0)
    draw_string(ThemeDB.fallback_font, Vector2(-62, hover - 42), "BELL WRAITH %d" % max(0, health), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#b7a09b"))
