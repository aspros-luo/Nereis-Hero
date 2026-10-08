extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")
const SLASH_ARC_SCRIPT = preload("res://scripts/effects/slash_arc.gd")
const DEATH_BURST_SCRIPT = preload("res://scripts/effects/death_burst.gd")
const HERO_SYSTEM_SCRIPT = preload("res://scripts/player/hero_system.gd")

const SPEED := 260.0
const ATTACK_MOVE_SPEED := 92.0
const JUMP_VELOCITY := -520.0
const GRAVITY := 1400.0
const DODGE_SPEED := 620.0
const ATTACK_DURATION := 0.34
const ATTACK_WINDUP := 0.07
const DODGE_DURATION := 0.18
const COYOTE_TIME := 0.10
const JUMP_BUFFER_TIME := 0.12
const COMBO_RESET_TIME := 0.42
const MAX_STAMINA := 100.0
const ATTACK_STAMINA_COST := 12.0
const DODGE_STAMINA_COST := 28.0
const STAMINA_REGEN_DELAY := 0.65
const STAMINA_REGEN_RATE := 42.0
const HURT_DURATION := 0.18
const HURT_KNOCKBACK := 180.0
const COMBO_DAMAGE_MULTIPLIERS := [1.0, 1.18, 1.5]
const COMBO_REACH := [54.0, 58.0, 64.0]

enum CombatState { IDLE, MOVE, JUMP, FALL, ATTACK, DODGE, HURT, DEAD }

var health := 100
var facing := 1.0
var attack_time := 0.0
var attack_windup := 0.0
var attack_hit_registered := false
var combo_step := 0
var combo_window := 0.0
var dodge_time := 0.0
var invulnerable := false
var stamina := MAX_STAMINA
var stamina_regen_delay := 0.0
var hurt_time := 0.0
var coyote_time := 0.0
var jump_buffer := 0.0
var camera_shake_time := 0.0
var camera_shake_strength := 0.0
var hit_confirm_time := 0.0
var state := CombatState.IDLE
var hero_system: Node
var previous_state := CombatState.IDLE
var animation_time := 0.0
var attack_hitbox: Area2D
var attack_requested := false
var dodge_requested := false
var jump_requested := false
signal defeated
signal attack_started(combo_step: int)
signal dodge_started
signal attack_landed(damage: int, target: Node)

func _input(event: InputEvent) -> void:
    if WorldState.input_locked:
        return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_J:
            attack_requested = true
        elif event.keycode == KEY_K or event.keycode == KEY_SHIFT:
            dodge_requested = true
        elif event.keycode == KEY_SPACE or event.keycode == KEY_UP:
            jump_requested = true
        elif event.keycode == KEY_Q:
            if hero_system and state not in [CombatState.ATTACK, CombatState.DODGE, CombatState.HURT]:
                hero_system.switch_weapon()
                queue_redraw()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        attack_requested = true

func _ready() -> void:
    hero_system = HERO_SYSTEM_SCRIPT.new()
    hero_system.name = "HeroSystem"
    add_child(hero_system)
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

func _process(delta: float) -> void:
    animation_time += delta
    queue_redraw()

func _physics_process(delta: float) -> void:
    if state == CombatState.DEAD:
        return

    _update_camera_shake(delta)
    hit_confirm_time = max(0.0, hit_confirm_time - delta)
    _update_jump_buffer(delta)
    _update_combo_window(delta)

    if is_on_floor():
        coyote_time = COYOTE_TIME
    else:
        coyote_time = max(0.0, coyote_time - delta)

    if WorldState.input_locked:
        attack_requested = false
        dodge_requested = false
        jump_requested = false
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
        attack_windup = max(0.0, attack_windup - delta)
        if attack_windup <= 0.0 and not attack_hit_registered:
            var base_damage := float(WorldState.hero_attack_damage)
            var multiplier: float = COMBO_DAMAGE_MULTIPLIERS[combo_step - 1]
            if hero_system and hero_system.is_short_blade():
                multiplier *= hero_system.get_weapon_damage_multiplier()
            var damage := int(round(base_damage * multiplier))
            var reach: float = COMBO_REACH[combo_step - 1]
            if hero_system:
                reach = hero_system.get_weapon_reach()
            attack_hitbox.position.x = facing * reach
            attack_hitbox.activate(damage, 0.11 if combo_step < 3 else 0.14)
            _spawn_slash_arc()
            attack_hit_registered = true
            _log("COMBAT", "Hero combo %d hit window; damage=%d" % [combo_step, damage])
        if attack_time <= 0.0:
            attack_hit_registered = false

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
        var move_speed := ATTACK_MOVE_SPEED if attack_time > 0.0 else SPEED
        velocity.x = move_toward(velocity.x, direction * move_speed, 2200.0 * delta)
    else:
        var friction := 1250.0 if attack_time > 0.0 else 2200.0
        velocity.x = move_toward(velocity.x, 0.0, friction * delta)

    if jump_buffer > 0.0 and coyote_time > 0.0 and attack_time <= 0.0 and dodge_time <= 0.0:
        jump_buffer = 0.0
        coyote_time = 0.0
        velocity.y = JUMP_VELOCITY
        _set_state(CombatState.JUMP)

    if attack_requested and attack_time <= 0.0 and dodge_time <= 0.0:
        attack_requested = false
        _perform_attack()

    if dodge_requested and dodge_time <= 0.0 and attack_time <= 0.0:
        dodge_requested = false
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

