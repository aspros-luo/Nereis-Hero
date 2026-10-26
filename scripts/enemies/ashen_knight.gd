extends CharacterBody2D

const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")
const DEATH_BURST_SCRIPT = preload("res://scripts/effects/death_burst.gd")

var health := 240
var max_health := 240
var boss_display_name := "灰烬骑士"
var phase := 1
var persist_global_boss_defeat := true
# Prologue-only executioner cannot be defeated; ordinary bosses remain damageable by default.
var damage_immune := false
## Per-instance damage scaling; lower values make a boss more resilient without making it invulnerable.
var damage_taken_multiplier := 1.0
var is_defeated := false
var visual_theme := "ashen"
var attack_cooldown := 0.0
var windup := 0.0
var hit_flash := 0.0
var stun_time := 0.0
var facing := -1.0
var attack_released := false
var phase_two := false
var attack_hitbox: Area2D
var animation_time := 0.0
var attack_effect_time := 0.0
signal defeated
signal phase_changed(phase: int)
signal attack_telegraphed

func _ready() -> void:
    add_to_group("combat_enemies")
    _setup_combat_components()
    _log("BOSS", "Ashen Knight initialized; hp=240")
    queue_redraw()

func _setup_combat_components() -> void:
    attack_hitbox = $AttackHitbox as Area2D
    attack_hitbox.setup(self, Vector2(120, 72), Vector2(facing * 64.0, -34.0))

    var hurtbox := $Hurtbox as Area2D
    hurtbox.setup(self, Vector2(48, 94), Vector2(0, -38))

func _process(delta: float) -> void:
    delta *= WorldState.get_combat_enemy_time_scale()
    if WorldState.input_locked:
        return
    animation_time += delta
    attack_effect_time = maxf(0.0, attack_effect_time - delta)
    queue_redraw()

func _physics_process(delta: float) -> void:
    delta *= WorldState.get_combat_enemy_time_scale()
    if WorldState.input_locked:
        return
    attack_cooldown = max(0.0, attack_cooldown - delta)
    hit_flash = max(0.0, hit_flash - delta)
    windup = max(0.0, windup - delta)
    stun_time = max(0.0, stun_time - delta)

    if not phase_two and health <= maxi(1, max_health / 2):
        phase_two = true
        phase = 2
        attack_cooldown = 0.2
        windup = 0.0
        _log("BOSS", "Ashen Knight entered Phase 2")
        phase_changed.emit(2)
        queue_redraw()

    if stun_time > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
        _move_and_slide_scaled()
        queue_redraw()
        return

    var hero: Node2D = get_node_or_null("../Hero") as Node2D
    if hero:
        var delta_x: float = hero.global_position.x - global_position.x
        if abs(delta_x) > (132.0 if phase_two else 120.0) and windup <= 0.0:
            facing = sign(delta_x)
            velocity.x = facing * (98.0 if phase_two else 64.0)
        elif windup > 0.0:
            velocity.x = move_toward(velocity.x, 0.0, 1600.0 * delta)
            facing = sign(delta_x) if delta_x != 0.0 else facing
            if windup <= 0.06 and not attack_released:
                attack_released = true
                attack_effect_time = 0.24
                attack_hitbox.position.x = facing * (72.0 if phase_two else 64.0)
                var attack_damage := 36 if phase_two else 24
                var attack_range := 132.0 if phase_two else 120.0
                attack_hitbox.activate(attack_damage, 0.18 if phase_two else 0.16)
                velocity.x = facing * (155.0 if phase_two else 85.0)
                _log("COMBAT", "Ashen Knight heavy attack released; damage=%d range=%.0f" % [attack_damage, attack_range])
        else:
            velocity.x = 0.0
            facing = sign(delta_x) if delta_x != 0.0 else facing
            if attack_cooldown <= 0.0:
                windup = 0.30 if phase_two else 0.42
                attack_cooldown = 0.82 if phase_two else 1.55
                attack_released = false
                attack_telegraphed.emit()
                _log("BOSS", "Ashen Knight attack telegraph phase=%d" % (2 if phase_two else 1))

    _move_and_slide_scaled()
    queue_redraw()

func _spawn_death_burst() -> void:
    var effect: Node2D = DEATH_BURST_SCRIPT.new()
    effect.global_position = global_position + Vector2(0, -44)
    get_parent().add_child(effect)
    effect.call("setup", 26.0)

func _spawn_hit_spark() -> void:
    var effect := Node2D.new()
    effect.set_script(HIT_SPARK_SCRIPT)
    effect.global_position = global_position + Vector2(0, -34)
    get_parent().add_child(effect)

