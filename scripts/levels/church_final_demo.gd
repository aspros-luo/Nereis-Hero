extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HIGH_PRIEST_SCRIPT = preload("res://scripts/enemies/high_priest.gd")
const KING_SCRIPT = preload("res://scripts/enemies/king_guardian.gd")
const ENDING_OVERLAY_SCENE: PackedScene = preload("res://scenes/ui/ending_sequence_overlay.tscn")

const FLOOR_Y := 540.0
const LEVEL_WIDTH := 4400.0

var hero: CharacterBody2D
var camera: Camera2D
var hud: CanvasLayer
var narrative: CanvasLayer
var boss: CharacterBody2D
var phase := 0
var epilogue_started := false
var epilogue_elapsed := 0.0
var ending_layer: CanvasLayer
var ending_backdrop: ColorRect
var ending_card: ColorRect
var ending_title: Label
var ending_body: Label
var ending_prompt: Label
var ending_stage := -1
var ending_stage_elapsed := 0.0
var ending_can_exit := false
var ending_cg: Control

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    WorldState.current_location = "church_final_demo"
    _create_floor()
    _create_boundaries()
    _spawn_hero()
    _spawn_hud()
    _spawn_narrative()
    _spawn_priest()
    get_tree().create_timer(0.8).timeout.connect(_show_intro)
    queue_redraw()

func _spawn_hero() -> void:
    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.position = Vector2(320, FLOOR_Y)
    hero.name = "Hero"
    _add_character_collision(hero, 18.0, 48.0)
    add_child(hero)

    camera = Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.5
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = LEVEL_WIDTH
    camera.limit_bottom = 720
    hero.add_child(camera)

func _spawn_hud() -> void:
    hud = CanvasLayer.new()
    hud.set_script(HUD_SCRIPT)
    add_child(hud)
    hud.bind_hero(hero)
    hud.set_debug_visible(false)

func _spawn_narrative() -> void:
    narrative = CanvasLayer.new()
    narrative.set_script(NARRATIVE_SCRIPT)
    add_child(narrative)

func _spawn_priest() -> void:
    phase = 1
    boss = CharacterBody2D.new()
    boss.set_script(HIGH_PRIEST_SCRIPT)
    boss.position = Vector2(1900, FLOOR_Y)
    boss.name = "HighPriest"
    _add_character_collision(boss, 24.0, 58.0)
    add_child(boss)
    boss.defeated.connect(_on_priest_defeated)
    hud.bind_boss(boss)
    boss.phase_changed.connect(_on_priest_phase_changed)

func _spawn_king() -> void:
    phase = 3
    boss = CharacterBody2D.new()
    boss.set_script(KING_SCRIPT)
    boss.position = Vector2(3420, FLOOR_Y)
    boss.name = "King"
    _add_character_collision(boss, 26.0, 62.0)
    add_child(boss)
    boss.defeated.connect(_on_king_defeated)
    hud.bind_boss(boss)
    boss.phase_changed.connect(_on_king_phase_changed)
    narrative.show_message(
        "THE KING",
        "The doors open.\n\n\"You think I did not know?\"\n\n\"I knew what they were doing. I knew what the Church had become.\nI only knew the alternative: the Kingdom falls.\"" ,
        7.0
    )

func _on_priest_defeated() -> void:
    phase = 2
    narrative.show_message(
        "THE CHURCH BREAKS",
        "The High Priest falls.\n\nThe flesh beneath the robes still twitches.\n\nThen the royal seal appears at the far end of the nave.",
        4.5
    )
    await narrative.message_finished
    _spawn_king()

func _on_priest_phase_changed(value: int) -> void:
    if value == 2:
        narrative.show_message("FALSE FAITH", "The relics in the sanctuary begin to pulse.\n\nThe High Priest's prayers continue after his mouth has stopped moving.", 3.5)

func _on_king_phase_changed(value: int) -> void:
    if value == 2:
        narrative.show_message("THE KING'S BURDEN", "The crown cracks.\n\nHe does not kneel.", 2.8)

func _on_king_defeated() -> void:
    if epilogue_started:
        return

    phase = 4
    epilogue_started = true
    ending_stage_elapsed = 0.0
    ending_can_exit = false

    WorldState.boss_defeated = true
    WorldState.set_ending_route("凡人之墓")
    WorldState.save_game()
    WorldState.input_locked = true

    if hud:
        hud.visible = false
    if narrative:
        narrative.visible = false

    _create_human_ending_overlay()
    _show_human_ending_stage(0)

