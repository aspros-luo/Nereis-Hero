extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const HUSK_SCRIPT = preload("res://scripts/enemies/research_husk.gd")
const INTERIOR_CLUE_SCRIPT = preload("res://scripts/world/interior_clue.gd")
const WORLD_CLUE_SCRIPT = preload("res://scripts/world/world_clue.gd")
const REST_POINT_SCRIPT = preload("res://scripts/world/rest_point.gd")
const INTERIOR_EXIT_SCRIPT = preload("res://scripts/world/interior_exit.gd")

const FLOOR_Y := 540.0

var hero: CharacterBody2D
var camera: Camera2D
var narrative: CanvasLayer
var hud: CanvasLayer
var husk: CharacterBody2D
var cleared := false

func _ready() -> void:
    WorldState.set_location("ancient_lab")
    WorldState.set_checkpoint(Vector2(300, FLOOR_Y))
    _create_floor()
    _create_boundaries()
    _spawn_hero()
    _spawn_husk()
    _spawn_clues()
    _spawn_rest()
    _spawn_exit()
    _spawn_ui()
    queue_redraw()

func _spawn_hero() -> void:
    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.position = Vector2(280, FLOOR_Y)
    hero.name = "Hero"
    _add_character_collision(hero, 18.0, 48.0)
    add_child(hero)
    hero.defeated.connect(_on_hero_defeated)

    camera = Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = 2400
    camera.limit_bottom = 720
    hero.add_child(camera)

func _spawn_husk() -> void:
    if cleared:
        return
    husk = CharacterBody2D.new()
    husk.set_script(HUSK_SCRIPT)
    husk.position = Vector2(1250, FLOOR_Y)
    husk.name = "ResearchHusk"
    _add_character_collision(husk, 24.0, 58.0)
    add_child(husk)
    husk.defeated.connect(_on_husk_defeated)

func _on_husk_defeated() -> void:
    cleared = true
    WorldState.record_hidden_artifact_source("ancient_lab")
    narrative.show_message(
        "THE VESSEL",
        "The thing collapses.

Beneath its ribs, a metal hook remains embedded in bone.

The hook is shaped for something much larger than the body it came from.",
        6.0
    )

func _spawn_clues() -> void:
    var fluid := Node2D.new()
    fluid.set_script(INTERIOR_CLUE_SCRIPT)
    fluid.position = Vector2(650, FLOOR_Y)
    fluid.clue_id = "ancient_fluid_vial"
    fluid.humanity_delta = -2
    fluid.display_name = "BLACK VIAL"
    fluid.description = "The liquid is not quite black.
\nWhen light crosses it, the color inside becomes red.
\nThe label contains only one word: 'SAINT.'"
    add_child(fluid)
    fluid.examined.connect(_on_clue_examined.bind(fluid))

    var hair := Node2D.new()
    hair.set_script(INTERIOR_CLUE_SCRIPT)
    hair.position = Vector2(900, FLOOR_Y)
    hair.clue_id = "ancient_hair_bundle"
    hair.humanity_delta = -2
    hair.display_name = "SEALED HAIR"
    hair.description = "A bundle of pale hair floats inside a glass cylinder.\n\nThere is no body attached to it.\n\nThe wax seal bears an older Kingdom crest."
    add_child(hair)
    hair.examined.connect(_on_clue_examined.bind(hair))

    var ledger := Node2D.new()
    ledger.set_script(WORLD_CLUE_SCRIPT)
    ledger.position = Vector2(1640, FLOOR_Y)
    ledger.clue_id = "ancient_vessel_ledger"
    ledger.humanity_delta = -5
    ledger.display_name = "VESSEL LEDGER"
    ledger.description = "Names are listed with dates, weights and survival percentages.\n\nOne line has been underlined in red:\n\n'Knight-class subjects demonstrate superior retention.'"
    add_child(ledger)
    ledger.examined.connect(_on_clue_examined.bind(ledger))

func _on_clue_examined(clue: Node) -> void:
    if clue.clue_id in ["ancient_fluid_vial", "ancient_hair_bundle", "ancient_vessel_ledger"]:
        WorldState.record_hidden_artifact_source("ancient_lab")
    narrative.show_message(clue.display_name, clue.description, 7.0)

func _spawn_rest() -> void:
    var rest := Node2D.new()
    rest.set_script(REST_POINT_SCRIPT)
    rest.position = Vector2(380, FLOOR_Y)
    rest.rest_id = "lab_rest"
    add_child(rest)

func _spawn_exit() -> void:
    var exit := Area2D.new()
    exit.set_script(INTERIOR_EXIT_SCRIPT)
    exit.position = Vector2(2220, FLOOR_Y)
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(100, 130)
    shape.shape = rectangle
    shape.position = Vector2(0, -65)
    exit.add_child(shape)
    add_child(exit)
    exit.reached.connect(func() -> void:
        WorldState.set_location("church")
        SceneTransition.fade_to_scene("res://scenes/locations/church_interior.tscn")
    )

func _spawn_ui() -> void:
    narrative = CanvasLayer.new()
    narrative.set_script(NARRATIVE_SCRIPT)
    add_child(narrative)

    hud = CanvasLayer.new()
    hud.set_script(HUD_SCRIPT)
    add_child(hud)
    hud.bind_hero(hero)
    hud.set_story_mode("ANCIENT RESEARCH WARD", "SEARCH THE ROOM / LEAVE WITH WHAT YOU CAN BEAR")

    get_tree().create_timer(0.7).timeout.connect(func() -> void:
        narrative.show_message(
            "THE RESEARCH WARD",
            "There are no prayers here.\n\nOnly instruments polished often enough to look sacred.",
            4.5
        )
    )

func _on_hero_defeated() -> void:
    if cleared:
        return
    if husk and is_instance_valid(husk):
        husk.queue_free()
    get_tree().create_timer(0.5).timeout.connect(_spawn_husk)

func _create_floor() -> void:
    var floor := StaticBody2D.new()
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(2400, 40)
    shape.shape = rectangle
    shape.position = Vector2(1200, FLOOR_Y + 20)
    floor.add_child(shape)
    add_child(floor)

func _create_boundaries() -> void:
    for x in [-20.0, 2420.0]:
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
    draw_rect(Rect2(0, 0, 2400, 720), Color("#0e0d12"))
    draw_rect(Rect2(0, FLOOR_Y, 2400, 180), Color("#1d1820"))

    for x in range(240, 2200, 340):
        draw_rect(Rect2(x, 270, 170, 250), Color("#211c24"))
        draw_line(Vector2(x + 25, 330), Vector2(x + 145, 330), Color("#4b383f"), 4.0)
        draw_line(Vector2(x + 50, 365), Vector2(x + 50, 500), Color("#30262f"), 6.0)

    draw_string(ThemeDB.fallback_font, Vector2(280, 210), "WHERE FAITH BECAME AN INSTRUMENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#665860"))
    draw_rect(Rect2(1130, 330, 200, 190), Color("#30232c"))
    draw_circle(Vector2(1230, 385), 46, Color("#70454f", 0.35))
