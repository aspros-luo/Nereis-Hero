extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const WARDEN_SCRIPT = preload("res://scripts/enemies/experiment_warden.gd")
const PROLOGUE_BOSS_SCRIPT = preload("res://scripts/enemies/ashen_knight.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const REST_POINT_SCRIPT = preload("res://scripts/world/rest_point.gd")
const INTERACTION_DOOR_SCRIPT = preload("res://scripts/world/interaction_door.gd")
const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")
const SURGERY_BACKDROP = preload("res://assets/art/backdrops/surgery_ward_backdrop.svg")
const SURGERY_FLOOR_STRIP = preload("res://assets/art/backdrops/surgery_floor_strip.svg")

const FLOOR_Y := 540.0
const LEVEL_WIDTH := 2500.0
const CLIFF_EDGE_X := 2220.0

var hero: CharacterBody2D
var camera: Camera2D
var hud: CanvasLayer
var narrative: CanvasLayer
var wardens: Array[CharacterBody2D] = []
var exit_area: Area2D
var exit_open := false
var wardens_defeated := 0
var cliff_barrier: StaticBody2D
var prologue_boss: CharacterBody2D
var prologue_boss_active := false
var prologue_fall_in_progress := false

func _ready() -> void:
	# P5.1 runtime contract for the prologue-to-village transition.
	set_meta("p5_1_exit_contract", true)
	set_meta("p5_1_target_location", "village")
	set_meta("p5_1_target_region", "A1")
	set_meta("p5_1_target_scene", "res://scenes/village_hub.tscn")
	set_meta("p5_1_spawn_side", "west")
	if WorldState.prologue_complete:
		get_tree().change_scene_to_file("res://scenes/village_hub.tscn")
		return

	WorldState.current_location = "church_escape"
	WorldState.record_natural_test_region("A0", "church_escape")
	WorldState.set_checkpoint(Vector2(300, FLOOR_Y))

	_create_floor()
	_create_surgical_catwalks()
	_create_boundaries()
	_spawn_hero()
	_spawn_wardens()
	_spawn_clue()
	_spawn_rest()
	_spawn_exit()
	_spawn_ui()
	if not WorldState.debug_map_test_mode:
		get_tree().create_timer(0.6).timeout.connect(_show_intro)
	queue_redraw()

func _spawn_hero() -> void:
	hero = CharacterBody2D.new()
	hero.set_script(HERO_SCRIPT)
	hero.position = Vector2(280, FLOOR_Y)
	hero.name = "Hero"
	_add_character_collision(hero, 18.0, 48.0)
	add_child(hero)
	hero.defeated.connect(_on_hero_defeated)
	hero.attack_started.connect(func(_combo): pass)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = LEVEL_WIDTH
	camera.limit_bottom = 720
	hero.add_child(camera)

func _spawn_wardens() -> void:
	_spawn_warden(Vector2(920, FLOOR_Y), "Warden_A")
	_spawn_warden(Vector2(1260, FLOOR_Y), "Warden_B")
	_spawn_warden(Vector2(1590, FLOOR_Y), "Warden_C")

func _spawn_warden(position: Vector2, enemy_name: String) -> void:
	var warden := CharacterBody2D.new()
	warden.set_script(WARDEN_SCRIPT)
	warden.position = position
	warden.name = enemy_name
	_add_character_collision(warden, 22.0, 50.0)
	add_child(warden)
	warden.defeated.connect(_on_warden_defeated)
	wardens.append(warden)

func _spawn_clue() -> void:
	var clue := Node2D.new()
	clue.set_script(preload("res://scripts/world/world_clue.gd"))
	clue.position = Vector2(620, FLOOR_Y)
	clue.clue_id = "escape_surgical_mark"
	clue.humanity_delta = -1
	clue.display_name = "手术托盘"
	clue.description = "金属托盘上覆着一层血，下面凝结着干涸的黑色残留物。\n\n英雄伸手触碰。\n\n他手臂深处的某种东西作出了回应。\n\n这种感觉尚未成为记忆，便突然中断。"
	add_child(clue)
	clue.examined.connect(_on_clue_examined.bind(clue))

func _on_clue_examined(clue: Node) -> void:
	WorldState.mark_ancient_residue_awakened()
	narrative.show_message(clue.display_name, clue.description, 7.0)

func _spawn_rest() -> void:
	var rest := Node2D.new()
	rest.set_script(REST_POINT_SCRIPT)
	rest.position = Vector2(350, FLOOR_Y)
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

func _on_warden_defeated() -> void:
	wardens_defeated += 1
	if wardens_defeated >= wardens.size():
		_open_exit()

func _open_exit() -> void:
	if exit_open:
		return
	exit_open = true
	exit_area.enabled = true
	narrative.show_message(
		"逃脱之路",
		"最后一道锁终于松开。\n\n你不记得自己如何来到这里。\n\n你只记得，留下来就意味着死亡。",
		5.0
	)
	print("[NEREIS][PROLOGUE] Escape route opened")
	queue_redraw()

func _on_exit_interacted() -> void:
	if not exit_open or WorldState.input_locked or prologue_boss_active or prologue_fall_in_progress:
		return
	_start_prologue_boss()

func _start_prologue_boss() -> void:
	prologue_boss_active = true
	exit_area.enabled = false
	if is_instance_valid(cliff_barrier):
		cliff_barrier.queue_free()
		cliff_barrier = null

	prologue_boss = CharacterBody2D.new()
	prologue_boss.set_script(PROLOGUE_BOSS_SCRIPT)
	prologue_boss.name = "A0_ChurchExecutioner"
	prologue_boss.position = Vector2(1900.0, FLOOR_Y)
	prologue_boss.set("boss_display_name", "教会执行者")
	prologue_boss.set("damage_immune", true)
	prologue_boss.set("persist_global_boss_defeat", false)
	_add_character_collision(prologue_boss, 26.0, 58.0)
	add_child(prologue_boss)
	narrative.show_message(
		"出口之外",
		"通道尽头站着一个没有追赶的理由、却始终挡在前方的人。\n\n他没有回答。刀锋已经抬起。",
		4.0
	)
	print("[NEREIS][PROLOGUE] Scripted executioner encounter started")

func _on_hero_defeated() -> void:
	if prologue_boss_active and not prologue_fall_in_progress:
		call_deferred("_play_forced_cliff_fall")
		return
	for warden in wardens:
		if is_instance_valid(warden) and not warden.is_queued_for_deletion():
			warden.queue_free()
	wardens.clear()
	wardens_defeated = 0
	call_deferred("_spawn_wardens")
	print("[NEREIS][PROLOGUE] Hero defeated; wardens reset")

func _play_forced_cliff_fall() -> void:
	if prologue_fall_in_progress:
		return
	prologue_fall_in_progress = true
	prologue_boss_active = false
	WorldState.input_locked = true
	if is_instance_valid(prologue_boss):
		prologue_boss.queue_free()
	INTERACTION_FOCUS_SCRIPT.clear_all(get_tree())

	# Hero.receive_damage() performs its ordinary checkpoint reset after emitting defeated.
	# Wait one frame, then take control for the one-time narrative fall instead of respawning.
	await get_tree().process_frame
	if is_instance_valid(hero):
		hero.global_position = Vector2(CLIFF_EDGE_X + 24.0, FLOOR_Y - 38.0)
		hero.velocity = Vector2.ZERO
		hero.invulnerable = true
		narrative.show_message(
			"无法战胜的对手",
			"身体已经不再听从指令。那个人没有追来。\n\n脚下的石沿断裂，河谷在视野中翻转。",
			3.2
		)
		var fall_tween := create_tween()
		fall_tween.tween_property(hero, "global_position", Vector2(CLIFF_EDGE_X + 140.0, 760.0), 1.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await fall_tween.finished
		await narrative.message_finished

	narrative.show_message(
		"河水",
		"冰冷的水吞没了最后一点光。\n\n很久以后，有人把昏迷的人从河岸拖了上去。",
		4.0
	)
	await narrative.message_finished

	WorldState.record_achievement("prologue_cliff_fall_rescue_pending")
	WorldState.mark_prologue_complete()
	WorldState.current_location = "village"
	WorldState.pending_region_spawn_side = "west"
	WorldState.save_game()
	WorldState.input_locked = false
	SceneTransition.fade_to_scene("res://scenes/village_hub.tscn")

func _spawn_ui() -> void:
	narrative = CanvasLayer.new()
	narrative.set_script(NARRATIVE_SCRIPT)
	add_child(narrative)

	hud = CanvasLayer.new()
	hud.set_script(HUD_SCRIPT)
	add_child(hud)
	hud.bind_hero(hero)
	hud.set_story_mode("A0｜教会手术所", "向右（D）推进并调查手术托盘；击败 3 名守卫后，前往出口按 E。出口之后还有必须面对的敌人。")

func _show_intro() -> void:
	narrative.show_message(
		"教会手术所",
		"束缚带已经断裂。房间里弥漫着铁锈与焚香的气味。\n\n墙壁深处，有一口钟始终响个不停。",
		5.5
	)

func _create_floor() -> void:
	# The playable floor ends at the cliff lip. A temporary barrier prevents accidental falls
	# before the exit encounter; it is removed when the executioner appears.
	var floor := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(CLIFF_EDGE_X, 40.0)
	shape.shape = rectangle
	shape.position = Vector2(CLIFF_EDGE_X * 0.5, FLOOR_Y + 20.0)
	floor.add_child(shape)
	add_child(floor)

	cliff_barrier = StaticBody2D.new()
	cliff_barrier.name = "CliffLipBarrier"
	cliff_barrier.position = Vector2(CLIFF_EDGE_X, FLOOR_Y - 72.0)
	var barrier_shape := CollisionShape2D.new()
	var barrier_rect := RectangleShape2D.new()
	barrier_rect.size = Vector2(24.0, 176.0)
	barrier_shape.shape = barrier_rect
	cliff_barrier.add_child(barrier_shape)
	add_child(cliff_barrier)

func _create_surgical_catwalks() -> void:
	# A short optional maintenance route crosses the first surgical rooms but cannot bypass the wardens or exit lock.
	# 可选维护高路穿过前段手术室，但不能绕过守卫战或出口锁。
	var route := [
		Rect2(430, 455, 100, 16),
		Rect2(560, 410, 110, 16),
		Rect2(700, 365, 110, 16),
		Rect2(850, 400, 110, 16),
		Rect2(1000, 440, 110, 16),
		Rect2(1130, 400, 110, 16)
	]
	for platform_rect in route:
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

func _draw() -> void:
	draw_texture_rect(SURGERY_BACKDROP, Rect2(0, 0, LEVEL_WIDTH, 720), false)
	draw_texture_rect(SURGERY_FLOOR_STRIP, Rect2(0, FLOOR_Y, CLIFF_EDGE_X, 180), false)
	# A dark river gorge marks the drop; the return route is intentionally unavailable in A0.\n	draw_rect(Rect2(CLIFF_EDGE_X, FLOOR_Y + 18.0, LEVEL_WIDTH - CLIFF_EDGE_X, 220.0), Color("#101c28"))
	for ripple_x in range(int(CLIFF_EDGE_X + 18.0), int(LEVEL_WIDTH - 20.0), 54):
		draw_line(Vector2(ripple_x, FLOOR_Y + 54.0 + sin(float(ripple_x) * 0.04) * 5.0), Vector2(ripple_x + 28.0, FLOOR_Y + 54.0), Color("#334a58", 0.62), 2.0)
	draw_line(Vector2(CLIFF_EDGE_X, FLOOR_Y - 4.0), Vector2(CLIFF_EDGE_X, FLOOR_Y + 42.0), Color("#77717b"), 5.0)

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

	draw_rect(Rect2(120, 280, 420, 240), Color("#29222c"))
	draw_rect(Rect2(180, 240, 300, 40), Color("#352d38"))
	draw_string(ThemeDB.fallback_font, Vector2(210, 215), NereisLocalization.translate_text("教会手术所"), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#7d6c73"))

	# Broken rails mark the optional maintenance catwalk above the surgical tables.
	# 断裂护栏标出手术台上方的可选维护高路。
	draw_line(Vector2(430, 455), Vector2(560, 410), Color("#66515f"), 3.0)
	draw_line(Vector2(560, 410), Vector2(700, 365), Color("#66515f"), 3.0)
	draw_line(Vector2(700, 365), Vector2(850, 400), Color("#66515f"), 3.0)
	draw_line(Vector2(850, 400), Vector2(1000, 440), Color("#66515f"), 3.0)
	draw_line(Vector2(1000, 440), Vector2(1130, 400), Color("#66515f"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(620, 295), "仅供维护人员通行", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#8b737e"))

	for x in [700.0, 1120.0, 1500.0]:
		draw_rect(Rect2(x - 55, 310, 110, 210), Color("#1f1a22"))
		draw_rect(Rect2(x - 44, 330, 88, 12), Color("#46343b"))
		draw_circle(Vector2(x, 320), 9, Color("#9b5c64"))

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(1780, 520),
			Vector2(1900, 270),
			Vector2(2020, 520)
		]),
		Color("#241e27")
	)
	draw_string(ThemeDB.fallback_font, Vector2(1810, 250), NereisLocalization.translate_text("逃脱之路"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#6d5c64"))

	if not exit_open:
		draw_rect(Rect2(2000, 300, 90, 220), Color("#18151b"))
		draw_line(Vector2(2010, 320), Vector2(2010, 500), Color("#5d4c55"), 5.0)
		draw_line(Vector2(2080, 320), Vector2(2080, 500), Color("#5d4c55"), 5.0)
	else:
		draw_rect(Rect2(2000, 300, 90, 220), Color("#33232a"))
		draw_string(ThemeDB.fallback_font, Vector2(1995, 275), NereisLocalization.translate_text("开启"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d6c7b2"))
