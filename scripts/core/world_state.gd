extends Node

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
var interior_clues_seen: Array[String] = []
var weapon_level := 1
var hero_attack_damage := 34
var input_locked := false

func _ready() -> void:
    load_game()

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
        "interior_clues_seen": interior_clues_seen,
        "weapon_level": weapon_level,
        "hero_attack_damage": hero_attack_damage
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
    var saved_interior_clues = parsed.get("interior_clues_seen", [])
    if saved_interior_clues is Array:
        interior_clues_seen.clear()
        for clue_id in saved_interior_clues:
            interior_clues_seen.append(str(clue_id))
    weapon_level = int(parsed.get("weapon_level", 1))
    hero_attack_damage = int(parsed.get("hero_attack_damage", 34))

    print("[NEREIS][SAVE] Game loaded; memory=%d boss_defeated=%s choice=%s" % [hero_memory, boss_defeated, first_choice_made])

func delete_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
        print("[NEREIS][SAVE] Save file deleted")
    reset()

func reset() -> void:
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
    current_location = "slice"
    interior_clues_seen.clear()
    weapon_level = 1
    hero_attack_damage = 34
    input_locked = false

  
func record_route_memory(memory_id: String) -> bool:
    if route_memory_seen and route_memory_id == memory_id:
        return false
    route_memory_seen = true
    route_memory_id = memory_id
    hero_memory += 1
    print("[NEREIS][STORY] Route memory recorded id=%s hero_memory=%d" % [memory_id, hero_memory])
    save_game()
    return true

func record_interior_clue(clue_id: String) -> bool:
    if clue_id in interior_clues_seen:
        return false
    interior_clues_seen.append(clue_id)
    hero_memory += 1
    print("[NEREIS][STORY] Interior clue recorded id=%s hero_memory=%d" % [clue_id, hero_memory])
    save_game()
    return true

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
        "village":
            return "res://scenes/village_hub.tscn"
        "tavern":
            return "res://scenes/locations/tavern_interior.tscn"
        "church":
            return "res://scenes/locations/church_interior.tscn"
        "route_church":
            return "res://scenes/routes/church_path.tscn"
        "route_lullaby":
            return "res://scenes/routes/lullaby_path.tscn"
        _:
            if route_complete:
                return "res://scenes/village_hub.tscn"
            if slice_complete and selected_route != "":
                return get_route_scene_path()
            return "res://scenes/main.tscn"

func get_route_scene_path() -> String:
    if selected_route == "lullaby":
        return "res://scenes/routes/lullaby_path.tscn"
    return "res://scenes/routes/church_path.tscn"
