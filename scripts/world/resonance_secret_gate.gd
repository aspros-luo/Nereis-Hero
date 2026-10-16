extends Node2D
## A persistent Resonance Sight gate. Revealing is temporary; opening is saved.
## 持久化灵视入口：显现是临时感知，开启状态写入存档。

signal opened(secret_id: String)

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

@export var secret_id: String = "H01"
@export var region_record_id: String = "" # Optional area ID when the secret path ID differs.
@export var target_scene_path: String = "res://scenes/hidden_well.tscn"
@export var target_location_id: String = "hidden_well"
@export_enum("west", "east") var target_spawn_side: String = "west"
@export_range(0, 100, 1) var required_resonance: int = 12
@export_range(0, 100, 1) var required_ancient_exposure: int = 0
@export_range(0, 100, 1) var required_outer_exposure: int = 0
@export var require_outer_god_resonance: bool = false
@export var required_source_ids: Array[String] = []
@export var interaction_radius: float = 80.0
# F5 debug override may bypass reveal thresholds for testing, but never opens or persists a gate by itself.
# F5 调试覆盖仅用于绕过显现门槛；它本身不会开门或写入永久通路状态。
@export var allow_debug_override: bool = true

var revealed := false
var opened_permanently := false
var hero_nearby := false
var cooldown := 0.0

func _ready() -> void:
    set_meta("interaction_priority", 25)
    set_meta("p5_1_exit_contract", true)
    set_meta("p5_1_target_scene", target_scene_path)
    set_meta("p5_1_target_region", _p5_1_region_for_location(target_location_id))
    set_meta("p5_1_spawn_side", target_spawn_side)
    add_to_group("resonance_hidden_targets")
    opened_permanently = WorldState.is_hidden_path_opened(secret_id)
    update_reveal_state(
        WorldState.resonance_sight_active,
        WorldState.hero_resonance,
        WorldState.ancient_exposure,
        WorldState.outer_exposure,
        _is_debug_override_active()
    )
    queue_redraw()

func _process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    opened_permanently = WorldState.is_hidden_path_opened(secret_id)
    update_reveal_state(
        WorldState.resonance_sight_active,
        WorldState.hero_resonance,
        WorldState.ancient_exposure,
        WorldState.outer_exposure,
        _is_debug_override_active()
    )

    var hero := get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= interaction_radius
    var available := (
        not WorldState.input_locked
        and hero_nearby
        and cooldown <= 0.0
        and (opened_permanently or revealed)
    )
    INTERACTION_FOCUS_SCRIPT.sync(self, available, 25)
    queue_redraw()

func _is_debug_override_active() -> bool:
    return allow_debug_override and WorldState.debug_ability_override_active

func _p5_1_region_for_location(target_location: String) -> String:
    var mapping := {
        "hidden_well":"H01", "hidden_bell_chamber":"H02", "erased_third_street":"H03",
        "reflected_stairwell":"H04", "silent_bell_room":"H05", "erased_royal_name_corridor":"H06",
        "mirror_street":"H07", "primordial_hollow":"H08", "deep_research_depths":"A11"
    }
    return str(mapping.get(target_location, secret_id))


func _get_region_record_id() -> String:
    var normalized_id := region_record_id.strip_edges()
    return secret_id if normalized_id.is_empty() else normalized_id

func _has_required_sources() -> bool:
    for source_id in required_source_ids:
        if source_id not in WorldState.resonance_sources:
            return false
    return true

