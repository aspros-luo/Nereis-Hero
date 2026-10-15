extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const BOSS_SCRIPT = preload("res://scripts/enemies/ashen_knight.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const DOOR_SCRIPT = preload("res://scripts/world/interaction_door.gd")
const FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")
const FLOOR_Y := 540.0
const ARENA_WIDTH := 1800.0
const BOSS_FLAG := "defeated_royal_tomb_guardian"

var hero: CharacterBody2D
var boss: CharacterBody2D
var hud: CanvasLayer
var narrative: CanvasLayer
var return_door: Area2D
var victory := false
var resetting_boss := false

func _ready() -> void:
    get_tree().paused = false
    WorldState.pending_region_spawn_side = "west"
    WorldState.set_location("royal_tomb_boss")
    _create_arena()
    _spawn_hero()
    _spawn_hud()
    _spawn_narrative()
    if BOSS_FLAG in WorldState.achievement_flags:
        victory = true
        _spawn_return_door()
        _show_victory_text()
    else:
        _spawn_boss()
        if is_instance_valid(narrative):
            narrative.show_message(
                "被抹名的守墓者",
                "石棺之后传来沉重的拖行声。守墓者没有名字，盔甲上所有铭文都被凿成了相同的空白。\n\n它仍然记得如何守门。",
                5.5
            )
    queue_redraw()

func _create_arena() -> void:
    var floor := StaticBody2D.new()
    floor.name = "BossArenaFloor"
    floor.collision_layer = 1
    floor.collision_mask = 1
    var floor_shape := CollisionShape2D.new()
    var floor_rect := RectangleShape2D.new()
    floor_rect.size = Vector2(ARENA_WIDTH + 160.0, 40.0)
    floor_shape.shape = floor_rect
    floor_shape.position = Vector2(ARENA_WIDTH * 0.5, FLOOR_Y + 20.0)
    floor.add_child(floor_shape)
    add_child(floor)

    for wall_x in [-80.0, ARENA_WIDTH + 80.0]:
        var wall := StaticBody2D.new()
        wall.name = "ArenaBoundary"
        wall.collision_layer = 1
        wall.collision_mask = 1
        var wall_shape := CollisionShape2D.new()
        var wall_rect := RectangleShape2D.new()
        wall_rect.size = Vector2(40.0, 720.0)
        wall_shape.shape = wall_rect
        wall_shape.position = Vector2(wall_x, 360.0)
        wall.add_child(wall_shape)
        add_child(wall)

func _spawn_hero() -> void:
    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.name = "Hero"
    hero.position = Vector2(220.0, FLOOR_Y)
    _add_character_collision(hero, 18.0, 48.0)
    add_child(hero)
    hero.defeated.connect(_on_hero_defeated)
    WorldState.set_checkpoint(hero.global_position)

    var camera := Camera2D.new()
    camera.name = "HeroCamera"
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = int(ARENA_WIDTH)
    camera.limit_bottom = 720
    hero.add_child(camera)

func _spawn_boss() -> void:
    if victory or is_instance_valid(boss):
        return
    boss = CharacterBody2D.new()
    boss.set_script(BOSS_SCRIPT)
    boss.name = "RoyalTombGuardian"
    boss.set("boss_display_name", "王墓守墓者")
    boss.set("persist_global_boss_defeat", false)
    boss.set("visual_theme", "royal_tomb")
    boss.position = Vector2(1390.0, FLOOR_Y)
    _add_character_collision(boss, 26.0, 60.0)
    add_child(boss)
    boss.defeated.connect(_on_boss_defeated)
    boss.phase_changed.connect(_on_boss_phase_changed)
    boss.attack_telegraphed.connect(_on_boss_attack_telegraphed)
    if is_instance_valid(hud):
        hud.bind_boss(boss)
    print("[NEREIS][BOSS][START] id=royal_tomb_guardian hp=%d" % int(boss.get("health")))

func _spawn_hud() -> void:
    hud = CanvasLayer.new()
    hud.set_script(HUD_SCRIPT)
    add_child(hud)
    hud.bind_hero(hero)
    hud.set_story_mode("旧王墓｜王墓内殿", "击败守墓者，离开内殿后返回王墓主路。")
    hud.set_debug_visible(false)

func _spawn_narrative() -> void:
    narrative = CanvasLayer.new()
    narrative.set_script(NARRATIVE_SCRIPT)
    add_child(narrative)

func _on_boss_defeated() -> void:
    if victory:
        return
    victory = true
    WorldState.record_achievement(BOSS_FLAG)
    print("[NEREIS][BOSS][VICTORY] id=royal_tomb_guardian persisted=true")
    _spawn_return_door()
    _show_victory_text()
    queue_redraw()

func _show_victory_text() -> void:
    if is_instance_valid(narrative):
        narrative.show_message(
            "无名之墓",
            "守墓者终于倒下。盔甲上的铭文被反复凿空，只剩无法辨认的痕迹。\n\n道路重新安静下来；那些被抹去的名字仍未得到答案。",
            5.5
        )

func _spawn_return_door() -> void:
    if is_instance_valid(return_door):
        return
    return_door = Area2D.new()
    return_door.set_script(DOOR_SCRIPT)
    return_door.name = "ReturnToRoyalTomb"
    return_door.position = Vector2(1650.0, FLOOR_Y)
    return_door.prompt_text = "E  返回旧王墓主路"
    return_door.enabled = true
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = Vector2(110.0, 80.0)
    shape.shape = rect
    shape.position = Vector2(0.0, -35.0)
    return_door.add_child(shape)
    add_child(return_door)
    return_door.interacted.connect(_return_to_tomb)
    print("[NEREIS][BOSS][EXIT] return door enabled")

func _return_to_tomb() -> void:
    FOCUS_SCRIPT.clear_all(get_tree())
    WorldState.pending_region_spawn_side = "boss_return"
    WorldState.set_location("royal_tomb")
    print("[NEREIS][BOSS][EXIT] to=royal_tomb spawn_side=boss_return")
    SceneTransition.fade_to_scene("res://scenes/royal_tomb.tscn")

func _on_hero_defeated() -> void:
    if victory or resetting_boss:
        return
    resetting_boss = true
    print("[NEREIS][BOSS][RESET] hero defeated; boss encounter reset")
    if is_instance_valid(boss):
        boss.queue_free()
    call_deferred("_respawn_boss_after_death")

func _respawn_boss_after_death() -> void:
    await get_tree().create_timer(0.35).timeout
    resetting_boss = false
    if is_inside_tree() and not victory:
        _spawn_boss()

func _on_boss_phase_changed(phase: int) -> void:
    if phase >= 2 and is_instance_valid(hud):
        hud.show_phase_two()
    print("[NEREIS][BOSS][PHASE] id=royal_tomb_guardian phase=%d" % phase)

func _on_boss_attack_telegraphed() -> void:
    print("[NEREIS][BOSS][TELEGRAPH] id=royal_tomb_guardian")

func _add_character_collision(character: CharacterBody2D, radius: float, height: float) -> void:
    var collision := CollisionShape2D.new()
    var capsule := CapsuleShape2D.new()
    capsule.radius = radius
    capsule.height = height
    collision.shape = capsule
    collision.position = Vector2(0.0, -height * 0.5)
    character.add_child(collision)

func _draw() -> void:
    draw_rect(Rect2(0.0, 0.0, ARENA_WIDTH, 720.0), Color("#100e13"))
    draw_rect(Rect2(0.0, FLOOR_Y, ARENA_WIDTH, 180.0), Color("#211b22"))
    for x in [120.0, 330.0, 620.0, 910.0, 1200.0, 1500.0, 1710.0]:
        draw_line(Vector2(x, FLOOR_Y - 8.0), Vector2(x + 18.0, 285.0), Color("#382a32"), 7.0)
        draw_line(Vector2(x + 18.0, 285.0), Vector2(x + 52.0, 345.0), Color("#382a32"), 5.0)
    draw_rect(Rect2(470.0, 110.0, 860.0, 8.0), Color("#45313a"))
    draw_rect(Rect2(510.0, 110.0, 8.0, 130.0), Color("#45313a"))
    draw_rect(Rect2(1290.0, 110.0, 8.0, 130.0), Color("#45313a"))
    draw_circle(Vector2(900.0, FLOOR_Y - 14.0), 180.0, Color(0.24, 0.12, 0.16, 0.22))
    if victory:
        draw_circle(Vector2(900.0, FLOOR_Y - 18.0), 70.0, Color(0.60, 0.40, 0.26, 0.08))
