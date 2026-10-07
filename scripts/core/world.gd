extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const ENEMY_SCRIPT = preload("res://scripts/enemies/cultist.gd")
const NPC_SCRIPT = preload("res://scripts/npc/old_hunter.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")

var hero: CharacterBody2D
var enemy: CharacterBody2D
var old_hunter: Node2D
var camera: Camera2D
var narrative: CanvasLayer
var debug_enabled := true

func _ready() -> void:
    _log("BOOT", "World initialization started")
    _create_floor()

    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.position = Vector2(320, 480)
    hero.name = "Hero"
    _add_character_collision(hero, 18.0, 48.0)
    add_child(hero)

    old_hunter = Node2D.new()
    old_hunter.set_script(NPC_SCRIPT)
    old_hunter.position = Vector2(560, 480)
    old_hunter.name = "OldHunter"
    add_child(old_hunter)
    old_hunter.interacted.connect(_on_old_hunter_interacted)

    enemy = CharacterBody2D.new()
    enemy.set_script(ENEMY_SCRIPT)
    enemy.position = Vector2(900, 480)
    enemy.name = "Cultist"
    _add_character_collision(enemy, 20.0, 44.0)
    add_child(enemy)

    narrative = CanvasLayer.new()
    narrative.set_script(NARRATIVE_SCRIPT)
    add_child(narrative)

    camera = Camera2D.new()
    camera.name = "HeroCamera"
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = 1280
    camera.limit_bottom = 720
    camera.position = hero.position
    hero.add_child(camera)

    _log("BOOT", "Hero, OldHunter, Cultist, Narrative and Camera initialized")
    queue_redraw()

func _add_character_collision(character: CharacterBody2D, radius: float, height: float) -> void:
    var shape := CollisionShape2D.new()
    var capsule := CapsuleShape2D.new()
    capsule.radius = radius
    capsule.height = height
    shape.shape = capsule
    shape.position = Vector2(0, -height * 0.5)
    character.add_child(shape)

func _create_floor() -> void:
    var floor := StaticBody2D.new()
    floor.name = "Ground"
    var collision := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(1400, 40)
    collision.shape = rectangle
    collision.position = Vector2(640, 540)
    floor.add_child(collision)
    add_child(floor)

func _on_old_hunter_interacted() -> void:
    _log("STORY", "Old Hunter interaction accepted")
    narrative.play_first_memory()
    queue_redraw()

func _process(_delta: float) -> void:
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
        debug_enabled = not debug_enabled
        _log("DEBUG", "Debug overlay=%s" % debug_enabled)
        queue_redraw()

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color("#111018"))
    draw_rect(Rect2(0, 520, 1280, 200), Color("#201c22"))
    for x in range(0, 1280, 64):
        draw_line(Vector2(x, 520), Vector2(x + 32, 552), Color("#302a30"), 2.0)

    draw_rect(Rect2(480, 445, 160, 75), Color("#27212a"))
    draw_string(ThemeDB.fallback_font, Vector2(485, 458), "OLD HUNTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#796d67"))

    draw_string(ThemeDB.fallback_font, Vector2(40, 55), "NEREIS HERO // VERTICAL SLICE 001", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#d6c7b2"))
    draw_string(ThemeDB.fallback_font, Vector2(40, 88), "A/D Move   Space Jump   J / LMB Attack   K / Shift Dodge   E Speak", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#9b9189"))
    draw_string(ThemeDB.fallback_font, Vector2(40, 125), "The village remembers what the hero has forgotten.", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#8e7777"))

    if debug_enabled and hero:
        var state_name: String = hero.get_debug_state()
        var invuln = hero.get("invulnerable")
        var hp = hero.get("health")
        draw_rect(Rect2(930, 32, 310, 158), Color("#0a090d", 0.88))
        draw_string(ThemeDB.fallback_font, Vector2(950, 60), "DEBUG [F3]", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d6c7b2"))
        draw_string(ThemeDB.fallback_font, Vector2(950, 88), "Hero HP: %s" % hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#b7a09b"))
        draw_string(ThemeDB.fallback_font, Vector2(950, 112), "State: %s" % state_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#b7a09b"))
        draw_string(ThemeDB.fallback_font, Vector2(950, 136), "Invulnerable: %s" % invuln, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#b7a09b"))
        draw_string(ThemeDB.fallback_font, Vector2(950, 160), "Memory: %d" % WorldState.hero_memory, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#b7a09b"))
        draw_string(ThemeDB.fallback_font, Vector2(950, 184), "Humanity: %d" % WorldState.hero_humanity, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#b7a09b"))
