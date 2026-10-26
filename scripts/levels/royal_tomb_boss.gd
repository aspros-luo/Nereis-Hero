extends Node2D

const ASHEN_KNIGHT_SCENE: PackedScene = preload("res://scenes/enemies/ashen_knight.tscn")
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


func _enter_tree() -> void:
    WorldState.pending_region_spawn_side = "west"


func _ready() -> void:
    get_tree().paused = false
    WorldState.set_location("royal_tomb_boss")

    hero = $Hero as CharacterBody2D
    var camera := hero.get_node("HeroCamera") as Camera2D
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = int(ARENA_WIDTH)
    camera.limit_bottom = 720
    hero.defeated.connect(_on_hero_defeated)
    WorldState.set_checkpoint(hero.global_position)

    hud = $HUD as CanvasLayer
    narrative = $Narrative as CanvasLayer
    return_door = $ReturnToRoyalTomb as Area2D
    return_door.interacted.connect(_return_to_tomb)
    hud.bind_hero(hero)
    hud.set_story_mode("旧王墓｜王墓内殿", "击败守墓者，离开内殿后返回王墓主路。")
    hud.set_debug_visible(false)

    boss = $RoyalTombGuardian as CharacterBody2D
    if BOSS_FLAG in WorldState.achievement_flags:
        victory = true
        boss.queue_free()
        boss = null
        _enable_return_door()
        _show_victory_text()
    else:
        _connect_boss_signals()
        hud.bind_boss(boss)
        narrative.show_message(
            "被抹名的守墓者",
            "石棺之后传来沉重的拖行声。守墓者没有名字，盔甲上所有铭文都被凿成了相同的空白。\n\n它仍然记得如何守门。",
            5.5
        )
    queue_redraw()


func _connect_boss_signals() -> void:
    if not is_instance_valid(boss):
        return
    boss.defeated.connect(_on_boss_defeated)
    boss.phase_changed.connect(_on_boss_phase_changed)
    boss.attack_telegraphed.connect(_on_boss_attack_telegraphed)


func _spawn_boss() -> void:
    if victory or (is_instance_valid(boss) and not boss.is_queued_for_deletion()):
        return
    boss = ASHEN_KNIGHT_SCENE.instantiate() as CharacterBody2D
    if boss == null:
        push_error("Royal Tomb Boss: failed to instantiate AshenKnight scene")
        return
    boss.name = "RoyalTombGuardian"
    boss.set("boss_display_name", "王墓守墓者")
    boss.set("persist_global_boss_defeat", false)
    boss.set("visual_theme", "royal_tomb")
    boss.position = Vector2(1390.0, FLOOR_Y)
    add_child(boss)
    _connect_boss_signals()
    hud.bind_boss(boss)
    print("[NEREIS][BOSS][START] id=royal_tomb_guardian hp=%d" % int(boss.get("health")))


func _on_boss_defeated() -> void:
    if victory:
        return
    victory = true
    WorldState.record_achievement(BOSS_FLAG)
    print("[NEREIS][BOSS][VICTORY] id=royal_tomb_guardian persisted=true")
    _enable_return_door()
    _show_victory_text()
    queue_redraw()


func _show_victory_text() -> void:
    if is_instance_valid(narrative):
        narrative.call(
            "show_message",
            "无名之墓",
            "守墓者终于倒下。盔甲上的铭文被反复凿空，只剩无法辨认的痕迹。\n\n道路重新安静下来；那些被抹去的名字仍未得到答案。",
            5.5
        )


func _enable_return_door() -> void:
    return_door.visible = true
    return_door.enabled = true
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
    boss = null
    call_deferred("_respawn_boss_after_death")


func _respawn_boss_after_death() -> void:
    await get_tree().create_timer(0.35).timeout
    resetting_boss = false
    if is_inside_tree() and not victory:
        _spawn_boss()


func _on_boss_phase_changed(phase: int) -> void:
    if phase >= 2 and is_instance_valid(hud):
        hud.call("show_phase_two")
    print("[NEREIS][BOSS][PHASE] id=royal_tomb_guardian phase=%d" % phase)


func _on_boss_attack_telegraphed() -> void:
    print("[NEREIS][BOSS][TELEGRAPH] id=royal_tomb_guardian")


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
