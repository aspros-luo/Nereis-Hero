extends Node2D

@onready var hero: CharacterBody2D = $Hero
@onready var boss: CharacterBody2D = $A0_ChurchExecutioner
@onready var narrative: CanvasLayer = $NarrativeManager
@onready var hud: CanvasLayer = $HUD
var cliff_approach_limit: Marker2D
var camera_right_limit: Marker2D
var ending_started := false
var boss_encounter_started := false
var encounter_elapsed := 0.0
var revival_started := false
var hero_defeat_pending := false
var dragon_sequence_started := false
var pursuers_revealed := false

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
	var camera := hero.get_node("HeroCamera") as Camera2D
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(camera_right_limit.global_position.x)
	camera.limit_bottom = 720
	hero.defeated.connect(_on_hero_defeated)
	boss.connect("scripted_revival_started", Callable(self, "_on_executioner_revival_started"))
	boss.connect("scripted_revival_completed", Callable(self, "_on_executioner_revived"))
	boss.connect("phase_changed", Callable(self, "_on_executioner_phase_changed"))
	boss.connect("defeated", Callable(self, "_on_executioner_defeated"))
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
			if is_instance_valid(hud):
				hud.bind_boss(boss)
				hud.set_story_mode("A0｜洞外山路", "挡路者没有退让。观察他的动作，寻找离开的机会。")

	if boss_encounter_started and not revival_started:
		encounter_elapsed += delta
		# A player who chooses not to attack still reaches the same authored story beat.
		if encounter_elapsed >= 30.0 and is_instance_valid(boss):
			boss.call("begin_scripted_revival")





func _on_hero_defeated() -> void:
	if hero_defeat_pending or dragon_sequence_started:
		return
	hero_defeat_pending = true
	ending_started = true
	WorldState.input_locked = true
	_clear_interaction_focus()
	AchievementManager.unlock("prologue_knight_defeat")
	_show_pursuers()
	# Preserve the existing achievement/defeat tableau before the dragon event.
	await get_tree().create_timer(3.2).timeout
	_begin_dragon_attack()

func _on_executioner_revival_started() -> void:
	if dragon_sequence_started:
		return
	revival_started = true
	_show_pursuers()
	for pursuer in $Pursuers.get_children():
		if pursuer.has_method("play_healing"):
			pursuer.call("play_healing")

func _on_executioner_phase_changed(phase: int) -> void:
	if phase >= 2 and not revival_started and not ending_started and is_instance_valid(boss):
		boss.begin_scripted_revival()

func _on_executioner_revived() -> void:
	if hero_defeat_pending or dragon_sequence_started:
		return
	# The executioner gets one brief return to combat; the dragon interrupts that renewed fight.
	if is_instance_valid(boss):
		boss.set("scripted_revival", false)
	call_deferred("_begin_post_revival_battle")

func _begin_post_revival_battle() -> void:
	await get_tree().create_timer(2.4).timeout
	if not hero_defeat_pending and not dragon_sequence_started:
		_begin_dragon_attack()

func _on_executioner_defeated() -> void:
	if not hero_defeat_pending and not dragon_sequence_started:
		call_deferred("_begin_dragon_attack")

