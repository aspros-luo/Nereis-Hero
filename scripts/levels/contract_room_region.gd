extends Node2D
## Contract-driven room network. Spatial contracts are source data; this controller is a playable construction pass, not final art.
const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const DOOR_SCRIPT = preload("res://scripts/world/interaction_door.gd")
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
var platforms: Array[Dictionary] = []
var exits: Array[Dictionary] = []
var landmarks: Array[Dictionary] = []

func _ready() -> void:
	WorldState.prepare_scene_runtime()
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
	_build_terrain()
	_build_exits()
	_spawn_hero(_entry_position(WorldState.pending_region_spawn_side))
	WorldState.pending_region_spawn_side = "west"
	_spawn_ui()
	WorldState.set_checkpoint(hero.global_position)
	queue_redraw()
	print("[NEREIS][ROOM_NETWORK] id=%s terrain=%d exits=%d" % [room_id, platforms.size(), exits.size()])

func _build_terrain() -> void:
	platforms.clear()
	for item in room_data.get("terrain", []):
		var values: Array = item.rect
		var rect := Rect2(Vector2(values[0], values[1]), Vector2(values[2], values[3]))
		platforms.append({"id": item.id, "rect": rect, "type": item.get("type", "ground")})
		var body := StaticBody2D.new()
		body.name = "Terrain_" + str(item.id)
		body.position = rect.position
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		collision.position = rect.size * 0.5
		collision.one_way_collision = item.get("type", "") == "one_way"
		body.add_child(collision)
		add_child(body)
	landmarks = room_data.get("landmarks", [])

func _build_exits() -> void:
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
		var anchor := Vector2(item.at[0], item.at[1])
		var door := Area2D.new()
		door.set_script(DOOR_SCRIPT)
		door.name = "Exit_" + str(item.id)
		door.position = anchor
		door.prompt_text = "E  " + str(item.kind).replace("_", " ")
		door.set_meta("room_target_id", target_id)
		door.set_meta("route_condition", item.get("condition", "none"))
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(76, 100)
		shape_node.shape = shape
		shape_node.position = Vector2(0, -44)
		door.add_child(shape_node)
		add_child(door)
		door.interacted.connect(_on_exit_interacted.bind(target_scene, _spawn_side_for_target(target_id), str(item.get("condition", "none"))))
		exits.append({"id": item.id, "position": anchor, "target": target_id, "condition": item.get("condition", "none")})

func _route_condition_met(condition: String) -> bool:
	if condition.is_empty() or condition == "none":
		return true
	if condition == "village_defense_survived":
		return WorldState.prologue_complete or condition in WorldState.achievement_flags
	return condition in WorldState.achievement_flags or condition in WorldState.opened_hidden_paths or condition in WorldState.unlocked_abilities

func _spawn_side_for_target(target_id: String) -> String:
	var region := target_id.split("-")[0]
	if region == "A1":
		return "east"
	if region == "A2":
		return "upper"
	if region == "A3":
		return "lower"
	return "west"

func _on_exit_interacted(target_scene: String, spawn_side: String, condition: String) -> void:
	if not _route_condition_met(condition):
		print("[NEREIS][ROOM_NETWORK][LOCKED] room=%s condition=%s" % [room_id, condition])
		return
	FOCUS_SCRIPT.clear_all(get_tree())
	WorldState.pending_region_spawn_side = spawn_side
	WorldState.set_location(target_scene.get_file().get_basename())
	print("[NEREIS][ROOM_NETWORK][EXIT] %s -> %s" % [room_id, target_scene])
	SceneTransition.fade_to_scene(target_scene)

func _entry_position(incoming: String) -> Vector2:
	var spawn: Array = room_data.get("spawn", {}).get("at", [120, 400])
	var point := Vector2(spawn[0], spawn[1])
	if incoming == "east":
		point.x = minf(room_size.x - 110.0, point.x + 180.0)
	elif incoming == "lower":
		point.y = minf(room_size.y - 130.0, point.y + 160.0)
	elif incoming == "upper":
		point.y = maxf(100.0, point.y - 100.0)
	return point

