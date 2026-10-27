extends Control
## Dedicated macro-map acceptance launcher. Test state is session-only and never overwrites the normal save.
## 专用宏观地图验收入口。测试状态仅限当前会话，不覆盖正式存档。

const REGION_ENTRIES: Array[Dictionary] = [
    {"id":"A0", "name":"边境手术所 / Escape Prologue", "path":"res://scenes/escape_prologue.tscn", "spawn":"west"},
    {"id":"A1", "name":"边境村庄 / Village Hub", "path":"res://scenes/village_hub.tscn", "spawn":"west"},
    {"id":"ROOM_WORLD", "name":"完整世界地图施工版（A0-A13 + H01-H08 / 50 房间）", "path":"res://scenes/rooms/world_a0_r01.tscn", "spawn":"west"},
    {"id":"A2", "name":"雾林与旧朝圣路 / Ash Forest", "path":"res://scenes/ash_forest.tscn", "spawn":"west"},
    {"id":"A3", "name":"废弃城区 / Forgotten City", "path":"res://scenes/forgotten_city.tscn", "spawn":"west"},
    {"id":"A4", "name":"沉积大厅与水库 / Sewer Reservoir", "path":"res://scenes/sewer_reservoir.tscn", "spawn":"west"},
    {"id":"A5", "name":"旧战场 / A5 RoomContainer 验收", "path":"res://scenes/world/world.tscn", "spawn":"west"},
    {"id":"A6", "name":"修道院钟塔 / Monastery Tower", "path":"res://scenes/monastery_tower.tscn", "spawn":"west"},
    {"id":"A7", "name":"监牢深层 / Prison Depths", "path":"res://scenes/prison_depths.tscn", "spawn":"west"},
    {"id":"A8", "name":"王室墓穴 / Royal Tomb", "path":"res://scenes/royal_tomb.tscn", "spawn":"west"},
    {"id":"OB01", "name":"王墓内殿 Boss / Royal Tomb Guardian", "path":"res://scenes/royal_tomb_boss.tscn", "spawn":"west"},
    {"id":"A9", "name":"王室外环 / Royal Outer Ring", "path":"res://scenes/royal_outer_ring.tscn", "spawn":"west"},
    {"id":"A10", "name":"大圣堂 / Grand Cathedral", "path":"res://scenes/grand_cathedral.tscn", "spawn":"west"},
    {"id":"A11", "name":"古神研究深层 / Deep Research Depths", "path":"res://scenes/deep_research_depths.tscn", "spawn":"west"},
    {"id":"A12", "name":"王室内城 / Inner City", "path":"res://scenes/inner_city.tscn", "spawn":"west"},
    {"id":"A13", "name":"深层梦境与终局异象 / Terminal Anomaly", "path":"res://scenes/terminal_anomaly.tscn", "spawn":"west"},
    {"id":"H01", "name":"井底回声层 / Hidden Well", "path":"res://scenes/hidden_regions/hidden_well.tscn", "spawn":"west"},
    {"id":"H02", "name":"倒响钟室 / Hidden Bell Chamber", "path":"res://scenes/hidden_regions/hidden_bell_chamber.tscn", "spawn":"west"},
    {"id":"H03", "name":"被删去的第三街 / Erased Third Street", "path":"res://scenes/erased_third_street.tscn", "spawn":"west"},
    {"id":"H04", "name":"水面背后的楼梯 / Reflected Stairwell", "path":"res://scenes/reflected_stairwell.tscn", "spawn":"west"},
    {"id":"H05", "name":"无声钟室 / Silent Bell Room", "path":"res://scenes/silent_bell_room.tscn", "spawn":"west"},
    {"id":"H06", "name":"王名抹除廊 / Erased Royal Name", "path":"res://scenes/erased_royal_name_corridor.tscn", "spawn":"west"},
    {"id":"H07", "name":"镜街 / Mirror Street", "path":"res://scenes/mirror_street.tscn", "spawn":"west"},
    {"id":"H08", "name":"胎宫与原初空腔 / Primordial Hollow", "path":"res://scenes/hidden_regions/primordial_hollow.tscn", "spawn":"west"}
]

@onready var region_grid: GridContainer = $MarginContainer/Content/MapAndRegions/ScrollContainer/RegionGrid
@onready var reset_button: Button = $MarginContainer/Content/Footer/ResetButton
@onready var back_button: Button = $MarginContainer/Content/Footer/BackButton

func _ready() -> void:
    var button_count := region_grid.get_child_count()
    if button_count != REGION_ENTRIES.size():
        push_error("World map test menu button count mismatch: %d != %d" % [button_count, REGION_ENTRIES.size()])
    var count := mini(button_count, REGION_ENTRIES.size())
    for index in range(count):
        var button := region_grid.get_child(index) as Button
        if button == null:
            push_error("World map test menu child %d is not a Button" % index)
            continue
        button.pressed.connect(_enter_region.bind(REGION_ENTRIES[index]))
    reset_button.pressed.connect(_prepare_test_state)
    back_button.pressed.connect(_return_to_title)
    _prepare_test_state()

func _prepare_test_state() -> void:
    WorldState.debug_map_test_mode = true
    WorldState.physical_union_complete = true
    var flags: Array[String] = [
        "village_defense_survived",
        "opened_bell_tower_drop",
        "opened_mirror_street_side_gate",
        "opened_old_bell_tower_connection",
        "opened_old_service_door",
        "opened_royal_tomb_side_door",
        "opened_royal_transport_side_door",
        "reached_A4_via_A3",
        "reached_A10_via_A9",
        "reached_A12_via_A10",
        "defeated_mad_cleric"
    ]
    for flag in flags:
        if flag not in WorldState.achievement_flags:
            WorldState.achievement_flags.append(flag)
    for hidden_id in ["H01", "H02", "H03", "H04", "H05", "H06", "H07", "H08"]:
        if hidden_id not in WorldState.opened_hidden_paths:
            WorldState.opened_hidden_paths.append(hidden_id)
    if not WorldState.debug_natural_test_active:
        WorldState.begin_natural_test_session()
    print("[NEREIS][MAP][ACCEPTANCE] Test flags primed; normal save writes disabled.")

func _enter_region(entry: Dictionary) -> void:
    _prepare_test_state()
    WorldState.pending_region_spawn_side = str(entry.get("spawn", "west"))
    print("[NEREIS][MAP][ACCEPTANCE] Enter %s -> %s" % [entry.id, entry.path])
    get_tree().change_scene_to_file(str(entry.path))

func _return_to_title() -> void:
    WorldState.finish_natural_test_session()
    WorldState.debug_natural_test_active = false
    WorldState.debug_map_test_mode = false
    if FileAccess.file_exists("user://nereis_hero_save.json"):
        WorldState.load_game()
    else:
        WorldState.delete_save()
    get_tree().change_scene_to_file("res://scenes/boot.tscn")
