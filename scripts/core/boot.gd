extends Node

func _ready() -> void:
    var next_scene := "res://scenes/escape_prologue.tscn"

    if WorldState.prologue_complete:
        next_scene = WorldState.get_resume_scene_path()

    print("[NEREIS][BOOT] Resuming scene=%s prologue_complete=%s" % [next_scene, WorldState.prologue_complete])
    get_tree().change_scene_to_file(next_scene)
