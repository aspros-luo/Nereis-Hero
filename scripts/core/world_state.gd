extends Node

var hero_memory := 0
var hero_humanity := 100
var first_memory_unlocked := false

func unlock_first_memory() -> void:
    if first_memory_unlocked:
        return
    first_memory_unlocked = true
    hero_memory += 1
    print("[NEREIS][STORY] First memory unlocked; hero_memory=%d" % hero_memory)

func reset() -> void:
    hero_memory = 0
    hero_humanity = 100
    first_memory_unlocked = false
