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
    if region_id == "A9" and side == "mirror":
        return 1680.0

    if region_id == "A3" and side == "sewer":
        return 1380.0
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
        "A5":
            return "CROSS THE TRENCHES. FIND THE FORTRESS ROAD."
        "A6":
            return "CLIMB THE MONASTERY TOWER. LISTEN FOR THE SILENT BELL."
        "A7":
            return "DESCEND THROUGH THE CELLS. FIND THE ROYAL CRYPT."
        "A8":
            return "READ THE NAMES THAT WERE REMOVED."
        "A9":
            return "CROSS THE OUTER RING. FOLLOW THE RAIN REFLECTIONS."
        "A10":
            return "CLIMB THE PILGRIM STEPS. FIND THE CHURCH INNER COURT."
        "A12":
            return "ENTER THE THRONE DISTRICT. DECIDE WHAT MUST FALL."
        "H07":
            return "FOLLOW THE STREET THAT ONLY EXISTS IN WATER."
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
        "A5":
            narrative.show_message(
                "THE BORDER BATTLEFIELD",
                "The bodies face the wrong direction.\n\nThe fortress gates were closed from the inside.",
                5.0
            )
        "A6":
            narrative.show_message(
                "THE MONASTERY THAT KEPT ITS BELL",
                "Every bell has a tongue.\n\nOne casts no shadow on the wall.",
                5.0
            )
        "A7":
            narrative.show_message(
                "THE PENITENTIAL DEPTHS",
                "The cell doors open inward.\n\nThe names have been scraped from the hinges.",
                5.0
            )
        "A8":
            narrative.show_message(
                "THE ROYAL TOMB",
                "The inscriptions have not weathered away.\n\nSomeone wanted the names to stop existing.",
                5.0
            )
        "A9":
            narrative.show_message(
                "THE ROYAL OUTER RING",
                "Rainwater pools in the street, though the roofs are dry.\n\nThe lamps in the puddles are lit. The lamps above them are not.",
                5.0
            )
        "A10":
            narrative.show_message(
                "THE GREAT CATHEDRAL",
                "The choir stops when you reach the steps.\n\nNo one turns to look at you.",
                5.0
            )
        "A12":
            narrative.show_message(
                "THE INNER CITY",
                "The palace doors stand open.\n\nThe guards have not been dismissed.",
                5.0
            )
        "H07":
            narrative.show_message(
                "MIRROR STREET: BEHIND THE RAIN",
                "The rain falls upward here.\n\nYour reflection arrives one step before you.",
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
        "A5":
            _add_platform(Rect2(280, 485, 185, 18))
            _add_platform(Rect2(560, 455, 160, 18))
            _add_platform(Rect2(850, 485, 210, 18))
            _add_platform(Rect2(1180, 450, 160, 18))
            _add_platform(Rect2(1490, 485, 175, 18))
            _add_platform(Rect2(1800, 445, 185, 18))
            _add_platform(Rect2(2150, 485, 180, 18))
        "A6":
            _add_platform(Rect2(300, 475, 155, 18))
            _add_platform(Rect2(525, 430, 125, 18))
            _add_platform(Rect2(720, 385, 125, 18))
            _add_platform(Rect2(910, 340, 130, 18))
            _add_platform(Rect2(1110, 295, 130, 18))
            _add_platform(Rect2(1320, 350, 155, 18))
            _add_platform(Rect2(1560, 405, 145, 18))
            _add_platform(Rect2(1840, 460, 160, 18))
            _add_platform(Rect2(2150, 485, 150, 18))
        "A7":
            _add_platform(Rect2(300, 480, 170, 18))
            _add_platform(Rect2(585, 440, 140, 18))
            _add_platform(Rect2(850, 480, 185, 18))
            _add_platform(Rect2(1140, 435, 150, 18))
            _add_platform(Rect2(1420, 480, 190, 18))
            _add_platform(Rect2(1740, 440, 150, 18))
            _add_platform(Rect2(2040, 480, 180, 18))
        "A8":
            _add_platform(Rect2(280, 480, 155, 18))
            _add_platform(Rect2(560, 440, 130, 18))
            _add_platform(Rect2(820, 395, 160, 18))
            _add_platform(Rect2(1100, 445, 150, 18))
            _add_platform(Rect2(1390, 395, 170, 18))
            _add_platform(Rect2(1670, 445, 150, 18))
            _add_platform(Rect2(1960, 480, 180, 18))
        "A9":
            _add_platform(Rect2(280, 475, 170, 18))
            _add_platform(Rect2(530, 430, 150, 18))
            _add_platform(Rect2(800, 390, 190, 18))
            _add_platform(Rect2(1110, 445, 165, 18))
            _add_platform(Rect2(1410, 405, 175, 18))
            _add_platform(Rect2(1700, 455, 175, 18))
            _add_platform(Rect2(2040, 420, 170, 18))
        "A10":
            _add_platform(Rect2(260, 485, 185, 18))
            _add_platform(Rect2(520, 440, 155, 18))
            _add_platform(Rect2(760, 395, 160, 18))
            _add_platform(Rect2(1010, 350, 145, 18))
            _add_platform(Rect2(1250, 305, 145, 18))
            _add_platform(Rect2(1480, 350, 160, 18))
            _add_platform(Rect2(1730, 405, 165, 18))
            _add_platform(Rect2(2010, 455, 185, 18))
        "A12":
            _add_platform(Rect2(300, 475, 160, 18))
            _add_platform(Rect2(560, 430, 150, 18))
            _add_platform(Rect2(850, 385, 180, 18))
            _add_platform(Rect2(1160, 435, 170, 18))
            _add_platform(Rect2(1460, 390, 180, 18))
            _add_platform(Rect2(1770, 435, 170, 18))
            _add_platform(Rect2(2100, 475, 190, 18))
        "H07":
            _add_platform(Rect2(250, 475, 150, 18))
            _add_platform(Rect2(520, 425, 125, 18))
            _add_platform(Rect2(780, 380, 160, 18))
            _add_platform(Rect2(1060, 430, 150, 18))
            _add_platform(Rect2(1350, 385, 160, 18))
            _add_platform(Rect2(1650, 440, 150, 18))
            _add_platform(Rect2(1970, 475, 170, 18))
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
                36,
                0,
                0,
                "",
                1
            )

        "A6":
            _spawn_source(
                Vector2(1125, 278),
                "anomaly_silent_bell_window",
                "THE WINDOW WITHOUT A SOUND",
                "The bell tower window has no view beyond it.\n\nIts shadow falls across a wall that is not there.",
                42,
                0,
                0,
                "",
                1
            )
        "A8":
            _spawn_source(
                Vector2(1740, floor_y - 18.0),
                "anomaly_erased_royal_name",
                "THE NAME SCRAPED FROM STONE",
                "The inscription is not worn.\n\nThe chisel marks begin after the stone had already been sealed.",
                55,
                0,
                0,
                "",
                2
            )

        "A9":
            _spawn_source(
                Vector2(1380, floor_y - 18.0),
                "anomaly_mirror_street_echo",
                "THE STREET IN THE PUDDLE",
                "The puddle reflects a street with one more lamp.\n\nYou count the lights again. Nothing changes above you.",
                68,
                0,
                0,
                "",
                0,
                12,
                true
            )

