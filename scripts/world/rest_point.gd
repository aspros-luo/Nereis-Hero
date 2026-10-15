extends Node2D

signal rested

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

@export var rest_id: String = ""
@export var display_name: String = "REST"

var hero_nearby := false
var cooldown := 0.0

func _ready() -> void:
    queue_redraw()

func _process(delta: float) -> void:
    cooldown = max(0.0, cooldown - delta)
    var hero: Node2D = get_node_or_null("../Hero") as Node2D
    hero_nearby = _hero_can_rest(hero)
    var available := not WorldState.input_locked and hero_nearby and cooldown <= 0.0
    INTERACTION_FOCUS_SCRIPT.sync(self, available)
    queue_redraw()


func _hero_can_rest(hero: Node2D) -> bool:
    # A rest interaction must not record an airborne checkpoint or one from a nearby upper ledge.
    # 休整必须发生在地面承托处，不能把空中坐标或附近高层平台记录成死亡出生点。
    if hero == null or not hero is CharacterBody2D:
        return false
    var body := hero as CharacterBody2D
    return (
        body.is_on_floor()
        and absf(body.global_position.x - global_position.x) <= 90.0
        and absf(body.global_position.y - global_position.y) <= 32.0
    )


func _unhandled_input(event: InputEvent) -> void:
    if WorldState.input_locked or not hero_nearby or cooldown > 0.0 or not INTERACTION_FOCUS_SCRIPT.is_focused(self):
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        cooldown = 1.0
        var hero: Node2D = get_node_or_null("../Hero") as Node2D
        if hero and hero.has_method("restore_full"):
            hero.restore_full()
            WorldState.set_checkpoint(hero.global_position)
            WorldState.save_game()
            rested.emit()
            print("[NEREIS][WORLD] Rest point used id=%s" % rest_id)
        get_viewport().set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(-36, -16, 72, 16), Color("#352d38"))
    draw_circle(Vector2(-24, -22), 8.0, Color("#796d67"))
    draw_circle(Vector2(24, -22), 8.0, Color("#796d67"))
    if hero_nearby and not WorldState.input_locked and INTERACTION_FOCUS_SCRIPT.is_focused(self):
        draw_string(ThemeDB.fallback_font, Vector2(-34, 28), "E  Rest", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d6c7b2"))
