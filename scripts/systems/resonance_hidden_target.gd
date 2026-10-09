extends Node2D
## Reusable target component for hidden traces, disguised foes and anomalous objects.
## 可复用的隐藏痕迹、伪装敌人与异常物件组件。

@export var required_resonance := 0
@export var required_ancient_exposure := 0
@export var required_outer_exposure := 0
@export var target_label := "HIDDEN TRACE"
@export var debug_fixture := false
# Optional CanvasItem to reveal/hide alongside this target marker.
# 可选的场景视觉节点：随本目标一起显现/隐藏。
@export var reveal_target_path: NodePath = NodePath("")
var revealed := false
var _reveal_target: CanvasItem

func _ready() -> void:
    add_to_group("resonance_hidden_targets")
    if not reveal_target_path.is_empty():
        _reveal_target = get_node_or_null(reveal_target_path) as CanvasItem
        if is_instance_valid(_reveal_target):
            _reveal_target.visible = false
    queue_redraw()
    if WorldState.resonance_sight_active:
        update_reveal_state(true, WorldState.hero_resonance, WorldState.ancient_exposure, WorldState.outer_exposure)

func configure(resonance: int, ancient: int, outer: int, label: String, is_debug_fixture: bool = false) -> void:
    required_resonance = maxi(0, resonance)
    required_ancient_exposure = maxi(0, ancient)
    required_outer_exposure = maxi(0, outer)
    target_label = label
    debug_fixture = is_debug_fixture
    queue_redraw()

func update_reveal_state(active: bool, resonance: int, ancient_exposure: int, outer_exposure: int, debug_override: bool = false) -> void:
    var meets_thresholds := resonance >= required_resonance and ancient_exposure >= required_ancient_exposure and outer_exposure >= required_outer_exposure
    var next_revealed := active and (debug_override or meets_thresholds)
    if revealed == next_revealed:
        return
    revealed = next_revealed
    if is_instance_valid(_reveal_target):
        _reveal_target.visible = revealed
    queue_redraw()
    if debug_fixture:
        print("[NEREIS][SENSE] %s %s" % [target_label, "revealed" if revealed else "hidden"])

func _draw() -> void:
    if not revealed:
        return
    var tint := Color("#9ce0ce")
    draw_circle(Vector2.ZERO, 4.0, tint)
    draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 24, Color(tint.r, tint.g, tint.b, 0.9), 2.0)
    draw_line(Vector2(-12.0, -12.0), Vector2(12.0, 12.0), Color(tint.r, tint.g, tint.b, 0.7), 1.0)
    draw_line(Vector2(12.0, -12.0), Vector2(-12.0, 12.0), Color(tint.r, tint.g, tint.b, 0.7), 1.0)
    draw_string(ThemeDB.fallback_font, Vector2(22.0, 4.0), target_label, HORIZONTAL_ALIGNMENT_LEFT, 160.0, 10, tint)
