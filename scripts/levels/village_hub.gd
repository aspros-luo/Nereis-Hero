extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const NARRATIVE_SCRIPT = preload("res://scripts/core/narrative_manager.gd")
const WORLD_EVENT_DIRECTOR_SCRIPT = preload("res://scripts/core/world_event_director.gd")
const HUD_SCRIPT = preload("res://scripts/ui/game_hud.gd")
const ROUTE_NPC_SCRIPT = preload("res://scripts/npc/route_npc.gd")
const CHECKPOINT_SCRIPT = preload("res://scripts/world/checkpoint.gd")
const REST_POINT_SCRIPT = preload("res://scripts/world/rest_point.gd")
const VILLAGE_POI_SCRIPT = preload("res://scripts/world/village_poi.gd")
const INTERACTION_DOOR_SCRIPT = preload("res://scripts/world/interaction_door.gd")
const VILLAGE_BACKDROP = preload("res://assets/art/backdrops/village_backdrop.svg")
const VILLAGE_GROUND_STRIP = preload("res://assets/art/backdrops/village_ground_strip.svg")
const MITE_SCRIPT = preload("res://scripts/npc/mite.gd")
const NARRATIVE_AUDIO_SCRIPT = preload("res://scripts/audio/narrative_audio.gd")
const FIREFLY_SCRIPT = preload("res://scripts/effects/village_fireflies.gd")
const RESONANCE_SECRET_GATE_SCRIPT = preload("res://scripts/world/resonance_secret_gate.gd")
const CLIFF_CAVE_SCENE := "res://scenes/cliff_cave_experiment.tscn"
@export var floor_y: float = 520.0

var hero: CharacterBody2D
var camera: Camera2D
var narrative: CanvasLayer
var hud: CanvasLayer
var checkpoint: Area2D
var mite: Node2D
var narrative_audio: Node
var mite_house_door: Area2D
var mite_house_transitioning := false
var fireflies: Node2D
var world_event_director: Node
var resonance_well_gate: Node2D
var cliff_cave_door: Area2D

func _ready() -> void:
	WorldState.prepare_scene_runtime()
	var spawn_side := WorldState.pending_region_spawn_side
	# Persist the incoming side before clearing the one-shot transition value.
	# 必须先保存实际进入侧，再清理一次性切图方向，确保 Continue 能恢复正确落点。
	WorldState.set_location("village")
	WorldState.pending_region_spawn_side = "west"
	world_event_director = Node.new()
	world_event_director.set_script(WORLD_EVENT_DIRECTOR_SCRIPT)
	world_event_director.name = "WorldEventDirector"
	world_event_director.setup(WorldState, self)
	add_child(world_event_director)
	print("[NEREIS][VILLAGE] Entered Village Hub route=%s spawn_side=%s" % [WorldState.selected_route, spawn_side])
	WorldState.set_checkpoint(Vector2(360, 520))
	_create_floor()
	_create_village_rooftop_route()
	_create_boundaries()
	# Each village return route uses a safe landing zone clear of unrelated interaction prompts.
	# 村庄各条回程路线使用独立安全落点，避免刚切图就显示无关的 E 交互提示。
	# Spawn after the watergate outside the well gate, tavern, and restoration-camp interaction radii.
	var spawn_x := 1850.0 if spawn_side in ["well_exit", "cliff_cave_return"] else (350.0 if spawn_side == "city_cut_return" else (2310.0 if spawn_side == "north_gate" else (530.0 if spawn_side == "mite_house_return" else 260.0)))
	_spawn_hero(spawn_x)
	_spawn_checkpoint()
	_spawn_village_rest_point()
	_spawn_mite()
	_spawn_mite_house_door()
	_spawn_gatekeeper()
	_spawn_shared_world_npcs()
	_spawn_village_pois()
	_spawn_resonance_well_gate()
	_spawn_cliff_cave_door()
	_spawn_ui()
	_spawn_narrative_audio()
	_spawn_fireflies()
	world_event_director.dispatch("region_entered", {"region": "A1", "location": "village", "spawn_side": spawn_side})
	_spawn_progression_npcs()
	# The newly revealed cave is presented by the changed world geometry and its entrance prompt, not a forced exposition panel.
	queue_redraw()

func _spawn_hero(spawn_x: float = 260.0) -> void:
	hero = CharacterBody2D.new()
	hero.set_script(HERO_SCRIPT)
	hero.position = Vector2(spawn_x, 520)
	hero.name = "Hero"
	_add_character_collision(hero, 18.0, 48.0)
	add_child(hero)

	camera = Camera2D.new()
	camera.name = "HeroCamera"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 2600
	camera.limit_bottom = 720
	camera.position = Vector2.ZERO
	hero.add_child(camera)

func _spawn_village_rest_point() -> void:
	# The village hearth is a safe hub rest point, separate from the checkpoint's spawn marker.
	# 村庄炉火是安全据点的休整点，与单纯记录出生位置的检查点分开。
	var rest := Node2D.new()
	rest.set_script(REST_POINT_SCRIPT)
	rest.name = "VillageHearthRestPoint"
	rest.position = Vector2(620, 520)
	rest.rest_id = "rest_A1_village_hearth"
	rest.display_name = "村庄炉火"
	add_child(rest)


