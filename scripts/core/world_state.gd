extends Node

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
var church_alignment := 0
var lullaby_resonance := 0
var first_choice_made := false

func unlock_first_memory() -> void:
    if first_memory_unlocked:
        return
    first_memory_unlocked = true
    hero_memory += 1
    print("[NEREIS][STORY] First memory unlocked; hero_memory=%d" % hero_memory)

func set_checkpoint(position: Vector2) -> void:
    checkpoint_position = position
    checkpoint_active = true
    print("[NEREIS][WORLD] Checkpoint activated at %s" % checkpoint_position)

func open_boss_gate() -> void:
    if boss_gate_open:
        return
    boss_gate_open = true
    print("[NEREIS][WORLD] Boss gate state recorded as open")

func make_first_choice(choice: int) -> void:
    if first_choice_made:
        return
    first_choice_made = true
    if choice == 1:
        church_alignment += 1
        print("[NEREIS][STORY] First choice: follow_church; church_alignment=%d" % church_alignment)
    else:
        lullaby_resonance += 1
        hero_memory += 1
        print("[NEREIS][STORY] First choice: follow_lullaby; lullaby_resonance=%d hero_memory=%d" % [lullaby_resonance, hero_memory])

func make_first_choice(choice: int) -> void:
    if first_choice_made:
        return
    first_choice_made = true
    if choice == 1:
        church_alignment += 1
        print("[NEREIS][STORY] First choice: follow_church; church_alignment=%d" % church_alignment)
    else:
        lullaby_resonance += 1
        hero_memory += 1
        print("[NEREIS][STORY] First choice: follow_lullaby; lullaby_resonance=%d hero_memory=%d" % [lullaby_resonance, hero_memory])

func mark_boss_defeated() -> void:
    if boss_defeated:
        return
    boss_defeated = true
    print("[NEREIS][BOSS] Ashen Knight victory recorded in WorldState")

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
    church_alignment = 0
    lullaby_resonance = 0
    first_choice_made = false
