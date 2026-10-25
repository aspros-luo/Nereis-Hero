extends Node
## A2 room assembly. Room scenes use local coordinates; the parent scene supplies each room origin.
## Keep cross-region doors and world-state contracts in the shared region controller.
## A2 房间装配：房间内部使用局部坐标，由父场景指定房间原点。
## 跨区出口与世界状态合同仍由公共区域控制器维护。

const A2_ROOM_SCENES: Array[PackedScene] = [
	preload("res://scenes/rooms/a2_fog_forest/a2_r01_forest_crossroads.tscn"),
	preload("res://scenes/rooms/a2_fog_forest/a2_r02_canopy_bridge.tscn"),
	preload("res://scenes/rooms/a2_fog_forest/a2_r03_bell_tomb_gallery.tscn"),
	preload("res://scenes/rooms/a2_fog_forest/a2_r04_crypt_landing.tscn"),
	preload("res://scenes/rooms/a2_fog_forest/a2_r05_old_pilgrim_highroad.tscn"),
	preload("res://scenes/rooms/a2_fog_forest/a2_r06_eastern_ravine.tscn"),
]

const A2_ROOM_NODE_NAMES: Array[String] = [
	"A2R01ForestCrossroads",
	"A2R02CanopyBridge",
	"A2R03BellTombGallery",
	"A2R04FloodedCrypt",
	"A2R05OldPilgrimHighroad",
	"A2R06EasternRavine",
]

const A2_EXPECTED_PLATFORM_COUNTS: Dictionary = {
	"A2R01ForestCrossroads": 20,
	"A2R02CanopyBridge": 9,
	"A2R03BellTombGallery": 9,
	"A2R04FloodedCrypt": 10,
	"A2R05OldPilgrimHighroad": 13,
	"A2R06EasternRavine": 24,
}

const A2_EXPECTED_GROUND_NODES: Dictionary = {
	"A2R01ForestCrossroads": "Ground_West",
	"A2R05OldPilgrimHighroad": "Ground_Middle",
	"A2R06EasternRavine": "Ground_East",
}


func _ready() -> void:
	call_deferred("_apply_authored_terrain")

func _apply_authored_terrain() -> void:
	var region := get_parent()
	if region == null or not is_instance_valid(region):
		return

	var rest := region.get_node_or_null("RegionRestPoint_A2")
	if rest != null:
		rest.position = Vector2(1450.0, float(region.get("floor_y")))

	var bell := region.get_node_or_null("Anomaly_anomaly_bell_retiming")
	if bell != null:
		bell.position = Vector2(735.0, 322.0)

	region.queue_redraw()
	_validate_authored_rooms(region)
	print("[NEREIS][A2][ROOMS] six authored room scenes assembled; canopy, crypt, C03/C04 and ravine geometry indexed")


func _validate_authored_rooms(region: Node) -> void:
	var valid := true
	var total_platforms := 0
	var max_platform_right := 0.0
	var room_count := 0
	for room_name in A2_EXPECTED_PLATFORM_COUNTS:
		var room := region.get_node_or_null(NodePath(str(room_name))) as Node2D
		if room == null:
			push_error("[NEREIS][A2][VERIFY][FAIL] missing room root: " + str(room_name))
			valid = false
			continue
		room_count += 1
		var platform_count := 0
		var expected_ground_name := str(A2_EXPECTED_GROUND_NODES.get(room_name, ""))
		if not expected_ground_name.is_empty():
			var ground := room.get_node_or_null(NodePath(expected_ground_name)) as StaticBody2D
			if ground == null or ground.get_node_or_null("CollisionShape2D") == null:
				push_error("[NEREIS][A2][VERIFY][FAIL] room=%s missing authored ground collision=%s" % [room_name, expected_ground_name])
				valid = false
			else:
				var ground_shape := ground.get_node("CollisionShape2D") as CollisionShape2D
				if not (ground_shape.shape is RectangleShape2D) or (ground_shape.shape as RectangleShape2D).size.x <= 0.0:
					push_error("[NEREIS][A2][VERIFY][FAIL] room=%s invalid authored ground shape=%s" % [room_name, expected_ground_name])
					valid = false
		for body in room.get_children():
			if not (body is StaticBody2D):
				continue
			if str(body.name).begins_with("Ground_"):
				continue
			platform_count += 1
			for shape_node in body.get_children():
				if not (shape_node is CollisionShape2D):
					continue
				if shape_node.shape is RectangleShape2D:
					var rectangle := shape_node.shape as RectangleShape2D
					var right_edge: float = room.position.x + body.position.x + shape_node.position.x + rectangle.size.x * 0.5
					max_platform_right = maxf(max_platform_right, right_edge)
		total_platforms += platform_count
		var expected := int(A2_EXPECTED_PLATFORM_COUNTS[room_name])
		if platform_count != expected:
			push_error("[NEREIS][A2][VERIFY][FAIL] room=%s platforms=%d expected=%d" % [room_name, platform_count, expected])
			valid = false
		else:
			print("[NEREIS][A2][VERIFY][ROOM] %s platforms=%d" % [room_name, platform_count])

	var map_width := float(region.get("map_width"))
	if room_count != A2_EXPECTED_PLATFORM_COUNTS.size():
		push_error("[NEREIS][A2][VERIFY][FAIL] room_count=%d expected=%d" % [room_count, A2_EXPECTED_PLATFORM_COUNTS.size()])
		valid = false
	if max_platform_right > map_width:
		push_error("[NEREIS][A2][VERIFY][FAIL] authored terrain exceeds map width: right=%.1f width=%.1f" % [max_platform_right, map_width])
		valid = false
	if map_width < 3480.0:
		push_error("[NEREIS][A2][VERIFY][FAIL] map width %.1f clips the eastern route; expected at least 3480" % map_width)
		valid = false
	if valid:
		print("[NEREIS][A2][VERIFY] PASS rooms=%d/%d platforms=%d right_edge=%.1f map_width=%.1f" % [
			room_count, A2_EXPECTED_PLATFORM_COUNTS.size(), total_platforms, max_platform_right, map_width
		])
	else:
		print("[NEREIS][A2][VERIFY] FAIL rooms=%d/%d platforms=%d right_edge=%.1f map_width=%.1f" % [
			room_count, A2_EXPECTED_PLATFORM_COUNTS.size(), total_platforms, max_platform_right, map_width
		])


func configure_platforms(region: Node) -> void:
	for room_index in range(A2_ROOM_SCENES.size()):
		var room_name := A2_ROOM_NODE_NAMES[room_index]
		var room := region.get_node_or_null(NodePath(room_name)) as Node2D
		if room == null:
			room = A2_ROOM_SCENES[room_index].instantiate() as Node2D
			if room == null:
				push_error("[NEREIS][A2] Failed to instantiate authored room scene: %s" % A2_ROOM_SCENES[room_index].resource_path)
				continue
			room.name = room_name
			region.add_child(room)
			room.owner = region

		for body in room.get_children():
			if not (body is StaticBody2D):
				continue
			for shape_node in body.get_children():
				if not (shape_node is CollisionShape2D) or not shape_node.one_way_collision:
					continue
				if not (shape_node.shape is RectangleShape2D):
					continue
				var rectangle := shape_node.shape as RectangleShape2D
				var rect := Rect2(room.position + body.position + shape_node.position - rectangle.size * 0.5, rectangle.size)
				region.call("_register_authored_platform", rect)


func create_floor(_region: Node) -> void:
	return