func _spawn_checkpoint() -> void:
	checkpoint = Area2D.new()
	checkpoint.set_script(CHECKPOINT_SCRIPT)
	checkpoint.position = Vector2(360, 520)
	checkpoint.name = "VillageCheckpoint"
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(130, 110)
	shape.shape = rectangle
	shape.position = Vector2(0, -55)
	checkpoint.add_child(shape)
	add_child(checkpoint)

func _spawn_mite() -> void:
	if WorldState.mite_connection_missed:
		var absence := Node2D.new()
		absence.position = Vector2(520, 520)
		absence.name = "MiteAbsence"
		absence.set_script(VILLAGE_POI_SCRIPT)
		absence.poi_id = "mite_absence"
		absence.display_name = "空椅子"
		absence.dialogue = "火堆旁的椅子空着。\n\n桌上留着一只杯子，仍然温热。\n\n这里没有人。"
		add_child(absence)
		absence.interacted.connect(_on_mite_absence_interacted)
		print("[NEREIS][RELATIONSHIP] Mite connection was missed; absence scene spawned")
		return

	mite = Node2D.new()
	mite.set_script(MITE_SCRIPT)
	mite.position = Vector2(800, 520)
	mite.name = "Mite"
	add_child(mite)
	mite.interacted.connect(_on_mite_interacted)
	print("[NEREIS][VILLAGE] Mite present; relationship facts=%d" % WorldState.mite_interactions_seen.size())

func _on_mite_absence_interacted() -> void:
	narrative.show_message("空椅子", "杯子仍然温热。\n\n你确信自己没有把它留在这里。", 5.0)

func _on_mite_interacted(_interaction_id: String, title: String, message: String) -> void:
	narrative.show_message(title, message, 7.0)
	if narrative_audio and narrative_audio.has_method("play_lullaby"):
		narrative_audio.play_lullaby()
	if WorldState.current_location != "village":
		WorldState.current_location = "village"
		WorldState.save_game()

func _spawn_narrative_audio() -> void:
	narrative_audio = Node.new()
	narrative_audio.set_script(NARRATIVE_AUDIO_SCRIPT)
	narrative_audio.name = "NarrativeAudio"
	add_child(narrative_audio)
	# No automatic lullaby on scene entry: the player should discover the sound through an in-world source.

func _spawn_mite_house_door() -> void:
	mite_house_door = Area2D.new()
	mite_house_door.set_script(INTERACTION_DOOR_SCRIPT)
	mite_house_door.position = Vector2(455, 520)
	mite_house_door.name = "MiteHouseDoor"
	mite_house_door.prompt_text = "E  进入"
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(70, 120)
	shape.shape = rectangle
	shape.position = Vector2(0, -60)
	mite_house_door.add_child(shape)
	add_child(mite_house_door)
	mite_house_door.interacted.connect(_enter_mite_house)

func _can_enter_mite_house() -> bool:
	return (
		not mite_house_transitioning
		and not WorldState.input_locked
		and not WorldState.mite_connection_missed
		and WorldState.mite_first_meeting
	)

func _enter_mite_house() -> void:
	if not _can_enter_mite_house():
		return
	mite_house_transitioning = true
	WorldState.set_location("mite_house")
	SceneTransition.fade_to_scene("res://scenes/mite_house.tscn")

func _spawn_fireflies() -> void:
	fireflies = Node2D.new()
	fireflies.set_script(FIREFLY_SCRIPT)
	fireflies.name = "VillageFireflies"
	add_child(fireflies)

func _spawn_gatekeeper() -> void:
	var npc := Node2D.new()
	npc.set_script(ROUTE_NPC_SCRIPT)
	npc.position = Vector2(650, 520)
	npc.interaction_range = 60.0
	npc.npc_id = "village_gatekeeper"
	npc.display_name = "村庄守门人"
	if "village_defense_survived" in WorldState.achievement_flags and WorldState.selected_route == "church":
		npc.dialogue = "守门人看了看你身上的教堂印记，又朝已经恢复通行的北门望去。\n\n“路是重新打开了。但他们说过的话，我还没打算忘。”"
	elif "village_defense_survived" in WorldState.achievement_flags and WorldState.selected_route == "lullaby":
		npc.dialogue = "守门人听见风里传来的旋律，手却没有再去掩酒馆的门。\n\n“北门暂时守住了。那首歌的事，还是别在街上唱。”"
	elif "village_defense_survived" in WorldState.achievement_flags:
		npc.dialogue = "守门人朝北门点了点头，神情仍然疲惫。\n\n“路重新通了。可别把能走过去，当成那边已经安全。”"
	elif WorldState.selected_route == "church":
		npc.dialogue = "守门人看了看你身上的教堂印记，神情变得警惕。\n\n“他们说你不会再回来。现在却又把你送回来了？”"
	elif WorldState.selected_route == "lullaby":
		npc.dialogue = "风里传来一段模糊的摇篮曲，守门人随即把酒馆的门掩上了一半。\n\n“别在这里唱那首歌。除非你想让整座村庄都回想起来。”"
	else:
		npc.dialogue = "守门人打量着你，又看了看北门的方向。\n\n“刚回来？村里有些路白天也不好走。先四处看看，别急着往外闯。”"
	add_child(npc)
	npc.interacted.connect(_on_village_npc_interacted.bind(npc))


