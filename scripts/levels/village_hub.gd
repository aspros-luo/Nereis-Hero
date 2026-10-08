extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const ROUTE_NPC_SCRIPT = preload("res://scripts/npc/route_npc.gd")
const CHECKPOINT_SCRIPT = preload("res://scripts/world/checkpoint.gd")
const VILLAGE_POI_SCRIPT = preload("res://scripts/world/village_poi.gd")
const MITE_SCRIPT = preload("res://scripts/npc/mite.gd")
const NARRATIVE_AUDIO_SCRIPT = preload("res://scripts/audio/narrative_audio.gd")
const FIREFLY_SCRIPT = preload("res://scripts/effects/village_fireflies.gd")

var hero: CharacterBody2D
var camera: Camera2D
var narrative: CanvasLayer
var hud: CanvasLayer
var checkpoint: Area2D
var mite: Node2D
var narrative_audio: Node
var mite_house_door: Area2D
var mite_house_nearby := false
var mite_house_transitioning := false
var fireflies: Node2D

func _ready() -> void:
    WorldState.current_location = "village"
    print("[NEREIS][VILLAGE] Entered Village Hub route=%s" % WorldState.selected_route)
    WorldState.set_checkpoint(Vector2(360, 520))
    _create_floor()
    _create_boundaries()
    _spawn_hero()
    _spawn_checkpoint()
    _spawn_mite()
    _spawn_mite_house_door()
    _spawn_gatekeeper()
    _spawn_shared_world_npcs()
    _spawn_village_pois()
    _spawn_ui()
    _spawn_narrative_audio()
    _spawn_fireflies()
    queue_redraw()

func _spawn_hero() -> void:
    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.position = Vector2(260, 520)
    hero.name = "Hero"
    _add_character_collision(hero, 18.0, 48.0)
    add_child(hero)

    camera = Camera2D.new()
    camera.name = "HeroCamera"
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = 2600
    camera.limit_bottom = 720
    camera.position = Vector2.ZERO
    hero.add_child(camera)

func _spawn_checkpoint() -> void:
    checkpoint = Area2D.new()
    checkpoint.set_script(CHECKPOINT_SCRIPT)
    checkpoint.position = Vector2(360, 520)
    checkpoint.name = "VillageCheckpoint"
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(130, 110)
    shape.shape = rectangle
    shape.position = Vector2(0, -55)
    checkpoint.add_child(shape)
    add_child(checkpoint)

func _spawn_mite() -> void:
    if WorldState.mite_connection_missed:
        var absence := Node2D.new()
        absence.position = Vector2(520, 520)
        absence.name = "MiteAbsence"
        absence.set_script(VILLAGE_POI_SCRIPT)
        absence.poi_id = "mite_absence"
        absence.display_name = "AN EMPTY CHAIR"
        absence.dialogue = "The chair beside the fire is empty.\n\nA cup has been left on the table. It is still warm.\n\nNo one is home."
        add_child(absence)
        absence.interacted.connect(_on_mite_absence_interacted)
        print("[NEREIS][RELATIONSHIP] Mite connection was missed; absence scene spawned")
        return

    mite = Node2D.new()
    mite.set_script(MITE_SCRIPT)
    mite.position = Vector2(520, 520)
    mite.name = "Mite"
    add_child(mite)
    mite.interacted.connect(_on_mite_interacted)
    print("[NEREIS][VILLAGE] Mite present; relationship facts=%d" % WorldState.mite_interactions_seen.size())

func _on_mite_absence_interacted() -> void:
    narrative.show_message("AN EMPTY CHAIR", "The cup is still warm.\n\nYou are certain you did not leave it here.", 5.0)

func _on_mite_interacted(_interaction_id: String, title: String, message: String) -> void:
    narrative.show_message(title, message, 7.0)
    if narrative_audio and narrative_audio.has_method("play_lullaby"):
        narrative_audio.play_lullaby()
    if WorldState.current_location != "village":
        WorldState.current_location = "village"
        WorldState.save_game()

