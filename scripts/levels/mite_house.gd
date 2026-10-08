extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const MITE_SCRIPT = preload("res://scripts/npc/mite.gd")
const REST_POINT_SCRIPT = preload("res://scripts/world/rest_point.gd")
const NARRATIVE_AUDIO_SCRIPT = preload("res://scripts/audio/narrative_audio.gd")
const INTERIOR_EXIT_SCRIPT = preload("res://scripts/world/interior_exit.gd")

var hero: CharacterBody2D
var camera: Camera2D
var mite: Node2D
var narrative: CanvasLayer
var hud: CanvasLayer
var narrative_audio: Node
var rest_point: Node2D
var exit: Area2D

func _ready() -> void:
    WorldState.set_location("mite_house")
    _create_floor()
    _create_boundaries()
    _spawn_hero()
    _spawn_mite()
    _spawn_rest()
    _spawn_exit()
    _spawn_ui()
    queue_redraw()

func _spawn_hero() -> void:
    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.position = Vector2(420, 520)
    hero.name = "Hero"
    _add_character_collision(hero, 18.0, 48.0)
    add_child(hero)

    camera = Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = 1400
    camera.limit_bottom = 720
    hero.add_child(camera)

func _spawn_mite() -> void:
    mite = Node2D.new()
    mite.set_script(MITE_SCRIPT)
    mite.position = Vector2(760, 520)
    mite.name = "Mite"
    add_child(mite)
    mite.interacted.connect(_on_mite_interacted)

func _spawn_rest() -> void:
    rest_point = Node2D.new()
    rest_point.set_script(REST_POINT_SCRIPT)
    rest_point.position = Vector2(1050, 520)
    rest_point.rest_id = "mite_house_bed"
    rest_point.display_name = "THE BED"
    add_child(rest_point)
    rest_point.rested.connect(_on_rest)

func _on_rest() -> void:
    if WorldState.physical_union_complete or WorldState.mite_connection_missed:
        narrative.show_message("A QUIET NIGHT", "The room remains quiet.\n\nNothing follows you into sleep.", 4.0)
        return

    if WorldState.mite_interactions_seen.size() < 4:
        narrative.show_message(
            "NOT YET",
            "Mite looks toward the empty half of the room.\n\n\"You should get some rest.\"",
            4.0
        )
        return

    WorldState.input_locked = true
    narrative.show_message(
        "AFTER THE LAST SONG",
        "The village has gone quiet.\n\nThere is nowhere either of you needs to be tonight.",
        4.5
    )
    get_tree().create_timer(4.7).timeout.connect(_complete_union)

func _complete_union() -> void:
    WorldState.mark_physical_union_complete()
    WorldState.mark_ancient_residue_awakened()
    WorldState.mark_outer_god_resonance()
    if narrative_audio and narrative_audio.has_method("play_corrupted_lullaby"):
        narrative_audio.play_corrupted_lullaby()
    narrative.show_message(
        "SOMETHING ANSWERS",
        "No voice speaks.\n\nOnly warmth beneath Hero's skin.\n\nMite opens her eyes.\n\n\"Did you hear that?\"",
        6.0
    )
    get_tree().create_timer(6.2).timeout.connect(func() -> void:
        WorldState.input_locked = false
    )

func _on_mite_interacted(_interaction_id: String, title: String, message: String) -> void:
    narrative.show_message(title, message, 7.0)
    if narrative_audio and narrative_audio.has_method("play_lullaby"):
        narrative_audio.play_lullaby()

func _spawn_exit() -> void:
    exit = Area2D.new()
    exit.set_script(INTERIOR_EXIT_SCRIPT)
    exit.position = Vector2(170, 520)
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(100, 130)
    shape.shape = rectangle
    shape.position = Vector2(0, -65)
    exit.add_child(shape)
    add_child(exit)
    exit.reached.connect(func() -> void:
        WorldState.set_location("village")
        SceneTransition.fade_to_scene("res://scenes/village_hub.tscn")
    )

func _spawn_ui() -> void:
    narrative = CanvasLayer.new()
    narrative.set_script(NARRATIVE_SCRIPT)
    add_child(narrative)

    hud = CanvasLayer.new()
    hud.set_script(HUD_SCRIPT)
    add_child(hud)
    hud.bind_hero(hero)
    hud.set_story_mode("MITE'S HOUSE", "STAY A LITTLE LONGER")

    narrative_audio = Node.new()
    narrative_audio.set_script(NARRATIVE_AUDIO_SCRIPT)
    add_child(narrative_audio)

    get_tree().create_timer(0.6).timeout.connect(func() -> void:
        narrative.show_message(
            "MITE'S HOUSE",
            "The room is small.\n\nTwo places at the table.\n\nOne bed.",
            4.0
        )
    )

func _create_floor() -> void:
    var floor := StaticBody2D.new()
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(1400, 40)
    shape.shape = rectangle
    shape.position = Vector2(700, 540)
    floor.add_child(shape)
    add_child(floor)

func _create_boundaries() -> void:
    for x in [-20.0, 1420.0]:
        var wall := StaticBody2D.new()
        var shape := CollisionShape2D.new()
        var rectangle := RectangleShape2D.new()
        rectangle.size = Vector2(40, 720)
        shape.shape = rectangle
        shape.position = Vector2(x, 360)
        wall.add_child(shape)
        add_child(wall)

func _add_character_collision(character: CharacterBody2D, radius: float, height: float) -> void:
    var collision := CollisionShape2D.new()
    var capsule := CapsuleShape2D.new()
    capsule.radius = radius
    capsule.height = height
    collision.shape = capsule
    collision.position = Vector2(0, -height * 0.5)
    character.add_child(collision)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
        WorldState.delete_save()
        get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")
        get_viewport().set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1400, 720), Color("#151117"))
    draw_rect(Rect2(0, 520, 1400, 200), Color("#211b22"))
    draw_rect(Rect2(260, 320, 760, 200), Color("#2c252d"))
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(220, 320),
            Vector2(640, 150),
            Vector2(1060, 320)
        ]),
        Color("#352c35")
    )
    draw_rect(Rect2(960, 370, 180, 150), Color("#211a22"))
    draw_rect(Rect2(995, 420, 110, 12), Color("#4b3940"))
    draw_string(ThemeDB.fallback_font, Vector2(360, 245), "A ROOM WITH TWO PLACES", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#72646b"))
