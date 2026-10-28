@tool
extends Node2D

const WARDEN_SCENE: PackedScene = preload("res://scenes/enemies/experiment_warden.tscn")

var hero: CharacterBody2D
var hud: CanvasLayer
var wardens: Array[CharacterBody2D] = []
var exit_area: Area2D
var ambush_trigger: Area2D
var right_gate_closure_threshold: Marker2D
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
		_sync_exit_gate_visual()
		queue_redraw()
		return
	if WorldState.prologue_complete:
		get_tree().change_scene_to_file("res://scenes/regions/village_hub.tscn")
		return

	hero = $Hero
	hud = $HUD
	exit_area = $VillageRoadExit
	ambush_trigger = $ExitAmbushTrigger
	right_gate_closure_threshold = $AmbushSpawnMarkers/RightGateClosureThreshold
	if ambush_trigger == null or right_gate_closure_threshold == null:
		push_error("[NEREIS][PROLOGUE][AUTHORED_TRIGGER_MISSING] exit ambush trigger or right-gate threshold")
		return
	ambush_trigger.body_entered.connect(_on_ambush_trigger_body_entered)
	progress_barriers = [$ProgressBarrier_Left as StaticBody2D, $ProgressBarrier_Right as StaticBody2D]
	for gate in progress_barriers:
		gate.visible = false
		var collision := gate.get_node("CollisionShape2D") as CollisionShape2D
		collision.disabled = true
	WorldState.current_location = "church_escape"
	WorldState.record_natural_test_region("A0", "church_escape")
	WorldState.set_checkpoint(hero.global_position)

	hero.defeated.connect(_on_hero_defeated)
	exit_area.interacted.connect(_on_exit_interacted)
	var clue := $SurgicalMark
	clue.examined.connect(_on_clue_examined.bind(clue))
	hud.bind_hero(hero)
	hud.set_story_mode("A0｜教会手术所", "查看手术托盘和周边物品，寻找离开的路。")

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if ambush_phase == 1 and not right_gate_closed:
		var doorway_warden := get_node_or_null("Warden_Right") as CharacterBody2D
		if is_instance_valid(doorway_warden) and is_instance_valid(right_gate_closure_threshold) and doorway_warden.global_position.x <= right_gate_closure_threshold.global_position.x:
			_spawn_single_progress_barrier(2000.0)
			right_gate_closed = true
	if first_combat_prompt_shown or wardens_defeated > 0 or not is_instance_valid(hero) or wardens.is_empty():
		return
	var first_warden := wardens[0]
	if is_instance_valid(first_warden) and hero.global_position.distance_to(first_warden.global_position) <= 260.0:
		first_combat_prompt_shown = true
		if is_instance_valid(hud):
			hud.set_story_mode("A0｜教会手术所", "伏击开始！留意两侧来敌与上方坠落的守卫，利用攻击前摇进行闪避。")


func _on_ambush_trigger_body_entered(body: Node2D) -> void:
	if body == hero and not ambush_started:
		_start_exit_ambush()


func _start_exit_ambush() -> void:
	if ambush_started:
		return
	ambush_started = true
	_spawn_progress_barriers()
	# Wave 1: the left warden walks in from the left; the second enters from the doorway.
	# 第一波只出现两名地面守卫，先给玩家时间读懂战斗节奏。
	ambush_phase = 1
	_spawn_warden_from_marker("WardenLeft", "Warden_Left")
	_spawn_warden_from_marker("WardenRight", "Warden_Right")
	if is_instance_valid(hud):
		hud.set_story_mode("A0｜教会手术所", "左侧传来沉重的脚步声，出口处的守卫也逼了进来！先解决他们。")
	print("[NEREIS][PROLOGUE] Exit ambush wave 1 started")


func _spawn_warden_from_marker(marker_name: String, enemy_name: String) -> void:
	# Enemy actors are dynamic, but their fixed spawn anchors belong to the editable scene.
	# 敌人本身动态生成；固定出场锚点由场景节点维护。
	var marker := get_node_or_null("AmbushSpawnMarkers/" + marker_name) as Marker2D
	if marker == null:
		push_error("[NEREIS][PROLOGUE][SPAWN_MARKER_MISSING] marker=%s" % marker_name)
		return
	_spawn_warden(to_local(marker.global_position), enemy_name)


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
	# Both barrier nodes are authored in escape_prologue.tscn; only their state changes at runtime.
	for gate in progress_barriers:
		gate.visible = false
		var collision := gate.get_node("CollisionShape2D") as CollisionShape2D
		collision.disabled = true
	_spawn_single_progress_barrier(1320.0)


func _spawn_single_progress_barrier(gate_x: float) -> void:
	var gate_name := "ProgressBarrier_Left" if gate_x < 1600.0 else "ProgressBarrier_Right"
	var gate := get_node_or_null(gate_name) as StaticBody2D
	if gate == null:
		push_error("[NEREIS][PROLOGUE] Missing authored progress barrier: " + gate_name)
		return
	# Fixed barrier coordinates are authored in escape_prologue.tscn; runtime only toggles state.
	# 固定障碍的位置由场景节点定义，运行时只切换可见性与碰撞状态。
	gate.visible = true
	var collision := gate.get_node("CollisionShape2D") as CollisionShape2D
	collision.disabled = false


func _open_progress_barrier(index: int) -> void:
	if index < 0 or index >= progress_barriers.size():
		return
	var gate := progress_barriers[index]
	if is_instance_valid(gate):
		gate.visible = false
		var collision := gate.get_node("CollisionShape2D") as CollisionShape2D
		collision.disabled = true


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
			gate.visible = false
			var collision := gate.get_node("CollisionShape2D") as CollisionShape2D
			collision.disabled = true
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


func _on_warden_defeated() -> void:
	wardens_defeated += 1
	if ambush_phase == 1 and wardens_defeated >= 2:
		# Wave 2 only begins after both ground wardens are defeated.
		# 第二波必须等两名地面守卫全部倒下后才触发。
		ambush_phase = 2
		_spawn_warden_from_marker("WardenDrop", "Warden_Drop")
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
	_sync_exit_gate_visual()
	exit_area.enabled = true
	if is_instance_valid(hud):
		hud.set_story_mode("A0｜教会手术所", "出口已打开。前往右侧出口按 E，离开手术所。")
	print("[NEREIS][PROLOGUE] Escape route opened")


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
		get_tree().change_scene_to_file("res://scenes/debug/world_map_test_menu.tscn")
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		_mark_input_handled()
		WorldState.delete_save()
		get_tree().change_scene_to_file("res://scenes/regions/escape_prologue.tscn")


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


func _sync_exit_gate_visual() -> void:
	var gate := get_node_or_null("ExitGateVisual")
	if gate == null:
		return
	gate.visible = true
	var closed := gate.get_node_or_null("ClosedGate") as CanvasItem
	var left_bar := gate.get_node_or_null("LeftBar") as CanvasItem
	var right_bar := gate.get_node_or_null("RightBar") as CanvasItem
	var opened := gate.get_node_or_null("OpenedGate") as CanvasItem
	var label := gate.get_node_or_null("OpenedLabel") as CanvasItem
	if closed != null:
		closed.visible = not exit_open
	if left_bar != null:
		left_bar.visible = not exit_open
	if right_bar != null:
		right_bar.visible = not exit_open
	if opened != null:
		opened.visible = exit_open
	if label != null:
		label.visible = exit_open