func receive_damage(amount: int, source: Node = null) -> void:
    if is_defeated or is_queued_for_deletion():
        return
    if damage_immune:
        _log("BOSS", "%s ignored damage during scripted prologue encounter" % boss_display_name)
        return
    var scaled_damage := maxi(1, roundi(float(maxi(1, amount)) * clampf(damage_taken_multiplier, 0.05, 1.0)))
    health = max(0, health - scaled_damage)
    _spawn_hit_spark()
    hit_flash = 0.12
    stun_time = 0.08 if phase_two else 0.12
    if source and source is Node2D:
        velocity.x = sign(global_position.x - source.global_position.x) * (95.0 if phase_two else 75.0)
    var source_name: String = source.name if source else "Unknown"
    _log("BOSS", "%s -> Ashen Knight damage=%d (raw=%d) hp=%d" % [source_name, scaled_damage, amount, health])
    if health <= 0:
        is_defeated = true
        _spawn_death_burst()
        _log("BOSS", "Ashen Knight defeated")
        if persist_global_boss_defeat:
            WorldState.mark_boss_defeated()
        defeated.emit()
        queue_free()

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func apply_echo_stagger(duration: float) -> bool:
    if health <= 0 or is_queued_for_deletion():
        return false
    # Bosses resist the full control effect; Echo can interrupt a tell but never lock the boss down.
    # Boss 对控制效果有抗性：余响可打断起手，但不能长时间压制。
    var capped_duration := minf(duration, 0.12 if phase_two else 0.15)
    stun_time = maxf(stun_time, capped_duration)
    windup = 0.0
    attack_released = true
    hit_flash = maxf(hit_flash, 0.10)
    velocity.x *= 0.35
    _log("BOSS", "Eldritch Echo caused brief stagger %.2fs (phase=%d)" % [capped_duration, 2 if phase_two else 1])
    return true

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
    var base: Color
    if visual_theme == "royal_tomb":
        base = Color("#9a8060") if phase_two else Color("#343039")
    else:
        base = Color("#7b3944") if phase_two else Color("#2c2932")
    var c: Color = base
    if hit_flash > 0.0:
        c = Color("#d9c8a2") if visual_theme == "royal_tomb" else Color("#d35a62")
    var pulse: float = sin(animation_time * 4.0) * 2.0
    draw_circle(Vector2(0, -61 + pulse), 22, Color("#141218"))
    draw_circle(Vector2(0, -61 + pulse), 19, c)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-26, -40 + pulse), Vector2(26, -40 + pulse),
        Vector2(32, 8), Vector2(-32, 8)
    ]), c)
    draw_arc(Vector2(0, -55 + pulse), 30.0 if phase_two else 26.0, PI * 0.1, PI * 0.9, 20, Color("#b8a47f") if visual_theme == "royal_tomb" else Color("#9f806f"), 4.0)
    draw_line(Vector2(-18, -4 + pulse), Vector2(-62, 10), c, 12.0)
    draw_line(Vector2(18, -4 + pulse), Vector2(62, 10), c, 12.0)
    draw_line(Vector2(facing * 8.0, -18 + pulse), Vector2(facing * 92.0, -44 + pulse), Color("#c9baa0"), 10.0)
    if windup > 0.0:
        # High-contrast warning: a forward line and broad arc remain visible throughout the wind-up.
        var telegraph_color := Color("#ffb0a2") if phase_two else Color("#e8a0a0")
        draw_arc(Vector2(facing * 42.0, -34), 56.0, -1.0 if facing > 0 else 2.15, 1.0 if facing > 0 else 4.15, 24, telegraph_color, 6.0)
        draw_line(Vector2(facing * 26.0, -28), Vector2(facing * 124.0, -28), telegraph_color, 5.0)
        draw_circle(Vector2(facing * 124.0, -28), 5.0, Color("#fff0d8"))
    if attack_effect_time > 0.0:
        var slash_alpha := clampf(attack_effect_time / 0.24, 0.0, 1.0)
        var slash_color := Color(1.0, 0.88, 0.72, slash_alpha)
        draw_line(Vector2(facing * 24.0, -70.0), Vector2(facing * 118.0, -8.0), slash_color, 11.0)
        draw_line(Vector2(facing * 36.0, -80.0), Vector2(facing * 132.0, -18.0), Color(1.0, 0.45, 0.43, slash_alpha * 0.9), 4.0)
    var label := boss_display_name
    if not damage_immune:
        label = "%s %d/%d" % [boss_display_name, max(0, health), max_health]
    draw_string(ThemeDB.fallback_font, Vector2(-86, -94), NereisLocalization.translate_text(label), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d6c7b2"))

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
