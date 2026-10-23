extends Node
## A2 terrain supplement. Keep the region controller's authored floors, ledges, doors, and route contracts.
## A2 地形补强：保留公共控制器既有的地面分段、平台、出口门与地图连接合同。

const FLOOR_THICKNESS := 40.0
const CRYPT_FLOOR_Y := 810.0
const CRYPT_LEFT := 860.0
const CRYPT_WIDTH := 200.0
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

	# The shared A2 controller already creates the west/middle/east surface gaps and all ledges.
	# Preserve them: the crypt opening is x=860..1060 and the eastern ravine is x=2420..2660.
	# 公共控制器已创建西/中/东地面分段与全部台阶；保留这些实体，只补上钟墓坑底。
	# The flooded crypt floor is authored inside A2-R04 as a StaticBody2D node.
	# 钟墓坑底已作为 StaticBody2D 手工放入 A2-R04 场景。

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
	print("[NEREIS][A2][TERRAIN] crypt landing added at y=810; shared canopy, C03/C04 and ravine ledges preserved")


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
	var floor_y := float(region.get("floor_y"))
	var map_width := float(region.get("map_width"))
	# Keep the ground gaps and lower shelves aligned with the region controller’s camera/world bounds.
	# 地面断口与下层石沿继续使用区域控制器的世界边界和镜头坐标。
	region.call("_add_ground_segment", "GreyboxGround_West", 0.0, 860.0)
	region.call("_add_ground_segment", "GreyboxGround_Middle", 1060.0, 1360.0)
	# The eastern ravine separates the expanded forest from the remote canopy exit.
	# 东部沟壑将扩建林地与远端树冠出口分开。
	region.call("_add_ground_segment", "GreyboxGround_East", 2660.0, map_width - 2660.0)
	# Bell Grave descends below the surface into a real undercroft with staggered exit shelves.
	# The eastern ravine is a deep cut: lower shelves make a second route under the high bridge.
	return
