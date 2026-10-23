extends Node
## A2 terrain supplement. Keep the region controller's authored floors, ledges, doors, and route contracts.
## A2 地形补强：保留公共控制器既有的地面分段、平台、出口门与地图连接合同。

const FLOOR_THICKNESS := 40.0
const CRYPT_FLOOR_Y := 810.0
const CRYPT_LEFT := 860.0
const CRYPT_WIDTH := 200.0

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
		_add_floor_segment(region, "A2_FloodedCryptFloor", CRYPT_LEFT, CRYPT_WIDTH, CRYPT_FLOOR_Y)

	# The default checkpoint is placed at x=1150 inside the Bell Grave opening; move it to safe ground.
	# 默认休整点 x=1150 位于钟墓坑口，移动到东侧安全地面。
	var rest := region.get_node_or_null("RegionRestPoint_A2")
	if rest != null:
		rest.position = Vector2(1600.0, float(region.get("floor_y")))

	# Keep the shared clue node and interaction state; only align its visual with the upper tomb ring.
	# 保留线索节点和交互状态，只将其摆放到钟墓上环。
	var bell := region.get_node_or_null("Anomaly_anomaly_bell_retiming")
	if bell != null:
		bell.position = Vector2(735.0, 322.0)

	region.queue_redraw()
	print("[NEREIS][A2][TERRAIN] crypt landing added at y=810; shared canopy, C03/C04 and ravine ledges preserved")

func _add_floor_segment(region: Node, segment_name: String, x: float, width: float, top_y: float) -> void:
	if width <= 0.0:
		return
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
