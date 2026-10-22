extends Node
## 房间切片的持久状态。使用独立 user:// 文件，避免覆盖现有主线存档。

const ROOM_SAVE_PATH := "user://room_world_state.json"
var explored_room_ids: Array[String] = []
var opened_shortcut_ids: Array[String] = []
var collected_item_ids: Array[String] = []

func _ready() -> void:
	load_room_state()

func mark_room_explored(room_id: String) -> void:
	if room_id.is_empty() or explored_room_ids.has(room_id):
		return
	explored_room_ids.append(room_id)
	save_room_state()

func is_room_explored(room_id: String) -> bool:
	return explored_room_ids.has(room_id)

func open_shortcut(shortcut_id: String) -> void:
	if shortcut_id.is_empty() or opened_shortcut_ids.has(shortcut_id):
		return
	opened_shortcut_ids.append(shortcut_id)
	save_room_state()

func collect_room_item(item_id: String) -> void:
	if item_id.is_empty() or collected_item_ids.has(item_id):
		return
	collected_item_ids.append(item_id)
	save_room_state()

func save_room_state() -> void:
	var file := FileAccess.open(ROOM_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("无法写入房间探索存档")
		return
	file.store_string(JSON.stringify({
		"explored_room_ids": explored_room_ids,
		"opened_shortcut_ids": opened_shortcut_ids,
		"collected_item_ids": collected_item_ids
	}, "\t"))

func load_room_state() -> void:
	if not FileAccess.file_exists(ROOM_SAVE_PATH):
		return
	var file := FileAccess.open(ROOM_SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("房间探索存档格式无效")
		return
	var data: Dictionary = parsed
	explored_room_ids.clear()
	for value: Variant in data.get("explored_room_ids", []):
		explored_room_ids.append(str(value))
	opened_shortcut_ids.clear()
	for value: Variant in data.get("opened_shortcut_ids", []):
		opened_shortcut_ids.append(str(value))
	collected_item_ids.clear()
	for value: Variant in data.get("collected_item_ids", []):
		collected_item_ids.append(str(value))
