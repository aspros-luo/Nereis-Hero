extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")

const SPEED := 260.0
const JUMP_VELOCITY := -520.0
const GRAVITY := 1400.0
const DODGE_SPEED := 620.0
const ATTACK_DURATION := 0.28
const DODGE_DURATION := 0.18
const MAX_STAMINA := 100.0
const ATTACK_STAMINA_COST := 12.0
const DODGE_STAMINA_COST := 28.0
const STAMINA_REGEN_DELAY := 0.65
const STAMINA_REGEN_RATE := 42.0
const HURT_DURATION := 0.18
const HURT_KNOCKBACK := 180.0

enum CombatState { IDLE, MOVE, JUMP, FALL, ATTACK, DODGE, HURT, DEAD }

var health := 100
var facing := 1.0
var attack_time := 0.0
var dodge_time := 0.0
var invulnerable := false
var stamina := MAX_STAMINA
var stamina_regen_delay := 0.0
var hurt_time := 0.0
var state := CombatState.IDLE
var previous_state := CombatState.IDLE
var attack_hitbox: Area2D
signal defeated

func _ready() -> void:
    _setup_combat_components()
    _log("BOOT", "Hero initialized")
    queue_redraw()

func _setup_combat_components() -> void:
    attack_hitbox = Area2D.new()
    attack_hitbox.name = "AttackHitbox"
    attack_hitbox.set_script(HITBOX_SCRIPT)
    add_child(attack_hitbox)
    attack_hitbox.setup(self, Vector2(105, 64), Vector2(facing * 54.0, -28.0))

    var hurtbox := Area2D.new()
    hurtbox.name = "Hurtbox"
    hurtbox.set_script(HURTBOX_SCRIPT)
    add_child(hurtbox)
    hurtbox.setup(self, Vector2(34, 78), Vector2(0, -34))

