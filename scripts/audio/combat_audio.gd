extends Node

var streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var player_cursor := 0

func _ready() -> void:
    _build_sounds()
    for i in range(8):
        var player := AudioStreamPlayer.new()
        player.name = "SfxPlayer_%d" % i
        add_child(player)
        players.append(player)

func _build_sounds() -> void:
    streams["attack"] = _make_tone(240.0, 0.10, -14.0, 1.7, 0.18)
    streams["telegraph"] = _make_tone(330.0, 0.07, -15.0, 0.15, 0.04)
    streams["hit"] = _make_tone(110.0, 0.08, -9.0, 2.2, 0.10)
    streams["dodge"] = _make_tone(520.0, 0.12, -12.0, 0.65, 0.20)
    streams["hurt"] = _make_tone(82.0, 0.13, -10.0, 1.3, 0.16)
    streams["death"] = _make_tone(58.0, 0.34, -7.0, 2.0, 0.18)
    streams["gate"] = _make_chord([98.0, 147.0, 196.0], 0.42, -12.0)
    streams["phase"] = _make_chord([73.0, 110.0, 165.0], 0.72, -8.0)
    streams["boss_death"] = _make_chord([196.0, 147.0, 98.0], 0.90, -6.0)

func play_sfx(id: String) -> void:
    if not streams.has(id) or players.is_empty():
        return
    player_cursor = (player_cursor + 1) % players.size()
    var player: AudioStreamPlayer = players[player_cursor]
    player.stream = streams[id]
    player.play()

func _make_tone(frequency: float, duration: float, volume_db: float, sweep: float, attack: float) -> AudioStreamWAV:
    var rate := 22050
    var sample_count := maxi(1, int(duration * rate))
    var bytes := PackedByteArray()
    bytes.resize(sample_count * 2)
    var amplitude := pow(10.0, volume_db / 20.0)
    for i in range(sample_count):
        var t: float = float(i) / float(rate)
        var phase: float = TAU * (frequency * t + 0.5 * sweep * frequency * t * t)
        var envelope_in: float = clampf(t / maxf(attack, 0.001), 0.0, 1.0)
        var envelope_out: float = clampf((duration - t) / 0.05, 0.0, 1.0)
        var sample: float = sin(phase) * amplitude * envelope_in * envelope_out
        var value: int = clampi(int(sample * 32767.0), -32768, 32767)
        bytes[i * 2] = value & 0xFF
        bytes[i * 2 + 1] = (value >> 8) & 0xFF
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = rate
    stream.stereo = false
    stream.data = bytes
    return stream

func _make_chord(frequencies: Array[float], duration: float, volume_db: float) -> AudioStreamWAV:
    var rate := 22050
    var sample_count := maxi(1, int(duration * rate))
    var bytes := PackedByteArray()
    bytes.resize(sample_count * 2)
    var amplitude := pow(10.0, volume_db / 20.0) / maxf(float(frequencies.size()), 1.0)
    for i in range(sample_count):
        var t: float = float(i) / float(rate)
        var mix: float = 0.0
        for frequency in frequencies:
            mix += sin(TAU * frequency * t)
        var envelope: float = clampf((duration - t) / 0.08, 0.0, 1.0)
        var value: int = clampi(int(mix * amplitude * envelope * 32767.0), -32768, 32767)
        bytes[i * 2] = value & 0xFF
        bytes[i * 2 + 1] = (value >> 8) & 0xFF
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = rate
    stream.stereo = false
    stream.data = bytes
    return stream
