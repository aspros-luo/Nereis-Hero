extends Node2D
## Shared playable graybox for the first connected world-map loop.
## 第一条互通地图环路的通用可玩灰盒场景。

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const INTERACTION_DOOR_SCRIPT = preload("res://scripts/world/interaction_door.gd")
const RESONANCE_SOURCE_SCRIPT = preload("res://scripts/world/resonance_source_clue.gd")
const RESONANCE_SECRET_GATE_SCRIPT = preload("res://scripts/world/resonance_secret_gate.gd")

@export var region_id: String = "A2"
@export var location_id: String = "ash_forest"
@export var region_title: String = "THE OLD PILGRIM ROAD"
@export var map_width: float = 2600.0
@export var floor_y: float = 540.0

var hero: CharacterBody2D
var camera: Camera2D
var narrative: CanvasLayer
var hud: CanvasLayer
var platforms: Array[Rect2] = []
var respawning := false

func _ready() -> void:
    WorldState.prepare_scene_runtime()
    var spawn_side := WorldState.pending_region_spawn_side
    WorldState.pending_region_spawn_side = "west"
    WorldState.set_location(location_id)

    _create_floor()
    _create_boundaries()
    _configure_platforms()
    _spawn_hero(_spawn_x_for_side(spawn_side))
    _spawn_ui()
    _spawn_region_sources()
    _spawn_region_exits()
    queue_redraw()

    var intro_id := "graybox_intro_%s" % location_id
    if intro_id not in WorldState.achievement_flags:
        WorldState.record_achievement(intro_id)
        get_tree().create_timer(0.55).timeout.connect(_show_intro)

func _spawn_x_for_side(side: String) -> float:
    if side == "east":
        return map_width - 180.0
    if region_id == "H01":
        # The village entrance drops the Hero near the well shaft, not at the far edge.
        # 从村庄进入井底时，主角应出现在井道附近，而不是场景边缘。
        return 700.0
    return 180.0

func _spawn_hero(spawn_x: float) -> void:
    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.position = Vector2(spawn_x, floor_y)
    hero.name = "Hero"
    _add_character_collision(hero, 18.0, 48.0)
    add_child(hero)
    hero.defeated.connect(_on_hero_defeated)
    # Keep death recovery inside the current region instead of reusing a previous scene's checkpoint.
    # 每个灰盒区域记录自己的入口检查点，避免死亡后回到上一个场景的坐标。
    WorldState.set_checkpoint(hero.global_position)

    camera = Camera2D.new()
    camera.name = "HeroCamera"
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = int(map_width)
    camera.limit_bottom = 720
    hero.add_child(camera)

func _spawn_ui() -> void:
    narrative = CanvasLayer.new()
    narrative.set_script(NARRATIVE_SCRIPT)
    add_child(narrative)

    hud = CanvasLayer.new()
    hud.set_script(HUD_SCRIPT)
    add_child(hud)
    hud.bind_hero(hero)
    hud.set_story_mode(region_title, _get_objective_text())

func _get_objective_text() -> String:
    match region_id:
        "A2":
            return "FOLLOW THE OLD ROAD. LISTEN TO THE BELL."
        "A3":
            return "FIND THE STREET THAT THE CITY FORGOT."
        "A4":
            return "TRACE THE OLD STONE BENEATH THE WATER."
        "H01":
            return "FIND A WAY BACK TO THE SURFACE."
        _:
            return "SEARCH THE ABNORMAL STONEWORK."

func _show_intro() -> void:
    if not is_instance_valid(narrative):
        return
    match region_id:
        "A2":
            narrative.show_message(
                "THE OLD PILGRIM ROAD",
                "The forest has grown over the road, not across it.\n\nA bell hangs ahead. Its tongue does not move.",
                5.0
            )
        "A3":
            narrative.show_message(
                "THE FORGOTTEN CITY",
                "The street ends at a wall that should be facing another street.\n\nA faded sign names a third road. No road is there.",
                5.0
            )
        "A4":
            narrative.show_message(
                "THE SEDIMENT HALL",
                "New pipes run through stone that was already old when the pipes were made.\n\nWater moves somewhere below your feet.",
                5.0
            )
        "H01":
            narrative.show_message(
                "THE WELL BELOW THE WELL",
                "The shaft is deeper than the village well could contain.\n\nYour footsteps return from above.",
                5.0
            )

