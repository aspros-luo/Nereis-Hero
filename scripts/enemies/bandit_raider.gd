extends CharacterBody2D

const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")
const DEATH_BURST_SCRIPT = preload("res://scripts/effects/death_burst.gd")
const HUMANOID_VISUAL_SCENE = preload("res://scenes/characters/humanoid_character_visual.tscn")

signal defeated
signal attack_telegraphed

const MOVE_SPEED := 105.0
const ATTACK_RANGE := 94.0

var health := 90
var attack_cooldown := 0.0
var windup := 0.0
var released := false
var facing := -1.0
var stun_time := 0.0
var hit_flash := 0.0
var animation_time := 0.0
var attack_hitbox: Area2D
var character_visual: HumanoidCharacterVisual

func _ready() -> void:
    character_visual = HUMANOID_VISUAL_SCENE.instantiate() as HumanoidCharacterVisual
    character_visual.name = "CharacterVisual"
    character_visual.position = Vector2(0.0, -20.0)
    character_visual.skin_color = Color("#9c776f")
    character_visual.cloth_color = Color("#45333b")
    character_visual.hurt_color = Color("#c45d65")
    add_child(character_visual)
    add_to_group("combat_enemies")
    attack_hitbox = $AttackHitbox as Area2D
    attack_hitbox.setup(self, Vector2(76, 54), Vector2(-42, -22))

    var hurtbox := $Hurtbox as Area2D
    hurtbox.setup(self, Vector2(40, 72), Vector2(0, -30))
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
    if is_instance_valid(character_visual):
        character_visual.set_facing(facing)
        character_visual.set_motion_state("run" if absf(velocity.x) > 8.0 else "idle")
        character_visual.set_hurt_flash(hit_flash > 0.0)
    queue_redraw()

func _physics_process(delta: float) -> void:
    delta *= WorldState.get_combat_enemy_time_scale()
    if WorldState.input_locked:
        return
    if stun_time > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 1050.0 * delta)
        _move_and_slide_scaled()
        return

    var hero := get_node_or_null("../Hero") as Node2D
    if hero:
        var dx := hero.global_position.x - global_position.x
        if not is_zero_approx(dx):
            facing = sign(dx)

        if windup > 0.0:
            velocity.x = 0.0
            if windup <= 0.07 and not released:
                attack_hitbox.position.x = facing * 42.0
                attack_hitbox.activate(14, 0.13)
                released = true
        elif absf(dx) > ATTACK_RANGE:
            velocity.x = facing * MOVE_SPEED
        elif attack_cooldown <= 0.0:
            velocity.x = 0.0
            windup = 0.30
            attack_cooldown = 1.15
            released = false
            attack_telegraphed.emit()

    _move_and_slide_scaled()

func receive_damage(amount: int, source: Node = null) -> void:
    health = max(0, health - amount)
    stun_time = 0.12
    hit_flash = 0.1

    var spark: Node2D = HIT_SPARK_SCRIPT.new()
    spark.global_position = global_position + Vector2(0, -30)
    get_parent().add_child(spark)

    if source and source is Node2D:
        velocity.x = sign(global_position.x - source.global_position.x) * 145.0

    if health <= 0:
        var burst: Node2D = DEATH_BURST_SCRIPT.new()
        burst.global_position = global_position + Vector2(0, -30)
        get_parent().add_child(burst)
        burst.call("setup", 13.0)
        defeated.emit()
        queue_free()

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func _draw() -> void:
    # The shared rig owns the bandit's body; this script retains combat telegraph and label.
    # 公用骨架负责强盗主体；此处保留战斗预警与名称。
    if windup > 0.0:
        draw_arc(Vector2(facing * 20.0, -22), 34.0, -0.85 if facing > 0 else 3.99, 0.85 if facing > 0 else 5.42, 14, Color("#d17b72"), 4.0)
    draw_string(ThemeDB.fallback_font, Vector2(-50, -72), NereisLocalization.translate_text("BANDIT"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#b7a09b"))

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
