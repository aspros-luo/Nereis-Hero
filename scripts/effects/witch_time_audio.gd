extends Node

const SAMPLE_RATE := 22050
const DURATION := 0.24

func _ready() -> void:
    var player := AudioStreamPlayer.new()
    player.name = "WitchTimeChime"
    player.volume_db = -9.0
    player.stream = _build_stream()
    add_child(player)
    player.finished.connect(queue_free)
    player.play()

func _build_stream() -> AudioStreamWAV:
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = SAMPLE_RATE
    stream.stereo = false

    var sample_count := int(SAMPLE_RATE * DURATION)
    var pcm := PackedByteArray()
    pcm.resize(sample_count * 2)
    var phase := 0.0
    for i in range(sample_count):
        var t := float(i) / float(SAMPLE_RATE)
        var progress := t / DURATION
        var frequency := lerpf(760.0, 210.0, progress)
        phase += TAU * frequency / float(SAMPLE_RATE)
        var envelope := pow(1.0 - progress, 1.8)
        var tone := sin(phase) * 0.68 + sin(phase * 2.01) * 0.22 + sin(phase * 0.5) * 0.10
        var sample := clampf(tone * envelope * 0.46, -1.0, 1.0)
        pcm.encode_s16(i * 2, int(sample * 32767.0))
    stream.data = pcm
    return stream
