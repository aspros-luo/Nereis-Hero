extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const CULTIST_SCRIPT = preload("res://scripts/enemies/cultist.gd")
const HOUND_SCRIPT = preload("res://scripts/enemies/pale_hound.gd")
const BOSS_SCRIPT = preload("res://scripts/enemies/ashen_knight.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const BOSS_GATE_SCRIPT = preload("res://scripts/world/boss_gate.gd")
const CHECKPOINT_SCRIPT = preload("res://scripts/world/checkpoint.gd")

const LEVEL_WIDTH := 2400.0
const FLOOR_Y := 540.0

var hero: CharacterBody2D
var enemies: Array[CharacterBody2D] = []
var boss: CharacterBody2D
var boss_gate: StaticBody2D
var checkpoint: Area2D
var camera: Camera2D
var hud: CanvasLayer

var enemies_defeated := 0
var combat_started := false
var boss_active := false
var demo_complete := false

func _ready() -> void:
    WorldState.reset()
    WorldState.current_location = "combat_demo"

    _create_floor()
    _create_boundaries()
    _spawn_hero()
    _spawn_checkpoint()
    _spawn_small_enemies()
    _spawn_boss_gate()
    _spawn_hud()

    combat_started = true
    print("[NEREIS][DEMO] Core Combat Demo started")
    print("[NEREIS][DEMO] Goal: defeat 3 small enemies, then defeat the Ashen Knight")
    queue_redraw()

func _spawn_hero() -> void:
    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.position = Vector2(260, FLOOR_Y)
    hero.name = "Hero"
    _add_character_collision(hero, 18.0, 48.0)
    add_child(hero)
    hero.defeated.connect(_on_hero_defeated)

    camera = Camera2D.new()
    camera.name = "HeroCamera"
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 7.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = int(LEVEL_WIDTH)
    camera.limit_bottom = 720
    camera.position = Vector2.ZERO
    hero.add_child(camera)

func _spawn_checkpoint() -> void:
    checkpoint = Area2D.new()
    checkpoint.set_script(CHECKPOINT_SCRIPT)
    checkpoint.position = Vector2(420, FLOOR_Y)
    checkpoint.name = "CombatCheckpoint"

    var shape := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(120, 110)
    shape.shape = rectangle
    shape.position = Vector2(0, -55)
    checkpoint.add_child(shape)

    add_child(checkpoint)

func _spawn_small_enemies() -> void:
    _spawn_enemy(CULTIST_SCRIPT, Vector2(900, FLOOR_Y), "Cultist_A")
    _spawn_enemy(HOUND_SCRIPT, Vector2(1240, FLOOR_Y), "PaleHound")
    _spawn_enemy(CULTIST_SCRIPT, Vector2(1500, FLOOR_Y), "Cultist_B")

func _spawn_enemy(enemy_script: Script, position: Vector2, enemy_name: String) -> void:
    var enemy := CharacterBody2D.new()
    enemy.set_script(enemy_script)
    enemy.position = position
    enemy.name = enemy_name

    if enemy_script == HOUND_SCRIPT:
        _add_character_collision(enemy, 25.0, 42.0)
    else:
        _add_character_collision(enemy, 20.0, 44.0)

    add_child(enemy)
    enemy.defeated.connect(_on_small_enemy_defeated)
    enemies.append(enemy)

func _spawn_boss_gate() -> void:
    boss_gate = StaticBody2D.new()
    boss_gate.set_script(BOSS_GATE_SCRIPT)
    boss_gate.position = Vector2(1800, FLOOR_Y)
    boss_gate.name = "BossGate"
    add_child(boss_gate)

func _spawn_boss() -> void:
    if boss_active or demo_complete:
        return

    boss_active = true
    boss = CharacterBody2D.new()
    boss.set_script(BOSS_SCRIPT)
    boss.position = Vector2(2120, FLOOR_Y)
    boss.name = "AshenKnight"
    _add_character_collision(boss, 24.0, 56.0)
    add_child(boss)
    boss.defeated.connect(_on_boss_defeated)

    if hud:
        hud.bind_boss(boss)

    print("[NEREIS][DEMO] Boss encounter started")

func _spawn_hud() -> void:
    hud = CanvasLayer.new()
    hud.set_script(HUD_SCRIPT)
    add_child(hud)
    hud.bind_hero(hero)
    hud.set_debug_visible(false)

func _on_small_enemy_defeated() -> void:
    enemies_defeated += 1
    print("[NEREIS][DEMO] Small enemy defeated %d/3" % enemies_defeated)

    if enemies_defeated >= 3:
        _open_boss_gate()

func _open_boss_gate() -> void:
    if not is_instance_valid(boss_gate):
        return

    boss_gate.open()
    print("[NEREIS][DEMO] All small enemies defeated; Boss gate opened")
    _spawn_boss()

func _on_hero_defeated() -> void:
    print("[NEREIS][DEMO] Hero defeated; resetting small-enemy wave")

    for enemy in enemies:
        if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
            enemy.queue_free()

    enemies.clear()
    enemies_defeated = 0

    if not boss_active:
        call_deferred("_spawn_small_enemies")

func _on_boss_defeated() -> void:
    demo_complete = true
    print("[NEREIS][DEMO] CORE COMBAT DEMO COMPLETE")
    queue_redraw()

func _create_floor() -> void:
    var floor := StaticBody2D.new()
    floor.name = "Ground"

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
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_F3:
            hud.set_debug_visible(not hud.debug_enabled)
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_F9:
            WorldState.delete_save()
            get_tree().reload_current_scene()
            get_viewport().set_input_as_handled()

func _draw() -> void:
    draw_rect(Rect2(0, 0, LEVEL_WIDTH, 720), Color("#111018"))
    draw_rect(Rect2(0, FLOOR_Y, LEVEL_WIDTH, 200), Color("#201c22"))

    _draw_backdrop()
    _draw_phase_markers()

func _draw_backdrop() -> void:
    for x in range(100, int(LEVEL_WIDTH), 260):
        draw_circle(Vector2(x, 250 + (int(x / 260.0) % 2) * 40), 120, Color("#18151d"))

    for x in range(120, int(LEVEL_WIDTH), 360):
        draw_line(Vector2(x, FLOOR_Y), Vector2(x + 70, 390), Color("#2c2530"), 8.0)
        draw_line(Vector2(x + 40, 440), Vector2(x + 110, 360), Color("#302832"), 5.0)

func _draw_phase_markers() -> void:
    draw_string(ThemeDB.fallback_font, Vector2(80, 180), "AWAKENING", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#4d454d"))
    draw_string(ThemeDB.fallback_font, Vector2(780, 180), "THE ROAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#4d454d"))
    draw_string(ThemeDB.fallback_font, Vector2(1680, 180), "ASH GATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#4d454d"))
    draw_string(ThemeDB.fallback_font, Vector2(2020, 180), "THE ASHEN KNIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#796d67"))

    draw_string(
        ThemeDB.fallback_font,
        Vector2(740, 610),
        "3 SMALL ENEMIES",
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        14,
        Color("#66545c")
    )

    if demo_complete:
        draw_string(
            ThemeDB.fallback_font,
            Vector2(820, 310),
            "CORE COMBAT DEMO COMPLETE",
            HORIZONTAL_ALIGNMENT_LEFT,
            -1,
            28,
            Color("#d6c7b2")
        )
