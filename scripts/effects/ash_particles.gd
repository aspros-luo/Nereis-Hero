extends Node2D

const PARTICLE_COUNT := 44
const AREA_WIDTH := 2400.0
const AREA_HEIGHT := 520.0

var positions := PackedVector2Array()
var speeds := PackedFloat32Array()
var sizes := PackedFloat32Array()
var phases := PackedFloat32Array()

func _ready() -> void:
    for i in range(PARTICLE_COUNT):
        positions.append(Vector2(randf_range(0.0, AREA_WIDTH), randf_range(100.0, AREA_HEIGHT)))
        speeds.append(randf_range(8.0, 22.0))
        sizes.append(randf_range(1.0, 2.8))
        phases.append(randf_range(0.0, TAU))
    z_index = 5
    queue_redraw()

func _process(delta: float) -> void:
    for i in range(PARTICLE_COUNT):
        positions[i].y += speeds[i] * delta
        positions[i].x += sin(Time.get_ticks_msec() * 0.00035 + phases[i]) * 5.0 * delta
        if positions[i].y > AREA_HEIGHT:
            positions[i].y = randf_range(80.0, 140.0)
            positions[i].x = randf_range(0.0, AREA_WIDTH)
    queue_redraw()

func _draw() -> void:
    for i in range(PARTICLE_COUNT):
        var alpha: float = 0.18 + sin(Time.get_ticks_msec() * 0.001 + phases[i]) * 0.07
        draw_circle(positions[i], sizes[i], Color(0.64, 0.57, 0.55, alpha))
