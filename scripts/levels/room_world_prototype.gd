extends Node2D
## Room-based exploration prototype. This is the replacement architecture, not the legacy long graybox.
## 房间式探索原型：这是新地图架构，不是旧的长条灰盒。

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const INTERACTION_DOOR_SCRIPT = preload("res://scripts/world/interaction_door.gd")
const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

@export var room_id: String = "R_SURFACE"
@export var room_title: String = "边境村庄 · 地表"
@export var room_size := Vector2(1500.0, 900.0)

var hero: CharacterBody2D
var room_platforms: Array[Rect2] = []
var room_exits: Array[Dictionary] = []

func _ready() -> void:
	WorldState.prepare_scene_runtime()
	WorldState.set_location(room_id.to_lower())
	var incoming := WorldState.pending_region_spawn_side
	WorldState.pending_region_spawn_side = "west"
	_build_room_geometry()
	_spawn_room_exits()
	_spawn_hero(_spawn_position(incoming))
	_spawn_ui()
	WorldState.set_checkpoint(hero.global_position)
	queue_redraw()
	print("[NEREIS][ROOM_WORLD] room=%s incoming=%s platforms=%d exits=%d" % [room_id, incoming, room_platforms.size(), room_exits.size()])

func _build_room_geometry() -> void:
	room_platforms.clear()
	match room_id:
		"R_SURFACE":
			_add_platform(Rect2(0.0, 690.0, 520.0, 42.0))
			_add_platform(Rect2(640.0, 690.0, 250.0, 42.0))
			_add_platform(Rect2(1030.0, 690.0, 470.0, 42.0))
			_add_platform(Rect2(180.0, 535.0, 210.0, 18.0))
			_add_platform(Rect2(490.0, 440.0, 170.0, 18.0))
			_add_platform(Rect2(850.0, 500.0, 220.0, 18.0))
			_add_platform(Rect2(1130.0, 400.0, 190.0, 18.0))
			_add_platform(Rect2(650.0, 820.0, 250.0, 18.0))
		"R_CANOPY":
			_add_platform(Rect2(0.0, 760.0, 260.0, 38.0))
			_add_platform(Rect2(390.0, 690.0, 210.0, 18.0))
			_add_platform(Rect2(690.0, 570.0, 180.0, 18.0))
			_add_platform(Rect2(980.0, 450.0, 200.0, 18.0))
			_add_platform(Rect2(1250.0, 330.0, 250.0, 18.0))
			_add_platform(Rect2(700.0, 820.0, 230.0, 18.0))
			_add_platform(Rect2(1040.0, 760.0, 260.0, 18.0))
		"R_UNDERCITY":
			_add_platform(Rect2(0.0, 250.0, 320.0, 34.0))
			_add_platform(Rect2(390.0, 370.0, 210.0, 18.0))
			_add_platform(Rect2(700.0, 500.0, 200.0, 18.0))
			_add_platform(Rect2(1010.0, 610.0, 190.0, 18.0))
			_add_platform(Rect2(1230.0, 760.0, 270.0, 34.0))
			_add_platform(Rect2(400.0, 760.0, 240.0, 18.0))
			_add_platform(Rect2(760.0, 820.0, 210.0, 18.0))
	for rect in room_platforms:
		var body := StaticBody2D.new()
		body.name = "Terrain_%03d" % body.get_instance_id()
		body.position = rect.position
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		collision.position = rect.size * 0.5
		collision.one_way_collision = true
		body.add_child(collision)
		add_child(body)

func _add_platform(rect: Rect2) -> void:
	room_platforms.append(rect)

func _spawn_room_exits() -> void:
	match room_id:
		"R_SURFACE":
			_add_exit(Vector2(90.0, 690.0), "E  进入树冠高路", "R_CANOPY", "res://scenes/rooms/canopy_crossing.tscn", "west", "west")
			_add_exit(Vector2(760.0, 820.0), "E  下潜至旧城区", "R_UNDERCITY", "res://scenes/rooms/undercity_descent.tscn", "lower", "lower")
		"R_CANOPY":
			_add_exit(Vector2(80.0, 760.0), "E  返回村庄高台", "R_SURFACE", "res://scenes/rooms/surface_hub.tscn", "upper", "upper")
			_add_exit(Vector2(1400.0, 330.0), "E  前往遗忘城区", "R_UNDERCITY", "res://scenes/rooms/undercity_descent.tscn", "upper", "upper")
		"R_UNDERCITY":
			_add_exit(Vector2(90.0, 250.0), "E  返回村庄井道", "R_SURFACE", "res://scenes/rooms/surface_hub.tscn", "lower", "lower")
			_add_exit(Vector2(1410.0, 760.0), "E  攀向树冠背面", "R_CANOPY", "res://scenes/rooms/canopy_crossing.tscn", "lower", "lower")

