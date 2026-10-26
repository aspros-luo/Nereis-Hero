extends Node2D

const RESEARCH_HUSK_SCENE: PackedScene = preload("res://scenes/enemies/research_husk.tscn")

const FLOOR_Y := 540.0

@onready var hero: CharacterBody2D = $Hero
@onready var camera: Camera2D = $Hero/HeroCamera
@onready var husk: CharacterBody2D = $ResearchHusk
@onready var narrative: CanvasLayer = $Narrative
@onready var hud: CanvasLayer = $HUD
@onready var fluid_vial: Node2D = $FluidVial
@onready var sealed_hair: Node2D = $SealedHair
@onready var vessel_ledger: Node2D = $VesselLedger
@onready var exit_area: Area2D = $Exit

var cleared := false


func _ready() -> void:
    WorldState.set_location("ancient_lab")
    WorldState.set_checkpoint(Vector2(300, FLOOR_Y))

    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = 2400
    camera.limit_bottom = 720

    hero.defeated.connect(_on_hero_defeated)
    husk.defeated.connect(_on_husk_defeated)
    fluid_vial.examined.connect(_on_clue_examined.bind(fluid_vial))
    sealed_hair.examined.connect(_on_clue_examined.bind(sealed_hair))
    vessel_ledger.examined.connect(_on_clue_examined.bind(vessel_ledger))
    exit_area.reached.connect(_on_exit_reached)

    hud.bind_hero(hero)
    hud.set_story_mode("ANCIENT RESEARCH WARD", "SEARCH THE ROOM / LEAVE WITH WHAT YOU CAN BEAR")
    get_tree().create_timer(0.7).timeout.connect(_show_intro)


func _show_intro() -> void:
    narrative.show_message(
        "THE RESEARCH WARD",
        "There are no prayers here.\n\nOnly instruments polished often enough to look sacred.",
        4.5
    )


func _on_husk_defeated() -> void:
    cleared = true
    WorldState.record_hidden_artifact_source("ancient_lab")
    narrative.show_message(
        "THE VESSEL",
        "The thing collapses.\n\nBeneath its ribs, a metal hook remains embedded in bone.\n\nThe hook is shaped for something much larger than the body it came from.",
        6.0
    )


func _on_clue_examined(clue: Node) -> void:
    if clue.clue_id in ["ancient_fluid_vial", "ancient_hair_bundle", "ancient_vessel_ledger"]:
        WorldState.record_hidden_artifact_source("ancient_lab")
    narrative.show_message(clue.display_name, clue.description, 7.0)


func _on_hero_defeated() -> void:
    if cleared:
        return
    if is_instance_valid(husk):
        husk.queue_free()
    husk = null
    get_tree().create_timer(0.5).timeout.connect(_spawn_husk)


func _spawn_husk() -> void:
    if cleared:
        return
    var instance := RESEARCH_HUSK_SCENE.instantiate() as CharacterBody2D
    if instance == null:
        push_error("Ancient Research Lab: failed to instantiate ResearchHusk scene")
        return
    instance.name = "ResearchHusk"
    instance.position = Vector2(1250, FLOOR_Y)
    add_child(instance)
    husk = instance
    husk.defeated.connect(_on_husk_defeated)


func _on_exit_reached() -> void:
    WorldState.set_location("church")
    SceneTransition.fade_to_scene("res://scenes/locations/church_interior.tscn")


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
        _mark_input_handled()
        WorldState.delete_save()
        get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")


func _mark_input_handled() -> void:
    var viewport := get_viewport()
    if viewport != null:
        viewport.set_input_as_handled()

