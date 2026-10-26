extends Node2D

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
	# The cliff-cave entrance is a return consequence, not a boss-defeat reward popup.
	# 只有击败疯狂神职人员后实际重新进入 A1，才持久记录“已回村”事实。
	if "defeated_mad_cleric" in WorldState.achievement_flags:
		if WorldState.record_achievement("returned_to_village_after_mad_cleric"):
			WorldState.save_game()
	WorldState.pending_region_spawn_side = "west"
	world_event_director = $WorldEventDirector
	world_event_director.setup(WorldState, self)
	print("[NEREIS][VILLAGE] Entered Village Hub route=%s spawn_side=%s" % [WorldState.selected_route, spawn_side])
	WorldState.set_checkpoint(Vector2(360, 520))
	# Each village return route uses a safe landing zone clear of unrelated interaction prompts.
	# 村庄各条回程路线使用独立安全落点，避免刚切图就显示无关的 E 交互提示。
	# Spawn after the watergate outside the well gate, tavern, and restoration-camp interaction radii.
	var spawn_x := 2420.0 if spawn_side == "backhill_return" else (1850.0 if spawn_side in ["well_exit", "cliff_cave_return"] else (350.0 if spawn_side == "city_cut_return" else (2630.0 if spawn_side == "north_gate" else (530.0 if spawn_side == "mite_house_return" else 260.0))))
	hero = $Hero
	camera = $Hero/HeroCamera
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 3000
	camera.limit_bottom = 720
	hero.position = Vector2(spawn_x, floor_y)
	checkpoint = $VillageCheckpoint
	mite = $Mite
	mite_house_door = $MiteHouseDoor
	_configure_static_village_nodes()
	_configure_baseline_npcs()
	$BackhillEntrance.interacted.connect(_on_village_poi_interacted.bind($BackhillEntrance))
	narrative = $Narrative
	hud = $HUD
	hud.bind_hero(hero)
	hud.set_story_mode("A1｜边境村庄", "自由探索村庄；按 E 与附近的人物和可调查物件互动。")
	narrative_audio = $NarrativeAudio
	fireflies = $VillageFireflies
	world_event_director.dispatch("region_entered", {"region": "A1", "location": "village", "spawn_side": spawn_side})
	_spawn_progression_npcs()
	# The newly revealed cave is presented by the changed world geometry and its entrance prompt, not a forced exposition panel.
	_refresh_world_visual_states()

func _configure_static_village_nodes() -> void:
	var mite_missed := WorldState.mite_connection_missed
	$Mite.visible = not mite_missed
	$Mite.process_mode = Node.PROCESS_MODE_DISABLED if mite_missed else Node.PROCESS_MODE_INHERIT
	$MiteAbsence.visible = mite_missed
	$MiteAbsence.process_mode = Node.PROCESS_MODE_INHERIT if mite_missed else Node.PROCESS_MODE_DISABLED
	if mite_missed:
		$MiteAbsence.interacted.connect(_on_mite_absence_interacted)
	else:
		$Mite.interacted.connect(_on_mite_interacted)
	$MiteHouseDoor.interacted.connect(_enter_mite_house)

	var graveyard: Node2D = $GraveyardPOI
	graveyard.dialogue = "墓园的大门敞开着。\n\n钟塔多年未曾鸣响，但当你呼唤时，里面仍有某种东西回应。"
	graveyard.interacted.connect(_on_village_poi_interacted.bind(graveyard))
	var camp: Node2D = $RestorationCampPOI
	camp.dialogue = "营地已经扎稳。有人整理装备，有人低声讨论接下来的道路。\n\n这里不再是临时停留的地方。"
	camp.interacted.connect(_on_village_poi_interacted.bind(camp))
	var north_gate: Node2D = $NorthGatePOI
	north_gate.set_meta("p5_1_exit_contract", true)
	north_gate.set_meta("p5_1_target_location", "ash_forest")
	north_gate.set_meta("p5_1_target_region", "A2")
	north_gate.set_meta("p5_1_target_scene", "res://scenes/rooms/a2_fog_forest/runtime/a2_r01_room.tscn")
	north_gate.set_meta("p5_1_spawn_side", "west")
	north_gate.interacted.connect(_on_village_poi_interacted.bind(north_gate))
	var city_cut: Node2D = $CityCutPOI
	city_cut.set_meta("p5_1_exit_contract", true)
	city_cut.set_meta("p5_1_target_location", "old_drain_exploration")
	city_cut.set_meta("p5_1_target_region", "A1")
	city_cut.set_meta("p5_1_target_scene", "res://scenes/old_drain_exploration.tscn")
	city_cut.set_meta("p5_1_spawn_side", "village_entry")
	city_cut.interacted.connect(_on_village_poi_interacted.bind(city_cut))
	resonance_well_gate = $ResonanceWellGate
	resonance_well_gate.secret_id = "H01"
	resonance_well_gate.target_scene_path = "res://scenes/hidden_well.tscn"
	resonance_well_gate.target_location_id = "hidden_well"
	resonance_well_gate.required_resonance = 12
	resonance_well_gate.required_ancient_exposure = 0
	resonance_well_gate.required_outer_exposure = 0
	resonance_well_gate.opened.connect(_on_resonance_well_opened)
	for label_path in ["RegionTitle", "DrainLabel", "GraveyardLabel", "OldHouseLabel", "CampLabel", "NorthGateLabel"]:
		var label: Label = get_node(label_path)
		label.text = NereisLocalization.translate_text(label.text)
	_refresh_world_visual_states()