func update_reveal_state(
    active: bool,
    resonance: int,
    ancient_exposure: int,
    outer_exposure: int,
    debug_override: bool = false
) -> void:
    opened_permanently = WorldState.is_hidden_path_opened(secret_id)
    var meets_thresholds := (
        resonance >= required_resonance
        and ancient_exposure >= required_ancient_exposure
        and outer_exposure >= required_outer_exposure
        and _has_required_sources()
        and (not require_outer_god_resonance or WorldState.outer_god_resonance)
    )
    var allow_override := debug_override and allow_debug_override
    var next_revealed := opened_permanently or (active and (meets_thresholds or allow_override))
    if revealed == next_revealed:
        return
    revealed = next_revealed
    print(
        "[NEREIS][MAP][GATE] id=%s revealed=%s active=%s debug=%s resonance=%d/%d ancient=%d/%d outer=%d/%d sources_ok=%s opened=%s"
        % [
            secret_id,
            str(revealed),
            str(active),
            str(allow_override),
            resonance,
            required_resonance,
            ancient_exposure,
            required_ancient_exposure,
            outer_exposure,
            required_outer_exposure,
            str(_has_required_sources()),
            str(opened_permanently)
        ]
    )
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if (
        WorldState.input_locked
        or not hero_nearby
        or cooldown > 0.0
        or not INTERACTION_FOCUS_SCRIPT.is_focused(self)
    ):
        return

    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        cooldown = 0.7
        if opened_permanently:
            WorldState.mark_hidden_region_entered(_get_region_record_id())
            WorldState.pending_region_spawn_side = target_spawn_side
            WorldState.set_location(target_location_id)
            print("[NEREIS][MAP][GATE] enter id=%s target=%s location=%s spawn_side=%s" % [secret_id, target_scene_path, target_location_id, target_spawn_side])
            get_viewport().set_input_as_handled()
            SceneTransition.fade_to_scene(target_scene_path)
            return

        if not revealed:
            return
        WorldState.discover_hidden_region(_get_region_record_id())
        WorldState.open_hidden_path(secret_id)
        opened_permanently = true
        revealed = true
        opened.emit(secret_id)
        print("[NEREIS][SECRET] Resonance gate opened id=%s" % secret_id)
        queue_redraw()
        get_viewport().set_input_as_handled()

func _draw() -> void:
    # Draw the anomaly using the motif of its parent region. A mirror-street entrance
    # must never look like another well just because both gates share this component.
    # 根据入口类型绘制对应的异常意象，避免镜街入口也呈现为一口井。
    match secret_id:
        "H01":
            _draw_well_marker()
        "H02":
            _draw_early_bell_marker()
        "H03":
            _draw_erased_street_marker()
        "H04":
            _draw_reflected_stairs_marker()
        "H05":
            _draw_silent_window_marker()
        "H06":
            _draw_erased_royal_name_marker()
        "H07":
            _draw_mirror_street_marker()
        "C15":
            _draw_erased_royal_name_marker()
        "C19":
            _draw_silent_chapel_marker()
        "H08":
            _draw_breathing_wall_marker()
        _:
            _draw_generic_anomaly_marker()

    if hero_nearby and not WorldState.input_locked and INTERACTION_FOCUS_SCRIPT.is_focused(self):
        var prompt := "E  Descend" if opened_permanently else "E  Resonate"
        draw_string(
            ThemeDB.fallback_font,
            Vector2(-58.0, 36.0),
            NereisLocalization.translate_text(prompt),
            HORIZONTAL_ALIGNMENT_LEFT,
            -1.0,
            15,
            Color("#d6c7b2")
        )

func _draw_well_marker() -> void:
    # The physical well exists before it can be understood; only the abnormal depth is hidden.
    draw_rect(Rect2(-52.0, -5.0, 104.0, 24.0), Color("#28232b"))
    draw_arc(Vector2(0.0, -2.0), 42.0, PI, TAU, 28, Color("#665b5d"), 5.0)
    draw_arc(Vector2(0.0, -2.0), 30.0, PI, TAU, 24, Color("#3d343e"), 4.0)
    draw_rect(Rect2(-32.0, -1.0, 64.0, 17.0), Color("#111018"))

    if revealed:
        var tint := Color("#9ce0ce") if not opened_permanently else Color("#d6c7b2")
        draw_arc(Vector2(0.0, -8.0), 48.0, PI, TAU, 28, tint, 2.0)
        draw_line(Vector2(-24.0, -26.0), Vector2(24.0, 10.0), Color(tint.r, tint.g, tint.b, 0.85), 2.0)
        draw_line(Vector2(24.0, -26.0), Vector2(-24.0, 10.0), Color(tint.r, tint.g, tint.b, 0.85), 2.0)
        if opened_permanently:
            draw_line(Vector2(-14.0, -1.0), Vector2(-32.0, 45.0), tint, 3.0)
            draw_line(Vector2(14.0, -1.0), Vector2(32.0, 45.0), tint, 3.0)