func _spawn_shared_world_npcs() -> void:
	# The amnesiac youth was removed from A1. This space now belongs to an ordinary elder.
	# 失忆的年轻人已从 A1 移除；此处改为普通村民老婆婆，不承载主角身世谜题。
	var grandmother := Node2D.new()
	grandmother.set_script(ROUTE_NPC_SCRIPT)
	grandmother.position = Vector2(1120, 520)
	grandmother.interaction_range = 60.0
	grandmother.npc_id = "village_grandmother"
	grandmother.display_name = "老婆婆"
	if "village_defense_survived" in WorldState.achievement_flags:
		grandmother.dialogue = "老婆婆把门边的灯芯拨亮了一些。\n\n“路总算安静了些。人受了惊，得先吃口热的、睡一觉，别急着把自己逼得太紧。”"
	else:
		grandmother.dialogue = "老婆婆坐在屋檐下理着旧布。\n\n“外头风大，进村就先歇歇。村里人各有各的烦心事，别什么都往自己身上揽。”"
	add_child(grandmother)
	grandmother.interacted.connect(_on_village_npc_interacted.bind(grandmother))

	# The blacksmith provides a world-facing service role; full weapon upgrades remain a later system.
	# 铁匠先作为功能型 NPC 接入，不在本次引入制作材料或完整强化循环。
	var blacksmith := Node2D.new()
	blacksmith.set_script(ROUTE_NPC_SCRIPT)
	blacksmith.position = Vector2(1430, 520)
	blacksmith.interaction_range = 65.0
	blacksmith.npc_id = "village_blacksmith"
	blacksmith.display_name = "铁匠"
	if "village_defense_survived" in WorldState.achievement_flags:
		blacksmith.dialogue = "铁匠把锤子搁在砧边，检查着刚换上的门钉。\n\n“北门暂时撑得住。等我把手头这批活做完，再看看你的兵器。”"
	else:
		blacksmith.dialogue = "铁匠正把一块发红的铁料翻了个面。\n\n“想修兵器就先让我看看。至于那扇北门——它比一把钝剑更急着修。”"
	add_child(blacksmith)
	blacksmith.interacted.connect(_on_village_npc_interacted.bind(blacksmith))

	var merchant := Node2D.new()
	merchant.set_script(ROUTE_NPC_SCRIPT)
	merchant.position = Vector2(1250, 520)
	merchant.interaction_range = 60.0
	merchant.npc_id = "traveling_merchant"
	merchant.display_name = "旅行商人"
	if WorldState.get_humanity_state() == "hollow":
		merchant.dialogue = "商人收起了笑容，悄悄把货箱往身边拉近。\n\n“今天先不谈价。你看起来比路上的风雨更难应付。”"
	elif "village_defense_survived" in WorldState.achievement_flags:
		merchant.dialogue = "商人重新整理着货物。\n\n“北门恢复通行后，来往的人会多起来。真要买东西，先想清楚下一段路缺什么。”"
	else:
		merchant.dialogue = "商人把银币在指间转了一圈，打量着你的行囊。\n\n“我从外面来，也会往外面去。要问路况可以，传闻就得自己掂量。”"
	add_child(merchant)
	merchant.interacted.connect(_on_village_npc_interacted.bind(merchant))


func _spawn_progression_npcs() -> void:
	# Progression-only NPCs are registered in world_event_director.gd; baseline villagers stay above.
	# 进度专属 NPC 在 world_event_director.gd 注册；常驻村民仍由上方基础生成逻辑负责。
	if world_event_director == null:
		return
	world_event_director.spawn_npcs(self, ROUTE_NPC_SCRIPT, Callable(self, "_on_village_npc_interacted"))

func refresh_progression_content() -> void:
	# Call after any quest/item/region fact changes while the Hero remains in A1.
	# 主角仍在 A1 时若任务、物品或区域事实发生变化，应调用此入口刷新进度内容。
	if world_event_director == null:
		return
	world_event_director.dispatch("state_refresh", {"region": "A1", "location": "village"})
	_spawn_progression_npcs()

func _on_village_npc_interacted(npc: Node) -> void:
	if narrative == null or not is_instance_valid(npc):
		return
	narrative.show_message(npc.display_name, npc.dialogue, 6.0)
	await narrative.message_finished
	if world_event_director != null:
		world_event_director.dispatch("interaction", {"region": "A1", "interaction_id": String(npc.npc_id), "npc_id": String(npc.npc_id)})
		refresh_progression_content()

