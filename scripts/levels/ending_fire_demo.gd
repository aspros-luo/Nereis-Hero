extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const FINAL_CULTIST_SCRIPT = preload("res://scripts/enemies/final_cultist.gd")
const FINAL_MITE_SCRIPT = preload("res://scripts/npc/final_mite.gd")

const CULTIST_COUNT := 100
const FLOOR_Y := 540.0
const LEVEL_WIDTH := 5600.0

var hero: CharacterBody2D
var camera: Camera2D
var hud: CanvasLayer
var narrative: CanvasLayer
var cultists: Array[CharacterBody2D] = []
var cultists_defeated := 0
var mite: Node2D
var mite_phase := false
var ending_started := false
var detonation_started := false
var elapsed := 0.0
var fire_intensity := 0.0

func _ready() -> void:
    # Director test scene only. Do not save these forced ending facts.
    WorldState.current_location = "ending_fire_demo"
    WorldState.physical_union_complete = true
    WorldState.outer_god_resonance = true
    WorldState.ancient_residue_awakened = true
    WorldState.hidden_artifact_pieces = 3

    _create_floor()
    _create_boundaries()
    _spawn_hero()
    _spawn_hud()
    _spawn_narrative()
    _spawn_cultist_swarm()
    get_tree().create_timer(0.8).timeout.connect(_show_intro)
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    if mite_phase:
        fire_intensity = minf(1.0, fire_intensity + delta * 0.045)
    else:
        fire_intensity = maxf(0.0, fire_intensity - delta * 0.5)
    queue_redraw()

func _spawn_hero() -> void:
    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.position = Vector2(260, FLOOR_Y)
    hero.name = "Hero"
    _add_character_collision(hero, 18.0, 48.0)
    add_child(hero)

    camera = Camera2D.new()
    camera.name = "EndingCamera"
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = int(LEVEL_WIDTH)
    camera.limit_bottom = 720
    hero.add_child(camera)

func _spawn_hud() -> void:
    hud = CanvasLayer.new()
    hud.set_script(HUD_SCRIPT)
    add_child(hud)
    hud.bind_hero(hero)
    hud.set_debug_visible(false)
    if hud.has_method("_set_humanity_visible"):
        hud._set_humanity_visible(true)

func _spawn_narrative() -> void:
    narrative = CanvasLayer.new()
    narrative.set_script(NARRATIVE_SCRIPT)
    add_child(narrative)

func _spawn_cultist_swarm() -> void:
    for i in range(CULTIST_COUNT):
        var cultist := CharacterBody2D.new()
        cultist.set_script(FINAL_CULTIST_SCRIPT)
        var lane := i % 5
        var row := int(i / 5)
        cultist.position = Vector2(900.0 + row * 92.0, FLOOR_Y - float(lane * 9))
        cultist.name = "FinalCultist_%03d" % (i + 1)
        _add_character_collision(cultist, 14.0, 42.0)
        add_child(cultist)
        cultist.setup(hero, float(i + 1) * 0.17)
        cultist.defeated.connect(_on_cultist_defeated)
        cultists.append(cultist)

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

    mite = Node2D.new()
    mite.set_script(FINAL_MITE_SCRIPT)
    mite.position = Vector2(4550, FLOOR_Y)
    mite.name = "Mite"
    add_child(mite)
    mite.setup(hero, self)

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
    await get_tree().create_timer(1.35).timeout

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

    get_tree().create_timer(3.4).timeout.connect(_begin_detonation)

func _begin_detonation() -> void:
    if detonation_started:
        return
    detonation_started = true
    WorldState.input_locked = true

    var flash := ColorRect.new()
    flash.color = Color("#f2d0a8")
    flash.modulate.a = 0.0
    flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(flash)

    var tween := create_tween()
    tween.tween_property(flash, "modulate:a", 1.0, 0.12)
    tween.tween_interval(0.35)
    tween.tween_property(flash, "modulate:a", 0.0, 1.1)

    narrative.show_message(
        "烈火天罚",
        "The city disappears beneath the fire.\n\nThere is no victory.",
        5.0
    )

func _show_intro() -> void:
    narrative.show_message(
        "烈火天罚 / DIRECTOR TEST",
        "One hundred cultists.\n\nNo hidden lore is attached to the count.\n\nKeep moving.",
        4.0
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
    var left_shape := CollisionShape2D.new()
    var left_rect := RectangleShape2D.new()
    left_rect.size = Vector2(40, 720)
    left_shape.shape = left_rect
    left_shape.position = Vector2(-20, 360)
    left.add_child(left_shape)
    add_child(left)

    var right := StaticBody2D.new()
    var right_shape := CollisionShape2D.new()
    var right_rect := RectangleShape2D.new()
    right_rect.size = Vector2(40, 720)
    right_shape.shape = right_rect
    right_shape.position = Vector2(LEVEL_WIDTH + 20.0, 360)
    right.add_child(right_shape)
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
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
        WorldState.delete_save()
        get_tree().change_scene_to_file("res://scenes/village_hub.tscn")
        get_viewport().set_input_as_handled()

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
