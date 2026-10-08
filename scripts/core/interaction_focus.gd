extends RefCounted
class_name NereisInteractionFocus

const GROUP := "nereis_interaction"
const TIE_DISTANCE := 28.0

static func sync(node: Node2D, available: bool, priority: int = 0) -> void:
    node.set_meta("interaction_available", available)
    node.set_meta("interaction_priority", priority)

    if available:
        if not node.is_in_group(GROUP):
            node.add_to_group(GROUP)
    elif node.is_in_group(GROUP):
        node.remove_from_group(GROUP)

static func is_focused(node: Node2D) -> bool:
    if not bool(node.get_meta("interaction_available", false)):
        return false

    var hero := node.get_node_or_null("../Hero") as Node2D
    if hero == null:
        return false

    var best_node: Node2D = node
    var best_distance := node.global_position.distance_to(hero.global_position)
    var best_priority := int(node.get_meta("interaction_priority", 0))

    for candidate in node.get_tree().get_nodes_in_group(GROUP):
        if candidate == null or not is_instance_valid(candidate):
            continue
        if candidate == node or not bool(candidate.get_meta("interaction_available", false)):
            continue

        var other := candidate as Node2D
        if other == null:
            continue

        var distance := other.global_position.distance_to(hero.global_position)
        var priority := int(other.get_meta("interaction_priority", 0))
        var distance_gap := distance - best_distance

        if distance_gap < -TIE_DISTANCE:
            best_node = other
            best_distance = distance
            best_priority = priority
        elif absf(distance_gap) <= TIE_DISTANCE:
            if priority > best_priority or (priority == best_priority and distance < best_distance):
                best_node = other
                best_distance = distance
                best_priority = priority

    return best_node == node
