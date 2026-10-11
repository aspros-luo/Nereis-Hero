extends Control
## Player-facing macro map. It visualizes the connected world without teleporting or unlocking routes.
## 面向玩家的世界箱庭路线图：展示区域关系，不传送、不解锁任何路线。

const MAIN_NODES: Array[Dictionary] = [
	{"id":"A0","name":"手术所","p":Vector2(0.035,0.48)},
	{"id":"A1","name":"边境村庄","p":Vector2(0.125,0.48)},
	{"id":"A2","name":"雾林钟墓","p":Vector2(0.215,0.48)},
	{"id":"A3","name":"废弃城区","p":Vector2(0.305,0.48)},
	{"id":"A5","name":"旧战场","p":Vector2(0.395,0.48)},
	{"id":"A6","name":"修道院","p":Vector2(0.485,0.48)},
	{"id":"A7","name":"监牢深处","p":Vector2(0.575,0.48)},
	{"id":"A8","name":"旧王墓","p":Vector2(0.665,0.48)},
	{"id":"A9","name":"王城外环","p":Vector2(0.755,0.48)},
	{"id":"A10","name":"大圣堂","p":Vector2(0.845,0.35)},
	{"id":"A12","name":"王室内城","p":Vector2(0.935,0.48)},
	{"id":"A4","name":"旧水库","p":Vector2(0.405,0.78)},
	{"id":"A11","name":"深层研究区","p":Vector2(0.715,0.78)}
]

const HIDDEN_NODES: Array[Dictionary] = [
	{"id":"H01","name":"井底回声","p":Vector2(0.125,0.78),"parent":"A1"},
	{"id":"H02","name":"倒响钟室","p":Vector2(0.255,0.18),"parent":"A2"},
	{"id":"H03","name":"被删去的街","p":Vector2(0.315,0.18),"parent":"A3"},
	{"id":"H04","name":"水面背阶","p":Vector2(0.475,0.88),"parent":"A4"},
	{"id":"H05","name":"无声钟室","p":Vector2(0.505,0.18),"parent":"A6"},
	{"id":"H06","name":"王名抹除廊","p":Vector2(0.665,0.18),"parent":"A8"},
	{"id":"H07","name":"镜街","p":Vector2(0.835,0.78),"parent":"A9"},
	{"id":"H08","name":"原初空腔","p":Vector2(0.755,0.92),"parent":"A11"}
]

const MAIN_EDGES: Array[Array] = [
	["A0","A1"],["A1","A2"],["A2","A3"],["A3","A5"],["A5","A6"],
	["A6","A7"],["A7","A8"],["A8","A9"],["A9","A10"],["A10","A12"]
]

const LOOP_EDGES: Array[Array] = [
	["A3","A4"],["A4","A1"],["A4","A7"],["A4","A8"],["A4","A9"],
	["A3","A6"],["A2","A5"],["A9","A12"],["A8","A11"],["A10","A11"]
]

const LOCATION_TO_REGION := {
	"church_escape":"A0","village":"A1","ash_forest":"A2","forgotten_city":"A3",
	"sewer_reservoir":"A4","old_battlefield":"A5","monastery_tower":"A6",
	"prison_depths":"A7","royal_tomb":"A8","royal_outer_ring":"A9",
	"grand_cathedral":"A10","deep_research_depths":"A11","inner_city":"A12",
	"hidden_well":"H01","hidden_bell_chamber":"H02","erased_third_street":"H03",
	"reflected_stairwell":"H04","silent_bell_room":"H05",
	"erased_royal_name_corridor":"H06","mirror_street":"H07","primordial_hollow":"H08"
}

var current_region := "A0"
var _node_positions: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	queue_redraw()

func open_map() -> void:
	current_region = str(LOCATION_TO_REGION.get(WorldState.current_location, "A0"))
	visible = true
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
	var viewport_size := get_viewport_rect().size
	var panel := Rect2(Vector2(36, 34), viewport_size - Vector2(72, 68))
	draw_rect(panel, Color("#08090e", 0.94))
	draw_rect(panel, Color("#746657", 0.9), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(panel.position.x + 24, panel.position.y + 34), "世界路线图  /  按 M 关闭", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color("#d6c7b2"))
	draw_string(ThemeDB.fallback_font, Vector2(panel.position.x + 24, panel.position.y + 58), "实线：主线通路    虚线：回环／捷径（部分需从另一侧开启）    紫色节点：已发现的异常区域", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#9c9290"))

	var map_rect := Rect2(panel.position + Vector2(24, 78), panel.size - Vector2(48, 110))
	_node_positions.clear()
	for node in MAIN_NODES:
		_node_positions[node["id"]] = _point_for(node["p"], map_rect)
	for node in HIDDEN_NODES:
		if _is_hidden_node_known(str(node["id"])):
			_node_positions[node["id"]] = _point_for(node["p"], map_rect)

	for edge in MAIN_EDGES:
		_draw_edge(str(edge[0]), str(edge[1]), Color("#786d67"), 2.2, false)
	for edge in LOOP_EDGES:
		_draw_edge(str(edge[0]), str(edge[1]), Color("#827b74"), 1.6, true)
	for node in HIDDEN_NODES:
		var hidden_id := str(node["id"])
		if not _is_hidden_node_known(hidden_id):
			continue
		_draw_edge(str(node["parent"]), hidden_id, Color("#8d6b9d"), 1.8, true)

	for node in MAIN_NODES:
		_draw_node(node, false)
	for node in HIDDEN_NODES:
		if _is_hidden_node_known(str(node["id"])):
			_draw_node(node, true)

	draw_string(ThemeDB.fallback_font, Vector2(panel.position.x + 24, panel.end.y - 18), "地图只记录区域关系；未发现的隐藏区域不会显示。A11 是可选深层区域，抵达王座区不要求先进入 A11。", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#b7a48c"))

func _point_for(normalized: Vector2, rect: Rect2) -> Vector2:
	return rect.position + Vector2(rect.size.x * normalized.x, rect.size.y * normalized.y)

func _draw_edge(from_id: String, to_id: String, color: Color, width: float, dashed: bool) -> void:
	if not _node_positions.has(from_id) or not _node_positions.has(to_id):
		return
	var start: Vector2 = _node_positions[from_id]
	var finish: Vector2 = _node_positions[to_id]
	if dashed:
		draw_dashed_line(start, finish, color, width, 7.0, true)
	else:
		draw_line(start, finish, color, width, true)

func _draw_node(node: Dictionary, hidden: bool) -> void:
	var node_id := str(node["id"])
	if not _node_positions.has(node_id):
		return
	var center: Vector2 = _node_positions[node_id]
	var size := Vector2(76, 38) if not hidden else Vector2(84, 34)
	var rect := Rect2(center - size * 0.5, size)
	var is_current := node_id == current_region
	var fill := Color("#9b794b") if is_current else (Color("#30243b") if hidden else Color("#1b1b23"))
	var border := Color("#e5c88e") if is_current else (Color("#9472a6") if hidden else Color("#6e6561"))
	draw_rect(rect, fill)
	draw_rect(rect, border, false, 2.0 if is_current else 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 5, rect.position.y + 14), node_id, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#f1e4d0"))
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 5, rect.position.y + 29), str(node["name"]), HORIZONTAL_ALIGNMENT_LEFT, size.x - 8, 10, Color("#d2c7bd"))

func _is_hidden_node_known(region: String) -> bool:
	return region in WorldState.discovered_hidden_regions or region in WorldState.entered_hidden_regions
