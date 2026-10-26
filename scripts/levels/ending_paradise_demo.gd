extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const MITE_SCRIPT = preload("res://scripts/npc/mite.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const NARRATIVE_AUDIO_SCRIPT = preload("res://scripts/audio/narrative_audio.gd")
const HIGH_PRIEST_SCRIPT = preload("res://scripts/enemies/high_priest.gd")
const KING_SCRIPT = preload("res://scripts/enemies/king_guardian.gd")
const ENDING_OVERLAY_SCENE: PackedScene = preload("res://scenes/ui/ending_sequence_overlay.tscn")

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
var ending_layer: CanvasLayer
var ending_backdrop: ColorRect
var ending_card: ColorRect
var ending_title: Label
var ending_body: Label
var ending_prompt: Label
var ending_active := false
var ending_stage := -1
var ending_stage_elapsed := 0.0
var ending_can_exit := false
var ending_cg: Control

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    WorldState.current_location = "ending_paradise_demo"

    _create_floor()
    _create_boundaries()
    _spawn_hero()
    _spawn_mite()
    _spawn_ui()
    _spawn_high_priest()
    _spawn_audio()

    # The cosmic ending follows from Resonance and exploration, not a relationship milestone.
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    paradise = clampf(paradise + delta * 0.035, 0.0, 1.0)
    if ending_active:
        ending_stage_elapsed += delta
        if ending_stage < 3 and ending_stage_elapsed >= 5.5:
            _advance_ending_stage()
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
    boss.max_health = 190
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
    boss.max_health = 210
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
    await narrative.message_finished
    _begin_paradise_ending()
    ending_active = true

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

func _begin_paradise_ending() -> void:
    WorldState.ending_route = "永恒乐园"
    WorldState.save_game()
    if audio_director and audio_director.has_method("play_corrupted_lullaby"):
        audio_director.play_corrupted_lullaby()

    WorldState.input_locked = true
    if hud:
        hud.visible = false
    if narrative:
        narrative.visible = false

    if is_instance_valid(boss):
        boss.queue_free()
        boss = null

    _create_ending_overlay()
    _show_ending_stage(0)

func _create_ending_overlay() -> void:
    ending_layer = ENDING_OVERLAY_SCENE.instantiate() as CanvasLayer
    add_child(ending_layer)
    ending_layer.visible = true
    ending_backdrop = ending_layer.get_node("Backdrop") as ColorRect
    ending_cg = ending_layer.get_node("CGOverlay") as Control
    ending_card = ending_layer.get_node("Card") as ColorRect
    ending_title = ending_layer.get_node("Card/Title") as Label
    ending_body = ending_layer.get_node("Card/Body") as Label
    ending_prompt = ending_layer.get_node("Card/Prompt") as Label
    var top_rule := ending_layer.get_node("Card/TopRule") as ColorRect
    var bottom_rule := ending_layer.get_node("Card/BottomRule") as ColorRect
    ending_backdrop.color = Color("#0a0810")
    ending_backdrop.modulate.a = 0.0
    ending_card.color = Color("#e6d9df", 0.42)
    ending_card.modulate.a = 0.0
    top_rule.color = Color("#6f596d")
    bottom_rule.color = top_rule.color
    ending_title.add_theme_font_size_override("font_size", 38)
    ending_title.add_theme_color_override("font_color", Color("#342b3b"))
    ending_body.add_theme_font_size_override("font_size", 24)
    ending_body.add_theme_color_override("font_color", Color("#514453"))
    ending_prompt.add_theme_font_size_override("font_size", 15)
    ending_prompt.add_theme_color_override("font_color", Color("#6f596d"))
    ending_cg.call("setup", "paradise")
    ending_cg.call("play")


func _show_ending_stage(stage: int) -> void:
    ending_stage = stage
    ending_stage_elapsed = 0.0
    ending_can_exit = false

    match stage:
        0:
            ending_title.text = "永恒乐园"
            ending_body.text = "The kingdom is gone.\nThe Church is gone.\nThere is nothing left that can call Hero back."
            ending_prompt.text = "The road behind you has disappeared."
            _tween_ending_in()
        1:
            ending_title.text = "THE LAST HAND"
            ending_body.text = "Mite reaches for Hero.\n\nShe is smiling like the night is ordinary.\n\n\"We can stay.\""
            ending_prompt.text = "No kingdom.  No duty.  No distance."
            _tween_ending_card()
        2:
            ending_title.text = "NO MORE DISTANCE"
            ending_body.text = "The two figures stand together.\n\nThe room softens.\nThe village stops making noise.\nThe boundary between dream and waking disappears."
            ending_prompt.text = "Something beyond the room has answered."
            _tween_ending_card()
        3:
            ending_title.text = "ETERNAL PARADISE"
            if ending_cg and ending_cg.has_method("pulse"):
                ending_cg.pulse()
            ending_body.text = "No one is lonely.\n\nNo one is separate.\n\nNo one wakes."
            ending_prompt.text = "ENDING COMPLETE    E / ENTER  Return to Title    F9  Restart"
            ending_can_exit = true
            _tween_ending_card()

func _tween_ending_in() -> void:
    ending_backdrop.modulate.a = 0.0
    ending_card.modulate.a = 0.0
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(ending_backdrop, "modulate:a", 0.86, 2.0)
    tween.tween_property(ending_card, "modulate:a", 1.0, 1.8)
    tween.set_parallel(false)

func _tween_ending_card() -> void:
    var tween := create_tween()
    ending_card.modulate.a = 0.0
    tween.tween_property(ending_card, "modulate:a", 1.0, 0.9)

func _advance_ending_stage() -> void:
    if not ending_active:
        return
    if ending_stage < 3:
        if ending_stage == 1:
            merged = true
        _show_ending_stage(ending_stage + 1)

func _return_from_ending() -> void:
    WorldState.input_locked = false
    WorldState.save_game()
    ending_active = false
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/boot.tscn")

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
    if not (event is InputEventKey and event.pressed and not event.echo):
        return

    if ending_active:
        if event.keycode in [KEY_E, KEY_ENTER, KEY_SPACE]:
            _mark_input_handled()
            if ending_can_exit:
                _return_from_ending()
            else:
                if ending_stage < 3:
                    if ending_stage == 1:
                        merged = true
                    _show_ending_stage(ending_stage + 1)
            return

    if event.keycode == KEY_F9:
        _mark_input_handled()
        WorldState.delete_save()
        get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")

func _mark_input_handled() -> void:
    var viewport := get_viewport()
    if viewport != null:
        viewport.set_input_as_handled()

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

    draw_string(ThemeDB.fallback_font, Vector2(120, 220), NereisLocalization.translate_text("THE WORLD FORGETS HOW TO HURT"), HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("#766a74"))