func _draw_mirror_street_marker() -> void:
    # The clue is a puddle first; a door only appears after the player resonates with it.
    var puddle := PackedVector2Array([
        Vector2(-62.0, 8.0), Vector2(-52.0, -1.0), Vector2(-34.0, -7.0),
        Vector2(-9.0, -10.0), Vector2(21.0, -7.0), Vector2(47.0, -2.0),
        Vector2(61.0, 7.0), Vector2(46.0, 14.0), Vector2(17.0, 17.0),
        Vector2(-16.0, 16.0), Vector2(-43.0, 13.0)
    ])
    draw_colored_polygon(puddle, Color("#17262c"))
    draw_polyline(PackedVector2Array([
        Vector2(-43.0, 5.0), Vector2(-21.0, 2.0), Vector2(2.0, 4.0),
        Vector2(29.0, 1.0), Vector2(46.0, 5.0)
    ]), Color("#52676b"), 2.0, true)

    if revealed:
        var tint := Color("#9ce0ce") if not opened_permanently else Color("#d6c7b2")
        draw_arc(Vector2(0.0, 3.0), 56.0, PI, TAU, 32, tint, 2.0)
        # A doorway reflected in water: the verticals bend away from each other.
        draw_line(Vector2(-22.0, 4.0), Vector2(-17.0, -36.0), tint, 2.0)
        draw_line(Vector2(22.0, 4.0), Vector2(17.0, -36.0), tint, 2.0)
        draw_line(Vector2(-17.0, -36.0), Vector2(17.0, -36.0), tint, 2.0)
        draw_line(Vector2(-35.0, -1.0), Vector2(-29.0, -5.0), Color(tint.r, tint.g, tint.b, 0.9), 2.0)
        draw_line(Vector2(31.0, 0.0), Vector2(37.0, 5.0), Color(tint.r, tint.g, tint.b, 0.9), 2.0)
        if opened_permanently:
            draw_line(Vector2(-13.0, 4.0), Vector2(-10.0, -24.0), tint, 3.0)
            draw_line(Vector2(13.0, 4.0), Vector2(10.0, -24.0), tint, 3.0)

func _draw_early_bell_marker() -> void:
    # The bell is stationary; the displaced arcs represent sound arriving from the wrong direction.
    draw_arc(Vector2(0.0, -12.0), 25.0, PI, TAU, 28, Color("#625568"), 3.0)
    draw_line(Vector2(-25.0, -12.0), Vector2(-25.0, 16.0), Color("#625568"), 3.0)
    draw_line(Vector2(25.0, -12.0), Vector2(25.0, 16.0), Color("#625568"), 3.0)
    draw_line(Vector2(-34.0, 16.0), Vector2(34.0, 16.0), Color("#625568"), 3.0)
    draw_line(Vector2(0.0, -45.0), Vector2(0.0, -6.0), Color("#83728c"), 2.0)
    if revealed:
        var tint := Color("#9ce0ce") if not opened_permanently else Color("#d6c7b2")
        for radius in [38.0, 48.0, 58.0]:
            draw_arc(Vector2(0.0, -8.0), radius, PI * 1.08, PI * 1.58, 18, tint, 2.0)
        draw_line(Vector2(-9.0, -1.0), Vector2(9.0, -1.0), tint, 2.0)

func _draw_erased_street_marker() -> void:
    # A street sign with a blank third arm.
    draw_rect(Rect2(-4.0, -8.0, 8.0, 38.0), Color("#5b4c51"))
    draw_rect(Rect2(-34.0, -22.0, 68.0, 13.0), Color("#3b343d"))
    draw_rect(Rect2(-34.0, -2.0, 55.0, 13.0), Color("#3b343d"))
    draw_line(Vector2(2.0, -13.0), Vector2(35.0, -30.0), Color("#5b4c51"), 4.0)
    if revealed:
        var tint := Color("#9ce0ce") if not opened_permanently else Color("#d6c7b2")
        draw_line(Vector2(2.0, -13.0), Vector2(42.0, -42.0), tint, 2.0)
        draw_line(Vector2(42.0, -42.0), Vector2(42.0, -25.0), tint, 2.0)
        draw_arc(Vector2(18.0, -13.0), 48.0, PI * 1.25, PI * 1.95, 24, tint, 2.0)

