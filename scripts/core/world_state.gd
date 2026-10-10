extends Node

signal hidden_resistance_awakened_event

const SAVE_PATH := "user://nereis_hero_save.json"
const WITCH_TIME_OVERLAY_SCRIPT: Script = preload("res://scripts/effects/witch_time_overlay.gd")

var hero_memory := 0
var hero_humanity := 100
var first_memory_unlocked := false
var checkpoint_position := Vector2(320, 520)
var checkpoint_active := false
var boss_defeated := false
var boss_gate_open := false
var church_alignment := 0
var lullaby_resonance := 0
var first_choice_made := false
var slice_complete := false
var selected_route := ""
var route_memory_seen := false
var route_memory_id := ""
var route_complete := false
var current_location := "slice"
# Transient direction used by graybox region scene transitions; intentionally not saved.
var pending_region_spawn_side := "west"
var language := "zh_cn"
var interior_clues_seen: Array[String] = []
var world_clues_seen: Array[String] = []
var graveyard_cleared := false
var graveyard_keeper_heard := false
var weapon_level := 1
var hero_attack_damage := 34

# Hidden protagonist progression. Never expose these values in normal HUD.
var hero_resonance := 0
var ancient_exposure := 0
var outer_exposure := 0
var abnormal_load := 0.0
var current_weapon_style := "long_sword"
var learned_techniques: Array[String] = []
var technique_variants: Dictionary = {}
var resonance_sources: Array[String] = []

# Persistent hidden-world discoveries. Discovery, gate opening and actual entry are distinct facts.
# 持久化隐藏世界状态：发现入口、开启通路、实际进入分别记录。
var discovered_hidden_regions: Array[String] = []
var opened_hidden_paths: Array[String] = []
var entered_hidden_regions: Array[String] = []

# Data-driven ability progression. Unlock records store their origin for debugging and save migration.
# 数据驱动的能力成长：保存解锁来源，便于排查和兼容旧存档。
const ABILITY_IDS := ["iaijutsu_basic", "double_jump", "quick_dash", "witch_time", "grapple", "wall_climb", "resonance_sight", "technique_judgment_slash", "technique_crescent_combo", "eldritch_echo"]
const ABILITY_SOURCE_TYPES := ["story", "exploration", "achievement", "resonance", "material"]
var unlocked_abilities: Dictionary = {}
var achievement_flags: Array[String] = []
var upgrade_materials: Dictionary = {}
var input_locked := false
# Menu lock disables Hero input while the world and all gameplay timers keep running.
var menu_input_locked := false
var hitstop_serial := 0

# Witch Time scales hostile AI delta only; Hero input and physics stay responsive.
# 魔女时间只缩放敌方 AI 的 delta，不减慢主角输入与物理响应。
var witch_time_remaining := 0.0
var witch_time_enemy_scale := 0.22
var witch_time_visual: CanvasLayer
var resonance_sight_active := false
var _last_runtime_scene_path := ""
var _last_resonance_signature := Vector3i(-1, -1, -1)

# Narrative state is stored as facts/flags, not as a visible romance meter.
var mite_first_meeting := false
var mite_interactions_seen: Array[String] = []
var mite_last_interaction_location := ""
var mite_connection_missed := false
var ancient_residue_awakened := false
var outer_god_resonance := false
var mite_control_stage := 0
var physical_union_complete := false
var hidden_artifact_pieces := 0
var hidden_artifact_sources: Array[String] = []
var hidden_resistance_awakened := false
var ending_route := ""
var prologue_complete := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    load_game()

func _process(delta: float) -> void:
    var scene := get_tree().current_scene
    if scene != null:
        var scene_path := str(scene.scene_file_path)
        if _last_runtime_scene_path.is_empty():
            _last_runtime_scene_path = scene_path
        elif scene_path != _last_runtime_scene_path:
            clear_witch_time("scene changed")
            set_resonance_sight_active(false)
            _last_runtime_scene_path = scene_path

    if input_locked or menu_input_locked or get_tree().paused:
        clear_witch_time("input/menu lock")
        set_resonance_sight_active(false)
        return

    if resonance_sight_active:
        var signature := Vector3i(hero_resonance, ancient_exposure, outer_exposure)
        if signature != _last_resonance_signature:
            _last_resonance_signature = signature
            refresh_resonance_reveals()
    else:
        _last_resonance_signature = Vector3i(-1, -1, -1)

    if witch_time_remaining > 0.0:
        if not is_instance_valid(witch_time_visual):
            _show_witch_time_visual()
        witch_time_remaining = maxf(0.0, witch_time_remaining - delta)
        if witch_time_remaining <= 0.0:
            print("[NEREIS][ABILITY] Witch Time ended")
            _hide_witch_time_visual()