func _spawn_narrative_audio() -> void:
    narrative_audio = Node.new()
    narrative_audio.set_script(NARRATIVE_AUDIO_SCRIPT)
    narrative_audio.name = "NarrativeAudio"
    add_child(narrative_audio)
    get_tree().create_timer(1.0).timeout.connect(func() -> void:
        if narrative_audio and narrative_audio.has_method("play_lullaby"):
            narrative_audio.play_lullaby()
    )

func _spawn_mite_house_door() -> void:
    mite_house_door = Area2D.new()
    mite_house_door.position = Vector2(455, 520)
    mite_house_door.name = "MiteHouseDoor"
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(70, 120)
    shape.shape = rectangle
    shape.position = Vector2(0, -60)
    mite_house_door.add_child(shape)
    add_child(mite_house_door)
    mite_house_door.body_entered.connect(_on_mite_house_entered)
    mite_house_door.body_exited.connect(_on_mite_house_exited)

func _on_mite_house_entered(body: Node) -> void:
    if body != get_node_or_null("Hero"):
        return
    mite_house_nearby = true
    queue_redraw()

func _on_mite_house_exited(body: Node) -> void:
    if body != get_node_or_null("Hero"):
        return
    mite_house_nearby = false
    queue_redraw()

func _enter_mite_house() -> void:
    if mite_house_transitioning or WorldState.input_locked:
        return
    if WorldState.mite_connection_missed:
        narrative.show_message("THE LOCKED DOOR", "There is no reason to go inside.", 3.0)
        return
    if not WorldState.mite_first_meeting:
        narrative.show_message("THE CLOSED DOOR", "You do not know who lives here yet.", 3.0)
        return

    mite_house_transitioning = true
    WorldState.set_location("mite_house")
    SceneTransition.fade_to_scene("res://scenes/mite_house.tscn")

func _spawn_fireflies() -> void:
    fireflies = Node2D.new()
    fireflies.set_script(FIREFLY_SCRIPT)
    fireflies.name = "VillageFireflies"
    add_child(fireflies)

func _spawn_gatekeeper() -> void:
    var npc := Node2D.new()
    npc.set_script(ROUTE_NPC_SCRIPT)
    npc.position = Vector2(760, 520)
    npc.npc_id = "village_gatekeeper"
    npc.display_name = "VILLAGE GATEKEEPER"
    if WorldState.selected_route == "church":
        npc.dialogue = "The gatekeeper studies the church seal.\n\n\"They told us you would never return. Why did they send the same man back?\""
    else:
        npc.dialogue = "The gatekeeper hears the lullaby on the wind and shuts the tavern door halfway.\n\n\"Don't sing that here. Not unless you want the village to remember.\""
    add_child(npc)

func _spawn_shared_world_npcs() -> void:
    var youth := Node2D.new()
    youth.set_script(ROUTE_NPC_SCRIPT)
    youth.position = Vector2(1120, 520)
    youth.npc_id = "amnesiac_youth"
    youth.display_name = "AMNESIAC YOUTH"
    if WorldState.get_humanity_state() == "hollow":
        youth.dialogue = "The young man takes one step back.\n\n\"I know that look. Something in you already left.\""
    elif WorldState.selected_route == "church":
        youth.dialogue = "The young man touches your church seal and goes pale.\n\n\"I remember you kneeling there. They told me not to remember.\""
    else:
        youth.dialogue = "The young man stares toward the tavern.\n\n\"You came back carrying someone once. I don't know who it was. I only remember the singing.\""
    add_child(youth)

    var merchant := Node2D.new()
    merchant.set_script(ROUTE_NPC_SCRIPT)
    merchant.position = Vector2(1380, 520)
    merchant.npc_id = "traveling_merchant"
    merchant.display_name = "TRAVELING MERCHANT"
    if WorldState.get_humanity_state() == "hollow":
        merchant.dialogue = "The merchant stops smiling.\n\n\"You should not be able to hear the song anymore.\""
    elif WorldState.selected_route == "church":
        merchant.dialogue = "The merchant turns a silver token between two fingers.\n\n\"Church roads are safe only until the bells start. Then even the stones lie.\""
    else:
        merchant.dialogue = "The merchant smiles without humor.\n\n\"I saw the village seven years ago. Your face was already on the church door.\""
    add_child(merchant)

