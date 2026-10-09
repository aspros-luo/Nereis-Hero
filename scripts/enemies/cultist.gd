extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")
const DEATH_BURST_SCRIPT = preload("res://scripts/effects/death_burst.gd")
const CULTIST_ART: Texture2D = preload("res://assets/art/characters/cultist.svg")

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
    var tint := Color("#f4d9d6") if hit_flash > 0.0 else Color.WHITE
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
    draw_texture_rect(CULTIST_ART, Rect2(-43.0, -86.0, 86.0, 108.0), false, tint)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

    if windup > 0.0:
        var telegraph_color := Color("#e77c83") if hit_flash <= 0.0 else Color("#f4c5b6")
        draw_arc(Vector2(facing * 22.0, -27.0), 38.0, -0.92 if facing > 0.0 else 4.06, 0.92 if facing > 0.0 else 5.36, 20, telegraph_color, 3.0)
        draw_line(Vector2(facing * 18.0, -27.0), Vector2(facing * 53.0, -34.0), telegraph_color, 2.0)
    draw_string(ThemeDB.fallback_font, Vector2(-48.0, -94.0), "CULTIST %d" % max(0, health), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#c7afa8"))


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
