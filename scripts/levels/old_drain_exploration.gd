extends Node2D
## Compact first-visit exploration section for the village's old drainage passage.
## 村庄旧排水口的早期探索短段；后续从城区/水库侧开启连接。

const SEWER_RAT_SCENE: PackedScene = preload("res://scenes/enemies/sewer_rat.tscn")
const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

const VILLAGE_SCENE := "res://scenes/regions/village_hub.tscn"
const CITY_SCENE := "res://scenes/regions/forgotten_city.tscn"
const RESERVOIR_SCENE := "res://scenes/regions/sewer_reservoir.tscn"
const CONNECTION_FLAG := "opened_old_drainage_link_from_A4"

@onready var hero: CharacterBody2D = $Hero
@onready var narrative: CanvasLayer = $NarrativeManager
@onready var hud: CanvasLayer = $HUD
var entry_side := "village_entry"
var respawning := false
@onready var village_door: Area2D = $VillageReturnDoor
@onready var city_door: Area2D = $CityGateDoor
@onready var reservoir_door: Area2D = $ReservoirDoor
@onready var gate_blocker: CollisionShape2D = $SealedOldDrainGate/CollisionShape2D

func _ready() -> void:
	WorldState.prepare_scene_runtime()
	entry_side = WorldState.pending_region_spawn_side
	WorldState.pending_region_spawn_side = "west"
	WorldState.set_location("old_drain_exploration")
	hero.position = Vector2(_spawn_x_for_side(entry_side), _spawn_y_for_side(entry_side))
	var camera := hero.get_node("HeroCamera") as Camera2D
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 2400
	camera.limit_bottom = 900
	hero.defeated.connect(_on_hero_defeated)
	WorldState.set_checkpoint(hero.global_position)
	village_door.set_meta("p5_1_exit_contract", true)
	village_door.set_meta("p5_1_target_scene", VILLAGE_SCENE)
	village_door.set_meta("p5_1_target_region", "A1")
	village_door.set_meta("p5_1_spawn_side", "city_cut_return")
	village_door.interacted.connect(_return_to_village)
	if CONNECTION_FLAG in WorldState.achievement_flags:
		city_door.set("prompt_text", "E  沿旧排水道进入城区")
		city_door.set_meta("p5_1_exit_contract", true)
		city_door.set_meta("p5_1_target_scene", CITY_SCENE)
		city_door.set_meta("p5_1_target_region", "A3")
		city_door.set_meta("p5_1_spawn_side", "village_city_cut")
		city_door.interacted.connect(_enter_city)
		reservoir_door.visible = true
		reservoir_door.monitoring = true
		(reservoir_door.get_node("CollisionShape2D") as CollisionShape2D).disabled = false
		reservoir_door.set_meta("p5_1_exit_contract", true)
		reservoir_door.set_meta("p5_1_target_scene", RESERVOIR_SCENE)
		reservoir_door.set_meta("p5_1_target_region", "A4")
		reservoir_door.set_meta("p5_1_spawn_side", "old_drain_link")
		reservoir_door.interacted.connect(_return_to_reservoir)
		gate_blocker.disabled = true
	else:
		city_door.set("prompt_text", "E  检查被堵住的闸门")
		city_door.interacted.connect(_inspect_blocked_gate)
		reservoir_door.visible = false
		reservoir_door.monitoring = false
		(reservoir_door.get_node("CollisionShape2D") as CollisionShape2D).disabled = true
		gate_blocker.disabled = false
	var gate_open := CONNECTION_FLAG in WorldState.achievement_flags
	$SealedGateVisual.visible = not gate_open
	$SealedGateLabel.visible = not gate_open
	$OpenGateLeftPost.visible = gate_open
	$OpenGateRightPost.visible = gate_open
	$OpenGateLabel.visible = gate_open
	_spawn_rat(900.0)
	_spawn_rat(1100.0)
	hud.bind_hero(hero)
	hud.set_story_mode("A1/A3/A4｜旧排水通道", "向下探索；东侧闸门暂时封闭，找到另一侧后再回来。")
	if "old_drain_first_visit_seen" not in WorldState.achievement_flags and not WorldState.debug_map_test_mode:
		WorldState.record_achievement("old_drain_first_visit_seen")
		get_tree().create_timer(0.55).timeout.connect(_show_intro)
