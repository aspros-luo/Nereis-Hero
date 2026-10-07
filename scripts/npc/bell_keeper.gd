extends Node2D

signal interacted(title: String, message: String)

const RANGE := 135.0

var hero_nearby := false
var cooldown := 0.0
var elapsed := 0.0

func _ready() -> void:
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    cooldown = maxf(0.0, cooldown - delta)
    var hero := get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= RANGE
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if WorldState.input_locked or not hero_nearby or cooldown > 0.0:
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        cooldown = 0.7
        var title := "BELL KEEPER"
        var message := ""
        if not WorldState.graveyard_cleared:
            message = "The old keeper touches the bell rope.\n\n"It stopped years ago."\n\n"But sometimes I hear it when someone who should be dead walks past."\n\nHis eyes settle on you."
        elif not WorldState.graveyard_keeper_heard:
            WorldState.record_hidden_artifact_source("graveyard_hero_gravestone")
            WorldState.mark_graveyard_keeper_heard()
            message = "The keeper looks toward the tower.\n\n"It rang after you left."\n\n"Not because of the dead."\n\n"Because something came back.""
        else:
            message = "The keeper has no more answers.\n\nHe only watches the silent bell."
        interacted.emit(title, message)
        get_viewport().set_input_as_handled()

func _draw() -> void:
    var sway := sin(elapsed * 1.3) * 1.0
    draw_circle(Vector2(0, -46 + sway), 16.0, Color("#30262f"))
    draw_circle(Vector2(0, -42 + sway), 6.0, Color("#9a7773"))
    draw_rect(Rect2(-18, -30 + sway, 36, 44), Color("#564651"))
    draw_line(Vector2(18, -2 + sway), Vector2(38, -22 + sway), Color("#8c756d"), 4.0)
    draw_string(ThemeDB.fallback_font, Vector2(-48, -70), "BELL KEEPER", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#9b8a86"))

    if hero_nearby and not WorldState.input_locked:
        draw_string(ThemeDB.fallback_font, Vector2(-42, 26), "E  Talk", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d6c7b2"))
