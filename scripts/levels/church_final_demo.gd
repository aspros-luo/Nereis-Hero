extends Node2D

const KING_SCENE: PackedScene = preload("res://scenes/enemies/king_guardian.tscn")
const FLOOR_Y := 540.0
const LEVEL_WIDTH := 4400.0

@onready var hero: CharacterBody2D = $Hero
@onready var camera: Camera2D = $Hero/HeroCamera
@onready var hud: CanvasLayer = $HUD
@onready var narrative: CanvasLayer = $Narrative

var boss: CharacterBody2D
var phase := 1
var epilogue_started := false
var ending_layer: CanvasLayer
var ending_backdrop: ColorRect
var ending_card: ColorRect
var ending_title: Label
var ending_body: Label
var ending_prompt: Label
var ending_cg: Control
var ending_stage := 0
var ending_stage_elapsed := 0.0
var ending_can_exit := false


func _ready() -> void:
    WorldState.current_location = "church_final_demo"
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.5
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = int(LEVEL_WIDTH)
    camera.limit_bottom = 720
    hud.bind_hero(hero)
    hud.set_debug_visible(false)

    boss = $HighPriest as CharacterBody2D
    boss.defeated.connect(_on_priest_defeated)
    boss.phase_changed.connect(_on_priest_phase_changed)
    hud.bind_boss(boss)
    get_tree().create_timer(0.8).timeout.connect(_show_intro)
    queue_redraw()


func _spawn_king() -> void:
    phase = 3
    boss = KING_SCENE.instantiate() as CharacterBody2D
    if boss == null:
        push_error("Church ending: failed to instantiate KingGuardian scene")
        return
    boss.position = Vector2(3420, FLOOR_Y)
    boss.name = "King"
    add_child(boss)
    boss.defeated.connect(_on_king_defeated)
    hud.bind_boss(boss)
    boss.phase_changed.connect(_on_king_phase_changed)
    narrative.show_message(
        "THE KING",
        "The doors open.\n\n\"You think I did not know?\"\n\n\"I knew what they were doing. I knew what the Church had become.\nI only knew the alternative: the Kingdom falls.\"",
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
    ending_layer = $EndingLayer as CanvasLayer
    ending_layer.visible = true
    ending_backdrop = ending_layer.get_node("Backdrop") as ColorRect
    ending_cg = ending_layer.get_node("CGOverlay") as Control
    ending_card = ending_layer.get_node("Card") as ColorRect
    ending_title = ending_layer.get_node("Card/Title") as Label
    ending_body = ending_layer.get_node("Card/Body") as Label
    ending_prompt = ending_layer.get_node("Card/Prompt") as Label
    ending_layer.layer = 100
    ending_backdrop.position = Vector2.ZERO
    ending_backdrop.size = Vector2(1280, 720)
    ending_backdrop.color = Color("#08070b")
    ending_backdrop.modulate.a = 1.0
    ending_card.position = Vector2(110, 90)
    ending_card.size = Vector2(1060, 540)
    ending_card.color = Color("#111018", 0.48)
    ending_card.modulate.a = 1.0
    var upper_rule := ending_layer.get_node("Card/TopRule") as ColorRect
    var lower_rule := ending_layer.get_node("Card/BottomRule") as ColorRect
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
                get_tree().change_scene_to_file("res://scenes/regions/escape_prologue.tscn")
        return

    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
        _mark_input_handled()
        WorldState.delete_save()
        get_tree().change_scene_to_file("res://scenes/regions/escape_prologue.tscn")

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
