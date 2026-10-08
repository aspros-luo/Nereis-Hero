extends Node2D

@export var route_id: String = "church"

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const ROUTE_NPC_SCRIPT = preload("res://scripts/npc/route_npc.gd")
const ROUTE_ECHO_SCRIPT = preload("res://scripts/world/route_memory_echo.gd")
const CHECKPOINT_SCRIPT = preload("res://scripts/world/checkpoint.gd")
const HOUND_SCRIPT = preload("res://scripts/enemies/pale_hound.gd")
const CULTIST_SCRIPT = preload("res://scripts/enemies/cultist.gd")
const ROUTE_EXIT_SCRIPT = preload("res://scripts/world/route_exit.gd")

var hero: CharacterBody2D
var camera: Camera2D
var narrative: CanvasLayer
var hud: CanvasLayer
var checkpoint: Area2D
var route_enemy: CharacterBody2D
var route_enemy_defeated := false
var route_exit: Area2D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    WorldState.prepare_scene_runtime()
    get_tree().process_frame.connect(_ensure_route_runtime, CONNECT_ONE_SHOT)
    if WorldState.route_complete:
        print("[NEREIS][ROUTE] Replaying completed route=%s" % route_id)

    WorldState.selected_route = route_id
    WorldState.set_location("route_%s" % route_id)

    print("[NEREIS][ROUTE] Entered route=%s" % route_id)
    WorldState.set_checkpoint(Vector2(420, 520))
    _create_floor()
    _create_boundaries()
    _spawn_hero()
    _spawn_checkpoint()
    _spawn_route_enemy()
    _spawn_route_npc()
    _spawn_route_exit()
    _spawn_route_memory_echo()
    hero.defeated.connect(_on_hero_defeated)
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

func _spawn_checkpoint() -> void:
    checkpoint = Area2D.new()
    checkpoint.set_script(CHECKPOINT_SCRIPT)
    checkpoint.position = Vector2(420, 520)
    checkpoint.name = "RouteCheckpoint"
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(130, 110)
    shape.shape = rectangle
    shape.position = Vector2(0, -55)
    checkpoint.add_child(shape)
    add_child(checkpoint)

func _spawn_route_enemy() -> void:
    if is_instance_valid(route_enemy) and not route_enemy.is_queued_for_deletion():
        return

    if WorldState.route_complete:
        route_enemy = null
        return

    route_enemy_defeated = false
    route_enemy = CharacterBody2D.new()

    if route_id == "church":
        route_enemy.set_script(CULTIST_SCRIPT)
        route_enemy.position = Vector2(1220, 520)
        route_enemy.name = "RouteCultist"
        _add_character_collision(route_enemy, 20.0, 44.0)
        print("[NEREIS][ROUTE] Church Route Cultist encounter spawned")
    else:
        route_enemy.set_script(HOUND_SCRIPT)
        route_enemy.position = Vector2(1220, 520)
        route_enemy.name = "RoutePaleHound"
        _add_character_collision(route_enemy, 25.0, 42.0)
        print("[NEREIS][ROUTE] Lullaby Route Pale Hound encounter spawned")

    add_child(route_enemy)
    route_enemy.defeated.connect(_on_route_enemy_defeated.bind(route_enemy))

func _on_route_enemy_defeated(enemy: Node) -> void:
    route_enemy_defeated = true
    print("[NEREIS][ROUTE] Route encounter defeated=%s" % enemy.name)

func _spawn_route_npc() -> void:
    var npc := Node2D.new()
    npc.set_script(ROUTE_NPC_SCRIPT)

    if route_id == "lullaby":
        npc.position = Vector2(900, 520)
        npc.npc_id = "traveling_merchant"
        npc.display_name = "TRAVELING MERCHANT"
        npc.dialogue = "The merchant studies your face for a long moment.\n\n\"You walked this road before. You were carrying someone then. Not a sword.\""
    else:
        npc.position = Vector2(900, 520)
        npc.npc_id = "amnesiac_youth"
        npc.display_name = "AMNESIAC YOUTH"
        npc.dialogue = "The young man touches the church seal and recoils.\n\n\"They told me you died inside the church. I remember hearing your name after the screaming stopped.\""

    add_child(npc)
    npc.interacted.connect(_on_route_npc_interacted.bind(npc))

func _spawn_route_exit() -> void:
    route_exit = Area2D.new()
    route_exit.set_script(ROUTE_EXIT_SCRIPT)
    route_exit.position = Vector2(2070, 520)
    route_exit.name = "RouteExit"
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(100, 130)
    shape.shape = rectangle
    shape.position = Vector2(0, -65)
    route_exit.add_child(shape)
    add_child(route_exit)
    route_exit.reached.connect(_on_route_exit_reached)

