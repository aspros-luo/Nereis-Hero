extends "res://scripts/levels/greybox_world_region.gd"
## A2-specific terrain layout. Keep the macro exit anchors owned by the shared region script.
## A2 专属地形：宏观出口锚点继续由共享区域脚本管理。

const A2_FLOOR_THICKNESS := 40.0
const A2_PIT_LEFT := 970.0
const A2_PIT_RIGHT := 1250.0
const A2_PIT_FLOOR_Y := 690.0

func _create_floor() -> void:
	# The ground route is deliberately interrupted by the bell-tomb sinkhole.
	# 地面主路在钟墓塌陷处断开，迫使玩家选择下探或寻找上层路线。
	_add_floor_segment(0.0, A2_PIT_LEFT, floor_y)
	_add_floor_segment(A2_PIT_RIGHT, map_width - A2_PIT_RIGHT, floor_y)
	# Safe landing basin at the bottom of the drop; the eastern stair returns to the surface.
	# 坑底设置实体落脚区，东侧台阶可重新回到地表。
	_add_floor_segment(A2_PIT_LEFT, A2_PIT_RIGHT - A2_PIT_LEFT, A2_PIT_FLOOR_Y)

func _add_floor_segment(x: float, width: float, top_y: float) -> void:
	var floor_body := StaticBody2D.new()
	floor_body.name = "A2TerrainFloor_%d" % int(x)
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, A2_FLOOR_THICKNESS)
	collision.shape = rectangle
	collision.position = Vector2(x + width * 0.5, top_y + A2_FLOOR_THICKNESS * 0.5)
	floor_body.add_child(collision)
	add_child(floor_body)

func _configure_platforms() -> void:
	platforms.clear()
	# Main route: broken forest floor, broad stone shelves, and a safe approach to the sinkhole.
	# 主路由断续林地、宽石台和坑口安全接近区构成。
	_add_platform(Rect2(250, 495, 120, 18))
	_add_platform(Rect2(400, 465, 130, 18))
	_add_platform(Rect2(545, 430, 145, 18))
	_add_platform(Rect2(690, 465, 150, 18))
	_add_platform(Rect2(820, 500, 120, 18))
	_add_platform(Rect2(890, 515, 80, 18))
	# The sinkhole's lower basin and east-side return stair. This is a one-way-feeling drop,
	# not a softlock: the player can climb out through the separate eastern shelves.
	# 坑底与东侧回升台阶：形成明显下坠路线，但不会把玩家锁死在坑底。
	_add_platform(Rect2(980, 650, 250, 18))
	_add_platform(Rect2(1100, 610, 115, 18))
	_add_platform(Rect2(1195, 570, 105, 18))
	_add_platform(Rect2(1260, 525, 115, 18))
	_add_platform(Rect2(1370, 490, 125, 18))
	# Upper canopy loop: staggered, supported jumps with alternate mid-height shelves.
	# 树冠回环：错层跳台与中层支撑点组成可选高路。
	_add_platform(Rect2(315, 420, 105, 18))
	_add_platform(Rect2(420, 375, 110, 18))
	_add_platform(Rect2(535, 335, 115, 18))
	_add_platform(Rect2(650, 300, 125, 18))
	_add_platform(Rect2(775, 325, 115, 18))
	_add_platform(Rect2(890, 365, 115, 18))
	_add_platform(Rect2(1005, 390, 110, 18))
	_add_platform(Rect2(1115, 350, 110, 18))
	_add_platform(Rect2(1225, 310, 115, 18))
	_add_platform(Rect2(1340, 275, 120, 18))
	_add_platform(Rect2(1460, 310, 115, 18))
	_add_platform(Rect2(1575, 350, 120, 18))
	_add_platform(Rect2(1695, 390, 110, 18))
	# Bell tomb: upper ring, middle mechanism ledge, and a lower crypt approach.
	# 钟墓分为上层墓环、中层机关台与下层墓室入口。
	_add_platform(Rect2(600, 390, 150, 18))
	_add_platform(Rect2(710, 350, 135, 18))
	_add_platform(Rect2(755, 405, 120, 18))
	_add_platform(Rect2(815, 445, 105, 18))
	# Old pilgrim highroad C04: exact contract area remains supported at y=400.
	# C04 旧朝圣高路保持合同要求的 y=400 实体承托。
	_add_platform(Rect2(1715, 400, 200, 18))
	_add_platform(Rect2(1885, 425, 110, 18))
	_add_platform(Rect2(1980, 425, 120, 18))
	_add_platform(Rect2(2100, 400, 120, 18))
	# C03 to A3 is a two-way canopy-highroad connection at the authored x=2240 anchor.
	# C03 通往 A3 的双向出口必须落在 x=2240 的树冠高路上。
	_add_platform(Rect2(2200, 380, 155, 18))
	_add_platform(Rect2(2335, 350, 115, 18))
	_add_platform(Rect2(2440, 390, 110, 18))
	# Small optional nooks add exploration without turning the safe ground route into a mandatory jump puzzle.
	# 小型支路提供额外探索，不把安全地面路线变成强制跳跃谜题。
	_add_platform(Rect2(1450, 440, 115, 18))
	_add_platform(Rect2(1565, 405, 105, 18))
	_add_platform(Rect2(180, 450, 95, 18))

func _spawn_hero(spawn_x: float, spawn_y: float = -1.0) -> void:
	super._spawn_hero(spawn_x, spawn_y)
	# Allow the camera to follow the lower crypt basin while preserving the full-width region bounds.
	# 镜头允许跟随主角进入坑底，同时仍受区域宽度约束。
	camera.limit_bottom = 900

