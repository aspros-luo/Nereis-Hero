extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")
const SLASH_ARC_SCRIPT = preload("res://scripts/effects/slash_arc.gd")
const DEATH_BURST_SCRIPT = preload("res://scripts/effects/death_burst.gd")
const HERO_SYSTEM_SCRIPT = preload("res://scripts/player/hero_system.gd")
const ECHO_PULSE_SCRIPT = preload("res://scripts/effects/echo_pulse.gd")
const HERO_LONG_ART: Texture2D = preload("res://assets/art/characters/hero_knight.svg")
const HERO_SHORT_ART: Texture2D = preload("res://assets/art/characters/hero_short_blade.svg")

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
const IAIJUTSU_STAMINA_COST := 26.0
const IAIJUTSU_HEALTH_COST := 8
const IAIJUTSU_DAMAGE_MULTIPLIER := 2.2
const IAIJUTSU_REACH := 124.0

# Weapon-bound special techniques. These are initial tuning values, not final balance.
# 武器绑定战技：以下数值是首轮调试基准，不是最终平衡结果。
const JUDGMENT_STAMINA_COST := 20.0
const JUDGMENT_DAMAGE_MULTIPLIER := 1.6
const JUDGMENT_WINDUP := 0.35
const JUDGMENT_DURATION := 0.70
const JUDGMENT_REACH := 66.0
const JUDGMENT_HITBOX_SIZE := Vector2(86.0, 54.0)
const JUDGMENT_HIT_DURATION := 0.14
const CRESCENT_STAMINA_COST := 16.0
const CRESCENT_DAMAGE_MULTIPLIER := 0.65
const CRESCENT_DURATION := 0.56
const CRESCENT_HIT_TIMES := [0.08, 0.23, 0.38]
const CRESCENT_REACH := [35.0, 38.0, 42.0]
const CRESCENT_HITBOX_WIDTHS := [54.0, 58.0, 62.0]
const CRESCENT_HIT_DURATION := 0.065
const ECHO_STAMINA_COST := 28.0
const ECHO_COOLDOWN := 8.0
const ECHO_WINDUP := 0.16
const ECHO_DURATION := 0.42
const ECHO_RANGE := 185.0
const ECHO_STAGGER_DURATION := 0.32

enum CombatState { IDLE, MOVE, JUMP, FALL, ATTACK, DODGE, HURT, DEAD }

var health := 100
var facing := 1.0
var attack_time := 0.0
var attack_windup := 0.0
var attack_hit_registered := false
var combo_step := 0
var combo_window := 0.0
var dodge_time := 0.0
# A short opening at dodge start rewards precise timing without adding another resource.
# 闪避起始的短窗口奖励精准操作，不额外引入资源条。
const PERFECT_DODGE_WINDOW := 0.075
const RIPOSTE_BONUS_MULTIPLIER := 1.35
var perfect_dodge_window_remaining := 0.0
var riposte_bonus_active := false
var invulnerable := false
var stamina := MAX_STAMINA
var stamina_regen_delay := 0.0
var hurt_time := 0.0
var coyote_time := 0.0
var jump_buffer := 0.0
# Counts only extra mid-air jumps; the ordinary ground/coyote jump is always available.
# 只记录额外空中跳跃次数；地面跳与土狼时间跳始终可用。
var air_jumps_used := 0
const MAX_EXTRA_AIR_JUMPS := 1
var camera_shake_time := 0.0
var camera_shake_strength := 0.0
var hit_confirm_time := 0.0
var state := CombatState.IDLE
var previous_state := CombatState.IDLE
var animation_time := 0.0
var attack_hitbox: Area2D
var attack_requested := false
var technique_requested := false # Legacy iaijutsu prototype input; retained during migration.
var weapon_technique_requested := false
var eldritch_requested := false
var iaijutsu_active := false
var active_action_kind := "none"
var action_elapsed := 0.0
var technique_hit_index := 0
var eldritch_cooldown_remaining := 0.0
var debug_ability_override := false
# Debug overlay is enabled by default on this development branch for acceptance testing.
# 当前开发分支默认开启调试覆盖层，便于验收；F3 可显示/隐藏。
var debug_mode_enabled := true
var dodge_requested := false
var jump_requested := false
var hero_system: Node
signal defeated
signal attack_started(combo_step: int)
signal dodge_started
signal attack_landed(damage: int, target: Node)