func _spawn_source(
    source_position: Vector2,
    source_id: String,
    display_name: String,
    description: String,
    resonance_target: int,
    ancient_delta: int = 0,
    outer_delta: int = 0,
    unlock_ability_id: String = "",
    ancient_floor: int = 0,
    outer_floor: int = 0,
    require_outer_god_resonance: bool = false
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
    clue.ancient_exposure_floor = ancient_floor
    clue.outer_exposure_floor = outer_floor
    clue.require_outer_god_resonance = require_outer_god_resonance
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
            # The sewer descent branches off mid-market; the main road continues to A5.
            # 下水道入口位于市场中段，城区东侧主路继续通往 A5。
            _spawn_exit_door(
                1480.0, "E  DESCEND TO THE RESERVOIR", "sewer_reservoir",
                "res://scenes/sewer_reservoir.tscn", "west"
            )
            _spawn_exit_door(
                map_width - 72.0, "E  FOLLOW THE BATTLEFIELD ROAD", "old_battlefield",
                "res://scenes/old_battlefield.tscn", "west"
            )
        "A4":
            _spawn_exit_door(
                72.0, "E  OPEN THE INSPECTION HATCH", "forgotten_city",
                "res://scenes/forgotten_city.tscn", "sewer",
                true, "opened_sewer_inspection_hatch_from_A4", "E  RETURN TO THE CITY"
            )
            if "reached_A4_via_A3" in WorldState.achievement_flags:
                _spawn_a4_hidden_well_gate(map_width - 105.0)

        "A5":
            _spawn_exit_door(
                72.0, "E  RETURN TO THE FORGOTTEN CITY", "forgotten_city",
                "res://scenes/forgotten_city.tscn", "east"
            )
            _spawn_exit_door(
                map_width - 72.0, "E  ENTER THE MONASTERY", "monastery_tower",
                "res://scenes/monastery_tower.tscn", "west"
            )
        "A6":
            _spawn_exit_door(
                72.0, "E  RETURN TO THE BATTLEFIELD", "old_battlefield",
                "res://scenes/old_battlefield.tscn", "east"
            )
            _spawn_exit_door(
                map_width - 72.0, "E  DESCEND INTO THE PRISON", "prison_depths",
                "res://scenes/prison_depths.tscn", "west"
            )
        "A7":
            _spawn_exit_door(
                72.0, "E  RETURN TO THE MONASTERY", "monastery_tower",
                "res://scenes/monastery_tower.tscn", "east"
            )
            _spawn_exit_door(
                map_width - 72.0, "E  ENTER THE ROYAL TOMB", "royal_tomb",
                "res://scenes/royal_tomb.tscn", "west"
            )
        "A8":
            _spawn_exit_door(
                72.0, "E  RETURN TO THE PRISON", "prison_depths",
                "res://scenes/prison_depths.tscn", "east"
            )
            _spawn_exit_door(
                map_width - 72.0, "E  ENTER THE ROYAL OUTER RING", "royal_outer_ring",
                "res://scenes/royal_outer_ring.tscn", "west"
            )

        "A9":
            _spawn_exit_door(
                72.0, "E  RETURN TO THE ROYAL TOMB", "royal_tomb",
                "res://scenes/royal_tomb.tscn", "east"
            )
            _spawn_exit_door(
                map_width - 72.0, "E  CLIMB TO THE GREAT CATHEDRAL", "grand_cathedral",
                "res://scenes/grand_cathedral.tscn", "west"
            )
            _spawn_a9_mirror_gate(1850.0)
        "A10":
            _spawn_exit_door(
                72.0, "E  RETURN TO THE OUTER RING", "royal_outer_ring",
                "res://scenes/royal_outer_ring.tscn", "east"
            )
            _spawn_exit_door(
                map_width - 72.0, "E  ENTER THE INNER CITY", "inner_city",
                "res://scenes/inner_city.tscn", "west"
            )
        "A12":
            _spawn_exit_door(
                72.0, "E  RETURN TO THE CATHEDRAL", "grand_cathedral",
                "res://scenes/grand_cathedral.tscn", "east"
            )
            if (
                "reached_A12_via_A10" in WorldState.achievement_flags
                and WorldState.is_hidden_path_opened("H07")
            ):
                _spawn_exit_door(
                    map_width - 350.0, "E  OPEN THE MIRROR STREET SIDE GATE", "mirror_street",
                    "res://scenes/mirror_street.tscn", "east",
                    true, "opened_mirror_street_side_gate", "E  ENTER MIRROR STREET"
                )
        "H07":
            _spawn_exit_door(
                72.0, "E  RETURN THROUGH THE PUDDLES", "royal_outer_ring",
                "res://scenes/royal_outer_ring.tscn", "mirror"
            )
            if "opened_mirror_street_side_gate" in WorldState.achievement_flags:
                _spawn_exit_door(
                    map_width - 72.0, "E  RETURN TO THE INNER CITY", "inner_city",
                    "res://scenes/inner_city.tscn", "west"
                )

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

func _spawn_a9_mirror_gate(x: float) -> void:
    var gate := Node2D.new()
    gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
    gate.name = "ResonanceMirrorStreetGate"
    gate.position = Vector2(x, floor_y)
    gate.secret_id = "H07"
    gate.target_scene_path = "res://scenes/mirror_street.tscn"
    gate.target_location_id = "mirror_street"
    gate.target_spawn_side = "west"
    gate.required_resonance = 68
    gate.required_ancient_exposure = 0
    gate.required_outer_exposure = 12
    gate.require_outer_god_resonance = true
    gate.required_source_ids = ["anomaly_mirror_street_echo"]
    gate.opened.connect(_on_mirror_street_gate_opened)
    add_child(gate)

func _on_mirror_street_gate_opened(secret_id: String) -> void:
    if narrative == null or not is_instance_valid(narrative):
        return
    narrative.show_message(
        "THE STREET THAT WAS REMOVED",
        "The reflection stops following the rain.\n\nFor the first time, the door has a shadow.",
        4.5
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
    enabled: bool = true,
    unlock_once_flag_id: String = "",
    opened_prompt_text: String = ""
) -> void:
    var door := Area2D.new()
    door.set_script(INTERACTION_DOOR_SCRIPT)
    door.name = "Exit_%s" % target_location
    door.position = Vector2(x, floor_y)
    door.prompt_text = prompt_text
    door.enabled = enabled
    door.unlock_once_flag_id = unlock_once_flag_id
    door.opened_prompt_text = opened_prompt_text

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
    if target_location == "inner_city" and region_id == "A10":
        WorldState.record_achievement("reached_A12_via_A10")
    if target_location == "mirror_street":
        WorldState.mark_hidden_region_entered("H07")
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
        "A5":
            _draw_battlefield_landmarks()
        "A6":
            _draw_monastery_landmarks()
        "A7":
            _draw_prison_landmarks()
        "A8":
            _draw_royal_tomb_landmarks()

        "A9":
            _draw_outer_ring_landmarks()
        "A10":
            _draw_cathedral_landmarks()
        "A12":
            _draw_inner_city_landmarks()
        "H07":
            _draw_mirror_street_landmarks()

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
        "A5":
            return Color("#21191a")
        "A6":
            return Color("#191b25")
        "A7":
            return Color("#111319")
        "A8":
            return Color("#1a171d")

        "A9":
            return Color("#1a1a22")
        "A10":
            return Color("#211b25")
        "A12":
            return Color("#201b20")
        "H07":
            return Color("#10191e")

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
        "A5":
            return Color("#463635")
        "A6":
            return Color("#393643")
        "A7":
            return Color("#35333b")
        "A8":
            return Color("#40383e")

        "A9":
            return Color("#373741")
        "A10":
            return Color("#403847")
        "A12":
            return Color("#42343b")
        "H07":
            return Color("#2d4144")

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

func _draw_outer_ring_landmarks() -> void:
    for x in range(200, int(map_width), 360):
        draw_rect(Rect2(x, floor_y - 180, 170, 180), Color("#292733"))
        draw_colored_polygon(PackedVector2Array([
            Vector2(x - 18, floor_y - 180),
            Vector2(x + 85, floor_y - 250),
            Vector2(x + 188, floor_y - 180)
        ]), Color("#35313b"))
        draw_rect(Rect2(x + 65, floor_y - 92, 35, 92), Color("#14131a"))
    draw_rect(Rect2(1320, floor_y - 160, 170, 160), Color("#202128"))
    draw_arc(Vector2(1380, floor_y - 18), 58.0, PI, TAU, 30, Color("#6d8790"), 3.0)
    draw_string(ThemeDB.fallback_font, Vector2(1300, floor_y - 195), "RAIN WITHOUT CLOUDS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#718790"))

