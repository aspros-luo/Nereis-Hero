extends Node2D

const WARDEN_SCENE: PackedScene = preload("res://scenes/enemies/experiment_warden.tscn")

var hero: CharacterBody2D
var hud: CanvasLayer
var wardens: Array[CharacterBody2D] = []
var exit_area: Area2D
var ambush_started := false
var ambush_phase := 0
var wardens_defeated := 0
var right_gate_closed := false
var first_combat_prompt_shown := false
var progress_barriers: Array[StaticBody2D] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if WorldState.prologue_complete:
		get_tree().change_scene_to_file("res://scenes/regions/village_hub.tscn")
		return
	hero = $Hero
	hud = $HUD
	exit_area = $VillageRoadExit
	progress_barriers = [$ProgressBarrier_Left as StaticBody2D, $ProgressBarrier_Right as StaticBody2D]
	for gate in progress_barriers:
		gate.visible = false
		(gate.get_node("CollisionShape2D") as CollisionShape2D).disabled = true
	WorldState.set_location("church_escape_s02")
	WorldState.record_natural_test_region("A0", "church_escape_s02")
	if not WorldState.checkpoint_active or WorldState.checkpoint_room_id != "a0_s02_ambush":
		WorldState.set_checkpoint(hero.global_position, "a0_s02_ambush")
	hero.defeated.connect(_on_hero_defeated)
	$ExitAmbushTrigger.body_entered.connect(_on_ambush_trigger_body_entered)
	$HUD.bind_hero(hero)
	$HUD.set_story_mode("A0｜洞穴逃亡", "沿着通道寻找出口。")
	exit_area.interacted.connect(_on_exit_interacted)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if ambush_phase == 1 and not right_gate_closed:
		var doorway_warden := get_node_or_null("Wardens/Warden_Right") as CharacterBody2D
		if is_instance_valid(doorway_warden) and doorway_warden.global_position.x <= $AmbushSpawnMarkers/RightGateClosureThreshold.global_position.x:
			_show_barrier("ProgressBarrier_Right")
			right_gate_closed = true
	if first_combat_prompt_shown or wardens_defeated > 0 or not is_instance_valid(hero) or wardens.is_empty():
		return
	if is_instance_valid(wardens[0]) and hero.global_position.distance_to(wardens[0].global_position) <= 260.0:
		first_combat_prompt_shown = true
		hud.set_story_mode("A0｜洞穴逃亡", "伏击开始！观察敌人的攻击前摇，利用走位和闪避寻找空隙。")

func _on_ambush_trigger_body_entered(body: Node2D) -> void:
	if body == hero and not ambush_started:
		# body_entered runs while the physics server is flushing queries.
		# Defer the whole setup so adding Areas / changing collision shapes is safe.
		ambush_started = true
		_start_ambush.call_deferred()

func _start_ambush() -> void:
	if not is_inside_tree() or not is_instance_valid(hero):
		return
	ambush_phase = 1
	_show_barrier("ProgressBarrier_Left")
	_spawn_warden("WardenLeft", "Warden_Left")
	_spawn_warden("WardenRight", "Warden_Right")
	hud.set_story_mode("A0｜洞穴逃亡", "前后方都有脚步声。先解决逼近的两名守卫。")
	print("[NEREIS][A0][S02] Ambush wave 1 started")

func _spawn_warden(marker_name: String, enemy_name: String) -> void:
	var marker := get_node_or_null("AmbushSpawnMarkers/" + marker_name) as Marker2D
	if marker == null:
		push_error("[NEREIS][A0][S02] Missing authored spawn marker: " + marker_name)
		return
	var warden := WARDEN_SCENE.instantiate() as CharacterBody2D
	if warden == null:
		push_error("[NEREIS][A0][S02] Could not instantiate warden")
		return
	warden.name = enemy_name
	warden.global_position = marker.global_position
	$Wardens.add_child(warden)
	warden.defeated.connect(_on_warden_defeated)
	wardens.append(warden)

func _show_barrier(gate_name: String) -> void:
	var gate := get_node_or_null(gate_name) as StaticBody2D
	if gate == null:
		push_error("[NEREIS][A0][S02] Missing authored barrier: " + gate_name)
		return
	gate.visible = true
	(gate.get_node("CollisionShape2D") as CollisionShape2D).set_deferred("disabled", false)

func _hide_barriers() -> void:
	for gate in progress_barriers:
		if is_instance_valid(gate):
			gate.visible = false
			(gate.get_node("CollisionShape2D") as CollisionShape2D).set_deferred("disabled", true)

func _on_warden_defeated() -> void:
	wardens_defeated += 1
	if ambush_phase == 1 and wardens_defeated >= 2:
		ambush_phase = 2
		_spawn_warden.call_deferred("WardenDrop", "Warden_Drop")
		hud.set_story_mode("A0｜洞穴逃亡", "上方传来金属断裂声……第三名守卫从高处坠落！")
		return
	if ambush_phase == 2 and wardens_defeated >= 3:
		ambush_phase = 3
		_hide_barriers()
		exit_area.enabled = true
		hud.set_story_mode("A0｜洞穴逃亡", "通往山外的道路终于打开了。")
		print("[NEREIS][A0][S02] Ambush cleared")
		return
	var remaining := maxi(0, 3 - wardens_defeated)
	hud.set_story_mode("A0｜洞穴逃亡", "守卫倒下了。还剩 %d 名敌人。" % remaining)

func _on_hero_defeated() -> void:
	for warden in wardens:
		if is_instance_valid(warden):
			warden.queue_free()
	wardens.clear()
	wardens_defeated = 0
	ambush_started = false
	ambush_phase = 0
	right_gate_closed = false
	first_combat_prompt_shown = false
	exit_area.enabled = false
	_hide_barriers()
	hud.set_story_mode("A0｜洞穴逃亡", "你在洞穴入口附近恢复了意识。再次前进时，伏击者仍在等候。")

func _on_exit_interacted() -> void:
	if ambush_phase != 3 or WorldState.input_locked:
		return
	WorldState.input_locked = true
	WorldState.pending_region_spawn_side = "west"
	WorldState.set_location("church_escape_exterior")
	SceneTransition.fade_to_scene("res://scenes/prologue_exterior.tscn")