func _create_floor() -> void:
    var floor := StaticBody2D.new()
    floor.name = "GreyboxGround"
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(map_width, 40.0)
    shape.shape = rectangle
    shape.position = Vector2(map_width * 0.5, floor_y + 20.0)
    floor.add_child(shape)
    add_child(floor)

func _create_boundaries() -> void:
    for x in [-20.0, map_width + 20.0]:
        var wall := StaticBody2D.new()
        var shape := CollisionShape2D.new()
        var rectangle := RectangleShape2D.new()
        rectangle.size = Vector2(40.0, 720.0)
        shape.shape = rectangle
        shape.position = Vector2(x, 360.0)
        wall.add_child(shape)
        add_child(wall)

func _configure_platforms() -> void:
    platforms.clear()
    match region_id:
        "A2":
            _add_platform(Rect2(430, 485, 105, 20))
            _add_platform(Rect2(535, 450, 110, 20))
            _add_platform(Rect2(645, 415, 130, 20))
            _add_platform(Rect2(930, 475, 180, 18))
            _add_platform(Rect2(1200, 435, 150, 18))
            _add_platform(Rect2(1500, 480, 160, 18))
            _add_platform(Rect2(1840, 445, 130, 18))
        "A3":
            _add_platform(Rect2(300, 470, 170, 18))
            _add_platform(Rect2(600, 430, 110, 18))
            _add_platform(Rect2(850, 390, 180, 18))
            _add_platform(Rect2(1190, 465, 200, 18))
            _add_platform(Rect2(1540, 425, 150, 18))
            _add_platform(Rect2(1880, 470, 170, 18))
            _add_platform(Rect2(2180, 410, 140, 18))
        "A4":
            _add_platform(Rect2(360, 475, 140, 18))
            _add_platform(Rect2(640, 435, 120, 18))
            _add_platform(Rect2(940, 395, 180, 18))
            _add_platform(Rect2(1260, 455, 190, 18))
            _add_platform(Rect2(1600, 420, 150, 18))
            _add_platform(Rect2(1980, 470, 170, 18))
        "H01":
            _add_platform(Rect2(310, 465, 140, 18))
            _add_platform(Rect2(540, 420, 130, 18))
            _add_platform(Rect2(780, 375, 150, 18))
            _add_platform(Rect2(1040, 430, 160, 18))
            _add_platform(Rect2(1320, 475, 140, 18))

func _add_platform(rect: Rect2) -> void:
    platforms.append(rect)
    var body := StaticBody2D.new()
    body.position = rect.position
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = rect.size
    shape.shape = rectangle
    shape.position = rect.size * 0.5
    body.add_child(shape)
    add_child(body)

func _spawn_region_sources() -> void:
    match region_id:
        "A2":
            _spawn_source(
                Vector2(735, floor_y - 18.0),
                "anomaly_bell_retiming",
                "THE BELL THAT DID NOT MOVE",
                "The bell's tongue hangs still.\n\nThe sound arrives anyway. The stone beneath your hand vibrates once, then stops.\n\nA second pulse remains behind your eyes.",
                12,
                0,
                0,
                "resonance_sight"
            )
            _spawn_source(
                Vector2(1530, floor_y - 18.0),
                "anomaly_old_pilgrim_echo",
                "THE SECOND ECHO",
                "You tap the old milestone. The answer comes from the road behind you.\n\nThe stone is warm, as if someone stood here moments ago.",
                18
            )
        "A3":
            _spawn_source(
                Vector2(900, floor_y - 18.0),
                "anomaly_erased_street_sign",
                "THE THIRD STREET",
                "The sign names three streets. Two remain.\n\nScratches cover the space where the third direction should point.",
                28
            )
        "A4":
            _spawn_source(
                Vector2(980, floor_y - 18.0),
                "anomaly_old_stone_layer",
                "STONE BENEATH THE PIPES",
                "The pipes are bolted into stone cut by a different hand.\n\nThe workers who built the pipes did not carve the hall.",
                36
            )

