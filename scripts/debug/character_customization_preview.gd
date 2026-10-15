extends Node2D

@onready var character: CustomizableCharacter = $CustomizableCharacter
@onready var animation_player: AnimationPlayer = $CustomizableCharacter/AnimationPlayer
@onready var status_label: Label = $CustomizationUI/PanelContainer/VBoxContainer/StatusLabel


func _ready() -> void:
	# Child AnimationSetup runs before this scene root's _ready().
	if animation_player.has_animation("idle"):
		animation_player.play("idle")
	if status_label:
		status_label.text = "1 Idle · 2 Run · 3 Attack · 4 Dodge\nAssign CharacterPartData arrays to enable live changes."


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key_event := event as InputEventKey
	match key_event.keycode:
		KEY_1:
			_play_preview("idle")
		KEY_2:
			_play_preview("run")
		KEY_3:
			_play_preview("attack")
		KEY_4:
			_play_preview("dodge")


func _play_preview(animation_name: String) -> void:
	if animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
	if status_label:
		status_label.text = "Preview animation: %s\n1 Idle · 2 Run · 3 Attack · 4 Dodge" % animation_name
