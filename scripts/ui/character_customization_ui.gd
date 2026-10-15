extends CanvasLayer

@export var character_path: NodePath
@onready var hair_option: OptionButton = $PanelContainer/VBoxContainer/HairOption
@onready var clothes_option: OptionButton = $PanelContainer/VBoxContainer/ClothesOption
@onready var face_option: OptionButton = $PanelContainer/VBoxContainer/FaceOption
@onready var accessory_option: OptionButton = $PanelContainer/VBoxContainer/AccessoryOption
@onready var accessory_toggle: CheckButton = $PanelContainer/VBoxContainer/AccessoryToggle
@onready var status_label: Label = $PanelContainer/VBoxContainer/StatusLabel

var character: CustomizableCharacter


func _ready() -> void:
	character = get_node_or_null(character_path) as CustomizableCharacter
	if character == null:
		status_label.text = "Assign Character Path in Inspector."
		push_warning("Customization UI needs a valid CustomizableCharacter path.")
		return
	_populate(hair_option, character.hair_options)
	_populate(clothes_option, character.clothes_options)
	_populate(face_option, character.face_options)
	_populate(accessory_option, character.accessory_options)
	hair_option.item_selected.connect(func(index: int): character.change_hair(index))
	clothes_option.item_selected.connect(func(index: int): character.change_clothes(index))
	face_option.item_selected.connect(func(index: int): character.change_face(index))
	accessory_option.item_selected.connect(func(index: int): character.change_accessory(index))
	accessory_toggle.toggled.connect(character.set_accessory_visible)
	status_label.text = "Choose parts in Inspector after atlas regions are catalogued."


func _populate(button: OptionButton, options: Array[CharacterPartData]) -> void:
	button.clear()
	for index in range(options.size()):
		var part := options[index]
		button.add_item(part.display_name if not part.display_name.is_empty() else "Part %d" % (index + 1), index)
	button.disabled = options.is_empty()