func _spawn_source(
    source_position: Vector2,
    source_id: String,
    display_name: String,
    description: String,
    resonance_target: int,
    ancient_delta: int = 0,
    outer_delta: int = 0,
    unlock_ability_id: String = ""
) -> void:
    var clue := Node2D.new()
    clue.set_script(RESONANCE_SOURCE_SCRIPT)
    clue.name = "Anomaly_%s" % source_id
    clue.position = source_position
    clue.source_id = source_id
    clue.display_name = display_name
    clue.description = description
    clue.resonance_target = resonance_target
    clue.ancient_exposure_delta = ancient_delta
    clue.outer_exposure_delta = outer_delta
    clue.unlock_ability_id = unlock_ability_id
    clue.unlock_source_type = "resonance"
    add_child(clue)
    clue.activated.connect(_on_source_activated.bind(source_id, unlock_ability_id))

func _on_source_activated(
    display_name: String,
    description: String,
    first_record: bool,
    source_id: String,
    unlock_ability_id: String
) -> void:
    if not first_record or not is_instance_valid(narrative):
        return
    var message := description
    if not unlock_ability_id.is_empty() and WorldState.is_ability_unlocked(unlock_ability_id):
        message += "\n\nAbility awakened: RESONANCE SIGHT — press V to listen."
    narrative.show_message(display_name, message, 6.0)

func _spawn_region_exits() -> void:
    match region_id:
        "A2":
            _spawn_exit_door(
                72.0, "E  RETURN TO VILLAGE", "village",
                "res://scenes/village_hub.tscn", "west"
            )
            _spawn_exit_door(
                map_width - 72.0, "E  ENTER THE FORGOTTEN CITY", "forgotten_city",
                "res://scenes/forgotten_city.tscn", "west"
            )
        "A3":
            _spawn_exit_door(
                72.0, "E  RETURN TO PILGRIM ROAD", "ash_forest",
                "res://scenes/ash_forest.tscn", "east"
            )
            _spawn_exit_door(
                map_width - 72.0, "E  DESCEND TO THE RESERVOIR", "sewer_reservoir",
                "res://scenes/sewer_reservoir.tscn", "west"
            )
        "A4":
            _spawn_exit_door(
                72.0, "E  RETURN TO THE CITY", "forgotten_city",
                "res://scenes/forgotten_city.tscn", "east"
            )
            if "reached_A4_via_A3" in WorldState.achievement_flags:
                _spawn_a4_hidden_well_gate(map_width - 105.0)
        "H01":
            _spawn_exit_door(
                72.0, "E  RETURN TO VILLAGE", "village",
                "res://scenes/village_hub.tscn", "west"
            )
            var can_return_to_a4 := (
                "reached_A4_via_A3" in WorldState.achievement_flags
                and WorldState.is_hidden_path_opened("H01")
            )
            _spawn_exit_door(
                map_width - 105.0,
                "E  RETURN THROUGH THE WELL GATE",
                "sewer_reservoir",
                "res://scenes/sewer_reservoir.tscn",
                "east",
                can_return_to_a4
            )

func _spawn_a4_hidden_well_gate(x: float) -> void:
    # This is the far-side entrance to H01, not a bypass: it still requires active Resonance Sight.
    # A4 另一侧井门也使用同一 H01 状态，但首次发现仍必须通过灵视条件。
    var gate := Node2D.new()
    gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
    gate.name = "ResonanceWellGateFromA4"
    gate.position = Vector2(x, floor_y)
    gate.secret_id = "H01"
    gate.target_scene_path = "res://scenes/hidden_well.tscn"
    gate.target_location_id = "hidden_well"
    gate.target_spawn_side = "east"
    gate.required_resonance = 12
    gate.required_ancient_exposure = 0
    gate.required_outer_exposure = 0
    gate.opened.connect(_on_hidden_well_gate_opened)
    add_child(gate)