func _draw_cathedral_landmarks() -> void:
    draw_rect(Rect2(880, floor_y - 330, 600, 330), Color("#302b38"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(830, floor_y - 330),
        Vector2(1180, floor_y - 555),
        Vector2(1530, floor_y - 330)
    ]), Color("#403546"))
    for x in [960, 1100, 1240, 1380]:
        draw_rect(Rect2(x, floor_y - 245, 42, 100), Color("#131119"))
        draw_colored_polygon(PackedVector2Array([
            Vector2(x - 10, floor_y - 245),
            Vector2(x + 21, floor_y - 285),
            Vector2(x + 52, floor_y - 245)
        ]), Color("#18141e"))
    draw_line(Vector2(875, floor_y - 325), Vector2(1485, floor_y - 325), Color("#766578"), 4.0)

func _draw_inner_city_landmarks() -> void:
    for x in range(260, int(map_width), 460):
        draw_rect(Rect2(x, floor_y - 205, 190, 205), Color("#302932"))
        draw_rect(Rect2(x + 70, floor_y - 125, 48, 125), Color("#151217"))
        draw_rect(Rect2(x + 18, floor_y - 160, 20, 25), Color("#17141b"))
        draw_rect(Rect2(x + 145, floor_y - 160, 20, 25), Color("#17141b"))
    draw_rect(Rect2(1670, floor_y - 280, 400, 280), Color("#3b3039"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(1620, floor_y - 280),
        Vector2(1870, floor_y - 420),
        Vector2(2120, floor_y - 280)
    ]), Color("#54414e"))
    draw_rect(Rect2(1825, floor_y - 175, 90, 175), Color("#141118"))

