extends Node2D

signal interacted(interaction_id: String, title: String, message: String)

const INTERACTION_RANGE := 95.0
const VILLAGE_HOUSE_DOOR_POSITION := Vector2(455, 520)
const VILLAGE_HOUSE_DOOR_EXCLUSION_RANGE := 105.0
const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")
const VILLAGE_VISUAL_SCENE = preload("res://scenes/characters/mite_village_visual.tscn")

var hero_nearby := false
var interaction_cooldown := 0.0
var elapsed := 0.0
var character_visual: Node2D
var aura: Line2D
var glow: Polygon2D
var control_mark: Polygon2D
var name_label: Label
var prompt_label: Label

func _ready() -> void:
    set_meta("interaction_priority", 80)
    if not has_node("MiteVisual"):
        var visual := VILLAGE_VISUAL_SCENE.instantiate()
        visual.name = "MiteVisual"
        add_child(visual)
    var visual_root: Node = get_node("MiteVisual")
    character_visual = visual_root.get_node("CharacterVisual") as Node2D
    aura = visual_root.get_node("Aura") as Line2D
    glow = visual_root.get_node("Glow") as Polygon2D
    control_mark = visual_root.get_node("ControlMark") as Polygon2D
    name_label = visual_root.get_node("NameLabel") as Label
    prompt_label = visual_root.get_node("PromptLabel") as Label
    name_label.text = NereisLocalization.translate_text("MITE")
    prompt_label.text = NereisLocalization.translate_text("E  Talk")
    _refresh_visual_state()
    print("[NEREIS][NPC] Mite initialized")

func _process(delta: float) -> void:
    elapsed += delta
    interaction_cooldown = maxf(0.0, interaction_cooldown - delta)

    var hero := get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= INTERACTION_RANGE
    var available := not WorldState.input_locked and hero_nearby and not _blocked_by_village_house_door(hero) and interaction_cooldown <= 0.0 and not _select_interaction().is_empty()
    INTERACTION_FOCUS_SCRIPT.sync(self, available, 80)

    _refresh_visual_state()

func _refresh_visual_state() -> void:
    if character_visual == null:
        return
    var control_stage: int = WorldState.mite_control_stage
    character_visual.modulate = Color("#ffffff") if control_stage == 0 else (Color("#e4d5e2") if control_stage == 1 else (Color("#d9bddb") if control_stage == 2 else Color("#d4a9c5")))
    aura.visible = control_stage >= 2
    control_mark.visible = control_stage >= 3
    glow.scale = Vector2.ONE * (1.0 + sin(elapsed * 1.4) * 0.035)
    prompt_label.visible = can_interact()
    prompt_label.text = NereisLocalization.translate_text("E  Talk")

func can_interact() -> bool:
    if WorldState.input_locked or not hero_nearby or interaction_cooldown > 0.0:
        return false
    if _blocked_by_village_house_door(get_node_or_null("../Hero") as Node2D):
        return false
    if _select_interaction().is_empty():
        return false
    return INTERACTION_FOCUS_SCRIPT.is_focused(self)

func _unhandled_input(event: InputEvent) -> void:
    if not can_interact():
        return

    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        interaction_cooldown = 0.55
        var interaction_id := _select_interaction()
        if interaction_id.is_empty():
            return

        var payload := _payload_for(interaction_id)
        if not WorldState.record_mite_interaction(interaction_id):
            return
        interacted.emit(interaction_id, str(payload.get("title", "MITE")), str(payload.get("message", "")))
        var viewport := get_viewport()
        if viewport:
            viewport.set_input_as_handled()
        print("[NEREIS][NPC] Mite interaction id=%s" % interaction_id)

func _blocked_by_village_house_door(hero: Node2D) -> bool:
    if hero == null or WorldState.current_location != "village":
        return false
    return hero.global_position.distance_to(VILLAGE_HOUSE_DOOR_POSITION) <= VILLAGE_HOUSE_DOOR_EXCLUSION_RANGE

func _select_interaction() -> String:
    if WorldState.mite_last_interaction_location == WorldState.current_location:
        return ""

    if WorldState.outer_god_resonance:
        if not WorldState.has_mite_interaction("mite_resonance_1"):
            return "mite_resonance_1"
        if not WorldState.has_mite_interaction("mite_resonance_2"):
            return "mite_resonance_2"
        if not WorldState.has_mite_interaction("mite_resonance_3"):
            return "mite_resonance_3"

    if not WorldState.mite_first_meeting:
        return "mite_first_meeting"
    if not WorldState.has_mite_interaction("mite_meal"):
        return "mite_meal"
    if not WorldState.has_mite_interaction("mite_stay_a_while"):
        return "mite_stay_a_while"
    if not WorldState.has_mite_interaction("mite_return"):
        return "mite_return"
    return "mite_quiet"

func _payload_for(interaction_id: String) -> Dictionary:
    match interaction_id:
        "mite_first_meeting":
            return {
                "title": "MITE",
                "message": "The girl kneels beside the old wooden table.\n\n\"You're awake. Good.\"\n\nShe studies your bandaged hands, then looks at the sword.\n\n\"Were you always this quiet?\"\n\nThere is no fear in her voice. Only curiosity."
            }
        "mite_meal":
            return {
                "title": "MITE",
                "message": "She pushes a warm bowl toward you.\n\n\"Eat before you leave.\"\n\nA small pause.\n\n\"You can tell me later where you are going.\"\n\nShe says it as though there is no reason you should refuse."
            }
        "mite_stay_a_while":
            return {
                "title": "MITE",
                "message": "Mite sits beside the doorway instead of looking at the road.\n\n\"You keep staring at the church path.\"\n\nShe looks at you.\n\n\"You don't have to go yet.\"\n\nShe pats the empty space beside her."
            }
        "mite_return":
            return {
                "title": "MITE",
                "message": "The light is fading from the village.\n\n\"You came back.\"\n\nMite smiles, almost relieved.\n\n\"I thought you might forget the way.\"\n\nShe does not explain why that thought bothered her."
            }
        "mite_resonance_1":
            return {
                "title": "MITE",
                "message": "Mite pauses beside the window.\n\n\"Did you hear something in your sleep?\"\n\nShe smiles when you shake your head.\n\n\"I did.\""
            }
        "mite_resonance_2":
            return {
                "title": "MITE",
                "message": "She watches the fire for a long time.\n\n\"Do you think two people can have the same dream?\"\n\nShe asks as if the answer should be obvious."
            }
        "mite_resonance_3":
            return {
                "title": "MITE",
                "message": "Mite takes your hand.\n\n\"Don't go to the Church tonight.\"\n\nHer fingers tighten.\n\n\"I don't want you to leave me alone.\""
            }
        _:
            return {
                "title": "MITE",
                "message": "Mite watches the road with you.\n\nFor a while, neither of you says anything.\n\nThe silence is easy."
            }

