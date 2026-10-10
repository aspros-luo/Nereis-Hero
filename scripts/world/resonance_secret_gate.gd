extends Node2D
## A persistent Resonance Sight gate. Revealing is temporary; opening is saved.
## 持久化灵视入口：显现是临时感知，开启状态写入存档。

signal opened(secret_id: String)

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

@export var secret_id: String = "H01"
@export var target_scene_path: String = "res://scenes/hidden_well.tscn"
@export var target_location_id: String = "hidden_well"
@export_enum("west", "east") var target_spawn_side: String = "west"
@export_range(0, 100, 1) var required_resonance: int = 12
@export_range(0, 100, 1) var required_ancient_exposure: int = 0
@export_range(0, 100, 1) var required_outer_exposure: int = 0
@export var require_outer_god_resonance: bool = false
@export var required_source_ids: Array[String] = []
@export var interaction_radius: float = 80.0
@export var allow_debug_override: bool = false

var revealed := false
var opened_permanently := false
var hero_nearby := false
var cooldown := 0.0

func _ready() -> void:
    set_meta("interaction_priority", 25)
    add_to_group("resonance_hidden_targets")
    opened_permanently = WorldState.is_hidden_path_opened(secret_id)
    update_reveal_state(
        WorldState.resonance_sight_active,
        WorldState.hero_resonance,
        WorldState.ancient_exposure,
        WorldState.outer_exposure
    )
    queue_redraw()

func _process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    opened_permanently = WorldState.is_hidden_path_opened(secret_id)
    update_reveal_state(
        WorldState.resonance_sight_active,
        WorldState.hero_resonance,
        WorldState.ancient_exposure,
        WorldState.outer_exposure
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
            WorldState.mark_hidden_region_entered(secret_id)
            WorldState.pending_region_spawn_side = target_spawn_side
            WorldState.set_location(target_location_id)
            get_viewport().set_input_as_handled()
            SceneTransition.fade_to_scene(target_scene_path)
            return

        if not revealed:
            return
        WorldState.discover_hidden_region(secret_id)
        WorldState.open_hidden_path(secret_id)
        opened_permanently = true
        revealed = true
        opened.emit(secret_id)
        print("[NEREIS][SECRET] Resonance gate opened id=%s" % secret_id)
        queue_redraw()
        get_viewport().set_input_as_handled()

func _draw() -> void:
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

    if hero_nearby and not WorldState.input_locked and INTERACTION_FOCUS_SCRIPT.is_focused(self):
        var prompt := "E  Descend" if opened_permanently else "E  Resonate"
        draw_string(
            ThemeDB.fallback_font,
            Vector2(-52.0, 17.0),
            NereisLocalization.translate_text(prompt),
            HORIZONTAL_ALIGNMENT_LEFT,
            -1.0,
            15,
            Color("#d6c7b2")
        )