func _spawn_village_pois() -> void:
	var tavern := Node2D.new()
	tavern.set_script(VILLAGE_POI_SCRIPT)
	tavern.position = Vector2(1730, 520)
	tavern.interaction_range = 80.0
	tavern.poi_id = "tavern"
	tavern.display_name = "酒馆"
	tavern.dialogue = "酒馆的门在你掌下发暖。\n\n你短暂地听见里面传来摇篮曲；当你碰到门把时，歌声却停了。"
	add_child(tavern)
	tavern.interacted.connect(_on_village_poi_interacted.bind(tavern))

	var graveyard := Node2D.new()
	graveyard.set_script(VILLAGE_POI_SCRIPT)
	graveyard.position = Vector2(950, 520)
	graveyard.interaction_range = 80.0
	graveyard.poi_id = "graveyard"
	graveyard.display_name = "村庄墓地"
	graveyard.dialogue = "墓园的大门敞开着。\n\n钟塔多年未曾鸣响，但当你呼唤时，里面仍有某种东西回应。"
	add_child(graveyard)
	graveyard.interacted.connect(_on_village_poi_interacted.bind(graveyard))

	# The Restoration Army is a later story arrival, not part of the first village visit.
	# 复国军是后续剧情阶段才进入村庄的势力，初次到达 A1 时不生成营地。
	if "restoration_camp_established" in WorldState.achievement_flags:
		var rebel_camp := Node2D.new()
		rebel_camp.set_script(VILLAGE_POI_SCRIPT)
		rebel_camp.position = Vector2(1990, 520)
		rebel_camp.interaction_range = 70.0
		rebel_camp.poi_id = "rebel_camp"
		rebel_camp.display_name = "复国军营地"
		rebel_camp.dialogue = "营地已经扎稳。有人整理装备，有人低声讨论接下来的道路。\n\n这里不再是临时停留的地方。"
		add_child(rebel_camp)
		rebel_camp.interacted.connect(_on_village_poi_interacted.bind(rebel_camp))

	var north_gate := Node2D.new()
	north_gate.set_script(VILLAGE_POI_SCRIPT)
	north_gate.position = Vector2(2440, 520)
	north_gate.interaction_range = 80.0
	north_gate.poi_id = "north_gate"
	# P5.1 runtime contract for the north route.
	north_gate.set_meta("p5_1_exit_contract", true)
	north_gate.set_meta("p5_1_target_location", "ash_forest")
	north_gate.set_meta("p5_1_target_region", "A2")
	north_gate.set_meta("p5_1_target_scene", "res://scenes/ash_forest.tscn")
	north_gate.set_meta("p5_1_spawn_side", "west")
	var old_pilgrim_road_open := "village_defense_survived" in WorldState.achievement_flags
	north_gate.display_name = "旧朝圣路" if old_pilgrim_road_open else "北门"
	if old_pilgrim_road_open:
		north_gate.dialogue = "大门已经修复，门后的旧路仍然存在。\n\n石头从森林深处传来钟声。"
	else:
		north_gate.dialogue = "新鲜的斧痕划伤了大门。\n\n门外的道路安静得反常。\n\n远处传来金属碰撞声。"
	add_child(north_gate)
	north_gate.interacted.connect(_on_village_poi_interacted.bind(north_gate))

	# A second, lower route reaches the forgotten city without forcing every player through the forest first.
	# 第二条低处通路可直达遗忘之城，避免所有玩家都必须先穿过森林。
	var city_cut := Node2D.new()
	city_cut.set_script(VILLAGE_POI_SCRIPT)
	city_cut.position = Vector2(100, 520)
	city_cut.interaction_range = 75.0
	city_cut.poi_id = "city_cut"
	# P5.1 runtime contract for the post-defense shortcut.
	city_cut.set_meta("p5_1_exit_contract", true)
	city_cut.set_meta("p5_1_target_location", "forgotten_city")
	city_cut.set_meta("p5_1_target_region", "A3")
	city_cut.set_meta("p5_1_target_scene", "res://scenes/forgotten_city.tscn")
	city_cut.set_meta("p5_1_spawn_side", "village_city_cut")
	var city_cut_open := "village_defense_survived" in WorldState.achievement_flags
	city_cut.display_name = "旧排水通道" if city_cut_open else "封闭的排水通道"
	if city_cut_open:
		city_cut.dialogue = "旧排水道从城墙下穿过，其石构甚至早于村庄的房屋。\n\n一条狭窄通路通向被遗忘的街道。"
	else:
		city_cut.dialogue = "倒塌的横梁与新鲜碎石封住了通道。有人最近才堵上这里。\n\n裂缝另一侧的石头比村庄古老得多。"
	add_child(city_cut)
	city_cut.interacted.connect(_on_village_poi_interacted.bind(city_cut))

	var church := Node2D.new()
	church.set_script(VILLAGE_POI_SCRIPT)
	# Keep a clear landing corridor between the church and north-gate interaction zones.
	# 教堂交互点与北门之间保留无交互提示的回程落脚区。
	church.position = Vector2(2180, 520)
	church.interaction_range = 60.0
	church.poi_id = "church"
	church.display_name = "教堂"
	church.dialogue = "教堂的大门没有上锁。里面空荡而安静，只有旧木椅与未燃尽的蜡烛。\n\n暂时没有人回应你的脚步声。"
	add_child(church)
	church.interacted.connect(_on_village_poi_interacted.bind(church))

func _on_village_poi_interacted(poi: Node) -> void:
	narrative.show_message(poi.display_name, poi.dialogue, 2.5)
	await narrative.message_finished
	if world_event_director != null:
		world_event_director.dispatch("interaction", {"region": "A1", "interaction_id": String(poi.poi_id), "poi": poi})
		refresh_progression_content()
	_enter_village_location(poi.poi_id)

func _spawn_resonance_well_gate() -> void:
	resonance_well_gate = Node2D.new()
	resonance_well_gate.set_script(RESONANCE_SECRET_GATE_SCRIPT)
	resonance_well_gate.position = Vector2(1555, 520)
	resonance_well_gate.name = "ResonanceWellGate"
	resonance_well_gate.secret_id = "H01"
	resonance_well_gate.target_scene_path = "res://scenes/hidden_well.tscn"
	resonance_well_gate.target_location_id = "hidden_well"
	resonance_well_gate.required_resonance = 12
	resonance_well_gate.required_ancient_exposure = 0
	resonance_well_gate.required_outer_exposure = 0
	resonance_well_gate.opened.connect(_on_resonance_well_opened)
	add_child(resonance_well_gate)

