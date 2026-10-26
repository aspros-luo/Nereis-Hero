extends Node2D

@export var location_id: String = "tavern"
@onready var hero: CharacterBody2D = $Hero
@onready var camera: Camera2D = $Hero/HeroCamera
@onready var narrative: CanvasLayer = $NarrativeManager
@onready var hud: CanvasLayer = $HUD
@onready var exit: Area2D = $InteriorExit
@onready var checkpoint: Area2D = $InteriorCheckpoint
@onready var clue: Node2D = $InteriorClue
@onready var rest_point: Node2D = $RestPoint
@onready var mite: Node2D = $Mite
@onready var narrative_audio: Node = $NarrativeAudio
@onready var route_door: Area2D = $InvestigationDoor
@onready var world_event_director: Node = $WorldEventDirector
@onready @onready var research_door: Area2D = $ResearchDoor
@onready var tavern_keeper: Node2D = $TavernKeeper = $ResearchDoor
func _ready() -> void:
	WorldState.prepare_scene_runtime()
	WorldState.set_location(location_id)
	world_event_director.setup(WorldState, self)
	hero.position = Vector2(260, 520)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1800
	camera.limit_bottom = 720
	checkpoint.position = Vector2(260, 520)
	WorldState.set_checkpoint(Vector2(260, 520))
	var church_occupied := "church_village_occupied" in WorldState.achievement_flags
	if location_id != "church" or church_occupied:
		_spawn_npc()
		world_event_director.spawn_npcs(self, Callable(self, "_on_npc_interacted"))
		_spawn_clue()
		_spawn_route_door()
		_spawn_research_door()
	else:
		tavern_keeper.visible = false
		clue.visible = false
		route_door.visible = false
		route_door.monitoring = false
		(route_door.get_node("CollisionShape2D") as CollisionShape2D).disabled = true
		research_door.visible = false
		research_door.monitoring = false
		(research_door.get_node("CollisionShape2D") as CollisionShape2D).disabled = true
	_spawn_mite_if_present()
	_spawn_rest_point()
	_spawn_exit()
	_spawn_ui()
	$TavernArchitecture.visible = location_id == "tavern"
	$ChurchArchitecture.visible = location_id == "church"


func _spawn_npc() -> void:
	if location_id != "tavern":
		tavern_keeper.visible = false
		return
	tavern_keeper.visible = true
	tavern_keeper.position = Vector2(900, 520)
	tavern_keeper.set("cloth_color", Color("#69404a"))
	tavern_keeper.set("npc_id", "tavern_keeper")
	tavern_keeper.set("display_name", "酒馆值夜人")
	if "A1_tavern_sound_noticed" in WorldState.achievement_flags and "village_defense_survived" in WorldState.achievement_flags:
		tavern_keeper.set("dialogue", "值夜人看了看你，又瞥向已经安静下来的北门方向。\n\n“你听见过那声音，也看见过北门外的事。两件事不一定有关——至少我没打算替你把它们连起来。”")
	elif "A1_tavern_sound_noticed" in WorldState.achievement_flags:
		tavern_keeper.set("dialogue", "值夜人看了你一眼，又低头擦杯子。\n\n“你上次听见的声音？我没说那是歌。你自己确定就好。”")
	elif "village_defense_survived" in WorldState.achievement_flags:
		tavern_keeper.set("dialogue", "值夜人把杯子放回架上。\n\n“北门那边总算安静了些。今晚的灯会一直亮着，但我可不保证每个故事都是真的。”")
	else:
		tavern_keeper.set("dialogue", "值夜人把杯子擦干，朝门口点点头。\n\n“进来暖暖身子吧。村里白天说的话，到了夜里往往就不一样了。”")
	tavern_keeper.interacted.connect(_on_npc_interacted.bind(tavern_keeper))
func _spawn_mite_if_present() -> void:
	if location_id != "tavern" or WorldState.mite_connection_missed or not WorldState.mite_first_meeting:
		mite.visible = false
		return
	mite.visible = true
	mite.position = Vector2(650, 520)
	mite.interacted.connect(_on_mite_interacted)
func _on_mite_interacted(_interaction_id: String, title: String, message: String) -> void:
    narrative.show_message(title, message, 7.0)
    if narrative_audio and narrative_audio.has_method("play_lullaby"):
        narrative_audio.play_lullaby()

func _spawn_clue() -> void:
	clue.visible = true
	if location_id == "tavern":
		clue.position = Vector2(1120, 520)
		clue.set("clue_id", "tavern_silver_bell")
		clue.set("humanity_delta", 2)
		clue.set("display_name", "SILVER BELL")
		clue.set("description", "The bell is cold to the touch.\n\nWhen you lift it, you remember a hand placing a cup in front of you. The hand is yours.")
	else:
		clue.position = Vector2(1260, 520)
		clue.set("clue_id", "church_confession_book")
		clue.set("humanity_delta", -5)
		clue.set("display_name", "CONFESSION BOOK")
		clue.set("description", "The book contains your handwriting.\n\nThe last entry ends with one sentence: \"I agreed because they promised she would live.\"")
	clue.examined.connect(_on_clue_examined.bind(clue))
