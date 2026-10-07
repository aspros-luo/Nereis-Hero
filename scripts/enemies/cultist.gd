extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")

var health := 100
var attack_cooldown := 0.0
var hit_flash := 0.0
var attack_hitbox: Area2D

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

func _physics_process(delta: float) -> void:
    attack_cooldown = max(0.0, attack_cooldown - delta)
    hit_flash = max(0.0, hit_flash - delta)

    var hero := get_node_or_null("../Hero")

    if hero:
        var distance := global_position.distance_to(hero.global_position)
        if distance > 90.0:
            velocity.x = sign(hero.global_position.x - global_position.x) * 95.0
            attack_hitbox.position.x = sign(hero.global_position.x - global_position.x) * 40.0
        else:
            velocity.x = 0.0
            attack_hitbox.position.x = sign(hero.global_position.x - global_position.x) * 40.0
            if attack_cooldown <= 0.0:
                attack_hitbox.activate(12, 0.12)
                attack_cooldown = 1.1
                _log("COMBAT", "Cultist attack started; hitbox active")

    move_and_slide()
    queue_redraw()

func receive_damage(amount: int, source: Node = null) -> void:
    health = max(0, health - amount)
    hit_flash = 0.12
    var source_name := source.name if source else "Unknown"
    _log("COMBAT", "%s -> Cultist damage=%d hp=%d" % [source_name, amount, health])
    if health <= 0:
        _log("COMBAT", "Cultist defeated")
        queue_free()

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
    var c := Color("#b44b52") if hit_flash > 0.0 else Color("#55404a")
    draw_circle(Vector2(0, -45), 17, c)
    draw_rect(Rect2(-20, -28, 40, 28), c)
    draw_line(Vector2(-14, -4), Vector2(-46, 8), c, 8.0)
    draw_line(Vector2(14, -4), Vector2(46, 8), c, 8.0)
    draw_string(ThemeDB.fallback_font, Vector2(-48, -72), "CULTIST %d" % max(0, health), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#b7a09b"))