func _spawn_cliff_cave_door() -> void:
	# This entrance only appears after the Hero defeats the mad cleric and physically returns to the village.
	# 只有击败疯狂神职人员并实际返回村庄后，崖下洞窟入口才会出现。
	if "returned_to_village_after_mad_cleric" not in WorldState.achievement_flags:
		return
	cliff_cave_door = Area2D.new()
	cliff_cave_door.set_script(INTERACTION_DOOR_SCRIPT)
	cliff_cave_door.name = "CliffCaveExperimentDoor"
	cliff_cave_door.position = Vector2(2260.0, 390.0)
	cliff_cave_door.prompt_text = "E  进入蜂巢后的洞穴"
	cliff_cave_door.set_meta("interaction_priority", 95)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(100.0, 138.0)
	shape.shape = rectangle
	shape.position = Vector2(0.0, -69.0)
	cliff_cave_door.add_child(shape)
	add_child(cliff_cave_door)
	cliff_cave_door.interacted.connect(_on_cliff_cave_interacted)



func _on_cliff_cave_interacted() -> void:
	WorldState.discover_hidden_region("H09")
	WorldState.open_hidden_path("H09")
	WorldState.mark_hidden_region_entered("H09")
	WorldState.pending_region_spawn_side = "west"
	WorldState.set_location("cliff_cave_experiment")
	print("[NEREIS][SECRET] Entering H09: cliff cave experiment site")
	SceneTransition.fade_to_scene(CLIFF_CAVE_SCENE)


func _on_resonance_well_opened(secret_id: String) -> void:
	if narrative == null or not is_instance_valid(narrative):
		return
	narrative.show_message(
		"THE WELL THAT WAS ALREADY THERE",
		"The stones slide inward without a sound.\n\nA stair descends where the water should be.\n\nThe opening will remain.",
		4.5
	)

func _enter_village_location(location_id: String) -> void:
	if location_id == "tavern":
		WorldState.set_location("tavern")
		print("[NEREIS][VILLAGE] Entering Tavern Interior")
		SceneTransition.fade_to_scene("res://scenes/locations/tavern_interior.tscn")
	elif location_id == "church":
		# Entering the church is exploration, not an irreversible relationship choice.
		# The player may still return to Mite after visiting this location.
		WorldState.set_location("church")
		print("[NEREIS][VILLAGE] Entering Church Interior")
		SceneTransition.fade_to_scene("res://scenes/locations/church_interior.tscn")
	elif location_id == "rebel_camp":
		WorldState.set_location("rebel_camp")
		print("[NEREIS][VILLAGE] Entering Restoration Camp")
		SceneTransition.fade_to_scene("res://scenes/rebel_camp.tscn")
	elif location_id == "north_gate":
		if "village_defense_survived" in WorldState.achievement_flags:
			WorldState.pending_region_spawn_side = "west"
			WorldState.set_location("ash_forest")
			print("[NEREIS][MAP] Entering A2: Old Pilgrim Road")
			SceneTransition.fade_to_scene("res://scenes/ash_forest.tscn")
		else:
			WorldState.set_location("village")
			print("[NEREIS][VILLAGE] Triggering village defense chapter")
			SceneTransition.fade_to_scene("res://scenes/village_defense_demo.tscn")
	elif location_id == "city_cut":
		if "village_defense_survived" in WorldState.achievement_flags:
			WorldState.pending_region_spawn_side = "village_city_cut"
			WorldState.set_location("forgotten_city")
			print("[NEREIS][MAP] Entering A3: Forgotten City via the old drainage passage")
			SceneTransition.fade_to_scene("res://scenes/forgotten_city.tscn")
		else:
			print("[NEREIS][MAP] Old drainage passage remains sealed until the village attack is survived")
	elif location_id == "graveyard":
		WorldState.set_location("graveyard")
		print("[NEREIS][VILLAGE] Entering Village Graveyard")
		SceneTransition.fade_to_scene("res://scenes/village_graveyard.tscn")

func _spawn_ui() -> void:
	narrative = CanvasLayer.new()
	narrative.set_script(NARRATIVE_SCRIPT)
	add_child(narrative)

	hud = CanvasLayer.new()
	hud.set_script(HUD_SCRIPT)
	add_child(hud)
	hud.bind_hero(hero)
	hud.set_story_mode("A1｜边境村庄", "自由探索村庄；按 E 与附近的人物和可调查物件互动。")

func _create_floor() -> void:
	var floor := StaticBody2D.new()
	floor.name = "Ground"
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(2600, 40)
	shape.shape = rectangle
	shape.position = Vector2(1300, 540)
	floor.add_child(shape)
	add_child(floor)

