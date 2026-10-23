extends Node
## Deferred A2 terrain replacement. The shared controller finishes spawning its world systems first;
## this node then replaces only the flat floor/platform geometry, leaving doors, save state and UI intact.
## 延迟替换 A2 地形：公共控制器先完成门、存档与 UI 初始化，本节点再只替换地面和平台碰撞。

const FLOOR_THICKNESS := 40.0
const CRYPT_FLOOR_Y := 660.0

func _ready() -> void:
	call_deferred("_apply_authored_terrain")

func _apply_authored_terrain() -> void:
	var region := get_parent()
	if region == null or not is_instance_valid(region):
		return

	var old_platforms: Array = region.get("platforms").duplicate()
	for child in region.get_children():
		if not (child is StaticBody2D):
			continue
		var should_remove := child.name == "GreyboxGround"
		if not should_remove:
			for rect in old_platforms:
				if child.position.is_equal_approx(rect.position):
					should_remove = true
					break
		if should_remove:
			region.remove_child(child)
			child.queue_free()

	var live_platforms: Array = region.get("platforms")
	live_platforms.clear()
	_add_floor_segment(region, "WestForestGround", 0.0, 860.0, 540.0)
	_add_floor_segment(region, "EastForestGround", 1480.0, 1120.0, 540.0)
	_add_floor_segment(region, "FloodedCryptFloor", 860.0, 620.0, CRYPT_FLOOR_Y)

	# A2-S01: forest approach rises from the village entrance into the canopy.
	# 西侧雾林从村庄入口逐步抬升，接入树冠路线。
	_add_platform(region, Rect2(250, 495, 115, 18))
	_add_platform(region, Rect2(355, 455, 115, 18))
	_add_platform(region, Rect2(465, 415, 120, 18))
	_add_platform(region, Rect2(575, 375, 120, 18))
	_add_platform(region, Rect2(690, 340, 130, 18))
	_add_platform(region, Rect2(805, 315, 145, 18))

	# A2-S02: upper tomb ring surrounds the sinkhole and leads toward the east bank.
	# 钟墓上环环绕深坑，并接向东岸森林。
	_add_platform(region, Rect2(830, 385, 135, 18))
	_add_platform(region, Rect2(930, 430, 125, 18))
	_add_platform(region, Rect2(1040, 455, 135, 18))
	_add_platform(region, Rect2(1155, 430, 130, 18))
	_add_platform(region, Rect2(1270, 390, 130, 18))
	_add_platform(region, Rect2(1375, 420, 125, 18))

	# A2-S03: lower flooded crypt has a stepped route back to the east forest.
	# 坑底淹水墓道以错层平台连接东侧森林，避免形成软锁。
	_add_platform(region, Rect2(875, 605, 120, 18))
	_add_platform(region, Rect2(990, 575, 120, 18))
	_add_platform(region, Rect2(1100, 610, 125, 18))
	_add_platform(region, Rect2(1215, 585, 120, 18))
	_add_platform(region, Rect2(1325, 550, 125, 18))
	_add_platform(region, Rect2(1370, 475, 100, 18))
	_add_platform(region, Rect2(1350, 440, 100, 18))
	_add_platform(region, Rect2(1400, 515, 110, 18))

	# A2-S04: canopy highroad is broken into readable jumps and rejoins the eastern approach.
	# 树冠高路由一组可辨认的跳跃平台组成，并接回东侧入口。
	_add_platform(region, Rect2(930, 340, 120, 18))
	_add_platform(region, Rect2(1055, 320, 120, 18))
	_add_platform(region, Rect2(1180, 335, 120, 18))
	_add_platform(region, Rect2(1305, 355, 120, 18))
	_add_platform(region, Rect2(1430, 375, 120, 18))
	_add_platform(region, Rect2(1490, 490, 100, 18))
	_add_platform(region, Rect2(1555, 395, 120, 18))
	_add_platform(region, Rect2(1580, 455, 100, 18))
	_add_platform(region, Rect2(1680, 415, 120, 18))
	_add_platform(region, Rect2(1805, 425, 120, 18))

	# C04 and C03 remain on their authored elevated layers, with supported door/arrival positions.
	# C04/C03 继续位于既有高位连接层，门锚点与到达出生点均有平台支撑。
	_add_platform(region, Rect2(1660, 400, 150, 18))
	_add_platform(region, Rect2(1805, 425, 165, 18))
	_add_platform(region, Rect2(1940, 415, 120, 18))
	_add_platform(region, Rect2(2055, 400, 145, 18))
	_add_platform(region, Rect2(2195, 380, 160, 18))

	# Optional lookout ledges: visible exploration goals, not mandatory route blockers.
	# 可选瞭望台：提供可见探索目标，不阻断主线。
	_add_platform(region, Rect2(480, 315, 90, 16))
	_add_platform(region, Rect2(625, 275, 100, 16))
	_add_platform(region, Rect2(1460, 310, 105, 16))
	_add_platform(region, Rect2(1580, 280, 100, 16))
	_add_platform(region, Rect2(1710, 320, 105, 16))
	_add_platform(region, Rect2(1980, 340, 100, 16))

	# The default A2 rest point was authored at x=1150; move it out of the sinkhole.
	# 默认 A2 休整点原在 x=1150 深坑上方，将其移动到东侧地面。
	var rest := region.get_node_or_null("RegionRestPoint_A2")
	if rest != null:
		rest.position = Vector2(1600.0, 540.0)

	# Reposition the existing bell clue onto the upper tomb ring; keep its shared state/interaction.
	# 将已有钟线索移至钟墓上环，保留公共状态与交互逻辑。
	var bell := region.get_node_or_null("Anomaly_anomaly_bell_retiming")
	if bell != null:
		bell.position = Vector2(735.0, 322.0)

	region.queue_redraw()
	print("[NEREIS][A2][TERRAIN] authored terrain applied: surface gap + flooded crypt + canopy loop")

func _add_floor_segment(region: Node, segment_name: String, x: float, width: float, top_y: float) -> void:
	var floor_body := StaticBody2D.new()
	floor_body.name = segment_name
	floor_body.position = Vector2(x, top_y)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, FLOOR_THICKNESS)
	shape.shape = rectangle
	shape.position = Vector2(width * 0.5, FLOOR_THICKNESS * 0.5)
	floor_body.add_child(shape)
	region.add_child(floor_body)

func _add_platform(region: Node, rect: Rect2) -> void:
	region.call("_add_platform", rect)
