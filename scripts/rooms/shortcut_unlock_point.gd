extends Area2D
## A5 shortcut/elevator interaction zone. Enter, then press E to persistently open it.
signal player_nearby_changed(shortcut_id: String, nearby: bool)

@export var shortcut_id: String = ""
@export var prompt_text: String = "按 E 开启捷径"

func _ready() -> void:
	var prompt := $InteractionPrompt as Label
	prompt.text = prompt_text
	prompt.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_node("InteractionPrompt").visible = true
		player_nearby_changed.emit(shortcut_id, true)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_node("InteractionPrompt").visible = false
		player_nearby_changed.emit(shortcut_id, false)
