extends CanvasLayer

const WITCH_TIME_SHADER: Shader = preload("res://scripts/effects/witch_time_overlay.gdshader")
const ACTIVATION_BURST_DURATION := 0.38

var _activation_elapsed := 0.0
var _material: ShaderMaterial

func _ready() -> void:
    # Keep this between the world canvas and the gameplay HUD (the HUD uses layer 10).
    # 放在世界画布与游戏 HUD 之间（游戏 HUD 使用第 10 层）。
    layer = 8
    process_mode = Node.PROCESS_MODE_ALWAYS

    var overlay := ColorRect.new()
    overlay.name = "TemporalVioletOverlay"
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.color = Color.WHITE

    _material = ShaderMaterial.new()
    _material.shader = WITCH_TIME_SHADER
    _material.set_shader_parameter("effect_strength", 1.0)
    _material.set_shader_parameter("burst_strength", 1.0)
    overlay.material = _material
    add_child(overlay)
    _activation_elapsed = 0.0

func play_activation() -> void:
    # A short edge streak / crystal-like burst marks entry; the tint then stays subtle.
    # 触发瞬间从屏幕边缘划过短暂光线与晶体闪点，之后只保留轻微染色。
    _activation_elapsed = 0.0
    if _material != null:
        _material.set_shader_parameter("burst_strength", 1.0)

func _process(delta: float) -> void:
    if _activation_elapsed >= ACTIVATION_BURST_DURATION:
        return
    _activation_elapsed = minf(_activation_elapsed + delta, ACTIVATION_BURST_DURATION)
    var remaining := 1.0 - _activation_elapsed / ACTIVATION_BURST_DURATION
    if _material != null:
        _material.set_shader_parameter("burst_strength", remaining)