func _input(event: InputEvent) -> void:
    if WorldState.input_locked or WorldState.menu_input_locked:
        return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_F3:
            debug_mode_enabled = not debug_mode_enabled
            queue_redraw()
            _log("DEBUG", "Overlay %s" % ("ON" if debug_mode_enabled else "OFF"))
        elif event.keycode == KEY_F4 and event.ctrl_pressed:
            toggle_debug_ability_override()
        elif event.keycode == KEY_F5 and event.ctrl_pressed:
            debug_refill_combat_resources()
        elif event.keycode == KEY_J:
            attack_requested = true
        elif event.keycode == KEY_L:
            technique_requested = true
        elif event.keycode == KEY_F:
            if state not in [CombatState.ATTACK, CombatState.DODGE, CombatState.HURT, CombatState.DEAD] and attack_time <= 0.0 and dodge_time <= 0.0:
                weapon_technique_requested = true
        elif event.keycode == KEY_R:
            if state not in [CombatState.ATTACK, CombatState.DODGE, CombatState.HURT, CombatState.DEAD] and attack_time <= 0.0 and dodge_time <= 0.0:
                eldritch_requested = true
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
    attack_hitbox.setup(self, Vector2(66, 48), Vector2(facing * 48.0, -28.0))

    var hurtbox := Area2D.new()
    hurtbox.name = "Hurtbox"
    hurtbox.set_script(HURTBOX_SCRIPT)
    add_child(hurtbox)
    hurtbox.setup(self, Vector2(34, 78), Vector2(0, -34))

func _process(delta: float) -> void:
    animation_time += delta
    # Physics updates already request redraws. Avoid issuing a second redraw every rendered frame.