func _refresh_world_visual_states() -> void:
	var defense_survived := "village_defense_survived" in WorldState.achievement_flags
	var camp_established := "restoration_camp_established" in WorldState.achievement_flags
	$DrainEntranceVisual/RubbleState.visible = not defense_survived
	$NorthGateVisual/BlockedState.visible = not defense_survived
	$NorthGateVisual/RepairedState.visible = defense_survived
	$CampVisual.visible = camp_established
	$CampLabel.visible = camp_established
	$RestorationCampPOI.visible = camp_established
	$RestorationCampPOI.process_mode = Node.PROCESS_MODE_INHERIT if camp_established else Node.PROCESS_MODE_DISABLED
	var north_gate: Node2D = $NorthGatePOI
	north_gate.display_name = "旧朝圣路" if defense_survived else "北门"
	north_gate.dialogue = "大门已经修复，门后的旧路仍然存在。\n\n石头从森林深处传来钟声。" if defense_survived else "新鲜的斧痕划伤了大门。\n\n门外的道路安静得反常。\n\n远处传来金属碰撞声。"
	$NorthGateLabel.text = NereisLocalization.translate_text(north_gate.display_name)
	var city_cut: Node2D = $CityCutPOI
	city_cut.display_name = "旧排水通道" if defense_survived else "封闭的排水通道"
	city_cut.dialogue = "旧排水道从城墙下方延伸。\n\n石阶通向更深处，远处似乎有水声；但里面的闸门看起来早已锈死。" if defense_survived else "倒塌的横梁与新鲜碎石封住了通道。有人最近才堵上这里。\n\n裂缝另一侧的石头比村庄古老得多。"


func _configure_baseline_npcs() -> void:
	for node_name in ["Gatekeeper", "Grandmother", "BlacksmithNPC", "TravelingMerchant"]:
		var npc: Node = get_node(node_name)
		_refresh_baseline_npc_dialogue(npc)
		npc.interacted.connect(_on_village_npc_interacted.bind(npc))


func _on_mite_absence_interacted() -> void:
	narrative.show_message("空椅子", "杯子仍然温热。\n\n你确信自己没有把它留在这里。", 5.0)


func _on_mite_interacted(_interaction_id: String, title: String, message: String) -> void:
	narrative.show_message(title, message, 7.0)
	if narrative_audio and narrative_audio.has_method("play_lullaby"):
		narrative_audio.play_lullaby()
	if WorldState.current_location != "village":
		WorldState.current_location = "village"
		WorldState.save_game()


func _can_enter_mite_house() -> bool:
	return not mite_house_transitioning and not WorldState.input_locked and not WorldState.mite_connection_missed and WorldState.mite_first_meeting


func _enter_mite_house() -> void:
	if not _can_enter_mite_house():
		return
	mite_house_transitioning = true
	WorldState.set_location("mite_house")
	SceneTransition.fade_to_scene("res://scenes/mite_house.tscn")

func _spawn_progression_npcs() -> void:
	# Progression-only NPCs are registered in world_event_director.gd; baseline villagers stay above.
	# 进度专属 NPC 在 world_event_director.gd 注册；常驻村民仍由上方基础生成逻辑负责。
	if world_event_director == null:
		return
	world_event_director.spawn_npcs(self, Callable(self, "_on_village_npc_interacted"))

