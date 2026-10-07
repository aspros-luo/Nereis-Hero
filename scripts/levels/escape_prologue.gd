extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const WARDEN_SCRIPT = preload("res://scripts/enemies/experiment_warden.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const REST_POINT_SCRIPT = preload("res://scripts/world/rest_point.gd")

const FLOOR_Y := 540.0
const LEVEL_WIDTH := 2200.0

var hero: CharacterBody2D
var camera: Camera2D
var hud: CanvasLayer
var narrative: CanvasLayer
var wardens: Array[CharacterBody2D] = []
var exit_area: Area2D
var exit_open := false
var wardens_defeated := 0

func _ready() -> void:
    if WorldState.prologue_complete:
        get_tree().change_scene_to_file("res://scenes/village_hub.tscn")
        return

    WorldState.current_location = "church_escape"
    WorldState.set_checkpoint(Vector2(300, FLOOR_Y))

    _create_floor()
    _create_boundaries()
    _spawn_hero()
    _spawn_wardens()
    _spawn_clue()
    _spawn_rest()
    _spawn_exit()
    _spawn_ui()
    get_tree().create_timer(0.6).timeout.connect(_show_intro)
    queue_redraw()

func _spawn_hero() -> void:
    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.position = Vector2(280, FLOOR_Y)
    hero.name = "Hero"
    _add_character_collision(hero, 18.0, 48.0)
    add_child(hero)
    hero.defeated.connect(_on_hero_defeated)
    hero.attack_started.connect(func(_combo): pass)

    camera = Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = LEVEL_WIDTH
    camera.limit_bottom = 720
    hero.add_child(camera)

func _spawn_wardens() -> void:
    _spawn_warden(Vector2(920, FLOOR_Y), "Warden_A")
    _spawn_warden(Vector2(1260, FLOOR_Y), "Warden_B")
    _spawn_warden(Vector2(1590, FLOOR_Y), "Warden_C")

func _spawn_warden(position: Vector2, enemy_name: String) -> void:
    var warden := CharacterBody2D.new()
    warden.set_script(WARDEN_SCRIPT)
    warden.position = position
    warden.name = enemy_name
    _add_character_collision(warden, 22.0, 50.0)
    add_child(warden)
    warden.defeated.connect(_on_warden_defeated)
    wardens.append(warden)

func _spawn_clue() -> void:
    var clue := Node2D.new()
    clue.set_script(preload("res://scripts/world/world_clue.gd"))
    clue.position = Vector2(620, FLOOR_Y)
    clue.clue_id = "escape_surgical_mark"
    clue.humanity_delta = -1
    clue.display_name = "SURGICAL TRAY"
    clue.description = "A metal tray holds dried black residue beneath a layer of blood.

The Hero touches it.

Something inside his arm answers.

The sensation stops before it becomes a memory."
    add_child(clue)
    clue.examined.connect(_on_clue_examined.bind(clue))

func _on_clue_examined(clue: Node) -> void:
    WorldState.mark_ancient_residue_awakened()
    narrative.show_message(clue.display_name, clue.description, 7.0)

func _spawn_rest() -> void:
    var rest := Node2D.new()
    rest.set_script(REST_POINT_SCRIPT)
    rest.position = Vector2(350, FLOOR_Y)
    rest.rest_id = "escape_stool"
    rest.display_name = "BROKEN STOOL"
    add_child(rest)

func _spawn_exit() -> void:
    exit_area = Area2D.new()
    exit_area.position = Vector2(2040, FLOOR_Y)
    exit_area.name = "VillageRoadExit"

    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(110, 140)
    shape.shape = rectangle
    shape.position = Vector2(0, -70)
    exit_area.add_child(shape)
    add_child(exit_area)
    exit_area.body_entered.connect(_on_exit_body_entered)
    queue_redraw()

func _on_warden_defeated() -> void:
    wardens_defeated += 1
    if wardens_defeated >= wardens.size():
        _open_exit()

func _open_exit() -> void:
    if exit_open:
        return
    exit_open = true
    narrative.show_message(
        "THE ROAD OUT",
        "The final lock gives way.

You do not remember how you arrived here.

You only remember that staying means dying.",
        5.0
    )
    print("[NEREIS][PROLOGUE] Escape route opened")
    queue_redraw()

func _on_exit_body_entered(body: Node) -> void:
    if body != hero or not exit_open:
        return

    WorldState.mark_prologue_complete()
    WorldState.current_location = "village"
    WorldState.input_locked = true
    narrative.show_message(
        "THE VILLAGE",
        "Cold air. A road. A cluster of lights in the distance.\n\nThe Hero keeps walking.",
        4.5
    )
    get_tree().create_timer(4.7).timeout.connect(func() -> void:
        WorldState.input_locked = false
        SceneTransition.fade_to_scene("res://scenes/village_hub.tscn")
    )

func _on_hero_defeated() -> void:
    for warden in wardens:
        if is_instance_valid(warden) and not warden.is_queued_for_deletion():
            warden.queue_free()
    wardens.clear()
    wardens_defeated = 0
    call_deferred("_spawn_wardens")
    print("[NEREIS][PROLOGUE] Hero defeated; wardens reset")

func _spawn_ui() -> void:
    narrative = CanvasLayer.new()
    narrative.set_script(NARRATIVE_SCRIPT)
    add_child(narrative)

    hud = CanvasLayer.new()
    hud.set_script(HUD_SCRIPT)
    add_child(hud)
    hud.bind_hero(hero)

func _show_intro() -> void:
    narrative.show_message(
        "THE SURGICAL WARD",
        "The straps are broken. The room smells of iron and incense.\n\nSomewhere behind the walls, a bell keeps ringing.",
        5.5
    )

func _create_floor() -> void:
    var floor := StaticBody2D.new()
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(LEVEL_WIDTH + 200.0, 40.0)
    shape.shape = rectangle
    shape.position = Vector2(LEVEL_WIDTH * 0.5, FLOOR_Y + 20.0)
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
    rs.position = Vector2(LEVEL_WIDTH + 20.0, 360)
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

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
        WorldState.delete_save()
        get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")
        get_viewport().set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(0, 0, LEVEL_WIDTH, 720), Color("#100d12"))
    draw_rect(Rect2(0, FLOOR_Y, LEVEL_WIDTH, 180), Color("#211a22"))

    draw_rect(Rect2(120, 280, 420, 240), Color("#29222c"))
    draw_rect(Rect2(180, 240, 300, 40), Color("#352d38"))
    draw_string(ThemeDB.fallback_font, Vector2(210, 215), "SURGICAL WARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#7d6c73"))

    for x in [700.0, 1120.0, 1500.0]:
        draw_rect(Rect2(x - 55, 310, 110, 210), Color("#1f1a22"))
        draw_rect(Rect2(x - 44, 330, 88, 12), Color("#46343b"))
        draw_circle(Vector2(x, 320), 9, Color("#9b5c64"))

    draw_colored_polygon(
        PackedVector2Array([
            Vector2(1780, 520),
            Vector2(1900, 270),
            Vector2(2020, 520)
        ]),
        Color("#241e27")
    )
    draw_string(ThemeDB.fallback_font, Vector2(1810, 250), "THE ROAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#6d5c64"))

    if not exit_open:
        draw_rect(Rect2(2000, 300, 90, 220), Color("#18151b"))
        draw_line(Vector2(2010, 320), Vector2(2010, 500), Color("#5d4c55"), 5.0)
        draw_line(Vector2(2080, 320), Vector2(2080, 500), Color("#5d4c55"), 5.0)
    else:
        draw_rect(Rect2(2000, 300, 90, 220), Color("#33232a"))
        draw_string(ThemeDB.fallback_font, Vector2(1995, 275), "OPEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d6c7b2"))
