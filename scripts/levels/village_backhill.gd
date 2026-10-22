extends Node2D

const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const CLIFF_CAVE_SCENE := "res://scenes/cliff_cave_experiment.tscn"

@onready var hero: CharacterBody2D = $Hero
@onready var cliff_cave_door: Area2D = $CliffCaveDoor
var narrative: CanvasLayer
var hud: CanvasLayer

func _ready() -> void:
	WorldState.prepare_scene_runtime()
	get_tree().paused = false
	WorldState.input_locked = false
	WorldState.set_location("village_backhill")
	_spawn_ui()
	$ChurchPOI.interacted.connect(_on_poi_interacted.bind($ChurchPOI))
	$TavernPOI.interacted.connect(_on_poi_interacted.bind($TavernPOI))
	$BackToVillagePOI.interacted.connect(_on_poi_interacted.bind($BackToVillagePOI))
	var cave_unlocked := "returned_to_village_after_mad_cleric" in WorldState.achievement_flags
	cliff_cave_door.enabled = cave_unlocked
	cliff_cave_door.visible = cave_unlocked
	if cave_unlocked:
		cliff_cave_door.interacted.connect(_on_cliff_cave_interacted)
	queue_redraw()

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


func _on_cliff_cave_interacted() -> void:
	WorldState.discover_hidden_region("H09")
	WorldState.open_hidden_path("H09")
	WorldState.mark_hidden_region_entered("H09")
	WorldState.pending_region_spawn_side = "west"
	WorldState.set_location("cliff_cave_experiment")
	print("[NEREIS][SECRET] Entering H09 from A1.1 backhill cliff")
	SceneTransition.fade_to_scene(CLIFF_CAVE_SCENE)

func _draw() -> void:
	# Buildings, platforms, and the collision-backed stair route are authored in village_backhill.tscn.
	# 结构与地形由场景节点负责；这里只绘制可读标签，不在代码中伪造地形。
	draw_string(ThemeDB.fallback_font, Vector2(365, 300), "教堂", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#c8b9c5"))
	draw_string(ThemeDB.fallback_font, Vector2(700, 370), "酒馆", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#c8a68b"))
	draw_string(ThemeDB.fallback_font, Vector2(1320, 320), "后山小径", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#a5a1b0"))
	draw_string(ThemeDB.fallback_font, Vector2(1740, 310), "悬崖边缘", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#9993a6"))