func _update_jump_buffer(delta: float) -> void:
    if jump_requested or Input.is_action_just_pressed("ui_accept"):
        jump_requested = false
        jump_buffer = JUMP_BUFFER_TIME
    elif jump_buffer > 0.0:
        jump_buffer = max(0.0, jump_buffer - delta)

func _update_combo_window(delta: float) -> void:
    if combo_window > 0.0:
        combo_window = max(0.0, combo_window - delta)
    elif combo_step != 0:
        combo_step = 0

func _perform_attack() -> void:
    var stamina_cost := ATTACK_STAMINA_COST
    if hero_system:
        stamina_cost *= hero_system.get_weapon_stamina_modifier()
    if stamina < stamina_cost:
        return
    stamina -= stamina_cost
    stamina_regen_delay = STAMINA_REGEN_DELAY

    if combo_window > 0.0:
        combo_step = min(3, combo_step + 1)
    else:
        combo_step = 1
    combo_window = COMBO_RESET_TIME

    attack_time = ATTACK_DURATION
    attack_windup = ATTACK_WINDUP
    attack_hit_registered = false
    attack_hitbox.position.x = facing * float(COMBO_REACH[combo_step - 1])

    _set_state(CombatState.ATTACK)
    attack_started.emit(combo_step)
    _log("COMBAT", "Hero attack %d started; windup=%.2f" % [combo_step, ATTACK_WINDUP])

func _start_dodge() -> void:
    if stamina < DODGE_STAMINA_COST:
        return
    stamina -= DODGE_STAMINA_COST
    stamina_regen_delay = STAMINA_REGEN_DELAY
    dodge_time = DODGE_DURATION
    invulnerable = true
    _set_state(CombatState.DODGE)
    dodge_started.emit()
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

func _spawn_slash_arc() -> void:
    var effect: Node2D = SLASH_ARC_SCRIPT.new()
    effect.global_position = global_position
    get_parent().add_child(effect)
    effect.call("setup", facing, combo_step)

func _spawn_hit_spark() -> void:
    var effect := Node2D.new()
    effect.set_script(HIT_SPARK_SCRIPT)
    effect.global_position = global_position + Vector2(0, -34)
    get_parent().add_child(effect)

func _spawn_death_burst() -> void:
    var effect: Node2D = DEATH_BURST_SCRIPT.new()
    effect.global_position = global_position + Vector2(0, -38)
    get_parent().add_child(effect)
    effect.call("setup", 18.0)

func _on_attack_hit(damage: int, target: Node) -> void:
    hit_confirm_time = 0.07
    var impact_strength: float = 4.0 + float(combo_step) * 1.4
    var hitstop_duration: float = 0.055 if combo_step >= 3 else 0.038
    var hitstop_scale: float = 0.06 if combo_step >= 3 else 0.08
    WorldState.trigger_hitstop(hitstop_duration, hitstop_scale)
    _shake_camera(impact_strength, 0.08)
    velocity.x = facing * (170.0 if combo_step >= 3 else 145.0)
    attack_landed.emit(damage, target)
    _log("COMBAT", "Attack confirmed; damage=%d target=%s" % [damage, target.name if target else "Unknown"])

func _shake_camera(strength: float, duration: float) -> void:
    camera_shake_strength = max(camera_shake_strength, strength)
    camera_shake_time = max(camera_shake_time, duration)

func _update_camera_shake(delta: float) -> void:
    var camera := get_viewport().get_camera_2d()
    if not camera:
        return
    if camera_shake_time > 0.0:
        camera_shake_time = max(0.0, camera_shake_time - delta)
        var fade: float = clampf(camera_shake_time / 0.10, 0.0, 1.0)
        camera.offset = Vector2(
            randf_range(-camera_shake_strength, camera_shake_strength) * fade,
            randf_range(-camera_shake_strength, camera_shake_strength) * fade * 0.65
        )
    else:
        camera.offset = Vector2.ZERO
        camera_shake_strength = 0.0

