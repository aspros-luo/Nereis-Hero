extends Node2D

const HERO_SCENE: PackedScene = preload("res://scenes/player/hero.tscn")
const CULTIST_SCRIPT = preload("res://scripts/enemies/cultist.gd")
const HOUND_SCRIPT = preload("res://scripts/enemies/pale_hound.gd")
const BOSS_SCRIPT = preload("res://scripts/enemies/ashen_knight.gd")
const ENEMY_ACTOR_SCENE: PackedScene = preload("res://scenes/characters/enemy_actor_base.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const BOSS_GATE_SCENE: PackedScene = preload("res://scenes/world/boss_gate.tscn")
const CHECKPOINT_SCENE: PackedScene = preload("res://scenes/world/checkpoint.tscn")
const COMBAT_AUDIO_SCENE: PackedScene = preload("res://scenes/audio/combat_audio.tscn")
const ASH_PARTICLES_SCENE: PackedScene = preload("res://scenes/effects/ash_particles.tscn")

## Enable the production Hero's opt-in skeletal visual only in the A3 preview scene.
## 仅在 A3 预览场景启用正式主角的可选骨骼表现。
@export var use_skeleton_visual_preview := false

const LEVEL_WIDTH := 2400.0
const FLOOR_Y := 540.0

var hero: CharacterBody2D
var enemies: Array[CharacterBody2D] = []
var boss: CharacterBody2D
var boss_gate: StaticBody2D
var checkpoint: Area2D
var boss_checkpoint: Area2D
var camera: Camera2D
var hud: CanvasLayer
var combat_audio: Node

var enemies_defeated := 0
var combat_started := false
var boss_active := false
var demo_complete := false
var boss_phase_two_visual := false

func _ready() -> void:
    # Combat can be entered from the narrative hub without wiping story state.
    WorldState.current_location = "combat_demo"

    _spawn_ambient_particles()
    _spawn_hero()
    _spawn_checkpoint()
    _spawn_small_enemies()
    _spawn_boss_gate()
    _spawn_hud()
    _spawn_audio()

    combat_started = true
    print("[NEREIS][DEMO] Core Combat Demo started")
    print("[NEREIS][DEMO] Goal: defeat 3 small enemies, then defeat the Ashen Knight")
    print("[NEREIS][DEMO] Combat direction: responsive 2D action; readable windups; deliberate spacing")
    queue_redraw()

func _spawn_hero() -> void:
	hero = HERO_SCENE.instantiate() as CharacterBody2D
	hero.set("use_skeleton_visual", use_skeleton_visual_preview)
	hero.position = Vector2(260, FLOOR_Y)
	hero.name = "Hero"
	add_child(hero)
	hero.defeated.connect(_on_hero_defeated)
	hero.attack_started.connect(_on_hero_attack_started)
	hero.dodge_started.connect(_on_hero_dodge_started)
	hero.attack_landed.connect(_on_hero_attack_landed)

	camera = hero.get_node("HeroCamera") as Camera2D
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(LEVEL_WIDTH)
	camera.limit_bottom = 720
	camera.position = Vector2.ZERO
func _spawn_ambient_particles() -> void:
	var particles := ASH_PARTICLES_SCENE.instantiate() as Node2D
	particles.name = "AshParticles"
	add_child(particles)
func _spawn_checkpoint() -> void:
	checkpoint = CHECKPOINT_SCENE.instantiate() as Area2D
	checkpoint.position = Vector2(420, FLOOR_Y)
	checkpoint.name = "CombatCheckpoint"
	add_child(checkpoint)
func _spawn_small_enemies() -> void:
    _spawn_enemy(CULTIST_SCRIPT, Vector2(900, FLOOR_Y), "Cultist_A")
    _spawn_enemy(HOUND_SCRIPT, Vector2(1240, FLOOR_Y), "PaleHound")
    _spawn_enemy(CULTIST_SCRIPT, Vector2(1500, FLOOR_Y), "Cultist_B")

func _spawn_enemy(enemy_script: Script, spawn_position: Vector2, enemy_name: String) -> void:
	var enemy := ENEMY_ACTOR_SCENE.instantiate() as CharacterBody2D
	if enemy == null:
		push_error("[NEREIS][DEMO] Failed to instantiate enemy actor scene")
		return
	enemy.set_script(enemy_script)
	enemy.position = spawn_position
	enemy.name = enemy_name
	var body_radius := 25.0 if enemy_script == HOUND_SCRIPT else 20.0
	var body_height := 42.0 if enemy_script == HOUND_SCRIPT else 44.0
	_configure_actor_collision(enemy, body_radius, body_height)
	add_child(enemy)
	enemy.defeated.connect(_on_small_enemy_defeated)
	if enemy.has_signal("attack_telegraphed"):
		enemy.attack_telegraphed.connect(_on_enemy_attack_telegraphed)
	enemies.append(enemy)
func _spawn_boss_gate() -> void:
	boss_gate = BOSS_GATE_SCENE.instantiate() as StaticBody2D
	boss_gate.position = Vector2(1800, FLOOR_Y)
	boss_gate.name = "BossGate"
	add_child(boss_gate)
func _spawn_boss() -> void:
	if boss_active or demo_complete:
		return

	boss_active = true
	boss = ENEMY_ACTOR_SCENE.instantiate() as CharacterBody2D
	if boss == null:
		push_error("[NEREIS][DEMO] Failed to instantiate boss actor scene")
		boss_active = false
		return
	boss.set_script(BOSS_SCRIPT)
	boss.position = Vector2(2120, FLOOR_Y)
	boss.name = "AshenKnight"
	_configure_actor_collision(boss, 24.0, 56.0)
	add_child(boss)
	boss.defeated.connect(_on_boss_defeated)
	if boss.has_signal("attack_telegraphed"):
		boss.attack_telegraphed.connect(_on_enemy_attack_telegraphed)
	if boss.has_signal("phase_changed"):
		boss.phase_changed.connect(_on_boss_phase_changed)

	if hud:
		hud.bind_boss(boss)
		hud.set_combat_demo_progress(enemies_defeated, true, demo_complete)
		hud.show_boss_intro()
	print("[NEREIS][DEMO] Boss encounter started")
func _spawn_boss_checkpoint() -> void:
	if is_instance_valid(boss_checkpoint):
		return

	WorldState.set_checkpoint(Vector2(1880, FLOOR_Y))
	boss_checkpoint = CHECKPOINT_SCENE.instantiate() as Area2D
	boss_checkpoint.position = Vector2(1880, FLOOR_Y)
	boss_checkpoint.name = "BossCheckpoint"
	add_child(boss_checkpoint)
	print("[NEREIS][DEMO] Boss checkpoint activated at x=1880")
func _spawn_audio() -> void:
	combat_audio = COMBAT_AUDIO_SCENE.instantiate()
	combat_audio.name = "CombatAudio"
	add_child(combat_audio)
func _spawn_hud() -> void:
	hud = HUD_SCENE.instantiate() as CanvasLayer
	add_child(hud)
	hud.bind_hero(hero)
	hud.set_combat_demo_mode()
	hud.set_combat_demo_progress(0, false, false)
	hud.set_debug_visible(false)
func _on_small_enemy_defeated() -> void:
    enemies_defeated += 1
    print("[NEREIS][DEMO] Small enemy defeated %d/3" % enemies_defeated)
    if hud:
        hud.set_combat_demo_progress(enemies_defeated, false, false)

    if enemies_defeated >= 3:
        _open_boss_gate()

func _open_boss_gate() -> void:
    if not is_instance_valid(boss_gate):
        return

    boss_gate.open()
    WorldState.open_boss_gate()
    _spawn_boss_checkpoint()
    _play_sfx("gate")
    print("[NEREIS][DEMO] All small enemies defeated; Boss gate opened")
    if hud:
        hud.set_combat_demo_progress(enemies_defeated, true, false)
    _spawn_boss()

func _play_sfx(id: String) -> void:
    if combat_audio and combat_audio.has_method("play_sfx"):
        combat_audio.play_sfx(id)

func _on_hero_attack_started(_combo: int) -> void:
    _play_sfx("attack")

func _on_enemy_attack_telegraphed() -> void:
    _play_sfx("telegraph")

func _on_hero_dodge_started() -> void:
    _play_sfx("dodge")

func _on_hero_attack_landed(damage: int, _target: Node) -> void:
    _play_sfx("hit")
    if hud:
        hud.show_hit_confirm(damage)

func _on_boss_phase_changed(phase: int) -> void:
    if phase == 2:
        boss_phase_two_visual = true
        queue_redraw()
        _play_sfx("phase")
        if hud:
            hud.show_phase_two()

func _on_hero_defeated() -> void:
    _play_sfx("death")
    if hud:
        hud.show_death_feedback()
        hud.set_combat_demo_progress(0, boss_active, false)
    print("[NEREIS][DEMO] Hero defeated; resetting small-enemy wave")

    for enemy in enemies:
        if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
            enemy.queue_free()

    enemies.clear()
    enemies_defeated = 0

    if not boss_active:
        call_deferred("_spawn_small_enemies")

func _on_boss_defeated() -> void:
    _play_sfx("boss_death")
    WorldState.mark_slice_complete()
    demo_complete = true
    if hud:
        hud.set_combat_demo_progress(enemies_defeated, true, true)
        hud.show_complete()
    print("[NEREIS][DEMO] CORE COMBAT DEMO COMPLETE")
    queue_redraw()

func _configure_actor_collision(character: CharacterBody2D, radius: float, height: float) -> void:
	var collision := character.get_node("CollisionShape2D") as CollisionShape2D
	var capsule := collision.shape as CapsuleShape2D
	capsule.radius = radius
	capsule.height = height
	collision.position = Vector2(0, -height * 0.5)

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
    # Far silhouette layer.
    for x in range(90, int(LEVEL_WIDTH), 300):
        var h: float = 120.0 + float((int(x / 300.0)) % 3) * 45.0
        draw_colored_polygon(PackedVector2Array([
            Vector2(x - 110, FLOOR_Y - 10),
            Vector2(x - 80, FLOOR_Y - h),
            Vector2(x - 20, FLOOR_Y - h - 26),
            Vector2(x + 25, FLOOR_Y - h + 8),
            Vector2(x + 95, FLOOR_Y - 10)
        ]), Color("#16141b"))

    # Distant dead trees / shrine silhouettes.
    for x in range(150, int(LEVEL_WIDTH), 360):
        draw_line(Vector2(x, FLOOR_Y), Vector2(x + 70, 390), Color("#2c2530"), 8.0)
        draw_line(Vector2(x + 36, 440), Vector2(x + 110, 360), Color("#302832"), 5.0)
        draw_line(Vector2(x + 58, 418), Vector2(x + 38, 350), Color("#2f2832"), 4.0)

    # Broken church spires along the horizon.
    for x in [520.0, 980.0, 1460.0, 1920.0]:
        draw_colored_polygon(
            PackedVector2Array([
                Vector2(x - 34, FLOOR_Y - 16),
                Vector2(x - 18, 290),
                Vector2(x, 248),
                Vector2(x + 22, 292),
                Vector2(x + 38, FLOOR_Y - 16)
            ]),
            Color("#211c25")
        )
        draw_rect(Rect2(x - 6, 310, 12, 180), Color("#2b232d"))

    # Low fog bands.
    for y in [390.0, 455.0, 515.0]:
        draw_rect(Rect2(0, y, LEVEL_WIDTH, 28), Color(0.08, 0.07, 0.10, 0.34))

func _draw_arena_details() -> void:
    var arena_core := Color("#21151c") if boss_phase_two_visual else Color("#17141b")
    var arena_edge := Color("#6b3039") if boss_phase_two_visual else Color("#2c2430")
    var arena_label := Color("#8f4852") if boss_phase_two_visual else Color("#514650")
    draw_rect(Rect2(1760, FLOOR_Y - 170, 18, 170), Color("#392731"))
    draw_rect(Rect2(1802, FLOOR_Y - 205, 18, 205), Color("#4a3439"))
    draw_rect(Rect2(2270, FLOOR_Y - 205, 18, 205), Color("#4a3439"))
    draw_circle(Vector2(2040, FLOOR_Y - 20), 180.0, arena_core)
    draw_arc(Vector2(2040, FLOOR_Y - 20), 176.0, PI, TAU, 40, arena_edge, 6.0)
    if boss_phase_two_visual:
        draw_arc(Vector2(2040, FLOOR_Y - 20), 128.0, PI * 1.08, PI * 1.92, 24, Color("#9b3d49", 0.65), 3.0)
    draw_string(ThemeDB.fallback_font, Vector2(1930, 350), NereisLocalization.translate_text("ASHEN ARENA"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, arena_label)

func _draw_phase_markers() -> void:
    draw_string(ThemeDB.fallback_font, Vector2(80, 180), NereisLocalization.translate_text("AWAKENING"), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#4d454d"))
    draw_string(ThemeDB.fallback_font, Vector2(780, 180), NereisLocalization.translate_text("THE ROAD"), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#4d454d"))
    draw_string(ThemeDB.fallback_font, Vector2(1680, 180), NereisLocalization.translate_text("ASH GATE"), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#4d454d"))
    draw_string(ThemeDB.fallback_font, Vector2(2020, 180), NereisLocalization.translate_text("THE ASHEN KNIGHT"), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#796d67"))

    draw_string(
        ThemeDB.fallback_font,
        Vector2(740, 610), NereisLocalization.translate_text("3 SMALL ENEMIES"), HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        14,
        Color("#66545c")
    )

    _draw_arena_details()

    if demo_complete:
        draw_string(
            ThemeDB.fallback_font,
            Vector2(820, 310), NereisLocalization.translate_text("CORE COMBAT DEMO COMPLETE"), HORIZONTAL_ALIGNMENT_LEFT,
            -1,
            28,
            Color("#d6c7b2")
        )