func _add_exit(position_in_room: Vector2, prompt: String, target_id: String, target_scene: String, spawn_out: String, spawn_in: String) -> void:
	var door := Area2D.new()
	door.set_script(INTERACTION_DOOR_SCRIPT)
	door.name = "Exit_%s" % target_id
	door.position = position_in_room
	door.prompt_text = prompt
	door.set_meta("room_target_id", target_id)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(76.0, 90.0)
	collision.shape = shape
	collision.position = Vector2(0.0, -36.0)
	door.add_child(collision)
	add_child(door)
	room_exits.append({"position": position_in_room, "target": target_id})
	door.interacted.connect(_on_exit_interacted.bind(target_scene, spawn_out, spawn_in))

func _on_exit_interacted(target_scene: String, spawn_out: String, spawn_in: String) -> void:
	INTERACTION_FOCUS_SCRIPT.clear_all(get_tree())
	WorldState.pending_region_spawn_side = spawn_in
	WorldState.set_location(target_scene.get_file().get_basename())
	print("[NEREIS][ROOM_WORLD][EXIT] scene=%s spawn=%s" % [target_scene, spawn_in])
	SceneTransition.fade_to_scene(target_scene)

func _spawn_position(incoming: String) -> Vector2:
	match incoming:
		"upper":
			match room_id:
				"R_CANOPY":
					return Vector2(1320.0, 295.0)
				"R_UNDERCITY":
					return Vector2(150.0, 205.0)
				_:
					return Vector2(1150.0, 365.0)
		"lower":
			match room_id:
				"R_CANOPY":
					return Vector2(1120.0, 725.0)
				"R_UNDERCITY":
					return Vector2(1350.0, 725.0)
				_:
					return Vector2(760.0, 785.0)
		"east":
			return Vector2(room_size.x - 150.0, 640.0)
		_:
			return Vector2(150.0, 640.0 if room_id != "R_UNDERCITY" else 205.0)

func _spawn_hero(spawn_at: Vector2) -> void:
	hero = CharacterBody2D.new()
	hero.set_script(HERO_SCRIPT)
	hero.name = "Hero"
	hero.position = spawn_at
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
	hud.set_story_mode(room_title, "探索分层通路，寻找通往其他区域的真实出口")

func _on_hero_defeated() -> void:
	if is_instance_valid(hero):
		hero.global_position = WorldState.checkpoint_position
		hero.velocity = Vector2.ZERO

func _draw() -> void:
	var palette := _room_palette()
	draw_rect(Rect2(Vector2.ZERO, room_size), palette.background, true)
	for layer in range(4):
		var y := 120.0 + float(layer) * 145.0
		for x in range(-80, int(room_size.x) + 160, 240):
			var offset := float((x / 240 + layer) % 2) * 110.0
			var ridge := Vector2(float(x) + offset, y + float((x / 120) % 3) * 18.0)
			draw_line(ridge, ridge + Vector2(130.0, -45.0 - float(layer) * 8.0), palette.far, 2.0, true)
	for rect in room_platforms:
		draw_rect(Rect2(rect.position + Vector2(0.0, 5.0), rect.size), palette.shadow, true)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 8.0)), palette.stone, true)
		draw_line(rect.position, rect.position + Vector2(rect.size.x, 0.0), palette.edge, 2.0, true)
	for exit in room_exits:
		var anchor: Vector2 = exit.position
		draw_arc(anchor + Vector2(0.0, -28.0), 28.0, PI, TAU, 18, palette.glow, 2.5, true)
		draw_line(anchor + Vector2(-28.0, 0.0), anchor + Vector2(-28.0, -28.0), palette.glow, 3.0, true)
		draw_line(anchor + Vector2(28.0, 0.0), anchor + Vector2(28.0, -28.0), palette.glow, 3.0, true)
	draw_string(ThemeDB.fallback_font, Vector2(42.0, 58.0), room_title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, palette.text)

func _room_palette() -> Dictionary:
	match room_id:
		"R_CANOPY":
			return {"background": Color("#101a20"), "far": Color("#31454a"), "shadow": Color("#0a1014"), "stone": Color("#52675d"), "edge": Color("#b6c7a2"), "glow": Color("#9ed4c1"), "text": Color("#d8e1d2")}
		"R_UNDERCITY":
			return {"background": Color("#100f1a"), "far": Color("#342b43"), "shadow": Color("#08070d"), "stone": Color("#554b62"), "edge": Color("#b9a2cf"), "glow": Color("#d0b5ec"), "text": Color("#e0d5ed")}
		_:
			return {"background": Color("#11151a"), "far": Color("#34434a"), "shadow": Color("#090c10"), "stone": Color("#5b625f"), "edge": Color("#c0c8ad"), "glow": Color("#e3c78e"), "text": Color("#e6dfcf")}