func _create_village_rooftop_route() -> void:
	# Optional rooftop route: each short ledge is within ordinary jump reach of the previous one.
	# 可选屋顶路线：相邻短平台保持在常规跳跃可达范围内。
	var route := [
		Rect2(220, 445, 90, 16),
		Rect2(270, 400, 90, 16),
		Rect2(320, 355, 100, 16),
		Rect2(400, 340, 130, 16),
		Rect2(600, 340, 110, 16),
		Rect2(750, 380, 110, 16),
		Rect2(900, 340, 110, 16),
		Rect2(1040, 385, 110, 16),
		Rect2(1160, 340, 110, 16),
		Rect2(1300, 300, 110, 16),
		Rect2(1430, 340, 110, 16),
		Rect2(1580, 300, 110, 16),
		Rect2(1710, 270, 110, 16),
		Rect2(1840, 310, 110, 16),
		Rect2(1980, 350, 110, 16),
		Rect2(2110, 310, 110, 16),
		Rect2(2240, 340, 110, 16)
	]
	for platform_rect in route:
		var body := StaticBody2D.new()
		body.name = "VillageRooftopPlatform"
		body.position = platform_rect.position
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = platform_rect.size
		shape.shape = rectangle
		shape.position = platform_rect.size * 0.5
		# One-way rooftop ledges preserve the optional high route without blocking jumps from below.
		# 单向屋顶平台保留高路探索，同时避免从下方跳跃时被平台侧面卡住。
		shape.one_way_collision = true
		body.add_child(shape)
		add_child(body)


func _create_boundaries() -> void:
	var left := StaticBody2D.new()
	var left_shape := CollisionShape2D.new()
	var left_rect := RectangleShape2D.new()
	left_rect.size = Vector2(40, 720)
	left_shape.shape = left_rect
	left_shape.position = Vector2(-20, 360)
	left.add_child(left_shape)
	add_child(left)

	var right := StaticBody2D.new()
	var right_shape := CollisionShape2D.new()
	var right_rect := RectangleShape2D.new()
	right_rect.size = Vector2(40, 720)
	right_shape.shape = right_rect
	right_shape.position = Vector2(2620, 360)
	right.add_child(right_shape)
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
	if event is InputEventKey and event.pressed and not event.echo:
		if WorldState.debug_map_test_mode and event.keycode == KEY_F6:
			_mark_input_handled()
			get_tree().change_scene_to_file("res://scenes/world_map_test_menu.tscn")
			return
		if event.keycode == KEY_F1:
			var endgame_scene := NereisEndingEvaluator.get_candidate()
			print("[NEREIS][DEBUG] Candidate endgame=%s" % endgame_scene)
			_mark_input_handled()
			match endgame_scene:
				"烈火天罚":
					get_tree().change_scene_to_file("res://scenes/ending_fire_demo.tscn")
				"永恒乐园":
					get_tree().change_scene_to_file("res://scenes/ending_paradise_demo.tscn")
				_:
					get_tree().change_scene_to_file("res://scenes/church_final_demo.tscn")
		elif event.keycode == KEY_F2:
			_mark_input_handled()
			print("[NEREIS][DEBUG] Opening Eternal Paradise theater")
			get_tree().change_scene_to_file("res://scenes/ending_paradise_demo.tscn")
		elif event.keycode == KEY_F4:
			_mark_input_handled()
			print("[NEREIS][DEBUG] Opening ancient research theater")
			get_tree().change_scene_to_file("res://scenes/ancient_research_lab.tscn")
		elif event.keycode == KEY_F5:
			_mark_input_handled()
			print("[NEREIS][DEBUG] Opening village defense theater")
			get_tree().change_scene_to_file("res://scenes/village_defense_demo.tscn")
		elif event.keycode == KEY_F8:
			_mark_input_handled()
			print("[NEREIS][DEBUG] Opening director ending theater")
			get_tree().change_scene_to_file("res://scenes/ending_fire_demo.tscn")
		elif event.keycode == KEY_F7:
			_mark_input_handled()
			print("[NEREIS][DEBUG] Opening church final boss theater")
			get_tree().change_scene_to_file("res://scenes/church_final_demo.tscn")
		elif event.keycode == KEY_F6:
			_mark_input_handled()
			print("[NEREIS][DEBUG] Opening Mite resonance theater")
			get_tree().change_scene_to_file("res://scenes/mite_resonance_demo.tscn")
		elif event.keycode == KEY_F9:
			_mark_input_handled()
			WorldState.delete_save()
			print("[NEREIS][DEBUG] Village run reset")
			get_tree().change_scene_to_file("res://scenes/escape_prologue.tscn")

func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

