extends Node2D
## Compact first-visit exploration section for the village's old drainage passage.
## 村庄旧排水口的早期探索短段；后续从城区/水库侧开启连接。

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const DOOR_SCRIPT = preload("res://scripts/world/interaction_door.gd")
const RAT_SCRIPT = preload("res://scripts/enemies/sewer_rat.gd")
const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

const VILLAGE_SCENE := "res://scenes/village_hub.tscn"
const CITY_SCENE := "res://scenes/forgotten_city.tscn"
const RESERVOIR_SCENE := "res://scenes/sewer_reservoir.tscn"
const CONNECTION_FLAG := "opened_old_drainage_link_from_A4"

var hero: CharacterBody2D
var narrative: CanvasLayer
var hud: CanvasLayer
var entry_side := "village_entry"
var respawning := false

func _ready() -> void:
	WorldState.prepare_scene_runtime()
	entry_side = WorldState.pending_region_spawn_side
	WorldState.pending_region_spawn_side = "west"
	WorldState.set_location("old_drain_exploration")
	_build_floor_and_descent()
	_spawn_hero(_spawn_x_for_side(entry_side), _spawn_y_for_side(entry_side))
	_spawn_door(150.0, 540.0, "E  返回边境村庄", _return_to_village)
	if CONNECTION_FLAG in WorldState.achievement_flags:
		_spawn_door(2260.0, 690.0, "E  沿旧排水道进入城区", _enter_city)
		_spawn_door(1360.0, 690.0, "E  返回旧水库", _return_to_reservoir)
	else:
		_spawn_door(2260.0, 690.0, "E  检查被堵住的闸门", _inspect_blocked_gate)
	_spawn_rat(900.0)
	_spawn_rat(1540.0)
	_spawn_ui()
	queue_redraw()
	if "old_drain_first_visit_seen" not in WorldState.achievement_flags and not WorldState.debug_map_test_mode:
		WorldState.record_achievement("old_drain_first_visit_seen")
		get_tree().create_timer(0.55).timeout.connect(_show_intro)

func _build_floor_and_descent() -> void:
	_add_floor_segment(0.0, 280.0, 540.0)
	_add_floor_segment(600.0, 1800.0, 690.0)
	_add_platform(Rect2(300.0, 555.0, 95.0, 16.0))
	_add_platform(Rect2(390.0, 600.0, 95.0, 16.0))
	_add_platform(Rect2(485.0, 645.0, 110.0, 16.0))
	_add_platform(Rect2(700.0, 635.0, 140.0, 16.0))
	_add_platform(Rect2(1030.0, 590.0, 125.0, 16.0))
	_add_platform(Rect2(1210.0, 550.0, 130.0, 16.0))
	_add_platform(Rect2(1480.0, 590.0, 145.0, 16.0))
	_add_platform(Rect2(1770.0, 625.0, 130.0, 16.0))
	_add_wall(-20.0)
	_add_wall(2420.0)

func _add_floor_segment(x: float, width: float, top_y: float) -> void:
	var body := StaticBody2D.new()
	body.name = "DrainFloor"
	body.position = Vector2(x + width * 0.5, top_y + 20.0)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, 40.0)
	shape.shape = rectangle
	body.add_child(shape)
	add_child(body)

