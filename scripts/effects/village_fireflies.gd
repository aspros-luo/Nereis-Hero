extends Node2D

const FIREFLY_COUNT := 26
const AREA := Rect2(80, 230, 2400, 300)

var points: Array[Vector2] = []
var phases: Array[float] = []
var speeds: Array[float] = []
var elapsed := 0.0

func _ready() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 918273
    for i in range(FIREFLY_COUNT):
        points.append(Vector2(
            rng.randf_range(AREA.position.x, AREA.end.x),
            rng.randf_range(AREA.position.y, AREA.end.y)
        ))
        phases.append(rng.randf_range(0.0, TAU))
        speeds.append(rng.randf_range(0.35, 0.9))
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    for i in range(points.size()):
        var drift := Vector2(
            sin(elapsed * speeds[i] + phases[i]) * 22.0,
            cos(elapsed * speeds[i] * 0.7 + phases[i]) * 16.0
        )
        var pulse := 0.5 + 0.5 * sin(elapsed * 1.8 + phases[i])
        draw_circle(points[i] + drift, 2.2 + pulse * 1.4, Color(0.78, 0.70, 0.55, 0.10 + pulse * 0.15))
