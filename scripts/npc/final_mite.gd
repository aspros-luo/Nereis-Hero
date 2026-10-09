extends Node2D

const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")

signal died

var hero: Node2D
var controller: Node
var elapsed := 0.0
var hit_flash := 0.0
var dying := false
var idle_time := 0.0
var can_wait := true
var lunging := false
var waiting_phase := 0

func setup(hero_target: Node2D, ending_controller: Node) -> void:
    hero = hero_target
    controller = ending_controller

func _ready() -> void:
    var hurtbox := Area2D.new()
    hurtbox.name = "Hurtbox"
    hurtbox.set_script(HURTBOX_SCRIPT)
    add_child(hurtbox)
    hurtbox.setup(self, Vector2(34, 72), Vector2(0, -36))
    queue_redraw()

func register_player_input() -> void:
    if dying:
        return
    idle_time = 0.0

func _process(delta: float) -> void:
    elapsed += delta
    hit_flash = maxf(0.0, hit_flash - delta)

    if dying:
        queue_redraw()
        return

    idle_time += delta

    if idle_time >= 15.0 and waiting_phase < 1:
        waiting_phase = 1
    if idle_time >= 35.0 and waiting_phase < 2:
        waiting_phase = 2
    if idle_time >= 50.0 and waiting_phase < 3:
        waiting_phase = 3

    if can_wait and idle_time >= 60.0:
        can_wait = false
        if controller and controller.has_method("_mite_chooses_the_blade"):
            controller._mite_chooses_the_blade()

    queue_redraw()

func receive_damage(_amount: int, _source: Node = null) -> void:
    if dying or lunging:
        return
    _die(false)

func take_damage(amount: int) -> void:
    receive_damage(amount, null)

func sacrifice_to_weapon() -> void:
    if dying or lunging or not hero:
        return

    lunging = true
    can_wait = false
    var facing_value = hero.get("facing")
    var facing := 1.0
    if facing_value != null:
        var numeric_facing := float(facing_value)
        if not is_zero_approx(numeric_facing):
            facing = sign(numeric_facing)

    var weapon_target := hero.global_position + Vector2(42.0 * facing, -34.0)
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_IN)
    tween.tween_property(self, "global_position", weapon_target, 0.62)
    tween.tween_callback(func() -> void:
        if hero and hero.has_method("_shake_camera"):
            hero._shake_camera(3.5, 0.18)
        _die(true)
    )

func _die(waited_for: bool) -> void:
    dying = true
    can_wait = false
    if controller and controller.has_method("_on_mite_dying"):
        controller._on_mite_dying(waited_for)
    died.emit()
    if not waited_for:
        queue_redraw()

func _draw() -> void:
    var breath: float = sin(elapsed * 1.15) * 1.0
    var waiting_offset := 0.0
    if waiting_phase == 1:
        waiting_offset = sin(elapsed * 0.7) * 0.8
    elif waiting_phase == 2:
        waiting_offset = -1.5
    elif waiting_phase >= 3:
        waiting_offset = -3.0
    var tint := Color("#f3d8d6") if hit_flash > 0.0 else Color.WHITE
    if dying:
        tint = Color("#d7c3cf", 0.82)

    draw_set_transform(Vector2(0.0, breath + waiting_offset), 0.0, Vector2.ONE)
    draw_texture_rect(MITE_ART, Rect2(-44.0, -96.0, 88.0, 114.0), false, tint)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

    if waiting_phase >= 2 and not dying:
        draw_arc(Vector2(0.0, -50.0), 27.0, -0.2, 2.9, 28, Color("#9a6d9c", 0.3), 1.4)
    if waiting_phase >= 3:
        draw_circle(Vector2(4.0, -61.0), 2.0, Color("#c47b8c", 0.8))
    if not dying:
        draw_circle(Vector2(0.0, 8.0 + breath), 12.0, Color(0.75, 0.58, 0.68, 0.10))
