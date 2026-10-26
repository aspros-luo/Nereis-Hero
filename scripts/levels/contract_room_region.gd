extends Node2D
## Contract-driven room network. Spatial contracts are source data; this controller is a playable construction pass, not final art.
const FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")
const CONTRACT_PATH := "res://tools/room_spatial_contracts_a1_a3.json"
const ROOM_SCENES := {
	"A0-R01": "res://scenes/rooms/world_a0_r01.tscn",
	"A1-R01": "res://scenes/rooms/a1_village_streets.tscn",
	"A2-R01": "res://scenes/rooms/a2_mist_forest.tscn",
	"A3-R01": "res://scenes/rooms/a3_collapsed_district.tscn",
	"A4-R01": "res://scenes/rooms/world_a4_r01.tscn",
	"A5-R01": "res://scenes/rooms/world_a5_r01.tscn",
	"A6-R01": "res://scenes/rooms/world_a6_r01.tscn",
	"A7-R01": "res://scenes/rooms/world_a7_r01.tscn",
	"A8-R01": "res://scenes/rooms/world_a8_r01.tscn",
	"A9-R01": "res://scenes/rooms/world_a9_r01.tscn",
	"A10-R01": "res://scenes/rooms/world_a10_r01.tscn",
	"A11-R01": "res://scenes/rooms/world_a11_r01.tscn",
	"A12-R01": "res://scenes/rooms/world_a12_r01.tscn",
	"A13-R01": "res://scenes/rooms/world_a13_r01.tscn",
	"A0-R02": "res://scenes/rooms/world_a0_r02.tscn",
	"A1-R02": "res://scenes/rooms/a1_old_well_shaft.tscn",
	"A2-R02": "res://scenes/rooms/a2_bell_tomb.tscn",
	"A3-R02": "res://scenes/rooms/a3_old_market_roofs.tscn",
	"A4-R02": "res://scenes/rooms/world_a4_r02.tscn",
	"A5-R02": "res://scenes/rooms/world_a5_r02.tscn",
	"A6-R02": "res://scenes/rooms/world_a6_r02.tscn",
	"A7-R02": "res://scenes/rooms/world_a7_r02.tscn",
	"A8-R02": "res://scenes/rooms/world_a8_r02.tscn",
	"A9-R02": "res://scenes/rooms/world_a9_r02.tscn",
	"A10-R02": "res://scenes/rooms/world_a10_r02.tscn",
	"A11-R02": "res://scenes/rooms/world_a11_r02.tscn",
	"A12-R02": "res://scenes/rooms/world_a12_r02.tscn",
	"A13-R02": "res://scenes/rooms/world_a13_r02.tscn",
	"A0-R03": "res://scenes/rooms/world_a0_r03.tscn",
	"A1-R03": "res://scenes/rooms/a1_north_gate_highroad.tscn",
	"A2-R03": "res://scenes/rooms/a2_pilgrim_highroad.tscn",
	"A3-R03": "res://scenes/rooms/a3_drain_alley.tscn",
	"A4-R03": "res://scenes/rooms/world_a4_r03.tscn",
	"A5-R03": "res://scenes/rooms/world_a5_r03.tscn",
	"A6-R03": "res://scenes/rooms/world_a6_r03.tscn",
	"A7-R03": "res://scenes/rooms/world_a7_r03.tscn",
	"A8-R03": "res://scenes/rooms/world_a8_r03.tscn",
	"A9-R03": "res://scenes/rooms/world_a9_r03.tscn",
	"A10-R03": "res://scenes/rooms/world_a10_r03.tscn",
	"A11-R03": "res://scenes/rooms/world_a11_r03.tscn",
	"A12-R03": "res://scenes/rooms/world_a12_r03.tscn",
	"A13-R03": "res://scenes/rooms/world_a13_r03.tscn",
	"H01-R01": "res://scenes/rooms/world_h01_r01.tscn",
	"H02-R01": "res://scenes/rooms/world_h02_r01.tscn",
	"H03-R01": "res://scenes/rooms/world_h03_r01.tscn",
	"H04-R01": "res://scenes/rooms/world_h04_r01.tscn",
	"H05-R01": "res://scenes/rooms/world_h05_r01.tscn",
	"H06-R01": "res://scenes/rooms/world_h06_r01.tscn",
	"H07-R01": "res://scenes/rooms/world_h07_r01.tscn",
	"H08-R01": "res://scenes/rooms/world_h08_r01.tscn"
}
const LEGACY_SCENES := {
	"A0": "res://scenes/escape_prologue.tscn", "A1": "res://scenes/village_hub.tscn",
	"A2": "res://scenes/ash_forest.tscn", "A3": "res://scenes/forgotten_city.tscn",
	"A4": "res://scenes/sewer_reservoir.tscn", "A5": "res://scenes/old_battlefield.tscn",
	"A6": "res://scenes/monastery_tower.tscn", "A7": "res://scenes/prison_depths.tscn",
	"A8": "res://scenes/royal_tomb.tscn", "A9": "res://scenes/royal_outer_ring.tscn",
	"A10": "res://scenes/grand_cathedral.tscn", "A11": "res://scenes/deep_research_depths.tscn",
	"A12": "res://scenes/inner_city.tscn", "A13": "res://scenes/terminal_anomaly.tscn"
}
@export var room_id := "A1-R01"
var room_data: Dictionary = {}
var room_size := Vector2(1600, 900)
var hero: CharacterBody2D
var camera: Camera2D
var narrative: CanvasLayer
var hud: CanvasLayer
var platforms: Array[Dictionary] = []
var exits: Array[Dictionary] = []
var landmarks: Array[Dictionary] = []

