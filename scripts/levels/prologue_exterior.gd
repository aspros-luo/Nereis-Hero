extends Node2D


const ENCOUNTER_ESCAPE_SECONDS := 12.0
@onready var hero: CharacterBody2D = $Hero
@onready var boss: CharacterBody2D = $A0_ChurchExecutioner
@onready var narrative: CanvasLayer = $NarrativeManager
@onready var hud: CanvasLayer = $HUD
var cliff_approach_limit: Marker2D
var camera_right_limit: Marker2D
var ending_started := false
var boss_encounter_started := false
var boss_encounter_elapsed := 0.0

func _ready() -> void:
	set_meta("p5_1_exit_contract", true)
	set_meta("p5_1_target_location", "mite_house")
	set_meta("p5_1_target_region", "A0_TRANSITION")
	set_meta("p5_1_target_scene", "res://scenes/mite_house.tscn")
	set_meta("p5_1_spawn_side", "west")
	cliff_approach_limit = get_node_or_null("CliffApproachLimit") as Marker2D
	camera_right_limit = get_node_or_null("CameraBounds/RightEdge") as Marker2D
	if cliff_approach_limit == null or camera_right_limit == null:
		push_error("[NEREIS][PROLOGUE_EXTERIOR][AUTHORED_BOUND_MARKER_MISSING]")
		return
	WorldState.set_location("church_escape_exterior")
	WorldState.record_natural_test_region("A0", "church_escape_exterior")
	hero.set("defer_death_recovery", true)
	hud.bind_hero(hero)
	hud.bind_boss(boss)
	var camera := hero.get_node("HeroCamera") as Camera2D
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(camera_right_limit.global_position.x)
	camera.limit_bottom = 720
	hero.defeated.connect(func() -> void:
		if not ending_started:
			AchievementManager.unlock("prologue_knight_defeat")
			call_deferred("_begin_rescue_transition", "defeated")
	)
	boss.scripted_revival_triggered.connect(_on_executioner_revived)
func _physics_process(delta: float) -> void:
	if ending_started or not is_instance_valid(hero):
		return

	# Keep the cliff approach closed until the executioner encounter resolves.
	# 在执行者遭遇结束前，阻止玩家直接越过战场。
	if is_instance_valid(boss) and hero.global_position.x > cliff_approach_limit.global_position.x:
		hero.global_position.x = cliff_approach_limit.global_position.x
		hero.velocity.x = minf(hero.velocity.x, 0.0)

	if not boss_encounter_started and is_instance_valid(boss):
		if hero.global_position.distance_to(boss.global_position) <= 245.0:
			boss_encounter_started = true
			boss_encounter_elapsed = 0.0
			if is_instance_valid(hud):
				hud.set_story_mode("A0｜洞外山路", "挡路者没有退让。观察他的动作，寻找离开的机会。")

	# The pursuers close in after the encounter window if the scripted revival has not occurred.
	if boss_encounter_started:
		boss_encounter_elapsed += delta
		if boss_encounter_elapsed >= ENCOUNTER_ESCAPE_SECONDS:
			call_deferred("_begin_cliff_escape")




func _on_executioner_revived() -> void:
	if ending_started:
		return
	_show_pursuers()
	for pursuer in $Pursuers.get_children():
		if pursuer.has_method("play_healing"):
			pursuer.call("play_healing")
	call_deferred("_begin_cliff_escape")

func _begin_cliff_escape() -> void:
	if ending_started:
		return
	ending_started = true
	WorldState.input_locked = true
	_clear_interaction_focus()
	_show_pursuers()
	if is_instance_valid(hero):
		hero.set_physics_process(false)
		var leap_target_x := minf(hero.global_position.x + 360.0, camera_right_limit.global_position.x - 24.0)
		var leap := create_tween()
		leap.set_parallel(true)
		leap.tween_property(hero, "global_position:x", leap_target_x, 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		leap.tween_property(hero, "global_position:y", hero.global_position.y - 150.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		leap.chain().tween_property(hero, "global_position:y", 780.0, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		leap.tween_callback(_complete_prologue_transition)
	else:
		_complete_prologue_transition()

func _begin_rescue_transition(_reason: String) -> void:
	if ending_started:
		return
	ending_started = true
	WorldState.input_locked = true
	_clear_interaction_focus()
	_complete_prologue_transition()

func _complete_prologue_transition() -> void:
	if is_instance_valid(boss):
		boss.queue_free()
	WorldState.mark_prologue_complete()
	WorldState.pending_region_spawn_side = "west"
	WorldState.set_location("mite_house")
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
