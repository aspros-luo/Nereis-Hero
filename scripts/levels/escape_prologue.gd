@tool
extends Node2D

const WARDEN_SCENE: PackedScene = preload("res://scenes/enemies/experiment_warden.tscn")
const PROGRESS_BARRIER_SCENE: PackedScene = preload("res://scenes/rooms/prologue_progress_barrier.tscn")
const SURGERY_BACKDROP = preload("res://assets/art/backdrops/surgery_ward_backdrop.svg")
const SURGERY_FLOOR_STRIP = preload("res://assets/art/backdrops/surgery_floor_strip.svg")
const SURGERY_FOREGROUND_PROPS = preload("res://assets/art/backdrops/surgery_foreground_props.svg")

const FLOOR_Y := 540.0
const LEVEL_WIDTH := 2200.0
var hero: CharacterBody2D
var hud: CanvasLayer
var wardens: Array[CharacterBody2D] = []
var exit_area: Area2D
var exit_open := false
var wardens_defeated := 0
var first_combat_prompt_shown := false
var ambush_started := false
var ambush_phase := 0 # 0=not started, 1=two-entry wave, 2=falling ambusher, 3=cleared
var right_gate_closed := false
var progress_barriers: Array[StaticBody2D] = []


func _ready() -> void:
	# Editor preview must never mutate save/world state.
	if Engine.is_editor_hint():
		queue_redraw()
		return
	if WorldState.prologue_complete:
		get_tree().change_scene_to_file("res://scenes/village_hub.tscn")
		return

	hero = $Hero
	hud = $HUD
	exit_area = $VillageRoadExit
	WorldState.current_location = "church_escape"
	WorldState.record_natural_test_region("A0", "church_escape")
	WorldState.set_checkpoint(Vector2(420.0, FLOOR_Y))

	hero.defeated.connect(_on_hero_defeated)
	exit_area.interacted.connect(_on_exit_interacted)
	var clue := $SurgicalMark
	clue.examined.connect(_on_clue_examined.bind(clue))
	hud.bind_hero(hero)
	hud.set_story_mode("A0｜教会手术所", "查看手术托盘和周边物品，寻找离开的路。")
	queue_redraw()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not ambush_started and is_instance_valid(hero) and hero.global_position.x >= 1710.0:
		_start_exit_ambush()
	if ambush_phase == 1 and not right_gate_closed:
		var doorway_warden := get_node_or_null("Warden_Right") as CharacterBody2D
		if is_instance_valid(doorway_warden) and doorway_warden.global_position.x <= 1960.0:
			_spawn_single_progress_barrier(2000.0)
			right_gate_closed = true
	if first_combat_prompt_shown or wardens_defeated > 0 or not is_instance_valid(hero) or wardens.is_empty():
		return
	var first_warden := wardens[0]
	if is_instance_valid(first_warden) and hero.global_position.distance_to(first_warden.global_position) <= 260.0:
		first_combat_prompt_shown = true
		if is_instance_valid(hud):
			hud.set_story_mode("A0｜教会手术所", "伏击开始！留意两侧来敌与上方坠落的守卫，利用攻击前摇进行闪避。")


func _start_exit_ambush() -> void:
	if ambush_started:
		return
	ambush_started = true
	_spawn_progress_barriers()
	# Wave 1: the left warden walks in from the left; the second enters from the doorway.
	# 第一波只出现两名地面守卫，先给玩家时间读懂战斗节奏。
	ambush_phase = 1
	_spawn_warden(Vector2(1425.0, FLOOR_Y), "Warden_Left")
	_spawn_warden(Vector2(2075.0, FLOOR_Y), "Warden_Right")
	if is_instance_valid(hud):
		hud.set_story_mode("A0｜教会手术所", "左侧传来沉重的脚步声，出口处的守卫也逼了进来！先解决他们。")
	print("[NEREIS][PROLOGUE] Exit ambush wave 1 started")


