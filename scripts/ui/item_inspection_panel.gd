extends CanvasLayer

# Dedicated readable description panel for examined objects and collected lore items.
# This is not a narrator: the caller must provide text that belongs to the inspected object.

@onready var panel: ColorRect = $Panel
@onready var title_label: Label = $Panel/TitleLabel
@onready var body_label: Label = $Panel/BodyLabel
@onready var hint_label: Label = $Panel/HintLabel
var _was_paused := false
var _previous_input_locked := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("item_inspection_panels")
func show_pickup(item_name: String) -> void:
	if not is_instance_valid(panel):
		return
	NereisInteractionFocus.clear_all(get_tree())
	_previous_input_locked = WorldState.input_locked
	_was_paused = get_tree().paused
	title_label.text = "获得物品"
	body_label.text = NereisLocalization.translate_text(item_name)
	panel.visible = true
	WorldState.input_locked = true
	get_tree().paused = true

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
