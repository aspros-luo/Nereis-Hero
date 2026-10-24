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
	"A2R01ForestCrossroads": 12,
	"A2R02CanopyBridge": 7,
	"A2R03BellTombGallery": 9,
	"A2R04FloodedCrypt": 9,
	"A2R05OldPilgrimHighroad": 13,
	"A2R06EasternRavine": 24,
}


func _ready() -> void:
	call_deferred("_apply_authored_terrain")

func _apply_authored_terrain() -> void:
	var region := get_parent()
	if region == null or not is_instance_valid(region):
		return

	# Floor gaps stay in the region's ground contract; all ledges and the crypt landing are authored in the six room scenes.
	# 地面断口仍由区域地面合同维护；所有台阶和钟墓坑底均手工放在六个房间场景中。

	# The expanded crypt opening ends at x=1360, so the checkpoint at x=1450 stays on continuous surface ground.
	# 钟墓坑口扩展至 x=1360；休整点移至 x=1450 的连续地表，避免落入坑口。
	var rest := region.get_node_or_null("RegionRestPoint_A2")
	if rest != null:
		rest.position = Vector2(1450.0, float(region.get("floor_y")))

	# Keep the shared clue node and interaction state; only align its visual with the upper tomb ring.
	# 保留线索节点和交互状态，只将其摆放到钟墓上环。
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
		for body in room.get_children():
			if not (body is StaticBody2D):
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
		print("[NEREIS][A2][VERIFY] PASS rooms=%d/%d platforms=%d/74 right_edge=%.1f map_width=%.1f ground_spans=3" % [
			room_count, A2_EXPECTED_PLATFORM_COUNTS.size(), total_platforms, max_platform_right, map_width
		])
	else:
		print("[NEREIS][A2][VERIFY] FAIL rooms=%d/%d platforms=%d/74 right_edge=%.1f map_width=%.1f" % [
			room_count, A2_EXPECTED_PLATFORM_COUNTS.size(), total_platforms, max_platform_right, map_width
		])


func configure_platforms(region: Node) -> void:
	# Prefer persistent PackedScene instances authored directly in ash_forest.tscn.
	# Fall back to instantiation only for older scene variants that do not yet contain them.
	# 优先使用 ash_forest.tscn 中持久化、可在编辑器直接查看的场景实例；旧场景缺少实例时才动态补齐。
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

		# Register existing scene collisions for shared route/material queries; never create duplicate room geometry.
		# 将场景中的实体碰撞登记给公共路线/材质查询，不重复创建房间或平台。
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


func create_floor(region: Node) -> void:
	var map_width := float(region.get("map_width"))
	# Only the continuous ground segments are assembled here; room scenes own all lower shelves.
	# 此处只装配连续地表分段；所有下层石沿均由房间场景负责。
	region.call("_add_ground_segment", "GreyboxGround_West", 0.0, 860.0)
	region.call("_add_ground_segment", "GreyboxGround_Middle", 1360.0, 1060.0)
	# The eastern ravine separates the expanded forest from the remote canopy exit.
	# 东部沟壑将扩建林地与远端树冠出口分开。
	region.call("_add_ground_segment", "GreyboxGround_East", 2660.0, map_width - 2660.0)
	return
