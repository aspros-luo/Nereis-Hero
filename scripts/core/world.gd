extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const ENEMY_SCRIPT = preload("res://scripts/enemies/cultist.gd")
const NPC_SCRIPT = preload("res://scripts/npc/old_hunter.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const BOSS_SCRIPT = preload("res://scripts/enemies/ashen_knight.gd")
const CHECKPOINT_SCRIPT = preload("res://scripts/world/checkpoint.gd")

var hero: CharacterBody2D
var enemy: CharacterBody2D
var boss: CharacterBody2D
var checkpoint: Area2D
var old_hunter: Node2D
var camera: Camera2D
var narrative: CanvasLayer
var debug_enabled := true

func _ready() -> void:
    _log("BOOT", "World initialization started")
    _create_floor()

    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.position = Vector2(320, 520)
    hero.name = "Hero"
    _add_character_collision(hero, 18.0, 48.0)
    add_child(hero)

    old_hunter = Node2D.new()
    old_hunter.set_script(NPC_SCRIPT)
    old_hunter.position = Vector2(560, 520)
    old_hunter.name = "OldHunter"
    add_child(old_hunter)
    old_hunter.interacted.connect(_on_old_hunter_interacted)

    _spawn_cultist()
    _spawn_boss()

    checkpoint = Area2D.new()
    checkpoint.set_script(CHECKPOINT_SCRIPT)
    checkpoint.position = Vector2(720, 520)
    checkpoint.name = "Checkpoint_01"
    var checkpoint_shape := CollisionShape2D.new()
    var checkpoint_rect := RectangleShape2D.new()
    checkpoint_rect.size = Vector2(150, 110)
    checkpoint_shape.shape = checkpoint_rect
    checkpoint_shape.position = Vector2(0, -55)
    checkpoint.add_child(checkpoint_shape)
    add_child(checkpoint)

    hero.defeated.connect(_on_hero_defeated)
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

    _log("BOOT", "Hero, OldHunter, Cultist, AshenKnight, Narrative and Camera initialized")
    queue_redraw()

func _spawn_cultist() -> void:
    if is_instance_valid(enemy):
        return
    enemy = CharacterBody2D.new()
    enemy.set_script(ENEMY_SCRIPT)
    enemy.position = Vector2(900, 520)
    enemy.name = "Cultist"
    _add_character_collision(enemy, 20.0, 44.0)
    add_child(enemy)
    _log("WORLD", "Cultist spawned")

func _spawn_boss() -> void:
    if WorldState.boss_defeated or is_instance_valid(boss):
        return
    boss = CharacterBody2D.new()
    boss.set_script(BOSS_SCRIPT)
    boss.position = Vector2(1130, 520)
    boss.name = "AshenKnight"
    _add_character_collision(boss, 24.0, 56.0)
    add_child(boss)
    boss.defeated.connect(_on_boss_defeated)
    _log("WORLD", "Ashen Knight spawned")

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

func _on_hero_defeated() -> void:
    _log("WORLD", "Hero death handled; checkpoint respawn complete")
    if not is_instance_valid(enemy):
        _spawn_cultist()
    if not WorldState.boss_defeated and not is_instance_valid(boss):
        _spawn_boss()

func _on_boss_defeated() -> void:
    _log("BOSS", "Ashen Knight encounter cleared")
    if narrative:
        narrative.show_message("THE ASHEN KNIGHT", "The armor falls without a body inside.\n\nFor a moment, the Hero remembers kneeling before the church. Then the memory tears itself away.")
    queue_redraw()

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
    draw_rect(Rect2(1040, 420, 160, 100), Color("#241d25"))
    draw_string(ThemeDB.fallback_font, Vector2(650, 438), "SAFE GROUND", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#796d67"))
    draw_string(ThemeDB.fallback_font, Vector2(1045, 438), "BOSS GATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#796d67"))
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
        draw_string(ThemeDB.fallback_font, Vector2(950, 208), "Boss Defeated: %s" % WorldState.boss_defeated, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#b7a09b"))
