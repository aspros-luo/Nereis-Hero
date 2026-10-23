extends Node
## A2 terrain pass that preserves the shared region controller's full platform and exit layout.
## A2 地形补强：保留公共区域控制器生成的完整平台网络与跨区出口，只替换地面碰撞分段。

const FLOOR_THICKNESS := 40.0
const CRYPT_FLOOR_Y := 790.0

func _ready() -> void:
	call_deferred("_apply_authored_terrain")

func _apply_authored_terrain() -> void:
	var region := get_parent()
	if region == null or not is_instance_valid(region):
		return

	# Replace only the three broad ground bodies. Do not clear region.platforms or delete ledges:
	# those ledges include the contracted C03 remote canopy exit, C04 highroad, and ravine return shelves.
	# 只替换大块地面碰撞体，不清空 platforms，也不删除 C03/C04 高路与沟壑回程台阶。
	for child in region.get_children():
		if child is StaticBody2D and String(child.name).begins_with("GreyboxGround"):
			region.remove_child(child)
			child.queue_free()

	var surface_y: float = float(region.get("floor_y"))
	var width: float = float(region.get("map_width"))
	_add_floor_segment(region, "A2_WestForestGround", 0.0, 860.0, surface_y)
	_add_floor_segment(region, "A2_EastForestGround", 1480.0, 940.0, surface_y)
	_add_floor_segment(region, "A2_FarEastForestGround", 2660.0, width - 2660.0, surface_y)
	# The bell grave is a true drop with a lower floor; the eastern ravine remains a separate gap.
	# 钟墓坑底是真实下落空间；东侧沟壑仍是独立的地面断口。
	_add_floor_segment(region, "A2_FloodedCryptFloor", 860.0, 620.0, CRYPT_FLOOR_Y)

	# The shared controller puts the checkpoint inside the sinkhole by default; move it onto safe east-bank ground.
	# 公共控制器默认把休整点放在坑口范围内，将其移至东岸安全地面。
	var rest := region.get_node_or_null("RegionRestPoint_A2")
	if rest != null:
		rest.position = Vector2(1600.0, surface_y)

	# Keep the existing clue interaction but place its visual at the upper bell-tomb ring.
	# 保留原有线索交互，仅将钟线索放在钟墓上环的可见位置。
	var bell := region.get_node_or_null("Anomaly_anomaly_bell_retiming")
	if bell != null:
		bell.position = Vector2(735.0, 322.0)

	region.queue_redraw()
	print("[NEREIS][A2][TERRAIN] terrain collision aligned: bell-grave drop + crypt floor + eastern ravine; existing ledges preserved")

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
