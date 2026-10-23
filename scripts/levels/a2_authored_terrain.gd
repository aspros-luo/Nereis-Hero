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


func configure_platforms(region: Node) -> void:
	# A2 platform collision and render data live with the authored terrain module.
	# A2 平台碰撞与绘制数据由专用地形模块维护。
	# A2 is a vertically interlocked region, not a longer flat corridor.
	# A2 采用犬牙交错的上下层：主路会攀升、回落，再从另一侧绕回同一地标。
	# West root climb: jagged shelves climb into the first canopy.
	region.call("_add_platform", Rect2(300, 585, 120, 18))
	region.call("_add_platform", Rect2(430, 530, 110, 18))
	region.call("_add_platform", Rect2(555, 465, 115, 18))
	region.call("_add_platform", Rect2(690, 410, 105, 18))
	region.call("_add_platform", Rect2(770, 345, 105, 18))
	region.call("_add_platform", Rect2(900, 290, 120, 18))
	region.call("_add_platform", Rect2(1035, 235, 130, 18))
	region.call("_add_platform", Rect2(1175, 275, 115, 18))
	region.call("_add_platform", Rect2(1265, 345, 120, 18))
	region.call("_add_platform", Rect2(1380, 405, 130, 18))
	region.call("_add_platform", Rect2(1510, 465, 120, 18))
	region.call("_add_platform", Rect2(1630, 520, 135, 18))
	# Bell Grave outer gallery: an upper rim and a lower return skirt overlap vertically.
	region.call("_add_platform", Rect2(820, 470, 105, 18))
	region.call("_add_platform", Rect2(935, 420, 115, 18))
	region.call("_add_platform", Rect2(1060, 385, 120, 18))
	region.call("_add_platform", Rect2(1180, 430, 115, 18))
	region.call("_add_platform", Rect2(1290, 490, 125, 18))
	region.call("_add_platform", Rect2(760, 535, 100, 18))
	region.call("_add_platform", Rect2(910, 560, 110, 18))
	region.call("_add_platform", Rect2(1050, 535, 110, 18))
	region.call("_add_platform", Rect2(1190, 555, 115, 18))
	# A broken canopy bridge rises over the gallery, then descends behind its ribs.
	region.call("_add_platform", Rect2(850, 185, 115, 18))
	region.call("_add_platform", Rect2(985, 145, 125, 18))
	region.call("_add_platform", Rect2(1125, 175, 115, 18))
	region.call("_add_platform", Rect2(1245, 220, 115, 18))
	region.call("_add_platform", Rect2(1360, 285, 115, 18))
	region.call("_add_platform", Rect2(1475, 330, 120, 18))
	region.call("_add_platform", Rect2(1490, 405, 130, 18))
	# Central pilgrim ribs: upper crossing and lower shelves weave around one another.
	region.call("_add_platform", Rect2(1585, 365, 115, 18))
	region.call("_add_platform", Rect2(1710, 310, 120, 18))
	region.call("_add_platform", Rect2(1840, 270, 120, 18))
	region.call("_add_platform", Rect2(1970, 315, 115, 18))
	region.call("_add_platform", Rect2(2085, 375, 120, 18))
	region.call("_add_platform", Rect2(2185, 440, 115, 18))
	region.call("_add_platform", Rect2(1735, 430, 115, 18))
	region.call("_add_platform", Rect2(1850, 485, 115, 18))
	region.call("_add_platform", Rect2(1975, 525, 125, 18))
	region.call("_add_platform", Rect2(2100, 565, 120, 18))
	# C04 remains on a supported highroad shelf; the lower path can pass beneath it.
	region.call("_add_platform", Rect2(1740, 510, 125, 18))
	region.call("_add_platform", Rect2(1840, 535, 140, 18))
	region.call("_add_platform", Rect2(1975, 465, 115, 18))
	# Eastern ravine: an upper bridge and a deep underpass share the same footprint.
	region.call("_add_platform", Rect2(2250, 490, 115, 18))
	region.call("_add_platform", Rect2(2355, 425, 110, 18))
	region.call("_add_platform", Rect2(2465, 350, 115, 18))
	region.call("_add_platform", Rect2(2580, 300, 120, 18))
	region.call("_add_platform", Rect2(2695, 345, 115, 18))
	region.call("_add_platform", Rect2(2795, 410, 115, 18))
	region.call("_add_platform", Rect2(2895, 465, 115, 18))
	region.call("_add_platform", Rect2(2985, 400, 115, 18))
	region.call("_add_platform", Rect2(3075, 335, 115, 18))
	region.call("_add_platform", Rect2(3165, 390, 115, 18))
	region.call("_add_platform", Rect2(3220, 510, 130, 18))
	# C03's remote canopy exit has a real landing at the authored anchor height.
	region.call("_add_platform", Rect2(3335, 490, 145, 18))
	# A second, higher route crosses above the ravine and rejoins the exit approach.
	region.call("_add_platform", Rect2(2310, 250, 115, 18))
	region.call("_add_platform", Rect2(2435, 205, 115, 18))
	region.call("_add_platform", Rect2(2560, 165, 120, 18))
	region.call("_add_platform", Rect2(2685, 205, 115, 18))
	region.call("_add_platform", Rect2(2805, 260, 115, 18))
	region.call("_add_platform", Rect2(2925, 305, 115, 18))
	region.call("_add_platform", Rect2(3045, 270, 115, 18))
	region.call("_add_platform", Rect2(3155, 315, 115, 18))

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
