extends Node2D


const CLIFF_BACKDROP = preload("res://assets/art/backdrops/prologue_cliff_backdrop.svg")
const CLIFF_X := 1120.0
const FLOOR_Y := 540.0
const LEVEL_WIDTH := 1500.0
const CLIFF_APPROACH_LIMIT := CLIFF_X - 26.0
const FORCED_DEFEAT_SECONDS := 12.0
@onready var hero: CharacterBody2D = $Hero
@onready var boss: CharacterBody2D = $A0_ChurchExecutioner
@onready var narrative: CanvasLayer = $NarrativeManager
@onready var hud: CanvasLayer = $HUD
var ending_started := false
var boss_encounter_started := false
var boss_encounter_elapsed := 0.0

func _ready() -> void:
	set_meta("p5_1_exit_contract", true)
	set_meta("p5_1_target_location", "mite_house")
	set_meta("p5_1_target_region", "A0_TRANSITION")
	set_meta("p5_1_target_scene", "res://scenes/mite_house.tscn")
	set_meta("p5_1_spawn_side", "west")
	WorldState.current_location = "church_escape_exterior"
	WorldState.record_natural_test_region("A0", "church_escape_exterior")
	hero.set("defer_death_recovery", true)
	var camera := hero.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = LEVEL_WIDTH
	camera.limit_bottom = 720
	hero.defeated.connect(func() -> void:
		if not ending_started:
			AchievementManager.unlock("prologue_knight_defeat")
			call_deferred("_begin_rescue_transition", "defeated")
	)
	boss.defeated.connect(func() -> void:
		if not ending_started:
			call_deferred("_begin_rescue_transition", "defeated")
	)
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




func _begin_rescue_transition(reason: String) -> void:
	if ending_started:
		return
	ending_started = true
	WorldState.input_locked = true
	_clear_interaction_focus()
	if is_instance_valid(boss):
		boss.queue_free()
	_show_pursuers()

	# Keep the story progression deterministic while the full cliff/fall animation is deferred.
	# A short fade-to-black replaces the unfinished retreat/fall animation; it must not block map development.
	# A0's one-time arrival is intentionally quiet: wake in Mite's house.
	# This is a story arrival, not the village's reusable checkpoint or return spawn.
	WorldState.mark_prologue_complete()
	WorldState.current_location = "mite_house"
	WorldState.pending_region_spawn_side = "west"
	WorldState.save_game()
	SceneTransition.fade_to_scene("res://scenes/mite_house.tscn")

func _show_pursuers() -> void:
	$Pursuers.visible = true
func _clear_interaction_focus() -> void:
	NereisInteractionFocus.clear_all(get_tree())



func _get_shelf_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var shelves := get_node_or_null("MountainShelves") as Node2D
	if shelves == null:
		return rects
	for child in shelves.get_children():
		var body := child as StaticBody2D
		if body == null:
			continue
		var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null or not collision.shape is RectangleShape2D:
			continue
		var rectangle := collision.shape as RectangleShape2D
		rects.append(Rect2(shelves.position + body.position + collision.position - rectangle.size * 0.5, rectangle.size))
	return rects

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
	# Match the five physical shelves above; the darker lower lip gives each ledge a readable edge.
	for shelf_rect in _get_shelf_rects():
		draw_colored_polygon(PackedVector2Array([
			shelf_rect.position,
			Vector2(shelf_rect.end.x, shelf_rect.position.y),
			Vector2(shelf_rect.end.x - 8.0, shelf_rect.end.y + 12.0),
			Vector2(shelf_rect.position.x + 8.0, shelf_rect.end.y + 12.0)
		]), Color("#343640"))
		draw_line(shelf_rect.position, Vector2(shelf_rect.end.x, shelf_rect.position.y), Color("#777783"), 3.0)
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