func _add_platform(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	shape.position = rect.size * 0.5
	shape.one_way_collision = true
	body.add_child(shape)
	add_child(body)

func _add_wall(x: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x, 600.0)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(40.0, 900.0)
	shape.shape = rectangle
	body.add_child(shape)
	add_child(body)

func _spawn_hero(spawn_x: float, spawn_y: float) -> void:
	hero = CharacterBody2D.new()
	hero.set_script(HERO_SCRIPT)
	hero.name = "Hero"
	hero.position = Vector2(spawn_x, spawn_y)
	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 18.0
	capsule.height = 48.0
	collision.shape = capsule
	collision.position = Vector2(0.0, -24.0)
	hero.add_child(collision)
	add_child(hero)
	hero.defeated.connect(_on_hero_defeated)
	WorldState.set_checkpoint(hero.global_position)
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 2400
	camera.limit_bottom = 900
	hero.add_child(camera)

func _spawn_ui() -> void:
	narrative = CanvasLayer.new()
	narrative.set_script(NARRATIVE_SCRIPT)
	add_child(narrative)
	hud = CanvasLayer.new()
	hud.set_script(HUD_SCRIPT)
	add_child(hud)
	hud.bind_hero(hero)
	hud.set_story_mode("A1/A3/A4｜旧排水通道", "向下探索；东侧闸门暂时封闭，找到另一侧后再回来。")

func _spawn_door(x: float, y: float, prompt: String, callback: Callable) -> void:
	var door := Area2D.new()
	door.set_script(DOOR_SCRIPT)
	door.position = Vector2(x, y)
	door.prompt_text = prompt
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(84.0, 112.0)
	shape.shape = rectangle
	shape.position = Vector2(0.0, -56.0)
	door.add_child(shape)
	add_child(door)
	door.interacted.connect(callback)

func _spawn_rat(x: float) -> void:
	var rat := CharacterBody2D.new()
	rat.set_script(RAT_SCRIPT)
	rat.name = "SewerRat_%d" % int(x)
	rat.position = Vector2(x, 690.0)
	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 14.0
	capsule.height = 28.0
	collision.shape = capsule
	collision.position = Vector2(0.0, -14.0)
	rat.add_child(collision)
	add_child(rat)
	rat.set_meta("interaction_priority", 0)

func _spawn_x_for_side(side: String) -> float:
	match side:
		"city_side_entry":
			return 2110.0
		"reservoir_link":
			return 1510.0
		_:
			return 210.0

func _spawn_y_for_side(side: String) -> float:
	return 540.0 if side == "village_entry" else 690.0

func _return_to_village() -> void:
	WorldState.pending_region_spawn_side = "city_cut_return"
	WorldState.set_location("village")
	SceneTransition.fade_to_scene(VILLAGE_SCENE)

func _inspect_blocked_gate() -> void:
	if narrative:
		narrative.show_message("锈蚀闸门", "闸门后方仍有通道，水声也从更深处传来。\n\n门轴已经被沉积物与铁锈咬死；你暂时找不到能从这一侧开启它的机构。", 4.5)

func _enter_city() -> void:
	if CONNECTION_FLAG not in WorldState.achievement_flags:
		_inspect_blocked_gate()
		return
	WorldState.pending_region_spawn_side = "city_cut_return"
	WorldState.set_location("forgotten_city")
	SceneTransition.fade_to_scene(CITY_SCENE)

func _return_to_reservoir() -> void:
	if CONNECTION_FLAG not in WorldState.achievement_flags:
		return
	WorldState.pending_region_spawn_side = "old_drain_link"
	WorldState.set_location("sewer_reservoir")
	SceneTransition.fade_to_scene(RESERVOIR_SCENE)

func _show_intro() -> void:
	if narrative == null or not is_instance_valid(narrative):
		return
	narrative.show_message("旧排水通道", "入口后的石阶向下延伸。\n\n墙缝里有新鲜的抓痕；更深处传来细碎的奔跑声。\n\n前方塌方封住了去路，但另一侧似乎仍然连着旧城区。", 5.5)

func _on_hero_defeated() -> void:
	if respawning:
		return
	respawning = true
	WorldState.input_locked = true
	INTERACTION_FOCUS_SCRIPT.clear_all(get_tree())
	await get_tree().create_timer(0.75).timeout
	if is_instance_valid(hero):
		hero.velocity = Vector2.ZERO
		hero.global_position = WorldState.checkpoint_position
		if hero.has_method("restore_full"):
			hero.call("restore_full")
	INTERACTION_FOCUS_SCRIPT.clear_all(get_tree())
	WorldState.input_locked = false
	respawning = false

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 2400.0, 900.0), Color("#101920"))
	for x in range(0, 2400, 160):
		draw_rect(Rect2(float(x), 140.0 + float((x / 160) % 3) * 26.0, 150.0, 130.0), Color("#1a2a30", 0.65))
		draw_line(Vector2(float(x) + 14.0, 520.0), Vector2(float(x) + 38.0, 540.0), Color("#37444a"), 2.0)
	for x in [60.0, 250.0, 640.0, 990.0, 1330.0, 1710.0, 2070.0]:
		draw_arc(Vector2(x, 510.0 + (20.0 if x > 300.0 else 0.0)), 42.0, PI, TAU, 18, Color("#46545b"), 5.0)
		draw_line(Vector2(x - 38.0, 520.0), Vector2(x - 38.0, 690.0), Color("#2d3c43"), 4.0)
		draw_line(Vector2(x + 38.0, 520.0), Vector2(x + 38.0, 690.0), Color("#2d3c43"), 4.0)
	draw_rect(Rect2(2118.0, 568.0, 110.0, 122.0), Color("#1c1d24"))
	draw_rect(Rect2(2128.0, 579.0, 90.0, 111.0), Color("#090d12"))
	for x in range(2125, 2220, 18):
		draw_line(Vector2(float(x), 580.0), Vector2(float(x - 5), 686.0), Color("#615b60"), 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(2020.0, 548.0), "SEALED GATE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("#9b8587"))
	draw_string(ThemeDB.fallback_font, Vector2(80.0, 450.0), "OLD DRAIN", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("#9b8587"))
	if CONNECTION_FLAG in WorldState.achievement_flags:
		draw_rect(Rect2(2118.0, 568.0, 110.0, 122.0), Color("#1b302e", 0.5))
		draw_string(ThemeDB.fallback_font, Vector2(2010.0, 548.0), "GATE OPEN", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("#84c4ad"))
