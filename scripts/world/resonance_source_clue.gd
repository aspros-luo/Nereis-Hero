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
@export_range(0, 100, 1) var ancient_exposure_floor: int = 0
@export_range(0, 100, 1) var outer_exposure_floor: int = 0
@export var require_outer_god_resonance: bool = false
@export var unlock_ability_id: String = ""
@export var unlock_source_type: String = "resonance"
@export var interaction_radius: float = 105.0

var consumed := false
var hero_nearby := false
var cooldown := 0.0

func _ready() -> void:
    set_meta("interaction_priority", 25)
    _refresh_consumed_state()
    queue_redraw()

# An old save may contain the source ID but lack its intended ability or minimums.
# 旧存档可能已经记录来源 ID，却没有完整保存能力解锁或最低状态；这种情况仍允许一次修复交互。
func _milestone_needs_repair() -> bool:
    var normalized_id := source_id.strip_edges()
    if normalized_id.is_empty():
        return false
    if normalized_id not in WorldState.resonance_sources:
        return true
    if WorldState.hero_resonance < resonance_target:
        return true
    if WorldState.ancient_exposure < ancient_exposure_floor:
        return true

    var effective_outer_floor := outer_exposure_floor
    if require_outer_god_resonance and not WorldState.outer_god_resonance:
        effective_outer_floor = 0
    if WorldState.outer_exposure < effective_outer_floor:
        return true
    if not unlock_ability_id.strip_edges().is_empty() and not WorldState.is_ability_unlocked(unlock_ability_id):
        return true
    return false

func _refresh_consumed_state() -> void:
    consumed = not _milestone_needs_repair()

func _process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    _refresh_consumed_state()

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
        var effective_outer_floor := outer_exposure_floor
        if require_outer_god_resonance and not WorldState.outer_god_resonance:
            effective_outer_floor = 0

        var recorded := WorldState.record_resonance_milestone(
            source_id,
            resonance_target,
            ancient_exposure_delta,
            outer_exposure_delta,
            unlock_ability_id,
            unlock_source_type,
            ancient_exposure_floor,
            effective_outer_floor
        )
        _refresh_consumed_state()
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
