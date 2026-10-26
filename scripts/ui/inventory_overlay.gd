extends CanvasLayer

const ITEM_CATALOG = preload("res://scripts/core/item_catalog.gd")
const ITEM_BUTTON_SCENE: PackedScene = preload("res://scenes/ui/inventory_item_button.tscn")

@onready var background: ColorRect = $Background
@onready var panel: ColorRect = $Background/Panel
@onready var title_label: Label = $Background/Panel/TitleLabel
@onready var list_container: VBoxContainer = $Background/Panel/ItemScroll/ListContainer
@onready var detail_name: Label = $Background/Panel/DetailName
@onready var detail_body: Label = $Background/Panel/DetailBody
@onready var close_hint: Label = $Background/Panel/CloseHint
var _previous_input_locked := false
var _previous_paused := false
var _selected_item_id := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
        detail_body.text = "探索时留意桌面、架子、遗落的物件与尸体。\n\n收集到的物品会保留在这里，方便之后重新查看。"
        return

    for raw_id in item_ids:
        var item_id := str(raw_id)
        var definition: Dictionary = ITEM_CATALOG.get_definition(item_id)
        if definition.is_empty():
            continue
        var count := int(WorldState.inventory_items.get(item_id, 0))
        var button := ITEM_BUTTON_SCENE.instantiate() as Button
        button.text = "%s  ×%d" % [str(definition.get("display_name", item_id)), count]
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.pressed.connect(_select_item.bind(item_id))
        list_container.add_child(button)

    _selected_item_id = ""
    detail_name.text = "选择物品"
    detail_body.text = "从左侧选择一件物品，查看它留下的记录或痕迹。"

func _select_item(item_id: String) -> void:
    var definition: Dictionary = ITEM_CATALOG.get_definition(item_id)
    if definition.is_empty():
        return
    _selected_item_id = item_id
    detail_name.text = str(definition.get("display_name", item_id))
    detail_body.text = str(definition.get("description", ""))
    WorldState.mark_item_read(item_id)

func _unhandled_input(event: InputEvent) -> void:
    if not background.visible:
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_I, KEY_ESCAPE, KEY_E]:
        close_inventory()
        get_viewport().set_input_as_handled()
