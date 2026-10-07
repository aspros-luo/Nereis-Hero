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
    var breath := sin(elapsed * 1.15) * 1.4
    var waiting_offset := 0.0
    if waiting_phase == 1:
        waiting_offset = sin(elapsed * 0.7) * 1.0
    elif waiting_phase == 2:
        waiting_offset = -2.0
    elif waiting_phase >= 3:
        waiting_offset = -4.0
    var body := Color("#6a5260")
    var skin := Color("#b58f87")
    var shadow := Color("#27202a")
    if hit_flash > 0.0:
        body = Color("#d5b8b0")

    draw_circle(Vector2(2.0 if waiting_phase >= 2 else 0.0, -34 + breath + waiting_offset), 16.0, skin)
    draw_circle(Vector2(-5, -39 + breath), 3.0, shadow)
    draw_circle(Vector2(5, -39 + breath), 3.0, shadow)
    draw_rect(Rect2(-19, -18 + breath + waiting_offset, 38, 52), body)
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(-22, -18 + breath + waiting_offset),
            Vector2(0, 18 + breath + waiting_offset),
            Vector2(22, -18 + breath + waiting_offset)
        ]),
        Color("#4a3b4a")
    )

    if not dying:
        draw_circle(Vector2(0, 7 + breath), 12.0, Color(0.75, 0.58, 0.58, 0.08))
