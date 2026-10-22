extends Node2D
## 常驻世界：玩家、相机与 HUD 持续存在；每次只实例化一个 A5 房间。
## A5 房间清单与连接唯一读取 tools/a5_room_assembly_contract.json。

const HERO_SCRIPT: Script = preload("res://scripts/player/hero.gd")
const HUD_SCRIPT: Script = preload("res://scripts/ui/game_hud.gd")
const A5_CONTRACT_PATH := "res://tools/a5_room_assembly_contract.json"

@onready var room_container: Node2D = $RoomContainer
@onready var fade_rect: ColorRect = $FadeLayer/ColorRect
@onready var transition_manager: RoomTransitionManager = $TransitionManager

var player: CharacterBody2D
var camera: Camera2D
var hud: CanvasLayer
var current_room: Node2D
var room_data_by_id: Dictionary = {}
var room_contract_by_id: Dictionary = {}
var connections_by_room: Dictionary = {}
var threaded_scene_paths: Dictionary = {}
var current_room_id: String = ""
var room_transition_nodes: Array[TransitionPoint] = []

func _ready() -> void:
	WorldState.load_room_state()
	if not _load_a5_contract():
		return
	_create_persistent_player()
	_create_persistent_hud()
	fade_rect.modulate.a = 1.0
	await _load_room("A5-R01", &"west", false)
	await _fade_to(0.0)

func _load_a5_contract() -> bool:
	if not FileAccess.file_exists(A5_CONTRACT_PATH):
		push_error("World: 缺少 A5 房间合同: " + A5_CONTRACT_PATH)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(A5_CONTRACT_PATH))
	if not parsed is Dictionary:
		push_error("World: A5 房间合同 JSON 无效")
		return false
	var rooms: Variant = parsed.get("rooms", [])
	var connections: Variant = parsed.get("connections", [])
	if not rooms is Array or not connections is Array:
		push_error("World: A5 房间合同缺少 rooms/connections 数组")
		return false
	room_data_by_id.clear()
	room_contract_by_id.clear()
	connections_by_room.clear()
	for raw: Variant in rooms:
		if not raw is Dictionary:
			continue
		var rid := str(raw.get("id", ""))
		var scene_path := str(raw.get("scene_path", ""))
		if rid.is_empty() or scene_path.is_empty() or not ResourceLoader.exists(scene_path):
			push_error("World: A5 房间 ID 或场景路径无效: " + rid + " / " + scene_path)
			return false
		if room_data_by_id.has(rid):
			push_error("World: A5 房间 ID 重复: " + rid)
			return false
		var data := RoomData.new()
		data.room_id = StringName(rid)
		data.area_id = &"A5"
		data.scene_path = scene_path
		data.entry_ids = PackedStringArray(["west", "east", "north", "south"])
		data.adjacent_room_ids = []
		room_data_by_id[rid] = data
		room_contract_by_id[rid] = raw
		connections_by_room[rid] = []
	for edge: Variant in connections:
		if not edge is Dictionary:
			continue
		var src := str(edge.get("from", ""))
		var dst := str(edge.get("to", ""))
		if not room_data_by_id.has(src) or not room_data_by_id.has(dst):
			push_error("World: 连接引用未知房间: " + str(edge.get("id", "?")))
			return false
		connections_by_room[src].append(edge)
		if edge.get("travel", "both") != "one_way":
			var reverse := edge.duplicate(true)
			reverse["from"] = dst
			reverse["to"] = src
			reverse["reverse_generated"] = true
			connections_by_room[dst].append(reverse)
		var source_data: RoomData = room_data_by_id[src]
		var target_data: RoomData = room_data_by_id[dst]
		if not source_data.adjacent_room_ids.has(StringName(dst)):
			source_data.adjacent_room_ids.append(StringName(dst))
		if edge.get("travel", "both") != "one_way" and not target_data.adjacent_room_ids.has(StringName(src)):
			target_data.adjacent_room_ids.append(StringName(src))
	return room_data_by_id.has("A5-R01") and room_data_by_id.has("A5-R20")

