extends CanvasLayer

const WITCH_TIME_SHADER: Shader = preload("res://scripts/effects/witch_time_overlay.gdshader")
const ACTIVATION_BURST_DURATION := 0.38

var _activation_elapsed := 0.0
@onready var overlay: ColorRect = $TemporalVioletOverlay
@onready var _activation_player: AudioStreamPlayer = $WitchTimeActivationSfx
var _material: ShaderMaterial

func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = WITCH_TIME_SHADER
	_material.set_shader_parameter("effect_strength", 1.0)
	_material.set_shader_parameter("burst_strength", 1.0)
	overlay.material = _material
	_activation_player.stream = _make_activation_sound()
	play_activation()
func play_activation() -> void:
    # A short edge streak / crystal-like burst marks entry; the tint then stays subtle.
    # 触发瞬间从屏幕边缘划过短暂光线与晶体闪点，之后只保留轻微染色。
    _activation_elapsed = 0.0
    if _material != null:
        _material.set_shader_parameter("burst_strength", 1.0)
    if is_instance_valid(_activation_player):
        _activation_player.stop()
        _activation_player.play()

func _make_activation_sound() -> AudioStreamWAV:
    # Original procedural cue: sub pulse + descending crystal partials + a reverse-breath swell.
    # 原创程序合成音：低频脉冲、下滑的水晶泛音，以及倒吸气般渐起的气流尾音。
    var sample_rate := 22050
    var duration := 0.62
    var sample_count := int(duration * float(sample_rate))
    var bytes := PackedByteArray()
    bytes.resize(sample_count * 4) # stereo, signed 16-bit PCM

    var air_filter := 0.0
    for i in range(sample_count):
        var t := float(i) / float(sample_rate)
        var noise_source := sin(float(i) * 12.9898) * sin(float(i) * 0.067 + 2.1)
        air_filter = lerpf(air_filter, noise_source, 0.28)
        var reverse_swell := smoothstep(0.0, 0.34, t) * exp(-maxf(t - 0.34, 0.0) * 8.0)

        var low_pulse := sin(TAU * (72.0 * t - 7.0 * t * t)) * exp(-t * 10.0) * 0.42
        var crystal_a := sin(TAU * (1040.0 * t - 280.0 * t * t)) * exp(-t * 5.8) * 0.31
        var crystal_b := sin(TAU * (1660.0 * t - 340.0 * t * t) + 0.7) * exp(-t * 8.5) * 0.16
        var crystal_c := sin(TAU * (2480.0 * t - 470.0 * t * t) + 1.1) * exp(-t * 11.0) * 0.06
        var onset_tick := sin(TAU * 2380.0 * t) * exp(-t * 55.0) * 0.10
        var airy_pull := air_filter * reverse_swell * 0.17
        var tail := clampf((duration - t) / 0.055, 0.0, 1.0)
        var mixed := clampf((low_pulse + crystal_a + crystal_b + crystal_c + onset_tick + airy_pull) * tail * 0.78, -0.95, 0.95)

        # Tiny left/right movement adds width without masking directional combat audio.
        var left_sample := mixed * (0.94 + 0.06 * sin(TAU * 1.7 * t))
        var right_sample := mixed * (0.94 + 0.06 * cos(TAU * 1.3 * t))
        var left_value := int(clampf(left_sample, -1.0, 1.0) * 32767.0)
        var right_value := int(clampf(right_sample, -1.0, 1.0) * 32767.0)
        var byte_offset := i * 4
        bytes[byte_offset] = left_value & 0xFF
        bytes[byte_offset + 1] = (left_value >> 8) & 0xFF
        bytes[byte_offset + 2] = right_value & 0xFF
        bytes[byte_offset + 3] = (right_value >> 8) & 0xFF

    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = sample_rate
    stream.stereo = true
    stream.data = bytes
    return stream

func _process(delta: float) -> void:
    if _activation_elapsed >= ACTIVATION_BURST_DURATION:
        return
    _activation_elapsed = minf(_activation_elapsed + delta, ACTIVATION_BURST_DURATION)
    var remaining := 1.0 - _activation_elapsed / ACTIVATION_BURST_DURATION
    if _material != null:
        _material.set_shader_parameter("burst_strength", remaining)
