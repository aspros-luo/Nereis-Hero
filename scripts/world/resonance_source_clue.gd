extends Node2D
## One-time world anomaly that records a resonance milestone.
## 一次性世界异常：记录鸣响里程碑，并可解锁现有能力。

signal activated(display_name: String, description: String, first_record: bool)

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

@export var source_id: String = ""
@export var display_name: String = "ANOMALY"
@export_multiline var description: String = ""
@export_range(0, 100, 1) var resonance_target: int = 0
@export_range(0, 100, 1) var ancient_exposure_delta: int = 0
@export_range(0, 100, 1) var outer_exposure_delta: int = 0
@export var unlock_ability_id: String = ""
@export var unlock_source_type: String = "resonance"
@export var interaction_radius: float = 105.0

var consumed := false
var hero_nearby := false
var cooldown := 0.0

func _ready() -> void:
    set_meta("interaction_priority", 25)
    consumed = source_id in WorldState.resonance_sources
    queue_redraw()

func _process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    if not consumed and source_id in WorldState.resonance_sources:
        consumed = true

    var hero := get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= interaction_radius
    var available := not consumed and not WorldState.input_locked and hero_nearby and cooldown <= 0.0
    INTERACTION_FOCUS_SCRIPT.sync(self, available, 25)
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if (
        WorldState.input_locked
        or consumed
        or not hero_nearby
        or cooldown > 0.0
        or not INTERACTION_FOCUS_SCRIPT.is_focused(self)
    ):
        return

    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        cooldown = 0.6
        var recorded := WorldState.record_resonance_milestone(
            source_id,
            resonance_target,
            ancient_exposure_delta,
            outer_exposure_delta,
            unlock_ability_id,
            unlock_source_type
        )
        consumed = source_id in WorldState.resonance_sources
        if recorded:
            activated.emit(display_name, description, true)
            print("[NEREIS][SENSE] Anomaly examined id=%s" % source_id)
        get_viewport().set_input_as_handled()

func _draw() -> void:
    var tint := Color("#b6a58a") if not consumed else Color("#514a4f")
    draw_circle(Vector2.ZERO, 15.0, Color("#28232b"))
    draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 20, tint, 2.0)
    draw_line(Vector2(-9.0, -9.0), Vector2(9.0, 9.0), tint, 2.0)
    draw_line(Vector2(9.0, -9.0), Vector2(-9.0, 9.0), tint, 2.0)

    if hero_nearby and not consumed and not WorldState.input_locked and INTERACTION_FOCUS_SCRIPT.is_focused(self):
        draw_string(
            ThemeDB.fallback_font,
            Vector2(-56.0, 13.0),
            NereisLocalization.translate_text("E  Examine"),
            HORIZONTAL_ALIGNMENT_LEFT,
            -1.0,
            15,
            Color("#d6c7b2")
        )