func _draw_mirror_street_landmarks() -> void:
    for x in range(160, int(map_width), 340):
        draw_rect(Rect2(x, floor_y - 150, 110, 150), Color("#263438"))
        draw_rect(Rect2(x + 37, floor_y - 92, 36, 92), Color("#0c1317"))
        draw_rect(Rect2(x - 18, floor_y + 42, 146, 24), Color("#28444a"))
        draw_line(Vector2(x - 18, floor_y + 42), Vector2(x + 128, floor_y + 42), Color("#6ca5ad"), 2.0)
    draw_string(ThemeDB.fallback_font, Vector2(680, floor_y - 220), "THE LAMPS ARE UNDER THE WATER", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#70979a"))


func _draw_battlefield_landmarks() -> void:
    for x in range(260, int(map_width), 390):
        draw_rect(Rect2(x, floor_y - 58, 180, 58), Color("#302528"))
        draw_line(Vector2(x, floor_y - 58), Vector2(x + 180, floor_y - 58), Color("#5a4443"), 3.0)
    draw_rect(Rect2(2020, floor_y - 230, 280, 230), Color("#30272b"))
    draw_rect(Rect2(2080, floor_y - 170, 52, 170), Color("#151318"))
    draw_rect(Rect2(2190, floor_y - 170, 52, 170), Color("#151318"))
    draw_line(Vector2(2030, floor_y - 235), Vector2(2300, floor_y - 235), Color("#6a5050"), 4.0)

func _draw_monastery_landmarks() -> void:
    draw_rect(Rect2(930, floor_y - 355, 270, 355), Color("#292833"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(900, floor_y - 355),
        Vector2(1065, floor_y - 505),
        Vector2(1230, floor_y - 355)
    ]), Color("#38323c"))
    draw_rect(Rect2(1080, floor_y - 310, 34, 52), Color("#111018"))
    draw_arc(Vector2(1097, floor_y - 287), 34.0, 0.0, TAU, 24, Color("#716975"), 2.0)
    draw_line(Vector2(1097, floor_y - 322), Vector2(1097, floor_y - 250), Color("#716975"), 2.0)
    draw_rect(Rect2(1760, floor_y - 165, 220, 165), Color("#25242e"))
    draw_rect(Rect2(1810, floor_y - 125, 42, 125), Color("#121118"))

