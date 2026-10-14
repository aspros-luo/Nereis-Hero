extends Node2D
class_name HeroSkeletonVisual

## Phase S1.1 visual prototype.
## Uses Line2D instead of polygon rendering to avoid triangulation failures.

@export var line_width: float = 4.0

func _ready() -> void:
	_build_visual()

func _build_visual() -> void:
	_create_line("Body", [Vector2(0, -20), Vector2(0, 20)])
	_create_line("ArmLeft", [Vector2(0, -10), Vector2(-18, 5)])
	_create_line("ArmRight", [Vector2(0, -10), Vector2(18, 5)])
	_create_line("LegLeft", [Vector2(0, 20), Vector2(-12, 40)])
	_create_line("LegRight", [Vector2(0, 20), Vector2(12, 40)])
	_create_line("Sword", [Vector2(18, 5), Vector2(45, -5)])

func _create_line(node_name: String, points: Array[Vector2]) -> void:
	var line := Line2D.new()
	line.name = node_name
	line.width = line_width
	line.points = PackedVector2Array(points)
	add_child(line)
