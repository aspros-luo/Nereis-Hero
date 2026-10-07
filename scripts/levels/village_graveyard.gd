extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const WRAITH_SCRIPT = preload("res://scripts/enemies/bell_wraith.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const CHECKPOINT_SCRIPT = preload("res://scripts/world/checkpoint.gd")
const WORLD_CLUE_SCRIPT = preload("res://scripts/world/world_clue.gd")
const INTERIOR_EXIT_SCRIPT = preload("res://scripts/world/interior_exit.gd")

var hero: CharacterBody2D
var wraiths: Array[CharacterBody2D] = []
var camera: Camera2D
var checkpoint: Area2D
var narrative: CanvasLayer
var hud: CanvasLayer
var exit: Area2D
var clue: Node2D

func _ready() -> void:
    WorldState.set_location("graveyard")
    WorldState.set_checkpoint(Vector2(360, 520))
    print("[NEREIS][GRAVEYARD] Entered Village Graveyard route=%s" % WorldState.selected_route)
    _create_floor()
    _create_boundaries()
    _spawn_hero()
    _spawn_checkpoint()
    _spawn_wraith(Vector2(1100, 430), "BellWraith_A")
    _spawn_wraith(Vector2(1480, 390), "BellWraith_B")
    _spawn_clue()
    _spawn_exit()
    _spawn_ui()
    queue_redraw()

func _spawn_hero() -> void:
    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.position = Vector2(260, 520)
    hero.name = "Hero"
    _add_character_collision(hero, 18.0, 48.0)
    add_child(hero)
    hero.defeated.connect(_on_hero_defeated)

    camera = Camera2D.new()
    camera.name = "HeroCamera"
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = 2200
    camera.limit_bottom = 720
    camera.position = Vector2.ZERO
    hero.add_child(camera)

func _spawn_checkpoint() -> void:
    checkpoint = Area2D.new()
    checkpoint.set_script(CHECKPOINT_SCRIPT)
    checkpoint.position = Vector2(360, 520)
    checkpoint.name = "GraveyardCheckpoint"
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(140, 110)
    shape.shape = rectangle
    shape.position = Vector2(0, -55)
    checkpoint.add_child(shape)
    add_child(checkpoint)

func _spawn_wraith(position: Vector2, wraith_name: String) -> void:
    var wraith := CharacterBody2D.new()
    wraith.set_script(WRAITH_SCRIPT)
    wraith.position = position
    wraith.name = wraith_name
    _add_character_collision(wraith, 22.0, 58.0)
    add_child(wraith)
    wraith.defeated.connect(_on_wraith_defeated.bind(wraith))
    wraiths.append(wraith)

func _spawn_clue() -> void:
    clue = Node2D.new()
    clue.set_script(WORLD_CLUE_SCRIPT)
    clue.position = Vector2(1740, 520)
    clue.clue_id = "graveyard_hero_gravestone"
    clue.display_name = "THE WEATHERED STONE"
    clue.description = "The stone carries your name, but the date is wrong.\n\nSomeone carved a second line beneath it: \\\"He came back after the bell stopped.\\\""
    add_child(clue)
    clue.examined.connect(_on_clue_examined.bind(clue))

func _spawn_exit() -> void:
    exit = Area2D.new()
    exit.set_script(INTERIOR_EXIT_SCRIPT)
    exit.position = Vector2(2050, 520)
    exit.name = "GraveyardExit"
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(100, 130)
    shape.shape = rectangle
    shape.position = Vector2(0, -65)
    exit.add_child(shape)
    add_child(exit)
    exit.reached.connect(_on_exit_reached)

func _spawn_ui() -> void:
    narrative = CanvasLayer.new()
    narrative.set_script(NARRATIVE_SCRIPT)
    add_child(narrative)

    hud = CanvasLayer.new()
    hud.set_script(HUD_SCRIPT)
    add_child(hud)
    hud.bind_hero(hero)

    get_tree().create_timer(0.6).timeout.connect(_show_intro)

func _show_intro() -> void:
    narrative.show_message(
        "THE VILLAGE GRAVEYARD",
        "The graves are too old for the names carved into them.\n\nThe bell tower is silent. Something beneath it is not.",
        6.0
    )

func _on_wraith_defeated(wraith: Node) -> void:
    _log("COMBAT", "Graveyard encounter defeated: %s" % wraith.name)
    if is_instance_valid(wraith):
        wraiths.erase(wraith)

func _on_hero_defeated() -> void:
    for wraith in wraiths:
        if is_instance_valid(wraith) and wraith.is_queued_for_deletion():
            continue
    if wraiths.is_empty():
        _spawn_wraith(Vector2(1100, 430), "BellWraith_A")
        _spawn_wraith(Vector2(1480, 390), "BellWraith_B")
    print("[NEREIS][GRAVEYARD] Hero defeated; wraith encounter state reset")

func _on_clue_examined(target: Node) -> void:
    narrative.show_message(target.display_name, target.description, 7.0)

func _on_exit_reached() -> void:
    WorldState.set_location("village")
    narrative.show_message("BACK TO THE VILLAGE", "The cemetery gate closes behind you.", 3.0)
    get_tree().create_timer(3.2).timeout.connect(_return_to_village)

func _return_to_village() -> void:
    SceneTransition.fade_to_scene("res://scenes/village_hub.tscn")

func _create_floor() -> void:
    var floor := StaticBody2D.new()
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(2200, 40)
    shape.shape = rectangle
    shape.position = Vector2(1100, 540)
    floor.add_child(shape)
    add_child(floor)

func _create_boundaries() -> void:
    var left := StaticBody2D.new()
    var ls := CollisionShape2D.new()
    var lr := RectangleShape2D.new()
    lr.size = Vector2(40, 720)
    ls.shape = lr
    ls.position = Vector2(-20, 360)
    left.add_child(ls)
    add_child(left)

    var right := StaticBody2D.new()
    var rs := CollisionShape2D.new()
    var rr := RectangleShape2D.new()
    rr.size = Vector2(40, 720)
    rs.shape = rr
    rs.position = Vector2(2220, 360)
    right.add_child(rs)
    add_child(right)

func _add_character_collision(character: CharacterBody2D, radius: float, height: float) -> void:
    var collision := CollisionShape2D.new()
    var capsule := CapsuleShape2D.new()
    capsule.radius = radius
    capsule.height = height
    collision.shape = capsule
    collision.position = Vector2(0, -height * 0.5)
    character.add_child(collision)

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
        WorldState.delete_save()
        print("[NEREIS][DEBUG] Graveyard reset; returning to Vertical Slice")
        get_tree().change_scene_to_file("res://scenes/main.tscn")
        get_viewport().set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 2200, 720), Color("#0f0e14"))
    draw_rect(Rect2(0, 520, 2200, 200), Color("#1d1820"))

    for x in range(140, 2120, 260):
        draw_rect(Rect2(x - 28, 430, 56, 90), Color("#302a32"))
        draw_string(ThemeDB.fallback_font, Vector2(x - 24, 455), "†", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color("#66545c"))

    draw_rect(Rect2(1840, 300, 90, 220), Color("#28212a"))
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(1810, 300),
            Vector2(1885, 190),
            Vector2(1960, 300)
        ]),
        Color("#352d38")
    )
    draw_string(ThemeDB.fallback_font, Vector2(1805, 170), "BELL TOWER", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#796d67"))