func _create_persistent_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Player"
	player.set_script(HERO_SCRIPT)
	player.add_to_group("player")
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var capsule := CapsuleShape2D.new()
	capsule.radius = 18.0
	capsule.height = 48.0
	collision.shape = capsule
	player.add_child(collision)
	add_child(player)
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)

func _create_persistent_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(HUD_SCRIPT)
	add_child(hud)
	hud.bind_hero(player)

func _load_room(room_id: String, entry_id: StringName, use_fade: bool = true) -> void:
	var data: RoomData = room_data_by_id.get(room_id) as RoomData
	if data == null:
		push_error("World: 未注册的房间 ID: " + room_id)
		return
	if use_fade:
		await _fade_to(1.0)
	var packed: PackedScene = await _get_room_scene(data.scene_path)
	if packed == null:
		push_error("World: 无法加载房间场景: " + data.scene_path)
		if use_fade:
			await _fade_to(0.0)
		return
	if is_instance_valid(current_room):
		current_room.queue_free()
		await get_tree().process_frame
	var instance := packed.instantiate() as Node2D
	if instance == null:
		push_error("World: 房间根节点必须是 Node2D: " + data.scene_path)
		return
	# Legacy A5 room scripts use this mode to build only the room geometry; the persistent World owns gameplay actors.
	if _has_property(instance, "assembly_child_mode"):
		instance.set("assembly_child_mode", true)
	room_container.add_child(instance)
	current_room = instance
	current_room_id = room_id
	if _has_property(instance, "room_id"):
		instance.set("room_id", room_id)
	if _has_property(instance, "region_id"):
		instance.set("region_id", "A5")
	var bounds := _get_room_bounds(instance)
	var entry_position := _entry_position(instance, entry_id, bounds)
	player.global_position = instance.to_global(entry_position)
	_apply_camera_bounds(bounds, instance.global_transform)
	_build_room_transitions(instance, room_id, bounds)
	WorldState.mark_room_explored(room_id)
	_preload_adjacent_rooms(data)
	if use_fade:
		await _fade_to(0.0)
	print("[NEREIS][ROOM_STREAM][LOAD] room=%s entry=%s bounds=%s" % [room_id, String(entry_id), str(bounds)])

func _has_property(node: Object, property_name: String) -> bool:
	for property: Dictionary in node.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false

func _get_room_bounds(room: Node2D) -> Rect2:
	var width := float(room.get("map_width")) if _has_property(room, "map_width") else 1280.0
	var height := float(room.get("room_height")) if _has_property(room, "room_height") else 720.0
	return Rect2(0.0, 0.0, maxf(width, 640.0), maxf(height, 480.0))

func _entry_position(room: Node2D, entry_id: StringName, bounds: Rect2) -> Vector2:
	var floor_y := float(room.get("floor_y")) if _has_property(room, "floor_y") else bounds.end.y - 100.0
	match entry_id:
		&"east":
			return Vector2(bounds.end.x - 100.0, floor_y - 72.0)
		&"north":
			return Vector2(bounds.size.x * 0.5, 90.0)
		&"south":
			return Vector2(bounds.size.x * 0.5, bounds.end.y - 120.0)
		_:
			return Vector2(100.0, floor_y - 72.0)

func _edge_entry_id(edge: Dictionary, room_id: String) -> StringName:
	var other_id := str(edge.get("to", ""))
	var here: Dictionary = room_contract_by_id.get(room_id, {})
	var other: Dictionary = room_contract_by_id.get(other_id, {})
	var here_pos: Array = here.get("position_screens", [0, 0])
	var other_pos: Array = other.get("position_screens", [0, 0])
	var dx := int(other_pos[0]) - int(here_pos[0])
	var dy := int(other_pos[1]) - int(here_pos[1])
	if absi(dx) >= absi(dy):
		return &"east" if dx >= 0 else &"west"
	return &"south" if dy >= 0 else &"north"

