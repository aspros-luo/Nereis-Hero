extends Node2D
## Shared playable graybox for the first connected world-map loop.
## 第一条互通地图环路的通用可玩灰盒场景。

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const INTERACTION_DOOR_SCRIPT = preload("res://scripts/world/interaction_door.gd")
const RESONANCE_SOURCE_SCRIPT = preload("res://scripts/world/resonance_source_clue.gd")
const RESONANCE_SECRET_GATE_SCRIPT = preload("res://scripts/world/resonance_secret_gate.gd")
const ENDGAME_GATE_SCRIPT = preload("res://scripts/core/endgame_gate.gd")

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
    # Save the target location and its incoming side before clearing the one-shot transition value.
    # 先保存目标地图与进入侧，再清理一次性切图方向。
    WorldState.set_location(location_id)
    WorldState.pending_region_spawn_side = "west"
    if region_id == "A4":
        # Reaching the reservoir records the C05 route and enables the return-side well entrance on later visits.
        # 抵达旧水库即记录 C05 路线；之后再次进入时，才会生成回程侧的水井入口。
        WorldState.record_achievement("reached_A4_via_A3")
    elif region_id == "A10":
        # Being inside the cathedral proves the main route has reached A10; this also repairs older saves.
        # 进入大圣堂本身即证明主线已抵达 A10，也可修复旧存档中的进程标记。
        WorldState.record_achievement("reached_A10_via_A9")
    elif region_id == "A12":
        # The inner city is only entered from the cathedral on the main route; persist this for H07's side gate.
        # 主线内城入口来自大圣堂；持久记录该事实，供 H07 的镜街侧门判断是否允许回程。
        WorldState.record_achievement("reached_A12_via_A10")

    _create_floor()
    _create_boundaries()
    _configure_platforms()
    _spawn_hero(_spawn_x_for_side(spawn_side))
    print("[NEREIS][MAP][SPAWN] region=%s location=%s side=%s x=%.1f resume_side=%s" % [region_id, location_id, spawn_side, hero.position.x, WorldState.resume_spawn_side])
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
    if region_id == "A3" and side == "village_city_cut":
        # Enter from the village drainage passage, away from the return door and city anomaly.
        # 从村庄排水通路进入，避开回村门与城区异常调查点。
        return 760.0
    if region_id == "A11" and side == "chapel_entry":
        # C19 enters from the cathedral-facing side, but must not overlap A11's return door at the east boundary.
        # C19 从大圣堂侧进入 A11，但出生点不能与 A11 东侧边界的返回门重叠。
        return map_width - 700.0
    # Far-side entrances place the Hero near, but not inside, the return door.
    # 从远侧捷径进入隐藏地图时，主角会落在出口附近，但不会与门的碰撞区重叠。
    if region_id == "H02" and side == "bell_tower_entry":
        return map_width - 360.0
    if region_id == "H03" and side == "third_street_entry":
        return map_width - 360.0
    if region_id == "H04" and side == "royal_tomb_side_entry":
        return map_width - 360.0
    if region_id == "H05" and side == "bell_drop_entry":
        return map_width - 360.0
    if region_id == "H06" and side == "royal_transport_entry":
        return map_width - 360.0
    if region_id == "A2" and side == "old_pilgrim_highroad":
        # C04 returns to the eastern half of the pilgrim road, clear of the bell gate.
        # C04 回到朝圣古道东段，并避开钟室入口。
        return map_width - 650.0
    if region_id == "A5" and side == "old_pilgrim_highroad":
        # C04 arrives near the city-facing end of the battlefield shortcut.
        # C04 从捷径抵达战场时，出生在靠近旧城的一侧。
        return 850.0
    if region_id == "A2" and side == "bell_gate":
        # Leave the H02 entrance's interaction radius after returning from the hidden chamber.
        # 从倒响钟室返回时，出生点应离入口足够远，避免一落地就抢占 E 交互。
        return map_width - 450.0
    if region_id == "A3" and side == "third_street_gate":
        # The gate is at map_width - 300; keep the return spawn outside its 80px focus radius.
        # 第三街入口位于 map_width - 300；返回出生点必须离开其 80px 交互半径。
        return map_width - 500.0
    if region_id == "A3" and side == "bell_drop":
        # The return door is at x=1830; do not spawn inside its Area2D body-entered region.
        # 钟塔落差门位于 x=1830；从隐藏区回来不能直接出生在门的触发区域内。
        return 1600.0
    if region_id == "A4" and side == "water_reflection_gate":
        # Move away from H04, whose entrance is at x=1780.
        # 旧水库侧的 H04 入口位于 x=1780，返回点与其保持明显距离。
        return 1550.0
    if region_id == "A4" and side == "east":
        # H01's A4-side well gate sits near the east boundary; avoid spawning inside its 80px interaction radius.
        # A4 东侧井门靠近地图边界；返回时避开其 80px 交互范围，防止落地就重新聚焦。
        return map_width - 360.0
    if region_id == "A4" and side == "prison_tunnel":
        return 520.0
    if region_id == "A4" and side == "royal_tomb_waterway":
        return 760.0
    if region_id == "A4" and side == "royal_drain":
        return 760.0
    if region_id == "A9" and side == "old_lift":
        return 1450.0
    if region_id == "A9" and side == "inner_city_side_gate":
        return 1650.0
    if region_id == "A5" and side == "bell_tower":
        # The far-side door is at x=2060; keep the arrival point clear of its trigger.
        # 钟塔远侧门位于 x=2060，抵达战场时避免立即触发返回门。
        return map_width - 800.0
    if region_id == "A6" and side == "silent_window":
        # H05 sits at x=1660. Keep this arrival away from its interaction radius.
        # H05 入口位于 x=1660，返回修道院后不应立即重新聚焦该入口。
        return 1400.0
    if region_id == "A8" and side == "royal_name_gate":
        # H06 sits at x=1870; place returnees clear of the secret entrance.
        # H06 入口位于 x=1870，从王名抹除廊返回时应远离入口。
        return 1350.0
    if region_id == "A8" and side == "royal_tomb_side":
        # The side door is at x=930; avoid spawning inside the same door on return.
        # 王墓侧门位于 x=930；从倒影阶梯返回时应离开门的触发范围。
        return 1200.0
    if region_id == "A9" and side == "third_street_service":
        # The service door is at x=1020; return to a neutral part of the street.
        # 旧服务门位于 x=1020；回到王城外环后落在街道中段。
        return 1250.0
    if region_id == "A9" and side == "royal_transport":
        # Keep distance from both the royal transport door (x=2200) and H07 (x=1850).
        # 远离王室运输门（x=2200）与 H07 镜街入口（x=1850）。
        return map_width - 650.0
    if region_id == "A3" and side == "sewer":
        return 1380.0
    if region_id == "H01" and side == "east":
        # Return from A4 to the hidden well without immediately overlapping its east exit.
        # 从 A4 回到隐藏水井时，不能直接出生在东侧出口触发区内。
        return map_width - 360.0
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
        "H02":
            return "LISTEN FOR THE BELL THAT ARRIVES BEFORE ITS SOUND."
        "H03":
            return "FOLLOW THE STREET THAT THE CITY ERASED."
        "H04":
            return "FOLLOW THE DRY STAIRS INSIDE THE WATER."
        "H05":
            return "CLIMB THE WINDOW THAT CASTS NO SHADOW."
        "H06":
            return "READ THE NAME SCRAPED FROM THE ROYAL STONE."

        "A9":
            return "CROSS THE OUTER RING. FOLLOW THE RAIN REFLECTIONS."
        "A10":
            return "CLIMB THE PILGRIM STEPS. FIND THE CHURCH INNER COURT."
        "A11":
            return "FOLLOW THE OBSERVATION PATH. THE WALLS REMEMBER EACH VISITOR."
        "H08":
            return "FOLLOW THE WALL THAT BREATHES WITHOUT WAKING IT."

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
        "A11":
            narrative.show_message(
                "THE DEPTHS THAT PRECEDED THE LAB",
                "The Church built its rooms around something already here.\n\nThe observation notes disagree about who entered first.",
                5.0
            )
        "H08":
            narrative.show_message(
                "THE WOMB BELOW THE LAB",
                "The wall is warm. No device is active.\n\nSomething in the stone exhales just before you do.",
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
        "H02":
            narrative.show_message(
                "THE BELL BEFORE THE SOUND",
                "The bell's tongue remains still.\n\nThe echo answers from a place you have not reached.",
                5.0
            )
        "H03":
            narrative.show_message(
                "THE STREET THE CITY REMOVED",
                "The houses have doors on both sides.\n\nOnly one side appears on the city plan.",
                5.0
            )
        "H04":
            narrative.show_message(
                "THE STAIRS BEHIND THE WATER",
                "The reflection has dry steps.\n\nYour boots leave no mark on the water above them.",
                5.0
            )
        "H05":
            narrative.show_message(
                "THE WINDOW THAT CASTS NO SHADOW",
                "The bell tower window has no view beyond it.\n\nSomeone has been using it from the inside.",
                5.0
            )
        "H06":
            narrative.show_message(
                "THE NAME SCRAPED FROM STONE",
                "The inscription is not weathered.\n\nThe chisel marks begin after the tomb was sealed.",
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
            # The ground route stays readable; the canopy route is a faster, riskier line across the forest.
            # 地面主路保持清晰；树冠路线提供更快但更有风险的横穿方式。
            _add_platform(Rect2(430, 485, 105, 20))
            _add_platform(Rect2(535, 450, 110, 20))
            _add_platform(Rect2(645, 415, 130, 20))
            _add_platform(Rect2(930, 475, 180, 18))
            _add_platform(Rect2(1200, 435, 150, 18))
            _add_platform(Rect2(1500, 480, 160, 18))
            _add_platform(Rect2(1840, 445, 130, 18))
            _add_platform(Rect2(760, 370, 110, 18))
            _add_platform(Rect2(870, 330, 110, 18))
            _add_platform(Rect2(1000, 360, 110, 18))
            _add_platform(Rect2(1120, 405, 110, 18))
            _add_platform(Rect2(1260, 390, 110, 18))
            _add_platform(Rect2(1380, 345, 110, 18))
            _add_platform(Rect2(1500, 310, 110, 18))
            _add_platform(Rect2(1620, 350, 110, 18))
            _add_platform(Rect2(1740, 400, 110, 18))
        "A3":
            # Street-level route: rubble, market, sewer descent, and the battlefield road.
            # 地面主路连接碎墙、市场、下水道入口与战场方向。
            _add_platform(Rect2(300, 470, 170, 18))
            _add_platform(Rect2(600, 430, 110, 18))
            _add_platform(Rect2(850, 390, 180, 18))
            _add_platform(Rect2(1190, 465, 200, 18))
            _add_platform(Rect2(1540, 425, 150, 18))
            _add_platform(Rect2(1880, 470, 170, 18))
            _add_platform(Rect2(2180, 410, 140, 18))
            # Optional rooftop loop rises above the erased third street, then descends to the sewer-side route.
            # 可选屋顶环路爬过被抹除的第三街，再下降接回下水道一侧的主路。
            _add_platform(Rect2(450, 400, 110, 18))
            _add_platform(Rect2(565, 355, 120, 18))
            _add_platform(Rect2(700, 310, 120, 18))
            _add_platform(Rect2(850, 300, 120, 18))
            _add_platform(Rect2(1000, 340, 120, 18))
            _add_platform(Rect2(1130, 390, 120, 18))
            _add_platform(Rect2(1320, 425, 130, 18))
        "A4":
            # The floor remains the safe route; a raised pipe walk is an optional way through the old stonework.
            # 地面保持安全主路；抬高的管线栈道提供穿越古老石殿的可选路线。
            _add_platform(Rect2(360, 475, 140, 18))
            _add_platform(Rect2(640, 435, 120, 18))
            _add_platform(Rect2(940, 395, 180, 18))
            _add_platform(Rect2(1260, 455, 190, 18))
            _add_platform(Rect2(1600, 420, 150, 18))
            _add_platform(Rect2(1980, 470, 170, 18))
            _add_platform(Rect2(470, 400, 115, 18))
            _add_platform(Rect2(600, 355, 120, 18))
            _add_platform(Rect2(760, 315, 130, 18))
            _add_platform(Rect2(930, 330, 125, 18))
            _add_platform(Rect2(1090, 375, 125, 18))
            _add_platform(Rect2(1320, 400, 120, 18))
            _add_platform(Rect2(1480, 355, 120, 18))
            _add_platform(Rect2(1650, 310, 130, 18))
            _add_platform(Rect2(1810, 355, 125, 18))
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
        "A11":
            _add_platform(Rect2(280, 480, 165, 18))
            _add_platform(Rect2(565, 438, 140, 18))
            _add_platform(Rect2(850, 390, 175, 18))
            _add_platform(Rect2(1150, 440, 155, 18))
            _add_platform(Rect2(1465, 385, 180, 18))
            _add_platform(Rect2(1780, 430, 150, 18))
            _add_platform(Rect2(2080, 475, 175, 18))
        "H08":
            _add_platform(Rect2(250, 470, 150, 18))
            _add_platform(Rect2(505, 425, 135, 18))
            _add_platform(Rect2(755, 380, 160, 18))
            _add_platform(Rect2(1030, 430, 145, 18))
            _add_platform(Rect2(1290, 385, 165, 18))
            _add_platform(Rect2(1560, 440, 145, 18))
        "H02":
            _add_platform(Rect2(260, 475, 145, 18))
            _add_platform(Rect2(515, 430, 135, 18))
            _add_platform(Rect2(790, 385, 160, 18))
            _add_platform(Rect2(1070, 435, 145, 18))
            _add_platform(Rect2(1340, 390, 155, 18))
        "H03":
            _add_platform(Rect2(250, 475, 150, 18))
            _add_platform(Rect2(515, 430, 140, 18))
            _add_platform(Rect2(780, 385, 175, 18))
            _add_platform(Rect2(1080, 445, 155, 18))
            _add_platform(Rect2(1420, 400, 170, 18))
            _add_platform(Rect2(1760, 455, 160, 18))
        "H04":
            _add_platform(Rect2(250, 475, 160, 18))
            _add_platform(Rect2(530, 425, 140, 18))
            _add_platform(Rect2(810, 380, 165, 18))
            _add_platform(Rect2(1100, 435, 150, 18))
            _add_platform(Rect2(1390, 390, 170, 18))
        "H05":
            _add_platform(Rect2(280, 480, 155, 18))
            _add_platform(Rect2(560, 430, 135, 18))
            _add_platform(Rect2(840, 385, 150, 18))
            _add_platform(Rect2(1120, 340, 140, 18))
            _add_platform(Rect2(1400, 395, 155, 18))
            _add_platform(Rect2(1700, 450, 160, 18))
        "H06":
            _add_platform(Rect2(260, 480, 160, 18))
            _add_platform(Rect2(540, 440, 140, 18))
            _add_platform(Rect2(820, 395, 165, 18))
            _add_platform(Rect2(1110, 445, 155, 18))
            _add_platform(Rect2(1420, 395, 165, 18))
            _add_platform(Rect2(1730, 450, 160, 18))

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
                Vector2(1530, floor_y - 18.0),
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
        "A11":
            _spawn_source(
                Vector2(1450, floor_y - 18.0),
                "anomaly_observer_reaction",
                "THE SECOND OBSERVER",
                "The record names an observer who never entered the chamber.\n\nA second line has been added in a different hand. It describes you leaving.",
                78,
                0,
                6,
                "",
                2
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
            _spawn_h02_gate(map_width - 300.0)
            # C04 is opened from A5; once opened, keep the reverse entrance persistent on A2.
            # C04 在 A5 侧开启；开启后，A2 侧永久生成对应回程门。
            if "reached_A5_and_opened_old_pilgrim_highroad" in WorldState.achievement_flags:
                _spawn_exit_door(
                    1880.0, "E  RETURN TO THE BATTLEFIELD", "old_battlefield",
                    "res://scenes/old_battlefield.tscn", "old_pilgrim_highroad"
                )
        "A3":
            # The city can also return directly to the village through the drainage passage.
            # 城区可经排水通路直接返回村庄，形成第二条回环。
            _spawn_exit_door(
                520.0, "E  RETURN THROUGH THE OLD DRAIN", "village",
                "res://scenes/village_hub.tscn", "city_cut_return"
            )
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
            if "reached_A9_via_A8_then_opened_old_lift_from_A9" in WorldState.achievement_flags:
                _spawn_exit_door(
                    1150.0, "E  RETURN TO THE ROYAL OUTER RING", "royal_outer_ring",
                    "res://scenes/royal_outer_ring.tscn", "old_lift"
                )
            _spawn_h03_gate(map_width - 300.0)
            if WorldState.is_hidden_path_opened("H05") and "opened_bell_tower_drop" in WorldState.achievement_flags:
                _spawn_exit_door(
                    1830.0, "E  RETURN TO THE SILENT BELL WINDOW", "silent_bell_room",
                    "res://scenes/silent_bell_room.tscn", "bell_drop_entry"
                )
            # C10 reverse door: only exists after the bell-tower drop has been opened from A6.
            # C10 反向门：必须先从 A6 开启钟塔落差，A3 才生成回程捷径。
            if "opened_bell_tower_drop" in WorldState.achievement_flags:
                _spawn_exit_door(
                    1710.0, "E  RETURN TO THE MONASTERY DROP", "monastery_tower",
                    "res://scenes/monastery_tower.tscn", "bell_drop"
                )
            # C10's destination is the monastery tower, so the return spawn must use the drop-side mapping.
            # C10 的回程目的地是修道院塔，因此出生点必须使用钟塔落差侧的映射。
        "A4":
            _spawn_exit_door(
                72.0, "E  OPEN THE INSPECTION HATCH", "forgotten_city",
                "res://scenes/forgotten_city.tscn", "sewer",
                true, "opened_sewer_inspection_hatch_from_A4", "E  RETURN TO THE CITY"
            )
            # C06 is a one-way return shortcut from the reservoir to the village well.
            # C06 是从旧水库返回村庄的单向捷径；首次互动开闸，再次互动才转场。
            _spawn_exit_door(
                map_width - 250.0, "E  OPEN THE VILLAGE WELL WATERGATE", "village",
                "res://scenes/village_hub.tscn", "well_exit",
                true, "opened_watergate_and_village_well_exit", "E  RETURN TO THE VILLAGE"
            )
            _spawn_h04_gate(1780.0)
            if "reached_A7_then_opened_supply_tunnel" in WorldState.achievement_flags:
                _spawn_exit_door(
                    1050.0, "E  RETURN TO THE PRISON", "prison_depths",
                    "res://scenes/prison_depths.tscn", "east"
                )
            if "reached_A8_via_A7_then_opened_royal_tomb_gate" in WorldState.achievement_flags:
                _spawn_exit_door(
                    1250.0, "E  RETURN TO THE ROYAL TOMB", "royal_tomb",
                    "res://scenes/royal_tomb.tscn", "royal_tomb_waterway"
                )
            if "reached_A9_then_opened_royal_drain_from_outer_ring" in WorldState.achievement_flags:
                _spawn_exit_door(
                    1450.0, "E  RETURN TO THE ROYAL OUTER RING", "royal_outer_ring",
                    "res://scenes/royal_outer_ring.tscn", "royal_drain"
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
            if WorldState.is_hidden_path_opened("H02"):
                _spawn_exit_door(
                    2060.0, "E  OPEN THE OLD BELL TOWER CONNECTION", "hidden_bell_chamber",
                    "res://scenes/hidden_bell_chamber.tscn", "bell_tower_entry",
                    true, "opened_old_bell_tower_connection", "E  ENTER THE BELL CHAMBER"
                )
            # C04: open the old pilgrim highroad from the battlefield side, then traverse on the next interaction.
            # C04：从战场侧开启旧朝圣高路；首次互动开路，下一次互动才转场。
            _spawn_exit_door(
                520.0, "E  OPEN THE OLD PILGRIM HIGHROAD", "ash_forest",
                "res://scenes/ash_forest.tscn", "old_pilgrim_highroad",
                true, "reached_A5_and_opened_old_pilgrim_highroad", "E  RETURN BY THE OLD PILGRIM HIGHROAD"
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
            _spawn_h05_gate(1660.0)
            if WorldState.is_hidden_path_opened("H05"):
                _spawn_exit_door(
                    2110.0, "E  OPEN THE BELL TOWER DROP", "forgotten_city",
                    "res://scenes/forgotten_city.tscn", "bell_drop",
                    true, "opened_bell_tower_drop", "E  RETURN TO THE FORGOTTEN CITY"
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
            # C12: unlock the supply tunnel from the prison side; the first E opens it, the second traverses.
            # C12：从监牢侧开启补给隧道；第一次 E 开门，第二次 E 才转场。
            _spawn_exit_door(
                520.0, "E  OPEN THE SUPPLY TUNNEL", "sewer_reservoir",
                "res://scenes/sewer_reservoir.tscn", "prison_tunnel",
                true, "reached_A7_then_opened_supply_tunnel", "E  RETURN THROUGH THE SUPPLY TUNNEL"
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
            # C07: the royal-tomb shortcut back to the reservoir is unlocked from A8.
            # C07：旧王墓返回旧水库的捷径只能在 A8 侧开启。
            _spawn_exit_door(
                520.0, "E  OPEN THE ROYAL TOMB WATERWAY", "sewer_reservoir",
                "res://scenes/sewer_reservoir.tscn", "royal_tomb_waterway",
                true, "reached_A8_via_A7_then_opened_royal_tomb_gate", "E  RETURN THROUGH THE ROYAL WATERWAY"
            )
            _spawn_h06_gate(1870.0)
            if WorldState.is_hidden_path_opened("H04"):
                _spawn_exit_door(
                    930.0, "E  OPEN THE ROYAL TOMB SIDE DOOR", "reflected_stairwell",
                    "res://scenes/reflected_stairwell.tscn", "royal_tomb_side_entry",
                    true, "opened_royal_tomb_side_door", "E  ENTER THE REFLECTION STAIRS"
                )
            _spawn_a11_maintenance_gate(2310.0)

        "A9":
            _spawn_exit_door(
                72.0, "E  RETURN TO THE ROYAL TOMB", "royal_tomb",
                "res://scenes/royal_tomb.tscn", "east"
            )
            _spawn_exit_door(
                map_width - 72.0, "E  CLIMB TO THE GREAT CATHEDRAL", "grand_cathedral",
                "res://scenes/grand_cathedral.tscn", "west"
            )
            if WorldState.is_hidden_path_opened("H03"):
                _spawn_exit_door(
                    1020.0, "E  OPEN THE OLD SERVICE DOOR", "erased_third_street",
                    "res://scenes/erased_third_street.tscn", "third_street_entry",
                    true, "opened_old_service_door", "E  ENTER THE THIRD STREET"
                )
            if WorldState.is_hidden_path_opened("H06"):
                _spawn_exit_door(
                    2200.0, "E  OPEN THE ROYAL TRANSPORT SIDE DOOR", "erased_royal_name_corridor",
                    "res://scenes/erased_royal_name_corridor.tscn", "royal_transport_entry",
                    true, "opened_royal_transport_side_door", "E  ENTER THE ROYAL NAME CORRIDOR"
                )
            _spawn_a9_mirror_gate(1850.0)
            if "reached_A12_via_A10_then_opened_inner_city_side_gate" in WorldState.achievement_flags:
                _spawn_exit_door(
                    900.0, "E  RETURN TO THE INNER CITY", "inner_city",
                    "res://scenes/inner_city.tscn", "inner_city_side_gate"
                )
            # C16: reconnect A9 to A3 after the old lift is opened from the outer ring.
            # C16：从王城外环开启旧升降机后，重新连通 A9 与 A3。
            _spawn_exit_door(
                520.0, "E  OPEN THE OLD LIFT", "forgotten_city",
                "res://scenes/forgotten_city.tscn", "old_lift",
                true, "reached_A9_via_A8_then_opened_old_lift_from_A9", "E  RETURN BY THE OLD LIFT"
            )
            # C23: the royal drain is a separate A9-to-A4 shortcut.
            # C23：王城排水道是另一条 A9 至 A4 的独立捷径。
            _spawn_exit_door(
                720.0, "E  OPEN THE ROYAL DRAIN", "sewer_reservoir",
                "res://scenes/sewer_reservoir.tscn", "royal_drain",
                true, "reached_A9_then_opened_royal_drain_from_outer_ring", "E  RETURN THROUGH THE ROYAL DRAIN"
            )
        "A10":
            _spawn_exit_door(
                72.0, "E  RETURN TO THE OUTER RING", "royal_outer_ring",
                "res://scenes/royal_outer_ring.tscn", "east"
            )
            _spawn_exit_door(
                map_width - 72.0, "E  ENTER THE INNER CITY", "inner_city",
                "res://scenes/inner_city.tscn", "west"
            )
            _spawn_a11_chapel_gate(1900.0)
        "A12":
            _spawn_exit_door(
                72.0, "E  RETURN TO THE CATHEDRAL", "grand_cathedral",
                "res://scenes/grand_cathedral.tscn", "east"
            )
            # C18: the inner-city side gate can only be opened after reaching A12 by the main route.
            # C18：必须先沿主线抵达 A12，才能从内城侧开启通往 A9 的侧门。
            _spawn_exit_door(
                520.0, "E  OPEN THE INNER-CITY SIDE GATE", "royal_outer_ring",
                "res://scenes/royal_outer_ring.tscn", "inner_city_side_gate",
                true, "reached_A12_via_A10_then_opened_inner_city_side_gate", "E  RETURN THROUGH THE SIDE GATE"
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

            # The throne route chooses the ending from persistent story facts rather than requiring a secret map.
            # 王座区的最终路线依据持久剧情事实选择结局，不要求玩家先发现隐藏地图。
            var ending_gate := ENDGAME_GATE_SCRIPT.new()
            var ending_scene_path := str(ending_gate.call("route_candidate"))
            var ending_location := "church_final_demo"
            if ending_scene_path.ends_with("ending_paradise_demo.tscn"):
                ending_location = "ending_paradise_demo"
            elif ending_scene_path.ends_with("ending_fire_demo.tscn"):
                ending_location = "ending_fire_demo"
            _spawn_exit_door(
                map_width - 72.0, "E  ENTER THE THRONE CHAMBER", ending_location,
                ending_scene_path, "west"
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

        "H02":
            _spawn_exit_door(
                72.0, "E  RETURN TO THE PILGRIM ROAD", "ash_forest",
                "res://scenes/ash_forest.tscn", "bell_gate"
            )
            _spawn_exit_door(
                map_width - 105.0, "E  RETURN THROUGH THE BELL TOWER",
                "old_battlefield", "res://scenes/old_battlefield.tscn", "bell_tower",
                "opened_old_bell_tower_connection" in WorldState.achievement_flags
            )

        "H03":
            _spawn_exit_door(
                72.0, "E  RETURN TO THE FORGOTTEN CITY", "forgotten_city",
                "res://scenes/forgotten_city.tscn", "third_street_gate"
            )
            _spawn_exit_door(
                map_width - 105.0, "E  RETURN THROUGH THE OLD SERVICE DOOR",
                "royal_outer_ring", "res://scenes/royal_outer_ring.tscn", "third_street_service",
                "opened_old_service_door" in WorldState.achievement_flags
            )

        "H04":
            _spawn_exit_door(
                72.0, "E  RETURN TO THE RESERVOIR", "sewer_reservoir",
                "res://scenes/sewer_reservoir.tscn", "water_reflection_gate"
            )
            _spawn_exit_door(
                map_width - 105.0, "E  RETURN THROUGH THE ROYAL TOMB DOOR",
                "royal_tomb", "res://scenes/royal_tomb.tscn", "royal_tomb_side",
                "opened_royal_tomb_side_door" in WorldState.achievement_flags
            )

        "H05":
            _spawn_exit_door(
                72.0, "E  RETURN TO THE MONASTERY", "monastery_tower",
                "res://scenes/monastery_tower.tscn", "silent_window"
            )
            _spawn_exit_door(
                map_width - 105.0, "E  RETURN THROUGH THE BELL TOWER DROP",
                "forgotten_city", "res://scenes/forgotten_city.tscn", "bell_drop",
                "opened_bell_tower_drop" in WorldState.achievement_flags
            )

        "H06":
            _spawn_exit_door(
                72.0, "E  RETURN TO THE ROYAL TOMB", "royal_tomb",
                "res://scenes/royal_tomb.tscn", "royal_name_gate"
            )
            _spawn_exit_door(
                map_width - 105.0, "E  RETURN THROUGH THE ROYAL TRANSPORT DOOR",
                "royal_outer_ring", "res://scenes/royal_outer_ring.tscn", "royal_transport",
                "opened_royal_transport_side_door" in WorldState.achievement_flags
            )

        "A11":
            var can_return_to_tomb := WorldState.is_hidden_path_opened("C15")
            var can_return_to_cathedral := "reached_A10_via_A9" in WorldState.achievement_flags
            _spawn_exit_door(
                72.0, "E  RETURN THROUGH THE ROYAL SHAFT", "royal_tomb",
                "res://scenes/royal_tomb.tscn", "east", can_return_to_tomb
            )
            _spawn_exit_door(
                map_width - 72.0, "E  RETURN TO THE GREAT CATHEDRAL", "grand_cathedral",
                "res://scenes/grand_cathedral.tscn", "east", can_return_to_cathedral
            )
            _spawn_h08_gate(map_width - 300.0)

        "H08":
            _spawn_exit_door(
                72.0, "E  RETURN TO THE DEPTHS", "deep_research_depths",
                "res://scenes/deep_research_depths.tscn", "east"
            )
            if WorldState.physical_union_complete:
                var ending_gate := ENDGAME_GATE_SCRIPT.new()
                var ending_scene_path := str(ending_gate.call("route_candidate"))
                var ending_location := "ending_paradise_demo" if ending_scene_path.ends_with("ending_paradise_demo.tscn") else "ending_fire_demo"
                _spawn_exit_door(
                    map_width - 72.0, "E  FOLLOW THE LAST DREAM", ending_location,
                    ending_scene_path, "west"
                )


func _spawn_a11_maintenance_gate(x: float) -> void:
    # The royal shaft requires proof that the Hero investigated the erased royal name.
    # 王室竖井要求主角已调查被抹去的王室姓名。
    var gate := Node2D.new()
    gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
    gate.name = "RoyalTombDeepResearchGate"
    gate.position = Vector2(x, floor_y)
    gate.secret_id = "C15"
    gate.region_record_id = "A11"
    gate.target_scene_path = "res://scenes/deep_research_depths.tscn"
    gate.target_location_id = "deep_research_depths"
    gate.target_spawn_side = "west"
    gate.required_resonance = 55
    gate.required_ancient_exposure = 2
    gate.required_source_ids = ["anomaly_bell_retiming", "anomaly_erased_royal_name"]
    gate.opened.connect(_on_a11_gate_opened)
    add_child(gate)

func _spawn_a11_chapel_gate(x: float) -> void:
    # The cathedral approach is an alternate entrance; it still requires the Mite-related outer-god fact.
    # 大圣堂是另一条入口，但仍然要求蜜忒相关的外神共鸣事实。
    var gate := Node2D.new()
    gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
    gate.name = "SilentChapelDeepResearchGate"
    gate.position = Vector2(x, floor_y)
    gate.secret_id = "C19"
    gate.region_record_id = "A11"
    gate.target_scene_path = "res://scenes/deep_research_depths.tscn"
    gate.target_location_id = "deep_research_depths"
    gate.target_spawn_side = "chapel_entry"
    gate.required_resonance = 68
    gate.required_outer_exposure = 12
    gate.require_outer_god_resonance = true
    gate.required_source_ids = ["anomaly_mirror_street_echo"]
    gate.opened.connect(_on_a11_gate_opened)
    add_child(gate)

func _on_a11_gate_opened(secret_id: String) -> void:
    if not is_instance_valid(narrative):
        return
    var title := "THE SHAFT BEHIND THE KING'S NAME" if secret_id == "C15" else "THE SILENT CHAPEL"
    narrative.show_message(
        title,
        "The stone opens inward.\n\nThe records say the Church excavated this depth. The dust has settled on the Church's tools, not the stone.",
        5.0
    )

func _spawn_h08_gate(x: float) -> void:
    var gate := Node2D.new()
    gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
    gate.name = "PrimordialHollowGate"
    gate.position = Vector2(x, floor_y)
    gate.secret_id = "H08"
    gate.target_scene_path = "res://scenes/primordial_hollow.tscn"
    gate.target_location_id = "primordial_hollow"
    gate.target_spawn_side = "west"
    gate.required_resonance = 78
    gate.required_ancient_exposure = 2
    gate.required_outer_exposure = 18
    gate.require_outer_god_resonance = true
    gate.required_source_ids = [
        "anomaly_bell_retiming",
        "anomaly_erased_street_sign",
        "anomaly_old_stone_layer"
    ]
    gate.opened.connect(_on_h08_gate_opened)
    add_child(gate)

func _on_h08_gate_opened(_secret_id: String) -> void:
    if not is_instance_valid(narrative):
        return
    narrative.show_message(
        "THE WALL THAT BREATHES",
        "The wall exhales.\n\nYou cannot tell whether the passage was built for you, or whether it noticed you first.",
        5.0
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


func _spawn_h02_gate(x: float) -> void:
    var gate := Node2D.new()
    gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
    gate.name = "HiddenBellChamberGate"
    gate.position = Vector2(x, floor_y)
    gate.secret_id = "H02"
    gate.target_scene_path = "res://scenes/hidden_bell_chamber.tscn"
    gate.target_location_id = "hidden_bell_chamber"
    gate.target_spawn_side = "west"
    gate.required_resonance = 18
    gate.opened.connect(_on_optional_hidden_gate_opened)
    add_child(gate)

func _spawn_h03_gate(x: float) -> void:
    var gate := Node2D.new()
    gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
    gate.name = "ErasedThirdStreetGate"
    gate.position = Vector2(x, floor_y)
    gate.secret_id = "H03"
    gate.target_scene_path = "res://scenes/erased_third_street.tscn"
    gate.target_location_id = "erased_third_street"
    gate.target_spawn_side = "west"
    gate.required_resonance = 28
    gate.opened.connect(_on_optional_hidden_gate_opened)
    add_child(gate)

func _spawn_h04_gate(x: float) -> void:
    var gate := Node2D.new()
    gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
    gate.name = "ReflectedStairwellGate"
    gate.position = Vector2(x, floor_y)
    gate.secret_id = "H04"
    gate.target_scene_path = "res://scenes/reflected_stairwell.tscn"
    gate.target_location_id = "reflected_stairwell"
    gate.target_spawn_side = "west"
    gate.required_resonance = 36
    gate.required_ancient_exposure = 1
    gate.opened.connect(_on_optional_hidden_gate_opened)
    add_child(gate)

func _spawn_h05_gate(x: float) -> void:
    var gate := Node2D.new()
    gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
    gate.name = "SilentBellRoomGate"
    gate.position = Vector2(x, floor_y)
    gate.secret_id = "H05"
    gate.target_scene_path = "res://scenes/silent_bell_room.tscn"
    gate.target_location_id = "silent_bell_room"
    gate.target_spawn_side = "west"
    gate.required_resonance = 42
    gate.required_ancient_exposure = 1
    gate.opened.connect(_on_optional_hidden_gate_opened)
    add_child(gate)

func _spawn_h06_gate(x: float) -> void:
    var gate := Node2D.new()
    gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
    gate.name = "ErasedRoyalNameGate"
    gate.position = Vector2(x, floor_y)
    gate.secret_id = "H06"
    gate.target_scene_path = "res://scenes/erased_royal_name_corridor.tscn"
    gate.target_location_id = "erased_royal_name_corridor"
    gate.target_spawn_side = "west"
    gate.required_resonance = 55
    gate.required_ancient_exposure = 2
    gate.required_source_ids = ["anomaly_bell_retiming", "anomaly_erased_street_sign"]
    gate.opened.connect(_on_optional_hidden_gate_opened)
    add_child(gate)

func _on_optional_hidden_gate_opened(secret_id: String) -> void:
    if not is_instance_valid(narrative):
        return
    var details := {
        "H02": ["THE BELL BEFORE THE SOUND", "The bell's tongue remains still.\n\nThe echo answers from a place you have not reached."],
        "H03": ["THE STREET THE CITY REMOVED", "The houses have doors on both sides.\n\nOnly one side appears on the city plan."],
        "H04": ["THE STAIRS BEHIND THE WATER", "The reflection has dry steps.\n\nYour boots leave no mark on the water above them."],
        "H05": ["THE WINDOW THAT CASTS NO SHADOW", "The bell tower window has no view beyond it.\n\nSomeone has been using it from the inside."],
        "H06": ["THE NAME SCRAPED FROM STONE", "The inscription is not weathered.\n\nThe chisel marks begin after the tomb was sealed."]
    }
    var entry: Array = details.get(secret_id, ["THE ABNORMAL STONEWORK", "The wall opens without moving."])
    narrative.show_message(str(entry[0]), str(entry[1]), 5.0)

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

    # Re-entry through a far-side shortcut must update the same persistent region record.
    # 从远侧捷径再次进入时，仍需更新同一个隐藏区域的持久记录。
    match target_location:
        "hidden_bell_chamber":
            WorldState.discover_hidden_region("H02")
            WorldState.mark_hidden_region_entered("H02")
        "erased_third_street":
            WorldState.discover_hidden_region("H03")
            WorldState.mark_hidden_region_entered("H03")
        "reflected_stairwell":
            WorldState.discover_hidden_region("H04")
            WorldState.mark_hidden_region_entered("H04")
        "silent_bell_room":
            WorldState.discover_hidden_region("H05")
            WorldState.mark_hidden_region_entered("H05")
        "erased_royal_name_corridor":
            WorldState.discover_hidden_region("H06")
            WorldState.mark_hidden_region_entered("H06")

    WorldState.pending_region_spawn_side = spawn_side
    WorldState.set_location(target_location)
    print("[NEREIS][MAP][EXIT] from=%s to=%s location=%s spawn_side=%s" % [region_id, target_scene, target_location, spawn_side])
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
        "A11":
            _draw_deep_research_landmarks()

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
        "H02":
            _draw_hidden_bell_chamber_landmarks()
        "H03":
            _draw_erased_third_street_landmarks()
        "H04":
            _draw_reflected_stairwell_landmarks()
        "H05":
            _draw_silent_bell_room_landmarks()
        "H06":
            _draw_erased_royal_name_landmarks()
        "H08":
            _draw_primordial_hollow_landmarks()

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
        "H02":
            return Color("#171822")
        "H03":
            return Color("#1b171f")
        "H04":
            return Color("#111a20")
        "H05":
            return Color("#191722")
        "H06":
            return Color("#1a151c")
        "A11":
            return Color("#16151e")
        "H08":
            return Color("#0e1419")
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
        "H02":
            return Color("#3b3541")
        "H03":
            return Color("#39303a")
        "H04":
            return Color("#303c43")
        "H05":
            return Color("#403943")
        "H06":
            return Color("#403039")
        "A11":
            return Color("#393744")
        "H08":
            return Color("#2c3c40")
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
    # Canopy silhouettes guide the optional upper traversal without hiding the bell landmark.
    # 树冠剪影提示上层可选路线，同时保留钟墓地标的可见性。
    draw_line(Vector2(755, 360), Vector2(875, 320), Color("#514957"), 3.0)
    draw_line(Vector2(875, 320), Vector2(1005, 350), Color("#514957"), 3.0)
    draw_line(Vector2(1005, 350), Vector2(1125, 395), Color("#514957"), 3.0)
    draw_line(Vector2(1125, 395), Vector2(1265, 380), Color("#514957"), 3.0)
    draw_line(Vector2(1265, 380), Vector2(1385, 335), Color("#514957"), 3.0)
    draw_line(Vector2(1385, 335), Vector2(1505, 300), Color("#514957"), 3.0)
    draw_line(Vector2(1505, 300), Vector2(1625, 340), Color("#514957"), 3.0)
    draw_line(Vector2(1625, 340), Vector2(1745, 390), Color("#514957"), 3.0)
    draw_line(Vector2(1745, 390), Vector2(1845, 435), Color("#514957"), 3.0)

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
    # The third-street sign and the false wall are the city's primary spatial landmark.
    # 第三街路牌与假墙是城区最重要的空间地标。
    draw_rect(Rect2(842, 340, 146, 28), Color("#4a3c43"))
    draw_string(ThemeDB.fallback_font, Vector2(855, 360), "III STREET", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#98867e"))
    draw_line(Vector2(905, 365), Vector2(905, 418), Color("#98867e"), 2.0)
    draw_rect(Rect2(1000, floor_y - 235, 105, 235), Color("#211e27"))
    draw_rect(Rect2(1016, floor_y - 205, 22, 46), Color("#131117"))
    draw_rect(Rect2(1066, floor_y - 205, 22, 46), Color("#131117"))
    draw_line(Vector2(990, floor_y - 240), Vector2(1115, floor_y - 240), Color("#66535e"), 4.0)
    draw_string(ThemeDB.fallback_font, Vector2(990, floor_y - 255), "WALL / NO STREET", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("#8b737b"))
    # Roof silhouettes mark the optional upper route; the platforms above them are physically traversable.
    # 屋顶剪影提示上层支路；其上的平台具有真实碰撞，可供玩家跳跃穿行。
    draw_line(Vector2(440, 390), Vector2(570, 345), Color("#5b4b57"), 3.0)
    draw_line(Vector2(570, 345), Vector2(710, 300), Color("#5b4b57"), 3.0)
    draw_line(Vector2(710, 300), Vector2(870, 290), Color("#5b4b57"), 3.0)
    draw_line(Vector2(870, 290), Vector2(1020, 330), Color("#5b4b57"), 3.0)

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


func _draw_hidden_bell_chamber_landmarks() -> void:
    draw_arc(Vector2(560, floor_y - 75), 88.0, PI, TAU, 32, Color("#49404b"), 8.0)
    draw_rect(Rect2(520, floor_y - 95, 80, 65), Color("#292430"))
    draw_line(Vector2(560, floor_y - 180), Vector2(560, floor_y - 92), Color("#817081"), 3.0)
    draw_line(Vector2(530, floor_y - 70), Vector2(590, floor_y - 70), Color("#6f5969"), 3.0)
    draw_string(ThemeDB.fallback_font, Vector2(900, floor_y - 190), "THE TONGUE DOES NOT MOVE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#817081"))

func _draw_erased_third_street_landmarks() -> void:
    for x in range(180, int(map_width), 360):
        draw_rect(Rect2(x, floor_y - 205, 160, 205), Color("#28242e"))
        draw_rect(Rect2(x + 52, floor_y - 112, 42, 112), Color("#111018"))
        draw_rect(Rect2(x + 17, floor_y - 164, 20, 28), Color("#17141d"))
        draw_rect(Rect2(x + 123, floor_y - 164, 20, 28), Color("#17141d"))
        draw_line(Vector2(x + 8, floor_y - 210), Vector2(x + 151, floor_y - 210), Color("#50424f"), 2.0)
    draw_string(ThemeDB.fallback_font, Vector2(760, floor_y - 250), "NO STREET NUMBER THREE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#8a727f"))

func _draw_reflected_stairwell_landmarks() -> void:
    draw_rect(Rect2(0, floor_y + 48, map_width, 36), Color("#15252d"))
    draw_line(Vector2(0, floor_y + 48), Vector2(map_width, floor_y + 48), Color("#50727b"), 3.0)
    for i in range(6):
        var step_x := 250.0 + float(i) * 230.0
        var step_y := floor_y - 48.0 - float(i) * 32.0
        draw_rect(Rect2(step_x, step_y, 150.0, 10.0), Color("#596e78"))
        draw_line(Vector2(step_x, step_y), Vector2(step_x + 150.0, step_y), Color("#8fa8ac"), 2.0)
    draw_string(ThemeDB.fallback_font, Vector2(700, floor_y - 260), "DRY STAIRS IN A WET ROOM", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#77959d"))

func _draw_silent_bell_room_landmarks() -> void:
    draw_rect(Rect2(900, floor_y - 390, 300, 390), Color("#292632"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(865, floor_y - 390), Vector2(1050, floor_y - 545),
        Vector2(1235, floor_y - 390)
    ]), Color("#38303f"))
    draw_arc(Vector2(1050, floor_y - 290), 56.0, PI, TAU, 30, Color("#74677d"), 3.0)
    draw_line(Vector2(1050, floor_y - 346), Vector2(1050, floor_y - 230), Color("#74677d"), 2.0)
    draw_rect(Rect2(1017, floor_y - 270, 66, 82), Color("#16131d"))
    draw_string(ThemeDB.fallback_font, Vector2(1320, floor_y - 250), "NO SHADOW", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#8a7b94"))

func _draw_erased_royal_name_landmarks() -> void:
    for x in [320.0, 760.0, 1200.0, 1640.0]:
        draw_rect(Rect2(x, floor_y - 82, 190, 54), Color("#393039"))
        draw_rect(Rect2(x + 14, floor_y - 94, 162, 14), Color("#5b4953"))
        draw_line(Vector2(x + 26, floor_y - 68), Vector2(x + 152, floor_y - 68), Color("#78636e"), 2.0)
        draw_line(Vector2(x + 74, floor_y - 62), Vector2(x + 112, floor_y - 74), Color("#8b7480"), 2.0)
    draw_string(ThemeDB.fallback_font, Vector2(720, floor_y - 190), "A NAME SCRAPED AWAY", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#9b808d"))

func _draw_deep_research_landmarks() -> void:
    # The laboratory is built around an older, warmer stone structure.
    draw_rect(Rect2(160, 280, 420, 240), Color("#211f2a"))
    draw_rect(Rect2(188, 308, 364, 212), Color("#292631"))
    draw_line(Vector2(188, 308), Vector2(552, 520), Color("#4d4954"), 3.0)
    draw_line(Vector2(552, 308), Vector2(188, 520), Color("#4d4954"), 3.0)
    draw_rect(Rect2(830, 250, 300, 270), Color("#242530"))
    draw_arc(Vector2(980, 382), 94.0, PI, TAU, 28, Color("#6d5c6a"), 3.0)
    draw_line(Vector2(980, 288), Vector2(980, 485), Color("#6d5c6a"), 2.0)
    draw_string(
        ThemeDB.fallback_font,
        Vector2(1220, 310),
        NereisLocalization.translate_text("OBSERVATION CHAMBER"),
        HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("#827887")
    )
    draw_rect(Rect2(2050, 250, 270, 270), Color("#211f28"))
    draw_line(Vector2(2070, 310), Vector2(2302, 290), Color("#4e495a"), 3.0)
    draw_line(Vector2(2060, 398), Vector2(2310, 420), Color("#4e495a"), 3.0)
    draw_arc(Vector2(2185, 388), 90.0, PI * 0.92, TAU * 0.86, 34, Color("#5c5367"), 2.0)

func _draw_primordial_hollow_landmarks() -> void:
    # This room is grown from the research wall, rather than constructed as a machine hall.
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(120, 540), Vector2(240, 405), Vector2(375, 380),
            Vector2(490, 440), Vector2(630, 360), Vector2(780, 405),
            Vector2(900, 330), Vector2(1035, 400), Vector2(1170, 365),
            Vector2(1340, 430), Vector2(1510, 382), Vector2(1700, 450),
            Vector2(1800, 540)
        ]),
        Color("#1d2b31")
    )
    draw_polyline(
        PackedVector2Array([
            Vector2(210, 492), Vector2(325, 432), Vector2(430, 464),
            Vector2(565, 414), Vector2(705, 455), Vector2(850, 392),
            Vector2(1000, 451), Vector2(1135, 414), Vector2(1270, 462),
            Vector2(1420, 420), Vector2(1570, 470), Vector2(1710, 440)
        ]),
        Color("#668b8b"), 2.0, true
    )
    for i in range(7):
        var x := 300.0 + float(i) * 210.0
        draw_line(Vector2(x, 445), Vector2(x + 18.0, 470), Color("#43595f"), 2.0)
        draw_line(Vector2(x + 18.0, 470), Vector2(x + 4.0, 495), Color("#43595f"), 2.0)
    draw_string(
        ThemeDB.fallback_font,
        Vector2(510, 265),
        NereisLocalization.translate_text("THE STONE BREATHES"),
        HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color("#8db8b4")
    )

func _draw_well_landmarks() -> void:
    draw_rect(Rect2(460, 70, 170, floor_y - 70), Color("#1b1822"))
    draw_line(Vector2(460, 70), Vector2(460, floor_y), Color("#403844"), 18.0)
    draw_line(Vector2(630, 70), Vector2(630, floor_y), Color("#403844"), 18.0)
    draw_line(Vector2(460, 170), Vector2(630, 170), Color("#302932"), 12.0)
    draw_line(Vector2(460, 300), Vector2(630, 300), Color("#302932"), 12.0)
    draw_line(Vector2(460, 425), Vector2(630, 425), Color("#302932"), 12.0)
    draw_arc(Vector2(1100, floor_y - 20), 54.0, PI, TAU, 32, Color("#73656d"), 6.0)
    draw_rect(Rect2(1046, floor_y - 20, 108, 22), Color("#16131b"))

