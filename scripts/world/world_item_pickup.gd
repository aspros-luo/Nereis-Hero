extends Node2D

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")
const ITEM_CATALOG = preload("res://scripts/core/item_catalog.gd")

@export var pickup_id: String = ""
@export var item_id: String = ""
@export var amount: int = 1
@export var prompt_text: String = "E  拾取"

var hero_nearby := false
var consumed := false
var cooldown := 0.0

func _ready() -> void:
    consumed = pickup_id in WorldState.collected_world_item_ids
    queue_redraw()

func _process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    if consumed:
        hero_nearby = false
        INTERACTION_FOCUS_SCRIPT.sync(self, false)
        return
    var hero := get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= 100.0
    var available := not WorldState.input_locked and hero_nearby and cooldown <= 0.0
    INTERACTION_FOCUS_SCRIPT.sync(self, available)
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if WorldState.input_locked or consumed or not hero_nearby or cooldown > 0.0 or not INTERACTION_FOCUS_SCRIPT.is_focused(self):
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        cooldown = 0.5
        if ITEM_CATALOG.has_item(item_id) and WorldState.record_world_item_pickup(pickup_id, item_id, amount):
            consumed = true
            queue_redraw()
            WorldState.mark_item_read(item_id)
            var definition: Dictionary = ITEM_CATALOG.get_definition(item_id)
            var panel := get_tree().get_first_node_in_group("item_inspection_panels")
            if panel != null and panel.has_method("show_description"):
                panel.call("show_pickup", str(definition.get("display_name", item_id)))
            print("[NEREIS][ITEM] Picked up id=%s amount=%d" % [item_id, amount])
        get_viewport().set_input_as_handled()

func _draw() -> void:
    var tint := Color("#d6c7b2") if not consumed else Color("#4d454d")
    if item_id == "church_bandage":
        draw_rect(Rect2(-17, -10, 34, 17), Color("#3a3034"))
        draw_rect(Rect2(-14, -8, 28, 13), Color("#b6a99a") if not consumed else Color("#655b5b"))
        draw_line(Vector2(-10, -8), Vector2(-5, 5), Color("#766a68"), 2.0)
        draw_line(Vector2(0, -8), Vector2(5, 5), Color("#766a68"), 2.0)
        draw_line(Vector2(9, -8), Vector2(12, 3), Color("#766a68"), 2.0)
    elif item_id == "surgery_record_fragment":
        draw_colored_polygon(PackedVector2Array([
            Vector2(-13, -18), Vector2(9, -18), Vector2(14, -12),
            Vector2(14, 8), Vector2(-13, 8)
        ]), Color("#b7a48c") if not consumed else Color("#655b5b"))
        for line_y in [-10.0, -4.0, 2.0]:
            draw_line(Vector2(-8, line_y), Vector2(8, line_y), Color("#4d4142"), 1.0)
        draw_line(Vector2(9, -18), Vector2(9, -12), Color("#75645b"), 1.0)
    else:
        draw_rect(Rect2(-12, -12, 24, 24), Color("#332c34"))
        draw_rect(Rect2(-8, -8, 16, 16), tint)
    if hero_nearby and not consumed:
        draw_string(ThemeDB.fallback_font, Vector2(-42, 30), prompt_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, tint)
