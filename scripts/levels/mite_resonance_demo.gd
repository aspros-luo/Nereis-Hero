extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const MITE_SCRIPT = preload("res://scripts/npc/mite.gd")
const NARRATIVE_AUDIO_SCRIPT = preload("res://scripts/audio/narrative_audio.gd")

var hero: CharacterBody2D
var camera: Camera2D
var narrative: CanvasLayer
var hud: CanvasLayer
var audio_director: Node
var mite: Node2D
var resonance_started := false
var resonance_elapsed := 0.0
var corruption_level := 0.0

func _ready() -> void:
    WorldState.current_location = "mite_resonance_demo"
    WorldState.mite_first_meeting = true
    WorldState.mite_interactions_seen = [
        "mite_first_meeting",
        "mite_meal",
        "mite_stay_a_while",
        "mite_return"
    ]

    _create_floor()
    _create_boundaries()
    _spawn_hero()
    _spawn_mite()
    _spawn_ui()
    _spawn_audio()
    get_tree().create_timer(0.7).timeout.connect(_begin_scene)
    queue_redraw()

func _process(delta: float) -> void:
    if not resonance_started:
        return
    resonance_elapsed += delta
    corruption_level = clampf(resonance_elapsed / 24.0, 0.0, 1.0)
    if corruption_level >= 0.72 and WorldState.outer_god_resonance:
        queue_redraw()
    queue_redraw()

func _spawn_hero() -> void:
    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.position = Vector2(430, 520)
    hero.name = "Hero"
    _add_character_collision(hero, 18.0, 48.0)
    add_child(hero)

    camera = Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = 1400
    camera.limit_bottom = 720
    hero.add_child(camera)

func _spawn_mite() -> void:
    mite = Node2D.new()
    mite.set_script(MITE_SCRIPT)
    mite.position = Vector2(770, 520)
    mite.name = "Mite"
    add_child(mite)

func _spawn_ui() -> void:
    narrative = CanvasLayer.new()
    narrative.set_script(NARRATIVE_SCRIPT)
    add_child(narrative)

    hud = CanvasLayer.new()
    hud.set_script(HUD_SCRIPT)
    add_child(hud)
    hud.bind_hero(hero)
    hud.set_story_mode("THE QUIET HOUSE", "DIRECTOR TEST: RESONANCE")

func _spawn_audio() -> void:
    audio_director = Node.new()
    audio_director.set_script(NARRATIVE_AUDIO_SCRIPT)
    add_child(audio_director)

func _begin_scene() -> void:
    narrative.show_message(
        "A NIGHT WITHOUT A NAME",
        "The village is asleep.\n\nHero and Mite are alone in the room.\n\nNothing outside asks either of them to be a knight, a vessel or a god.",
        5.0
    )
    await narrative.message_finished
    _begin_union()

func _begin_union() -> void:
    WorldState.mark_physical_union_complete()
    WorldState.mark_ancient_residue_awakened()
    WorldState.mark_outer_god_resonance()

    resonance_started = true
    if audio_director and audio_director.has_method("play_corrupted_lullaby"):
        audio_director.play_corrupted_lullaby()

    narrative.show_message(
        "THE RESONANCE",
        "There is no explosion.\n\nOnly a brief warmth beneath Hero's skin.\n\nMite opens her eyes.\n\nShe is smiling. She does not know why.",
        5.5
    )

    await narrative.message_finished
    _show_influence()

func _show_influence() -> void:
    narrative.show_message(
        "MITE",
        ""I dreamed you were still here."\n\nA pause.\n\n"We don't have to leave anymore, do we?"",
        5.5
    )

    get_tree().create_timer(5.8).timeout.connect(_show_second_influence)

func _show_second_influence() -> void:
    narrative.show_message(
        "MITE",
        ""Outside feels very far away."\n\nShe looks toward Hero.\n\n"I don't want to be alone again."",
        5.0
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
    draw_rect(Rect2(260, 330, 760, 190), Color("#2b242c"))
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(220, 330),
            Vector2(640, 150),
            Vector2(1060, 330)
        ]),
        Color("#342b35")
    )

    if resonance_started:
        for i in range(9):
            var x := 430.0 + float(i) * 100.0
            var y := 220.0 + sin(resonance_elapsed * 0.9 + i) * 45.0
            draw_circle(Vector2(x, y), 10.0 + corruption_level * 18.0, Color(0.45, 0.25, 0.48, 0.08))
            draw_circle(Vector2(x, y), 2.5, Color("#8c627f"))

    draw_string(
        ThemeDB.fallback_font,
        Vector2(470, 250), NereisLocalization.translate_text("THE ROOM REMEMBERS"), HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        24,
        Color("#76656d")
    )
