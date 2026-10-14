extends CharacterBody2D
class_name StickmanTrainingDummy

@export var max_health: float = 100.0
@export var knockback_damping: float = 520.0

var health: float = 100.0
var hurt_flash_remaining: float = 0.0
var last_hit_direction: float = 0.0
var last_damage: float = 0.0

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
	last_damage = amount
	last_hit_direction = signf(knockback)
	velocity.x = knockback
	hurt_flash_remaining = 0.22
	queue_redraw()
	if health <= 0.0:
		# Training target resets automatically so the prototype can be tested repeatedly.
		health = max_health


func _draw() -> void:
	var flash: bool = hurt_flash_remaining > 0.0
	var body_color: Color = Color(1.0, 0.86, 0.38, 1.0) if flash else Color(0.66, 0.48, 0.31, 1.0)
	var outline: Color = Color(0.08, 0.07, 0.07, 1.0)
	# Large, high-contrast padded dummy silhouette, readable at prototype camera zoom.
	draw_rect(Rect2(Vector2(-13.0, -27.0), Vector2(26.0, 27.0)), outline, true)
	draw_rect(Rect2(Vector2(-9.0, -24.0), Vector2(18.0, 20.0)), body_color, true)
	draw_circle(Vector2(0.0, -39.0), 10.0, outline)
	draw_circle(Vector2(0.0, -39.0), 7.5, body_color)
	draw_line(Vector2(-11.0, -20.0), Vector2(-20.0, -8.0), outline, 7.0, true)
	draw_line(Vector2(11.0, -20.0), Vector2(20.0, -8.0), outline, 7.0, true)
	draw_line(Vector2(-6.0, -1.0), Vector2(-10.0, 0.0), outline, 7.0, true)
	draw_line(Vector2(6.0, -1.0), Vector2(10.0, 0.0), outline, 7.0, true)
	# A visible stand and target label make it obvious this is the combat target.
	draw_line(Vector2(0.0, 1.0), Vector2(0.0, 7.0), Color(0.25, 0.23, 0.21, 1.0), 3.0, true)
	draw_line(Vector2(-13.0, 7.0), Vector2(13.0, 7.0), Color(0.25, 0.23, 0.21, 1.0), 3.0, true)
	draw_string(ThemeDB.fallback_font, Vector2(-24.0, -54.0), "TRAINING DUMMY", HORIZONTAL_ALIGNMENT_LEFT, 100.0, 9, Color(1.0, 1.0, 1.0, 1.0))
	var bar_width: float = 44.0
	draw_rect(Rect2(Vector2(-bar_width * 0.5, -59.0), Vector2(bar_width, 5.0)), Color(0.10, 0.08, 0.08, 1.0), true)
	draw_rect(Rect2(Vector2(-bar_width * 0.5, -59.0), Vector2(bar_width * health / maxf(max_health, 1.0), 5.0)), Color(0.88, 0.20, 0.16, 1.0), true)
	if flash:
		draw_string(ThemeDB.fallback_font, Vector2(12.0, -31.0), "-%d" % roundi(last_damage), HORIZONTAL_ALIGNMENT_LEFT, 40.0, 12, Color(1.0, 0.92, 0.70, 1.0))
