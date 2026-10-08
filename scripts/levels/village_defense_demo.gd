extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const BANDIT_SCRIPT = preload("res://scripts/enemies/bandit_raider.gd")
const INQUISITOR_SCRIPT = preload("res://scripts/enemies/church_inquisitor.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const NARRATIVE_AUDIO_SCRIPT = preload("res://scripts/audio/narrative_audio.gd")

const FLOOR_Y := 540.0
const LEVEL_WIDTH := 3600.0

var hero: CharacterBody2D
var camera: Camera2D
var narrative: CanvasLayer
var hud: CanvasLayer
var narrative_audio: Node
var attackers: Array[CharacterBody2D] = []
var defeated := 0
var stage := 0
var spawn_timer := 0.0
var wave_started := false

func _ready() -> void:
    WorldState.current_location = "village_defense_demo"
    _create_floor()
    _create_boundaries()
    _spawn_hero()
    _spawn_ui()
    narrative_audio = Node.new()
    narrative_audio.set_script(NARRATIVE_AUDIO_SCRIPT)
    add_child(narrative_audio)

    get_tree().create_timer(0.8).timeout.connect(_begin_attack)
    queue_redraw()

func _spawn_hero() -> void:
    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.position = Vector2(420, FLOOR_Y)
    hero.name = "Hero"
    _add_character_collision(hero, 18.0, 48.0)
    add_child(hero)
    hero.defeated.connect(_on_hero_defeated)

    camera = Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = LEVEL_WIDTH
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
    hud.set_story_mode("THE VILLAGE", "PROTECT THE VILLAGE")

func _begin_attack() -> void:
    wave_started = true
    if narrative_audio and narrative_audio.has_method("play_corrupted_lullaby"):
        narrative_audio.play_corrupted_lullaby()
    narrative.show_message(
        "THE ATTACK",
        "Torches appear beyond the fields.\n\nThe Church came with the bandits.\n\nNo one asks the Hero to fight. He simply draws his sword.",
        5.0
    )
    await narrative.message_finished
    _spawn_wave()

func _spawn_wave() -> void:
    stage = 1
    _spawn_attackers([
        ["bandit", Vector2(1380, FLOOR_Y)],
        ["bandit", Vector2(1520, FLOOR_Y)],
        ["inquisitor", Vector2(1780, FLOOR_Y)]
    ])
    narrative.show_message("THE FIRST WAVE", "They are coming for the houses behind you.", 3.0)

func _spawn_attackers(definitions: Array) -> void:
    for definition in definitions:
        var kind: String = definition[0]
        var position: Vector2 = definition[1]
        var enemy: CharacterBody2D = CharacterBody2D.new()
        if kind == "bandit":
            enemy.set_script(BANDIT_SCRIPT)
            _add_character_collision(enemy, 20.0, 44.0)
        else:
            enemy.set_script(INQUISITOR_SCRIPT)
            _add_character_collision(enemy, 22.0, 50.0)
        enemy.position = position
        enemy.name = "%s_%d" % [kind, attackers.size()]
        add_child(enemy)
        enemy.defeated.connect(_on_attacker_defeated)
        attackers.append(enemy)

func _on_attacker_defeated() -> void:
    defeated += 1
    if defeated == 3 and stage == 1:
        stage = 2
        get_tree().create_timer(0.7).timeout.connect(_spawn_second_wave)
    elif defeated == 7 and stage == 2:
        _finish_defense()

func _spawn_second_wave() -> void:
    _spawn_attackers([
        ["bandit", Vector2(2080, FLOOR_Y)],
        ["bandit", Vector2(2240, FLOOR_Y)],
        ["inquisitor", Vector2(2380, FLOOR_Y)],
        ["inquisitor", Vector2(2520, FLOOR_Y)]
    ])
    narrative.show_message("THE SECOND WAVE", "The first line breaks.\n\nThere are more behind it.", 3.2)

func _finish_defense() -> void:
    stage = 3
    WorldState.current_location = "village"
    narrative.show_message(
        "AFTER THE FIRE",
        "The attackers retreat.\n\nThe village is still standing.\n\nFor tonight, that is enough.",
        4.5
    )
    await narrative.message_finished
    SceneTransition.fade_to_scene("res://scenes/village_hub.tscn")

func _on_hero_defeated() -> void:
    for attacker in attackers:
        if is_instance_valid(attacker) and not attacker.is_queued_for_deletion():
            attacker.queue_free()
    attackers.clear()
    defeated = 0
    stage = 0
    wave_started = false
    narrative.show_message("THE VILLAGE FALLS QUIET", "The Hero rises again.\n\nThe attack has not ended.", 3.0)
    await narrative.message_finished
    _begin_attack()

func _create_floor() -> void:
    var floor := StaticBody2D.new()
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(LEVEL_WIDTH + 200, 40)
    shape.shape = rectangle
    shape.position = Vector2(LEVEL_WIDTH * 0.5, FLOOR_Y + 20)
    floor.add_child(shape)
    add_child(floor)

func _create_boundaries() -> void:
    for x in [-20.0, LEVEL_WIDTH + 20.0]:
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
        _mark_input_handled()
        WorldState.delete_save()
        get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")

func _mark_input_handled() -> void:
    var viewport := get_viewport()
    if viewport != null:
        viewport.set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(0, 0, LEVEL_WIDTH, 720), Color("#130f13"))
    draw_rect(Rect2(0, FLOOR_Y, LEVEL_WIDTH, 180), Color("#211a22"))

    for x in range(100, 3400, 360):
        draw_rect(Rect2(x, 370, 150, 150), Color("#2a242c"))
        draw_colored_polygon(
            PackedVector2Array([
                Vector2(x - 20, 370),
                Vector2(x + 75, 285),
                Vector2(x + 170, 370)
            ]),
            Color("#352d38")
        )
    draw_string(ThemeDB.fallback_font, Vector2(120, 230), NereisLocalization.translate_text("THE VILLAGE BURNS AT THE EDGES"), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#6f5e63"))