func _draw_reflected_stairs_marker() -> void:
    # The reflected steps climb in the opposite direction to the real ones.
    draw_rect(Rect2(-42.0, 9.0, 84.0, 12.0), Color("#24323a"))
    draw_polyline(PackedVector2Array([
        Vector2(-34.0, 5.0), Vector2(-16.0, 5.0), Vector2(-16.0, -7.0),
        Vector2(2.0, -7.0), Vector2(2.0, -19.0), Vector2(20.0, -19.0),
        Vector2(20.0, -31.0), Vector2(35.0, -31.0)
    ]), Color("#587680"), 3.0, true)
    if revealed:
        var tint := Color("#9ce0ce") if not opened_permanently else Color("#d6c7b2")
        draw_polyline(PackedVector2Array([
            Vector2(-35.0, -34.0), Vector2(-18.0, -34.0), Vector2(-18.0, -22.0),
            Vector2(0.0, -22.0), Vector2(0.0, -10.0), Vector2(18.0, -10.0),
            Vector2(18.0, 2.0), Vector2(35.0, 2.0)
        ]), tint, 2.0, true)
        draw_line(Vector2(-48.0, 25.0), Vector2(48.0, 25.0), Color(tint.r, tint.g, tint.b, 0.65), 2.0)

func _draw_silent_window_marker() -> void:
    draw_rect(Rect2(-35.0, -4.0, 70.0, 28.0), Color("#2a2632"))
    draw_arc(Vector2(0.0, -8.0), 30.0, PI, TAU, 26, Color("#665d70"), 4.0)
    draw_line(Vector2(-30.0, -8.0), Vector2(-30.0, 24.0), Color("#665d70"), 3.0)
    draw_line(Vector2(30.0, -8.0), Vector2(30.0, 24.0), Color("#665d70"), 3.0)
    draw_line(Vector2(0.0, -35.0), Vector2(0.0, 20.0), Color("#665d70"), 2.0)
    if revealed:
        var tint := Color("#9ce0ce") if not opened_permanently else Color("#d6c7b2")
        draw_arc(Vector2(0.0, -8.0), 42.0, PI, TAU, 28, tint, 2.0)
        draw_line(Vector2(-22.0, -1.0), Vector2(22.0, -1.0), tint, 2.0)
        draw_line(Vector2(-22.0, 11.0), Vector2(22.0, 11.0), tint, 2.0)
        draw_arc(Vector2(0.0, 8.0), 51.0, 0.0, TAU, 28, Color(tint.r, tint.g, tint.b, 0.7), 2.0)

func _draw_erased_royal_name_marker() -> void:
    # The sign is a stone inscription first; only the missing name is anomalous.
    draw_rect(Rect2(-42.0, -28.0, 84.0, 58.0), Color("#302b31"))
    draw_rect(Rect2(-35.0, -21.0, 70.0, 44.0), Color("#24212a"))
    draw_line(Vector2(-25.0, -11.0), Vector2(22.0, -11.0), Color("#5c5052"), 2.0)
    draw_line(Vector2(-25.0, 1.0), Vector2(25.0, 1.0), Color("#5c5052"), 2.0)
    draw_line(Vector2(-25.0, 13.0), Vector2(12.0, 13.0), Color("#5c5052"), 2.0)
    if revealed:
        var tint := Color("#9ce0ce") if not opened_permanently else Color("#d6c7b2")
        draw_line(Vector2(-23.0, -3.0), Vector2(-7.0, 7.0), tint, 2.0)
        draw_line(Vector2(-7.0, 7.0), Vector2(1.0, -3.0), tint, 2.0)
        draw_line(Vector2(7.0, -3.0), Vector2(24.0, 8.0), tint, 2.0)
        draw_arc(Vector2(0.0, 1.0), 54.0, PI * 1.08, PI * 1.92, 24, tint, 2.0)