func _physics_process(_delta: float) -> void:
	# The drainage shaft has descending ledges but no lethal bottom collider.
	# Recover the Hero if they fall below the playable space, rather than leaving
	# them in an endless FALL/MOVE loop with no way to return.
	if not respawning and is_instance_valid(hero) and hero.global_position.y > 820.0:
		_recover_from_fall()









func _spawn_rat(x: float) -> void:
	var rat := SEWER_RAT_SCENE.instantiate() as CharacterBody2D
	rat.name = "SewerRat_%d" % int(x)
	rat.position = Vector2(x, 690.0)
	add_child(rat)
func _spawn_x_for_side(side: String) -> float:
	match side:
		"city_side_entry":
			return 2110.0
		"reservoir_link":
			return 1510.0
		_:
			return 210.0

func _spawn_y_for_side(side: String) -> float:
	return 540.0 if side == "village_entry" else 690.0

func _return_to_village() -> void:
	WorldState.pending_region_spawn_side = "city_cut_return"
	WorldState.set_location("village")
	SceneTransition.fade_to_scene(VILLAGE_SCENE)

func _inspect_blocked_gate() -> void:
	if narrative:
		narrative.show_message("锈蚀闸门", "闸门后方仍有通道，水声也从更深处传来。\n\n门轴已经被沉积物与铁锈咬死；你暂时找不到能从这一侧开启它的机构。", 4.5)

func _enter_city() -> void:
	if CONNECTION_FLAG not in WorldState.achievement_flags:
		_inspect_blocked_gate()
		return
	WorldState.pending_region_spawn_side = "village_city_cut"
	WorldState.set_location("forgotten_city")
	SceneTransition.fade_to_scene(CITY_SCENE)

func _return_to_reservoir() -> void:
	if CONNECTION_FLAG not in WorldState.achievement_flags:
		return
	WorldState.pending_region_spawn_side = "old_drain_link"
	WorldState.set_location("sewer_reservoir")
	SceneTransition.fade_to_scene(RESERVOIR_SCENE)

func _show_intro() -> void:
	if narrative == null or not is_instance_valid(narrative):
		return
	narrative.show_message("旧排水通道", "入口后的石阶向下延伸。\n\n墙缝里有新鲜的抓痕；更深处传来细碎的奔跑声。\n\n前方塌方封住了去路，但另一侧似乎仍然连着旧城区。", 5.5)

func _on_hero_defeated() -> void:
	if respawning:
		return
	respawning = true
	WorldState.input_locked = true
	INTERACTION_FOCUS_SCRIPT.clear_all(get_tree())
	await get_tree().create_timer(0.75).timeout
	if is_instance_valid(hero):
		hero.velocity = Vector2.ZERO
		hero.global_position = WorldState.checkpoint_position
		if hero.has_method("restore_full"):
			hero.call("restore_full")
	INTERACTION_FOCUS_SCRIPT.clear_all(get_tree())
	WorldState.input_locked = false
	respawning = false


func _recover_from_fall() -> void:
	if respawning:
		return
	respawning = true
	WorldState.input_locked = true
	INTERACTION_FOCUS_SCRIPT.clear_all(get_tree())
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(hero):
		hero.velocity = Vector2.ZERO
		hero.global_position = WorldState.checkpoint_position
		if hero.has_method("restore_full"):
			hero.call("restore_full")
	INTERACTION_FOCUS_SCRIPT.clear_all(get_tree())
	WorldState.input_locked = false
	respawning = false
