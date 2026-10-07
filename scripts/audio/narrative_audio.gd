extends Node

var players: Array[AudioStreamPlayer] = []
var lullaby: AudioStreamWAV
var corrupted_lullaby: AudioStreamWAV

func _ready() -> void:
    lullaby = _make_sequence([261.63, 329.63, 392.0, 329.63, 293.66, 261.63], 0.28, -21.0)
    corrupted_lullaby = _make_sequence([261.63, 329.63, 389.0, 311.0, 293.66, 207.65], 0.34, -20.0)
    for i in range(2):
        var player := AudioStreamPlayer.new()
        player.name = "NarrativePlayer_%d" % i
        add_child(player)
        players.append(player)

func play_lullaby() -> void:
    _play(lullaby)

func play_corrupted_lullaby() -> void:
    _play(corrupted_lullaby)

func _play(stream: AudioStreamWAV) -> void:
    if players.is_empty() or stream == null:
        return
    var player := players[0]
    if player.playing:
        player.stop()
    player.stream = stream
    player.play()

func _make_sequence(notes: Array[float], note_duration: float, volume_db: float) -> AudioStreamWAV:
    var rate := 22050
    var gap := 0.035
    var total_duration := notes.size() * (note_duration + gap)
    var sample_count := maxi(1, int(total_duration * rate))
    var bytes := PackedByteArray()
    bytes.resize(sample_count * 2)

    var amplitude := pow(10.0, volume_db / 20.0)

    for i in range(sample_count):
        var t := float(i) / float(rate)
        var note_span := note_duration + gap
        var note_index := int(t / note_span)

        if note_index >= notes.size():
            bytes[i * 2] = 0
            bytes[i * 2 + 1] = 0
            continue

        var local_t := fmod(t, note_span)
        var sample := 0.0

        if local_t < note_duration:
            var frequency: float = notes[note_index]
            var phase := TAU * frequency * local_t
            var attack := clampf(local_t / 0.035, 0.0, 1.0)
            var release := clampf((note_duration - local_t) / 0.09, 0.0, 1.0)
            var harmonic := sin(phase * 2.0) * 0.14
            sample = (sin(phase) + harmonic) * amplitude * attack * release

        var value := clampi(int(sample * 32767.0), -32768, 32767)
        bytes[i * 2] = value & 0xFF
        bytes[i * 2 + 1] = (value >> 8) & 0xFF

    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = rate
    stream.stereo = false
    stream.data = bytes
    return stream
