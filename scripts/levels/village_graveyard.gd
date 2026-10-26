extends Node2D

const WRAITH_SCENE: PackedScene = preload("res://scenes/enemies/bell_wraith.tscn")

@onready var hero: CharacterBody2D = $Hero
var wraiths: Array[CharacterBody2D] = []
@onready var checkpoint: Area2D = $GraveyardCheckpoint
@onready var narrative: CanvasLayer = $NarrativeManager
@onready var hud: CanvasLayer = $HUD
@onready var exit: Area2D = $GraveyardExit
@onready var clue: Node2D = $GravestoneClue
@onready var bell_keeper: Node2D = $BellKeeper

func _ready() -> void:
	WorldState.prepare_scene_runtime()
	WorldState.set_location("graveyard")
	WorldState.set_checkpoint(Vector2(360, 520))
	print("[NEREIS][GRAVEYARD] Entered Village Graveyard route=%s" % WorldState.selected_route)
	hero.defeated.connect(_on_hero_defeated)
	clue.examined.connect(_on_clue_examined.bind(clue))
	bell_keeper.interacted.connect(_on_bell_keeper_interacted)
	exit.reached.connect(_on_exit_reached)
	hud.bind_hero(hero)
	if not WorldState.graveyard_cleared:
		_spawn_wraith(Vector2(1100, 430), "BellWraith_A")
		_spawn_wraith(Vector2(1480, 390), "BellWraith_B")
	get_tree().create_timer(0.6).timeout.connect(_show_intro)


func _spawn_wraith(spawn_position: Vector2, wraith_name: String) -> void:
	var wraith := WRAITH_SCENE.instantiate() as CharacterBody2D
	wraith.position = spawn_position
	wraith.name = wraith_name
	add_child(wraith)
	wraith.defeated.connect(_on_wraith_defeated.bind(wraith))
	wraiths.append(wraith)


func _on_bell_keeper_interacted(title: String, message: String) -> void:
    narrative.show_message(title, message, 7.0)



func _show_intro() -> void:
    if WorldState.graveyard_cleared:
        narrative.show_message(
            "THE SILENT BELL",
            "The bell tower is quiet now.\n\nYou are certain it rang after you left.",
            5.0
        )
    else:
        narrative.show_message(
            "THE VILLAGE GRAVEYARD",
            "The graves are too old for the names carved into them.\n\nThe bell tower is silent. Something beneath it is not.",
            6.0
        )

func _on_wraith_defeated(wraith: Node) -> void:
    _log("COMBAT", "Graveyard encounter defeated: %s" % wraith.name)
    if is_instance_valid(wraith):
        wraiths.erase(wraith)
    if wraiths.is_empty() and not WorldState.graveyard_cleared:
        WorldState.mark_graveyard_cleared()
        narrative.show_message(
            "THE BELL",
            "Both wraiths collapse.\n\nThe silent tower rings once. No bell moves.",
            6.0
        )

func _on_hero_defeated() -> void:
    if WorldState.graveyard_cleared:
        return
    for wraith in wraiths:
        if is_instance_valid(wraith) and not wraith.is_queued_for_deletion():
            wraith.queue_free()
    wraiths.clear()
    _spawn_wraith(Vector2(1100, 430), "BellWraith_A")
    _spawn_wraith(Vector2(1480, 390), "BellWraith_B")
    print("[NEREIS][GRAVEYARD] Hero defeated; wraith encounter state reset")

func _on_clue_examined(target: Node) -> void:
    narrative.show_message(target.display_name, target.description, 7.0)

func _on_exit_reached() -> void:
    WorldState.set_location("village")
    narrative.show_message("BACK TO THE VILLAGE", "The cemetery gate closes behind you.", 3.0)
    await narrative.message_finished
    _return_to_village()

func _return_to_village() -> void:
    SceneTransition.fade_to_scene("res://scenes/village_hub.tscn")




func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
        WorldState.delete_save()
        print("[NEREIS][DEBUG] Graveyard reset; returning to Vertical Slice")
        get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")
        get_viewport().set_input_as_handled()
