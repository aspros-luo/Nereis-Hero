extends Node2D


@onready var hero: CharacterBody2D = $Hero
@onready var mite: Node2D = $Mite
@onready var narrative: CanvasLayer = $NarrativeManager
@onready var hud: CanvasLayer = $HUD
@onready var narrative_audio: Node = $NarrativeAudio
@onready var rest_point: Node2D = $RestPoint
@onready var exit: Area2D = $VillageExit

func _ready() -> void:
	WorldState.prepare_scene_runtime()
	get_tree().paused = false
	WorldState.input_locked = false
	WorldState.set_location("mite_house")
	var camera := hero.get_node("HeroCamera") as Camera2D
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1400
	camera.limit_bottom = 720
	mite.interacted.connect(_on_mite_interacted)
	rest_point.rested.connect(_on_rest)
	exit.reached.connect(func() -> void:
		WorldState.pending_region_spawn_side = "mite_house_return"
		WorldState.set_location("village")
		SceneTransition.fade_to_scene("res://scenes/regions/village_hub.tscn")
	)
	hud.bind_hero(hero)
	hud.set_story_mode("MITE'S HOUSE", "STAY A LITTLE LONGER")



func _on_rest() -> void:
	if WorldState.physical_union_complete or WorldState.mite_connection_missed:
		narrative.show_message("A QUIET NIGHT", "The room remains quiet.\n\nNothing follows you into sleep.", 4.0)
		return

	if WorldState.mite_interactions_seen.size() < 4:
		narrative.show_message(
			"NOT YET",
			"Mite looks toward the empty half of the room.\n\n\"You should get some rest.\"",
			4.0
		)
		return

	WorldState.input_locked = true
	narrative.show_message(
		"AFTER THE LAST SONG",
		"The village has gone quiet.\n\nThere is nowhere either of you needs to be tonight.",
		4.5
	)
	await narrative.message_finished
	_complete_union()

func _complete_union() -> void:
	WorldState.mark_physical_union_complete()
	WorldState.mark_ancient_residue_awakened()
	WorldState.mark_outer_god_resonance()
	if narrative_audio and narrative_audio.has_method("play_corrupted_lullaby"):
		narrative_audio.play_corrupted_lullaby()
	narrative.show_message(
		"SOMETHING ANSWERS",
		"No voice speaks.\n\nOnly warmth beneath Hero's skin.\n\nMite opens her eyes.\n\n\"Did you hear that?\"",
		6.0
	)
	await narrative.message_finished
	WorldState.input_locked = false

func _on_mite_interacted(_interaction_id: String, title: String, message: String) -> void:
	narrative.show_message(title, message, 7.0)
	if narrative_audio and narrative_audio.has_method("play_lullaby"):
		narrative_audio.play_lullaby()






func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		WorldState.delete_save()
		get_tree().change_scene_to_file("res://scenes/regions/escape_prologue.tscn")
		var viewport := get_viewport()
		if viewport:
			viewport.set_input_as_handled()
