extends Node

func _ready() -> void:
    var next_scene := "res://scenes/escape_prologue.tscn"

    if WorldState.prologue_complete:
        next_scene = WorldState.get_resume_scene_path()

    print("[NEREIS][BOOT] Resuming scene=%s prologue_complete=%s" % [next_scene, WorldState.prologue_complete])
    call_deferred("_change_to_resume_scene", next_scene)

func _change_to_resume_scene(scene_path: String) -> void:
    var tree := get_tree()
    if tree == null:
        return

    var result := tree.change_scene_to_file(scene_path)
    if result != OK:
        print("[NEREIS][BOOT][ERROR] Failed to resume scene=%s error=%d" % [scene_path, result])
