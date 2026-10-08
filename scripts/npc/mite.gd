extends Node2D

signal interacted(interaction_id: String, title: String, message: String)

const INTERACTION_RANGE := 110.0
const VILLAGE_HOUSE_DOOR_POSITION := Vector2(455, 520)
const VILLAGE_HOUSE_DOOR_EXCLUSION_RANGE := 105.0
const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

var hero_nearby := false
var interaction_cooldown := 0.0
var elapsed := 0.0

func _ready() -> void:
    print("[NEREIS][NPC] Mite initialized")
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    interaction_cooldown = maxf(0.0, interaction_cooldown - delta)

    var hero := get_node_or_null("../Hero") as Node2D
    hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= INTERACTION_RANGE
    var available := not WorldState.input_locked and hero_nearby and not _blocked_by_village_house_door(hero) and interaction_cooldown <= 0.0 and not _select_interaction().is_empty()
    INTERACTION_FOCUS_SCRIPT.sync(self, available)

    queue_redraw()

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
        get_viewport().set_input_as_handled()
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

func _draw() -> void:
    var sway := sin(elapsed * 1.7) * 2.0
    var glow := 0.12 + sin(elapsed * 1.4) * 0.035
    var control_stage: int = WorldState.mite_control_stage

    var skin := Color("#b38d82")
    var dress := Color("#61505d")
    var shadow := Color("#211a20")

    if control_stage == 1:
        skin = Color("#ad8882")
        dress = Color("#5d4f5e")
    elif control_stage == 2:
        skin = Color("#a47e7f")
        dress = Color("#5b4a5c")
    elif control_stage >= 3:
        skin = Color("#9d777d")
        dress = Color("#56455a")
        shadow = Color("#261d28")

    draw_circle(Vector2(0, -34), 16.0, skin)
    draw_circle(Vector2(-5, -39), 3.0, Color("#211a20"))
    draw_circle(Vector2(5, -39), 3.0, Color("#211a20"))
    draw_rect(Rect2(-19, -18 + sway, 38, 52), dress)
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(-22, -18 + sway),
            Vector2(0, 18 + sway),
            Vector2(22, -18 + sway)
        ]),
        Color("#493d49")
    )
    draw_circle(Vector2(0, 6 + sway), 10.0, Color(0.72, 0.56, 0.52, glow))

    if control_stage >= 2:
        draw_arc(Vector2(0, -34), 19.0, 0.45, 2.7, 16, Color(0.56, 0.34, 0.58, 0.22), 2.0)
    if control_stage >= 3:
        draw_circle(Vector2(0, -39 + sway), 2.5, Color("#b96b75", 0.75))
    draw_string(ThemeDB.fallback_font, Vector2(-38, -64), NereisLocalization.translate_text("MITE"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#d6c7b2"))

    if can_interact():
        draw_string(ThemeDB.fallback_font, Vector2(-54, 42), NereisLocalization.translate_text("E  Talk"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#e0d1bd"))