func prepare_scene_runtime() -> void:
    get_tree().paused = false
    input_locked = false
    menu_input_locked = false
    clear_witch_time("scene runtime reset")
    set_resonance_sight_active(false)
    _last_runtime_scene_path = ""
    hitstop_serial += 1
    Engine.time_scale = 1.0

func trigger_witch_time(duration: float = 2.4, enemy_scale: float = 0.22) -> void:
    if input_locked or menu_input_locked or duration <= 0.0:
        return
    var was_active := witch_time_remaining > 0.0
    witch_time_remaining = maxf(witch_time_remaining, duration)
    witch_time_enemy_scale = clampf(enemy_scale, 0.08, 0.60)
    if not was_active:
        _show_witch_time_visual()
    # Do not replay the activation sting on every precision dodge while already slowed.
    # 魔女时间已激活时再次触发，不重复播放入场音，避免连续精准闪避造成音效轰炸。
    print("[NEREIS][ABILITY] Witch Time active for %.2fs; enemy delta scale=%.2f" % [witch_time_remaining, witch_time_enemy_scale])

func clear_witch_time(reason: String = "") -> void:
    if witch_time_remaining > 0.0:
        print("[NEREIS][ABILITY] Witch Time cleared%s" % (": " + reason if not reason.is_empty() else ""))
    witch_time_remaining = 0.0
    witch_time_enemy_scale = 1.0
    _hide_witch_time_visual()

func _show_witch_time_visual() -> void:
    var scene := get_tree().current_scene
    if scene == null:
        return
    if is_instance_valid(witch_time_visual) and witch_time_visual.get_parent() != scene:
        witch_time_visual.queue_free()
        witch_time_visual = null
    if not is_instance_valid(witch_time_visual):
        witch_time_visual = CanvasLayer.new()
        witch_time_visual.set_script(WITCH_TIME_OVERLAY_SCRIPT)
        witch_time_visual.name = "WitchTimeVisual"
        scene.add_child(witch_time_visual)
    else:
        witch_time_visual.call("play_activation")

func _hide_witch_time_visual() -> void:
    if is_instance_valid(witch_time_visual):
        witch_time_visual.queue_free()
    witch_time_visual = null

func get_combat_enemy_time_scale() -> float:
    return witch_time_enemy_scale if witch_time_remaining > 0.0 else 1.0

func set_resonance_sight_active(active: bool) -> void:
    if resonance_sight_active == active:
        return
    resonance_sight_active = active
    _last_resonance_signature = Vector3i(-1, -1, -1)
    refresh_resonance_reveals()

func refresh_resonance_reveals(debug_override: bool = false) -> void:
    for target in get_tree().get_nodes_in_group("resonance_hidden_targets"):
        if not is_instance_valid(target) or target.is_queued_for_deletion():
            continue
        if target.has_method("update_reveal_state"):
            target.call("update_reveal_state", resonance_sight_active, hero_resonance, ancient_exposure, outer_exposure, debug_override)

func unlock_first_memory() -> void:
    if first_memory_unlocked:
        return
    first_memory_unlocked = true
    hero_memory += 1
    print("[NEREIS][STORY] First memory unlocked; hero_memory=%d" % hero_memory)
    save_game()

func set_checkpoint(position: Vector2) -> void:
    checkpoint_position = position
    checkpoint_active = true
    print("[NEREIS][WORLD] Checkpoint activated at %s" % checkpoint_position)
    save_game()

func open_boss_gate() -> void:
    if boss_gate_open:
        return
    boss_gate_open = true
    print("[NEREIS][WORLD] Boss gate state recorded as open")
    save_game()

func make_first_choice(choice: int) -> void:
    if first_choice_made:
        return
    first_choice_made = true
    if choice == 1:
        church_alignment += 1
        selected_route = "church"
        print("[NEREIS][STORY] First choice: follow_church; church_alignment=%d" % church_alignment)
    else:
        lullaby_resonance += 1
        selected_route = "lullaby"
        hero_memory += 1
        print("[NEREIS][STORY] First choice: follow_lullaby; lullaby_resonance=%d hero_memory=%d" % [lullaby_resonance, hero_memory])
    save_game()

func mark_boss_defeated() -> void:
    if boss_defeated:
        return
    boss_defeated = true
    print("[NEREIS][BOSS] Ashen Knight victory recorded in WorldState")
    save_game()

func upgrade_weapon() -> bool:
    if weapon_level >= 2:
        return false
    weapon_level = 2
    hero_attack_damage = 44
    print("[NEREIS][COMBAT] Weapon upgraded; level=%d damage=%d" % [weapon_level, hero_attack_damage])
    save_game()
    return true

func mark_slice_complete() -> void:
    if slice_complete:
        return
    slice_complete = true
    print("[NEREIS][WORLD] Vertical Slice completion saved")
    save_game()

