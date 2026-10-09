extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const ENEMY_SCRIPT = preload("res://scripts/enemies/cultist.gd")
const HOUND_SCRIPT = preload("res://scripts/enemies/pale_hound.gd")
const NPC_SCRIPT = preload("res://scripts/npc/old_hunter.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const BOSS_SCRIPT = preload("res://scripts/enemies/ashen_knight.gd")
const CHECKPOINT_SCRIPT = preload("res://scripts/world/checkpoint.gd")
const BOSS_GATE_SCRIPT = preload("res://scripts/world/boss_gate.gd")
const LEVEL_EXIT_SCRIPT = preload("res://scripts/world/level_exit.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const ASHEN_ROAD_BACKDROP = preload("res://assets/backgrounds/ashen_road_painterly.svg")
const ASHEN_ROAD_FAR_MIST = preload("res://assets/backgrounds/ashen_road_far_mist.svg")
const ASHEN_ROAD_MIDGROUND = preload("res://assets/backgrounds/ashen_road_midground.svg")
const ASHEN_ROAD_FOREGROUND = preload("res://assets/backgrounds/ashen_road_foreground.svg")

var hero: CharacterBody2D
var enemy: CharacterBody2D
var hound: CharacterBody2D
var boss: CharacterBody2D
var checkpoint: Area2D
var boss_gate: StaticBody2D
var level_exit: Area2D
var old_hunter: Node2D
var camera: Camera2D
var narrative: CanvasLayer
var hud: CanvasLayer

func _ready() -> void:
    if WorldState.current_location != "slice" or (WorldState.slice_complete and WorldState.selected_route != ""):
        print("[NEREIS][ROUTE] Restoring saved progress route=%s complete=%s" % [WorldState.selected_route, WorldState.route_complete])
        SceneTransition.fade_to_scene(WorldState.get_resume_scene_path())
        return

    _log("BOOT", "World initialization started")
    _create_floor()
    _create_boundaries()

    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.position = WorldState.checkpoint_position if WorldState.checkpoint_active else Vector2(320, 520)
    hero.name = "Hero"
    _add_character_collision(hero, 18.0, 48.0)
    add_child(hero)

    old_hunter = Node2D.new()
    old_hunter.set_script(NPC_SCRIPT)
    old_hunter.position = Vector2(680, 520)
    old_hunter.name = "OldHunter"
    add_child(old_hunter)
    old_hunter.interacted.connect(_on_old_hunter_interacted)

    _spawn_cultist()
    _spawn_hound()
    _spawn_boss()

    checkpoint = Area2D.new()
    checkpoint.set_script(CHECKPOINT_SCRIPT)
    checkpoint.position = Vector2(980, 520)
    checkpoint.name = "Checkpoint_01"
    var checkpoint_shape := CollisionShape2D.new()
    var checkpoint_rect := RectangleShape2D.new()
    checkpoint_rect.size = Vector2(150, 110)
    checkpoint_shape.shape = checkpoint_rect
    checkpoint_shape.position = Vector2(0, -55)
    checkpoint.add_child(checkpoint_shape)
    add_child(checkpoint)

    hero.defeated.connect(_on_hero_defeated)
    if not WorldState.boss_gate_open:
        boss_gate = StaticBody2D.new()
        boss_gate.set_script(BOSS_GATE_SCRIPT)
        boss_gate.position = Vector2(1800, 520)
        boss_gate.name = "AshGate"
        add_child(boss_gate)

    narrative = CanvasLayer.new()
    narrative.set_script(NARRATIVE_SCRIPT)
    add_child(narrative)
    if WorldState.boss_defeated and not WorldState.first_choice_made:
        get_tree().create_timer(0.8).timeout.connect(_open_first_choice)

    hud = CanvasLayer.new()
    hud.set_script(HUD_SCRIPT)
    add_child(hud)
    hud.bind_hero(hero)
    if is_instance_valid(boss):
        hud.bind_boss(boss)

    level_exit = Area2D.new()
    level_exit.set_script(LEVEL_EXIT_SCRIPT)
    level_exit.position = Vector2(2320, 520)
    level_exit.name = "LevelExit"
    var exit_shape := CollisionShape2D.new()
    var exit_rect := RectangleShape2D.new()
    exit_rect.size = Vector2(100, 130)
    exit_shape.shape = exit_rect
    exit_shape.position = Vector2(0, -65)
    level_exit.add_child(exit_shape)
    add_child(level_exit)
    level_exit.reached.connect(_on_level_exit_reached)

    camera = Camera2D.new()
    camera.name = "HeroCamera"
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = 2400
    camera.limit_bottom = 720
    camera.position = Vector2.ZERO
    hero.add_child(camera)

    _log("BOOT", "Hero, OldHunter, Cultist, AshenKnight, Narrative and Camera initialized")
    queue_redraw()

func _spawn_hound() -> void:
    if is_instance_valid(hound) and not hound.is_queued_for_deletion():
        return
    hound = CharacterBody2D.new()
    hound.set_script(HOUND_SCRIPT)
    hound.position = Vector2(1180, 520)
    hound.name = "PaleHound"
    _add_character_collision(hound, 25.0, 42.0)
    add_child(hound)
    _log("WORLD", "Pale Hound spawned")

func _spawn_cultist() -> void:
    if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
        return
    enemy = CharacterBody2D.new()
    enemy.set_script(ENEMY_SCRIPT)
    enemy.position = Vector2(1400, 520)
    enemy.name = "Cultist"
    _add_character_collision(enemy, 20.0, 44.0)
    add_child(enemy)
    enemy.defeated.connect(_on_cultist_defeated)
    _log("WORLD", "Cultist spawned")

func _spawn_boss() -> void:
    if WorldState.boss_defeated or (is_instance_valid(boss) and not boss.is_queued_for_deletion()):
        return
    boss = CharacterBody2D.new()
    boss.set_script(BOSS_SCRIPT)
    boss.position = Vector2(2080, 520)
    boss.name = "AshenKnight"
    _add_character_collision(boss, 24.0, 56.0)
    add_child(boss)
    boss.defeated.connect(_on_boss_defeated)
    if hud:
        hud.bind_boss(boss)
    _log("WORLD", "Ashen Knight spawned")

func _add_character_collision(character: CharacterBody2D, radius: float, height: float) -> void:
    var shape := CollisionShape2D.new()
    var capsule := CapsuleShape2D.new()
    capsule.radius = radius
    capsule.height = height
    shape.shape = capsule
    shape.position = Vector2(0, -height * 0.5)
    character.add_child(shape)

func _create_boundaries() -> void:
    var left_wall := StaticBody2D.new()
    left_wall.name = "LeftBoundary"
    var left_shape := CollisionShape2D.new()
    var left_rect := RectangleShape2D.new()
    left_rect.size = Vector2(40, 720)
    left_shape.shape = left_rect
    left_shape.position = Vector2(-20, 360)
    left_wall.add_child(left_shape)
    add_child(left_wall)

    var right_wall := StaticBody2D.new()
    right_wall.name = "RightBoundary"
    var right_shape := CollisionShape2D.new()
    var right_rect := RectangleShape2D.new()
    right_rect.size = Vector2(40, 720)
    right_shape.shape = right_rect
    right_shape.position = Vector2(2420, 360)
    right_wall.add_child(right_shape)
    add_child(right_wall)

func _create_floor() -> void:
    var floor := StaticBody2D.new()
    floor.name = "Ground"
    var collision := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = Vector2(2600, 40)
    collision.shape = rectangle
    collision.position = Vector2(1200, 540)
    floor.add_child(collision)
    add_child(floor)

func _on_hero_defeated() -> void:
    _log("WORLD", "Hero death handled; checkpoint respawn complete")
    if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
        _spawn_cultist()
    if not WorldState.boss_defeated and (not is_instance_valid(boss) or boss.is_queued_for_deletion()):
        _spawn_boss()
    if not is_instance_valid(hound) or hound.is_queued_for_deletion():
        _spawn_hound()

func _on_cultist_defeated() -> void:
    WorldState.open_boss_gate()
    _log("WORLD", "Cultist encounter cleared; Ash Gate unlocked")
    if is_instance_valid(boss_gate):
        boss_gate.open()
    if narrative:
        narrative.show_message("THE PATH OPENS", "The cultist falls. Somewhere beyond the iron gate, something hears the silence.")
    queue_redraw()

func _on_level_exit_reached() -> void:
    _log("WORLD", "Vertical Slice 001 acceptance boundary reached")
    if narrative:
        narrative.show_message("THE ROAD AWAITS", "The first road is behind you.\n\nThe church seal is warm in one hand. The lullaby is still somewhere behind the hills.\n\nVERTICAL SLICE 001 COMPLETE", 5.0)
    get_tree().create_timer(5.2).timeout.connect(_enter_selected_route)
    queue_redraw()

func _enter_selected_route() -> void:
    if WorldState.selected_route == "":
        return
    print("[NEREIS][ROUTE] Leaving Vertical Slice 001 -> %s" % WorldState.selected_route)
    SceneTransition.fade_to_scene(WorldState.get_route_scene_path())

func _open_first_choice() -> void:
    if narrative and WorldState.boss_defeated and not WorldState.first_choice_made:
        narrative.begin_first_choice()

func _on_boss_defeated() -> void:
    _log("BOSS", "Ashen Knight encounter cleared")
    if narrative:
        narrative.show_message("THE ASHEN KNIGHT", "The armor falls without a body inside.\n\nFor a moment, the Hero remembers kneeling before the church. Then the memory tears itself away.")
        get_tree().create_timer(2.0).timeout.connect(_open_first_choice)
    queue_redraw()

func _on_old_hunter_interacted() -> void:
    _log("STORY", "Old Hunter interaction accepted")
    if WorldState.first_memory_unlocked:
        narrative.play_weapon_upgrade()
    else:
        narrative.play_first_memory()
    queue_redraw()

func _process(_delta: float) -> void:
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_F4:
            hud.set_debug_visible(not hud.debug_enabled)
            _log("DEBUG", "Debug overlay=%s" % hud.debug_enabled)
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_F9:
            WorldState.delete_save()
            _log("DEBUG", "Run state reset; reloading scene")
            get_tree().reload_current_scene()
            get_viewport().set_input_as_handled()

func _log(category: String, message: String) -> void:
    print("[NEREIS][%s] %s" % [category, message])

func _draw_environment_backdrop() -> void:
    # Base illustration stays fixed to the level; transparent art layers add depth over it.
    draw_texture_rect(ASHEN_ROAD_BACKDROP, Rect2(0, 0, 2400, 720), false)

func _draw_parallax_layer(texture: Texture2D, scroll_factor: float, left_padding: float) -> void:
    var camera_x := camera.get_screen_center_position().x if is_instance_valid(camera) else 0.0
    var layer_x := camera_x * scroll_factor - left_padding
    draw_texture_rect(texture, Rect2(layer_x, 0, 3600, 720), false)

func _draw_house(origin: Vector2, width: float, height: float) -> void:
    draw_rect(Rect2(origin.x - width * 0.5, origin.y - height, width, height), Color("#29232b"))
    draw_colored_polygon(
        PackedVector2Array([
            Vector2(origin.x - width * 0.62, origin.y - height),
            Vector2(origin.x, origin.y - height - 72),
            Vector2(origin.x + width * 0.62, origin.y - height)
        ]),
        Color("#352d38")
    )
    draw_rect(Rect2(origin.x - 13, origin.y - 55, 26, 55), Color("#17141b"))
    draw_circle(Vector2(origin.x - 36, origin.y - 62), 7, Color("#796d67"))
    draw_circle(Vector2(origin.x + 36, origin.y - 62), 7, Color("#796d67"))

func _draw_dead_tree(origin: Vector2, height: float) -> void:
    draw_line(origin, origin + Vector2(-10, -height), Color("#2e272e"), 10.0)
    draw_line(origin + Vector2(0, -height * 0.62), origin + Vector2(-48, -height * 0.88), Color("#2e272e"), 6.0)
    draw_line(origin + Vector2(-10, -height * 0.45), origin + Vector2(44, -height * 0.7), Color("#2e272e"), 6.0)
    draw_line(origin + Vector2(-8, -height * 0.78), origin + Vector2(18, -height), Color("#2e272e"), 5.0)

func _draw() -> void:
    draw_rect(Rect2(0, 0, 2400, 720), Color("#111018"))
    _draw_environment_backdrop()
    _draw_parallax_layer(ASHEN_ROAD_FAR_MIST, 0.12, 0.0)
    _draw_parallax_layer(ASHEN_ROAD_MIDGROUND, 0.48, 250.0)
    draw_rect(Rect2(0, 520, 2400, 200), Color("#201c22"))
    for x in range(0, 2400, 64):
        draw_line(Vector2(x, 520), Vector2(x + 32, 552), Color("#302a30"), 2.0)

    draw_rect(Rect2(600, 445, 160, 75), Color("#27212a"))
    if not WorldState.boss_gate_open:
        draw_rect(Rect2(1730, 350, 140, 170), Color("#241d25"))
        draw_string(ThemeDB.fallback_font, Vector2(1750, 365), NereisLocalization.translate_text("ASH GATE"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#796d67"))
    draw_string(ThemeDB.fallback_font, Vector2(900, 490), NereisLocalization.translate_text("SAFE GROUND"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#796d67"))
    draw_string(ThemeDB.fallback_font, Vector2(605, 458), NereisLocalization.translate_text("OLD HUNTER"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#796d67"))

    draw_string(ThemeDB.fallback_font, Vector2(40, 235), NereisLocalization.translate_text("VILLAGE OUTSKIRTS"), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#4d454d"))
    draw_string(ThemeDB.fallback_font, Vector2(1240, 235), NereisLocalization.translate_text("THE ASHEN ROAD"), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#4d454d"))
    _draw_parallax_layer(ASHEN_ROAD_FOREGROUND, 1.08, 420.0)


