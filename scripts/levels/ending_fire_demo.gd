extends Node2D

const CULTIST_COUNT := 100
const FLOOR_Y := 540.0
const LEVEL_WIDTH := 5600.0
const FINAL_CULTIST_SCENE: PackedScene = preload("res://scenes/enemies/final_cultist.tscn")
const FINAL_MITE_SCENE: PackedScene = preload("res://scenes/npc/final_mite.tscn")

@onready var hero: CharacterBody2D = $Hero
@onready var camera: Camera2D = $Hero/HeroCamera
@onready var hud: CanvasLayer = $HUD
@onready var narrative: CanvasLayer = $Narrative
@onready var narrative_audio: Node = $NarrativeAudio
@onready var ending_layer: CanvasLayer = $EndingLayer
@onready var flash: ColorRect = $Flash

var cultists: Array[CharacterBody2D] = []
var cultists_defeated := 0
var mite: Node2D
var mite_phase := false
var ending_started := false
var detonation_started := false
var elapsed := 0.0
var fire_intensity := 0.0
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
    # Director test scene only. Do not save forced ending facts or fabricate relationship milestones.
    WorldState.current_location = "ending_fire_demo"
    WorldState.ancient_residue_awakened = true
    WorldState.hidden_artifact_pieces = 3

    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = int(LEVEL_WIDTH)
    camera.limit_bottom = 720
    hud.bind_hero(hero)
    hud.set_debug_visible(false)
    if hud.has_method("_set_humanity_visible"):
        hud._set_humanity_visible(true)

    _spawn_cultist_swarm()
    get_tree().create_timer(0.8).timeout.connect(_show_intro)
    queue_redraw()


func _spawn_cultist_swarm() -> void:
    for i in range(CULTIST_COUNT):
        var cultist := FINAL_CULTIST_SCENE.instantiate() as CharacterBody2D
        if cultist == null:
            push_error("Fire ending: failed to instantiate FinalCultist scene")
            return
        var lane := i % 5
        var row := int(i / 5)
        cultist.position = Vector2(900.0 + row * 92.0, FLOOR_Y - float(lane * 9))
        cultist.name = "FinalCultist_%03d" % (i + 1)
        add_child(cultist)
        cultist.setup(hero, float(i + 1) * 0.17)
        cultist.defeated.connect(_on_cultist_defeated)
        cultists.append(cultist)


func _process(delta: float) -> void:
    elapsed += delta
    if mite_phase:
        fire_intensity = minf(1.0, fire_intensity + delta * 0.045)
    else:
        fire_intensity = maxf(0.0, fire_intensity - delta * 0.5)

    if ending_active:
        ending_stage_elapsed += delta
        if ending_stage < 3 and ending_stage_elapsed >= 5.5:
            _advance_ending_stage()

    queue_redraw()

func _on_cultist_defeated() -> void:
    cultists_defeated += 1
    if cultists_defeated % 10 == 0:
        print("[NEREIS][ENDING] Final cultists cleared=%d/%d" % [cultists_defeated, CULTIST_COUNT])
    if cultists_defeated >= CULTIST_COUNT and not mite_phase:
        _start_mite_phase()

func _start_mite_phase() -> void:
    mite_phase = true
    for cultist in cultists:
        if is_instance_valid(cultist):
            cultist.queue_free()
    cultists.clear()

    mite = FINAL_MITE_SCENE.instantiate() as Node2D
    if mite == null:
        push_error("Fire ending: failed to instantiate FinalMite scene")
        return
    mite.position = Vector2(4550, FLOOR_Y)
    mite.name = "Mite"
    add_child(mite)
    mite.setup(hero, self)
    if narrative_audio and narrative_audio.has_method("play_corrupted_lullaby"):
        narrative_audio.play_corrupted_lullaby()

    hero.global_position = Vector2(4100, FLOOR_Y)
    narrative.show_message(
        "THE LAST ROOM",
        "The city burns behind you.\n\nMite is waiting ahead.\n\nShe does not raise her hands.",
        6.0
    )
    print("[NEREIS][ENDING] Entered final Mite encounter")