func trigger_hitstop(duration: float = 0.045, slow_scale: float = 0.08) -> void:
    if duration <= 0.0:
        return

    hitstop_serial += 1
    var serial: int = hitstop_serial
    Engine.time_scale = minf(Engine.time_scale, slow_scale)
    get_tree().create_timer(duration, true, false, true).timeout.connect(func() -> void:
        if serial == hitstop_serial:
            Engine.time_scale = 1.0
    )

func record_mite_interaction(interaction_id: String) -> bool:
    if interaction_id in mite_interactions_seen:
        return false
    mite_interactions_seen.append(interaction_id)
    mite_last_interaction_location = current_location
    if interaction_id == "mite_first_meeting":
        mite_first_meeting = true
    print("[NEREIS][RELATIONSHIP] Mite interaction recorded id=%s total=%d" % [interaction_id, mite_interactions_seen.size()])
    save_game()
    return true

func has_mite_interaction(interaction_id: String) -> bool:
    return interaction_id in mite_interactions_seen

func mark_mite_connection_missed() -> void:
    if mite_connection_missed:
        return
    mite_connection_missed = true
    print("[NEREIS][RELATIONSHIP] Mite connection window marked missed")
    save_game()

func mark_ancient_residue_awakened() -> void:
    if ancient_residue_awakened:
        return
    ancient_residue_awakened = true
    # The awakening is a real bodily exposure, not a visible character stat.
    ancient_exposure = maxi(ancient_exposure, 1)
    hero_resonance = maxi(hero_resonance, 12)
    if "ancient_residue_awakened" not in resonance_sources:
        resonance_sources.append("ancient_residue_awakened")
    print("[NEREIS][STORY] Ancient-god residue awakened; hidden protagonist response recorded")
    save_game()

func mark_outer_god_resonance() -> void:
    # Keep deep hidden-region access order-independent. If the Hero examined the
    # Observer Reaction before the Mite-related story flag, the later story event
    # must reconcile the already-recorded +6 instead of leaving H08 permanently locked.
    # 保证深层入口不受调查顺序影响：若先调查观测者，再触发外神共鸣，接触度应补齐到 18。
    var exposure_target := 18 if "anomaly_observer_reaction" in resonance_sources else 12
    var exposure_changed := outer_exposure < exposure_target
    outer_exposure = maxi(outer_exposure, exposure_target)
    if outer_god_resonance:
        if exposure_changed:
            save_game()
        return
    outer_god_resonance = true
    print("[NEREIS][STORY] Outer-God resonance established; exposure=%d" % outer_exposure)
    save_game()

func advance_mite_control_stage() -> int:
    if not outer_god_resonance:
        return mite_control_stage
    mite_control_stage = clampi(mite_control_stage + 1, 0, 3)
    print("[NEREIS][STORY] Mite control stage=%d/3" % mite_control_stage)
    save_game()
    return mite_control_stage

func mark_physical_union_complete() -> void:
    if physical_union_complete:
        return
    physical_union_complete = true
    print("[NEREIS][STORY] Physical union state recorded")
    save_game()

func record_hidden_artifact_source(source_id: String) -> bool:
    var canonical_id := _canonical_artifact_source(source_id)
    if canonical_id.is_empty() or canonical_id in hidden_artifact_sources:
        return false
    hidden_artifact_sources.append(canonical_id)
    hidden_artifact_pieces = mini(hidden_artifact_sources.size(), 4)
    if hidden_artifact_pieces >= 3 and not hidden_resistance_awakened:
        hidden_resistance_awakened = true
        hidden_resistance_awakened_event.emit()
        print("[NEREIS][SECRET] The hidden resistance anchor has awakened")
    print("[NEREIS][SECRET] Hidden artifact source=%s pieces=%d/4" % [canonical_id, hidden_artifact_pieces])
    save_game()
    return true

func _canonical_artifact_source(source_id: String) -> String:
    if source_id.begins_with("lab_") or source_id == "ancient_lab_husk":
        return "ancient_lab"
    if source_id == "graveyard_hero_gravestone":
        return "graveyard_bell"
    if source_id == "rebel_dead_letter":
        return "rebel_order"
    if source_id.begins_with("route_echo_"):
        return "memory_echo"
    return ""

func has_hidden_resistance() -> bool:
    return hidden_resistance_awakened and hidden_artifact_pieces >= 3

func get_hidden_resistance_description() -> String:
    if not has_hidden_resistance():
        return ""
    return "Something assembled from four unrelated stories rests against the Hero's skin. It is not a weapon. It simply refuses to let the self disappear."

func add_hidden_artifact_piece() -> int:
    hidden_artifact_pieces = mini(hidden_artifact_pieces + 1, 4)
    print("[NEREIS][SECRET] Hidden artifact pieces=%d/4" % hidden_artifact_pieces)
    save_game()
    return hidden_artifact_pieces

