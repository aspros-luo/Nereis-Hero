extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")

const SPEED := 260.0
const JUMP_VELOCITY := -520.0
const GRAVITY := 1400.0
const DODGE_SPEED := 620.0
const ATTACK_DURATION := 0.28
const DODGE_DURATION := 0.18

enum CombatState { IDLE, MOVE, JUMP, FALL, ATTACK, DODGE, HURT, DEAD }

var health := 100
var facing := 1.0
var attack_time := 0.0
var dodge_time := 0.0
var invulnerable := false
var state := CombatState.IDLE
var previous_state := CombatState.IDLE
var attack_hitbox: Area2D

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
    attack_time = ATTACK_DURATION
    attack_hitbox.position.x = facing * 54.0
    attack_hitbox.activate(34, 0.12)
    _set_state(CombatState.ATTACK)
    _log("COMBAT", "Hero attack started; hitbox active")

func _start_dodge() -> void:
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

func receive_damage(amount: int, source: Node = null) -> void:
    if invulnerable or state == CombatState.DEAD:
        _log("COMBAT", "Hero damage ignored (invulnerable=%s)" % invulnerable)
        return
    health = max(0, health - amount)
    _set_state(CombatState.HURT)
    var source_name := source.name if source else "Unknown"
    _log("COMBAT", "%s -> Hero damage=%d hp=%d" % [source_name, amount, health])
    if health == 0:
        _set_state(CombatState.DEAD)
        _log("HERO", "Hero defeated; resetting vertical slice")
        health = 100
        global_position = Vector2(320, 480)
        velocity = Vector2.ZERO
        invulnerable = false
        _set_state(CombatState.IDLE)

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
    var body := Color("#c8b59b")
    var cloak := Color("#433a42")
    draw_circle(Vector2(0, -52), 18, body)
    draw_rect(Rect2(-18, -34, 36, 60), cloak)
    draw_line(Vector2(0, -8), Vector2(facing * 58, -22), Color("#b7a48c"), 7.0)
    if attack_time > 0.0:
        draw_arc(Vector2(facing * 26, -24), 64, -1.2 if facing > 0 else 1.2, 1.2 if facing > 0 else 5.2, 20, Color("#d9d0bf"), 5.0)
    draw_string(ThemeDB.fallback_font, Vector2(-52, -82), "HERO %d" % health, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d6c7b2"))