func _mite_chooses_the_blade() -> void:
    if not mite or not is_instance_valid(mite) or detonation_started:
        return

    narrative.show_message("MITE", "Hero...", 1.2)
    await get_tree().create_timer(1.35, true).timeout

    if mite and is_instance_valid(mite):
        mite.sacrifice_to_weapon()

func _on_mite_dying(waited_for: bool) -> void:
    if ending_started:
        return

    ending_started = true
    if waited_for:
        print("[NEREIS][ENDING] Mite chose the blade after the waiting window")
    else:
        print("[NEREIS][ENDING] Player delivered the final blow")

    WorldState.ending_route = "烈火天罚"
    WorldState.input_locked = true
    if narrative:
        narrative.show_message(
            "MITE",
            "The blade enters.\n\nFor one breath, she is only herself again.",
            3.2
        )

        await narrative.message_finished
        _begin_detonation()

func _begin_detonation() -> void:
    if detonation_started:
        return
    detonation_started = true
    if narrative_audio and narrative_audio.has_method("play_corrupted_lullaby"):
        narrative_audio.play_corrupted_lullaby()
    WorldState.input_locked = true
    WorldState.ending_route = "烈火天罚"
    WorldState.save_game()

    flash.color = Color("#f2d0a8")
    flash.modulate.a = 0.0
    flash.visible = true

    var tween := create_tween()
    tween.tween_property(flash, "modulate:a", 1.0, 0.12)
    tween.tween_interval(0.35)
    tween.tween_property(flash, "modulate:a", 0.0, 1.1)
    narrative.show_message(
        "烈火天罚",
        "The city disappears beneath the fire.\n\nThere is no victory.",
        5.0
    )
    await narrative.message_finished
    _start_final_ending()

func _start_final_ending() -> void:
    ending_active = true
    if hud:
        hud.visible = false
    if narrative:
        narrative.visible = false
    _create_ending_overlay()
    _show_ending_stage(0)

func _create_ending_overlay() -> void:
    ending_layer = $EndingLayer as CanvasLayer
    ending_layer.visible = true
    ending_backdrop = ending_layer.get_node("Backdrop") as ColorRect
    ending_cg = ending_layer.get_node("CGOverlay") as Control
    ending_card = ending_layer.get_node("Card") as ColorRect
    ending_title = ending_layer.get_node("Card/Title") as Label
    ending_body = ending_layer.get_node("Card/Body") as Label
    ending_prompt = ending_layer.get_node("Card/Prompt") as Label
    var top_rule := ending_layer.get_node("Card/TopRule") as ColorRect
    var bottom_rule := ending_layer.get_node("Card/BottomRule") as ColorRect
    ending_backdrop.color = Color("#09070a")
    ending_backdrop.modulate.a = 0.0
    ending_card.color = Color("#1b1518", 0.58)
    ending_card.modulate.a = 0.0
    top_rule.color = Color("#9b4c42")
    bottom_rule.color = top_rule.color
    ending_title.add_theme_font_size_override("font_size", 38)
    ending_title.add_theme_color_override("font_color", Color("#ead3c7"))
    ending_body.add_theme_font_size_override("font_size", 24)
    ending_body.add_theme_color_override("font_color", Color("#c7b1a8"))
    ending_prompt.add_theme_font_size_override("font_size", 15)
    ending_prompt.add_theme_color_override("font_color", Color("#9b8078"))
    ending_cg.call("setup", "fire")
    ending_cg.call("play")