func set_ending_route(route_id: String) -> void:
    ending_route = route_id
    print("[NEREIS][ENDING] Route=%s" % ending_route)
    save_game()

func set_language(language_id: String) -> void:
    if language_id not in ["zh_cn", "zh_tw", "en", "ja"]:
        return
    language = language_id
    print("[NEREIS][SYSTEM] Language=%s" % language)
    save_game()

func save_game() -> void:
    var data := {
        "hero_memory": hero_memory,
        "hero_humanity": hero_humanity,
        "first_memory_unlocked": first_memory_unlocked,
        "checkpoint_position": {
            "x": checkpoint_position.x,
            "y": checkpoint_position.y
        },
        "checkpoint_active": checkpoint_active,
        "boss_defeated": boss_defeated,
        "boss_gate_open": boss_gate_open,
        "church_alignment": church_alignment,
        "lullaby_resonance": lullaby_resonance,
        "first_choice_made": first_choice_made,
        "slice_complete": slice_complete,
        "selected_route": selected_route,
        "route_memory_seen": route_memory_seen,
        "route_memory_id": route_memory_id,
        "route_complete": route_complete,
        "current_location": current_location,
        "language": language,
        "interior_clues_seen": interior_clues_seen,
        "world_clues_seen": world_clues_seen,
        "graveyard_cleared": graveyard_cleared,
        "graveyard_keeper_heard": graveyard_keeper_heard,
        "weapon_level": weapon_level,
        "hero_attack_damage": hero_attack_damage,
        "hero_resonance": hero_resonance,
        "ancient_exposure": ancient_exposure,
        "outer_exposure": outer_exposure,
        "abnormal_load": abnormal_load,
        "current_weapon_style": current_weapon_style,
        "learned_techniques": learned_techniques,
        "technique_variants": technique_variants,
        "resonance_sources": resonance_sources,
        "discovered_hidden_regions": discovered_hidden_regions,
        "opened_hidden_paths": opened_hidden_paths,
        "entered_hidden_regions": entered_hidden_regions,
        "unlocked_abilities": unlocked_abilities,
        "achievement_flags": achievement_flags,
        "upgrade_materials": upgrade_materials,
        "mite_first_meeting": mite_first_meeting,
        "mite_interactions_seen": mite_interactions_seen,
        "mite_last_interaction_location": mite_last_interaction_location,
        "mite_connection_missed": mite_connection_missed,
        "ancient_residue_awakened": ancient_residue_awakened,
        "outer_god_resonance": outer_god_resonance,
        "mite_control_stage": mite_control_stage,
        "physical_union_complete": physical_union_complete,
        "hidden_artifact_pieces": hidden_artifact_pieces,
        "hidden_artifact_sources": hidden_artifact_sources,
        "hidden_resistance_awakened": hidden_resistance_awakened,
        "ending_route": ending_route,
        "prologue_complete": prologue_complete
    }

    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        print("[NEREIS][SAVE][ERROR] Could not open save file")
        return

    file.store_string(JSON.stringify(data))
    print("[NEREIS][SAVE] Game saved")

