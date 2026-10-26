extends Control
class_name NereisEndingCGOverlay

@onready var cg: TextureRect = $CG
@onready var vignette: ColorRect = $Vignette

var route_id := ""

const CG_PATHS := {
    "human": "res://assets/cg/ending_human.svg",
    "paradise": "res://assets/cg/ending_paradise.svg",
    "fire": "res://assets/cg/ending_fire.svg"
}


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    cg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    cg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
    cg.modulate.a = 0.0
    cg.pivot_offset = Vector2(640, 360)
    cg.scale = Vector2(1.035, 1.035)


func setup(route: String) -> void:
    route_id = route
    var path: String = CG_PATHS.get(route_id, "")
    if path.is_empty():
        return
    var texture := load(path)
    if texture is Texture2D:
        cg.texture = texture


func play() -> void:
    if cg == null or cg.texture == null:
        return
    cg.modulate.a = 0.0
    cg.scale = Vector2(1.045, 1.045)
    var tween := create_tween()
    tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.set_parallel(true)
    tween.tween_property(cg, "modulate:a", 1.0, 1.6)
    tween.tween_property(cg, "scale", Vector2(1.0, 1.0), 8.0)
    tween.set_parallel(false)


func hold() -> void:
    if cg == null:
        return
    var tween := create_tween()
    tween.set_loops()
    tween.tween_property(cg, "scale", Vector2(1.012, 1.012), 4.5)
    tween.tween_property(cg, "scale", Vector2(1.0, 1.0), 4.5)


func pulse() -> void:
    if cg == null:
        return
    var tween := create_tween()
    tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_property(cg, "modulate:a", 0.78, 0.18)
    tween.tween_property(cg, "modulate:a", 1.0, 0.5)
