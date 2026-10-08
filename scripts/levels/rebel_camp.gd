extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const ROUTE_NPC_SCRIPT = preload("res://scripts/npc/route_npc.gd")
const WORLD_CLUE_SCRIPT = preload("res://scripts/world/world_clue.gd")
const INTERIOR_EXIT_SCRIPT = preload("res://scripts/world/interior_exit.gd")
const NARRATIVE_AUDIO_SCRIPT = preload("res://scripts/audio/narrative_audio.gd")

var hero: CharacterBody2D
var camera: Camera2D
var narrative: CanvasLayer
var hud: CanvasLayer
var narrative_audio: Node

func _ready() -> void:
    WorldState.set_location("rebel_camp")
    _create_floor()
    _create_boundaries()
    _spawn_hero()
    _spawn_npcs()
    _spawn_clue()
    _spawn_exit()
    _spawn_ui()
    queue_redraw()

func _spawn_hero() -> void:
    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.position = Vector2(260, 520)
    hero.name = "Hero"
    _add_character_collision(hero, 18.0, 48.0)
    add_child(hero)

    camera = Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = 1900
    camera.limit_bottom = 720
    hero.add_child(camera)

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
    var npc := Node2D.new()
    npc.set_script(ROUTE_NPC_SCRIPT)
    npc.position = position
    npc.npc_id = npc_id
    npc.display_name = display_name
    npc.dialogue = dialogue
    add_child(npc)
    npc.interacted.connect(_on_npc_interacted.bind(npc))

func _spawn_clue() -> void:
    var clue := Node2D.new()
    clue.set_script(WORLD_CLUE_SCRIPT)
    clue.position = Vector2(1670, 520)
    clue.clue_id = "rebel_dead_letter"
    clue.display_name = "UNSENT ORDER"
    clue.humanity_delta = 1
    clue.description = "An unsigned order lies beneath a bloodstained map.\n\nThe first line reads: 'After the Church falls, do not let the soldiers choose the next priest.'\n\nThe rest has been burned away."
    add_child(clue)
    clue.examined.connect(_on_clue_examined.bind(clue))

func _spawn_exit() -> void:
    var exit := Area2D.new()
    exit.set_script(INTERIOR_EXIT_SCRIPT)
    exit.position = Vector2(1780, 520)
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(100, 130)
    shape.shape = rectangle
    shape.position = Vector2(0, -65)
    exit.add_child(shape)
    add_child(exit)
    exit.reached.connect(_on_exit_reached)

func _spawn_ui() -> void:
    narrative = CanvasLayer.new()
    narrative.set_script(NARRATIVE_SCRIPT)
    add_child(narrative)

    hud = CanvasLayer.new()
    hud.set_script(HUD_SCRIPT)
    add_child(hud)
    hud.bind_hero(hero)
    hud.set_story_mode("THE RESTORATION CAMP", "LISTEN BEFORE YOU CHOOSE WHOM TO TRUST")

    narrative_audio = Node.new()
    narrative_audio.set_script(NARRATIVE_AUDIO_SCRIPT)
    add_child(narrative_audio)

    get_tree().create_timer(0.7).timeout.connect(func() -> void:
        narrative.show_message(
            "THE RESTORATION CAMP",
            "There is no banner over the fire.\n\nOnly stolen weapons, borrowed horses and people waiting for a kingdom that no longer exists.",
            5.5
        )
    )

func _on_npc_interacted(npc: Node) -> void:
    narrative.show_message(npc.display_name, npc.dialogue, 7.0)

func _on_clue_examined(clue: Node) -> void:
    if clue.clue_id == "rebel_dead_letter":
        WorldState.record_hidden_artifact_source("rebel_dead_letter")
    narrative.show_message(clue.display_name, clue.description, 7.0)

func _on_exit_reached() -> void:
    narrative.show_message("BACK TO THE ROAD", "The camp keeps breathing behind you.", 3.0)
    await narrative.message_finished
    SceneTransition.fade_to_scene("res://scenes/village_hub.tscn")

func _create_floor() -> void:
    var floor := StaticBody2D.new()
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(1900, 40)
    shape.shape = rectangle
    shape.position = Vector2(950, 540)
    floor.add_child(shape)
    add_child(floor)

func _create_boundaries() -> void:
    for x in [-20.0, 1920.0]:
        var wall := StaticBody2D.new()
        var shape := CollisionShape2D.new()
        var rectangle := RectangleShape2D.new()
        rectangle.size = Vector2(40, 720)
        shape.shape = rectangle
        shape.position = Vector2(x, 360)
        wall.add_child(shape)
        add_child(wall)

func _add_character_collision(character: CharacterBody2D, radius: float, height: float) -> void:
    var collision := CollisionShape2D.new()
    var capsule := CapsuleShape2D.new()
    capsule.radius = radius
    capsule.height = height
    collision.shape = capsule
    collision.position = Vector2(0, -height * 0.5)
    character.add_child(collision)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
        WorldState.delete_save()
        get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")
        get_viewport().set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1900, 720), Color("#100f13"))
    draw_rect(Rect2(0, 520, 1900, 200), Color("#201a22"))

    for x in range(120, 1750, 320):
        draw_line(Vector2(x, 520), Vector2(x + 35, 410), Color("#30262e"), 8.0)
        draw_line(Vector2(x + 20, 470), Vector2(x + 72, 395), Color("#342a31"), 5.0)

    draw_circle(Vector2(570, 470), 85.0, Color("#302127"))
    draw_circle(Vector2(570, 470), 52.0, Color("#63322f"))

    for x in [720.0, 1050.0, 1380.0]:
        draw_rect(Rect2(x - 80, 360, 160, 160), Color("#26212a"))
        draw_colored_polygon(
            PackedVector2Array([
                Vector2(x - 95, 360),
                Vector2(x, 270),
                Vector2(x + 95, 360)
            ]),
            Color("#302832")
        )

    draw_string(ThemeDB.fallback_font, Vector2(100, 230), NereisLocalization.translate_text("THE RESTORATION CAMP"), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#6c5d64"))
    draw_string(ThemeDB.fallback_font, Vector2(480, 450), NereisLocalization.translate_text("NO KING / NO CHURCH"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#8d7776"))
