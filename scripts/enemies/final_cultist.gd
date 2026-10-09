extends CharacterBody2D

const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const DEATH_BURST_SCRIPT = preload("res://scripts/effects/death_burst.gd")

signal defeated

var health := 1
var speed := 105.0
var target: Node2D
var seed_offset := 0.0
var dying := false
var animation_time := 0.0

func setup(hero_target: Node2D, variant_seed: float) -> void:
    target = hero_target
    seed_offset = variant_seed
    speed += fmod(absf(variant_seed * 37.0), 40.0)

func _ready() -> void:
    add_to_group("combat_enemies")
    collision_layer = 0
    collision_mask = 0

    var hurtbox := Area2D.new()
    hurtbox.name = "Hurtbox"
    hurtbox.set_script(HURTBOX_SCRIPT)
    add_child(hurtbox)
    hurtbox.setup(self, Vector2(34, 66), Vector2(0, -32))
    queue_redraw()

func _physics_process(delta: float) -> void:
    delta *= WorldState.get_combat_enemy_time_scale()
    if WorldState.input_locked:
        return
    animation_time += delta

    if dying or not target or not is_instance_valid(target):
        velocity = Vector2.ZERO
        return

    var to_target := target.global_position - global_position
    var distance := to_target.length()

    if distance > 74.0:
        velocity.x = sign(to_target.x) * speed
    else:
        velocity.x = 0.0

    velocity.y = sin(animation_time * 3.0 + seed_offset) * 8.0
    _move_and_slide_scaled()
    queue_redraw()

func receive_damage(_amount: int, source: Node = null) -> void:
    if dying:
        return
    dying = true
    health = 0

    var effect: Node2D = DEATH_BURST_SCRIPT.new()
    effect.global_position = global_position + Vector2(0, -30)
    get_parent().add_child(effect)
    effect.call("setup", 10.0)

    defeated.emit()
    queue_free()

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func _draw() -> void:
    var sway := sin(animation_time * 4.0 + seed_offset) * 1.5
    var body := Color("#3f333b")
    var cloth := Color("#2a232d")
    draw_circle(Vector2(0, -47 + sway), 15.0, cloth)
    draw_circle(Vector2(0, -43 + sway), 6.0, Color("#a14e59"))
    draw_rect(Rect2(-17, -31 + sway, 34, 38), body)
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(-18, 5 + sway),
            Vector2(18, 5 + sway),
            Vector2(27, 12 + sway),
            Vector2(-27, 12 + sway)
        ]),
        cloth
    )
    draw_line(Vector2(-12, -2 + sway), Vector2(-32, 11 + sway), body, 6.0)
    draw_line(Vector2(12, -2 + sway), Vector2(32, 11 + sway), body, 6.0)


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
