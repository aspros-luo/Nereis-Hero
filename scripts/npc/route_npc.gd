extends Node2D

signal interacted

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")
const HUMANOID_VISUAL_SCENE = preload("res://scenes/characters/humanoid_character_visual.tscn")

@export var npc_id: String = ""
@export var display_name: String = ""
@export_multiline var dialogue: String = ""
@export_range(40.0, 140.0, 5.0) var interaction_range: float = 100.0
@export var skin_color: Color = Color("#8d7566")
@export var cloth_color: Color = Color("#49424a")

var cooldown := 0.0
var hero_nearby := false
var character_visual: HumanoidCharacterVisual

func _ready() -> void:
    character_visual = HUMANOID_VISUAL_SCENE.instantiate() as HumanoidCharacterVisual
    character_visual.name = "CharacterVisual"
    character_visual.position = Vector2(0.0, -20.0)
    character_visual.skin_color = skin_color
    character_visual.cloth_color = cloth_color
    add_child(character_visual)
    set_meta("interaction_priority", 60)
    print("[NEREIS][NPC] %s initialized id=%s" % [display_name, npc_id])
    queue_redraw()

func _process(delta: float) -> void:
    cooldown = max(0.0, cooldown - delta)
    var hero: Node2D = get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= interaction_range
    if hero != null and not is_zero_approx(hero.global_position.x - global_position.x):
        character_visual.set_facing(signf(hero.global_position.x - global_position.x))
    var available := not WorldState.input_locked and hero_nearby and cooldown <= 0.0 and not display_name.is_empty() and not dialogue.is_empty()
    INTERACTION_FOCUS_SCRIPT.sync(self, available, 60)
    queue_redraw()

func can_interact() -> bool:
    return (
        not WorldState.input_locked
        and hero_nearby
        and cooldown <= 0.0
        and not display_name.is_empty()
        and not dialogue.is_empty()
        and INTERACTION_FOCUS_SCRIPT.is_focused(self)
    )

func _unhandled_input(event: InputEvent) -> void:
    if not can_interact():
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        cooldown = 0.5
        interacted.emit()
        print("[NEREIS][NPC] Interaction id=%s" % npc_id)
        var viewport := get_viewport()
        if viewport:
            viewport.set_input_as_handled()

func _draw() -> void:
    # The reusable rig owns the character silhouette; this node only draws interaction text.
    # 角色轮廓由可复用骨架表现层负责；此节点仅绘制名称和交互提示。
    draw_string(ThemeDB.fallback_font, Vector2(-58, -76), NereisLocalization.translate_text(display_name), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#b7a09b"))
    if can_interact():
        draw_string(ThemeDB.fallback_font, Vector2(-50, 28), NereisLocalization.translate_text("E  Speak"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d6c7b2"))
