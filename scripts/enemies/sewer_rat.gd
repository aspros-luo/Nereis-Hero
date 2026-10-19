extends CharacterBody2D

const HITBOX_SCRIPT = preload("res://scripts/combat/hitbox.gd")
const HURTBOX_SCRIPT = preload("res://scripts/combat/hurtbox.gd")
const HIT_SPARK_SCRIPT = preload("res://scripts/effects/hit_spark.gd")
const DEATH_BURST_SCRIPT = preload("res://scripts/effects/death_burst.gd")

signal defeated

const MOVE_SPEED := 72.0
const ATTACK_RANGE := 54.0
const ATTACK_COOLDOWN := 1.8

var health := 24
var facing := -1.0
var attack_timer := 0.0
var stun_time := 0.0
var hit_flash := 0.0
var animation_time := 0.0
var attack_hitbox: Area2D

func _ready() -> void:
	add_to_group("combat_enemies")
	attack_hitbox = Area2D.new()
	attack_hitbox.name = "AttackHitbox"
	attack_hitbox.set_script(HITBOX_SCRIPT)
	add_child(attack_hitbox)
	attack_hitbox.setup(self, Vector2(34.0, 22.0), Vector2(facing * 20.0, -12.0))
	var hurtbox := Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.set_script(HURTBOX_SCRIPT)
	add_child(hurtbox)
	hurtbox.setup(self, Vector2(36.0, 24.0), Vector2(0.0, -12.0))
	queue_redraw()

func _process(delta: float) -> void:
	delta *= WorldState.get_combat_enemy_time_scale()
	if WorldState.input_locked:
		return
	animation_time += delta
	attack_timer = maxf(0.0, attack_timer - delta)
	stun_time = maxf(0.0, stun_time - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	queue_redraw()

func _physics_process(delta: float) -> void:
	delta *= WorldState.get_combat_enemy_time_scale()
	if WorldState.input_locked:
		return
	if not is_on_floor():
		velocity.y += 1400.0 * delta
	if stun_time > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		move_and_slide()
		return
	var hero := get_node_or_null("../Hero") as Node2D
	if hero != null and absf(hero.global_position.x - global_position.x) < 260.0:
		var dx := hero.global_position.x - global_position.x
		if not is_zero_approx(dx):
			facing = sign(dx)
		if absf(dx) > ATTACK_RANGE:
			velocity.x = facing * MOVE_SPEED
		else:
			velocity.x = 0.0
			if attack_timer <= 0.0:
				attack_hitbox.position = Vector2(facing * 20.0, -12.0)
				attack_hitbox.activate(6, 0.12)
				attack_timer = ATTACK_COOLDOWN
	else:
		velocity.x = move_toward(velocity.x, 0.0, 450.0 * delta)
	move_and_slide()

func receive_damage(amount: int, source: Node = null) -> void:
	health = maxi(0, health - amount)
	hit_flash = 0.12
	stun_time = 0.14
	if source is Node2D:
		velocity.x = sign(global_position.x - source.global_position.x) * 110.0
	var spark := Node2D.new()
	spark.set_script(HIT_SPARK_SCRIPT)
	spark.global_position = global_position + Vector2(0.0, -14.0)
	get_parent().add_child(spark)
	if health <= 0:
		var burst := Node2D.new()
		burst.set_script(DEATH_BURST_SCRIPT)
		burst.global_position = global_position + Vector2(0.0, -12.0)
		get_parent().add_child(burst)
		burst.call("setup", 8.0)
		defeated.emit()
		queue_free()

func take_damage(amount: int) -> void:
	receive_damage(amount)

func _draw() -> void:
	var body_color := Color("#d1aaa0") if hit_flash > 0.0 else Color("#4a3c3d")
	var bob := sin(animation_time * 11.0) * 1.4 if absf(velocity.x) > 4.0 else 0.0
	draw_ellipse(Vector2(0.0, -12.0 + bob), Vector2(18.0, 10.0), body_color)
	draw_circle(Vector2(facing * 14.0, -20.0 + bob), 7.0, body_color)
	draw_circle(Vector2(facing * 17.0, -22.0 + bob), 1.8, Color("#d97870"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(facing * 10.0, -26.0 + bob),
		Vector2(facing * 12.0, -34.0 + bob),
		Vector2(facing * 16.0, -26.0 + bob)
	]), Color("#786064"))
	draw_line(Vector2(-8.0, -6.0 + bob), Vector2(-13.0, 1.0), body_color, 3.0)
	draw_line(Vector2(8.0, -6.0 + bob), Vector2(12.0, 1.0), body_color, 3.0)
	draw_line(Vector2(-12.0, -16.0 + bob), Vector2(-20.0, -10.0 + bob), body_color, 2.0)

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(20):
		var angle := TAU * float(index) / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
