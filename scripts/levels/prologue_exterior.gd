extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const BOSS_SCRIPT = preload("res://scripts/enemies/ashen_knight.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const CLIFF_X := 1120.0
const FLOOR_Y := 540.0
const LEVEL_WIDTH := 1500.0

var hero: CharacterBody2D
var boss: CharacterBody2D
var narrative: CanvasLayer
var hud: CanvasLayer
var ending_started := false

func _ready() -> void:
	set_meta("p5_1_exit_contract", true)
	set_meta("p5_1_target_location", "village")
	set_meta("p5_1_target_region", "A1")
	set_meta("p5_1_target_scene", "res://scenes/village_hub.tscn")
	set_meta("p5_1_spawn_side", "west")
	WorldState.current_location = "church_escape_exterior"
	WorldState.record_natural_test_region("A0", "church_escape_exterior")
	_create_ground()
	_spawn_hero()
	_spawn_boss()
	_spawn_ui()
	if not WorldState.debug_map_test_mode:
		get_tree().create_timer(0.45).timeout.connect(_show_intro)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if ending_started or not is_instance_valid(hero):
		return
	if hero.global_position.x >= CLIFF_X + 12.0 and hero.global_position.y >= FLOOR_Y + 48.0:
		call_deferred("_begin_rescue_transition", "cliff")

func _spawn_hero() -> void:
	hero = CharacterBody2D.new()
	hero.set_script(HERO_SCRIPT)
	hero.name = "Hero"
	hero.position = Vector2(150.0, FLOOR_Y)
	_add_character_collision(hero, 18.0, 48.0)
	add_child(hero)
	hero.defeated.connect(func() -> void:
		if not ending_started:
			call_deferred("_begin_rescue_transition", "defeated")
	)
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = LEVEL_WIDTH
	camera.limit_bottom = 720
	hero.add_child(camera)

func _spawn_boss() -> void:
	boss = CharacterBody2D.new()
	boss.set_script(BOSS_SCRIPT)
	boss.name = "A0_ChurchExecutioner"
	boss.position = Vector2(760.0, FLOOR_Y)
	boss.set("boss_display_name", "教会执行者")
	boss.set("damage_immune", true)
	boss.set("persist_global_boss_defeat", false)
	_add_character_collision(boss, 26.0, 58.0)
	add_child(boss)

func _spawn_ui() -> void:
	narrative = CanvasLayer.new()
	narrative.set_script(NARRATIVE_SCRIPT)
	add_child(narrative)
	hud = CanvasLayer.new()
	hud.set_script(HUD_SCRIPT)
	add_child(hud)
	hud.bind_hero(hero)
	hud.set_story_mode("A0｜洞外山路", "沿山路前进。眼前的人挡住了唯一的出口。")

func _show_intro() -> void:
	if ending_started or not is_instance_valid(narrative):
		return
	narrative.show_message(
		"洞外山路",
		"山风从狭窄的洞口灌进来。身后的铁门已经合拢。\n\n前方的山路通向河谷；一个教会的身影横在路中央。",
		4.5
	)


func _begin_rescue_transition(reason: String) -> void:
	if ending_started:
		return
	ending_started = true
	WorldState.input_locked = true
	_clear_interaction_focus()
	if is_instance_valid(boss):
		boss.queue_free()
	if is_instance_valid(hero):
		hero.velocity = Vector2.ZERO
		hero.invulnerable = true
	if is_instance_valid(narrative):
		var text := "刀锋落下，身体终于支撑不住。山路在眼前沉入黑暗。" if reason == "defeated" else "碎石从脚下崩落。你坠向被雾吞没的河谷。"
		narrative.show_caption("失去意识", text, 1.0)
		WorldState.input_locked = true
		await get_tree().create_timer(0.85).timeout
	WorldState.record_achievement("prologue_cliff_fall_rescue_pending")
	WorldState.mark_prologue_complete()
	WorldState.current_location = "village"
	WorldState.pending_region_spawn_side = "west"
	WorldState.save_game()
	SceneTransition.fade_to_scene("res://scenes/village_hub.tscn")

func _clear_interaction_focus() -> void:
	NereisInteractionFocus.clear_all(get_tree())

func _create_ground() -> void:
	var ground := StaticBody2D.new()
	ground.name = "MountainPathGround"
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(CLIFF_X, 40.0)
	shape.shape = rectangle
	shape.position = Vector2(CLIFF_X * 0.5, FLOOR_Y + 20.0)
	ground.add_child(shape)
	add_child(ground)
	var left_wall := StaticBody2D.new()
	var left_shape := CollisionShape2D.new()
	var left_rect := RectangleShape2D.new()
	left_rect.size = Vector2(40.0, 720.0)
	left_shape.shape = left_rect
	left_shape.position = Vector2(-20.0, 360.0)
	left_wall.add_child(left_shape)
	add_child(left_wall)

func _add_character_collision(character: CharacterBody2D, radius: float, height: float) -> void:
	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = radius
	capsule.height = height
	collision.shape = capsule
	collision.position = Vector2(0.0, -height * 0.5)
	character.add_child(collision)

func _draw() -> void:
	# Outdoor palette and distant ridgelines clearly separate this space from the surgery interior.
	draw_rect(Rect2(0, 0, LEVEL_WIDTH, 720), Color("#111923"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 390), Vector2(170, 250), Vector2(330, 360),
		Vector2(520, 205), Vector2(710, 360), Vector2(890, 230),
		Vector2(1080, 355), Vector2(1280, 210), Vector2(1500, 370),
		Vector2(1500, 540), Vector2(0, 540)
	]), Color("#252d39"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 455), Vector2(250, 350), Vector2(420, 445),
		Vector2(650, 320), Vector2(850, 455), Vector2(1030, 350),
		Vector2(1250, 430), Vector2(1500, 340), Vector2(1500, 540),
		Vector2(0, 540)
	]), Color("#1b252e"))
	# Cave mouth behind the player; the open path leads toward a broken cliff above the river.
	draw_rect(Rect2(35, 300, 185, 240), Color("#090c12"))
	draw_arc(Vector2(127, 315), 92.0, PI, TAU, 32, Color("#59606c"), 12.0)
	draw_line(Vector2(250, 500), Vector2(520, 478), Color("#5b606b"), 3.0)
	draw_line(Vector2(520, 478), Vector2(740, 505), Color("#5b606b"), 3.0)
	draw_line(Vector2(740, 505), Vector2(CLIFF_X - 12.0, 485), Color("#5b606b"), 3.0)
	draw_rect(Rect2(CLIFF_X, FLOOR_Y + 18.0, LEVEL_WIDTH - CLIFF_X, 230.0), Color("#0b121c"))
	for ripple_x in range(int(CLIFF_X + 20.0), int(LEVEL_WIDTH - 20.0), 48):
		draw_line(Vector2(ripple_x, FLOOR_Y + 62.0 + sin(float(ripple_x) * 0.04) * 4.0), Vector2(ripple_x + 24.0, FLOOR_Y + 62.0), Color("#344958", 0.65), 2.0)
	draw_line(Vector2(CLIFF_X, FLOOR_Y - 12.0), Vector2(CLIFF_X, FLOOR_Y + 34.0), Color("#7b8189"), 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(55, 265), "山洞出口", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#9a9aa8"))
	draw_string(ThemeDB.fallback_font, Vector2(565, 270), "通往河谷的山路", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#a7a6b0"))