func _draw_prison_landmarks() -> void:
    for x in range(330, int(map_width), 330):
        draw_rect(Rect2(x, floor_y - 200, 7, 200), Color("#4a464e"))
        draw_rect(Rect2(x + 66, floor_y - 200, 7, 200), Color("#4a464e"))
        draw_line(Vector2(x, floor_y - 155), Vector2(x + 73, floor_y - 155), Color("#4a464e"), 5.0)
        draw_line(Vector2(x, floor_y - 82), Vector2(x + 73, floor_y - 82), Color("#4a464e"), 5.0)
    draw_rect(Rect2(1660, floor_y - 265, 150, 265), Color("#29272f"))
    draw_rect(Rect2(1713, floor_y - 214, 44, 214), Color("#121117"))

func _draw_royal_tomb_landmarks() -> void:
    for x in [360, 760, 1160, 1560, 1960]:
        draw_rect(Rect2(x, floor_y - 82, 180, 54), Color("#373039"))
        draw_rect(Rect2(x + 14, floor_y - 94, 152, 14), Color("#5a4d55"))
        draw_line(Vector2(x + 26, floor_y - 68), Vector2(x + 154, floor_y - 68), Color("#78666d"), 2.0)
    draw_rect(Rect2(1660, floor_y - 244, 28, 170), Color("#51454d"))
    draw_rect(Rect2(1694, floor_y - 244, 28, 170), Color("#51454d"))
    draw_line(Vector2(1648, floor_y - 244), Vector2(1734, floor_y - 244), Color("#817079"), 5.0)
    draw_string(ThemeDB.fallback_font, Vector2(1500, floor_y - 270), "NAME REMOVED", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#8f8086"))


func _draw_well_landmarks() -> void:
    draw_rect(Rect2(460, 70, 170, floor_y - 70), Color("#1b1822"))
    draw_line(Vector2(460, 70), Vector2(460, floor_y), Color("#403844"), 18.0)
    draw_line(Vector2(630, 70), Vector2(630, floor_y), Color("#403844"), 18.0)
    draw_line(Vector2(460, 170), Vector2(630, 170), Color("#302932"), 12.0)
    draw_line(Vector2(460, 300), Vector2(630, 300), Color("#302932"), 12.0)
    draw_line(Vector2(460, 425), Vector2(630, 425), Color("#302932"), 12.0)
    draw_arc(Vector2(1100, floor_y - 20), 54.0, PI, TAU, 32, Color("#73656d"), 6.0)
    draw_rect(Rect2(1046, floor_y - 20, 108, 22), Color("#16131b"))