func _physics_process(delta: float) -> void:
    if state == CombatState.DEAD:
        return

    _update_camera_shake(delta)
    hit_confirm_time = max(0.0, hit_confirm_time - delta)
    eldritch_cooldown_remaining = maxf(0.0, eldritch_cooldown_remaining - delta)
    _update_jump_buffer(delta)
    _update_combo_window(delta)

    if is_on_floor():
        coyote_time = COYOTE_TIME
        air_jumps_used = 0
    else:
        coyote_time = max(0.0, coyote_time - delta)

    if WorldState.input_locked:
        attack_requested = false
        technique_requested = false
        weapon_technique_requested = false
        eldritch_requested = false
        dodge_requested = false
        jump_requested = false
        _cancel_attack_action()
        dodge_time = 0.0
        invulnerable = false
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

    if WorldState.menu_input_locked:
        # Ignore any action queued before the menu opened; ongoing attacks and enemy actions still resolve.
        attack_requested = false
        technique_requested = false
        weapon_technique_requested = false
        eldritch_requested = false
        dodge_requested = false
        jump_requested = false
        jump_buffer = 0.0

    if stamina_regen_delay > 0.0:
        stamina_regen_delay = max(0.0, stamina_regen_delay - delta)
    elif stamina < MAX_STAMINA:
        stamina = min(MAX_STAMINA, stamina + STAMINA_REGEN_RATE * delta)

    if attack_time > 0.0:
        attack_time = max(0.0, attack_time - delta)
        attack_windup = max(0.0, attack_windup - delta)
        action_elapsed += delta
        match active_action_kind:
            "judgment_slash":
                if attack_windup <= 0.0 and not attack_hit_registered:
                    _release_judgment_slash()
                    attack_hit_registered = true
            "crescent_combo":
                _update_crescent_combo()
            "eldritch_echo":
                if attack_windup <= 0.0 and not attack_hit_registered:
                    _release_eldritch_echo()
                    attack_hit_registered = true
            _:
                if attack_windup <= 0.0 and not attack_hit_registered:
                    var base_damage := float(WorldState.hero_attack_damage)
                    var multiplier: float = hero_system.get_combo_damage_multiplier(combo_step) if hero_system else 1.0
                    var iaijutsu_profile: Dictionary = hero_system.get_iaijutsu_profile() if hero_system and iaijutsu_active else {}
                    if iaijutsu_active:
                        multiplier = float(iaijutsu_profile.get("damage_multiplier", IAIJUTSU_DAMAGE_MULTIPLIER))
                    var damage_multiplier := multiplier
                    if riposte_bonus_active:
                        damage_multiplier *= RIPOSTE_BONUS_MULTIPLIER
                    var damage := int(round(base_damage * damage_multiplier))
                    if riposte_bonus_active:
                        riposte_bonus_active = false
                        _log("COMBAT", "Perfect-dodge riposte consumed")
                    var reach: float = hero_system.get_weapon_reach(combo_step) if hero_system and not iaijutsu_active else float(iaijutsu_profile.get("reach", IAIJUTSU_REACH))
                    var shape_size: Vector2 = hero_system.get_weapon_hitbox_size(combo_step) if hero_system and not iaijutsu_active else iaijutsu_profile.get("hitbox_size", Vector2(152, 58))
                    attack_hitbox.position.x = facing * reach
                    attack_hitbox.set_shape_size(shape_size)
                    var hit_duration: float = hero_system.get_hit_window_duration(combo_step) if hero_system and not iaijutsu_active else float(iaijutsu_profile.get("hit_duration", 0.16))
                    attack_hitbox.activate(damage, hit_duration)
                    _spawn_slash_arc()
                    attack_hit_registered = true
                    _log("COMBAT", "Hero attack hit window; damage=%d" % damage)
        if attack_time <= 0.0:
            attack_hit_registered = false
            iaijutsu_active = false
            active_action_kind = "none"
            action_elapsed = 0.0
            technique_hit_index = 0

    if perfect_dodge_window_remaining > 0.0:
        perfect_dodge_window_remaining = maxf(0.0, perfect_dodge_window_remaining - delta)

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

    var direction := 0.0 if WorldState.menu_input_locked else Input.get_axis("ui_left", "ui_right")
    if not WorldState.menu_input_locked:
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

    var can_ground_or_coyote_jump := coyote_time > 0.0
    var can_unlocked_double_jump := WorldState.is_ability_unlocked("double_jump") and air_jumps_used < MAX_EXTRA_AIR_JUMPS and not can_ground_or_coyote_jump
    if jump_buffer > 0.0 and (can_ground_or_coyote_jump or can_unlocked_double_jump) and attack_time <= 0.0 and dodge_time <= 0.0:
        jump_buffer = 0.0
        if can_unlocked_double_jump:
            air_jumps_used += 1
            _log("MOVEMENT", "Double jump used; extra_jumps=%d/%d" % [air_jumps_used, MAX_EXTRA_AIR_JUMPS])
        coyote_time = 0.0
        velocity.y = JUMP_VELOCITY
        _set_state(CombatState.JUMP)

    if weapon_technique_requested and attack_time <= 0.0 and dodge_time <= 0.0:
        weapon_technique_requested = false
        _perform_weapon_technique()
    if eldritch_requested and attack_time <= 0.0 and dodge_time <= 0.0:
        eldritch_requested = false
        _perform_eldritch_echo()
    if technique_requested and attack_time <= 0.0 and dodge_time <= 0.0:
        technique_requested = false
        _perform_iaijutsu()
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
        combo_step = mini(hero_system.get_combo_limit() if hero_system else 3, combo_step + 1)
    else:
        combo_step = 1
    combo_window = hero_system.get_combo_reset_time() if hero_system else 0.42
    if hero_system:
        combo_step = mini(combo_step, hero_system.get_combo_limit())

    iaijutsu_active = false
    active_action_kind = "basic"
    action_elapsed = 0.0
    technique_hit_index = 0
    attack_time = hero_system.get_attack_duration() if hero_system else 0.34
    attack_windup = hero_system.get_attack_windup() if hero_system else 0.07
    attack_hit_registered = false
    if hero_system:
        attack_hitbox.position.x = facing * hero_system.get_weapon_reach(combo_step)
        attack_hitbox.set_shape_size(hero_system.get_weapon_hitbox_size(combo_step))

    _set_state(CombatState.ATTACK)
    attack_started.emit(combo_step)
    _log("COMBAT", "Hero attack %d started; windup=%.2f" % [combo_step, attack_windup])