func _physics_process(delta: float) -> void:
    if state == CombatState.DEAD:
        return

    if WorldState.input_locked:
        velocity.x = move_toward(velocity.x, 0.0, 2200.0 * delta)
        if not is_on_floor():
            velocity.y += GRAVITY * delta
        move_and_slide()
        queue_redraw()
        return

    if hurt_time > 0.0:
        hurt_time = max(0.0, hurt_time - delta)
        if not is_on_floor():
            velocity.y += GRAVITY * delta
        move_and_slide()
        if hurt_time <= 0.0:
            _set_state(CombatState.IDLE)
        queue_redraw()
        return

    if stamina_regen_delay > 0.0:
        stamina_regen_delay = max(0.0, stamina_regen_delay - delta)
    elif stamina < MAX_STAMINA:
        stamina = min(MAX_STAMINA, stamina + STAMINA_REGEN_RATE * delta)

    if attack_time > 0.0:
        attack_time = max(0.0, attack_time - delta)

    if dodge_time > 0.0:
        dodge_time = max(0.0, dodge_time - delta)
        velocity.x = facing * DODGE_SPEED
        _set_state(CombatState.DODGE)
        move_and_slide()
        queue_redraw()
        return
    elif invulnerable:
        invulnerable = false
        _log("HERO", "Dodge ended; invulnerable=false")

    if not is_on_floor():
        velocity.y += GRAVITY * delta

    var direction := Input.get_axis("ui_left", "ui_right")
    if Input.is_key_pressed(KEY_A):
        direction = -1.0
    elif Input.is_key_pressed(KEY_D):
        direction = 1.0

    if direction != 0.0:
        facing = sign(direction)
        velocity.x = move_toward(velocity.x, direction * SPEED, 1800.0 * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, 2200.0 * delta)

    if (Input.is_key_pressed(KEY_SPACE) or Input.is_action_just_pressed("ui_accept")) and is_on_floor():
        velocity.y = JUMP_VELOCITY
        _set_state(CombatState.JUMP)

    if (Input.is_key_pressed(KEY_J) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and attack_time <= 0.0:
        _perform_attack()

    if (Input.is_key_pressed(KEY_K) or Input.is_key_pressed(KEY_SHIFT)) and dodge_time <= 0.0:
        _start_dodge()

    move_and_slide()

    if not is_on_floor():
        _set_state(CombatState.JUMP if velocity.y < 0.0 else CombatState.FALL)
    elif attack_time > 0.0:
        _set_state(CombatState.ATTACK)
    elif abs(velocity.x) > 10.0:
        _set_state(CombatState.MOVE)
    else:
        _set_state(CombatState.IDLE)

    queue_redraw()

func _perform_attack() -> void:
    if stamina < ATTACK_STAMINA_COST:
        return
    stamina -= ATTACK_STAMINA_COST
    stamina_regen_delay = STAMINA_REGEN_DELAY
    attack_time = ATTACK_DURATION
    attack_hitbox.position.x = facing * 54.0
    attack_hitbox.activate(WorldState.hero_attack_damage, 0.12)
    _set_state(CombatState.ATTACK)
    _log("COMBAT", "Hero attack started; damage=%d hitbox active" % WorldState.hero_attack_damage)

func _start_dodge() -> void:
    if stamina < DODGE_STAMINA_COST:
        return
    stamina -= DODGE_STAMINA_COST
    stamina_regen_delay = STAMINA_REGEN_DELAY
    dodge_time = DODGE_DURATION
    invulnerable = true
    _set_state(CombatState.DODGE)
    _log("HERO", "Dodge started; invulnerable=true")

func _set_state(next_state: CombatState) -> void:
    if state == next_state:
        return
    previous_state = state
    state = next_state
    _log("STATE", "%s -> %s" % [_state_name(previous_state), _state_name(state)])

func _state_name(value: CombatState) -> String:
    return CombatState.keys()[value]

func get_debug_state() -> String:
    return _state_name(state)

func _spawn_hit_spark() -> void:
    var effect := Node2D.new()
    effect.set_script(HIT_SPARK_SCRIPT)
    effect.global_position = global_position + Vector2(0, -34)
    get_parent().add_child(effect)

func receive_damage(amount: int, source: Node = null) -> void:
    if invulnerable or state == CombatState.DEAD:
        _log("COMBAT", "Hero damage ignored (invulnerable=%s)" % invulnerable)
        return
    health = max(0, health - amount)
    _spawn_hit_spark()
    hurt_time = HURT_DURATION
    velocity.y = -120.0
    if source and source is Node2D:
        velocity.x = sign(global_position.x - source.global_position.x) * HURT_KNOCKBACK
    else:
        velocity.x = -facing * HURT_KNOCKBACK
    _set_state(CombatState.HURT)
    var source_name := source.name if source else "Unknown"
    _log("COMBAT", "%s -> Hero damage=%d hp=%d" % [source_name, amount, health])
    if health == 0:
        _set_state(CombatState.DEAD)
        _log("HERO", "Hero defeated; resetting vertical slice")
        defeated.emit()
        health = 100
        global_position = WorldState.checkpoint_position
        velocity = Vector2.ZERO
        invulnerable = true
        _log("WORLD", "Hero respawned at checkpoint=%s" % WorldState.checkpoint_position)
        get_tree().create_timer(0.75).timeout.connect(_clear_respawn_invulnerability)
        _set_state(CombatState.IDLE)

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func _clear_respawn_invulnerability() -> void:
    invulnerable = false
    _log("HERO", "Respawn invulnerability ended")

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
    var body := Color("#c8b59b")
    var cloak := Color("#433a42")
    draw_circle(Vector2(0, -52), 18, body)
    draw_rect(Rect2(-18, -34, 36, 34), cloak)
    draw_line(Vector2(0, -8), Vector2(facing * 58, -22), Color("#b7a48c"), 7.0)
    if attack_time > 0.0:
        draw_arc(Vector2(facing * 26, -24), 64, -1.2 if facing > 0 else 1.2, 1.2 if facing > 0 else 5.2, 20, Color("#d9d0bf"), 5.0)
    draw_string(ThemeDB.fallback_font, Vector2(-52, -82), "HERO %d" % health, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d6c7b2"))
    draw_rect(Rect2(-32, -96, 64, 5), Color("#27212a"))
    draw_rect(Rect2(-32, -96, 64.0 * (stamina / MAX_STAMINA), 5), Color("#9e8b72"))
