extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const BOSS_SCRIPT = preload("res://scripts/enemies/ashen_knight.gd")
const PURSUER_SCRIPT = preload("res://scripts/levels/prologue_pursuer.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const CLIFF_BACKDROP = preload("res://assets/art/backdrops/prologue_cliff_backdrop.svg")
const CLIFF_X := 1120.0
const FLOOR_Y := 540.0
const LEVEL_WIDTH := 1500.0
const CLIFF_APPROACH_LIMIT := CLIFF_X - 26.0
const FORCED_DEFEAT_SECONDS := 12.0

var hero: CharacterBody2D
var boss: CharacterBody2D
var narrative: CanvasLayer
var hud: CanvasLayer
var ending_started := false
var boss_encounter_started := false
var boss_encounter_elapsed := 0.0

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
	queue_redraw()

func _physics_process(delta: float) -> void:
	if ending_started or not is_instance_valid(hero):
		return

	# The cliff is a forced-loss boundary, not an alternate way to skip the executioner.
	# 悬崖是必败演出的边界，不是绕过出口执行者的捷径。
	if is_instance_valid(boss) and hero.global_position.x > CLIFF_APPROACH_LIMIT:
		hero.global_position.x = CLIFF_APPROACH_LIMIT
		hero.velocity.x = minf(hero.velocity.x, 0.0)

	if not boss_encounter_started and is_instance_valid(boss):
		if hero.global_position.distance_to(boss.global_position) <= 245.0:
			boss_encounter_started = true
			boss_encounter_elapsed = 0.0
			if is_instance_valid(hud):
				hud.set_story_mode("A0｜洞外山路", "挡路者没有退让。观察他的动作，寻找离开的机会。")

	# Mandatory-loss story gate: combat remains interactive, but cannot skip the authored defeat and rescue.
	if boss_encounter_started:
		boss_encounter_elapsed += delta
		if boss_encounter_elapsed >= FORCED_DEFEAT_SECONDS:
			call_deferred("_begin_rescue_transition", "defeated")

func _spawn_hero() -> void:
	hero = CharacterBody2D.new()
	hero.set_script(HERO_SCRIPT)
	hero.name = "Hero"
	hero.position = Vector2(150.0, FLOOR_Y)
	hero.set("defer_death_recovery", true)
	_add_character_collision(hero, 18.0, 48.0)
	add_child(hero)
	hero.defeated.connect(func() -> void:
		if not ending_started:
			AchievementManager.unlock("prologue_knight_defeat")
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
	boss.set("health", 900)
	boss.set("max_health", 900)
	boss.set("damage_taken_multiplier", 0.42)
	boss.set("persist_global_boss_defeat", false)
	_add_character_collision(boss, 26.0, 58.0)
	add_child(boss)
	# Defensive fallback in case a future combat change bypasses damage immunity.
	boss.defeated.connect(func() -> void:
		if not ending_started:
			call_deferred("_begin_rescue_transition", "defeated")
	)

func _spawn_ui() -> void:
	narrative = CanvasLayer.new()
	narrative.set_script(NARRATIVE_SCRIPT)
	add_child(narrative)
	hud = CanvasLayer.new()
	hud.set_script(HUD_SCRIPT)
	add_child(hud)
	hud.bind_hero(hero)
	hud.set_story_mode("A0｜洞外山路", "沿山路前进。眼前的人挡住了唯一的出口。")

func _begin_rescue_transition(reason: String) -> void:
	if ending_started:
		return
	ending_started = true
	WorldState.input_locked = true
	_clear_interaction_focus()
	if is_instance_valid(boss):
		boss.queue_free()
	_spawn_pursuers()

	var fall_tween: Tween
	if is_instance_valid(hero):
		hero.invulnerable = true
		hero.velocity = Vector2.ZERO
		# The level owns the authored ending; stop gameplay physics but preserve the real defeat position.
		hero.set_physics_process(false)
		fall_tween = create_tween()
		fall_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		# Retreat is continuous from the actual combat position; no visible snap to the cliff.
		var retreat_target := Vector2(CLIFF_X - 20.0, FLOOR_Y - 18.0)
		var retreat_distance := hero.global_position.distance_to(retreat_target)
		var retreat_duration := clampf(retreat_distance / 430.0, 0.22, 1.15)
		fall_tween.tween_property(hero, "global_position", retreat_target, retreat_duration)
		fall_tween.tween_property(hero, "global_position", Vector2(CLIFF_X + 42.0, FLOOR_Y + 165.0), 0.55)

	if is_instance_valid(narrative):
		var title := "无路可退"
		var text := "你被逼到悬崖边。身后传来追兵的脚步声，前方只剩被雾吞没的河谷。"
		narrative.show_caption(title, text, 1.35)
		WorldState.input_locked = true

	if fall_tween != null:
		await fall_tween.finished
	await get_tree().create_timer(0.18).timeout
	WorldState.record_achievement("prologue_cliff_fall_rescue_pending")
	WorldState.mark_prologue_complete()
	WorldState.current_location = "village"
	WorldState.pending_region_spawn_side = "west"
	WorldState.save_game()
	SceneTransition.fade_to_scene("res://scenes/village_hub.tscn")

func _spawn_pursuers() -> void:
	# The chase is represented on-screen, not only described by the caption.
	# 追兵实际出现在画面中，封住退路；这组剪影仅服务于演出，不介入战斗逻辑。
	var positions := [Vector2(630.0, FLOOR_Y), Vector2(770.0, FLOOR_Y), Vector2(910.0, FLOOR_Y)]
	for i in range(positions.size()):
		var pursuer := Node2D.new()
		pursuer.set_script(PURSUER_SCRIPT)
		pursuer.name = "ChurchPursuer_%02d" % (i + 1)
		pursuer.set("variant", i)
		pursuer.set("lantern", i == 0)
		pursuer.position = positions[i]
		add_child(pursuer)

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
	# Painted scenic layer is visual-only; collision, encounter bounds and cliff coordinates stay in code.
	# 绘制感远景只负责视觉；碰撞、遭遇边界和悬崖坐标仍由逻辑代码控制。
	draw_texture_rect(CLIFF_BACKDROP, Rect2(0.0, 0.0, LEVEL_WIDTH, 720.0), false)
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
	# Broken masonry and a collapsed path frame the edge; the player cannot bypass the scripted encounter.
	draw_colored_polygon(PackedVector2Array([
		Vector2(CLIFF_X - 86.0, FLOOR_Y - 6.0),
		Vector2(CLIFF_X - 72.0, FLOOR_Y - 52.0),
		Vector2(CLIFF_X - 46.0, FLOOR_Y - 32.0),
		Vector2(CLIFF_X - 22.0, FLOOR_Y - 68.0),
		Vector2(CLIFF_X - 4.0, FLOOR_Y - 8.0)
	]), Color("#3a3b43"))
	draw_line(Vector2(CLIFF_X - 90.0, FLOOR_Y - 8.0), Vector2(CLIFF_X - 8.0, FLOOR_Y - 8.0), Color("#72717b"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(55, 265), "山洞出口", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#9a9aa8"))
	draw_string(ThemeDB.fallback_font, Vector2(565, 270), "通往河谷的山路", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#a7a6b0"))