func _spawn_village_pois() -> void:
    var tavern := Node2D.new()
    tavern.set_script(VILLAGE_POI_SCRIPT)
    tavern.position = Vector2(1730, 520)
    tavern.poi_id = "tavern"
    tavern.display_name = "THE TAVERN"
    tavern.dialogue = "The tavern door is warm beneath your hand.\n\nFor a moment you hear a lullaby from inside. The voice stops when you touch the handle."
    add_child(tavern)
    tavern.interacted.connect(_on_village_poi_interacted.bind(tavern))

    var graveyard := Node2D.new()
    graveyard.set_script(VILLAGE_POI_SCRIPT)
    graveyard.position = Vector2(950, 520)
    graveyard.poi_id = "graveyard"
    graveyard.display_name = "VILLAGE GRAVEYARD"
    graveyard.dialogue = "The cemetery gate is open.\n\nThe bell tower has not rung in years. Something inside still answers when you call."
    add_child(graveyard)
    graveyard.interacted.connect(_on_village_poi_interacted.bind(graveyard))

    var rebel_camp := Node2D.new()
    rebel_camp.set_script(VILLAGE_POI_SCRIPT)
    rebel_camp.position = Vector2(1990, 520)
    rebel_camp.poi_id = "rebel_camp"
    rebel_camp.display_name = "RESTORATION CAMP"
    rebel_camp.dialogue = "A small fire burns behind the hill.\n\nSomeone has pitched a camp without a flag.\n\nYou hear soldiers arguing about the throne."
    add_child(rebel_camp)
    rebel_camp.interacted.connect(_on_village_poi_interacted.bind(rebel_camp))

    var north_gate := Node2D.new()
    north_gate.set_script(VILLAGE_POI_SCRIPT)
    north_gate.position = Vector2(2440, 520)
    north_gate.poi_id = "north_gate"
    north_gate.display_name = "NORTH GATE"
    north_gate.dialogue = "Fresh axe marks scar the gate.\n\nBeyond it, the road is too quiet.\n\nYou hear distant metal."
    add_child(north_gate)
    north_gate.interacted.connect(_on_village_poi_interacted.bind(north_gate))

    var church := Node2D.new()
    church.set_script(VILLAGE_POI_SCRIPT)
    church.position = Vector2(2220, 520)
    church.poi_id = "church"
    church.display_name = "THE CHURCH"
    church.dialogue = "The church door bears your name beneath layers of newer paint.\n\nSomeone has tried to erase it many times."
    add_child(church)
    church.interacted.connect(_on_village_poi_interacted.bind(church))

func _on_village_poi_interacted(poi: Node) -> void:
    narrative.show_message(poi.display_name, poi.dialogue, 2.5)
    get_tree().create_timer(2.7).timeout.connect(_enter_village_location.bind(poi.poi_id))

func _enter_village_location(location_id: String) -> void:
    if location_id == "tavern":
        WorldState.set_location("tavern")
        print("[NEREIS][VILLAGE] Entering Tavern Interior")
        SceneTransition.fade_to_scene("res://scenes/locations/tavern_interior.tscn")
    elif location_id == "church":
        if not WorldState.has_mite_interaction("mite_stay_a_while"):
            WorldState.mark_mite_connection_missed()
        WorldState.set_location("church")
        print("[NEREIS][VILLAGE] Entering Church Interior")
        SceneTransition.fade_to_scene("res://scenes/locations/church_interior.tscn")
    elif location_id == "rebel_camp":
        WorldState.set_location("rebel_camp")
        print("[NEREIS][VILLAGE] Entering Restoration Camp")
        SceneTransition.fade_to_scene("res://scenes/rebel_camp.tscn")
    elif location_id == "north_gate":
        WorldState.current_location = "village"
        print("[NEREIS][VILLAGE] Triggering village defense chapter")
        SceneTransition.fade_to_scene("res://scenes/village_defense_demo.tscn")
    elif location_id == "graveyard":
        WorldState.set_location("graveyard")
        print("[NEREIS][VILLAGE] Entering Village Graveyard")
        SceneTransition.fade_to_scene("res://scenes/village_graveyard.tscn")