func _spawn_warden(spawn_position: Vector2, enemy_name: String) -> void:
	var warden := WARDEN_SCENE.instantiate() as CharacterBody2D
	if warden == null:
		push_error("[NEREIS][PROLOGUE] Failed to instantiate warden scene")
		return
	warden.position = spawn_position
	warden.name = enemy_name
	add_child(warden)
	warden.defeated.connect(_on_warden_defeated)
	wardens.append(warden)

func _spawn_progress_barriers() -> void:
	# Close both ends of the arena only after the exit ambush starts.
	# 仅在出口伏击触发后关闭战斗场地两端，避免开场就加载敌人。
	_spawn_single_progress_barrier(1320.0)


func _spawn_single_progress_barrier(gate_x: float) -> void:
	var gate := PROGRESS_BARRIER_SCENE.instantiate() as StaticBody2D
	if gate == null:
		push_error("[NEREIS][PROLOGUE] Failed to instantiate progress barrier scene")
		return
	gate.name = "SurgeryProgressBarrier"
	gate.position = Vector2(gate_x, 420.0)
	add_child(gate)
	progress_barriers.append(gate)

func _open_progress_barrier(index: int) -> void:
	if index < 0 or index >= progress_barriers.size():
		return
	var gate := progress_barriers[index]
	if is_instance_valid(gate):
		gate.queue_free()
	queue_redraw()


func _on_clue_examined(clue: Node) -> void:
	WorldState.mark_ancient_residue_awakened()
	hud.call("show_item_description", clue.display_name, clue.description)


func _on_hero_defeated() -> void:
	# A0 is a retryable encounter: reset the entire ambush immediately when death starts,
	# while the Hero's fade-out hides the cleanup. The checkpoint is before the trigger,
	# so enemies will only spawn again when the player deliberately re-enters the arena.
	for warden in wardens:
		if is_instance_valid(warden):
			warden.queue_free()
	wardens.clear()
	for gate in progress_barriers:
		if is_instance_valid(gate):
			gate.queue_free()
	progress_barriers.clear()
	wardens_defeated = 0
	ambush_started = false
	ambush_phase = 0
	right_gate_closed = false
	first_combat_prompt_shown = false
	exit_open = false
	if is_instance_valid(exit_area):
		exit_area.enabled = false
	if is_instance_valid(hud):
		hud.set_story_mode("A0｜教会手术所", "你在检查点恢复了意识。重新接近出口时，守卫会再次出现。")
	queue_redraw()


func _on_warden_defeated() -> void:
	wardens_defeated += 1
	if ambush_phase == 1 and wardens_defeated >= 2:
		# Wave 2 only begins after both ground wardens are defeated.
		# 第二波必须等两名地面守卫全部倒下后才触发。
		ambush_phase = 2
		_spawn_warden(Vector2(1480.0, 95.0), "Warden_Drop")
		if is_instance_valid(hud):
			hud.set_story_mode("A0｜教会手术所", "上方传来金属断裂声……第三名守卫从左侧高处坠落！")
		return
	if ambush_phase == 2 and wardens_defeated >= 3:
		ambush_phase = 3
		for index in range(progress_barriers.size()):
			_open_progress_barrier(index)
		_open_exit()
		return
	var total_in_phase := 2 if ambush_phase == 1 else 3
	var remaining := maxi(0, total_in_phase - wardens_defeated)
	if remaining > 0 and is_instance_valid(hud):
		hud.set_story_mode("A0｜教会手术所", "守卫倒下了。还剩 %d 名敌人。" % remaining)


func _open_exit() -> void:
	if exit_open:
		return
	exit_open = true
	exit_area.enabled = true
	if is_instance_valid(hud):
		hud.set_story_mode("A0｜教会手术所", "出口已打开。前往右侧出口按 E，离开手术所。")
	print("[NEREIS][PROLOGUE] Escape route opened")
	queue_redraw()


