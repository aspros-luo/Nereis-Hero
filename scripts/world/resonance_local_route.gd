extends Node2D
## A local route inside an already explored map, revealed by Resonance Sight.
## 在已探索地图内部显现的局部路线，由鸣响 / 灵视揭示。

signal opened(route_id: String)

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

@export var route_id: String = "A3_THIRD_STREET_ROOFLINE"
@export var required_resonance: int = 28
@export var bridge_start_x: float = 1690.0
@export var bridge_end_x: float = 2050.0
@export var bridge_y: float = 350.0

var revealed := false
var opened_permanently := false
var hero_nearby := false
var cooldown := 0.0
@export var prompt_text: String = "E  ANCHOR THE THIRD STREET"

@onready var bridge_body: StaticBody2D = $BridgeBody

func _ready() -> void:
    add_to_group("resonance_hidden_targets")
    opened_permanently = WorldState.is_hidden_path_opened(route_id)
    update_reveal_state(
        WorldState.resonance_sight_active,
        WorldState.hero_resonance,
        WorldState.ancient_exposure,
        WorldState.outer_exposure,
        WorldState.debug_ability_override_active
    )
    queue_redraw()

func _process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    opened_permanently = WorldState.is_hidden_path_opened(route_id)
    var hero := get_node_or_null("../Hero") as Node2D
    var bridge_center := Vector2((bridge_start_x + bridge_end_x) * 0.5, bridge_y)
    # Focus arbitration must measure this composite route at its bridge anchor, not at the root origin (0, 0).
    # 共享焦点仲裁必须以桥体锚点计算距离，不能把根节点原点 (0, 0) 当作交互位置。
    set_meta("interaction_focus_position", to_global(bridge_center))
    hero_nearby = hero != null and hero.global_position.distance_to(to_global(bridge_center)) <= 105.0
    # Keep a temporary bridge solid while the Hero is standing on it, even if Sight expires.
    # 即使灵视计时结束，只要主角仍站在临时桥体上，就暂时保留碰撞，避免脚下消失。
    _sync_bridge_collision()
    var available := (
        not WorldState.input_locked
        and hero_nearby
        and cooldown <= 0.0
        and revealed
        and not opened_permanently
    )
    INTERACTION_FOCUS_SCRIPT.sync(self, available, 30)
    queue_redraw()

func update_reveal_state(
    sight_active: bool,
    resonance: int,
    _ancient_exposure: int,
    _outer_exposure: int,
    debug_override: bool = false
) -> void:
    opened_permanently = WorldState.is_hidden_path_opened(route_id)
    revealed = opened_permanently or debug_override or (sight_active and resonance >= required_resonance)
    _sync_bridge_collision()
    queue_redraw()

func _hero_over_bridge() -> bool:
    var hero := get_node_or_null("../Hero") as Node2D
    if hero == null:
        return false
    var hero_local := to_local(hero.global_position)
    return (
        hero_local.x >= bridge_start_x - 24.0
        and hero_local.x <= bridge_end_x + 24.0
        and absf(hero_local.y - bridge_y) <= 72.0
    )

func _sync_bridge_collision() -> void:
    var should_exist := revealed or opened_permanently or _hero_over_bridge()
    var collision := bridge_body.get_node("CollisionShape2D") as CollisionShape2D
    var rectangle := collision.shape as RectangleShape2D
    bridge_body.position = Vector2(bridge_start_x, bridge_y)
    rectangle.size = Vector2(bridge_end_x - bridge_start_x, 18.0)
    collision.position = rectangle.size * 0.5
    collision.one_way_collision = true
    collision.disabled = not should_exist
    bridge_body.visible = should_exist
func _unhandled_input(event: InputEvent) -> void:
    if (
        WorldState.input_locked
        or not hero_nearby
        or cooldown > 0.0
        or opened_permanently
        or not revealed
        or not INTERACTION_FOCUS_SCRIPT.is_focused(self)
    ):
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        cooldown = 0.7
        WorldState.open_hidden_path(route_id)
        opened_permanently = true
        revealed = true
        _sync_bridge_collision()
        opened.emit(route_id)
        print("[NEREIS][MAP][LOCAL_ROUTE] permanently_opened id=%s" % route_id)
        get_viewport().set_input_as_handled()

func _draw() -> void:
    if revealed or opened_permanently or _hero_over_bridge():
        var width := bridge_end_x - bridge_start_x
        var bridge_color := Color("#667d6b") if opened_permanently else Color("#536b75")
        var edge_color := Color("#c1d6ad") if opened_permanently else Color("#9bb5b9")
        draw_rect(Rect2(bridge_start_x, bridge_y, width, 18.0), bridge_color)
        draw_line(
            Vector2(bridge_start_x, bridge_y),
            Vector2(bridge_end_x, bridge_y),
            edge_color,
            3.0
        )
        for x in range(int(bridge_start_x + 24.0), int(bridge_end_x), 48):
            draw_line(Vector2(x, bridge_y + 2.0), Vector2(x - 8.0, bridge_y + 16.0), Color("#26323a"), 2.0)
        draw_circle(Vector2(bridge_start_x + 8.0, bridge_y - 8.0), 4.0, edge_color)
        draw_circle(Vector2(bridge_end_x - 8.0, bridge_y - 8.0), 4.0, edge_color)
        if hero_nearby and not WorldState.input_locked and revealed and not opened_permanently and INTERACTION_FOCUS_SCRIPT.is_focused(self):
            draw_string(
                ThemeDB.fallback_font,
                Vector2((bridge_start_x + bridge_end_x) * 0.5 - 88.0, bridge_y - 14.0),
                prompt_text,
                HORIZONTAL_ALIGNMENT_LEFT,
                -1.0,
                13,
                Color("#d6c7b2")
            )
    else:
        # Three pale scratches hint that the absent street has a physical anchor.
        # 三道浅色刻痕提示这条不存在的街道仍有实体锚点。
        draw_line(Vector2(bridge_start_x, bridge_y - 4.0), Vector2(bridge_start_x + 16.0, bridge_y - 12.0), Color("#5c5667"), 2.0)
        draw_line(Vector2(bridge_start_x + 6.0, bridge_y + 2.0), Vector2(bridge_start_x + 22.0, bridge_y - 6.0), Color("#5c5667"), 2.0)
        draw_line(Vector2(bridge_start_x + 12.0, bridge_y + 8.0), Vector2(bridge_start_x + 28.0, bridge_y), Color("#5c5667"), 2.0)