func _create_human_ending_overlay() -> void:
    if ending_layer and is_instance_valid(ending_layer):
        return
    ending_layer = ENDING_OVERLAY_SCENE.instantiate() as CanvasLayer
    add_child(ending_layer)
    ending_layer.layer = 100
    ending_layer.visible = true
    ending_backdrop = ending_layer.get_node("Backdrop") as ColorRect
    ending_cg = ending_layer.get_node("CGOverlay") as Control
    ending_card = ending_layer.get_node("Card") as ColorRect
    ending_title = ending_layer.get_node("Card/Title") as Label
    ending_body = ending_layer.get_node("Card/Body") as Label
    ending_prompt = ending_layer.get_node("Card/Prompt") as Label
    var upper_rule := ending_layer.get_node("Card/TopRule") as ColorRect
    var lower_rule := ending_layer.get_node("Card/BottomRule") as ColorRect
    ending_backdrop.position = Vector2.ZERO
    ending_backdrop.size = Vector2(1280, 720)
    ending_backdrop.color = Color("#08070b")
    ending_backdrop.modulate.a = 1.0
    ending_card.position = Vector2(110, 90)
    ending_card.size = Vector2(1060, 540)
    ending_card.color = Color("#111018", 0.48)
    ending_card.modulate.a = 1.0
    upper_rule.position = Vector2(54, 74)
    upper_rule.size = Vector2(952, 2)
    upper_rule.color = Color("#5a4a50", 0.7)
    lower_rule.position = Vector2(54, 444)
    lower_rule.size = Vector2(952, 2)
    lower_rule.color = upper_rule.color
    ending_title.position = Vector2(54, 44)
    ending_title.size = Vector2(952, 54)
    ending_title.add_theme_font_size_override("font_size", 36)
    ending_title.add_theme_color_override("font_color", Color("#d6c7b2"))
    ending_body.position = Vector2(120, 150)
    ending_body.size = Vector2(820, 270)
    ending_body.add_theme_font_size_override("font_size", 21)
    ending_body.add_theme_color_override("font_color", Color("#b8aaa5"))
    ending_prompt.position = Vector2(70, 462)
    ending_prompt.size = Vector2(920, 42)
    ending_prompt.add_theme_font_size_override("font_size", 14)
    ending_prompt.add_theme_color_override("font_color", Color("#756d72"))
    for banner_name in ["BannerLeft", "BannerCenter", "BannerRight"]:
        var banner := ending_layer.get_node("Card/" + banner_name) as ColorRect
        banner.visible = true
    ending_cg.call("setup", "human")
    ending_cg.call("play")


func _show_human_ending_stage(stage: int) -> void:
    ending_stage = clampi(stage, 0, 3)
    ending_stage_elapsed = 0.0
    ending_can_exit = ending_stage == 3

    var stage_titles := [
        "凡人之墓",
        "THE RESTORATION",
        "THE NEXT ALTAR",
        "凡人之墓"
    ]
    var stage_bodies := [
        "The King falls.\nThe Church is defeated.\n\nThe Kingdom survives — but no one has been saved.",
        "The Restoration Army enters the capital.\nThe old banners burn.\n\nFor a while, the bells are silent.",
        "New rulers promise that power will never be abused again.\n\nThey build a new altar.\nThen a new order.\nThen new reasons to obey.",
        "No god chose the Hero.\nNo paradise opened.\n\nHe remained a human being.\n\nAnd the world kept going."
    ]

    ending_title.text = NereisLocalization.translate_text(stage_titles[ending_stage])
    if ending_cg and ending_stage == 3 and ending_cg.has_method("pulse"):
        ending_cg.pulse()
    ending_body.text = NereisLocalization.translate_text(stage_bodies[ending_stage])

    if ending_stage < 3:
        ending_prompt.text = "E / ENTER    Continue"
    else:
        ending_prompt.text = "ENDING COMPLETE    E / ENTER  Return to Title    F9  Restart"

    ending_card.modulate.a = 0.0
    var tween := create_tween()
    tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_property(ending_card, "modulate:a", 1.0, 0.8)

func _process(delta: float) -> void:
    if not epilogue_started:
        return

    ending_stage_elapsed += delta
    if ending_stage < 3 and ending_stage_elapsed >= 4.8:
        _show_human_ending_stage(ending_stage + 1)

func _return_from_human_ending() -> void:
    WorldState.input_locked = false
    WorldState.prepare_scene_runtime()
    get_tree().change_scene_to_file("res://scenes/boot.tscn")

