extends CharacterBody2D

const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")
const DEATH_BURST_SCRIPT = preload("res://scripts/effects/death_burst.gd")

signal defeated
signal attack_telegraphed

var health := 170
var attack_cooldown := 0.0
var windup := 0.0
var released := false
var facing := -1.0
var stun_time := 0.0
var hit_flash := 0.0
var animation_time := 0.0
var attack_hitbox: Area2D

func _ready() -> void:
    add_to_group("combat_enemies")
    attack_hitbox = $AttackHitbox as Area2D
    attack_hitbox.setup(self, Vector2(92, 62), Vector2(-46, -28))

    var hurtbox := $Hurtbox as Area2D
    hurtbox.setup(self, Vector2(48, 92), Vector2(0, -40))
    queue_redraw()

func _process(delta: float) -> void:
    delta *= WorldState.get_combat_enemy_time_scale()
    if WorldState.input_locked:
        return
    animation_time += delta
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    windup = maxf(0.0, windup - delta)
    stun_time = maxf(0.0, stun_time - delta)
    hit_flash = maxf(0.0, hit_flash - delta)
    queue_redraw()

func _physics_process(delta: float) -> void:
    delta *= WorldState.get_combat_enemy_time_scale()
    if WorldState.input_locked:
        return
    if stun_time > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
        _move_and_slide_scaled()
        return

    var hero := get_node_or_null("../Hero") as Node2D
    if hero:
        var dx := hero.global_position.x - global_position.x
        if not is_zero_approx(dx):
            facing = sign(dx)

        if windup > 0.0:
            velocity.x = 0.0
            if windup <= 0.08 and not released:
                attack_hitbox.position.x = facing * 48.0
                attack_hitbox.activate(22, 0.14)
                released = true
        elif absf(dx) > 132.0:
            velocity.x = facing * 56.0
        elif attack_cooldown <= 0.0:
            windup = 0.52
            attack_cooldown = 1.8
            released = false
            attack_telegraphed.emit()

    _move_and_slide_scaled()

func receive_damage(amount: int, source: Node = null) -> void:
    health = max(0, health - amount)
    stun_time = 0.15
    hit_flash = 0.1

    var spark: Node2D = HIT_SPARK_SCRIPT.new()
    spark.global_position = global_position + Vector2(0, -40)
    get_parent().add_child(spark)

    if source and source is Node2D:
        velocity.x = sign(global_position.x - source.global_position.x) * 100.0

    if health <= 0:
        var burst: Node2D = DEATH_BURST_SCRIPT.new()
        burst.global_position = global_position + Vector2(0, -40)
        get_parent().add_child(burst)
        burst.call("setup", 20.0)
        defeated.emit()
        queue_free()

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func _draw() -> void:
    var is_ancient_experiment := name == "H09_AncientExperiment"
    var tissue := (Color("#765064") if is_ancient_experiment else Color("#6c5a62")) if hit_flash <= 0.0 else Color("#e2a0a0")
    var bone := Color("#c8b6a5") if is_ancient_experiment else Color("#b8a69c")
    var shadow := Color("#221720") if is_ancient_experiment else Color("#221c25")
    var pulse := sin(animation_time * (3.0 if is_ancient_experiment else 2.1)) * (4.0 if is_ancient_experiment else 2.0)

    draw_circle(Vector2(0, -56 + pulse), 21.0 if not is_ancient_experiment else 27.0, shadow)
    draw_circle(Vector2(facing * 6, -52 + pulse), 7.0, Color("#c3a2d0") if is_ancient_experiment else tissue)
    draw_rect(Rect2(-24, -36 + pulse, 48, 46), tissue)
    draw_line(Vector2(-12, 0 + pulse), Vector2(-55, 14 + pulse), bone, 7.0)
    draw_line(Vector2(12, 0 + pulse), Vector2(50, 12 + pulse), bone, 7.0)
    draw_circle(Vector2(0, -18 + pulse), 9.0, Color("#8f5c6b", 0.34))
    if is_ancient_experiment:
        # Exposed vertebrae and a split crown identify this as an ancient-god specimen, not a generic husk.
        # 外露脊椎与裂开的冠状骨辨认出这是古神实验体，而非普通研究残骸。
        for rib in range(4):
            var rib_y := -34.0 + float(rib) * 10.0 + pulse
            draw_arc(Vector2(0, rib_y), 30.0 - float(rib) * 2.0, 0.15, PI - 0.15, 12, bone, 2.0)
        draw_line(Vector2(-18, -74 + pulse), Vector2(-29, -96 + pulse), bone, 3.0)
        draw_line(Vector2(0, -78 + pulse), Vector2(0, -104 + pulse), bone, 3.0)
        draw_line(Vector2(18, -74 + pulse), Vector2(29, -96 + pulse), bone, 3.0)
        draw_arc(Vector2(0, -74 + pulse), 34.0, PI + 0.1, TAU - 0.1, 20, Color("#ad779e"), 3.0)

    if windup > 0.0:
        draw_arc(Vector2(facing * 24, -26), 42.0, -0.85 if facing > 0 else 3.99, 0.85 if facing > 0 else 5.42, 16, Color("#d56b6a"), 4.0)

    draw_string(ThemeDB.fallback_font, Vector2(-86, -112 if name == "H09_AncientExperiment" else -86), "ANCIENT TEST SUBJECT" if name == "H09_AncientExperiment" else "RESEARCH HUSK", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#d3a9cb" if name == "H09_AncientExperiment" else "#b7a09b"))


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