func _on_route_exit_reached() -> void:
    if route_id == "lullaby":
        narrative.show_message("THE VILLAGE LIGHTS", "The road ends at a cluster of warm windows.\n\nYou recognize the tavern before you recognize why.", 6.0)
    else:
        narrative.show_message("THE OLD CHURCH", "The bell is silent. Your name is not.\n\nSomewhere beyond the doors, someone has been waiting for you.", 6.0)
    await narrative.message_finished
    _enter_village_hub()
    queue_redraw()

func _enter_village_hub() -> void:
    print("[NEREIS][VILLAGE] Leaving route=%s -> Village Hub" % WorldState.selected_route)
    SceneTransition.fade_to_scene("res://scenes/village_hub.tscn")

func _spawn_route_memory_echo() -> void:
    var echo := Node2D.new()
    echo.set_script(ROUTE_ECHO_SCRIPT)

    if route_id == "lullaby":
        echo.position = Vector2(1450, 520)
        echo.echo_id = "lullaby_broken_bell"
        echo.humanity_delta = 1
        echo.display_name = "BROKEN BELL"
        echo.dialogue = "The bell rings without moving.\n\nA child hums a melody you remember from before you were born."
    else:
        echo.position = Vector2(1450, 520)
        echo.echo_id = "church_ledger"
        echo.humanity_delta = -4
        echo.display_name = "CHURCH LEDGER"
        echo.dialogue = "Your name is written in the margin three times.\n\nThe first is dated seven years ago. The second is yesterday. The third has no date."

    add_child(echo)
    echo.interacted.connect(_on_route_memory_interacted.bind(echo))

func _on_hero_defeated() -> void:
    if is_instance_valid(route_enemy) and not route_enemy.is_queued_for_deletion():
        route_enemy.queue_free()
    route_enemy = null
    call_deferred("_spawn_route_enemy")
    print("[NEREIS][ROUTE] Hero defeated; route encounter reset")

func _spawn_ui() -> void:
    narrative = CanvasLayer.new()
    narrative.set_script(NARRATIVE_SCRIPT)
    add_child(narrative)

    hud = CanvasLayer.new()
    hud.set_script(HUD_SCRIPT)
    add_child(hud)
    hud.bind_hero(hero)

    get_tree().create_timer(0.6).timeout.connect(_show_route_intro)

func _process(_delta: float) -> void:
    if not WorldState.input_locked and get_tree().paused:
        get_tree().paused = false
        WorldState.input_locked = false
        print("[NEREIS][ROUTE] Cleared latent pause state")

    if hero != null and not WorldState.input_locked and not hero.is_physics_processing():
        hero.set_physics_process(true)

func _ensure_route_runtime() -> void:
    WorldState.prepare_scene_runtime()
    if hero != null:
        hero.set_physics_process(true)

func _show_route_intro() -> void:
    WorldState.prepare_scene_runtime()
    if route_id == "lullaby":
        narrative.show_caption("THE LULLABY PATH", "The road bends toward the village lights.\n\nYou are certain you have never been here. Your hands disagree.", 2.8)
    else:
        narrative.show_caption("THE CHURCH ROAD", "Stone markers line the road toward the old church.\n\nEach one bears your name.", 2.8)

func _on_route_npc_interacted(npc: Node) -> void:
    print("[NEREIS][STORY] Route NPC interaction id=%s" % npc.npc_id)
    narrative.show_message(npc.display_name, npc.dialogue, 7.0)

func _on_route_memory_interacted(echo: Node) -> void:
    WorldState.record_route_memory(echo.echo_id, echo.humanity_delta)
    print("[NEREIS][STORY] Route memory displayed id=%s" % echo.echo_id)
    narrative.show_message(echo.display_name, echo.dialogue, 7.0)

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
        get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")
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
    draw_string(ThemeDB.fallback_font, Vector2(100, 230), NereisLocalization.translate_text("THE CHURCH ROAD"), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#4d454d"))
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
    draw_string(ThemeDB.fallback_font, Vector2(1500, 470), NereisLocalization.translate_text("THE OLD CHURCH"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#796d67"))

func _draw_lullaby_path() -> void:
    draw_string(ThemeDB.fallback_font, Vector2(100, 230), NereisLocalization.translate_text("THE LULLABY PATH"), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#4d454d"))
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
    draw_string(ThemeDB.fallback_font, Vector2(1660, 330), NereisLocalization.translate_text("THE VILLAGE LIGHTS"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#796d67"))
