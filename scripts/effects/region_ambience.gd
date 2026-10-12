extends Node2D
## Lightweight ambient motion for regional graybox scenes.
## 灰盒区域使用的轻量环境动态层。

@export var map_width: float = 2600.0
@export var floor_y: float = 540.0
@export var region_id: String = "A2"
@export var atmosphere_color: Color = Color("#93849b")

var motes: Array[Dictionary] = []
var phase := 0.0

func _ready() -> void:
	# Keep the particle field deterministic so screenshots and bug reports are reproducible.
	# 粒子布局保持确定性，方便复现截图与视觉问题。
	var seed_offset := int(region_id.hash() % 127)
	for index in range(18):
		var x := float((index * 173 + seed_offset) % int(map_width))
		var y := 190.0 + float((index * 71 + seed_offset) % 300)
		motes.append({
			"position": Vector2(x, y),
			"radius": 1.0 + float(index % 3) * 0.45,
			"speed": 7.0 + float((index * 5) % 12),
			"drift": -5.0 + float((index * 13) % 11)
		})
	queue_redraw()

func _process(delta: float) -> void:
	phase = fmod(phase + delta, TAU)
	for index in range(motes.size()):
		var mote: Dictionary = motes[index]
		var particle_position: Vector2 = mote["position"]
		var speed: float = mote["speed"]
		var drift: float = mote["drift"]
		if region_id == "H07":
			# Rain in Mirror Street climbs toward the sky.
			# 镜街中的雨向天空回落。
			particle_position.y -= speed * delta
			particle_position.x += drift * delta
		elif region_id == "A5":
			# Ash drifts down through the battlefield.
			# 灰烬在旧战场缓慢下坠。
			particle_position.y += speed * delta * 0.45
			particle_position.x += drift * delta
		else:
			# Most regions carry slow dust or spores rather than obvious weather.
			# 大多数区域只有缓慢尘埃或孢子，不制造过于明显的天气效果。
			particle_position.y += sin(phase + float(index)) * delta * speed * 0.22
			particle_position.x += drift * delta * 0.35

		if particle_position.x < -8.0:
			particle_position.x = map_width + 8.0
		elif particle_position.x > map_width + 8.0:
			particle_position.x = -8.0
		if particle_position.y < 175.0:
			particle_position.y = floor_y - 44.0
		elif particle_position.y > floor_y - 32.0:
			particle_position.y = 180.0
		mote["position"] = particle_position
		motes[index] = mote
	queue_redraw()

func _draw() -> void:
	for index in range(motes.size()):
		var mote: Dictionary = motes[index]
		var particle_position: Vector2 = mote["position"]
		var radius: float = mote["radius"]
		var pulse := 0.75 + 0.25 * sin(phase * 1.4 + float(index))
		draw_circle(particle_position, radius * 3.0, Color(atmosphere_color.r, atmosphere_color.g, atmosphere_color.b, 0.025 * pulse))
		draw_circle(particle_position, radius, Color(atmosphere_color.r, atmosphere_color.g, atmosphere_color.b, 0.18 * pulse))
		if region_id == "H07":
			draw_line(particle_position, particle_position + Vector2(0.0, -7.0 - radius * 3.0), Color(atmosphere_color.r, atmosphere_color.g, atmosphere_color.b, 0.075), 1.0)