func _draw() -> void:
	draw_texture_rect(VILLAGE_BACKDROP, Rect2(0, 0, 2600, 720), false)
	draw_texture_rect(VILLAGE_GROUND_STRIP, Rect2(0, 520, 2600, 200), false)
	for x in range(0, 2600, 64):
		draw_line(Vector2(x, 520), Vector2(x + 32, 552), Color("#302a30"), 2.0)

	draw_string(ThemeDB.fallback_font, Vector2(100, 230), NereisLocalization.translate_text("边境村庄"), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("#4d454d"))

	# The western drain is a visible alternate route; rubble remains until the village defense is survived.
	# 西侧排水通路作为可见的替代路线；村庄防卫战完成前仍由碎石封住。
	var drain_open := "village_defense_survived" in WorldState.achievement_flags
	draw_rect(Rect2(18, 420, 96, 100), Color("#25232b"))
	draw_rect(Rect2(32, 438, 68, 82), Color("#11141a"))
	draw_arc(Vector2(66, 440), 34.0, PI, TAU, 20, Color("#5d5964"), 6.0)
	if not drain_open:
		draw_rect(Rect2(24, 425, 84, 88), Color("#514149"))
		for rubble_x in [34, 55, 77, 94]:
			draw_line(Vector2(rubble_x, 435), Vector2(rubble_x - 5, 500), Color("#79656a"), 5.0)
	draw_string(ThemeDB.fallback_font, Vector2(20, 400), "旧排水道", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8d7776"))

	# Small house where the Hero first recovers.
	draw_rect(Rect2(350, 360, 210, 160), Color("#27222b"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(325, 360),
			Vector2(455, 245),
			Vector2(585, 360)
		]),
		Color("#302832")
	)
	draw_rect(Rect2(430, 430, 50, 90), Color("#17141b"))
	draw_string(ThemeDB.fallback_font, Vector2(388, 332), NereisLocalization.translate_text("蜜忒的家"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#8d7776"))

	# A low hearth marks the safe hub and the point where survivors gather.
	# 低矮炉火标记安全据点，也是村民聚集的地方。
	draw_rect(Rect2(590, 492, 62, 28), Color("#3a2d35"))
	draw_circle(Vector2(620, 492), 11.0, Color("#a85e45"))
	draw_circle(Vector2(620, 487), 6.0, Color("#d49b68"))
	draw_string(ThemeDB.fallback_font, Vector2(584, 475), "炉火", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#8d7776"))

	# Leave the western edge open for the old drainage passage; houses begin beyond its arch.
	# 西侧为旧排水通路保留空间，民居从拱门以东开始排列。
	for x in range(600, 2300, 480):
		draw_rect(Rect2(x - 90, 360, 180, 160), Color("#29232b"))
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(x - 110, 360),
				Vector2(x, 260),
				Vector2(x + 110, 360)
			]),
			Color("#352d38")
		)
		draw_rect(Rect2(x - 12, 440, 24, 80), Color("#17141b"))
		draw_circle(Vector2(x - 42, 430), 8, Color("#8e7777"))
		draw_circle(Vector2(x + 42, 430), 8, Color("#66545c"))

	draw_rect(Rect2(1580, 300, 300, 220), Color("#2d2630"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(1530, 300),
			Vector2(1730, 190),
			Vector2(1930, 300)
		]),
		Color("#3a303a")
	)
	draw_rect(Rect2(1690, 400, 80, 120), Color("#17141b"))
	draw_string(ThemeDB.fallback_font, Vector2(1630, 275), NereisLocalization.translate_text("酒馆"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d6c7b2"))

	draw_rect(Rect2(900, 390, 120, 130), Color("#28212a"))
	draw_string(ThemeDB.fallback_font, Vector2(885, 365), NereisLocalization.translate_text("墓地"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#796d67"))

	# Give the blacksmith a readable workshop silhouette instead of leaving the role as a floating label.
	# 为铁匠铺提供明确的灰盒轮廓，避免功能角色看起来只是站在路边的普通 NPC。
	draw_rect(Rect2(1350, 385, 150, 135), Color("#29232a"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(1335, 385),
			Vector2(1425, 315),
			Vector2(1515, 385)
		]),
		Color("#3a3036")
	)
	draw_rect(Rect2(1370, 425, 30, 95), Color("#17141b"))
	draw_rect(Rect2(1440, 445, 35, 20), Color("#4c3a3b"))
	draw_circle(Vector2(1457, 443), 12.0, Color("#a85e45"))
	draw_circle(Vector2(1457, 443), 6.0, Color("#d49b68"))
	draw_string(ThemeDB.fallback_font, Vector2(1370, 365), NereisLocalization.translate_text("铁匠铺"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#b7a09b"))

	# Hide the camp's distinctive fire and label until the later story-arrival flag is set.
	# 初期只保留普通建筑轮廓；复国军的营火与营地标识必须等剧情节点后才出现。
	if "restoration_camp_established" in WorldState.achievement_flags:
		draw_rect(Rect2(1940, 360, 150, 160), Color("#27212a"))
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(1915, 360),
				Vector2(2015, 270),
				Vector2(2115, 360)
			]),
			Color("#312934")
		)
		draw_circle(Vector2(2015, 455), 34.0, Color("#63322f"))
		draw_string(ThemeDB.fallback_font, Vector2(1900, 335), NereisLocalization.translate_text("复国军营地"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#8d7776"))

	draw_rect(Rect2(2380, 330, 120, 190), Color("#241e27"))
	draw_rect(Rect2(2410, 350, 18, 170), Color("#4a3439"))
	draw_rect(Rect2(2460, 350, 18, 170), Color("#4a3439"))
	if "village_defense_survived" in WorldState.achievement_flags:
		# The gate is visibly passable after the defense; keep the opening readable from the hub.
		draw_line(Vector2(2418, 360), Vector2(2394, 405), Color("#79656a"), 6.0)
		draw_line(Vector2(2468, 360), Vector2(2490, 405), Color("#79656a"), 6.0)
	else:
		# Before the defense, crossbars communicate that the route is physically blocked.
		draw_rect(Rect2(2418, 385, 50, 12), Color("#79656a"))
		draw_rect(Rect2(2418, 430, 50, 12), Color("#79656a"))
	draw_string(ThemeDB.fallback_font, Vector2(2370, 310), NereisLocalization.translate_text("北门"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#796d67"))

	# Broken roof beams mark an optional high route across the village; they are not a required path.
	# 断裂屋脊标记穿越村庄的可选高路，不是主线必经路线。
	draw_line(Vector2(220, 445), Vector2(310, 400), Color("#514652"), 3.0)
	draw_line(Vector2(310, 400), Vector2(420, 355), Color("#514652"), 3.0)
	draw_line(Vector2(420, 355), Vector2(600, 350), Color("#514652"), 3.0)
	draw_line(Vector2(600, 350), Vector2(750, 390), Color("#514652"), 3.0)
	draw_line(Vector2(750, 390), Vector2(900, 350), Color("#514652"), 3.0)
	draw_line(Vector2(900, 350), Vector2(1040, 395), Color("#514652"), 3.0)
	draw_line(Vector2(1040, 395), Vector2(1160, 350), Color("#514652"), 3.0)
	draw_line(Vector2(1160, 350), Vector2(1300, 310), Color("#514652"), 3.0)
	draw_line(Vector2(1300, 310), Vector2(1430, 350), Color("#514652"), 3.0)
	draw_line(Vector2(1580, 310), Vector2(1710, 280), Color("#514652"), 3.0)
	draw_line(Vector2(1710, 280), Vector2(1840, 320), Color("#514652"), 3.0)
	draw_line(Vector2(1840, 320), Vector2(1980, 360), Color("#514652"), 3.0)
	draw_line(Vector2(1980, 360), Vector2(2110, 320), Color("#514652"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(1060, 285), "屋顶捷径", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#796b7c"))

	draw_rect(Rect2(2180, 320, 80, 200), Color("#26202a"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(2150, 320),
			Vector2(2220, 220),
			Vector2(2290, 320)
		]),
		Color("#312934")
	)
	draw_string(ThemeDB.fallback_font, Vector2(2135, 200), NereisLocalization.translate_text("教会"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#796d67"))

	# New art pass: broken stonework, amber window-light, and low fog separate the safe village from the old wall.
	# 美术细化：破损石构、琥珀窗光与贴地薄雾，区分安全村庄与古老城墙。
	for crack_x in [680.0, 1015.0, 1460.0, 1870.0, 2075.0]:
		draw_line(Vector2(crack_x, 516), Vector2(crack_x + 18, 508), Color("#4a3b47"), 2.0)
		draw_line(Vector2(crack_x + 18, 508), Vector2(crack_x + 29, 519), Color("#4a3b47"), 1.5)
	for window_x in [650.0, 1120.0, 1490.0, 1800.0, 2040.0]:
		draw_rect(Rect2(window_x, 390, 18, 30), Color("#17141b"))
		draw_rect(Rect2(window_x + 4, 395, 10, 20), Color("#9b7157", 0.72))
		draw_line(Vector2(window_x + 9, 394), Vector2(window_x + 9, 416), Color("#3e2b31"), 2.0)
	for fog_index in range(5):
		var fog_x := 240.0 + float(fog_index) * 510.0
		draw_arc(Vector2(fog_x, 498.0), 118.0, PI + 0.2, TAU - 0.2, 28, Color("#777080", 0.10), 9.0)
		draw_arc(Vector2(fog_x + 55.0, 506.0), 72.0, PI + 0.4, TAU - 0.4, 20, Color("#b5a1b2", 0.07), 6.0)

	# The cliff hive is a story-state landmark: sealed before the return, a sickly-lit cave afterward.
	# 山崖蜂巢是剧情状态地标：回访前被蜂巢封住，满足条件后才显露幽暗洞口。
	draw_colored_polygon(PackedVector2Array([
		Vector2(2190, 520), Vector2(2205, 445), Vector2(2240, 408),
		Vector2(2280, 422), Vector2(2315, 460), Vector2(2340, 520)
	]), Color("#39313c"))
	var cave_open := "returned_to_village_after_mad_cleric" in WorldState.achievement_flags
	if cave_open:
		draw_arc(Vector2(2260, 455), 39.0, PI, TAU, 28, Color("#a77c91"), 5.0)
		draw_rect(Rect2(2233, 450, 54, 70), Color("#100f18"))
		draw_arc(Vector2(2260, 454), 28.0, PI, TAU, 22, Color("#6f91a0", 0.42), 8.0)
		draw_circle(Vector2(2260, 485), 7.0, Color("#91a9b4", 0.42))
		draw_string(ThemeDB.fallback_font, Vector2(2190, 392), "蜂群退入石壁", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#a5a1b9"))
	else:
		draw_colored_polygon(PackedVector2Array([
			Vector2(2220, 458), Vector2(2234, 435), Vector2(2250, 449),
			Vector2(2262, 428), Vector2(2280, 445), Vector2(2294, 465),
			Vector2(2275, 483), Vector2(2245, 482)
		]), Color("#5d4b3a"))
		for bee_index in range(9):
			var bee_x := 2220.0 + float((bee_index * 17) % 70)
			var bee_y := 425.0 + float((bee_index * 23) % 56)
			draw_circle(Vector2(bee_x, bee_y), 2.5, Color("#c4a16b", 0.85))
		draw_string(ThemeDB.fallback_font, Vector2(2180, 392), "蜂巢封住了旧石缝", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#9d8b7d"))
		if OS.is_debug_build():
			draw_line(Vector2(2260, 408), Vector2(2260, 300), Color("#ed8796"), 3.0, true)
			draw_string(ThemeDB.fallback_font, Vector2(2110, 286), "[条件未满足] 崖下实验窟：击败疯狂神职人员并返回村庄", HORIZONTAL_ALIGNMENT_LEFT, 460.0, 13, Color("#ed8796"))