func _show_ending_stage(stage: int) -> void:
    ending_stage = stage
    ending_stage_elapsed = 0.0
    ending_can_exit = false

    match stage:
        0:
            ending_title.text = "烈火天罚"
            ending_body.text = "The city burns beneath the sky.\n\nMite is gone.\nThe Church is gone.\nThe kingdom is gone."
            ending_prompt.text = "There is no victory."
            _tween_ending_in()
        1:
            ending_title.text = "THE LAST SONG"
            ending_body.text = "For one breath, Mite was only herself again.\n\nThen the fire answered the thing sleeping inside her."
            ending_prompt.text = "No one remains to tell the story correctly."
            _tween_ending_card()
        2:
            ending_title.text = "ASHES WITHOUT A GOD"
            ending_body.text = "Hero survives.\n\nNot because the world was saved.\nNot because the gods were defeated.\nOnly because someone chose, for one last moment, to resist."
            ending_prompt.text = "The road ahead is buried in ash."
            _tween_ending_card()
        3:
            ending_title.text = "烈火天罚"
            if ending_cg and ending_cg.has_method("pulse"):
                ending_cg.pulse()
            ending_body.text = "The city is dead.\n\nMite is dead.\n\nAnd the fire keeps burning long after the Hero leaves."
            ending_prompt.text = "ENDING COMPLETE    E / ENTER  Return to Title    F9  Restart"
            ending_can_exit = true
            _tween_ending_card()

func _tween_ending_in() -> void:
    ending_backdrop.modulate.a = 0.0
    ending_card.modulate.a = 0.0
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(ending_backdrop, "modulate:a", 0.94, 2.0)
    tween.tween_property(ending_card, "modulate:a", 1.0, 1.8)
    tween.set_parallel(false)

func _tween_ending_card() -> void:
    var tween := create_tween()
    ending_card.modulate.a = 0.0
    tween.tween_property(ending_card, "modulate:a", 1.0, 0.9)

func _advance_ending_stage() -> void:
    if not ending_active or ending_stage >= 3:
        return
    _show_ending_stage(ending_stage + 1)

func _return_from_ending() -> void:
    WorldState.input_locked = false
    ending_active = false
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/boot.tscn")

func _show_intro() -> void:
    narrative.show_message(
        "烈火天罚 / DIRECTOR TEST",
        "One hundred cultists.\n\nNo hidden lore is attached to the count.\n\nKeep moving.",
        4.0
    )

func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey and event.pressed and not event.echo):
        return

    if ending_active:
        if event.keycode in [KEY_E, KEY_ENTER, KEY_SPACE]:
            _mark_input_handled()
            if ending_can_exit:
                _return_from_ending()
            else:
                _show_ending_stage(ending_stage + 1)
            return

    if event.keycode == KEY_F9:
        _mark_input_handled()
        WorldState.delete_save()
        get_tree().change_scene_to_file("res://scenes/regions/escape_prologue.tscn")

func _mark_input_handled() -> void:
    var viewport := get_viewport()
    if viewport != null:
        viewport.set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(0, 0, LEVEL_WIDTH, 720), Color("#110e13"))

    for x in range(0, int(LEVEL_WIDTH), 320):
        var height := 100.0 + float((x / 320) % 3) * 55.0
        draw_colored_polygon(
            PackedVector2Array([
                Vector2(x, FLOOR_Y),
                Vector2(x + 80, FLOOR_Y - height),
                Vector2(x + 180, FLOOR_Y - height - 40),
                Vector2(x + 280, FLOOR_Y)
            ]),
            Color("#1d1820")
        )

    draw_rect(Rect2(0, FLOOR_Y, LEVEL_WIDTH, 180), Color("#211820"))

    if mite_phase:
        for i in range(12):
            var fx := 3900.0 + float(i) * 150.0
            var fy := 280.0 + sin(elapsed * 1.7 + i) * 70.0
            draw_circle(Vector2(fx, fy), 20.0 + fire_intensity * 28.0, Color(0.8, 0.32, 0.22, 0.08))
            draw_circle(Vector2(fx, fy), 5.0, Color("#9b4c42"))

    draw_string(
        ThemeDB.fallback_font,
        Vector2(180, 220),
        "THE CITY IS ALREADY DEAD",
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        28,
        Color("#62535c")
    )
