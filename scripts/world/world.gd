extends Node2D
## 常驻世界：Player、HUD、Camera2D 不随房间释放，只替换 RoomContainer 内容。

const HERO_SCRIPT: Script = preload("res://scripts/player/hero.gd")
const HUD_SCRIPT: Script = preload("res://scripts/ui/game_hud.gd")
const ROOM_ONE: Resource = preload("res://resources/rooms/a5_room_01.tres")
const ROOM_TWO: Resource = preload("res://resources/rooms/a5_room_02.tres")

@onready var room_container: Node2D = $RoomContainer
@onready var fade_rect: ColorRect = $FadeLayer/ColorRect
@onready var transition_manager: RoomTransitionManager = $TransitionManager

var player: CharacterBody2D
var camera: Camera2D
var hud: CanvasLayer
var current_room: RoomBase
var room_data_by_id: Dictionary = {}
var threaded_scene_paths: Dictionary = {}

func _ready() -> void:
	room_data_by_id[String(ROOM_ONE.room_id)] = ROOM_ONE
	room_data_by_id[String(ROOM_TWO.room_id)] = ROOM_TWO
	_create_persistent_player()
	_create_persistent_hud()
	fade_rect.modulate.a = 1.0
	_load_room(String(ROOM_ONE.room_id), &"west", false)
	fade_rect.create_tween().tween_property(fade_rect, "modulate:a", 0.0, 0.25)

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
	var packed := load(data.scene_path) as PackedScene
	if packed == null:
		push_error("World: 无法加载房间场景: " + data.scene_path)
		if use_fade:
			await _fade_to(0.0)
		return
	if is_instance_valid(current_room):
		current_room.queue_free()
		await get_tree().process_frame
	var instance := packed.instantiate() as RoomBase
	if instance == null:
		push_error("World: 场景根节点必须挂载 RoomBase: " + data.scene_path)
		return
	room_container.add_child(instance)
	current_room = instance
	current_room.room_id = data.room_id
	current_room.area_id = data.area_id
	var entry := current_room.get_entry(entry_id)
	if entry == null:
		entry = current_room.get_entry(&"default")
	if entry == null:
		push_error("World: 房间 %s 缺少入口 %s/default" % [room_id, entry_id])
		return
	player.global_position = entry.global_position
	_apply_camera_bounds(current_room.get_room_bounds(), current_room.global_transform)
	_connect_room_transitions(current_room)
	_preload_adjacent_rooms(data)
	if use_fade:
		await _fade_to(0.0)

func _connect_room_transitions(room: RoomBase) -> void:
	for node: Node in room.find_children("*", "Area2D", true, false):
		if node is TransitionPoint:
			var point := node as TransitionPoint
			if not point.transition_requested.is_connected(_on_transition_requested):
				point.transition_requested.connect(_on_transition_requested)

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

func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", alpha, 0.20)
	await tween.finished