func _on_exit_interacted() -> void:
	if not exit_open or WorldState.input_locked:
		return
	WorldState.input_locked = true
	WorldState.current_location = "church_escape_exterior"
	WorldState.pending_region_spawn_side = "west"
	print("[NEREIS][PROLOGUE] Leaving surgery interior for the exterior mountain path")
	SceneTransition.fade_to_scene("res://scenes/prologue_exterior.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if WorldState.debug_map_test_mode and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
		_mark_input_handled()
		get_tree().change_scene_to_file("res://scenes/world_map_test_menu.tscn")
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		_mark_input_handled()
		WorldState.delete_save()
		get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")


func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _get_traversal_route_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var route := get_node_or_null("PrologueTraversalRoute") as Node2D
	if route == null:
		return rects
	for child in route.get_children():
		var platform := child as StaticBody2D
		if platform == null:
			continue
		var collision := platform.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or not collision.shape is RectangleShape2D:
			continue
		var rectangle := collision.shape as RectangleShape2D
		var top_left := route.position + platform.position + collision.position - rectangle.size * 0.5
		rects.append(Rect2(top_left, rectangle.size))
	return rects


func _draw_security_shutter(gate_x: float) -> void:
	# Make the temporary collision boundary legible before the player reaches it.
	# 临时碰撞边界必须在玩家撞上之前就能被清楚识别，不能只靠物理体表达。
	draw_rect(Rect2(gate_x - 34.0, 292.0, 68.0, 252.0), Color("#a54c62", 0.10))
	draw_rect(Rect2(gate_x - 16.0, 300.0, 32.0, 240.0), Color("#17141b"))
	draw_rect(Rect2(gate_x - 21.0, 296.0, 42.0, 8.0), Color("#b87583"))
	draw_rect(Rect2(gate_x - 21.0, 536.0, 42.0, 7.0), Color("#8d5968"))
	# Thick side rails visually align with the StaticBody2D collision footprint.
	draw_line(Vector2(gate_x - 13.0, 302.0), Vector2(gate_x - 13.0, 536.0), Color("#a87580"), 3.0)
	draw_line(Vector2(gate_x + 13.0, 302.0), Vector2(gate_x + 13.0, 536.0), Color("#a87580"), 3.0)
	for bar_y in range(312, 536, 24):
		draw_line(Vector2(gate_x - 10.0, float(bar_y)), Vector2(gate_x + 10.0, float(bar_y)), Color("#8c6873"), 3.0)
	# Warning lamps communicate that the shutter is an active combat lock, not an invisible wall.
	draw_circle(Vector2(gate_x, 284.0), 8.0, Color("#f0b35c", 0.22))
	draw_circle(Vector2(gate_x, 284.0), 4.0, Color("#f0b35c"))
	draw_line(Vector2(gate_x - 28.0, 284.0), Vector2(gate_x - 17.0, 284.0), Color("#c58b62"), 2.0)
	draw_line(Vector2(gate_x + 17.0, 284.0), Vector2(gate_x + 28.0, 284.0), Color("#c58b62"), 2.0)


func _draw() -> void:
	draw_texture_rect(SURGERY_BACKDROP, Rect2(0, 0, LEVEL_WIDTH, 720), false)
	draw_texture_rect(SURGERY_FLOOR_STRIP, Rect2(0, FLOOR_Y, LEVEL_WIDTH, 180), false)
	# Illustrated prop pass replaces the flat geometric furniture while leaving gameplay bodies untouched.
	draw_texture_rect(SURGERY_FOREGROUND_PROPS, Rect2(0, 0, LEVEL_WIDTH, 720), false)
	# Collision-backed tutorial ledges are also drawn so the optional route reads clearly.
	# 将具有真实碰撞的教学平台同步绘制出来，让可选路线清晰可读。
	for ledge in _get_traversal_route_rects():
		draw_rect(ledge, Color("#40323d"))
		draw_rect(Rect2(ledge.position.x, ledge.position.y, ledge.size.x, 3.0), Color("#947984"))
		# Broken edge marks keep the route readable without drawing a false continuous ramp.
		for seam_x in [ledge.position.x + 28.0, ledge.position.x + 76.0, ledge.position.x + 104.0]:
			draw_line(Vector2(seam_x, ledge.position.y + 4.0), Vector2(seam_x - 5.0, ledge.position.y + 12.0), Color("#241f29"), 1.5)

	# Cold surgical shafts and suspended cables establish depth before the room's props are drawn.
	# 冷色手术灯柱与悬垂线缆先建立空间纵深，再绘制房间内的物件。
	for lamp_x in [700.0, 1120.0, 1500.0]:
		draw_rect(Rect2(lamp_x - 28.0, 86.0, 56.0, 420.0), Color("#b66e82", 0.025))
		draw_rect(Rect2(lamp_x - 12.0, 105.0, 24.0, 300.0), Color("#d49aa8", 0.018))
		draw_line(Vector2(lamp_x - 58.0, 0.0), Vector2(lamp_x - 58.0, 306.0), Color("#51404d", 0.70), 2.0)
		draw_line(Vector2(lamp_x + 58.0, 0.0), Vector2(lamp_x + 58.0, 306.0), Color("#51404d", 0.70), 2.0)
		draw_line(Vector2(lamp_x - 58.0, 306.0), Vector2(lamp_x + 58.0, 306.0), Color("#6e4b5a", 0.65), 2.0)
		draw_circle(Vector2(lamp_x, 320.0), 24.0, Color("#b66e82", 0.035))
		draw_circle(Vector2(lamp_x, 320.0), 9.0, Color("#b66e82", 0.12))

	# Sparse surgical floor seams and a few broken tile marks replace the uninterrupted flat floor.
	# 稀疏的手术室地砖缝与破损痕迹打破连续纯色地面。
	for tile_x in range(90, int(LEVEL_WIDTH), 210):
		draw_line(Vector2(tile_x, FLOOR_Y + 12.0), Vector2(tile_x - 7.0, FLOOR_Y + 38.0), Color("#0b090f", 0.48), 1.0)
		draw_line(Vector2(tile_x + 34.0, FLOOR_Y + 68.0), Vector2(tile_x + 66.0, FLOOR_Y + 64.0), Color("#57434d", 0.22), 1.0)

	# Keep the illustrated glass tanks and wall structure from the SVG visible.
	# Earlier opaque graybox blocks hid most of the backdrop in the opening camera view.
	# 保留 SVG 中的玻璃实验舱和墙体；旧版不透明灰盒曾遮住开场镜头的大部分背景。
	# Operating table, snapped restraints, instrument trolley and wall shelf are drawn by the SVG prop layer.
	draw_rect(Rect2(180, 240, 300, 40), Color("#352d38"))
	draw_string(ThemeDB.fallback_font, Vector2(210, 215), _editor_safe_text("教会手术所"), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#7d6c73"))


	# Background equipment is already illustrated in SURGERY_BACKDROP; do not cover it with
	# opaque placeholder cabinets. Foreground props below remain separate from collision bodies.

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(1780, 520),
			Vector2(1900, 270),
			Vector2(2020, 520)
		]),
		Color("#241e27")
	)
	draw_string(ThemeDB.fallback_font, Vector2(1810, 250), _editor_safe_text("逃脱之路"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#6d5c64"))

	# The arena shutters appear only after the exit ambush begins.
	if ambush_started and wardens_defeated < wardens.size():
		if progress_barriers.size() > 0 and is_instance_valid(progress_barriers[0]):
			_draw_security_shutter(1320.0)
		if right_gate_closed:
			_draw_security_shutter(2000.0)

	if not exit_open:
		draw_rect(Rect2(2000, 300, 90, 220), Color("#18151b"))
		draw_line(Vector2(2010, 320), Vector2(2010, 500), Color("#5d4c55"), 5.0)
		draw_line(Vector2(2080, 320), Vector2(2080, 500), Color("#5d4c55"), 5.0)
	else:
		draw_rect(Rect2(2000, 300, 90, 220), Color("#33232a"))
		draw_string(ThemeDB.fallback_font, Vector2(1995, 275), _editor_safe_text("开启"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d6c7b2"))

	if Engine.is_editor_hint():
		_draw_editor_layout_overlay()


func _editor_safe_text(fallback_text: String) -> String:
	if Engine.is_editor_hint():
		return fallback_text
	return NereisLocalization.translate_text(fallback_text)


## Editor-only collision and interaction guides for checking the fixed A0 layout.
## These outlines are guides, not extra physics bodies.

func _draw_editor_layout_overlay() -> void:
	var collision_color := Color("#4bd4ff", 0.88)
	var focus_color := Color("#ffd166", 0.72)
	var anchor_color := Color("#ff6b6b", 0.95)

	# Floor and world boundaries.
	draw_rect(Rect2(0.0, FLOOR_Y, LEVEL_WIDTH, 40.0), Color(collision_color, 0.10), false, 2.0)
	draw_rect(Rect2(-40.0, 0.0, 40.0, 720.0), collision_color, false, 2.0)
	draw_rect(Rect2(LEVEL_WIDTH, 0.0, 40.0, 720.0), collision_color, false, 2.0)

	# Surgery table collision: center (280, 500), 180 x 12.
	draw_rect(Rect2(190.0, 494.0, 180.0, 12.0), collision_color, false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(190.0, 486.0), "手术台碰撞 180×12", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, collision_color)


	# Hero spawn/checkpoint and rest point are intentionally separated for a clean opening silhouette.
	draw_circle(Vector2(420.0, FLOOR_Y), 6.0, anchor_color)
	draw_line(Vector2(420.0, FLOOR_Y - 48.0), Vector2(420.0, FLOOR_Y), anchor_color, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(430.0, FLOOR_Y - 34.0), "Hero / 初始检查点 (420, 540)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, anchor_color)
	draw_circle(Vector2(540.0, FLOOR_Y), 6.0, focus_color)
	# Rest eligibility uses independent horizontal/vertical thresholds, not a radial distance.
	draw_rect(Rect2(450.0, FLOOR_Y - 32.0, 180.0, 64.0), Color(focus_color, 0.42), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(545.0, FLOOR_Y + 18.0), "休整点 (540, 540)：横向90 / 高差32 / 必须落地", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, focus_color)

	# Clue and pickups use distance-based interaction, not physical Area2D shapes.
	draw_circle(Vector2(620.0, 520.0), 5.0, focus_color)
	draw_circle(Vector2(620.0, 520.0), 120.0, Color(focus_color, 0.40), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(625.0, 508.0), "调查点：手术托盘 (620, 520) / 半径120", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, focus_color)

	draw_circle(Vector2(320.0, 482.0), 5.0, Color("#a7f3d0"))
	draw_circle(Vector2(320.0, 482.0), 100.0, Color("#a7f3d0", 0.42), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(325.0, 470.0), "绷带 (320, 482) / 半径100；置于手术台上", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#a7f3d0"))

	draw_circle(Vector2(880.0, 393.0), 5.0, Color("#a7f3d0"))
	draw_circle(Vector2(810.0, 393.0), 100.0, Color("#a7f3d0", 0.42), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(815.0, 381.0), "手术记录 (880, 393) / 半径100；置于维护平台", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#a7f3d0"))

	# Exit trigger area: center (2040, 470), 110 x 140.
	draw_rect(Rect2(1985.0, 400.0, 110.0, 140.0), Color("#ff9f43", 0.12), true)
	draw_rect(Rect2(1985.0, 400.0, 110.0, 140.0), Color("#ff9f43", 0.95), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(1980.0, 390.0), "出口交互区 110×140", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ff9f43"))