func _perform_weapon_technique() -> void:
    if not hero_system:
        return
    var technique_id: String = hero_system.get_weapon_technique_id()
    if not hero_system.can_use_technique(technique_id, debug_ability_override):
        _log("TECHNIQUE", "Weapon technique locked: %s" % technique_id)
        return

    var stamina_cost := CRESCENT_STAMINA_COST if technique_id == "technique_crescent_combo" else JUDGMENT_STAMINA_COST
    if stamina < stamina_cost:
        _log("TECHNIQUE", "Insufficient stamina for %s" % technique_id)
        return

    stamina -= stamina_cost
    stamina_regen_delay = STAMINA_REGEN_DELAY
    combo_step = 1
    combo_window = 0.0
    iaijutsu_active = false
    active_action_kind = "crescent_combo" if technique_id == "technique_crescent_combo" else "judgment_slash"
    action_elapsed = 0.0
    technique_hit_index = 0
    attack_hit_registered = false
    attack_time = CRESCENT_DURATION if active_action_kind == "crescent_combo" else JUDGMENT_DURATION
    attack_windup = 0.0 if active_action_kind == "crescent_combo" else JUDGMENT_WINDUP
    _set_state(CombatState.ATTACK)
    _log("TECHNIQUE", "Started %s; stamina=%.0f" % [technique_id, stamina_cost])

func _release_judgment_slash() -> void:
    var multiplier := JUDGMENT_DAMAGE_MULTIPLIER
    if riposte_bonus_active:
        multiplier *= RIPOSTE_BONUS_MULTIPLIER
        riposte_bonus_active = false
        _log("COMBAT", "Perfect-dodge riposte consumed by Judgment Slash")
    var damage := int(round(float(WorldState.hero_attack_damage) * multiplier))
    attack_hitbox.position.x = facing * JUDGMENT_REACH
    attack_hitbox.set_shape_size(JUDGMENT_HITBOX_SIZE)
    attack_hitbox.activate(damage, JUDGMENT_HIT_DURATION)
    _spawn_technique_arc("technique_judgment_slash", 0)
    _log("TECHNIQUE", "Judgment Slash released; damage=%d" % damage)

func _update_crescent_combo() -> void:
    while technique_hit_index < CRESCENT_HIT_TIMES.size() and action_elapsed >= float(CRESCENT_HIT_TIMES[technique_hit_index]):
        _release_crescent_hit(technique_hit_index)
        technique_hit_index += 1

func _release_crescent_hit(stage_index: int) -> void:
    var stage := clampi(stage_index, 0, 2)
    combo_step = stage + 1
    var multiplier := CRESCENT_DAMAGE_MULTIPLIER
    if riposte_bonus_active:
        multiplier *= RIPOSTE_BONUS_MULTIPLIER
        riposte_bonus_active = false
        _log("COMBAT", "Perfect-dodge riposte consumed by Crescent Combo")
    var damage := int(round(float(WorldState.hero_attack_damage) * multiplier))
    attack_hitbox.position.x = facing * float(CRESCENT_REACH[stage])
    attack_hitbox.set_shape_size(Vector2(float(CRESCENT_HITBOX_WIDTHS[stage]), 36.0))
    attack_hitbox.activate(damage, CRESCENT_HIT_DURATION)
    _spawn_technique_arc("technique_crescent_combo", stage)
    _log("TECHNIQUE", "Crescent Combo hit %d/3; damage=%d" % [stage + 1, damage])

