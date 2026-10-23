extends "res://scripts/levels/greybox_world_region.gd"
## Authored terrain pass for A2. Keeps the shared world/door/save systems while replacing
## the flat prototype floor with a traversable forest, canopy, bell-tomb and flooded-crypt profile.
## A2 地形专用实现：保留公共世界/门/存档逻辑，替换平直地面并加入树冠、钟墓与坑底结构。

const FLOOR_THICKNESS := 40.0
const CRYPT_FLOOR_Y := 660.0

func _create_floor() -> void:
	# The broad central sinkhole is a real gap in the surface collision, not painted decoration.
	# 中央深坑是真实碰撞断口，不是单纯画出来的装饰。
	_add_floor_segment("WestForestGround", 0.0, 860.0, floor_y)
	_add_floor_segment("EastForestGround", 1480.0, map_width - 1480.0, floor_y)
	_add_floor_segment("FloodedCryptFloor", 860.0, 620.0, CRYPT_FLOOR_Y)

func _add_floor_segment(segment_name: String, x: float, width: float, top_y: float) -> void:
	var floor_body := StaticBody2D.new()
	floor_body.name = segment_name
	floor_body.position = Vector2(x, top_y)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, FLOOR_THICKNESS)
	shape.shape = rectangle
	shape.position = Vector2(width * 0.5, FLOOR_THICKNESS * 0.5)
	floor_body.add_child(shape)
	add_child(floor_body)

func _configure_platforms() -> void:
	platforms.clear()

	# A2-S01: the western forest path rises out of the village entrance into the first canopy loop.
	# 西侧雾林从村庄入口缓步抬升，形成第一条可回环的树冠路线。
	_add_platform(Rect2(250, 495, 115, 18))
	_add_platform(Rect2(355, 455, 115, 18))
	_add_platform(Rect2(465, 415, 120, 18))
	_add_platform(Rect2(575, 375, 120, 18))
	_add_platform(Rect2(690, 340, 130, 18))
	_add_platform(Rect2(805, 315, 145, 18))

	# A2-S02: the bell-tomb upper ring overlooks the sinkhole and reconnects to the canopy.
	# 钟墓上环俯瞰深坑，并与树冠路线交叉；跳落可进入墓穴下层。
	_add_platform(Rect2(830, 385, 135, 18))
	_add_platform(Rect2(930, 430, 125, 18))
	_add_platform(Rect2(1040, 455, 135, 18))
	_add_platform(Rect2(1155, 430, 130, 18))
	_add_platform(Rect2(1270, 390, 130, 18))
	_add_platform(Rect2(1375, 420, 125, 18))

	# A2-S03: ledges in the pit form a lower crypt route and a safe climb back to the eastern forest.
	# 坑底错层石沿构成淹水墓道，并给误落玩家留下可辨认的回攀路线。
	_add_platform(Rect2(875, 605, 120, 18))
	_add_platform(Rect2(990, 575, 120, 18))
	_add_platform(Rect2(1100, 610, 125, 18))
	_add_platform(Rect2(1215, 585, 120, 18))
	_add_platform(Rect2(1325, 550, 125, 18))
	_add_platform(Rect2(1400, 515, 110, 18))

	# A2-S04: long canopy spans are deliberately broken into readable jumps rather than one flat bridge.
	# 树冠高路分段铺设，保持跳跃节奏与可读的落脚点，而不是一条平直长桥。
	_add_platform(Rect2(930, 340, 120, 18))
	_add_platform(Rect2(1055, 320, 120, 18))
	_add_platform(Rect2(1180, 335, 120, 18))
	_add_platform(Rect2(1305, 355, 120, 18))
	_add_platform(Rect2(1430, 375, 120, 18))
	_add_platform(Rect2(1555, 395, 120, 18))
	_add_platform(Rect2(1680, 415, 120, 18))
	_add_platform(Rect2(1805, 425, 120, 18))

	# C04: old pilgrim highroad shortcut. Both its door and return spawn have physical support.
	# C04 旧朝圣高路捷径：门与回程出生点均有实体承托。
	_add_platform(Rect2(1660, 400, 150, 18))
	_add_platform(Rect2(1805, 425, 165, 18))

	# C03: elevated east canopy transition to A3. The A3 return spawn is at x=2120, y=floor_y-140.
	# C03 东侧树冠连接城区；从 A3 返回的出生点 x=2120 / y=floor_y-140 由平台承托。
	_add_platform(Rect2(1940, 415, 120, 18))
	_add_platform(Rect2(2055, 400, 145, 18))
	_add_platform(Rect2(2195, 380, 160, 18))

	# Optional high lookout and side alcoves reward exploration without blocking the main route.
	# 高位瞭望台与侧向小平台是可选探索，不阻断主路。
	_add_platform(Rect2(480, 315, 90, 16))
	_add_platform(Rect2(625, 275, 100, 16))
	_add_platform(Rect2(1460, 310, 105, 16))
	_add_platform(Rect2(1580, 280, 100, 16))
	_add_platform(Rect2(1710, 320, 105, 16))
	_add_platform(Rect2(1980, 340, 100, 16))

func _spawn_region_rest_point() -> void:
	# The A2 shrine sits on the eastern forest shelf; do not place it over the new sinkhole.
	# A2 休整点移至东侧森林地面，避免生成在新挖出的深坑上方。
	var rest := Node2D.new()
	rest.set_script(REST_POINT_SCRIPT)
	rest.name = "RegionRestPoint_A2"
	rest.position = Vector2(1600.0, floor_y)
	rest.rest_id = "rest_A2"
	rest.display_name = "旧朝圣圣龛"
	add_child(rest)

func _spawn_region_sources() -> void:
	# Preserve the shared A2 anomaly logic but place the bell on the tomb-ring platform,
	# so its interaction point is physically reachable instead of floating above a gap.
	# 保留公共 A2 异常逻辑；钟的交互点落在墓环平台上，避免悬空。
	super._spawn_region_sources()
	var bell := get_node_or_null("Anomaly_anomaly_bell_retiming")
	if bell != null:
		bell.position = Vector2(735.0, 322.0)
	var echo := get_node_or_null("Anomaly_anomaly_old_pilgrim_echo")
	if echo != null:
		echo.position = Vector2(1530.0, floor_y - 18.0)
