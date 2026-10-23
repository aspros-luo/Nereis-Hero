extends Node2D

signal interacted

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")
const POI_VISUAL_SCENE = preload("res://scenes/world/village_poi_visual.tscn")

@export var poi_id: String = ""
@export var display_name: String = ""
@export_multiline var dialogue: String = ""
@export_range(40.0, 140.0, 5.0) var interaction_range: float = 110.0

var cooldown := 0.0
var hero_nearby := false
var prompt_label: Label

func _ready() -> void:
    set_meta("interaction_priority", 40)
    if not has_node("POIVisual"):
        var visual := POI_VISUAL_SCENE.instantiate()
        visual.name = "POIVisual"
        add_child(visual)
    prompt_label = get_node("POIVisual/PromptLabel") as Label
    prompt_label.text = NereisLocalization.translate_text("E  Examine")
    prompt_label.visible = false

func _process(delta: float) -> void:
    cooldown = max(0.0, cooldown - delta)
    var hero: Node2D = get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= interaction_range
    var available := not WorldState.input_locked and hero_nearby and cooldown <= 0.0 and not display_name.is_empty() and not dialogue.is_empty()
    INTERACTION_FOCUS_SCRIPT.sync(self, available, 40)
    if prompt_label != null:
        prompt_label.visible = available
        prompt_label.text = NereisLocalization.translate_text("E  Examine")

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
        print("[NEREIS][VILLAGE] POI interacted id=%s" % poi_id)
        var viewport := get_viewport()
        if viewport:
            viewport.set_input_as_handled()

