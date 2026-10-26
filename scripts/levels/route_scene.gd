extends Node2D

@export var route_id: String = "church"

const CULTIST_SCENE: PackedScene = preload("res://scenes/enemies/cultist.tscn")
const PALE_HOUND_SCENE: PackedScene = preload("res://scenes/enemies/pale_hound.tscn")

var hero: CharacterBody2D
var narrative: CanvasLayer
var hud: CanvasLayer
var route_enemy: CharacterBody2D
var route_npc: Node2D
var route_exit: Area2D
var route_memory_echo: Node2D


func _enter_tree() -> void:
    WorldState.prepare_scene_runtime()


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().paused = false
    WorldState.input_locked = false
    get_tree().process_frame.connect(_ensure_route_runtime, CONNECT_ONE_SHOT)

    WorldState.selected_route = route_id
    WorldState.set_location("route_%s" % route_id)
    if WorldState.route_complete:
        print("[NEREIS][ROUTE] Replaying completed route=%s" % route_id)
    WorldState.set_checkpoint(Vector2(420, 520))

    hero = $Hero as CharacterBody2D
    var camera := hero.get_node("HeroCamera") as Camera2D
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = 2200
    camera.limit_bottom = 720

    narrative = $Narrative as CanvasLayer
    hud = $HUD as CanvasLayer
    route_npc = $RouteNPC as Node2D
    route_exit = $RouteExit as Area2D
    route_memory_echo = $RouteMemoryEcho as Node2D
    route_enemy = get_node("RouteCultist" if route_id == "church" else "RoutePaleHound") as CharacterBody2D

    hero.defeated.connect(_on_hero_defeated)
    route_npc.interacted.connect(_on_route_npc_interacted.bind(route_npc))
    route_exit.reached.connect(_on_route_exit_reached)
    route_memory_echo.interacted.connect(_on_route_memory_interacted.bind(route_memory_echo))
    hud.bind_hero(hero)

    if WorldState.route_complete:
        route_enemy.queue_free()
        route_enemy = null
    get_tree().create_timer(0.6).timeout.connect(_show_route_intro)
    queue_redraw()


func _spawn_route_enemy() -> void:
    if is_instance_valid(route_enemy) and not route_enemy.is_queued_for_deletion():
        return
    if WorldState.route_complete:
        route_enemy = null
        return
    var scene: PackedScene = CULTIST_SCENE if route_id == "church" else PALE_HOUND_SCENE
    var instance := scene.instantiate() as CharacterBody2D
    if instance == null:
        push_error("Failed to instantiate route enemy scene for route " + route_id)
        return
    instance.name = "RouteCultist" if route_id == "church" else "RoutePaleHound"
    instance.position = Vector2(1220, 520)
    add_child(instance)
    route_enemy = instance


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

func _process(_delta: float) -> void:
    if not WorldState.input_locked and get_tree().paused:
        get_tree().paused = false
        print("[NEREIS][ROUTE] Cleared latent pause state")

    if hero != null and not WorldState.input_locked and not hero.is_physics_processing():
        hero.set_physics_process(true)

func _ensure_route_runtime() -> void:
    WorldState.prepare_scene_runtime()
    get_tree().paused = false
    WorldState.input_locked = false
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

func _on_hero_defeated() -> void:
    if is_instance_valid(route_enemy) and not route_enemy.is_queued_for_deletion():
        route_enemy.queue_free()
    route_enemy = null
    call_deferred("_spawn_route_enemy")
    print("[NEREIS][ROUTE] Hero defeated; route encounter reset")

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
        WorldState.delete_save()
        print("[NEREIS][DEBUG] Route run reset; returning to Vertical Slice")
        get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")
        var viewport := get_viewport()
        if viewport:
            viewport.set_input_as_handled()

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