func receive_damage(amount: int, source: Node = null) -> void:
    if invulnerable or state == CombatState.DEAD:
        _log("COMBAT", "Hero damage ignored (invulnerable=%s)" % invulnerable)
        return
    health = max(0, health - amount)
    _spawn_hit_spark()
    WorldState.trigger_hitstop(0.032, 0.10)
    _shake_camera(9.0, 0.12)
    hurt_time = HURT_DURATION
    velocity.y = -120.0
    if source and source is Node2D:
        velocity.x = sign(global_position.x - source.global_position.x) * HURT_KNOCKBACK
    else:
        velocity.x = -facing * HURT_KNOCKBACK
    _set_state(CombatState.HURT)
    var source_name: String = source.name if source else "Unknown"
    _log("COMBAT", "%s -> Hero damage=%d hp=%d" % [source_name, amount, health])
    if health == 0:
        _set_state(CombatState.DEAD)
        _spawn_death_burst()
        _log("HERO", "Hero defeated; resetting vertical slice")
        defeated.emit()
        health = 100
        global_position = WorldState.checkpoint_position
        velocity = Vector2.ZERO
        invulnerable = true
        stamina = MAX_STAMINA
        combo_step = 0
        combo_window = 0.0
        attack_requested = false
        dodge_requested = false
        jump_requested = false
        _log("WORLD", "Hero respawned at checkpoint=%s" % WorldState.checkpoint_position)
        get_tree().create_timer(0.75).timeout.connect(_clear_respawn_invulnerability)
        _set_state(CombatState.IDLE)

func restore_full() -> void:
    health = 100
    stamina = MAX_STAMINA
    hurt_time = 0.0
    velocity = Vector2.ZERO
    invulnerable = false
    combo_step = 0
    combo_window = 0.0
    attack_requested = false
    dodge_requested = false
    jump_requested = false
    _log("HERO", "Hero fully restored at rest point")

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func _clear_respawn_invulnerability() -> void:
    invulnerable = false
    _log("HERO", "Respawn invulnerability ended")

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
    var bob: float = sin(animation_time * 7.0) * 1.5 if state == CombatState.IDLE else 0.0
    var step: float = sin(animation_time * 11.0) * 2.0 if state == CombatState.MOVE else 0.0
    var body := Color("#d0bea4")
    var armor := Color("#3d3740")
    var cloak := Color("#252129")
    var metal := Color("#b7a48c")

    draw_circle(Vector2(0, -52 + bob), 18, body)
    draw_circle(Vector2(facing * 5.0, -54 + bob), 6, Color("#19171c"))
    draw_rect(Rect2(-18, -35 + bob, 36, 35), armor)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-19, -32 + bob), Vector2(19, -32 + bob),
        Vector2(27, 10 + step), Vector2(-30, 10 - step)
    ]), cloak)
    draw_line(Vector2(-12, -3 + bob), Vector2(-22, 18 + step), armor, 7.0)
    draw_line(Vector2(12, -3 + bob), Vector2(22, 18 - step), armor, 7.0)
    var blade_length := 58.0
    var blade_width := 7.0
    if hero_system and hero_system.is_short_blade():
        blade_length = 38.0
        blade_width = 5.0
    draw_line(Vector2(0, -8 + bob), Vector2(facing * blade_length, -22 + bob), metal, blade_width)

    if WorldState.hidden_resistance_awakened:
        var anchor_color := Color("#aa8d72") if WorldState.mite_control_stage < 2 else Color("#8d6c98")
        draw_circle(Vector2(-13, -1 + bob), 4.0, Color(0.75, 0.66, 0.55, 0.32))
        draw_arc(Vector2(-13, -1 + bob), 7.0, 0.0, TAU, 16, anchor_color, 2.0)
    var edge_length := 47.0 if not hero_system or hero_system.is_long_sword() else 33.0
    draw_line(Vector2(facing * 28, -23 + bob), Vector2(facing * edge_length, -30 + bob), Color("#e0d6c3"), 3.0)
    if hit_confirm_time > 0.0:
        draw_arc(Vector2(facing * 28, -24), 70.0, 0.0, TAU, 24, Color("#efe1c8"), 6.0)
    elif attack_time > 0.0 and attack_windup <= 0.0:
        var arc_start := -1.20 if facing > 0 else 1.20
        var arc_end := 1.20 if facing > 0 else 5.08
        var arc_radius := 64.0 + combo_step * 3.0
        draw_arc(Vector2(facing * 26, -24), arc_radius, arc_start, arc_end, 20, Color("#d9d0bf"), 5.0)
    elif attack_time > 0.0:
        draw_arc(Vector2(facing * 25, -24), 42.0, -0.45 if facing > 0 else 3.59, 0.45 if facing > 0 else 4.49, 12, Color("#9e8b72"), 3.0)
    # No gameplay numbers are rendered above the Hero.
    # HP/stamina are presented only through the HUD bars.
