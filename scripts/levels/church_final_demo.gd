extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HIGH_PRIEST_SCRIPT = preload("res://scripts/enemies/high_priest.gd")
const KING_SCRIPT = preload("res://scripts/enemies/king_guardian.gd")

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

func _ready() -> void:
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
    boss.phase_changed.connect(_on_king_phase_changed)
    narrative.show_message(
        "THE KING",
        "The doors open.

"You think I did not know?"\n\n"I knew what they were doing. I knew what the Church had become.\nI only knew the alternative: the Kingdom falls."",
        7.0
    )

func _on_priest_defeated() -> void:
    phase = 2
    narrative.show_message(
        "THE CHURCH BREAKS",
        "The High Priest falls.

The flesh beneath the robes still twitches.

Then the royal seal appears at the far end of the nave.",
        4.5
    )
    get_tree().create_timer(4.7).timeout.connect(_spawn_king)

func _on_priest_phase_changed(value: int) -> void:
    if value == 2:
        narrative.show_message("FALSE FAITH", "The relics in the sanctuary begin to pulse.

The High Priest's prayers continue after his mouth has stopped moving.", 3.5)

func _on_king_phase_changed(value: int) -> void:
    if value == 2:
        narrative.show_message("THE KING'S BURDEN", "The crown cracks.

He does not kneel.", 2.8)

func _on_king_defeated() -> void:
    phase = 4
    WorldState.boss_defeated = true
    narrative.show_message(
        "NO KINGDOM",
        "The King falls.

The Church is defeated.

The Kingdom is not saved.",
        5.0
    )
    get_tree().create_timer(5.3).timeout.connect(_finish_demo)

func _finish_demo() -> void:
    WorldState.input_locked = false
    narrative.show_message("DIRECTOR TEST COMPLETE", "This scene is a combat prototype for the 凡人之墓 / political final confrontation.", 4.0)

func _show_intro() -> void:
    narrative.show_message(
        "THE LAST CHURCH",
        "The High Priest is waiting.

He does not look surprised to see you.",
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
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
        WorldState.delete_save()
        get_tree().change_scene_to_file("res://scenes/village_hub.tscn")
        get_viewport().set_input_as_handled()

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
