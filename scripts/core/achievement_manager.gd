extends Node

## Achievement notifications are a side channel: unlocking never waits for presentation.
## 成就是旁路消息：解锁只记录并入队，不等待任何 UI 或剧情流程。

signal achievement_unlocked(achievement_id: String, title: String, message: String)

const DEFINITIONS := {
	"prologue_knight_victory": {
		"title": "击败作者的拦路虎",
		"message": "你竟然打败了作者的拦路虎？"
	},
	"prologue_knight_defeat": {
		"title": "拼尽全力",
		"message": "拼尽全力，依然无法战胜么？"
	}
}
const TOAST_DURATION := 3.2

var pending_notifications: Array[Dictionary] = []
var toast_layer: CanvasLayer
var toast_panel: PanelContainer
var toast_title: Label
var toast_message: Label
var toast_remaining := 0.0
var toast_active := false

func unlock(achievement_id: String) -> bool:
	var normalized_id := achievement_id.strip_edges()
	if not DEFINITIONS.has(normalized_id):
		push_warning("[ACHIEVEMENT] Unknown achievement id: %s" % normalized_id)
		return false
	if not WorldState.record_achievement(normalized_id):
		return false

	var definition: Dictionary = DEFINITIONS[normalized_id]
	var notification := {
		"id": normalized_id,
		"title": str(definition.get("title", normalized_id)),
		"message": str(definition.get("message", ""))
	}
	pending_notifications.append(notification)
	achievement_unlocked.emit(normalized_id, notification.title, notification.message)
	print("[ACHIEVEMENT] Unlocked id=%s; queued notification count=%d" % [normalized_id, pending_notifications.size()])
	return true

func has_unlocked(achievement_id: String) -> bool:
	return achievement_id in WorldState.achievement_flags

func get_definitions() -> Dictionary:
	return DEFINITIONS.duplicate(true)

func _process(delta: float) -> void:
	if toast_active:
		toast_remaining -= delta
		if toast_remaining <= 0.0:
			_hide_toast()
	if not toast_active and not pending_notifications.is_empty():
		_show_next_notification()

func _show_next_notification() -> void:
	if pending_notifications.is_empty():
		return
	var notification: Dictionary = pending_notifications.pop_front()
	if not _ensure_toast():
		# Keep the notification queued if the UI cannot be created.
		pending_notifications.push_front(notification)
		return
	toast_title.text = "成就解锁 · " + str(notification.get("title", ""))
	toast_message.text = str(notification.get("message", ""))
	toast_layer.visible = true
	toast_panel.visible = true
	toast_remaining = TOAST_DURATION
	toast_active = true

func _ensure_toast() -> bool:
	if is_instance_valid(toast_layer):
		return true
	if get_tree() == null or get_tree().root == null:
		return false

	toast_layer = CanvasLayer.new()
	toast_layer.name = "AchievementNotifications"
	toast_layer.layer = 90
	toast_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(toast_layer)

	toast_panel = PanelContainer.new()
	toast_panel.name = "AchievementToast"
	toast_panel.position = Vector2(760.0, 32.0)
	toast_panel.custom_minimum_size = Vector2(460.0, 100.0)
	toast_panel.visible = false
	toast_layer.add_child(toast_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#17151c", 0.96)
	style.border_color = Color("#b7a477")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	toast_panel.add_theme_stylebox_override("panel", style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	toast_panel.add_child(column)

	toast_title = Label.new()
	toast_title.add_theme_font_size_override("font_size", 19)
	toast_title.add_theme_color_override("font_color", Color("#e7d5a4"))
	column.add_child(toast_title)

	toast_message = Label.new()
	toast_message.add_theme_font_size_override("font_size", 16)
	toast_message.add_theme_color_override("font_color", Color("#e3dce0"))
	toast_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(toast_message)
	return true

func _hide_toast() -> void:
	toast_active = false
	toast_remaining = 0.0
	if is_instance_valid(toast_panel):
		toast_panel.visible = false
