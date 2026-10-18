extends CanvasLayer

const ITEM_CATALOG = preload("res://scripts/core/item_catalog.gd")

var background: ColorRect
var panel: ColorRect
var title_label: Label
var list_container: VBoxContainer
var detail_name: Label
var detail_category: Label
var detail_body: Label
var close_hint: Label
var _previous_input_locked := false
var _previous_paused := false
var _selected_item_id := ""

func _ready() -> void:
    layer = 24
    process_mode = Node.PROCESS_MODE_ALWAYS

    background = ColorRect.new()
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.color = Color("#07060b", 0.86)
    background.visible = false
    background.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(background)

    panel = ColorRect.new()
    panel.position = Vector2(120, 64)
    panel.size = Vector2(1040, 592)
    panel.color = Color("#111018", 0.98)
    background.add_child(panel)

    title_label = Label.new()
    title_label.position = Vector2(28, 20)
    title_label.size = Vector2(984, 38)
    title_label.text = "物品"
    title_label.add_theme_font_size_override("font_size", 28)
    title_label.add_theme_color_override("font_color", Color("#d6c7b2"))
    panel.add_child(title_label)

    var separator := ColorRect.new()
    separator.position = Vector2(28, 68)
    separator.size = Vector2(984, 2)
    separator.color = Color("#554650")
    panel.add_child(separator)

    var scroll := ScrollContainer.new()
    scroll.position = Vector2(28, 88)
    scroll.size = Vector2(350, 430)
    panel.add_child(scroll)

    list_container = VBoxContainer.new()
    list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list_container.add_theme_constant_override("separation", 8)
    scroll.add_child(list_container)

    detail_name = Label.new()
    detail_name.position = Vector2(410, 94)
    detail_name.size = Vector2(590, 38)
    detail_name.add_theme_font_size_override("font_size", 23)
    detail_name.add_theme_color_override("font_color", Color("#d6c7b2"))
    panel.add_child(detail_name)

    detail_category = Label.new()
    detail_category.position = Vector2(410, 136)
    detail_category.size = Vector2(590, 24)
    detail_category.add_theme_font_size_override("font_size", 14)
    detail_category.add_theme_color_override("font_color", Color("#9e8b72"))
    panel.add_child(detail_category)

    detail_body = Label.new()
    detail_body.position = Vector2(410, 176)
    detail_body.size = Vector2(590, 390)
    detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    detail_body.add_theme_font_size_override("font_size", 18)
    detail_body.add_theme_color_override("font_color", Color("#c0b6b2"))
    panel.add_child(detail_body)

    close_hint = Label.new()
    close_hint.position = Vector2(28, 548)
    close_hint.size = Vector2(984, 24)
    close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    close_hint.text = "I / Esc  关闭"
    close_hint.add_theme_font_size_override("font_size", 13)
    close_hint.add_theme_color_override("font_color", Color("#756d72"))
    panel.add_child(close_hint)

    visible = true
    background.visible = false

func open_inventory() -> void:
    _previous_input_locked = WorldState.input_locked
    _previous_paused = get_tree().paused
    WorldState.input_locked = true
    get_tree().paused = true
    background.visible = true
    _refresh_items()

func close_inventory() -> void:
    if not background.visible:
        return
    background.visible = false
    WorldState.input_locked = _previous_input_locked
    get_tree().paused = _previous_paused

func _refresh_items() -> void:
    for child in list_container.get_children():
        child.queue_free()

    var item_ids: Array = WorldState.inventory_items.keys()
    item_ids.sort()
    if item_ids.is_empty():
        detail_name.text = "尚无物品"
        detail_category.text = ""
        detail_body.text = "探索时留意桌面、架子、遗落的物件与尸体。\n\n收集到的物品会保留在这里，方便之后重新查看。"
        return

    for raw_id in item_ids:
        var item_id := str(raw_id)
        var definition: Dictionary = ITEM_CATALOG.get_definition(item_id)
        if definition.is_empty():
            continue
        var count := int(WorldState.inventory_items.get(item_id, 0))
        var button := Button.new()
        button.custom_minimum_size = Vector2(320, 46)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.text = "%s  ×%d" % [str(definition.get("display_name", item_id)), count]
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.pressed.connect(_select_item.bind(item_id))
        list_container.add_child(button)

    _select_item(str(item_ids[0]))

func _select_item(item_id: String) -> void:
    var definition: Dictionary = ITEM_CATALOG.get_definition(item_id)
    if definition.is_empty():
        return
    _selected_item_id = item_id
    detail_name.text = str(definition.get("display_name", item_id))
    detail_category.text = _category_label(str(definition.get("category", "")))
    detail_body.text = str(definition.get("description", ""))
    WorldState.mark_item_read(item_id)

func _category_label(category: String) -> String:
    match category:
        "consumable":
            return "消耗品"
        "key_item":
            return "关键道具"
        "lore":
            return "记载与线索"
        "badge":
            return "徽章"
        "crest":
            return "纹章"
        "equipment":
            return "装备"
        _:
            return "物品"

func _unhandled_input(event: InputEvent) -> void:
    if not background.visible:
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_I, KEY_ESCAPE, KEY_E]:
        close_inventory()
        get_viewport().set_input_as_handled()