func _perform_eldritch_echo() -> void:
    if not hero_system or not hero_system.can_use_technique("eldritch_echo", debug_ability_override):
        _log("TECHNIQUE", "Eldritch Echo locked")
        return
    if eldritch_cooldown_remaining > 0.0:
        _log("TECHNIQUE", "Eldritch Echo cooling down; remaining=%.1f" % eldritch_cooldown_remaining)
        return
    if stamina < ECHO_STAMINA_COST:
        _log("TECHNIQUE", "Insufficient stamina for Eldritch Echo")
        return

    stamina -= ECHO_STAMINA_COST
    stamina_regen_delay = STAMINA_REGEN_DELAY
    eldritch_cooldown_remaining = ECHO_COOLDOWN
    active_action_kind = "eldritch_echo"
    action_elapsed = 0.0
    technique_hit_index = 0
    attack_hit_registered = false
    iaijutsu_active = false
    attack_time = ECHO_DURATION
    attack_windup = ECHO_WINDUP
    combo_step = 1
    combo_window = 0.0
    _set_state(CombatState.ATTACK)
    _log("TECHNIQUE", "Eldritch Echo invoked; cooldown=%.1f" % ECHO_COOLDOWN)

func _release_eldritch_echo() -> void:
    var pulse: Node2D = ECHO_PULSE_SCRIPT.new()
    pulse.global_position = global_position + Vector2(0.0, -30.0)
    get_parent().add_child(pulse)
    var affected := 0
    for target in get_tree().get_nodes_in_group("combat_enemies"):
        if not is_instance_valid(target) or not target is Node2D:
            continue
        if global_position.distance_to((target as Node2D).global_position) > ECHO_RANGE:
            continue
        if target.has_method("apply_echo_stagger") and bool(target.call("apply_echo_stagger", ECHO_STAGGER_DURATION)):
            affected += 1
    _log("TECHNIQUE", "Eldritch Echo resolved; affected_enemies=%d" % affected)

func _spawn_combat_slash_arc(step: int, short_blade: bool) -> void:
    var effect: Node2D = SLASH_ARC_SCRIPT.new()
    effect.global_position = global_position
    get_parent().add_child(effect)
    effect.call("setup", facing, step, short_blade, false, "")

func _spawn_technique_arc(technique_id: String, stage: int) -> void:
    var effect: Node2D = SLASH_ARC_SCRIPT.new()
    effect.global_position = global_position
    get_parent().add_child(effect)
    effect.call("setup_combat_technique", facing, technique_id, stage)

func set_debug_ability_override(enabled: bool) -> void:
    debug_ability_override = enabled
    _log("DEBUG", "Ability override %s (session only; not saved)" % ("ON" if enabled else "OFF"))

func toggle_debug_ability_override() -> void:
    set_debug_ability_override(not debug_ability_override)

func debug_refill_combat_resources() -> void:
    health = 100
    stamina = MAX_STAMINA
    stamina_regen_delay = 0.0
    eldritch_cooldown_remaining = 0.0
    invulnerable = false
    hurt_time = 0.0
    dodge_time = 0.0
    combo_step = 0
    combo_window = 0.0
    _cancel_attack_action()
    if state in [CombatState.HURT, CombatState.DODGE, CombatState.ATTACK]:
        _set_state(CombatState.IDLE)
    _log("DEBUG", "HP/stamina/cooldown restored (session only)")

