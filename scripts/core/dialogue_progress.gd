extends RefCounted
## Shared, data-driven NPC dialogue progression.
## Entries are ordered by priority, then by their authored array order.

static func select_next(entries: Array[Dictionary], world_state: Node) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for index in range(entries.size()):
		var entry := entries[index]
		if _conditions_met(entry.get("conditions", []), world_state):
			var dialogue_id := String(entry.get("id", "")).strip_edges()
			if not dialogue_id.is_empty() and not world_state.has_read_dialogue(dialogue_id):
				var candidate := entry.duplicate(true)
				candidate["_order"] = index
				candidates.append(candidate)
	if candidates.is_empty():
		for entry in entries:
			if bool(entry.get("repeat", false)) and _conditions_met(entry.get("conditions", []), world_state):
				return entry.duplicate(true)
		return {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var priority_a := int(a.get("priority", 0))
		var priority_b := int(b.get("priority", 0))
		if priority_a == priority_b:
			return int(a.get("_order", 0)) < int(b.get("_order", 0))
		return priority_a > priority_b
	)
	var selected := candidates[0]
	selected.erase("_order")
	return selected

static func _conditions_met(conditions: Array, world_state: Node) -> bool:
	for condition in conditions:
		if not condition is Dictionary:
			return false
		var kind := String(condition.get("type", ""))
		var value := String(condition.get("value", ""))
		match kind:
			"flag":
				if value not in world_state.achievement_flags:
					return false
			"flag_absent":
				if value in world_state.achievement_flags:
					return false
			"location":
				if String(world_state.current_location) != value:
					return false
			"room_explored":
				if not world_state.is_room_explored(value):
					return false
			_:
				push_warning("[DialogueProgress] Unknown condition type: %s" % kind)
				return false
	return true