func _draw_silent_chapel_marker() -> void:
    # A chapel window without a shadow; the bell-shaped arch appears only under resonance.
    draw_rect(Rect2(-42.0, -4.0, 84.0, 27.0), Color("#29242e"))
    draw_arc(Vector2(0.0, -9.0), 31.0, PI, TAU, 28, Color("#5c5361"), 4.0)
    draw_line(Vector2(-31.0, -9.0), Vector2(-31.0, 21.0), Color("#5c5361"), 3.0)
    draw_line(Vector2(31.0, -9.0), Vector2(31.0, 21.0), Color("#5c5361"), 3.0)
    if revealed:
        var tint := Color("#9ce0ce") if not opened_permanently else Color("#d6c7b2")
        draw_arc(Vector2(0.0, -9.0), 42.0, PI, TAU, 28, tint, 2.0)
        draw_line(Vector2(0.0, -33.0), Vector2(0.0, 12.0), tint, 2.0)
        draw_line(Vector2(-18.0, -7.0), Vector2(18.0, -7.0), tint, 2.0)
        draw_line(Vector2(-18.0, 5.0), Vector2(18.0, 5.0), tint, 2.0)

func _draw_breathing_wall_marker() -> void:
    # The wall should feel grown, not mechanical.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-44.0, 13.0), Vector2(-35.0, -8.0), Vector2(-18.0, -17.0),
        Vector2(-6.0, -10.0), Vector2(4.0, -34.0), Vector2(23.0, -22.0),
        Vector2(38.0, -4.0), Vector2(42.0, 15.0), Vector2(22.0, 24.0),
        Vector2(-7.0, 19.0)
    ]), Color("#202b31"))
    draw_polyline(PackedVector2Array([
        Vector2(-30.0, 8.0), Vector2(-15.0, 0.0), Vector2(-7.0, 9.0),
        Vector2(3.0, -13.0), Vector2(17.0, -4.0), Vector2(29.0, 11.0)
    ]), Color("#3e555a"), 2.0, true)
    if revealed:
        var tint := Color("#9ce0ce") if not opened_permanently else Color("#d6c7b2")
        draw_arc(Vector2(0.0, 0.0), 48.0, PI * 1.05, PI * 1.95, 28, tint, 2.0)
        draw_arc(Vector2(0.0, 0.0), 35.0, PI * 0.05, PI * 0.95, 28, Color(tint.r, tint.g, tint.b, 0.75), 2.0)
        draw_line(Vector2(-6.0, -23.0), Vector2(-1.0, -5.0), tint, 2.0)
        draw_line(Vector2(-1.0, -5.0), Vector2(8.0, 12.0), tint, 2.0)
        draw_line(Vector2(8.0, 12.0), Vector2(17.0, -8.0), tint, 2.0)
        if opened_permanently:
            draw_arc(Vector2(0.0, 0.0), 55.0, 0.0, TAU, 32, tint, 2.0)

func _draw_generic_anomaly_marker() -> void:
    draw_colored_polygon(PackedVector2Array([
        Vector2(-36.0, 8.0), Vector2(-20.0, -13.0), Vector2(-5.0, -8.0),
        Vector2(10.0, -29.0), Vector2(31.0, -8.0), Vector2(35.0, 11.0),
        Vector2(12.0, 18.0), Vector2(-11.0, 14.0)
    ]), Color("#28232b"))
    if revealed:
        var tint := Color("#9ce0ce") if not opened_permanently else Color("#d6c7b2")
        draw_line(Vector2(-22.0, 9.0), Vector2(-9.0, -9.0), tint, 2.0)
        draw_line(Vector2(-9.0, -9.0), Vector2(1.0, 3.0), tint, 2.0)
        draw_line(Vector2(1.0, 3.0), Vector2(16.0, -19.0), tint, 2.0)
        draw_line(Vector2(16.0, -19.0), Vector2(24.0, 5.0), tint, 2.0)
        if opened_permanently:
            draw_arc(Vector2(0.0, 0.0), 48.0, 0.0, TAU, 28, tint, 2.0)
