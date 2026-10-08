extends RefCounted
class_name NereisInteractionFocus

const GROUP := "nereis_interaction"

static func sync(node: Node2D, available: bool) -> void:
    if available:
        if not node.is_in_group(GROUP):
            node.add_to_group(GROUP)
        node.set_meta("interaction_available", true)
    else:
        node.set_meta("interaction_available", false)
        if node.is_in_group(GROUP):
            node.remove_from_group(GROUP)

static func is_focused(node: Node2D) -> bool:
    if not bool(node.get_meta("interaction_available", false)):
        return false

    var hero := node.get_node_or_null("../Hero") as Node2D
    if hero == null:
        return false

    var candidate_distance := node.global_position.distance_to(hero.global_position)
    var best_node: Node2D = node
    var best_distance := candidate_distance

    for candidate in node.get_tree().get_nodes_in_group(GROUP):
        if candidate == null or not is_instance_valid(candidate):
            continue
        if candidate == node or not bool(candidate.get_meta("interaction_available", false)):
            continue

        var other := candidate as Node2D
        if other == null:
            continue

        var distance := other.global_position.distance_to(hero.global_position)
        if distance + 1.0 < best_distance:
            best_node = other
            best_distance = distance

    return best_node == node