func load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        print("[NEREIS][SAVE] No save file; starting new run")
        return

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        print("[NEREIS][SAVE][ERROR] Could not open save file")
        return

    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        print("[NEREIS][SAVE][ERROR] Save payload is invalid")
        return

    hero_memory = int(parsed.get("hero_memory", 0))
    hero_humanity = int(parsed.get("hero_humanity", 100))
    first_memory_unlocked = bool(parsed.get("first_memory_unlocked", false))

    var saved_checkpoint = parsed.get("checkpoint_position", {})
    if saved_checkpoint is Dictionary:
        checkpoint_position = Vector2(
            float(saved_checkpoint.get("x", 320.0)),
            float(saved_checkpoint.get("y", 520.0))
        )
    else:
        checkpoint_position = Vector2(320, 520)

    checkpoint_active = bool(parsed.get("checkpoint_active", false))
    boss_defeated = bool(parsed.get("boss_defeated", false))
    boss_gate_open = bool(parsed.get("boss_gate_open", false))
    church_alignment = int(parsed.get("church_alignment", 0))
    lullaby_resonance = int(parsed.get("lullaby_resonance", 0))
    first_choice_made = bool(parsed.get("first_choice_made", false))
    slice_complete = bool(parsed.get("slice_complete", false))
    selected_route = str(parsed.get("selected_route", ""))
    route_memory_seen = bool(parsed.get("route_memory_seen", false))
    route_memory_id = str(parsed.get("route_memory_id", ""))
    route_complete = bool(parsed.get("route_complete", false))
    current_location = str(parsed.get("current_location", "slice"))
    language = str(parsed.get("language", "zh_cn"))
    if language not in ["zh_cn", "zh_tw", "en", "ja"]:
        language = "zh_cn"

    world_clues_seen.clear()
    graveyard_cleared = bool(parsed.get("graveyard_cleared", false))
    graveyard_keeper_heard = bool(parsed.get("graveyard_keeper_heard", false))
    var saved_world_clues = parsed.get("world_clues_seen", [])
    if saved_world_clues is Array:
        for clue_id in saved_world_clues:
            world_clues_seen.append(str(clue_id))

    interior_clues_seen.clear()
    var saved_interior_clues = parsed.get("interior_clues_seen", [])
    if saved_interior_clues is Array:
        for clue_id in saved_interior_clues:
            interior_clues_seen.append(str(clue_id))

    weapon_level = int(parsed.get("weapon_level", 1))
    hero_attack_damage = int(parsed.get("hero_attack_damage", 34))
    hero_resonance = clampi(int(parsed.get("hero_resonance", 0)), 0, 100)
    ancient_exposure = clampi(int(parsed.get("ancient_exposure", 0)), 0, 100)
    outer_exposure = clampi(int(parsed.get("outer_exposure", 0)), 0, 100)
    abnormal_load = clampf(float(parsed.get("abnormal_load", 0.0)), 0.0, 100.0)
    current_weapon_style = str(parsed.get("current_weapon_style", "long_sword"))
    if current_weapon_style not in ["long_sword", "short_blade"]:
        current_weapon_style = "long_sword"
    learned_techniques.clear()
    var saved_techniques = parsed.get("learned_techniques", [])
    if saved_techniques is Array:
        for technique_id in saved_techniques:
            learned_techniques.append(str(technique_id))
    technique_variants = {}
    var saved_variants = parsed.get("technique_variants", {})
    if saved_variants is Dictionary:
        technique_variants = saved_variants.duplicate(true)
    unlocked_abilities = {}
    var saved_abilities = parsed.get("unlocked_abilities", {})
    if saved_abilities is Dictionary:
        for ability_id in saved_abilities.keys():
            if str(ability_id) in ABILITY_IDS and saved_abilities[ability_id] is Dictionary:
                unlocked_abilities[str(ability_id)] = saved_abilities[ability_id].duplicate(true)
    achievement_flags.clear()
    var saved_achievements = parsed.get("achievement_flags", [])
    if saved_achievements is Array:
        for achievement_id in saved_achievements:
            var normalized_achievement := str(achievement_id)
            if not normalized_achievement.is_empty() and normalized_achievement not in achievement_flags:
                achievement_flags.append(normalized_achievement)
    upgrade_materials = {}
    var saved_materials = parsed.get("upgrade_materials", {})
    if saved_materials is Dictionary:
        for material_id in saved_materials.keys():
            upgrade_materials[str(material_id)] = maxi(0, int(saved_materials[material_id]))
    resonance_sources.clear()
    var saved_resonance_sources = parsed.get("resonance_sources", [])
    if saved_resonance_sources is Array:
        for source_id in saved_resonance_sources:
            var normalized_source := str(source_id)
            if not normalized_source.is_empty() and normalized_source not in resonance_sources:
                resonance_sources.append(normalized_source)

    _restore_string_ids(discovered_hidden_regions, parsed.get("discovered_hidden_regions", []))
    _restore_string_ids(opened_hidden_paths, parsed.get("opened_hidden_paths", []))
    _restore_string_ids(entered_hidden_regions, parsed.get("entered_hidden_regions", []))
    mite_first_meeting = bool(parsed.get("mite_first_meeting", false))
    mite_interactions_seen.clear()
    var saved_mite_interactions = parsed.get("mite_interactions_seen", [])
    if saved_mite_interactions is Array:
        for interaction_id in saved_mite_interactions:
            mite_interactions_seen.append(str(interaction_id))
    mite_last_interaction_location = str(parsed.get("mite_last_interaction_location", ""))
    mite_connection_missed = bool(parsed.get("mite_connection_missed", false))
    ancient_residue_awakened = bool(parsed.get("ancient_residue_awakened", false))
    # Migrate older saves where this story flag existed before protagonist progression was wired in.
    if ancient_residue_awakened:
        ancient_exposure = maxi(ancient_exposure, 1)
        hero_resonance = maxi(hero_resonance, 12)
    outer_god_resonance = bool(parsed.get("outer_god_resonance", false))
    mite_control_stage = clampi(int(parsed.get("mite_control_stage", 0)), 0, 3)
    physical_union_complete = bool(parsed.get("physical_union_complete", false))
    hidden_artifact_pieces = clampi(int(parsed.get("hidden_artifact_pieces", 0)), 0, 4)
    hidden_artifact_sources.clear()
    hidden_resistance_awakened = bool(parsed.get("hidden_resistance_awakened", false))
    var saved_artifact_sources = parsed.get("hidden_artifact_sources", [])
    if saved_artifact_sources is Array:
        for source_id in saved_artifact_sources:
            hidden_artifact_sources.append(str(source_id))
    ending_route = str(parsed.get("ending_route", ""))
    prologue_complete = bool(parsed.get("prologue_complete", false))

    # Legacy saves that already reached the village must retain the first story reward.
    # 已经完成序章的旧存档，也应保留第一项剧情奖励。
    var migrated_basic_iaijutsu := false
    if prologue_complete and not unlocked_abilities.has("iaijutsu_basic"):
        unlocked_abilities["iaijutsu_basic"] = {
            "source_type": "story",
            "source_id": "legacy_prologue_completion"
        }
        migrated_basic_iaijutsu = true
        print("[NEREIS][SAVE] Migrated completed prologue to basic iaijutsu unlock")

    print("[NEREIS][SAVE] Game loaded; memory=%d boss_defeated=%s choice=%s" % [hero_memory, boss_defeated, first_choice_made])
    if migrated_basic_iaijutsu:
        save_game()

