extends Node
## A2 terrain supplement. Keep the region controller's authored floors, ledges, doors, and route contracts.
## A2 地形补强：保留公共控制器既有的地面分段、平台、出口门与地图连接合同。

const FLOOR_THICKNESS := 40.0
const CRYPT_FLOOR_Y := 810.0
const CRYPT_LEFT := 860.0
const CRYPT_WIDTH := 200.0
const CRYPT_LANDING_SCENE := preload("res://scenes/rooms/a2_fog_forest/a2_r04_crypt_landing.tscn")

func _ready() -> void:
	call_deferred("_apply_authored_terrain")

func _apply_authored_terrain() -> void:
	var region := get_parent()
	if region == null or not is_instance_valid(region):
		return

	# The shared A2 controller already creates the west/middle/east surface gaps and all ledges.
	# Preserve them: the crypt opening is x=860..1060 and the eastern ravine is x=2420..2660.
	# 公共控制器已创建西/中/东地面分段与全部台阶；保留这些实体，只补上钟墓坑底。
	if region.get_node_or_null("A2_FloodedCryptFloor") == null:
		var crypt_landing := CRYPT_LANDING_SCENE.instantiate() as StaticBody2D
		if crypt_landing != null:
			crypt_landing.name = "A2_FloodedCryptFloor"
			crypt_landing.position = Vector2(CRYPT_LEFT, CRYPT_FLOOR_Y)
			region.add_child(crypt_landing)

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
	region.call("_add_platform", Rect2(860.0, floor_y + 125.0, 200.0, 18.0))
	region.call("_add_platform", Rect2(850.0, floor_y + 78.0, 70.0, 12.0))
	region.call("_add_platform", Rect2(1000.0, floor_y + 45.0, 70.0, 12.0))
	region.call("_add_platform", Rect2(900.0, floor_y + 5.0, 75.0, 12.0))
	# The eastern ravine is a deep cut: lower shelves make a second route under the high bridge.
	region.call("_add_platform", Rect2(2420.0, floor_y + 125.0, 240.0, 18.0))
	region.call("_add_platform", Rect2(2400.0, floor_y + 78.0, 70.0, 12.0))
	region.call("_add_platform", Rect2(2590.0, floor_y + 45.0, 70.0, 12.0))
	region.call("_add_platform", Rect2(2490.0, floor_y + 5.0, 80.0, 12.0))
	return