func _begin_dragon_attack() -> void:
	if dragon_sequence_started:
		return
	dragon_sequence_started = true
	ending_started = true
	WorldState.input_locked = true
	_clear_interaction_focus()
	_show_pursuers()

	if is_instance_valid(boss):
		boss.set("damage_immune", true)
		boss.set_process(false)
		boss.set_physics_process(false)
	if is_instance_valid(hero):
		hero.set_physics_process(false)
		hero.velocity = Vector2.ZERO
		var camera := hero.get_node_or_null("HeroCamera") as Camera2D
		if camera:
			camera.position_smoothing_enabled = false
			camera.limit_bottom = 1600

	var dragon := $DragonPass as Node2D
	dragon.visible = true
	var flight := create_tween()
	flight.tween_property(dragon, "position", Vector2(900, 115), 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	flight.tween_property(dragon, "position", Vector2(1380, 430), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flight.tween_property(dragon, "position", Vector2(1880, 170), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var dive_tilt := create_tween()
	dive_tilt.tween_property(dragon, "rotation", 0.12, 1.25)
	dive_tilt.tween_property(dragon, "rotation", 0.38, 0.4)
	dive_tilt.tween_property(dragon, "rotation", 0.0, 0.7)

	var left_wing := $DragonPass/LeftWing as Polygon2D
	var right_wing := $DragonPass/RightWing as Polygon2D
	var left_flap := create_tween().set_loops(4)
	left_flap.tween_property(left_wing, "rotation", 0.38, 0.24)
	left_flap.tween_property(left_wing, "rotation", -0.32, 0.24)
	var right_flap := create_tween().set_loops(4)
	right_flap.tween_property(right_wing, "rotation", -0.34, 0.24)
	right_flap.tween_property(right_wing, "rotation", 0.30, 0.24)

	# The dragon crosses the valley; it never targets the hero or the executioner.
	await get_tree().create_timer(1.65).timeout
	_collapse_mountain_road()

	await get_tree().create_timer(0.28).timeout
	if is_instance_valid(hero):
		var fall := create_tween()
		fall.set_parallel(true)
		fall.tween_property(hero, "global_position:x", hero.global_position.x + 42.0, 2.35)
		fall.tween_property(hero, "global_position:y", hero.global_position.y + 820.0, 2.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fall.tween_property(hero, "rotation", 0.16, 2.35).set_trans(Tween.TRANS_SINE)
		await fall.finished

	# Hold the deep-gorge view briefly so the fall reads as an event, not a scene cut.
	await get_tree().create_timer(1.35).timeout
	_complete_prologue_transition()

func _collapse_mountain_road() -> void:
	var road := $MountainPathGround as StaticBody2D
	var collision := road.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision:
		collision.set_deferred("disabled", true)

	# A pre-authored fracture rig breaks apart at the dragon's cliff impact point.
	var fracture := $CliffFractureVisual as Node2D
	fracture.visible = true
	var dust := $CliffFractureVisual/DustBurst as Polygon2D
	dust.scale = Vector2(0.55, 0.55)
	var dust_tween := create_tween()
	dust_tween.set_parallel(true)
	dust_tween.tween_property(dust, "scale", Vector2(1.8, 1.45), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	dust_tween.tween_property(dust, "modulate:a", 0.0, 1.0)

	var shard_targets := [
		["Shard01", Vector2(-168, 92), -0.72],
		["Shard02", Vector2(-42, 148), 0.48],
		["Shard03", Vector2(126, 88), 0.82],
		["Shard04", Vector2(-208, 178), -0.42],
		["Shard05", Vector2(8, 212), 0.66],
		["Shard06", Vector2(190, 164), 1.05]
	]
	for target in shard_targets:
		var shard := fracture.get_node(String(target[0])) as Polygon2D
		var shard_tween := create_tween()
		shard_tween.set_parallel(true)
		shard_tween.tween_property(shard, "position", target[1], 1.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		shard_tween.tween_property(shard, "rotation", float(target[2]), 1.05)
		shard_tween.tween_property(shard, "modulate:a", 0.0, 1.1)

	var rubble := $ImpactRubbleVisual as Node2D
	rubble.visible = true
	var rubble_tween := create_tween()
	rubble_tween.set_parallel(true)
	rubble_tween.tween_property(rubble, "position:y", rubble.position.y + 112.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	rubble_tween.tween_property(rubble, "modulate:a", 0.0, 1.25)

	var road_tween := create_tween()
	road_tween.set_parallel(true)
	road_tween.tween_property(road, "position:y", road.position.y + 230.0, 1.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	road_tween.tween_property(road, "rotation", 0.18, 1.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if is_instance_valid(hero):
		var camera := hero.get_node_or_null("HeroCamera") as Camera2D
		if camera:
			var shake := create_tween()
			shake.tween_property(camera, "offset", Vector2(14, -10), 0.07)
			shake.tween_property(camera, "offset", Vector2(-11, 8), 0.07)
			shake.tween_property(camera, "offset", Vector2(7, -5), 0.07)
			shake.tween_property(camera, "offset", Vector2.ZERO, 0.18)

func _complete_prologue_transition() -> void:
	if is_instance_valid(boss):
		boss.queue_free()
	WorldState.mark_prologue_complete()
	WorldState.pending_region_spawn_side = "west"
	WorldState.set_location("mite_house")
	SceneTransition.fade_to_scene("res://scenes/mite_house.tscn", 0.85, 1.15, 1.1)

func _show_pursuers() -> void:
	if pursuers_revealed:
		return
	pursuers_revealed = true
	$Pursuers.visible = true
	for pursuer in $Pursuers.get_children():
		if pursuer.has_method("begin_cave_blockade"):
			pursuer.call("begin_cave_blockade")
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