func get_debug_action_kind() -> String:
    return active_action_kind

func get_debug_eldritch_cooldown() -> float:
    return eldritch_cooldown_remaining

func _perform_iaijutsu() -> void:
    if not hero_system or not hero_system.can_use_blood_iaijutsu():
        return
    var profile: Dictionary = hero_system.get_iaijutsu_profile()
    if profile.is_empty():
        return

    var stamina_cost := float(profile.get("stamina_cost", IAIJUTSU_STAMINA_COST))
    var health_cost := int(profile.get("health_cost", IAIJUTSU_HEALTH_COST))
    if stamina < stamina_cost or health <= health_cost:
        return

    stamina -= stamina_cost
    health -= health_cost
    stamina_regen_delay = STAMINA_REGEN_DELAY
    active_action_kind = "iaijutsu"
    action_elapsed = 0.0
    technique_hit_index = 0
    hero_system.add_abnormal_load(float(profile.get("abnormal_load", 10.0)))
    combo_step = 3
    combo_window = 0.0
    attack_time = float(profile.get("attack_time", 0.42))
    attack_windup = float(profile.get("windup", 0.11))
    attack_hit_registered = false
    iaijutsu_active = true
    _set_state(CombatState.ATTACK)
    _log("COMBAT", "%s used; hidden abnormal load increased" % str(profile.get("variant", "blood")))

func _start_dodge() -> void:
    if stamina < DODGE_STAMINA_COST:
        return
    stamina -= DODGE_STAMINA_COST
    stamina_regen_delay = STAMINA_REGEN_DELAY
    dodge_time = DODGE_DURATION
    perfect_dodge_window_remaining = PERFECT_DODGE_WINDOW
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
    var variant: String = hero_system.resolve_iaijutsu_variant() if hero_system != null and iaijutsu_active else ""
    effect.call("setup", facing, combo_step, hero_system != null and hero_system.is_short_blade(), iaijutsu_active, variant)

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
    var technique_finisher := active_action_kind == "judgment_slash" or (active_action_kind == "crescent_combo" and technique_hit_index >= 3)
    var finisher: bool = combo_step >= (hero_system.get_combo_limit() if hero_system else 3) or technique_finisher
    var impact_strength: float = 10.0 if technique_finisher else 9.0 if iaijutsu_active else 4.0 + float(combo_step) * 1.0
    var hitstop_duration: float = 0.055 if finisher or iaijutsu_active else 0.038
    var hitstop_scale: float = 0.06 if finisher or iaijutsu_active else 0.08
    WorldState.trigger_hitstop(hitstop_duration, hitstop_scale)
    _shake_camera(impact_strength, 0.08)
    velocity.x = facing * (105.0 if hero_system and hero_system.is_short_blade() else 190.0 if finisher else 145.0)
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
    if state == CombatState.DEAD:
        return
    if invulnerable:
        # Only a hit avoided during the opening dodge window counts as a perfect dodge.
        # 只有闪避起始窗口内成功避开攻击，才算精准闪避。
        if dodge_time > 0.0 and perfect_dodge_window_remaining > 0.0:
            riposte_bonus_active = true
            perfect_dodge_window_remaining = 0.0
            _log("COMBAT", "Perfect dodge! Next hit bonus armed")
        else:
            _log("COMBAT", "Hero damage ignored (invulnerable=true)")
        return
    health = max(0, health - amount)
    _spawn_hit_spark()
    WorldState.trigger_hitstop(0.032, 0.10)
    _shake_camera(9.0, 0.12)
    # A confirmed hit interrupts the Hero's current action; never let a stale hitbox resolve after hitstun.
    _cancel_attack_action()
    perfect_dodge_window_remaining = 0.0
    riposte_bonus_active = false
    attack_requested = false
    technique_requested = false
    weapon_technique_requested = false
    eldritch_requested = false
    dodge_requested = false
    jump_requested = false
    combo_step = 0
    combo_window = 0.0
    dodge_time = 0.0
    invulnerable = false
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
        air_jumps_used = 0
        coyote_time = 0.0
        jump_buffer = 0.0
        invulnerable = true
        stamina = MAX_STAMINA
        hurt_time = 0.0
        attack_time = 0.0
        attack_windup = 0.0
        attack_hit_registered = false
        iaijutsu_active = false
        active_action_kind = "none"
        action_elapsed = 0.0
        technique_hit_index = 0
        eldritch_cooldown_remaining = 0.0
        dodge_time = 0.0
        stamina_regen_delay = 0.0
        combo_step = 0
        combo_window = 0.0
        _deactivate_attack_hitbox()
        attack_requested = false
        technique_requested = false
        weapon_technique_requested = false
        eldritch_requested = false
        dodge_requested = false
        jump_requested = false
        _log("WORLD", "Hero respawned at checkpoint=%s" % WorldState.checkpoint_position)
        get_tree().create_timer(0.75).timeout.connect(_clear_respawn_invulnerability)
        _set_state(CombatState.IDLE)