func _on_clue_examined(target: Node) -> void:
    narrative.show_message(target.display_name, target.description, 7.0)

func _spawn_rest_point() -> void:
	if location_id != "tavern":
		rest_point.visible = false
		return
	rest_point.visible = true
	rest_point.position = Vector2(1460, 520)
	rest_point.set("rest_id", "tavern_bench")
	rest_point.set("display_name", "A QUIET BENCH")
	rest_point.rested.connect(_on_rest_point_used)
func _on_rest_point_used() -> void:
    narrative.show_message("A MOMENT OF QUIET", "For once, nothing asks you to remember.", 4.0)


func _spawn_exit() -> void:
	exit.position = Vector2(1660, 520)
	exit.reached.connect(_on_exit_reached)
func _spawn_route_door() -> void:
	if location_id == "church" and "church_village_occupied" not in WorldState.achievement_flags:
		route_door.visible = false
		route_door.monitoring = false
		(route_door.get_node("CollisionShape2D") as CollisionShape2D).disabled = true
		return
	route_door.visible = true
	route_door.monitoring = true
	route_door.position = Vector2(1350, 520)
	route_door.set("prompt_text", "E  Enter")
	var collision := route_door.get_node("CollisionShape2D") as CollisionShape2D
	var rectangle := collision.shape as RectangleShape2D
	rectangle.size = Vector2(100, 130)
	collision.position = Vector2(0, -65)
	collision.disabled = false
	route_door.interacted.connect(_on_route_door_interacted)
func _on_route_door_interacted() -> void:
    if WorldState.input_locked:
        return
    if location_id == "church":
        WorldState.selected_route = "church"
        WorldState.set_location("route_church")
        narrative.show_message("THE ARCHIVES", "The door was never meant for the faithful.\n\nYour name is scratched into the stone beside the lock.", 4.0)
        await narrative.message_finished
        SceneTransition.fade_to_scene("res://scenes/routes/church_path.tscn")
    elif location_id == "tavern":
        WorldState.selected_route = "lullaby"
        WorldState.set_location("route_lullaby")
        narrative.show_message("THE BACK ROAD", "Behind the tavern is a path no map remembers.\n\nYou can hear the song again.", 4.0)
        await narrative.message_finished
        SceneTransition.fade_to_scene("res://scenes/routes/lullaby_path.tscn")

func _spawn_research_door() -> void:
	if location_id != "church" or "church_village_occupied" not in WorldState.achievement_flags:
		research_door.visible = false
		research_door.monitoring = false
		(research_door.get_node("CollisionShape2D") as CollisionShape2D).disabled = true
		return
	research_door.visible = true
	research_door.monitoring = true
	research_door.position = Vector2(1020, 520)
	research_door.set("prompt_text", "E  Enter")
	var collision := research_door.get_node("CollisionShape2D") as CollisionShape2D
	var rectangle := collision.shape as RectangleShape2D
	rectangle.size = Vector2(80, 130)
	collision.position = Vector2(0, -65)
	collision.disabled = false
	research_door.interacted.connect(_on_research_door_interacted)
func _on_research_door_interacted() -> void:
    if WorldState.input_locked:
        return
    WorldState.set_location("ancient_lab")
    narrative.show_message("THE LOCKED STAIR", "The stone gives way beneath your hand.\n\nThere should not be a room underneath a village church.", 4.2)
    await narrative.message_finished
    SceneTransition.fade_to_scene("res://scenes/ancient_research_lab.tscn")

func _spawn_ui() -> void:
	hud.bind_hero(hero)
	get_tree().create_timer(0.6).timeout.connect(_show_intro)
func _show_intro() -> void:
    if location_id == "tavern" and WorldState.mite_connection_missed:
        narrative.show_message(
            "THE EMPTY TABLE",
            "The chair near the window is empty.\n\nSomeone has left a cup there anyway.",
            4.5
        )
        return
    if location_id == "tavern":
        narrative.show_message("THE TAVERN", "The room is warmer than the road.\n\nSomewhere behind the bar, a glass is placed down by a hand you cannot see.", 6.0)
    elif location_id == "church" and "church_village_occupied" not in WorldState.achievement_flags:
        narrative.show_message("教堂", "教堂里没有神职人员，也没有可供调查的物品。\n\n空荡的长椅朝向一座没有点燃蜡烛的祭台。\n\n这里要等到后续剧情节点才会有人到来。", 6.0)
    else:
        narrative.show_message("教堂", "旧木椅整齐地排在空旷的长厅里。\n\n没有人回应你的脚步，只有灰尘在高窗下缓慢浮动。", 6.0)

func _on_npc_interacted(npc: Node) -> void:
    narrative.show_message(npc.display_name, npc.dialogue, 6.0)

func _on_exit_reached() -> void:
    WorldState.set_location("village")
    narrative.show_message("BACK TO THE VILLAGE", "The village waits outside.", 3.0)
    await narrative.message_finished
    _return_to_village()

func _return_to_village() -> void:
    SceneTransition.fade_to_scene("res://scenes/village_hub.tscn")




func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
        WorldState.delete_save()
        print("[NEREIS][DEBUG] Interior run reset; returning to Vertical Slice")
        get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")
        get_viewport().set_input_as_handled()
