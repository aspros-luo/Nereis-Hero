extends Node2D

## A lightweight cutscene-only church pursuer silhouette.
## 仅用于序章收束演出的教会追兵剪影，不参与战斗或关卡碰撞。

@export var variant := 0
@export var lantern := false
var reveal := 0.0
var animation_time := 0.0
var healing_time := 0.0

func play_healing() -> void:
	healing_time = 2.4
	queue_redraw()

func _ready() -> void:
	z_index = 4
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	animation_time += delta
	reveal = minf(1.0, reveal + delta * 2.8)
	healing_time = maxf(0.0, healing_time - delta)
	queue_redraw()

func _draw() -> void:
	var alpha := smoothstep(0.0, 1.0, reveal)
	if healing_time > 0.0:
		var heal_alpha := clampf(healing_time / 2.4, 0.0, 1.0)
		var pulse := 1.0 + sin(animation_time * 11.0) * 0.18
		draw_circle(Vector2(0, -52), 26.0 * pulse, Color(0.76, 0.86, 1.0, heal_alpha * 0.10))
		draw_arc(Vector2(0, -52), 30.0 * pulse, 0.0, TAU, 32, Color(0.78, 0.88, 1.0, heal_alpha * 0.8), 3.0)
	var sway := sin(animation_time * 2.2 + float(variant)) * 1.5
	var cloth := Color("#171821", alpha)
	var edge := Color("#47404a", alpha)
	var metal := Color("#77717a", alpha)
	# Hood and face void.
	draw_circle(Vector2(0, -62 + sway), 12.0, cloth)
	draw_circle(Vector2(1, -61 + sway), 7.0, Color("#07080d", alpha))
	# Long, weathered robe.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10, -49 + sway), Vector2(10, -49 + sway),
		Vector2(17, -8), Vector2(25, 0), Vector2(-22, 0),
		Vector2(-16, -8)
	]), cloth)
	draw_line(Vector2(-8, -43 + sway), Vector2(-15, -9), edge, 3.0)
	draw_line(Vector2(7, -43 + sway), Vector2(12, -11), edge, 2.0)
	# A long polearm marks the group as church pursuers rather than villagers.
	var pole_x := 18.0 if variant % 2 == 0 else -18.0
	draw_line(Vector2(pole_x, -8), Vector2(pole_x + 5.0, -91), cloth, 4.0)
	draw_line(Vector2(pole_x, -8), Vector2(pole_x + 5.0, -91), metal, 1.4)
	draw_colored_polygon(PackedVector2Array([
		Vector2(pole_x + 1, -84), Vector2(pole_x + 5, -101),
		Vector2(pole_x + 10, -84)
	]), metal)
	if lantern:
		draw_line(Vector2(-8, -39 + sway), Vector2(-22, -25 + sway), cloth, 4.0)
		draw_line(Vector2(-22, -25 + sway), Vector2(-26, -14 + sway), cloth, 3.0)
		draw_rect(Rect2(-31, -17 + sway, 10, 12), Color("#8b7250", alpha))
		draw_circle(Vector2(-26, -11 + sway), 10.0, Color(0.83, 0.59, 0.30, alpha * 0.12))
	# Feet remain close to the ground plane.
	draw_line(Vector2(-7, -4), Vector2(-10, 0), cloth, 5.0)
	draw_line(Vector2(8, -4), Vector2(11, 0), cloth, 5.0)
