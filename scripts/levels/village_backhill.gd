extends Node2D

const NARRATIVE_SCENE: PackedScene = preload("res://scenes/core/narrative_manager.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const CLIFF_EXPLORATION_SCENE := "res://scenes/cliff_exploration.tscn"

@onready var hero: CharacterBody2D = $Hero
@onready var cliff_exploration_door: Area2D = $CliffExplorationDoor
var narrative: CanvasLayer
var hud: CanvasLayer
@onready var world_event_director: Node = $WorldEventDirector


func _ready() -> void:
	WorldState.prepare_scene_runtime()
	get_tree().paused = false
	WorldState.input_locked = false
	var spawn_side := WorldState.pending_region_spawn_side
	WorldState.pending_region_spawn_side = "west"
	if spawn_side == "cliff_return":
		hero.position = Vector2(1150, 540)
	world_event_director.setup(WorldState, self)
	WorldState.set_location("village_backhill")
	world_event_director.dispatch("region_entered", {"region": "A1", "location": "village_backhill"})
	_spawn_ui()
	$ChurchPOI.interacted.connect(_on_poi_interacted.bind($ChurchPOI))
	$TavernPOI.interacted.connect(_on_poi_interacted.bind($TavernPOI))
	$BackToVillagePOI.interacted.connect(_on_poi_interacted.bind($BackToVillagePOI))
	cliff_exploration_door.interacted.connect(_on_cliff_exploration_interacted)


func _spawn_ui() -> void:
	narrative = NARRATIVE_SCENE.instantiate() as CanvasLayer
	add_child(narrative)
	hud = HUD_SCENE.instantiate() as CanvasLayer
	add_child(hud)
	hud.bind_hero(hero)
	hud.set_story_mode("A1.1｜教堂与后山", "左侧可进入悬崖探索；右侧通往雾林与钟墓的道路尚未开放。")


func _on_poi_interacted(poi: Node) -> void:
	_refresh_tavern_poi_dialogue()
	if String(poi.poi_id) == "back_to_village":
		WorldState.pending_region_spawn_side = "backhill_return"
		WorldState.set_location("village")
		SceneTransition.fade_to_scene("res://scenes/regions/village_hub.tscn")
		return
	narrative.show_message(poi.display_name, poi.dialogue, 4.0)
	await narrative.message_finished
	world_event_director.dispatch("interaction", {"region": "A1", "interaction_id": String(poi.poi_id), "poi": poi})
	if String(poi.poi_id) == "tavern":
		WorldState.set_location("tavern")
		SceneTransition.fade_to_scene("res://scenes/locations/tavern_interior.tscn")
	elif String(poi.poi_id) == "church":
		WorldState.set_location("church")
		SceneTransition.fade_to_scene("res://scenes/locations/church_interior.tscn")


func _on_cliff_exploration_interacted() -> void:
	WorldState.pending_region_spawn_side = "backhill"
	WorldState.set_location("cliff_exploration")
	SceneTransition.fade_to_scene(CLIFF_EXPLORATION_SCENE)


func _refresh_tavern_poi_dialogue() -> void:
	for poi in get_tree().get_nodes_in_group("a1_tavern_poi"):
		if not is_instance_valid(poi):
			continue
		if "A1_tavern_sound_noticed" in WorldState.achievement_flags:
			poi.dialogue = "你再次靠近酒馆。门内没有歌声，只有杯碟轻碰。\n\n值夜人似乎一直留意着门外，却没有主动提起那一瞬间的旋律。"
		else:
			poi.dialogue = "酒馆的门在你掌下发暖。\n\n你短暂地听见里面传来摇篮曲；当你碰到门把时，歌声却停了。"
