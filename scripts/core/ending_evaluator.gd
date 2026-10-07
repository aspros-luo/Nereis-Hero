extends RefCounted
class_name NereisEndingEvaluator

# This evaluator intentionally reads facts, not hidden romance points.
# The final threshold for the multi-part artifact remains easy to change during narrative implementation.
const REQUIRED_ARTIFACT_PIECES := 3

static func get_candidate() -> String:
    if WorldState.physical_union_complete:
        if WorldState.hidden_artifact_pieces >= REQUIRED_ARTIFACT_PIECES:
            return "烈火天罚"
        return "永恒乐园"

    return "凡人之墓"

static func get_candidate_reason() -> String:
    if WorldState.physical_union_complete:
        if WorldState.hidden_artifact_pieces >= REQUIRED_ARTIFACT_PIECES:
            return "Union occurred, but enough hidden resistance knowledge remains."
        return "Union occurred without enough hidden resistance knowledge."

    if WorldState.mite_connection_missed or WorldState.mite_interactions_seen.size() < 3:
        return "Hero never reached the physical union state."

    return "Visible political progression remains the dominant path."