func _on_hidden_well_gate_opened(secret_id: String) -> void:
    if narrative == null or not is_instance_valid(narrative):
        return
    narrative.show_message(
        "THE WELL HAS ANOTHER MOUTH",
        "The stone opens without turning.\n\nYou can no longer tell which side is above.",
        4.0
    )

func _spawn_exit_door(
    x: float,
    prompt_text: String,
    target_location: String,
    target_scene: String,
    spawn_side: String,
    enabled: bool = true
) -> void:
    var door := Area2D.new()
    door.set_script(INTERACTION_DOOR_SCRIPT)
    door.name = "Exit_%s" % target_location
    door.position = Vector2(x, floor_y)
    door.prompt_text = prompt_text
    door.enabled = enabled

    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(110.0, 138.0)
    shape.shape = rectangle
    shape.position = Vector2(0.0, -69.0)
    door.add_child(shape)
    add_child(door)
    door.interacted.connect(_on_exit_interacted.bind(target_location, target_scene, spawn_side))

func _on_exit_interacted(target_location: String, target_scene: String, spawn_side: String) -> void:
    if region_id == "A3" and target_location == "sewer_reservoir":
        WorldState.record_achievement("reached_A4_via_A3")
    if target_location == "hidden_well":
        WorldState.discover_hidden_region("H01")
        WorldState.open_hidden_path("H01")
        WorldState.mark_hidden_region_entered("H01")
    elif target_location == "sewer_reservoir" and region_id == "H01":
        WorldState.mark_hidden_region_entered("H01")

    WorldState.pending_region_spawn_side = spawn_side
    WorldState.set_location(target_location)
    SceneTransition.fade_to_scene(target_scene)

func _on_hero_defeated() -> void:
    if respawning:
        return
    respawning = true
    await get_tree().create_timer(0.75).timeout
    if is_instance_valid(hero):
        hero.velocity = Vector2.ZERO
        hero.global_position = WorldState.checkpoint_position
        if hero.has_method("restore_full"):
            hero.call("restore_full")
    WorldState.input_locked = false
    respawning = false

func _add_character_collision(character: CharacterBody2D, radius: float, height: float) -> void:
    var collision := CollisionShape2D.new()
    var capsule := CapsuleShape2D.new()
    capsule.radius = radius
    capsule.height = height
    collision.shape = capsule
    collision.position = Vector2(0, -height * 0.5)
    character.add_child(collision)

func _draw() -> void:
    var background := _background_color()
    draw_rect(Rect2(0.0, 0.0, map_width, 720.0), background)
    draw_rect(Rect2(0.0, floor_y, map_width, 180.0), Color("#211b23"))

    for x in range(0, int(map_width), 64):
        draw_line(Vector2(x, floor_y), Vector2(x + 32, floor_y + 32), Color("#302a31"), 2.0)

    match region_id:
        "A2":
            _draw_forest_landmarks()
        "A3":
            _draw_city_landmarks()
        "A4":
            _draw_reservoir_landmarks()
        "H01":
            _draw_well_landmarks()

    for platform in platforms:
        draw_rect(platform, _platform_color())
        draw_line(platform.position, Vector2(platform.end.x, platform.position.y), Color("#7d6c65"), 2.0)

    draw_string(
        ThemeDB.fallback_font,
        Vector2(88.0, 190.0),
        region_title,
        HORIZONTAL_ALIGNMENT_LEFT,
        -1.0,
        28,
        Color("#b7a48c")
    )

func _background_color() -> Color:
    match region_id:
        "A2":
            return Color("#171823")
        "A3":
            return Color("#19161d")
        "A4":
            return Color("#11151c")
        "H01":
            return Color("#100f18")
        _:
            return Color("#111018")

