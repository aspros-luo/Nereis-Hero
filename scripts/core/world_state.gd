extends Node

signal hidden_resistance_awakened_event
signal witch_time_started(duration: float)
signal witch_time_ended

const SAVE_PATH := "user://nereis_hero_save.json"

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
var language := "zh_cn"
var interior_clues_seen: Array[String] = []
var world_clues_seen: Array[String] = []
var graveyard_cleared := false
var graveyard_keeper_heard := false
var weapon_level := 1
var hero_attack_damage := 34
var input_locked := false
var hitstop_serial := 0
var hitstop_active := false
var active_hitstop_scale := 0.08
var witch_time_serial := 0
var witch_time_active := false
var witch_time_scale := 0.24
var witch_time_cooldown_until_msec := 0

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
    load_game()

func prepare_scene_runtime() -> void:
    get_tree().paused = false
    input_locked = false
    hitstop_serial += 1
    witch_time_serial += 1
    hitstop_active = false
    witch_time_active = false
    Engine.time_scale = 1.0

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
    hitstop_active = true
    active_hitstop_scale = clampf(slow_scale, 0.01, 1.0)
    _refresh_time_scale()
    get_tree().create_timer(duration, true, false, true).timeout.connect(func() -> void:
        if serial == hitstop_serial:
            hitstop_active = false
            _refresh_time_scale()
    )

func trigger_witch_time(duration: float = 0.52, slow_scale: float = 0.24) -> bool:
    var now_msec := Time.get_ticks_msec()
    if duration <= 0.0 or now_msec < witch_time_cooldown_until_msec:
        return false

    witch_time_cooldown_until_msec = now_msec + 1450
    witch_time_serial += 1
    var serial: int = witch_time_serial
    witch_time_active = true
    witch_time_scale = clampf(slow_scale, 0.12, 0.6)
    _refresh_time_scale()
    witch_time_started.emit(duration)
    print("[NEREIS][COMBAT] WITCH TIME! duration=%.2f scale=%.2f" % [duration, witch_time_scale])

    get_tree().create_timer(duration, true, false, true).timeout.connect(func() -> void:
        if serial == witch_time_serial:
            witch_time_active = false
            _refresh_time_scale()
            witch_time_ended.emit()
    )
    return true

func _refresh_time_scale() -> void:
    var target_scale := 1.0
    if witch_time_active:
        target_scale = minf(target_scale, witch_time_scale)
    if hitstop_active:
        target_scale = minf(target_scale, active_hitstop_scale)
    Engine.time_scale = target_scale

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
    print("[NEREIS][STORY] Ancient-god residue awakened")
    save_game()

func mark_outer_god_resonance() -> void:
    if outer_god_resonance:
        return
    outer_god_resonance = true
    print("[NEREIS][STORY] Outer-God resonance established")
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
    mite_first_meeting = bool(parsed.get("mite_first_meeting", false))
    mite_interactions_seen.clear()
    var saved_mite_interactions = parsed.get("mite_interactions_seen", [])
    if saved_mite_interactions is Array:
        for interaction_id in saved_mite_interactions:
            mite_interactions_seen.append(str(interaction_id))
    mite_last_interaction_location = str(parsed.get("mite_last_interaction_location", ""))
    mite_connection_missed = bool(parsed.get("mite_connection_missed", false))
    ancient_residue_awakened = bool(parsed.get("ancient_residue_awakened", false))
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

    print("[NEREIS][SAVE] Game loaded; memory=%d boss_defeated=%s choice=%s" % [hero_memory, boss_defeated, first_choice_made])

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
    hitstop_serial += 1
    witch_time_serial += 1
    hitstop_active = false
    witch_time_active = false
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