func restore_full() -> void:
    health = 100
    stamina = MAX_STAMINA
    stamina_regen_delay = 0.0
    hurt_time = 0.0
    velocity = Vector2.ZERO
    air_jumps_used = 0
    coyote_time = 0.0
    jump_buffer = 0.0
    invulnerable = false
    attack_time = 0.0
    attack_windup = 0.0
    attack_hit_registered = false
    iaijutsu_active = false
    eldritch_cooldown_remaining = 0.0
    dodge_time = 0.0
    combo_step = 0
    combo_window = 0.0
    _cancel_attack_action()
    perfect_dodge_window_remaining = 0.0
    riposte_bonus_active = false
    attack_requested = false
    technique_requested = false
    weapon_technique_requested = false
    eldritch_requested = false
    dodge_requested = false
    jump_requested = false
    _set_state(CombatState.IDLE)
    _log("HERO", "Hero fully restored at rest point")

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func _cancel_attack_action() -> void:
    attack_time = 0.0
    attack_windup = 0.0
    attack_hit_registered = false
    iaijutsu_active = false
    active_action_kind = "none"
    action_elapsed = 0.0
    technique_hit_index = 0
    _deactivate_attack_hitbox()

func _deactivate_attack_hitbox() -> void:
    if is_instance_valid(attack_hitbox) and attack_hitbox.has_method("deactivate"):
        attack_hitbox.deactivate()

