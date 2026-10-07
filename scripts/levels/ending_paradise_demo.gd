extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const MITE_SCRIPT = preload("res://scripts/npc/mite.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const NARRATIVE_AUDIO_SCRIPT = preload("res://scripts/audio/narrative_audio.gd")
const HIGH_PRIEST_SCRIPT = preload("res://scripts/enemies/high_priest.gd")
const KING_SCRIPT = preload("res://scripts/enemies/king_guardian.gd")

const FLOOR_Y := 540.0
const WIDTH := 2600.0

var hero: CharacterBody2D
var mite: Node2D
var camera: Camera2D
var narrative: CanvasLayer
var hud: CanvasLayer
var audio_director: Node
var paradise := 0.0
var merged := false
var elapsed := 0.0
var fade: ColorRect
var boss: CharacterBody2D
var boss_stage := 0

func _ready() -> void:
    WorldState.current_location = "ending_paradise_demo"
    WorldState.physical_union_complete = true
    WorldState.outer_god_resonance = true

    _create_floor()
    _create_boundaries()
    _spawn_hero()
    _spawn_mite()
    _spawn_ui()
    _spawn_high_priest()
    _spawn_audio()

    # Union begins only after both monstrous institutional bosses are defeated.
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    paradise = clampf(paradise + delta * 0.035, 0.0, 1.0)
    queue_redraw()

func _spawn_hero() -> void:
    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.position = Vector2(760, FLOOR_Y)
    hero.name = "Hero"
    _add_character_collision(hero, 18.0, 48.0)
    add_child(hero)

    camera = Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 4.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = WIDTH
    camera.limit_bottom = 720
    hero.add_child(camera)

func _spawn_high_priest() -> void:
    boss_stage = 1
    boss = CharacterBody2D.new()
    boss.set_script(HIGH_PRIEST_SCRIPT)
    boss.position = Vector2(1500, FLOOR_Y)
    boss.name = "ParadiseHighPriest"
    _add_character_collision(boss, 24.0, 58.0)
    add_child(boss)
    boss.phase = 2
    boss.health = 190
    boss.defeated.connect(_on_high_priest_defeated)
    hud.bind_boss(boss)
    narrative.show_message(
        "THE LAST PRAYER",
        "The High Priest is no longer human.\n\nHe still bows.",
        3.5
    )

func _on_high_priest_defeated() -> void:
    boss_stage = 2
    _spawn_paradise_king()

func _spawn_paradise_king() -> void:
    boss = CharacterBody2D.new()
    boss.set_script(KING_SCRIPT)
    boss.position = Vector2(2050, FLOOR_Y)
    boss.name = "ParadiseKing"
    _add_character_collision(boss, 26.0, 62.0)
    add_child(boss)
    boss.phase = 2
    boss.health = 210
    boss.defeated.connect(_on_paradise_king_defeated)
    hud.bind_boss(boss)
    narrative.show_message(
        "THE LAST CROWN",
        "The King arrives already transformed.\n\nHe does not recognize the throne.",
        3.8
    )

func _on_paradise_king_defeated() -> void:
    boss_stage = 3
    narrative.show_message(
        "NO MORE KINGDOMS",
        "The Church falls.\n\nThe crown falls.\n\nNeither matters anymore.",
        3.8
    )
    get_tree().create_timer(4.0).timeout.connect(_begin_union)

func _spawn_mite() -> void:
    mite = Node2D.new()
    mite.set_script(MITE_SCRIPT)
    mite.position = Vector2(960, FLOOR_Y)
    mite.name = "Mite"
    add_child(mite)

func _spawn_ui() -> void:
    narrative = CanvasLayer.new()
    narrative.set_script(NARRATIVE_SCRIPT)
    add_child(narrative)

    hud = CanvasLayer.new()
    hud.set_script(HUD_SCRIPT)
    add_child(hud)
    hud.bind_hero(hero)
    hud.set_story_mode("ETERNAL GARDEN", "THERE IS NOWHERE ELSE TO GO")

func _spawn_audio() -> void:
    audio_director = Node.new()
    audio_director.set_script(NARRATIVE_AUDIO_SCRIPT)
    add_child(audio_director)

func _begin_union() -> void:
    WorldState.mark_physical_union_complete()
    narrative.show_message(
        "永恒乐园",
        "The world has become quiet.\n\nMite reaches for Hero's hand.\n\n\"We can stay.\"",
        4.5
    )
    get_tree().create_timer(4.8).timeout.connect(_begin_merge)

func _begin_merge() -> void:
    merged = true
    WorldState.ending_route = "永恒乐园"
    if audio_director and audio_director.has_method("play_lullaby"):
        audio_director.play_lullaby()

    narrative.show_message(
        "NO MORE DISTANCE",
        "The two figures stand together.\n\nThe edges of the room soften.\n\nThe village outside stops making noise.",
        4.5
    )

    get_tree().create_timer(4.8).timeout.connect(_finish)

func _finish() -> void:
    fade = ColorRect.new()
    fade.color = Color("#d8c9c0")
    fade.modulate.a = 0.0
    fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(fade)

    var tween := create_tween()
    tween.tween_property(fade, "modulate:a", 0.82, 3.0)

    narrative.show_message(
        "ETERNAL PARADISE",
        "No one is lonely.\n\nNo one is separate.\n\nNo one wakes.",
        7.0
    )

func _create_floor() -> void:
    var floor := StaticBody2D.new()
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(WIDTH + 200.0, 40.0)
    shape.shape = rectangle
    shape.position = Vector2(WIDTH * 0.5, FLOOR_Y + 20.0)
    floor.add_child(shape)
    add_child(floor)

func _create_boundaries() -> void:
    for x in [-20.0, WIDTH + 20.0]:
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
    var dream := Color("#b2a3b0")
    var sky := Color("#17141d").lerp(dream, paradise * 0.55)
    draw_rect(Rect2(0, 0, WIDTH, 720), sky)

    for i in range(30):
        var x := float((i * 173) % int(WIDTH))
        var y := 100.0 + float((i * 71) % 330)
        var radius := 2.0 + sin(elapsed * 0.7 + i) * 1.0
        draw_circle(Vector2(x, y), radius + paradise * 3.0, Color(0.88, 0.82, 0.88, 0.14))

    draw_rect(Rect2(0, FLOOR_Y, WIDTH, 180), Color("#24202a").lerp(Color("#d3c6cf"), paradise * 0.35))

    for x in range(180, 2450, 300):
        var sway := sin(elapsed * 0.45 + x) * 18.0
        draw_line(Vector2(x, FLOOR_Y), Vector2(x + sway, 300), Color("#3d3340").lerp(Color("#b9aeb7"), paradise * 0.45), 5.0)
        draw_circle(Vector2(x + sway, 300), 16.0 + paradise * 12.0, Color("#705f71", 0.16))

    if merged:
        draw_circle((hero.global_position + mite.global_position) * 0.5 + Vector2(0, -70), 90.0 + paradise * 80.0, Color(0.78, 0.72, 0.82, 0.08))

    draw_string(ThemeDB.fallback_font, Vector2(120, 220), "THE WORLD FORGETS HOW TO HURT", HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("#766a74"))