func _spawn_ui() -> void:
    narrative = CanvasLayer.new()
    narrative.set_script(NARRATIVE_SCRIPT)
    add_child(narrative)

    hud = CanvasLayer.new()
    hud.set_script(HUD_SCRIPT)
    add_child(hud)
    hud.bind_hero(hero)
    hud.set_story_mode("THE REMOTE VILLAGE", "LEARN WHY THE VILLAGE SAVED YOU")

    get_tree().create_timer(0.7).timeout.connect(_show_village_intro)

func _show_village_intro() -> void:
    narrative.show_message(
        "THE VILLAGE",
        "The road ends where the village begins.\n\nThe Hero recognizes none of it. The village recognizes him.\n\nSomeone has left a place for him by the fire.",
        6.0
    )

func _create_floor() -> void:
    var floor := StaticBody2D.new()
    floor.name = "Ground"
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(2600, 40)
    shape.shape = rectangle
    shape.position = Vector2(1300, 540)
    floor.add_child(shape)
    add_child(floor)

func _create_boundaries() -> void:
    var left := StaticBody2D.new()
    var left_shape := CollisionShape2D.new()
    var left_rect := RectangleShape2D.new()
    left_rect.size = Vector2(40, 720)
    left_shape.shape = left_rect
    left_shape.position = Vector2(-20, 360)
    left.add_child(left_shape)
    add_child(left)

    var right := StaticBody2D.new()
    var right_shape := CollisionShape2D.new()
    var right_rect := RectangleShape2D.new()
    right_rect.size = Vector2(40, 720)
    right_shape.shape = right_rect
    right_shape.position = Vector2(2620, 360)
    right.add_child(right_shape)
    add_child(right)