func _target_entry_id(edge: Dictionary, room_id: String) -> StringName:
	var here: Dictionary = room_contract_by_id.get(room_id, {})
	var other: Dictionary = room_contract_by_id.get(str(edge.get("to", "")), {})
	var here_pos: Array = here.get("position_screens", [0, 0])
	var other_pos: Array = other.get("position_screens", [0, 0])
	var dx := int(other_pos[0]) - int(here_pos[0])
	var dy := int(other_pos[1]) - int(here_pos[1])
	if absi(dx) >= absi(dy):
		return &"west" if dx >= 0 else &"east"
	return &"north" if dy >= 0 else &"south"

func _build_room_transitions(room: Node2D, room_id: String, bounds: Rect2) -> void:
	for point in room_transition_nodes:
		if is_instance_valid(point):
			point.queue_free()
	room_transition_nodes.clear()
	for edge: Variant in connections_by_room.get(room_id, []):
		if not edge is Dictionary:
			continue
		var edge_id := str(edge.get("id", ""))
		var edge_state := str(edge.get("initial_state", "open"))
		# Keep locked shortcuts, hidden paths and ability gates physically unavailable until their state is implemented.
		if edge_state != "open":
			continue
		var point := TransitionPoint.new()
		point.name = "Transition_" + edge_id
		point.connection_id = StringName(edge_id)
		point.target_room_id = StringName(edge.get("to", ""))
		point.target_entry_id = _target_entry_id(edge, room_id)
		var side := _edge_entry_id(edge, room_id)
		point.position = _transition_position(side, bounds, room)
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(48.0, 112.0) if side == &"west" or side == &"east" else Vector2(112.0, 48.0)
		shape.shape = rectangle
		point.add_child(shape)
		room.add_child(point)
		point.transition_requested.connect(_on_transition_requested)
		room_transition_nodes.append(point)

func _transition_position(side: StringName, bounds: Rect2, room: Node2D) -> Vector2:
	var floor_y := float(room.get("floor_y")) if _has_property(room, "floor_y") else bounds.end.y - 100.0
	match side:
		&"east":
			return Vector2(bounds.end.x - 24.0, floor_y - 56.0)
		&"west":
			return Vector2(24.0, floor_y - 56.0)
		&"north":
			return Vector2(bounds.size.x * 0.5, 24.0)
		_:
			return Vector2(bounds.size.x * 0.5, bounds.end.y - 24.0)

func _on_transition_requested(target_room_id: StringName, target_entry_id: StringName) -> void:
	if not transition_manager.begin_transition():
		return
	await _load_room(String(target_room_id), target_entry_id)
	transition_manager.end_transition()

func _apply_camera_bounds(local_bounds: Rect2, room_transform: Transform2D) -> void:
	var world_rect := Rect2(room_transform * local_bounds.position, local_bounds.size)
	camera.limit_left = floori(world_rect.position.x)
	camera.limit_top = floori(world_rect.position.y)
	camera.limit_right = ceili(world_rect.end.x)
	camera.limit_bottom = ceili(world_rect.end.y)
	camera.reset_smoothing()

func _preload_adjacent_rooms(data: RoomData) -> void:
	for adjacent_id: StringName in data.adjacent_room_ids:
		var adjacent: RoomData = room_data_by_id.get(String(adjacent_id)) as RoomData
		if adjacent == null or threaded_scene_paths.has(adjacent.scene_path):
			continue
		var error := ResourceLoader.load_threaded_request(adjacent.scene_path, "PackedScene")
		if error == OK:
			threaded_scene_paths[adjacent.scene_path] = true

func _get_room_scene(scene_path: String) -> PackedScene:
	if threaded_scene_paths.has(scene_path):
		var status := ResourceLoader.load_threaded_get_status(scene_path)
		while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
			status = ResourceLoader.load_threaded_get_status(scene_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var threaded_resource := ResourceLoader.load_threaded_get(scene_path) as PackedScene
			threaded_scene_paths.erase(scene_path)
			return threaded_resource
		threaded_scene_paths.erase(scene_path)
	return load(scene_path) as PackedScene

func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", alpha, 0.20)
	await tween.finished