func is_ability_unlocked(ability_id: String) -> bool:
    return ability_id in ABILITY_IDS and unlocked_abilities.has(ability_id)

func unlock_ability(ability_id: String, source_type: String, source_id: String) -> bool:
    # Call only after the relevant story/exploration/achievement/resonance/material requirement is fulfilled.
    # 仅在对应剧情、探索、成就、共鸣或材料条件满足后调用。
    if ability_id not in ABILITY_IDS or source_type not in ABILITY_SOURCE_TYPES or source_id.strip_edges().is_empty():
        return false
    if ability_id == "iaijutsu_basic" and source_type != "story":
        return false
    if unlocked_abilities.has(ability_id):
        return false
    unlocked_abilities[ability_id] = {"source_type": source_type, "source_id": source_id}
    print("[NEREIS][PROGRESSION] Ability unlocked id=%s source=%s:%s" % [ability_id, source_type, source_id])
    save_game()
    return true

func record_achievement(achievement_id: String) -> bool:
    var normalized_id := achievement_id.strip_edges()
    if normalized_id.is_empty() or normalized_id in achievement_flags:
        return false
    achievement_flags.append(normalized_id)
    save_game()
    return true

func add_upgrade_material(material_id: String, amount: int = 1) -> int:
    var normalized_id := material_id.strip_edges()
    if normalized_id.is_empty() or amount <= 0:
        return int(upgrade_materials.get(normalized_id, 0))
    upgrade_materials[normalized_id] = maxi(0, int(upgrade_materials.get(normalized_id, 0))) + amount
    save_game()
    return int(upgrade_materials[normalized_id])

func spend_upgrade_material(material_id: String, amount: int = 1) -> bool:
    var normalized_id := material_id.strip_edges()
    if normalized_id.is_empty() or amount <= 0:
        return false
    var owned := maxi(0, int(upgrade_materials.get(normalized_id, 0)))
    if owned < amount:
        return false
    upgrade_materials[normalized_id] = owned - amount
    save_game()
    return true

func record_resonance_source(source_id: String) -> bool:
    var normalized_id := source_id.strip_edges()
    if normalized_id.is_empty() or normalized_id in resonance_sources:
        return false
    resonance_sources.append(normalized_id)
    save_game()
    return true

# Record a one-time anomaly milestone and raise resonance to its planned minimum.
# 记录一次性异常节点：鸣响提升至指定下限，避免玩家改变探索顺序后门槛失效。
func record_resonance_milestone(
    source_id: String,
    resonance_target: int,
    ancient_exposure_delta: int = 0,
    outer_exposure_delta: int = 0,
    unlock_ability_id: String = "",
    unlock_source_type: String = "resonance",
    ancient_exposure_floor: int = 0,
    outer_exposure_floor: int = 0
) -> bool:
    var normalized_id := source_id.strip_edges()
    if normalized_id.is_empty():
        return false

    # Existing records do not grant deltas twice, but may safely repair missing
    # minimums / ability unlocks after an update or an older save.
    # 已记录的来源不会重复发放增量，但允许补齐版本更新后的最低值与能力解锁。
    var is_new_source := normalized_id not in resonance_sources
    var resonance_before := hero_resonance
    var ancient_before := ancient_exposure
    var outer_before := outer_exposure
    var ability_id := unlock_ability_id.strip_edges()
    var ability_was_unlocked := ability_id.is_empty() or is_ability_unlocked(ability_id)

    if is_new_source:
        resonance_sources.append(normalized_id)
    hero_resonance = maxi(hero_resonance, clampi(resonance_target, 0, 100))
    ancient_exposure = maxi(ancient_exposure, clampi(ancient_exposure_floor, 0, 100))
    outer_exposure = maxi(outer_exposure, clampi(outer_exposure_floor, 0, 100))

    if is_new_source:
        ancient_exposure = clampi(ancient_exposure + maxi(0, ancient_exposure_delta), 0, 100)
        outer_exposure = clampi(outer_exposure + maxi(0, outer_exposure_delta), 0, 100)

    if not ability_id.is_empty() and not is_ability_unlocked(ability_id):
        unlock_ability(ability_id, unlock_source_type, normalized_id)

    var state_changed := (
        is_new_source
        or hero_resonance != resonance_before
        or ancient_exposure != ancient_before
        or outer_exposure != outer_before
        or (not ability_was_unlocked and not ability_id.is_empty() and is_ability_unlocked(ability_id))
    )
    if not state_changed:
        return false

    print("[NEREIS][SENSE] Anomaly recorded id=%s new=%s resonance=%d ancient=%d outer=%d" % [
        normalized_id, str(is_new_source), hero_resonance, ancient_exposure, outer_exposure
    ])
    save_game()
    refresh_resonance_reveals()
    return is_new_source

