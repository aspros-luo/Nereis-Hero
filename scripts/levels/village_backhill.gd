extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")

var hero: CharacterBody2D
var narrative: CanvasLayer
var hud: CanvasLayer

func _ready() -> void:
	WorldState.prepare_scene_runtime()
	get_tree().paused = false
	WorldState.input_locked = false
	WorldState.set_location("village_backhill")
	_spawn_hero()
	_spawn_ui()
	$ChurchPOI.interacted.connect(_on_poi_interacted.bind($ChurchPOI))
	$TavernPOI.interacted.connect(_on_poi_interacted.bind($TavernPOI))
	$BackToVillagePOI.interacted.connect(_on_poi_interacted.bind($BackToVillagePOI))
	queue_redraw()

func _spawn_hero() -> void:
	hero = CharacterBody2D.new()
	hero.set_script(HERO_SCRIPT)
	hero.name = "Hero"
	hero.position = Vector2(180, 540)
	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 18.0
	capsule.height = 48.0
	collision.shape = capsule
	collision.position = Vector2(0, -24)
	hero.add_child(collision)
	add_child(hero)
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 2200
	camera.limit_bottom = 720
	hero.add_child(camera)

func _spawn_ui() -> void:
	narrative = CanvasLayer.new()
	narrative.set_script(NARRATIVE_SCRIPT)
	add_child(narrative)
	hud = CanvasLayer.new()
	hud.set_script(HUD_SCRIPT)
	add_child(hud)
	hud.bind_hero(hero)
	hud.set_story_mode("A1.1｜教堂与后山", "探索教堂、酒馆与通往悬崖的山路。")

func _on_poi_interacted(poi: Node) -> void:
	if String(poi.poi_id) == "back_to_village":
		WorldState.pending_region_spawn_side = "backhill_return"
		WorldState.set_location("village")
		SceneTransition.fade_to_scene("res://scenes/village_hub.tscn")
		return
	narrative.show_message(poi.display_name, poi.dialogue, 4.0)
	await narrative.message_finished
	if String(poi.poi_id) == "tavern":
		WorldState.set_location("tavern")
		SceneTransition.fade_to_scene("res://scenes/locations/tavern_interior.tscn")
	elif String(poi.poi_id) == "church":
		WorldState.set_location("church")
		SceneTransition.fade_to_scene("res://scenes/locations/church_interior.tscn")

func _draw() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(365, 300), "教堂", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#c8b9c5"))
	draw_string(ThemeDB.fallback_font, Vector2(700, 370), "酒馆", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#c8a68b"))
	draw_string(ThemeDB.fallback_font, Vector2(1320, 320), "后山小径", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#a5a1b0"))
	draw_line(Vector2(1020, 520), Vector2(1190, 475), Color("#6f6874"), 5.0)
	draw_line(Vector2(1190, 475), Vector2(1350, 420), Color("#6f6874"), 5.0)
	draw_line(Vector2(1350, 420), Vector2(1530, 365), Color("#6f6874"), 5.0)
	draw_line(Vector2(1530, 365), Vector2(1720, 335), Color("#6f6874"), 5.0)
	draw_line(Vector2(1760, 335), Vector2(1900, 370), Color("#4b4653"), 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(1740, 310), "悬崖边缘", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#9993a6"))
