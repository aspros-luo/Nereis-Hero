extends CanvasLayer

var overlay: ColorRect
var transitioning := false

func _ready() -> void:
    layer = 100
    overlay = ColorRect.new()
    overlay.color = Color("#08070a")
    overlay.modulate.a = 0.0
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.position = Vector2.ZERO
    overlay.size = get_viewport().get_visible_rect().size
    add_child(overlay)
    get_viewport().size_changed.connect(_resize_overlay)

func _resize_overlay() -> void:
    if overlay:
        overlay.size = get_viewport().get_visible_rect().size

func fade_to_scene(scene_path: String) -> void:
    if transitioning:
        return
    transitioning = true

    WorldState.input_locked = false
    var fade_out := create_tween()
    fade_out.tween_property(overlay, "modulate:a", 1.0, 0.22)
    await fade_out.finished

    var result := get_tree().change_scene_to_file(scene_path)
    if result != OK:
        print("[NEREIS][SCENE][ERROR] Failed to load scene=%s error=%d" % [scene_path, result])
        var recover := create_tween()
        recover.tween_property(overlay, "modulate:a", 0.0, 0.2)
        await recover.finished
        transitioning = false
        return

    await get_tree().process_frame

    var fade_in := create_tween()
    fade_in.tween_property(overlay, "modulate:a", 0.0, 0.32)
    await fade_in.finished
    transitioning = false
    print("[NEREIS][SCENE] Transition complete scene=%s" % scene_path)
