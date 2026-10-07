extends Node

func route_candidate() -> String:
    var candidate := NereisEndingEvaluator.get_candidate()
    print("[NEREIS][ENDING] Candidate route=%s reason=%s" % [
        candidate,
        NereisEndingEvaluator.get_candidate_reason()
    ])

    match candidate:
        "烈火天罚":
            return "res://scenes/ending_fire_demo.tscn"
        "永恒乐园":
            return "res://scenes/ending_paradise_demo.tscn"
        _:
            return "res://scenes/church_final_demo.tscn"