func _add_character_collision(character: CharacterBody2D, radius: float, height: float) -> void:
    var collision := CollisionShape2D.new()
    var capsule := CapsuleShape2D.new()
    capsule.radius = radius
    capsule.height = height
    collision.shape = capsule
    collision.position = Vector2(0, -height * 0.5)
    character.add_child(collision)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_E and mite_house_nearby:
            _enter_mite_house()
            get_viewport().set_input_as_handled()
            return
        if event.keycode == KEY_F1:
            var endgame_scene := NereisEndingEvaluator.get_candidate()
            print("[NEREIS][DEBUG] Candidate endgame=%s" % endgame_scene)
            match endgame_scene:
                "烈火天罚":
                    get_tree().change_scene_to_file("res://scenes/ending_fire_demo.tscn")
                "永恒乐园":
                    get_tree().change_scene_to_file("res://scenes/ending_paradise_demo.tscn")
                _:
                    get_tree().change_scene_to_file("res://scenes/church_final_demo.tscn")
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_F2:
            print("[NEREIS][DEBUG] Opening Eternal Paradise theater")
            get_tree().change_scene_to_file("res://scenes/ending_paradise_demo.tscn")
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_F4:
            print("[NEREIS][DEBUG] Opening ancient research theater")
            get_tree().change_scene_to_file("res://scenes/ancient_research_lab.tscn")
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_F5:
            print("[NEREIS][DEBUG] Opening village defense theater")
            get_tree().change_scene_to_file("res://scenes/village_defense_demo.tscn")
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_F8:
            print("[NEREIS][DEBUG] Opening director ending theater")
            get_tree().change_scene_to_file("res://scenes/ending_fire_demo.tscn")
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_F7:
            print("[NEREIS][DEBUG] Opening church final boss theater")
            get_tree().change_scene_to_file("res://scenes/church_final_demo.tscn")
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_F6:
            print("[NEREIS][DEBUG] Opening Mite resonance theater")
            get_tree().change_scene_to_file("res://scenes/mite_resonance_demo.tscn")
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_F9:
            WorldState.delete_save()
            print("[NEREIS][DEBUG] Village run reset")
            get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")
            get_viewport().set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 2600, 720), Color("#111018"))
    draw_rect(Rect2(0, 520, 2600, 200), Color("#201c22"))
    for x in range(0, 2600, 64):
        draw_line(Vector2(x, 520), Vector2(x + 32, 552), Color("#302a30"), 2.0)

    draw_string(ThemeDB.fallback_font, Vector2(100, 230), "THE VILLAGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("#4d454d"))

    # Small house where the Hero first recovers.
    draw_rect(Rect2(350, 360, 210, 160), Color("#27222b"))
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(325, 360),
            Vector2(455, 245),
            Vector2(585, 360)
        ]),
        Color("#302832")
    )
    draw_rect(Rect2(430, 430, 50, 90), Color("#17141b"))
    draw_string(ThemeDB.fallback_font, Vector2(388, 332), "MITE'S HOUSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#8d7776"))
    if mite_house_nearby and not WorldState.input_locked:
        draw_string(ThemeDB.fallback_font, Vector2(420, 555), "E  Enter", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#e0d1bd"))

    for x in range(120, 2300, 480):
        draw_rect(Rect2(x - 90, 360, 180, 160), Color("#29232b"))
        draw_colored_polygon(
            PackedVector2Array([
                Vector2(x - 110, 360),
                Vector2(x, 260),
                Vector2(x + 110, 360)
            ]),
            Color("#352d38")
        )
        draw_rect(Rect2(x - 12, 440, 24, 80), Color("#17141b"))
        draw_circle(Vector2(x - 42, 430), 8, Color("#8e7777"))
        draw_circle(Vector2(x + 42, 430), 8, Color("#66545c"))

    draw_rect(Rect2(1580, 300, 300, 220), Color("#2d2630"))
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(1530, 300),
            Vector2(1730, 190),
            Vector2(1930, 300)
        ]),
        Color("#3a303a")
    )
    draw_rect(Rect2(1690, 400, 80, 120), Color("#17141b"))
    draw_string(ThemeDB.fallback_font, Vector2(1630, 275), "THE TAVERN", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d6c7b2"))

    draw_rect(Rect2(900, 390, 120, 130), Color("#28212a"))
    draw_string(ThemeDB.fallback_font, Vector2(885, 365), "GRAVEYARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#796d67"))

    draw_rect(Rect2(1940, 360, 150, 160), Color("#27212a"))
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(1915, 360),
            Vector2(2015, 270),
            Vector2(2115, 360)
        ]),
        Color("#312934")
    )
    draw_circle(Vector2(2015, 455), 34.0, Color("#63322f"))
    draw_string(ThemeDB.fallback_font, Vector2(1900, 335), "RESTORATION CAMP", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#8d7776"))

    draw_rect(Rect2(2380, 330, 120, 190), Color("#241e27"))
    draw_rect(Rect2(2410, 350, 18, 170), Color("#4a3439"))
    draw_rect(Rect2(2460, 350, 18, 170), Color("#4a3439"))
    draw_string(ThemeDB.fallback_font, Vector2(2370, 310), "NORTH GATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#796d67"))

    draw_rect(Rect2(2180, 320, 80, 200), Color("#26202a"))
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(2150, 320),
            Vector2(2220, 220),
            Vector2(2290, 320)
        ]),
        Color("#312934")
    )
    draw_string(ThemeDB.fallback_font, Vector2(2135, 200), "CHURCH", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#796d67"))
