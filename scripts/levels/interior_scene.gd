extends Node2D

@export var location_id: String = "tavern"

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const ROUTE_NPC_SCRIPT = preload("res://scripts/npc/route_npc.gd")
const INTERIOR_EXIT_SCRIPT = preload("res://scripts/world/interior_exit.gd")

var hero: CharacterBody2D
var camera: Camera2D
var narrative: CanvasLayer
var hud: CanvasLayer
var exit: Area2D

func _ready() -> void:
    WorldState.set_location(location_id)
    print("[NEREIS][INTERIOR] Entered %s route=%s" % [location_id, WorldState.selected_route])
    _create_floor()
    _create_boundaries()
    _spawn_hero()
    _spawn_npc()
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

    camera = Camera2D.new()
    camera.name = "HeroCamera"
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = 1800
    camera.limit_bottom = 720
    camera.position = Vector2.ZERO
    hero.add_child(camera)

func _spawn_npc() -> void:
    var npc := Node2D.new()
    npc.set_script(ROUTE_NPC_SCRIPT)
    npc.position = Vector2(900, 520)

    if location_id == "tavern":
        npc.npc_id = "tavern_keeper"
        npc.display_name = "TAVERN KEEPER"
        if WorldState.selected_route == "lullaby":
            npc.dialogue = "The keeper watches you enter.\n\n\"You heard the song too. Don't pretend you didn't.\""
        else:
            npc.dialogue = "The keeper notices the church seal and stops polishing the glass.\n\n\"We don't serve church messengers here. Not after what happened last winter.\""
    else:
        npc.npc_id = "church_confessor"
        npc.display_name = "CHURCH CONFESSOR"
        npc.dialogue = "The confessor recognizes the Hero before the Hero recognizes him.\n\n\"Your confession was never finished.\""

    add_child(npc)
    npc.interacted.connect(_on_npc_interacted.bind(npc))

func _spawn_exit() -> void:
    exit = Area2D.new()
    exit.set_script(INTERIOR_EXIT_SCRIPT)
    exit.position = Vector2(1660, 520)
    exit.name = "InteriorExit"
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
    if location_id == "tavern":
        narrative.show_message("THE TAVERN", "The room is warmer than the road.\n\nSomewhere behind the bar, a glass is placed down by a hand you cannot see.", 6.0)
    else:
        narrative.show_message("THE CHURCH", "Incense clings to the stone.\n\nThe Hero's footsteps are familiar to the room.", 6.0)

func _on_npc_interacted(npc: Node) -> void:
    narrative.show_message(npc.display_name, npc.dialogue, 6.0)

func _on_exit_reached() -> void:
    WorldState.set_location("village")
    narrative.show_message("BACK TO THE VILLAGE", "The village waits outside.", 3.0)
    get_tree().create_timer(3.2).timeout.connect(_return_to_village)

func _return_to_village() -> void:
    get_tree().change_scene_to_file("res://scenes/village_hub.tscn")

func _create_floor() -> void:
    var floor := StaticBody2D.new()
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(1800, 40)
    shape.shape = rectangle
    shape.position = Vector2(900, 540)
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
    rs.position = Vector2(1820, 360)
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
        print("[NEREIS][DEBUG] Interior run reset; returning to Vertical Slice")
        get_tree().change_scene_to_file("res://scenes/main.tscn")
        get_viewport().set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1800, 720), Color("#141116"))
    draw_rect(Rect2(0, 520, 1800, 200), Color("#201c22"))

    if location_id == "tavern":
        draw_rect(Rect2(480, 290, 840, 230), Color("#2e252e"))
        draw_rect(Rect2(700, 400, 420, 120), Color("#211a21"))
        draw_string(ThemeDB.fallback_font, Vector2(820, 380), "TAVERN HALL", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#d6c7b2"))
        for x in range(560, 1320, 120):
            draw_circle(Vector2(x, 350), 10, Color("#8e7777"))
    else:
        draw_rect(Rect2(420, 220, 960, 300), Color("#29222c"))
        draw_colored_polygon(
            PackedVector2Array([
                Vector2(380, 220),
                Vector2(900, 80),
                Vector2(1420, 220)
            ]),
            Color("#352d38")
        )
        draw_rect(Rect2(850, 350, 100, 170), Color("#17141b"))
        draw_string(ThemeDB.fallback_font, Vector2(800, 190), "CHURCH NAVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#d6c7b2"))

    draw_rect(Rect2(1550, 370, 120, 150), Color("#241d25"))
    draw_string(ThemeDB.fallback_font, Vector2(1560, 350), "VILLAGE EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#796d67"))