func _draw_forest_landmarks() -> void:
	# Layered forest silhouettes frame the traversable space rather than filling it.
	# 多层森林剪影用于框出可玩空间，不遮挡平台轮廓。
	for x in range(110, int(map_width), 245):
		var height := 130 + (int(x / 245) % 3) * 30
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 62, floor_y + 4), Vector2(x, floor_y - height),
			Vector2(x + 62, floor_y + 4)
		]), Color("#1d2930", 0.88))
		draw_rect(Rect2(x - 9, floor_y - 38, 18, 42), Color("#302b32"))
	# The bell tomb silhouette is visible from the approach and has three readable strata.
	# 从接近路线即可看见钟墓；三层结构清晰可辨。
	draw_rect(Rect2(615, 280, 215, 205), Color("#34313b"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(585, 282), Vector2(720, 215), Vector2(855, 282)
	]), Color("#4b4149"))
	draw_arc(Vector2(720, 330), 75.0, PI, TAU, 28, Color("#9c8a85"), 4.0)
	draw_line(Vector2(625, 390), Vector2(815, 390), Color("#82716f"), 4.0)
	draw_line(Vector2(650, 435), Vector2(790, 435), Color("#5f626c"), 3.0)
	draw_line(Vector2(720, 238), Vector2(720, 275), Color("#d0b58d"), 3.0)
	draw_circle(Vector2(720, 280), 5.0, Color("#d0b58d"))
	draw_string(ThemeDB.fallback_font, Vector2(620, 255), "钟墓 / 上层墓环", HORIZONTAL_ALIGNMENT_LEFT, 220.0, 12, Color("#c1b2a6"))
	draw_string(ThemeDB.fallback_font, Vector2(820, 425), "机关层", HORIZONTAL_ALIGNMENT_LEFT, 100.0, 11, Color("#a9a0a8"))
	# Sinkhole walls and a damp crypt pool mark the actual lower route.
	# 坑壁与潮湿墓底标示真实的下层通路。
	draw_colored_polygon(PackedVector2Array([
		Vector2(A2_PIT_LEFT, floor_y), Vector2(A2_PIT_LEFT + 70, floor_y + 55),
		Vector2(A2_PIT_LEFT + 20, A2_PIT_FLOOR_Y), Vector2(A2_PIT_LEFT, A2_PIT_FLOOR_Y)
	]), Color("#28252d"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(A2_PIT_RIGHT, floor_y), Vector2(A2_PIT_RIGHT - 70, floor_y + 55),
		Vector2(A2_PIT_RIGHT - 18, A2_PIT_FLOOR_Y), Vector2(A2_PIT_RIGHT, A2_PIT_FLOOR_Y)
	]), Color("#28252d"))
	draw_rect(Rect2(A2_PIT_LEFT + 12, A2_PIT_FLOOR_Y + 10, A2_PIT_RIGHT - A2_PIT_LEFT - 24, 24), Color("#1c3540", 0.95))
	draw_line(Vector2(A2_PIT_LEFT + 12, A2_PIT_FLOOR_Y + 10), Vector2(A2_PIT_RIGHT - 12, A2_PIT_FLOOR_Y + 10), Color("#557b86"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(A2_PIT_LEFT + 28, A2_PIT_FLOOR_Y - 12), "淹没的墓底 / 可返回东侧台阶", HORIZONTAL_ALIGNMENT_LEFT, 260.0, 11, Color("#91b6bd"))
	# The old pilgrim road is intentionally raised and visually connects the upper shelves.
	# 旧朝圣路被抬高，视觉上与上层栈台相连。
	for segment in [
		[1575.0, 350.0, 1695.0, 390.0],
		[1695.0, 390.0, 1810.0, 400.0],
		[1810.0, 400.0, 1940.0, 425.0],
		[2100.0, 400.0, 2240.0, 380.0],
		[2240.0, 380.0, 2390.0, 350.0]
	]:
		draw_line(Vector2(segment[0], segment[1]), Vector2(segment[2], segment[3]), Color("#68736e", 0.72), 3.0)


func _draw_ground_detail() -> void:
	# Draw surface detail only where collision-backed floor exists; leave the sinkhole visually open.
	# 地面细节只绘制在有碰撞承托的区域，钟墓坑口保持视觉上的真实空缺。
	var atmosphere := _atmosphere_color()
	for segment in [
		Rect2(0.0, floor_y, A2_PIT_LEFT, 180.0),
		Rect2(A2_PIT_RIGHT, floor_y, map_width - A2_PIT_RIGHT, 180.0),
		Rect2(A2_PIT_LEFT, A2_PIT_FLOOR_Y, A2_PIT_RIGHT - A2_PIT_LEFT, 100.0)
	]:
		draw_rect(Rect2(segment.position.x, segment.position.y, segment.size.x, 3.0), Color(atmosphere.r, atmosphere.g, atmosphere.b, 0.34))
		draw_rect(Rect2(segment.position.x, segment.position.y + 92.0, segment.size.x, 2.0), Color("#100f17", 0.46))
	for x in range(28, int(A2_PIT_LEFT), 128):
		draw_line(Vector2(x, floor_y + 10.0), Vector2(x + 13.0, floor_y + 17.0), Color("#302a31", 0.72), 1.0)
	for x in range(int(A2_PIT_RIGHT) + 28, int(map_width), 128):
		draw_line(Vector2(x, floor_y + 10.0), Vector2(x + 13.0, floor_y + 17.0), Color("#302a31", 0.72), 1.0)
	for x in range(int(A2_PIT_LEFT) + 28, int(A2_PIT_RIGHT), 128):
		draw_line(Vector2(x, A2_PIT_FLOOR_Y + 10.0), Vector2(x + 13.0, A2_PIT_FLOOR_Y + 17.0), Color("#302a31", 0.72), 1.0)
