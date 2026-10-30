@tool
extends Node2D

var hero: CharacterBody2D
var hud: CanvasLayer
var exit_door: Area2D
var sword_event_completed := false

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    if WorldState.prologue_complete:
        get_tree().change_scene_to_file("res://scenes/regions/village_hub.tscn")
        return
    hero = $Hero
    hud = $HUD
    exit_door = $S01ExitDoor
    WorldState.set_location("church_escape_s01")
    WorldState.record_natural_test_region("A0", "church_escape_s01")
    if not WorldState.checkpoint_active or WorldState.checkpoint_room_id != "a0_s01_surgery":
        WorldState.set_checkpoint(hero.global_position, "a0_s01_surgery")
    hero.defeated.connect(_on_hero_defeated)
    exit_door.interacted.connect(_on_s01_exit_interacted)
    var clue := $SurgicalMark
    clue.examined.connect(_on_clue_examined.bind(clue))
    hud.bind_hero(hero)
    hud.set_story_mode("A0｜教会手术所", "查看手术托盘和周边物品，寻找离开的路。")
    if WorldState.has_long_sword:
        $LongSwordVisual.visible = false
        sword_event_completed = true

func _on_clue_examined(clue: Node) -> void:
    WorldState.mark_ancient_residue_awakened()
    hud.call("show_item_description", clue.display_name, clue.description)

func _on_s01_exit_interacted() -> void:
    if WorldState.input_locked:
        return
    if not WorldState.has_long_sword:
        if not WorldState.acquire_long_sword_and_equip():
            hud.call("show_item_acquisition_error", "长剑")
            return
        sword_event_completed = true
        $LongSwordVisual.visible = false
        if hud.has_method("show_pickup_notification"):
            hud.call("show_pickup_notification", "长剑", 1)
    elif WorldState.current_weapon_style != "long_sword" and not WorldState.has_short_blade:
        WorldState.current_weapon_style = "long_sword"
        if not WorldState.save_game():
            hud.call("show_item_acquisition_error", "长剑")
            return
    WorldState.input_locked = true
    WorldState.pending_region_spawn_side = "west"
    WorldState.set_location("church_escape_s02")
    print("[NEREIS][A0][S01] Sword discovery complete; entering S02")
    SceneTransition.fade_to_scene("res://scenes/regions/a0_s02_escape.tscn")

func _on_hero_defeated() -> void:
    if is_instance_valid(hud):
        hud.set_story_mode("A0｜教会手术所", "你在手术室中恢复了意识。出口仍在前方。")

func _unhandled_input(event: InputEvent) -> void:
    if WorldState.debug_map_test_mode and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
        get_viewport().set_input_as_handled()
        get_tree().change_scene_to_file("res://scenes/debug/world_map_test_menu.tscn")
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
        get_viewport().set_input_as_handled()
        WorldState.delete_save()
        get_tree().change_scene_to_file("res://scenes/regions/escape_prologue.tscn")