func _show_intro() -> void:
    narrative.show_message(
        "THE LAST CHURCH",
        "The High Priest is waiting.\n\nHe does not look surprised to see you.",
        4.5
    )

func _create_floor() -> void:
    var floor := StaticBody2D.new()
    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(LEVEL_WIDTH + 200.0, 40.0)
    shape.shape = rectangle
    shape.position = Vector2(LEVEL_WIDTH * 0.5, FLOOR_Y + 20.0)
    floor.add_child(shape)
    add_child(floor)

func _create_boundaries() -> void:
    var left := StaticBody2D.new()
    var ls := CollisionShape2D.new()
    var lr := RectangleShape2D.new()
    lr.size = Vector2(40, 720)
    ls.shape = lr
    ls.position = Vector2(-20, 360)
    left.add_child(ls)
    add_child(left)

    var right := StaticBody2D.new()
    var rs := CollisionShape2D.new()
    var rr := RectangleShape2D.new()
    rr.size = Vector2(40, 720)
    rs.shape = rr
    rs.position = Vector2(LEVEL_WIDTH + 20.0, 360)
    right.add_child(rs)
    add_child(right)

func _add_character_collision(character: CharacterBody2D, radius: float, height: float) -> void:
    var collision := CollisionShape2D.new()
    var capsule := CapsuleShape2D.new()
    capsule.radius = radius
    capsule.height = height
    collision.shape = capsule
    collision.position = Vector2(0, -height * 0.5)
    character.add_child(collision)

func _unhandled_input(event: InputEvent) -> void:
    if epilogue_started:
        if event is InputEventKey and event.pressed and not event.echo:
            if event.keycode in [KEY_E, KEY_ENTER, KEY_SPACE]:
                _mark_input_handled()
                if ending_stage < 3:
                    _show_human_ending_stage(ending_stage + 1)
                elif ending_can_exit:
                    _return_from_human_ending()
            elif event.keycode == KEY_F9:
                _mark_input_handled()
                WorldState.delete_save()
                get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")
        return

    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
        _mark_input_handled()
        WorldState.delete_save()
        get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")

func _mark_input_handled() -> void:
    var viewport := get_viewport()
    if viewport != null:
        viewport.set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(0, 0, LEVEL_WIDTH, 720), Color("#100e12"))
    draw_rect(Rect2(0, FLOOR_Y, LEVEL_WIDTH, 180), Color("#201a22"))

    for x in range(0, int(LEVEL_WIDTH), 260):
        draw_colored_polygon(
            PackedVector2Array([
                Vector2(x + 18, FLOOR_Y),
                Vector2(x + 110, 260),
                Vector2(x + 210, FLOOR_Y)
            ]),
            Color("#1f1a22")
        )

    draw_rect(Rect2(1440, 300, 700, 220), Color("#29222c"))
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(1370, 300),
            Vector2(1790, 100),
            Vector2(2210, 300)
        ]),
        Color("#352d38")
    )
    draw_rect(Rect2(1735, 350, 110, 170), Color("#17141b"))
    draw_rect(Rect2(2930, 270, 980, 250), Color("#27212a"))
    draw_string(ThemeDB.fallback_font, Vector2(1660, 250), "THE LAST CHURCH", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#7f6e72"))
    draw_string(ThemeDB.fallback_font, Vector2(3210, 230), "THE THRONE", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#7f6e72"))

    if epilogue_started:
        draw_rect(Rect2(0, 0, LEVEL_WIDTH, 720), Color(0.07, 0.055, 0.08, clampf(0.25 + epilogue_elapsed * 0.02, 0.25, 0.62)))
        draw_colored_polygon(
            PackedVector2Array([
                Vector2(650, 480),
                Vector2(670, 285),
                Vector2(690, 480)
            ]),
            Color("#473640")
        )
        draw_rect(Rect2(650, 330, 40, 150), Color("#2a222d"))
        draw_circle(Vector2(670, 312), 10.0, Color("#a27a68"))

        draw_line(Vector2(1840, 420), Vector2(1840, 190), Color("#56424a"), 8.0)
        draw_colored_polygon(
            PackedVector2Array([
                Vector2(1842, 215),
                Vector2(1960, 245),
                Vector2(1842, 280)
            ]),
            Color("#5d3e49")
        )
        draw_string(ThemeDB.fallback_font, Vector2(1640, 150), "THE FIRST NEW CEREMONY", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#78666c"))
