extends Control
## Dedicated macro-map acceptance launcher. Test state is session-only and never overwrites the normal save.
## 专用宏观地图验收入口。测试状态仅限当前会话，不覆盖正式存档。

const REGION_ENTRIES: Array[Dictionary] = [
    {"id":"A0", "name":"边境手术所 / Escape Prologue", "path":"res://scenes/escape_prologue.tscn", "spawn":"west"},
    {"id":"A1", "name":"边境村庄 / Village Hub", "path":"res://scenes/village_hub.tscn", "spawn":"west"},
    {"id":"A2", "name":"雾林与旧朝圣路 / Ash Forest", "path":"res://scenes/ash_forest.tscn", "spawn":"west"},
    {"id":"A3", "name":"废弃城区 / Forgotten City", "path":"res://scenes/forgotten_city.tscn", "spawn":"west"},
    {"id":"A4", "name":"沉积大厅与水库 / Sewer Reservoir", "path":"res://scenes/sewer_reservoir.tscn", "spawn":"west"},
    {"id":"A5", "name":"旧战场 / Old Battlefield", "path":"res://scenes/old_battlefield.tscn", "spawn":"west"},
    {"id":"A6", "name":"修道院钟塔 / Monastery Tower", "path":"res://scenes/monastery_tower.tscn", "spawn":"west"},
    {"id":"A7", "name":"监牢深层 / Prison Depths", "path":"res://scenes/prison_depths.tscn", "spawn":"west"},
    {"id":"A8", "name":"王室墓穴 / Royal Tomb", "path":"res://scenes/royal_tomb.tscn", "spawn":"west"},
    {"id":"OB01", "name":"王墓内殿 Boss / Royal Tomb Guardian", "path":"res://scenes/royal_tomb_boss.tscn", "spawn":"west"},
    {"id":"A9", "name":"王室外环 / Royal Outer Ring", "path":"res://scenes/royal_outer_ring.tscn", "spawn":"west"},
    {"id":"A10", "name":"大圣堂 / Grand Cathedral", "path":"res://scenes/grand_cathedral.tscn", "spawn":"west"},
    {"id":"A11", "name":"古神研究深层 / Deep Research Depths", "path":"res://scenes/deep_research_depths.tscn", "spawn":"west"},
    {"id":"A12", "name":"王室内城 / Inner City", "path":"res://scenes/inner_city.tscn", "spawn":"west"},
    {"id":"A13", "name":"深层梦境与终局异象 / Terminal Anomaly", "path":"res://scenes/terminal_anomaly.tscn", "spawn":"west"},
    {"id":"H01", "name":"井底回声层 / Hidden Well", "path":"res://scenes/hidden_well.tscn", "spawn":"west"},
    {"id":"H02", "name":"倒响钟室 / Hidden Bell Chamber", "path":"res://scenes/hidden_bell_chamber.tscn", "spawn":"west"},
    {"id":"H03", "name":"被删去的第三街 / Erased Third Street", "path":"res://scenes/erased_third_street.tscn", "spawn":"west"},
    {"id":"H04", "name":"水面背后的楼梯 / Reflected Stairwell", "path":"res://scenes/reflected_stairwell.tscn", "spawn":"west"},
    {"id":"H05", "name":"无声钟室 / Silent Bell Room", "path":"res://scenes/silent_bell_room.tscn", "spawn":"west"},
    {"id":"H06", "name":"王名抹除廊 / Erased Royal Name", "path":"res://scenes/erased_royal_name_corridor.tscn", "spawn":"west"},
    {"id":"H07", "name":"镜街 / Mirror Street", "path":"res://scenes/mirror_street.tscn", "spawn":"west"},
    {"id":"H08", "name":"胎宫与原初空腔 / Primordial Hollow", "path":"res://scenes/primordial_hollow.tscn", "spawn":"west"}
]

func _ready() -> void:
    _build_ui()

func _build_ui() -> void:
    var background := ColorRect.new()
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.color = Color("#0b090f")
    add_child(background)

    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 12)
    root.add_theme_constant_override("margin_left", 44)
    root.add_theme_constant_override("margin_right", 44)
    root.add_theme_constant_override("margin_top", 26)
    root.add_theme_constant_override("margin_bottom", 26)
    add_child(root)

    var title := Label.new()
    title.text = "宏观地图验收 / WORLD MAP ACCEPTANCE"
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", Color("#d6c7b2"))
    root.add_child(title)

    var description := Label.new()
    description.text = "选择任意区域直接进入。测试模式预置跨区与隐藏路线条件，不覆盖正式存档。\nSelect any region directly. Route gates are primed for traversal checks; your normal save is protected.\n操作：方向键/A-D 移动，Space 跳跃，E 交互，F6 返回本选择页。"
    description.custom_minimum_size.y = 58
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description.add_theme_color_override("font_color", Color("#9b9099"))
    root.add_child(description)

    # Show the original macro topology beside the region launch list so map acceptance starts from spatial context.
    # 在区域启动列表旁展示原创宏观拓扑图，让地图验收从空间关系出发。
    var map_and_regions := HBoxContainer.new()
    map_and_regions.size_flags_vertical = Control.SIZE_EXPAND_FILL
    map_and_regions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    map_and_regions.add_theme_constant_override("separation", 18)
    root.add_child(map_and_regions)

    var map_panel := PanelContainer.new()
    map_panel.custom_minimum_size = Vector2(470, 0)
    map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    map_and_regions.add_child(map_panel)

    var map_preview := TextureRect.new()
    map_preview.texture = load("res://assets/art/maps/nereis_world_topology.svg")
    map_preview.custom_minimum_size = Vector2(450, 330)
    map_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    map_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
    map_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    map_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    map_panel.add_child(map_preview)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    map_and_regions.add_child(scroll)

    var grid := GridContainer.new()
    grid.columns = 2
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 14)
    grid.add_theme_constant_override("v_separation", 8)
    scroll.add_child(grid)

    for entry in REGION_ENTRIES:
        var button := Button.new()
        button.text = "%s   %s" % [str(entry.id), str(entry.name)]
        button.custom_minimum_size = Vector2(520, 42)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.add_theme_font_size_override("font_size", 15)
        button.pressed.connect(_enter_region.bind(entry))
        grid.add_child(button)

    var footer := HBoxContainer.new()
    root.add_child(footer)

    var reset_button := Button.new()
    reset_button.text = "重新预置测试条件 / Reset Test Flags"
    reset_button.custom_minimum_size = Vector2(300, 40)
    reset_button.pressed.connect(_prepare_test_state)
    footer.add_child(reset_button)

    var back_button := Button.new()
    back_button.text = "返回标题菜单 / Main Menu"
    back_button.custom_minimum_size = Vector2(240, 40)
    back_button.pressed.connect(_return_to_title)
    footer.add_child(back_button)

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
