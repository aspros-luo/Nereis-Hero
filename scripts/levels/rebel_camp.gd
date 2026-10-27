extends Node2D

const ROUTE_NPC_SCENE: PackedScene = preload("res://scenes/npc/route_npc.tscn")

@onready var hero: CharacterBody2D = $Hero
@onready var narrative: CanvasLayer = $NarrativeManager
@onready var hud: CanvasLayer = $HUD
@onready var narrative_audio: Node = $NarrativeAudio
@onready var clue: Node2D = $UnsentOrderClue
@onready var exit: Area2D = $CampExit

func _ready() -> void:
	WorldState.set_location("rebel_camp")
	clue.examined.connect(_on_clue_examined.bind(clue))
	exit.reached.connect(_on_exit_reached)
	hud.bind_hero(hero)
	hud.set_story_mode("THE RESTORATION CAMP", "LISTEN BEFORE YOU CHOOSE WHOM TO TRUST")
	get_tree().create_timer(0.7).timeout.connect(func() -> void:
		narrative.show_message(
			"THE RESTORATION CAMP",
			"There is no banner over the fire.\n\nOnly stolen weapons, borrowed horses and people waiting for a kingdom that no longer exists.",
			5.5
		)
	)

func _spawn_npcs() -> void:
    _spawn_npc(
        Vector2(780, 520),
        "restoration_captain",
        "RESTORATION CAPTAIN",
        "The captain studies your church-marked blade.\n\n\"We are not here because we are righteous.\"\n\n\"We are here because the throne is ours.\"\n\nThere is no pride in the last sentence."
    )

    _spawn_npc(
        Vector2(1120, 520),
        "rebel_quartermaster",
        "QUARTERMASTER",
        "The quartermaster counts bandages twice.\n\n\"If the Kingdom returns, food still has to be bought.\"\n\n\"People forget that when they start talking about crowns.\""
    )

    _spawn_npc(
        Vector2(1450, 520),
        "royal_survivor",
        "ROYAL SURVIVOR",
        "The old soldier never looks toward the campfire.\n\n\"The Church taught us obedience.\"\n\n\"The rebels will teach us loyalty.\"\n\nHe spits into the dirt."
    )

func _spawn_npc(position: Vector2, npc_id: String, display_name: String, dialogue: String) -> void:
	var npc := ROUTE_NPC_SCENE.instantiate() as Node2D
	npc.position = position
	npc.set("npc_id", npc_id)
	npc.set("display_name", display_name)
	npc.set("dialogue", dialogue)
	add_child(npc)
	npc.interacted.connect(_on_npc_interacted.bind(npc))



func _on_npc_interacted(npc: Node) -> void:
    narrative.show_message(npc.display_name, npc.dialogue, 7.0)

func _on_clue_examined(clue: Node) -> void:
    if clue.clue_id == "rebel_dead_letter":
        WorldState.record_hidden_artifact_source("rebel_dead_letter")
    narrative.show_message(clue.display_name, clue.description, 7.0)

func _on_exit_reached() -> void:
    narrative.show_message("BACK TO THE ROAD", "The camp keeps breathing behind you.", 3.0)
    await narrative.message_finished
    SceneTransition.fade_to_scene("res://scenes/regions/village_hub.tscn")




func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
        WorldState.delete_save()
        get_tree().change_scene_to_file("res://scenes/regions/escape_prologue.tscn")
        get_viewport().set_input_as_handled()
