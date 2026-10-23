extends Node2D
## Animated ambience using scene-authored Polygon2D particles, never draw calls.
## 由场景树中预置的 Polygon2D 组成的动画氛围效果，不使用 _draw()。

var elapsed := 0.0
var fireflies: Array[Polygon2D] = []
var base_positions: Array[Vector2] = []
var phases: Array[float] = []
var speeds: Array[float] = []

func _ready() -> void:
	for child in get_children():
		if child is Polygon2D:
			var firefly := child as Polygon2D
			fireflies.append(firefly)
			base_positions.append(firefly.position)
			var index := fireflies.size() - 1
			phases.append(fposmod(float(index) * 2.399963, TAU))
			speeds.append(0.35 + fposmod(float(index) * 0.173, 0.55))
	_refresh_particles()


func _process(delta: float) -> void:
	elapsed += delta
	_refresh_particles()


func _refresh_particles() -> void:
	var resonance := WorldState.outer_god_resonance
	var control_stage: int = WorldState.mite_control_stage
	for i in range(fireflies.size()):
		var firefly := fireflies[i]
		var phase := phases[i]
		var speed := speeds[i]
		var drift := Vector2(
			sin(elapsed * speed + phase) * 22.0,
			cos(elapsed * speed * 0.7 + phase) * 16.0
		)
		var pulse := 0.5 + 0.5 * sin(elapsed * 1.8 + phase)
		firefly.position = base_positions[i] + drift
		firefly.scale = Vector2.ONE * (0.75 + pulse * 0.55)
		if resonance and i % 5 == 0:
			var sync_speed := 1.8 if control_stage < 2 else 0.9
			var sync := sin(elapsed * sync_speed + phase)
			firefly.position = base_positions[i] + Vector2(sin(elapsed * 0.8 + phase) * 30.0, sync * 26.0)
			firefly.color = Color(0.48, 0.34, 0.58, 0.12 + pulse * 0.16)
		else:
			firefly.color = Color(0.78, 0.70, 0.55, 0.10 + pulse * 0.15)