func _spawn_hero(at: Vector2) -> void:
	hero = CharacterBody2D.new()
	hero.set_script(HERO_SCRIPT)
	hero.name = "Hero"
	hero.position = at
	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 18.0
	capsule.height = 48.0
	collision.shape = capsule
	hero.add_child(collision)
	add_child(hero)
	var camera := Camera2D.new()
	camera.name = "HeroCamera"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(room_size.x)
	camera.limit_bottom = int(room_size.y)
	hero.add_child(camera)
	if hero.has_signal("defeated"):
		hero.defeated.connect(_on_hero_defeated)

func _spawn_ui() -> void:
	var narrative := CanvasLayer.new()
	narrative.set_script(NARRATIVE_SCRIPT)
	add_child(narrative)
	var hud := CanvasLayer.new()
	hud.set_script(HUD_SCRIPT)
	add_child(hud)
	hud.bind_hero(hero)
	hud.set_story_mode(str(room_data.get("title", room_id)), "探索错层地形，寻找回环、竖井与隐藏路线")

func _on_hero_defeated() -> void:
	if is_instance_valid(hero):
		hero.global_position = WorldState.checkpoint_position
		hero.velocity = Vector2.ZERO

func _draw() -> void:
	var title: String = room_data.get("title", room_id)
	var deep := room_id.begins_with("A3") or room_id == "A1-R02"
	var base := Color("#10151b") if not deep else Color("#100d17")
	draw_rect(Rect2(Vector2.ZERO, room_size), base, true)
	var far := Color("#273941") if not deep else Color("#30243b")
	var mid := Color("#35484a") if not deep else Color("#49334d")
	for layer in range(5):
		var y := room_size.y * (0.15 + layer * 0.13)
		var step := 190.0 + layer * 23.0
		var x := -step
		while x < room_size.x + step:
			var peak := y + sin((x / step) + layer * 1.7) * (24.0 + layer * 7.0)
			var ridge := PackedVector2Array([Vector2(x, room_size.y), Vector2(x, peak + 80), Vector2(x + step * 0.4, peak), Vector2(x + step * 0.72, peak + 42), Vector2(x + step, room_size.y)])
			draw_colored_polygon(ridge, far if layer < 3 else mid)
			x += step * 0.76
	for item in platforms:
		var rect: Rect2 = item.rect
		var top := rect.position
		var is_ground := item.type == "ground"
		var fill := Color("#292d31") if is_ground else Color("#343b3c")
		draw_rect(Rect2(top + Vector2(0, 7), rect.size), Color("#080a0d"), true)
		draw_rect(rect, fill, true)
		draw_line(top, top + Vector2(rect.size.x, 0), Color("#a4a88d") if is_ground else Color("#8dada3"), 3.0, true)
		draw_line(top + Vector2(0, 4), top + Vector2(rect.size.x, 4), Color("#626b61"), 1.0, true)
		for seam_x in range(36, int(rect.size.x), 72):
			draw_line(top + Vector2(seam_x, 8), top + Vector2(seam_x + 16, minf(rect.size.y, 20)), Color("#20262a"), 1.0, true)
	for landmark in landmarks:
		var p := Vector2(landmark.at[0], landmark.at[1])
		draw_circle(p, 26, Color("#101114"))
		draw_arc(p, 30, 0, TAU, 24, Color("#c3a879"), 2.0, true)
		draw_line(p + Vector2(0, -18), p + Vector2(0, 18), Color("#d7c7a2"), 2.0, true)
		draw_line(p + Vector2(-12, 0), p + Vector2(12, 0), Color("#d7c7a2"), 2.0, true)
	for exit in exits:
		var p: Vector2 = exit.position
		var glow := Color("#cfb57c") if exit.condition == "none" else Color("#8a6b76")
		draw_arc(p + Vector2(0, -30), 28, PI, TAU, 24, glow, 2.0, true)
		draw_line(p + Vector2(-28, 0), p + Vector2(-28, -30), glow, 3.0, true)
		draw_line(p + Vector2(28, 0), p + Vector2(28, -30), glow, 3.0, true)
	draw_string(ThemeDB.fallback_font, Vector2(42, 58), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#e0d4bb"))