func _platform_color() -> Color:
    match region_id:
        "A2":
            return Color("#39343d")
        "A3":
            return Color("#343039")
        "A4":
            return Color("#30353a")
        "H01":
            return Color("#39303a")
        _:
            return Color("#302a33")

func _draw_forest_landmarks() -> void:
    for x in range(180, int(map_width), 230):
        var height := 110 + (int(x / 230) % 3) * 28
        draw_colored_polygon(
            PackedVector2Array([
                Vector2(x - 46, floor_y),
                Vector2(x, floor_y - height),
                Vector2(x + 46, floor_y)
            ]),
            Color("#252934")
        )
        draw_rect(Rect2(x - 8, floor_y - 30, 16, 30), Color("#30272d"))
    draw_rect(Rect2(710, 285, 48, 195), Color("#302c35"))
    draw_line(Vector2(704, 290), Vector2(765, 290), Color("#75666b"), 4.0)
    draw_line(Vector2(735, 300), Vector2(735, 350), Color("#75666b"), 3.0)
    draw_string(ThemeDB.fallback_font, Vector2(690, 260), "NO WIND", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#75666b"))

func _draw_city_landmarks() -> void:
    for x in range(200, int(map_width), 390):
        draw_rect(Rect2(x, floor_y - 190, 150, 190), Color("#29252f"))
        draw_colored_polygon(
            PackedVector2Array([
                Vector2(x - 22, floor_y - 190),
                Vector2(x + 75, floor_y - 285),
                Vector2(x + 172, floor_y - 190)
            ]),
            Color("#342d38")
        )
        draw_rect(Rect2(x + 56, floor_y - 92, 38, 92), Color("#131117"))
        draw_rect(Rect2(x + 20, floor_y - 150, 18, 26), Color("#15131b"))
        draw_rect(Rect2(x + 112, floor_y - 150, 18, 26), Color("#15131b"))
    draw_rect(Rect2(842, 340, 146, 28), Color("#4a3c43"))
    draw_string(ThemeDB.fallback_font, Vector2(855, 360), "III STREET", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#98867e"))
    draw_line(Vector2(905, 365), Vector2(905, 418), Color("#98867e"), 2.0)

func _draw_reservoir_landmarks() -> void:
    for x in range(180, int(map_width), 410):
        draw_arc(Vector2(x, floor_y - 8), 118.0, PI, TAU, 28, Color("#343a46"), 10.0)
        draw_line(Vector2(x - 118, floor_y - 8), Vector2(x - 118, floor_y + 14), Color("#343a46"), 10.0)
        draw_line(Vector2(x + 118, floor_y - 8), Vector2(x + 118, floor_y + 14), Color("#343a46"), 10.0)
    draw_rect(Rect2(0, floor_y + 48, map_width, 36), Color("#19272f"))
    draw_line(Vector2(0, floor_y + 48), Vector2(map_width, floor_y + 48), Color("#405660"), 2.0)
    draw_string(ThemeDB.fallback_font, Vector2(960, floor_y + 75), "WATER BELOW THE STONE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#637a83"))

func _draw_well_landmarks() -> void:
    draw_rect(Rect2(460, 70, 170, floor_y - 70), Color("#1b1822"))
    draw_line(Vector2(460, 70), Vector2(460, floor_y), Color("#403844"), 18.0)
    draw_line(Vector2(630, 70), Vector2(630, floor_y), Color("#403844"), 18.0)
    draw_line(Vector2(460, 170), Vector2(630, 170), Color("#302932"), 12.0)
    draw_line(Vector2(460, 300), Vector2(630, 300), Color("#302932"), 12.0)
    draw_line(Vector2(460, 425), Vector2(630, 425), Color("#302932"), 12.0)
    draw_arc(Vector2(1100, floor_y - 20), 54.0, PI, TAU, 32, Color("#73656d"), 6.0)
    draw_rect(Rect2(1046, floor_y - 20, 108, 22), Color("#16131b"))

