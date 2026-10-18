@tool
extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const WARDEN_SCRIPT = preload("res://scripts/enemies/experiment_warden.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const REST_POINT_SCRIPT = preload("res://scripts/world/rest_point.gd")
const INTERACTION_DOOR_SCRIPT = preload("res://scripts/world/interaction_door.gd")
const SURGERY_BACKDROP = preload("res://assets/art/backdrops/surgery_ward_backdrop.svg")
const SURGERY_FLOOR_STRIP = preload("res://assets/art/backdrops/surgery_floor_strip.svg")
const SURGERY_FOREGROUND_PROPS = preload("res://assets/art/backdrops/surgery_foreground_props.svg")

const FLOOR_Y := 540.0
const LEVEL_WIDTH := 2200.0
# Shared visual/physical layout for the optional maintenance route.
# Keep rise steps modest and gaps wide enough for Hero's capsule to clear platform sides.
const SURGICAL_CATWALK_RECTS := [
	Rect2(430.0, 465.0, 120.0, 16.0),
	Rect2(590.0, 435.0, 120.0, 16.0),
	Rect2(750.0, 405.0, 120.0, 16.0),
	Rect2(910.0, 420.0, 120.0, 16.0),
	Rect2(1070.0, 440.0, 120.0, 16.0),
	Rect2(1230.0, 415.0, 120.0, 16.0)
]

var hero: CharacterBody2D
var camera: Camera2D
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
	# Editor preview must never spawn runtime actors or mutate save/world state.
	if Engine.is_editor_hint():
		queue_redraw()
		return
	if WorldState.prologue_complete:
		get_tree().change_scene_to_file("res://scenes/village_hub.tscn")
		return

	WorldState.current_location = "church_escape"
	WorldState.record_natural_test_region("A0", "church_escape")
	WorldState.set_checkpoint(Vector2(420.0, FLOOR_Y))

	_create_floor()
	_create_surgical_catwalks()
	_create_boundaries()
	_create_surgery_table()
	_spawn_hero()
	# Keep the opening focused on exploration; the exit ambush creates enemies and shutters later.
	_spawn_clue()
	_spawn_item_pickups()
	_spawn_rest()
	_spawn_exit()
	_spawn_ui()
	queue_redraw()

func _process(_delta: float) -> void:
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

func _create_surgery_table() -> void:
	var table := StaticBody2D.new()
	table.name = "BrokenSurgeryTable"
	table.position = Vector2(280.0, 500.0)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(180.0, 12.0)
	shape.shape = rectangle
	table.add_child(shape)
	add_child(table)

func _spawn_hero() -> void:
	hero = CharacterBody2D.new()
	hero.set_script(HERO_SCRIPT)
	hero.position = Vector2(420.0, FLOOR_Y)
	hero.name = "Hero"
	_add_character_collision(hero, 18.0, 48.0)
	add_child(hero)
	# Hero handles checkpoint respawn internally; this interior scene has no defeated callback.
	hero.attack_started.connect(func(_combo): pass)
	hero.defeated.connect(_on_hero_defeated)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = LEVEL_WIDTH
	camera.limit_bottom = 720
	hero.add_child(camera)

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

func _spawn_warden(position: Vector2, enemy_name: String) -> void:
	var warden := CharacterBody2D.new()
	warden.set_script(WARDEN_SCRIPT)
	warden.position = position
	warden.name = enemy_name
	_add_character_collision(warden, 22.0, 50.0)
	add_child(warden)
	warden.defeated.connect(_on_warden_defeated)
	wardens.append(warden)

func _spawn_progress_barriers() -> void:
	# Close both ends of the arena only after the exit ambush starts.
	# 仅在出口伏击触发后关闭战斗场地两端，避免开场就加载敌人。
	_spawn_single_progress_barrier(1320.0)

func _spawn_single_progress_barrier(gate_x: float) -> void:
	var gate := StaticBody2D.new()
	gate.name = "SurgeryProgressBarrier"
	gate.position = Vector2(gate_x, 420.0)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(24.0, 240.0)
	shape.shape = rectangle
	gate.add_child(shape)
	add_child(gate)
	progress_barriers.append(gate)

func _open_progress_barrier(index: int) -> void:
	if index < 0 or index >= progress_barriers.size():
		return
	var gate := progress_barriers[index]
	if is_instance_valid(gate):
		gate.queue_free()
	queue_redraw()

func _spawn_clue() -> void:
	var clue := Node2D.new()
	clue.set_script(preload("res://scripts/world/world_clue.gd"))
	clue.position = Vector2(620, 520)
	clue.clue_id = "escape_surgical_mark"
	clue.humanity_delta = -1
	clue.display_name = "手术托盘"
	clue.description = "金属托盘上覆着一层血。托盘底部凝结着干涸的黑色残留物，边缘留有几道浅浅的刮痕。器械编号已被刮去，只剩模糊的痕迹。"
	add_child(clue)
	var examined_callback := _on_clue_examined.bind(clue)
	clue.examined.connect(examined_callback)

func _spawn_item_pickups() -> void:
	var pickup_script = preload("res://scripts/world/world_item_pickup.gd")
	var bandage := Node2D.new()
	bandage.set_script(pickup_script)
	bandage.position = Vector2(460, 492)
	bandage.pickup_id = "a0_bandage_pickup"
	bandage.item_id = "church_bandage"
	bandage.amount = 1
	add_child(bandage)

	var record := Node2D.new()
	record.set_script(pickup_script)
	record.position = Vector2(740, 450)
	record.pickup_id = "a0_surgery_record_pickup"
	record.item_id = "surgery_record_fragment"
	record.amount = 1
	add_child(record)

func _on_clue_examined(clue: Node) -> void:
	WorldState.mark_ancient_residue_awakened()
	hud.call("show_item_description", clue.display_name, clue.description)

func _spawn_rest() -> void:
	var rest := Node2D.new()
	rest.set_script(REST_POINT_SCRIPT)
	rest.position = Vector2(420.0, FLOOR_Y)
	rest.rest_id = "escape_stool"
	rest.display_name = "破损的凳子"
	add_child(rest)

func _spawn_exit() -> void:
	exit_area = Area2D.new()
	exit_area.set_script(INTERACTION_DOOR_SCRIPT)
	exit_area.position = Vector2(2040, FLOOR_Y)
	exit_area.name = "VillageRoadExit"
	exit_area.prompt_text = "E  逃离"
	exit_area.enabled = false

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(110, 140)
	shape.shape = rectangle
	shape.position = Vector2(0, -70)
	exit_area.add_child(shape)
	add_child(exit_area)
	exit_area.interacted.connect(_on_exit_interacted)
	queue_redraw()

func _on_hero_defeated() -> void:
	# Death respawns the Hero at the checkpoint behind the arena; reopen the entry shutter
	# so the player can return to the unfinished encounter instead of being soft-locked.
	if ambush_started and wardens_defeated < wardens.size():
		_open_progress_barrier(0)

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

func _spawn_ui() -> void:
	hud = CanvasLayer.new()
	hud.set_script(HUD_SCRIPT)
	add_child(hud)
	hud.bind_hero(hero)
	hud.set_story_mode("A0｜教会手术所", "查看手术托盘和周边物品，寻找离开的路。")

func _create_floor() -> void:
	var floor := StaticBody2D.new()
	floor.name = "SurgeryFloor"
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(LEVEL_WIDTH, 40.0)
	shape.shape = rectangle
	shape.position = Vector2(LEVEL_WIDTH * 0.5, FLOOR_Y + 20.0)
	floor.add_child(shape)
	add_child(floor)

func _create_surgical_catwalks() -> void:
	# Optional maintenance route; gentler rises and wider gaps reduce capsule snagging.
	# 可选维护高路：降低连续台阶高度，并扩大水平间隔，避免主角提前撞上平台侧面。
	for platform_rect in SURGICAL_CATWALK_RECTS:
		var body := StaticBody2D.new()
		body.name = "SurgicalCatwalkPlatform"
		body.position = platform_rect.position
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = platform_rect.size
		shape.shape = rectangle
		shape.position = platform_rect.size * 0.5
		body.add_child(shape)
		add_child(body)


func _create_boundaries() -> void:
	var left := StaticBody2D.new()
	var ls := CollisionShape2D.new()
	var lr := RectangleShape2D.new()
	lr.size = Vector2(40, 720)
	ls.shape = lr
	ls.position = Vector2(-20, 360)
	left.add_child(ls)
	add_child(left)

	var right := StaticBody2D.new()
	var rs := CollisionShape2D.new()
	var rr := RectangleShape2D.new()
	rr.size = Vector2(40, 720)
	rs.shape = rr
	rs.position = Vector2(LEVEL_WIDTH + 20.0, 360)
	right.add_child(rs)
	add_child(right)

func _add_character_collision(character: CharacterBody2D, radius: float, height: float) -> void:
	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = radius
	capsule.height = height
	collision.shape = capsule
	collision.position = Vector2(0, -height * 0.5)
	character.add_child(collision)

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

func _draw_security_shutter(gate_x: float) -> void:
	draw_rect(Rect2(gate_x - 13.0, 300.0, 26.0, 240.0), Color("#17141b"))
	for bar_y in range(312, 536, 28):
		draw_line(Vector2(gate_x - 10.0, float(bar_y)), Vector2(gate_x + 10.0, float(bar_y)), Color("#65505c"), 3.0)
	draw_rect(Rect2(gate_x - 19.0, 292.0, 38.0, 8.0), Color("#8d5968"))

func _draw() -> void:
	draw_texture_rect(SURGERY_BACKDROP, Rect2(0, 0, LEVEL_WIDTH, 720), false)
	draw_texture_rect(SURGERY_FLOOR_STRIP, Rect2(0, FLOOR_Y, LEVEL_WIDTH, 180), false)
	# Illustrated prop pass replaces the flat geometric furniture while leaving gameplay bodies untouched.
	draw_texture_rect(SURGERY_FOREGROUND_PROPS, Rect2(0, 0, LEVEL_WIDTH, 720), false)

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
	draw_string(ThemeDB.fallback_font, Vector2(210, 215), NereisLocalization.translate_text("教会手术所"), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#7d6c73"))

	# Draw broken rails on each actual platform, not diagonal lines across non-colliding gaps.
	# 护栏只画在真实平台段上，不再用斜线把无碰撞的间隙伪装成连续斜坡。
	for platform_rect: Rect2 in SURGICAL_CATWALK_RECTS:
		var left: float = platform_rect.position.x
		var right: float = left + platform_rect.size.x
		var rail_y: float = platform_rect.position.y - 10.0
		draw_line(Vector2(left + 8.0, rail_y), Vector2(left + 42.0, rail_y), Color("#66515f"), 3.0)
		draw_line(Vector2(left + 76.0, rail_y), Vector2(right - 8.0, rail_y), Color("#66515f"), 3.0)
		for support_x in [left + 12.0, left + 42.0, left + 76.0, right - 10.0]:
			draw_line(Vector2(support_x, rail_y), Vector2(support_x, platform_rect.position.y - 1.0), Color("#51404d"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(620, 295), "仅供维护人员通行", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#8b737e"))



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
	draw_string(ThemeDB.fallback_font, Vector2(1810, 250), NereisLocalization.translate_text("逃脱之路"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#6d5c64"))

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
		draw_string(ThemeDB.fallback_font, Vector2(1995, 275), NereisLocalization.translate_text("开启"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d6c7b2"))

	if Engine.is_editor_hint():
		_draw_editor_layout_overlay()


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

	# Catwalk collision boxes mirror SURGICAL_CATWALK_RECTS.
	for platform_rect: Rect2 in SURGICAL_CATWALK_RECTS:
		draw_rect(platform_rect, Color(collision_color, 0.14), true)
		draw_rect(platform_rect, collision_color, false, 2.0)

	# Hero/checkpoint and rest point share x=420; their overlap is intentional but worth seeing.
	draw_circle(Vector2(420.0, FLOOR_Y), 6.0, anchor_color)
	draw_line(Vector2(420.0, FLOOR_Y - 48.0), Vector2(420.0, FLOOR_Y), anchor_color, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(430.0, FLOOR_Y - 34.0), "Hero / 初始检查点 (420, 540)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, anchor_color)
	draw_circle(Vector2(420.0, FLOOR_Y), 90.0, Color(focus_color, 0.42), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(430.0, FLOOR_Y + 18.0), "休整点：横向90 / 高差32 / 必须落地", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, focus_color)

	# Clue and pickups use distance-based interaction, not physical Area2D shapes.
	draw_circle(Vector2(620.0, 520.0), 5.0, focus_color)
	draw_circle(Vector2(620.0, 520.0), 120.0, Color(focus_color, 0.40), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(625.0, 508.0), "调查点：手术托盘 (620, 520) / 半径120", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, focus_color)

	draw_circle(Vector2(460.0, 492.0), 5.0, Color("#a7f3d0"))
	draw_circle(Vector2(460.0, 492.0), 100.0, Color("#a7f3d0", 0.42), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(465.0, 480.0), "绷带 (460, 492) / 半径100", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#a7f3d0"))

	draw_circle(Vector2(740.0, 450.0), 5.0, Color("#a7f3d0"))
	draw_circle(Vector2(740.0, 450.0), 100.0, Color("#a7f3d0", 0.42), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(745.0, 438.0), "手术记录 (740, 450) / 半径100", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#a7f3d0"))

	# Exit trigger area: center (2040, 470), 110 x 140.
	draw_rect(Rect2(1985.0, 400.0, 110.0, 140.0), Color("#ff9f43", 0.12), true)
	draw_rect(Rect2(1985.0, 400.0, 110.0, 140.0), Color("#ff9f43", 0.95), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(1980.0, 390.0), "出口交互区 110×140", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ff9f43"))

