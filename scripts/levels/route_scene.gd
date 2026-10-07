extends Node2D

@export var route_id: String = "church"

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const ROUTE_NPC_SCRIPT = preload("res://scripts/npc/route_npc.gd")

var hero: CharacterBody2D
var camera: Camera2D
var narrative: CanvasLayer
var hud: CanvasLayer

func _ready() -> void:
    if WorldState.selected_route == "":
        WorldState.selected_route = route_id

    print("[NEREIS][ROUTE] Entered route=%s" % route_id)
    _create_floor()
    _create_boundaries()
    _spawn_hero()
    _spawn_route_npc()
    _spawn_ui()
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
    camera.limit_right = 2200
    camera.limit_bottom = 720
    camera.position = Vector2.ZERO
    hero.add_child(camera)

func _spawn_route_npc() -> void:
    var npc := Node2D.new()
    npc.set_script(ROUTE_NPC_SCRIPT)

    if route_id == "lullaby":
        npc.position = Vector2(900, 520)
        npc.npc_id = "traveling_merchant"
        npc.display_name = "TRAVELING MERCHANT"
        npc.dialogue = "The merchant studies your face for a long moment.\\n\\n\\"You walked this road before. You were carrying someone then. Not a sword.\\""
    else:
        npc.position = Vector2(900, 520)
        npc.npc_id = "amnesiac_youth"
        npc.display_name = "AMNESIAC YOUTH"
        npc.dialogue = "The young man touches the church seal and recoils.\\n\\n\\"They told me you died inside the church. I remember hearing your name after the screaming stopped.\\""

    add_child(npc)
    npc.interacted.connect(_on_route_npc_interacted.bind(npc))

func _spawn_ui() -> void:
    narrative = CanvasLayer.new()
    narrative.set_script(NARRATIVE_SCRIPT)
    add_child(narrative)

    hud = CanvasLayer.new()
    hud.set_script(HUD_SCRIPT)
    add_child(hud)
    hud.bind_hero(hero)

    get_tree().create_timer(0.6).timeout.connect(_show_route_intro)

func _show_route_intro() -> void:
    if route_id == "lullaby":
        narrative.show_message("THE LULLABY PATH", "The road bends toward the village lights.\n\nYou are certain you have never been here. Your hands disagree.", 6.0)
    else:
        narrative.show_message("THE CHURCH ROAD", "Stone markers line the road toward the old church.\n\nEach one bears your name.", 6.0)

func _on_route_npc_interacted(npc: Node) -> void:
    print("[NEREIS][STORY] Route NPC interaction id=%s" % npc.npc_id)
    narrative.show_message(npc.display_name, npc.dialogue, 7.0)

func _create_floor() -> void:
    var floor := StaticBody2D.new()
    floor.name = "Ground"
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(2200, 40)
    shape.shape = rectangle
    shape.position = Vector2(1100, 540)
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
    right_shape.position = Vector2(2220, 360)
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
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
        WorldState.delete_save()
        print("[NEREIS][DEBUG] Route run reset; returning to Vertical Slice")
        get_tree().change_scene_to_file("res://scenes/main.tscn")
        get_viewport().set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 2200, 720), Color("#111018"))
    draw_rect(Rect2(0, 520, 2200, 200), Color("#201c22"))
    for x in range(0, 2200, 64):
        draw_line(Vector2(x, 520), Vector2(x + 32, 552), Color("#302a30"), 2.0)

    if route_id == "lullaby":
        _draw_lullaby_path()
    else:
        _draw_church_path()

func _draw_church_path() -> void:
    draw_string(ThemeDB.fallback_font, Vector2(100, 230), "THE CHURCH ROAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#4d454d"))
    for x in range(260, 2000, 420):
        draw_circle(Vector2(x, 450), 54, Color("#28222a"))
        draw_rect(Rect2(x - 10, 400, 20, 70), Color("#352d38"))
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(1580, 430),
            Vector2(1680, 250),
            Vector2(1780, 430)
        ]),
        Color("#26202a")
    )
    draw_rect(Rect2(1650, 330, 60, 100), Color("#312934"))
    draw_circle(Vector2(1680, 310), 18, Color("#66545c"))
    draw_string(ThemeDB.fallback_font, Vector2(1500, 470), "THE OLD CHURCH", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#796d67"))

func _draw_lullaby_path() -> void:
    draw_string(ThemeDB.fallback_font, Vector2(100, 230), "THE LULLABY PATH", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#4d454d"))
    for x in range(180, 2100, 300):
        draw_line(Vector2(x, 520), Vector2(x + 40, 390), Color("#312a31"), 10.0)
        draw_line(Vector2(x + 30, 450), Vector2(x - 30, 370), Color("#312a31"), 6.0)
    for x in range(320, 1960, 480):
        draw_circle(Vector2(x, 440), 7.0, Color("#8e7777"))
        draw_circle(Vector2(x + 56, 410), 5.0, Color("#66545c"))
    draw_rect(Rect2(1680, 350, 190, 170), Color("#29232b"))
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(1645, 350),
            Vector2(1775, 250),
            Vector2(1905, 350)
        ]),
        Color("#352d38")
    )
    draw_string(ThemeDB.fallback_font, Vector2(1660, 330), "THE VILLAGE LIGHTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#796d67"))
