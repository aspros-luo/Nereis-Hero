extends CanvasLayer

# Dedicated readable description panel for examined objects and collected lore items.
# This is not a narrator: the caller must provide text that belongs to the inspected object.

var panel: ColorRect
var title_label: Label
var body_label: Label
var hint_label: Label
var _was_paused := false
var _previous_input_locked := false

func _ready() -> void:
    layer = 22
    process_mode = Node.PROCESS_MODE_ALWAYS
    add_to_group("item_inspection_panels")

    panel = ColorRect.new()
    panel.position = Vector2(170, 468)
    panel.size = Vector2(940, 190)
    panel.color = Color("#0a090d", 0.96)
    panel.visible = false
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(panel)

    title_label = Label.new()
    title_label.position = Vector2(28, 18)
    title_label.size = Vector2(884, 32)
    title_label.add_theme_font_size_override("font_size", 22)
    title_label.add_theme_color_override("font_color", Color("#d6c7b2"))
    panel.add_child(title_label)

    body_label = Label.new()
    body_label.position = Vector2(28, 58)
    body_label.size = Vector2(884, 92)
    body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body_label.add_theme_font_size_override("font_size", 18)
    body_label.add_theme_color_override("font_color", Color("#c0b6b2"))
    panel.add_child(body_label)

    hint_label = Label.new()
    hint_label.position = Vector2(28, 158)
    hint_label.size = Vector2(884, 20)
    hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    hint_label.add_theme_font_size_override("font_size", 12)
    hint_label.add_theme_color_override("font_color", Color("#756d72"))
    hint_label.text = "E / Esc  关闭"
    panel.add_child(hint_label)

func show_description(item_name: String, description: String) -> void:
    if not is_instance_valid(panel):
        return
    NereisInteractionFocus.clear_all(get_tree())
    _previous_input_locked = WorldState.input_locked
    _was_paused = get_tree().paused
    title_label.text = NereisLocalization.translate_text(item_name)
    body_label.text = NereisLocalization.translate_text(description)
    panel.visible = true
    WorldState.input_locked = true
    get_tree().paused = true

func _unhandled_input(event: InputEvent) -> void:
    if not panel.visible:
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_E, KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
        close_description()
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
        close_description()
        get_viewport().set_input_as_handled()

func close_description() -> void:
    if not is_instance_valid(panel) or not panel.visible:
        return
    panel.visible = false
    WorldState.input_locked = _previous_input_locked
    get_tree().paused = _was_paused