func _refresh_baseline_npc_dialogue(npc: Node) -> void:
	if not is_instance_valid(npc):
		return
	match String(npc.npc_id):
		"village_gatekeeper":
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
		"village_grandmother":
			if "village_defense_survived" in WorldState.achievement_flags:
				npc.dialogue = "老婆婆把门边的灯芯拨亮了一些。\n\n“路总算安静了些。人受了惊，得先吃口热的、睡一觉，别急着把自己逼得太紧。”"
			else:
				npc.dialogue = "老婆婆坐在屋檐下理着旧布。\n\n“外头风大，进村就先歇歇。村里人各有各的烦心事，别什么都往自己身上揽。”"
		"village_blacksmith":
			if "village_defense_survived" in WorldState.achievement_flags:
				npc.dialogue = "铁匠把锤子搁在砧边，检查着刚换上的门钉。\n\n“北门暂时撑得住。等我把手头这批活做完，再看看你的兵器。”"
			else:
				npc.dialogue = "铁匠正把一块发红的铁料翻了个面。\n\n“想修兵器就先让我看看。至于那扇北门——它比一把钝剑更急着修。”"
		"traveling_merchant":
			if WorldState.get_humanity_state() == "hollow":
				npc.dialogue = "商人收起了笑容，悄悄把货箱往身边拉近。\n\n“今天先不谈价。你看起来比路上的风雨更难应付。”"
			elif "graybox_intro_forgotten_city" in WorldState.achievement_flags:
				npc.dialogue = "商人注意到你靴边的旧灰，没追问你在城墙下看见了什么。\n\n“旧城区的路不适合闭着眼走。记住自己从哪一侧进来，比记住传闻更有用。”"
			elif "graybox_intro_ash_forest" in WorldState.achievement_flags:
				npc.dialogue = "商人把一枚磨损的路标放回箱中。\n\n“北边的旧路能走，不代表每条岔路都值得追。回来时，先记清楚自己看见了什么。”"
			elif "village_defense_survived" in WorldState.achievement_flags:
				npc.dialogue = "商人重新整理着货物。\n\n“北门恢复通行后，来往的人会多起来。真要买东西，先想清楚下一段路缺什么。”"
			else:
				npc.dialogue = "商人把银币在指间转了一圈，打量着你的行囊。\n\n“我从外面来，也会往外面去。要问路况可以，传闻就得自己掂量。”"

func refresh_progression_content() -> void:
	# Refresh resident dialogue and stateful POI feedback from persisted world facts.
	# 常驻 NPC 与带状态的 POI 都读取持久化事实，避免事件发生后场景内反馈滞后。
	for npc in get_tree().get_nodes_in_group("a1_baseline_npcs"):
		_refresh_baseline_npc_dialogue(npc)
	_refresh_tavern_poi_dialogue()
	_refresh_world_visual_states()
	if world_event_director == null:
		return
	world_event_director.dispatch("state_refresh", {"region": "A1", "location": "village"})
	_spawn_progression_npcs()

func _refresh_tavern_poi_dialogue() -> void:
	for poi in get_tree().get_nodes_in_group("a1_tavern_poi"):
		if not is_instance_valid(poi):
			continue
		if "A1_tavern_sound_noticed" in WorldState.achievement_flags:
			poi.dialogue = "你再次靠近酒馆。门内没有歌声，只有杯碟轻碰。\n\n值夜人似乎一直留意着门外，却没有主动提起那一瞬间的旋律。"
		else:
			poi.dialogue = "酒馆的门在你掌下发暖。\n\n你短暂地听见里面传来摇篮曲；当你碰到门把时，歌声却停了。"

func _on_village_npc_interacted(npc: Node) -> void:
	if narrative == null or not is_instance_valid(npc):
		return
	narrative.show_message(npc.display_name, npc.dialogue, 6.0)
	await narrative.message_finished
	if world_event_director != null:
		world_event_director.dispatch("interaction", {"region": "A1", "interaction_id": String(npc.npc_id), "npc_id": String(npc.npc_id)})
		refresh_progression_content()


func _on_village_poi_interacted(poi: Node) -> void:
	narrative.show_message(poi.display_name, poi.dialogue, 2.5)
	await narrative.message_finished
	if world_event_director != null:
		world_event_director.dispatch("interaction", {"region": "A1", "interaction_id": String(poi.poi_id), "poi": poi})
		refresh_progression_content()
	_enter_village_location(poi.poi_id)


func _on_resonance_well_opened(secret_id: String) -> void:
	if narrative == null or not is_instance_valid(narrative):
		return
	narrative.show_message(
		"THE WELL THAT WAS ALREADY THERE",
		"The stones slide inward without a sound.\n\nA stair descends where the water should be.\n\nThe opening will remain.",
		4.5
	)

func _enter_village_location(location_id: String) -> void:
	if location_id == "backhill_path":
		WorldState.pending_region_spawn_side = "backhill_return"
		WorldState.set_location("village_backhill")
		print("[NEREIS][VILLAGE] Entering A1.1: Church, Tavern and Backhill")
		SceneTransition.fade_to_scene("res://scenes/village_backhill.tscn")
	elif location_id == "tavern":
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
			WorldState.pending_region_spawn_side = "village_entry"
			WorldState.set_location("old_drain_exploration")
			print("[NEREIS][MAP] Entering the first old-drain exploration segment")
			SceneTransition.fade_to_scene("res://scenes/old_drain_exploration.tscn")
		else:
			print("[NEREIS][MAP] Old drainage passage remains sealed until the village attack is survived")
	elif location_id == "graveyard":
		WorldState.set_location("graveyard")
		print("[NEREIS][VILLAGE] Entering Village Graveyard")
		SceneTransition.fade_to_scene("res://scenes/village_graveyard.tscn")

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
