extends Node2D

const NARRATIVE_SCENE: PackedScene = preload("res://scenes/core/narrative_manager.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const CLIFF_CAVE_SCENE := "res://scenes/cliff_cave_experiment.tscn"

@onready var hero: CharacterBody2D = $Hero
@onready var backhill_return_door: Area2D = $BackToBackhillDoor
@onready var h09_cave_door: Area2D = $H09CaveDoor
var narrative: CanvasLayer
var hud: CanvasLayer


func _ready() -> void:
	WorldState.prepare_scene_runtime()
	get_tree().paused = false
	WorldState.input_locked = false
	WorldState.pending_region_spawn_side = "west"
	hero.position = Vector2(240, 540)
	WorldState.set_location("cliff_exploration")
	backhill_return_door.interacted.connect(_on_backhill_return_interacted)
	for poi_name in ["ObservationPOI", "WeatheredInscriptionPOI", "CollapsedLookoutPOI"]:
		var poi: Node = get_node(poi_name)
		poi.interacted.connect(_on_poi_interacted.bind(poi))
	var h09_unlocked := "returned_to_village_after_mad_cleric" in WorldState.achievement_flags
	h09_cave_door.enabled = h09_unlocked
	h09_cave_door.visible = h09_unlocked
	$H09CaveVisual.visible = h09_unlocked
	if h09_unlocked:
		h09_cave_door.interacted.connect(_on_h09_cave_interacted)
	_spawn_ui()


func _spawn_ui() -> void:
	narrative = NARRATIVE_SCENE.instantiate() as CanvasLayer
	add_child(narrative)
	hud = HUD_SCENE.instantiate() as CanvasLayer
	add_child(hud)
	hud.bind_hero(hero)
	hud.set_story_mode("A1.1｜悬崖探索", "沿崖岸探索旧观测遗址。西侧入口可以返回后山。")


func _on_backhill_return_interacted() -> void:
	WorldState.pending_region_spawn_side = "cliff_return"
	WorldState.set_location("village_backhill")
	SceneTransition.fade_to_scene("res://scenes/village_backhill.tscn")


func _on_poi_interacted(poi: Node) -> void:
	narrative.show_message(poi.display_name, poi.dialogue, 5.0)
	await narrative.message_finished


func _on_h09_cave_interacted() -> void:
	WorldState.discover_hidden_region("H09")
	WorldState.open_hidden_path("H09")
	WorldState.mark_hidden_region_entered("H09")
	WorldState.pending_region_spawn_side = "west"
	WorldState.set_location("cliff_cave_experiment")
	print("[NEREIS][SECRET] Entering H09 from the cliff exploration scene")
	SceneTransition.fade_to_scene(CLIFF_CAVE_SCENE)