func discover_hidden_region(region_id: String) -> bool:
    var normalized_id := region_id.strip_edges()
    if normalized_id.is_empty() or normalized_id in discovered_hidden_regions:
        return false
    discovered_hidden_regions.append(normalized_id)
    print("[NEREIS][SECRET] Hidden region discovered id=%s" % normalized_id)
    save_game()
    return true

func open_hidden_path(path_id: String) -> bool:
    var normalized_id := path_id.strip_edges()
    if normalized_id.is_empty() or normalized_id in opened_hidden_paths:
        return false
    opened_hidden_paths.append(normalized_id)
    print("[NEREIS][SECRET] Hidden path permanently opened id=%s" % normalized_id)
    save_game()
    return true

func mark_hidden_region_entered(region_id: String) -> bool:
    var normalized_id := region_id.strip_edges()
    if normalized_id.is_empty() or normalized_id in entered_hidden_regions:
        return false
    entered_hidden_regions.append(normalized_id)
    print("[NEREIS][SECRET] Hidden region entered id=%s" % normalized_id)
    save_game()
    return true

func is_hidden_path_opened(path_id: String) -> bool:
    return path_id in opened_hidden_paths

func _restore_string_ids(target: Array[String], raw_value: Variant) -> void:
    target.clear()
    if not (raw_value is Array):
        return
    for raw_id in raw_value:
        var normalized_id := str(raw_id)
        if not normalized_id.is_empty() and normalized_id not in target:
            target.append(normalized_id)

func mark_prologue_complete() -> void:
    if prologue_complete:
        return
    prologue_complete = true
    print("[NEREIS][STORY] Prologue complete; Hero reached the village")
    save_game()

func delete_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
        print("[NEREIS][SAVE] Save file deleted")
    reset()
    save_game()

func reset() -> void:
    var preserved_language := language
    hero_memory = 0
    hero_humanity = 100
    first_memory_unlocked = false
    checkpoint_position = Vector2(320, 520)
    checkpoint_active = false
    boss_defeated = false
    boss_gate_open = false
    church_alignment = 0
    lullaby_resonance = 0
    first_choice_made = false
    slice_complete = false
    selected_route = ""
    route_memory_seen = false
    route_memory_id = ""
    route_complete = false
    current_location = "church_escape"
    language = preserved_language
    interior_clues_seen.clear()
    world_clues_seen.clear()
    graveyard_cleared = false
    graveyard_keeper_heard = false
    weapon_level = 1
    hero_attack_damage = 34
    hero_resonance = 0
    ancient_exposure = 0
    outer_exposure = 0
    abnormal_load = 0.0
    current_weapon_style = "long_sword"
    learned_techniques.clear()
    technique_variants.clear()
    resonance_sources.clear()
    discovered_hidden_regions.clear()
    opened_hidden_paths.clear()
    entered_hidden_regions.clear()
    pending_region_spawn_side = "west"
    unlocked_abilities.clear()
    achievement_flags.clear()
    upgrade_materials.clear()
    mite_first_meeting = false
    mite_interactions_seen.clear()
    mite_last_interaction_location = ""
    mite_connection_missed = false
    ancient_residue_awakened = false
    outer_god_resonance = false
    mite_control_stage = 0
    physical_union_complete = false
    hidden_artifact_pieces = 0
    hidden_artifact_sources.clear()
    hidden_resistance_awakened = false
    ending_route = ""
    prologue_complete = false
    input_locked = false
    menu_input_locked = false
    clear_witch_time("world state reset")
    set_resonance_sight_active(false)
    hitstop_serial += 1
    Engine.time_scale = 1.0

func record_route_memory(memory_id: String, humanity_delta: int = 0) -> bool:
    if route_memory_seen and route_memory_id == memory_id:
        return false
    route_memory_seen = true
    route_memory_id = memory_id
    hero_memory += 1
    hero_humanity = clamp(hero_humanity + humanity_delta, 0, 100)
    print("[NEREIS][STORY] Route memory recorded id=%s hero_memory=%d humanity=%d" % [memory_id, hero_memory, hero_humanity])
    save_game()
    return true