func _clear_respawn_invulnerability() -> void:
    invulnerable = false
    _log("HERO", "Respawn invulnerability ended")

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
    # Character art is a visual-only layer: collision, movement, attacks and hurtboxes remain unchanged.
    var short_blade: bool = hero_system != null and hero_system.is_short_blade()
    var hero_art: Texture2D = HERO_SHORT_ART if short_blade else HERO_LONG_ART
    var art_tint := Color("#f3e6d4") if hit_confirm_time > 0.0 else Color.WHITE
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
    draw_texture_rect(hero_art, Rect2(-48.0, -96.0, 96.0, 112.0), false, art_tint)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

    # Keep readable gameplay feedback above the painted silhouette.
    if hit_confirm_time > 0.0:
        draw_arc(Vector2(facing * 26.0, -42.0), 47.0, -0.75, 0.75, 20, Color("#efe1c8", 0.78), 3.0)
    if attack_time > 0.0 and attack_windup > 0.0:
        var windup_radius: float = 28.0 if short_blade else 38.0
        var telegraph := Color("#d2c1a4", 0.82)
        draw_arc(Vector2(facing * 24.0, -38.0), windup_radius, -0.55 if facing > 0.0 else 3.69, 0.55 if facing > 0.0 else 4.69, 16, telegraph, 2.5)
    elif attack_time > 0.0 and iaijutsu_active:
        var technique_color: Color = Color("#17151f") if hero_system and hero_system.resolve_iaijutsu_variant() == "black_horizon" else Color("#7951a1") if hero_system and hero_system.resolve_iaijutsu_variant() == "abyssal" else Color("#d0dce8") if hero_system and hero_system.resolve_iaijutsu_variant() == "human_iaijutsu" else Color("#c94a58")
        var technique_radius: float = 72.0 if hero_system and hero_system.resolve_iaijutsu_variant() == "black_horizon" else 61.0 if hero_system and hero_system.resolve_iaijutsu_variant() == "abyssal" else 54.0 if hero_system and hero_system.resolve_iaijutsu_variant() == "human_iaijutsu" else 48.0
        draw_arc(Vector2(facing * 25.0, -40.0), technique_radius, -0.72 if facing > 0.0 else 2.42, 0.72 if facing > 0.0 else 3.86, 24, technique_color, 5.0)

    if debug_mode_enabled:
        # World-space debug overlay follows the Hero and intentionally exposes hidden values only in debug mode.
        var debug_font := ThemeDB.fallback_font
        var debug_color := Color("#f0dfc3")
        var weapon_name := "短刃" if short_blade else "长剑"
        var action_name := active_action_kind if active_action_kind != "none" else get_debug_state().to_lower()
        draw_rect(Rect2(-112.0, -184.0, 224.0, 78.0), Color(0.035, 0.025, 0.04, 0.86), true)
        draw_string(debug_font, Vector2(-104.0, -166.0), "DEBUG F3 | Ctrl+F4:技能覆盖 | Ctrl+F5:恢复", HORIZONTAL_ALIGNMENT_LEFT, 212.0, 10, debug_color)
        draw_string(debug_font, Vector2(-104.0, -150.0), "HP %d | ST %d | %s" % [health, int(round(stamina)), weapon_name], HORIZONTAL_ALIGNMENT_LEFT, 212.0, 12, debug_color)
        draw_string(debug_font, Vector2(-104.0, -134.0), "状态 %s | 动作 %s | 连击 %d" % [get_debug_state(), action_name, combo_step], HORIZONTAL_ALIGNMENT_LEFT, 212.0, 10, debug_color)
        draw_string(debug_font, Vector2(-104.0, -118.0), "无敌 %s | 技能覆盖 %s | 冷却 %.1f" % [str(invulnerable), str(debug_ability_override), eldritch_cooldown_remaining], HORIZONTAL_ALIGNMENT_LEFT, 212.0, 10, debug_color)
        if hero_system != null:
            draw_string(debug_font, Vector2(-104.0, -102.0), "共鸣 %d 古神 %d 外神 %d 人性 %d" % [hero_system.resonance, hero_system.ancient_exposure, hero_system.outer_exposure, hero_system.humanity], HORIZONTAL_ALIGNMENT_LEFT, 212.0, 10, Color("#d7a8d9"))
            draw_string(debug_font, Vector2(-104.0, -86.0), "异常负荷 %.1f | 二段跳 %d/%d" % [hero_system.abnormal_load, air_jumps_used, MAX_EXTRA_AIR_JUMPS], HORIZONTAL_ALIGNMENT_LEFT, 212.0, 10, Color("#d7a8d9"))
        draw_rect(Rect2(-25.0, -72.0, 50.0, 4.0), Color("#27212a"), true)
        draw_rect(Rect2(-25.0, -72.0, 50.0 * (float(health) / 100.0), 4.0), Color("#bd5b61"), true)
        draw_rect(Rect2(-25.0, -65.0, 50.0, 3.0), Color("#27212a"), true)
        draw_rect(Rect2(-25.0, -65.0, 50.0 * (stamina / MAX_STAMINA), 3.0), Color("#b5a184"), true)
        if combo_step > 0 and attack_time > 0.0:
            draw_string(debug_font, Vector2(-4.0, -54.0), "%d" % combo_step, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e4d2b4"))