func _enter_tree() -> void:
	# Reset shared runtime state before pre-authored child nodes receive _ready().
	WorldState.prepare_scene_runtime()


func _ready() -> void:
	var file := FileAccess.open(CONTRACT_PATH, FileAccess.READ)
	if file == null:
		push_error("Room spatial contracts not found: " + CONTRACT_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Room spatial contracts are invalid JSON.")
		return
	for candidate in parsed.get("rooms", []):
		if candidate.get("room_id", "") == room_id:
			room_data = candidate
			break
	if room_data.is_empty():
		push_error("No room contract for " + room_id)
		return

	room_size = Vector2(room_data.size[0], room_data.size[1])
	WorldState.set_location(room_id.to_lower())
	hero = $Hero as CharacterBody2D
	narrative = $Narrative as CanvasLayer
	hud = $HUD as CanvasLayer
	_read_authored_terrain()
	_read_authored_exits()
	_configure_authored_hero(_entry_position(WorldState.pending_region_spawn_side))
	WorldState.pending_region_spawn_side = "west"
	_configure_authored_ui()

	WorldState.set_checkpoint(hero.global_position)
	queue_redraw()
	print("[NEREIS][ROOM_NETWORK] id=%s terrain=%d exits=%d" % [room_id, platforms.size(), exits.size()])


func _read_authored_terrain() -> void:
	platforms.clear()
	for item in room_data.get("terrain", []):
		var values: Array = item.rect
		var rect := Rect2(Vector2(values[0], values[1]), Vector2(values[2], values[3]))
		var terrain_id := str(item.id)
		var body := get_node_or_null("Terrain_" + terrain_id) as StaticBody2D
		if body == null:
			push_error("%s missing authored terrain node Terrain_%s" % [room_id, terrain_id])
			continue
		var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or not collision.shape is RectangleShape2D:
			push_error("%s terrain %s has no RectangleShape2D collision" % [room_id, terrain_id])
			continue
		var shape := collision.shape as RectangleShape2D
		if shape.size != rect.size:
			push_error("%s terrain %s collision size differs from spatial contract" % [room_id, terrain_id])
		platforms.append({"id": terrain_id, "rect": rect, "type": item.get("type", "ground")})
	landmarks = room_data.get("landmarks", [])


func _read_authored_exits() -> void:
	exits.clear()
	for item in room_data.get("exits", []):
		var target_id: String = item.get("target", "")
		var target_scene: String = ROOM_SCENES.get(target_id, "")
		if target_scene.is_empty():
			var region := target_id.split("-")[0]
			target_scene = LEGACY_SCENES.get(region, "")
		if target_scene.is_empty() or not ResourceLoader.exists(target_scene):
			push_warning("%s exit %s has no scene target yet." % [room_id, item.get("id", "?")])
			continue
		var exit_id := str(item.get("id", ""))
		var door := get_node_or_null("Exit_" + exit_id) as Area2D
		if door == null:
			push_error("%s missing authored exit node Exit_%s" % [room_id, exit_id])
			continue
		var condition := str(item.get("condition", "none"))
		door.set_meta("room_target_id", target_id)
		door.set_meta("route_condition", condition)
		if door.has_signal("interacted"):
			door.interacted.connect(_on_exit_interacted.bind(target_scene, target_id, exit_id, condition))
		exits.append({
			"id": exit_id,
			"position": Vector2(item.at[0], item.at[1]),
			"target": target_id,
			"condition": condition
		})


func _configure_authored_hero(at: Vector2) -> void:
	hero.position = at
	camera = hero.get_node("HeroCamera") as Camera2D
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(room_size.x)
	camera.limit_bottom = int(room_size.y)
	if hero.has_signal("defeated") and not hero.defeated.is_connected(_on_hero_defeated):
		hero.defeated.connect(_on_hero_defeated)


func _configure_authored_ui() -> void:
	hud.bind_hero(hero)
	hud.set_story_mode(str(room_data.get("title", room_id)), "探索错层地形，寻找回环、竖井与隐藏路线")


func _route_condition_met(condition: String) -> bool:
	if condition.is_empty() or condition == "none":
		return true
	if condition == "prologue_escape":
		return WorldState.prologue_complete or WorldState.debug_map_test_mode or condition in WorldState.achievement_flags
	if condition == "village_defense_survived":
		return WorldState.prologue_complete or WorldState.debug_map_test_mode or condition in WorldState.achievement_flags
	if condition.begins_with("resonance_sight_and_"):
		return "resonance_sight" in WorldState.unlocked_abilities or condition in WorldState.achievement_flags or WorldState.debug_map_test_mode
	if condition.ends_with("_contract") or condition.ends_with("_discovery_contract") or condition.ends_with("_secondary_route_contract"):
		var token := condition.replace("_contract", "").replace("_discovery", "").replace("_secondary_route", "")
		return condition in WorldState.achievement_flags or token in WorldState.opened_hidden_paths or WorldState.debug_map_test_mode
	return condition in WorldState.achievement_flags or condition in WorldState.opened_hidden_paths or condition in WorldState.unlocked_abilities or WorldState.debug_map_test_mode

func _target_entry_position(target_id: String, connection_id: String) -> Vector2:
	var file := FileAccess.open(CONTRACT_PATH, FileAccess.READ)
	if file == null:
		return Vector2(150.0, 400.0)
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return Vector2(150.0, 400.0)
	for candidate in parsed.get("rooms", []):
		if candidate.get("room_id", "") != target_id:
			continue
		for target_exit in candidate.get("exits", []):
			if str(target_exit.get("target", "")) != room_id:
				continue
			if not connection_id.is_empty() and str(target_exit.get("id", "")) != connection_id:
				continue
			var p: Array = target_exit.get("at", [150, 400])
			var entry := Vector2(p[0], p[1])
			var target_size: Array = candidate.get("size", [1600, 900])
			if entry.x < float(target_size[0]) * 0.25:
				entry.x += 100.0
			elif entry.x > float(target_size[0]) * 0.75:
				entry.x -= 100.0
			if entry.y < float(target_size[1]) * 0.25:
				entry.y += 90.0
			elif entry.y > float(target_size[1]) * 0.75:
				entry.y -= 90.0
			return entry
		var fallback: Array = candidate.get("spawn", {}).get("at", [150, 400])
		return Vector2(fallback[0], fallback[1])
	return Vector2(150.0, 400.0)

func _on_exit_interacted(target_scene: String, target_id: String, connection_id: String, condition: String) -> void:
	if not _route_condition_met(condition):
		print("[NEREIS][ROOM_NETWORK][LOCKED] room=%s connection=%s condition=%s" % [room_id, connection_id, condition])
		return
	FOCUS_SCRIPT.clear_all(get_tree())
	var entry := _target_entry_position(target_id, connection_id)
	WorldState.pending_region_spawn_side = "point|%d|%d" % [roundi(entry.x), roundi(entry.y)]
	WorldState.set_location(target_id.to_lower())
	print("[NEREIS][ROOM_NETWORK][EXIT] %s -> %s at=%s" % [room_id, target_id, str(entry)])
	SceneTransition.fade_to_scene(target_scene)

func _entry_position(incoming: String) -> Vector2:
	if incoming.begins_with("point|"):
		var parts := incoming.split("|")
		if parts.size() == 3:
			return Vector2(clampf(float(parts[1]), 40.0, room_size.x - 40.0), clampf(float(parts[2]), 40.0, room_size.y - 40.0))
	var spawn: Array = room_data.get("spawn", {}).get("at", [120, 400])
	var point := Vector2(spawn[0], spawn[1])
	if incoming == "east":
		point.x = minf(room_size.x - 110.0, point.x + 180.0)
	elif incoming == "lower":
		point.y = minf(room_size.y - 130.0, point.y + 160.0)
	elif incoming == "upper":
		point.y = maxf(100.0, point.y - 100.0)
	return point

func _on_hero_defeated() -> void:
	if is_instance_valid(hero):
		hero.global_position = WorldState.checkpoint_position
		hero.velocity = Vector2.ZERO

func _theme() -> Dictionary:
	var region := room_id.split("-")[0]
	match region:
		"A0": return {"name":"surgery","sky":Color("#11151d"),"far":Color("#292b38"),"mid":Color("#45404a"),"stone":Color("#34333c"),"ledge":Color("#b3a2a0"),"glow":Color("#e0a56d"),"detail":Color("#5e404a")}
		"A1": return {"name":"village","sky":Color("#121a20"),"far":Color("#263a3b"),"mid":Color("#3d5146"),"stone":Color("#45443a"),"ledge":Color("#c4b38b"),"glow":Color("#e8bd78"),"detail":Color("#78634a")}
		"A2": return {"name":"forest","sky":Color("#0d1b1c"),"far":Color("#1c3934"),"mid":Color("#2d5145"),"stone":Color("#34463b"),"ledge":Color("#9bbd8d"),"glow":Color("#c8db8a"),"detail":Color("#426e54")}
		"A3": return {"name":"ruins","sky":Color("#11131d"),"far":Color("#292b3b"),"mid":Color("#40394a"),"stone":Color("#3a3743"),"ledge":Color("#b0a4b9"),"glow":Color("#d18e8c"),"detail":Color("#6d536d")}
		"A4": return {"name":"reservoir","sky":Color("#0c1925"),"far":Color("#19344a"),"mid":Color("#27506a"),"stone":Color("#2e4653"),"ledge":Color("#8bc5d1"),"glow":Color("#6ed5d2"),"detail":Color("#34758a")}
		"A5": return {"name":"battlefield","sky":Color("#201716"),"far":Color("#44302a"),"mid":Color("#61423a"),"stone":Color("#51413a"),"ledge":Color("#c9a77d"),"glow":Color("#f0b36c"),"detail":Color("#865447")}
		"A6": return {"name":"monastery","sky":Color("#1b1823"),"far":Color("#393043"),"mid":Color("#5a465b"),"stone":Color("#4a3d4e"),"ledge":Color("#d6c39b"),"glow":Color("#f2d48c"),"detail":Color("#85677e")}
		"A7": return {"name":"prison","sky":Color("#11131c"),"far":Color("#252c3b"),"mid":Color("#384253"),"stone":Color("#343b49"),"ledge":Color("#a4b2bd"),"glow":Color("#d1a2c5"),"detail":Color("#596d80")}
		"A8": return {"name":"tomb","sky":Color("#17111d"),"far":Color("#33233e"),"mid":Color("#4b3155"),"stone":Color("#443549"),"ledge":Color("#c3a7cf"),"glow":Color("#dba7f0"),"detail":Color("#78548c")}
		"A9": return {"name":"outer_city","sky":Color("#151822"),"far":Color("#2b3440"),"mid":Color("#48505b"),"stone":Color("#41444a"),"ledge":Color("#c0c4c2"),"glow":Color("#e4c889"),"detail":Color("#707985")}
		"A10": return {"name":"cathedral","sky":Color("#171621"),"far":Color("#373248"),"mid":Color("#5a4e6b"),"stone":Color("#51495b"),"ledge":Color("#d7d0b6"),"glow":Color("#f5e2aa"),"detail":Color("#8e7aa4")}
		"A11": return {"name":"relic","sky":Color("#0c1a20"),"far":Color("#1b3b42"),"mid":Color("#2d5b5d"),"stone":Color("#30484b"),"ledge":Color("#9fd2c3"),"glow":Color("#75f0d0"),"detail":Color("#347e7c")}
		"A12": return {"name":"inner_city","sky":Color("#20141b"),"far":Color("#442532"),"mid":Color("#673647"),"stone":Color("#4d3540"),"ledge":Color("#d6b3a3"),"glow":Color("#f2b1a0"),"detail":Color("#9a4d5e")}
		"A13": return {"name":"anomaly","sky":Color("#0b0b16"),"far":Color("#21152f"),"mid":Color("#38214c"),"stone":Color("#30243b"),"ledge":Color("#c2a5ef"),"glow":Color("#fa8de6"),"detail":Color("#713b91")}
		"H01": return {"name":"hidden_well","sky":Color("#090f17"),"far":Color("#192634"),"mid":Color("#263c4d"),"stone":Color("#283846"),"ledge":Color("#86bac9"),"glow":Color("#9be9ed"),"detail":Color("#356b82")}
		"H02": return {"name":"hidden_bell","sky":Color("#15121b"),"far":Color("#30263a"),"mid":Color("#4a3551"),"stone":Color("#3b3047"),"ledge":Color("#c7b5a2"),"glow":Color("#f3d8a2"),"detail":Color("#886c8f")}
		"H03": return {"name":"erased_street","sky":Color("#12131b"),"far":Color("#292b37"),"mid":Color("#41414c"),"stone":Color("#373740"),"ledge":Color("#b6b2bd"),"glow":Color("#a4e8db"),"detail":Color("#5f7780")}
		"H04": return {"name":"reflection","sky":Color("#0b1721"),"far":Color("#1c3342"),"mid":Color("#2b4c5b"),"stone":Color("#30454e"),"ledge":Color("#9dc8d5"),"glow":Color("#b4f3ff"),"detail":Color("#4d8ca0")}
		"H05": return {"name":"silent_bell","sky":Color("#15121a"),"far":Color("#2b2533"),"mid":Color("#403649"),"stone":Color("#38313f"),"ledge":Color("#c7b5bd"),"glow":Color("#f0c5d5"),"detail":Color("#76596e")}
		"H06": return {"name":"erased_name","sky":Color("#1b1119"),"far":Color("#38202b"),"mid":Color("#56313f"),"stone":Color("#47313c"),"ledge":Color("#d7b5b7"),"glow":Color("#ff9fbd"),"detail":Color("#8b4c61")}
		"H07": return {"name":"mirror","sky":Color("#101721"),"far":Color("#233342"),"mid":Color("#34505c"),"stone":Color("#35454d"),"ledge":Color("#b1d5d9"),"glow":Color("#a8fff0"),"detail":Color("#477c8b")}
		_: return {"name":"primordial","sky":Color("#0c0915"),"far":Color("#25142d"),"mid":Color("#40204b"),"stone":Color("#34233d"),"ledge":Color("#d0a6e5"),"glow":Color("#ff8ddd"),"detail":Color("#81428b")}

func _draw() -> void:
	var title: String = room_data.get("title", room_id)
	var palette := _theme()
	draw_rect(Rect2(Vector2.ZERO, room_size), palette.sky, true)
	for layer in range(5):
		var y := room_size.y * (0.13 + layer * 0.135)
		var step := 175.0 + layer * 31.0
		var x := -step
		while x < room_size.x + step:
			var peak := y + sin((x / step) + layer * 1.73) * (30.0 + layer * 8.0)
			var ridge := PackedVector2Array([Vector2(x, room_size.y), Vector2(x, peak + 90), Vector2(x + step * 0.36, peak), Vector2(x + step * 0.71, peak + 54), Vector2(x + step, room_size.y)])
			draw_colored_polygon(ridge, palette.far if layer < 3 else palette.mid)
			x += step * 0.74
	_draw_region_silhouette(palette)
	for item in platforms:
		var rect: Rect2 = item.rect
		var top := rect.position
		var is_ground := item.type == "ground"
		draw_rect(Rect2(top + Vector2(0, 8), rect.size), Color("#08090d"), true)
		draw_rect(rect, palette.stone if is_ground else palette.detail, true)
		draw_line(top, top + Vector2(rect.size.x, 0), palette.ledge if is_ground else palette.glow, 3.0, true)
		draw_line(top + Vector2(0, 5), top + Vector2(rect.size.x, 5), palette.detail, 1.0, true)
		for seam_x in range(30, int(rect.size.x), 78):
			draw_line(top + Vector2(seam_x, 8), top + Vector2(seam_x + 15, minf(rect.size.y, 21)), palette.sky, 1.0, true)
	for landmark in landmarks:
		var p := Vector2(landmark.at[0], landmark.at[1])
		draw_circle(p, 34, palette.sky)
		draw_arc(p, 31, 0, TAU, 32, palette.glow, 2.0, true)
		draw_arc(p, 21, 0, TAU, 24, palette.detail, 1.0, true)
		draw_line(p + Vector2(0, -19), p + Vector2(0, 19), palette.ledge, 2.0, true)
		draw_line(p + Vector2(-13, 0), p + Vector2(13, 0), palette.ledge, 2.0, true)
	for exit in exits:
		var p: Vector2 = exit.position
		var glow: Color = palette.glow if exit.condition == "none" else palette.detail
		draw_arc(p + Vector2(0, -30), 29, PI, TAU, 28, glow, 3.0, true)
		draw_line(p + Vector2(-28, 0), p + Vector2(-28, -30), glow, 3.0, true)
		draw_line(p + Vector2(28, 0), p + Vector2(28, -30), glow, 3.0, true)
		draw_line(p + Vector2(-28, -15), p + Vector2(28, -15), glow, 1.0, true)
	draw_rect(Rect2(24, 24, minf(room_size.x - 48.0, 650.0), 52), Color("#090b10"), true)
	draw_string(ThemeDB.fallback_font, Vector2(42, 58), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, palette.ledge)

func _draw_region_silhouette(palette: Dictionary) -> void:
	var kind: String = palette.name
	var span := int(room_size.x / 250.0)
	match kind:
		"village", "outer_city", "inner_city", "ruins":
			for i in range(span):
				var x := float(i) * 250.0 + 45.0
				var base_y := room_size.y * (0.66 + float(i % 3) * 0.045)
				var building_h := 100.0 + float((i * 37) % 170)
				var w := 82.0 + float((i * 19) % 65)
				draw_rect(Rect2(x, base_y - building_h, w, building_h), palette.sky.lightened(0.055), true)
				var roof := PackedVector2Array([Vector2(x - 12, base_y - building_h), Vector2(x + w * 0.5, base_y - building_h - 28), Vector2(x + w + 12, base_y - building_h)])
				draw_colored_polygon(roof, palette.detail)
				for window_i in range(2):
					draw_rect(Rect2(x + 15 + window_i * 30, base_y - building_h + 24, 11, 20), palette.glow.darkened(0.35), true)
		"forest":
			for i in range(span + 3):
				var x := float(i) * 215.0 + 25.0
				var trunk_h := 160.0 + float((i * 53) % 240)
				draw_rect(Rect2(x, room_size.y * 0.56 - trunk_h, 22.0 + float(i % 3) * 8.0, trunk_h), palette.detail, true)
				draw_line(Vector2(x + 12, room_size.y * 0.56 - trunk_h + 90), Vector2(x - 36, room_size.y * 0.56 - trunk_h + 35), palette.detail, 8.0, true)
				draw_line(Vector2(x + 15, room_size.y * 0.56 - trunk_h + 130), Vector2(x + 62, room_size.y * 0.56 - trunk_h + 75), palette.detail, 7.0, true)
		"reservoir", "reflection", "hidden_well":
			for band in range(5):
				var y := room_size.y * (0.52 + band * 0.075)
				draw_line(Vector2(0, y), Vector2(room_size.x, y + sin(float(band)) * 8.0), palette.glow.darkened(0.55), 2.0, true)
		"monastery", "cathedral", "tomb", "hidden_bell", "silent_bell":
			for i in range(span + 1):
				var x := float(i) * 250.0 + 90.0
				var top_y := room_size.y * 0.22 + float(i % 2) * 70.0
				draw_rect(Rect2(x, top_y, 20, room_size.y * 0.58), palette.detail, true)
				draw_arc(Vector2(x + 10, top_y + 15), 54.0, PI, TAU, 24, palette.glow.darkened(0.4), 4.0, true)
				draw_rect(Rect2(x - 8, top_y + 80, 36, 56), palette.sky, true)
		"prison":
			for x in range(80, int(room_size.x), 110):
				draw_line(Vector2(x, room_size.y * 0.2), Vector2(x, room_size.y * 0.76), palette.detail, 4.0, true)
			for y in range(int(room_size.y * 0.28), int(room_size.y * 0.72), 120):
				draw_line(Vector2(40, y), Vector2(room_size.x - 40, y), palette.detail.darkened(0.25), 2.0, true)
		"battlefield":
			for i in range(span):
				var x := float(i) * 270.0 + 70.0
				var y := room_size.y * (0.62 - float(i % 4) * 0.07)
				draw_line(Vector2(x, y), Vector2(x + 12, y - 150), palette.detail, 5.0, true)
				draw_line(Vector2(x - 28, y - 112), Vector2(x + 42, y - 102), palette.glow.darkened(0.4), 3.0, true)
		"relic", "anomaly", "primordial", "erased_name":
			for i in range(span):
				var p := Vector2(float(i) * 260.0 + 130.0, room_size.y * (0.26 + float(i % 3) * 0.17))
				draw_arc(p, 42.0 + float(i % 2) * 18.0, 0, TAU, 36, palette.glow.darkened(0.3), 2.0, true)
				draw_arc(p, 24.0, 0, TAU, 24, palette.detail, 1.0, true)
				draw_circle(p, 4.0, palette.glow)
		"erased_street", "mirror":
			for i in range(span):
				var x := float(i) * 260.0 + 90.0
				draw_line(Vector2(x, room_size.y * 0.18), Vector2(x, room_size.y * 0.78), palette.glow.darkened(0.55), 2.0, true)
				draw_line(Vector2(x - 34, room_size.y * 0.32), Vector2(x + 34, room_size.y * 0.32), palette.glow, 2.0, true)
		_:
			for i in range(span):
				var x := float(i) * 260.0 + 100.0
				draw_circle(Vector2(x, room_size.y * 0.4), 3.0 + float(i % 3), palette.glow)
