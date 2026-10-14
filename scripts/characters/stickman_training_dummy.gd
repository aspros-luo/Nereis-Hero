extends CharacterBody2D
class_name StickmanTrainingDummy

@export var max_health: float = 100.0
@export var knockback_damping: float = 520.0

var health: float = 100.0
var hurt_flash_remaining: float = 0.0
var last_hit_direction: float = 0.0

func _ready() -> void:
	health = max_health
	add_to_group("damageable")
	queue_redraw()


func _physics_process(delta: float) -> void:
	hurt_flash_remaining = maxf(0.0, hurt_flash_remaining - delta)
	velocity.x = move_toward(velocity.x, 0.0, knockback_damping * delta)
	move_and_slide()
	queue_redraw()


func take_damage(amount: float, knockback: float) -> void:
	if amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	last_hit_direction = signf(knockback)
	velocity.x = knockback
	hurt_flash_remaining = 0.16
	queue_redraw()
	if health <= 0.0:
		# Training target resets automatically so the prototype can be tested repeatedly.
		health = max_health


func _draw() -> void:
	var flash: bool = hurt_flash_remaining > 0.0
	var body_color: Color = Color(0.94, 0.72, 0.58, 1.0) if flash else Color(0.48, 0.44, 0.40, 1.0)
	var outline: Color = Color(0.10, 0.09, 0.10, 1.0)
	# Compact padded dummy silhouette, with the head/body separation easy to read.
	draw_circle(Vector2(0.0, -28.0), 7.0, outline)
	draw_circle(Vector2(0.0, -28.0), 5.5, body_color)
	draw_line(Vector2(0.0, -21.0), Vector2(0.0, -4.0), outline, 8.0, true)
	draw_line(Vector2(0.0, -21.0), Vector2(0.0, -4.0), body_color, 5.0, true)
	draw_line(Vector2(0.0, -18.0), Vector2(-9.0, -10.0), outline, 5.0, true)
	draw_line(Vector2(0.0, -18.0), Vector2(9.0, -10.0), outline, 5.0, true)
	draw_line(Vector2(0.0, -4.0), Vector2(-7.0, 0.0), outline, 5.0, true)
	draw_line(Vector2(0.0, -4.0), Vector2(7.0, 0.0), outline, 5.0, true)
	var bar_width: float = 34.0
	draw_rect(Rect2(Vector2(-bar_width * 0.5, -42.0), Vector2(bar_width, 4.0)), Color(0.12, 0.10, 0.10, 1.0), true)
	draw_rect(Rect2(Vector2(-bar_width * 0.5, -42.0), Vector2(bar_width * health / max_health, 4.0)), Color(0.76, 0.24, 0.20, 1.0), true)
