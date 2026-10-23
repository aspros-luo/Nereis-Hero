extends Node2D

signal interacted

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")
const HUMANOID_VISUAL_SCENE = preload("res://scenes/characters/humanoid_character_visual.tscn")
const NPC_LABELS_SCENE = preload("res://scenes/world/route_npc_labels.tscn")

@export var npc_id: String = ""
@export var display_name: String = ""
@export_multiline var dialogue: String = ""
@export_range(40.0, 140.0, 5.0) var interaction_range: float = 100.0
@export var skin_color: Color = Color("#8d7566")
@export var cloth_color: Color = Color("#49424a")

var cooldown := 0.0
var hero_nearby := false
var character_visual: HumanoidCharacterVisual
var name_label: Label
var prompt_label: Label

func _ready() -> void:
    character_visual = get_node_or_null("CharacterVisual") as HumanoidCharacterVisual
    if character_visual == null:
        character_visual = HUMANOID_VISUAL_SCENE.instantiate() as HumanoidCharacterVisual
        character_visual.name = "CharacterVisual"
        character_visual.position = Vector2(0.0, -20.0)
        character_visual.skin_color = skin_color
        character_visual.cloth_color = cloth_color
        add_child(character_visual)

    var labels := get_node_or_null("Labels")
    if labels == null:
        labels = NPC_LABELS_SCENE.instantiate()
        labels.name = "Labels"
        add_child(labels)
    name_label = labels.get_node("NameLabel") as Label
    prompt_label = labels.get_node("PromptLabel") as Label
    name_label.text = NereisLocalization.translate_text(display_name)
    prompt_label.text = NereisLocalization.translate_text("E  Speak")
    set_meta("interaction_priority", 60)
    print("[NEREIS][NPC] %s initialized id=%s" % [display_name, npc_id])
func _process(delta: float) -> void:
    cooldown = max(0.0, cooldown - delta)
    var hero: Node2D = get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= interaction_range
    if hero != null and not is_zero_approx(hero.global_position.x - global_position.x):
        character_visual.set_facing(signf(hero.global_position.x - global_position.x))
    var available := not WorldState.input_locked and hero_nearby and cooldown <= 0.0 and not display_name.is_empty() and not dialogue.is_empty()
    INTERACTION_FOCUS_SCRIPT.sync(self, available, 60)
    if name_label != null:
        name_label.text = NereisLocalization.translate_text(display_name)
    if prompt_label != null:
        prompt_label.visible = available
        prompt_label.text = NereisLocalization.translate_text("E  Speak")

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

