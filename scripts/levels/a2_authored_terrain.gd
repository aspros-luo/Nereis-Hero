extends Node
## A2 room assembly. Keep cross-region doors and world-state contracts in the shared region controller.
## A2 房间装配：跨区出口与世界状态合同仍由公共区域控制器维护。

const A2_ROOM_SCENES: Array[PackedScene] = [
	preload("res://scenes/rooms/a2_fog_forest/a2_r01_forest_crossroads.tscn"),
	preload("res://scenes/rooms/a2_fog_forest/a2_r02_canopy_bridge.tscn"),
	preload("res://scenes/rooms/a2_fog_forest/a2_r03_bell_tomb_gallery.tscn"),
	preload("res://scenes/rooms/a2_fog_forest/a2_r04_crypt_landing.tscn"),
	preload("res://scenes/rooms/a2_fog_forest/a2_r05_old_pilgrim_highroad.tscn"),
	preload("res://scenes/rooms/a2_fog_forest/a2_r06_eastern_ravine.tscn"),
]


func _ready() -> void:
	call_deferred("_apply_authored_terrain")

func _apply_authored_terrain() -> void:
	var region := get_parent()
	if region == null or not is_instance_valid(region):
		return

	# Floor gaps stay in the region's ground contract; all ledges and the crypt landing are authored in the six room scenes.
	# 地面断口仍由区域地面合同维护；所有台阶和钟墓坑底均手工放在六个房间场景中。

	# The crypt opening ends at x=1060, so the checkpoint at x=1150 is already on continuous surface ground.
	# 钟墓坑口在 x=1060 结束；x=1150 的休整点原本就在连续地表，不应被无故移到远处。
	var rest := region.get_node_or_null("RegionRestPoint_A2")
	if rest != null:
		rest.position = Vector2(1150.0, float(region.get("floor_y")))

	# Keep the shared clue node and interaction state; only align its visual with the upper tomb ring.
	# 保留线索节点和交互状态，只将其摆放到钟墓上环。
	var bell := region.get_node_or_null("Anomaly_anomaly_bell_retiming")
	if bell != null:
		bell.position = Vector2(735.0, 322.0)

	region.queue_redraw()
	print("[NEREIS][A2][ROOMS] six authored room scenes assembled; canopy, crypt, C03/C04 and ravine geometry indexed")


func configure_platforms(region: Node) -> void:
	# A2 geometry is authored in six editable Godot scenes. This function only assembles scenes
	# and indexes their existing one-way collision rectangles for the region's shared renderer.
	# A2 地形由六个可编辑 Godot 场景手工维护；这里仅装配场景，并把现有单向平台登记给区域渲染器。
	for room_scene in A2_ROOM_SCENES:
		var room := room_scene.instantiate() as Node2D
		if room == null:
			push_error("[NEREIS][A2] Failed to instantiate authored room scene: %s" % room_scene.resource_path)
			continue
		region.add_child(room)
		for body in room.get_children():
			if not body is StaticBody2D:
				continue
			for shape_node in body.get_children():
				if not shape_node is CollisionShape2D or not shape_node.one_way_collision:
					continue
				if not shape_node.shape is RectangleShape2D:
					continue
				var rectangle := shape_node.shape as RectangleShape2D
				var rect := Rect2(body.position + shape_node.position - rectangle.size * 0.5, rectangle.size)
				region.call("_register_authored_platform", rect)


func create_floor(region: Node) -> void:
	var map_width := float(region.get("map_width"))
	# Only the continuous ground segments are assembled here; room scenes own all lower shelves.
	# 此处只装配连续地表分段；所有下层石沿均由房间场景负责。
	region.call("_add_ground_segment", "GreyboxGround_West", 0.0, 860.0)
	region.call("_add_ground_segment", "GreyboxGround_Middle", 1060.0, 1360.0)
	# The eastern ravine separates the expanded forest from the remote canopy exit.
	# 东部沟壑将扩建林地与远端树冠出口分开。
	region.call("_add_ground_segment", "GreyboxGround_East", 2660.0, map_width - 2660.0)
	return
