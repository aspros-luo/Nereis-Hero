extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const ROUTE_NPC_SCRIPT = preload("res://scripts/npc/route_npc.gd")
const CHECKPOINT_SCRIPT = preload("res://scripts/world/checkpoint.gd")
const VILLAGE_POI_SCRIPT = preload("res://scripts/world/village_poi.gd")

var hero: CharacterBody2D
var camera: Camera2D
var narrative: CanvasLayer
var hud: CanvasLayer
var checkpoint: Area2D

func _ready() -> void:
    print("[NEREIS][VILLAGE] Entered Village Hub route=%s" % WorldState.selected_route)
    WorldState.set_checkpoint(Vector2(360, 520))
    _create_floor()
    _create_boundaries()
    _spawn_hero()
    _spawn_checkpoint()
    _spawn_gatekeeper()
    _spawn_village_pois()
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

func _spawn_gatekeeper() -> void:
    var npc := Node2D.new()
    npc.set_script(ROUTE_NPC_SCRIPT)
    npc.position = Vector2(760, 520)
    npc.npc_id = "village_gatekeeper"
    npc.display_name = "VILLAGE GATEKEEPER"
    if WorldState.selected_route == "church":
        npc.dialogue = "The gatekeeper studies the church seal.\n\n"They told us you would never return. Why did they send the same man back?""
    else:
        npc.dialogue = "The gatekeeper hears the lullaby on the wind and shuts the tavern door halfway.\n\n"Don't sing that here. Not unless you want the village to remember.""
    add_child(npc)

func _spawn_village_pois() -> void:
    var tavern := Node2D.new()
    tavern.set_script(VILLAGE_POI_SCRIPT)
    tavern.position = Vector2(1730, 520)
    tavern.poi_id = "tavern"
    tavern.display_name = "THE TAVERN"
    tavern.dialogue = "The tavern door is warm beneath your hand.\\n\\nFor a moment you hear a lullaby from inside. The voice stops when you touch the handle."
    add_child(tavern)
    tavern.interacted.connect(_on_village_poi_interacted.bind(tavern))

    var church := Node2D.new()
    church.set_script(VILLAGE_POI_SCRIPT)
    church.position = Vector2(2220, 520)
    church.poi_id = "church"
    church.display_name = "THE CHURCH"
    church.dialogue = "The church door bears your name beneath layers of newer paint.\\n\\nSomeone has tried to erase it many times."
    add_child(church)
    church.interacted.connect(_on_village_poi_interacted.bind(church))

func _on_village_poi_interacted(poi: Node) -> void:
    narrative.show_message(poi.display_name, poi.dialogue, 6.0)

func _spawn_ui() -> void:
    narrative = CanvasLayer.new()
    narrative.set_script(NARRATIVE_SCRIPT)
    add_child(narrative)

    hud = CanvasLayer.new()
    hud.set_script(HUD_SCRIPT)
    add_child(hud)
    hud.bind_hero(hero)

    get_tree().create_timer(0.7).timeout.connect(_show_village_intro)

func _show_village_intro() -> void:
    narrative.show_message(
        "THE VILLAGE",
        "The road ends where the village begins.\n\nThe Hero recognizes none of it. The village recognizes him.",
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
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
        WorldState.delete_save()
        print("[NEREIS][DEBUG] Village run reset; returning to Vertical Slice")
        get_tree().change_scene_to_file("res://scenes/main.tscn")
        get_viewport().set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 2600, 720), Color("#111018"))
    draw_rect(Rect2(0, 520, 2600, 200), Color("#201c22"))
    for x in range(0, 2600, 64):
        draw_line(Vector2(x, 520), Vector2(x + 32, 552), Color("#302a30"), 2.0)

    draw_string(ThemeDB.fallback_font, Vector2(100, 230), "THE VILLAGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("#4d454d"))

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