func record_interior_clue(clue_id: String, humanity_delta: int = 0) -> bool:
    if clue_id in interior_clues_seen:
        return false
    interior_clues_seen.append(clue_id)
    hero_memory += 1
    hero_humanity = clamp(hero_humanity + humanity_delta, 0, 100)
    print("[NEREIS][STORY] Interior clue recorded id=%s hero_memory=%d humanity=%d" % [clue_id, hero_memory, hero_humanity])
    save_game()
    return true

func mark_graveyard_keeper_heard() -> void:
    if graveyard_keeper_heard:
        return
    graveyard_keeper_heard = true
    save_game()

func mark_graveyard_cleared() -> void:
    if graveyard_cleared:
        return
    graveyard_cleared = true
    print("[NEREIS][WORLD] Village Graveyard encounter cleared")
    save_game()

func record_world_clue(clue_id: String, humanity_delta: int = 0) -> bool:
    if clue_id in world_clues_seen:
        return false
    world_clues_seen.append(clue_id)
    hero_memory += 1
    hero_humanity = clamp(hero_humanity + humanity_delta, 0, 100)
    print("[NEREIS][STORY] World clue recorded id=%s hero_memory=%d humanity=%d" % [clue_id, hero_memory, hero_humanity])
    save_game()
    return true

func get_humanity_state() -> String:
    if hero_humanity < 25:
        return "hollow"
    if hero_humanity < 60:
        return "frayed"
    return "stable"

func set_location(location_id: String) -> void:
    current_location = location_id
    print("[NEREIS][WORLD] Current location=%s" % current_location)
    save_game()

func mark_route_complete() -> void:
    if route_complete:
        return
    route_complete = true
    print("[NEREIS][ROUTE] Route completion saved for %s" % selected_route)
    save_game()

func get_resume_scene_path() -> String:
    match current_location:
        "church_escape":
            return "res://scenes/escape_prologue.tscn"
        "village":
            return "res://scenes/village_hub.tscn"
        "ash_forest":
            return "res://scenes/ash_forest.tscn"
        "forgotten_city":
            return "res://scenes/forgotten_city.tscn"
        "sewer_reservoir":
            return "res://scenes/sewer_reservoir.tscn"
        "old_battlefield":
            return "res://scenes/old_battlefield.tscn"
        "monastery_tower":
            return "res://scenes/monastery_tower.tscn"
        "prison_depths":
            return "res://scenes/prison_depths.tscn"
        "royal_tomb":
            return "res://scenes/royal_tomb.tscn"
        "royal_outer_ring":
            return "res://scenes/royal_outer_ring.tscn"
        "grand_cathedral":
            return "res://scenes/grand_cathedral.tscn"
        "inner_city":
            return "res://scenes/inner_city.tscn"
        "deep_research_depths":
            return "res://scenes/deep_research_depths.tscn"
        "primordial_hollow":
            return "res://scenes/primordial_hollow.tscn"
        "church_final_demo":
            return "res://scenes/church_final_demo.tscn"
        "ending_paradise_demo":
            return "res://scenes/ending_paradise_demo.tscn"
        "ending_fire_demo":
            return "res://scenes/ending_fire_demo.tscn"
        "hidden_bell_chamber":
            return "res://scenes/hidden_bell_chamber.tscn"
        "erased_third_street":
            return "res://scenes/erased_third_street.tscn"
        "reflected_stairwell":
            return "res://scenes/reflected_stairwell.tscn"
        "silent_bell_room":
            return "res://scenes/silent_bell_room.tscn"
        "erased_royal_name_corridor":
            return "res://scenes/erased_royal_name_corridor.tscn"
        "mirror_street":
            return "res://scenes/mirror_street.tscn"
        "hidden_well":
            return "res://scenes/hidden_well.tscn"
        "tavern":
            return "res://scenes/locations/tavern_interior.tscn"
        "church":
            return "res://scenes/locations/church_interior.tscn"
        "graveyard":
            return "res://scenes/village_graveyard.tscn"
        "rebel_camp":
            return "res://scenes/rebel_camp.tscn"
        "ancient_lab":
            return "res://scenes/ancient_research_lab.tscn"
        "mite_house":
            return "res://scenes/mite_house.tscn"
        "route_church":
            return "res://scenes/routes/church_path.tscn"
        "route_lullaby":
            return "res://scenes/routes/lullaby_path.tscn"
        _:
            if route_complete:
                return "res://scenes/village_hub.tscn"
            if slice_complete and selected_route != "":
                return get_route_scene_path()
            return "res://scenes/escape_prologue.tscn"

func get_route_scene_path() -> String:
    if selected_route == "lullaby":
        return "res://scenes/routes/lullaby_path.tscn"
    return "res://scenes/routes/church_path.tscn"
