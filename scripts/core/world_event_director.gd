extends Node
## Data-driven world event hooks shared by hub scenes.
## Event definitions live in EVENT_DEFINITIONS; conditions are facts, not narrative decisions.
## Future scenes may call dispatch() after a state change without embedding story branches.

signal event_triggered(event_id: String, payload: Dictionary)

const NPC_DEFINITIONS: Array[Dictionary] = [
]

const EVENT_DEFINITIONS: Array[Dictionary] = [
	{
		"id": "A1_tavern_sound_notice",
		"trigger": "interaction",
		"region": "A1",
		"interaction_id": "tavern",
		"once": true,
		"conditions": [{"type": "flag_absent", "value": "A1_tavern_sound_noticed"}],
		"effects": [{"type": "add_flag", "value": "A1_tavern_sound_noticed"}]
	}
]

var _world_state: Variant
var _host: Node
var _dispatching := false
var _managed_npcs: Array[Node] = []

func setup(world_state: Variant, host: Node) -> void:
	_world_state = world_state
	_host = host

func spawn_npcs(host: Node, npc_script: Script, interaction_callback: Callable) -> Array[Node]:
	# Refresh only director-managed NPCs; baseline NPCs are owned by the scene controller.
	for old_npc in _managed_npcs:
		if is_instance_valid(old_npc):
			if old_npc.get_parent() != null:
				old_npc.get_parent().remove_child(old_npc)
			old_npc.queue_free()
	_managed_npcs.clear()
	var spawned: Array[Node] = []
	for definition in NPC_DEFINITIONS:
		var npc_id := String(definition.get("id", ""))
		if npc_id.is_empty() or not _conditions_met(definition.get("conditions", [])):
			continue
		var absent_flag := String(definition.get("required_flag_absent", ""))
		if not absent_flag.is_empty() and absent_flag in _world_state.achievement_flags:
			continue
		var npc := Node2D.new()
		npc.set_script(npc_script)
		npc.name = npc_id
		npc.npc_id = npc_id
		npc.position = definition.get("position", Vector2.ZERO)
		npc.display_name = String(definition.get("display_name", npc_id))
		npc.dialogue = _resolve_dialogue(definition)
		host.add_child(npc)
		npc.interacted.connect(interaction_callback.bind(npc))
		spawned.append(npc)
		_managed_npcs.append(npc)
	return spawned

func _resolve_dialogue(definition: Dictionary) -> String:
	# Variants are ordered from most specific to least specific; first match wins.
	for variant in definition.get("dialogue_variants", []):
		if variant is Dictionary and _conditions_met(variant.get("conditions", [])):
			var text := String(variant.get("dialogue", ""))
			if not text.is_empty():
				return text
	return String(definition.get("dialogue", ""))

func dispatch(trigger: String, context: Dictionary = {}) -> Array[String]:
	var fired: Array[String] = []
	if _dispatching or _world_state == null:
		return fired
	_dispatching = true
	for definition in EVENT_DEFINITIONS:
		if String(definition.get("trigger", "")) != trigger:
			continue
		if not _matches_context(definition, context):
			continue
		var event_id := String(definition.get("id", ""))
		if event_id.is_empty() or not _conditions_met(definition.get("conditions", [])):
			continue
		if bool(definition.get("once", true)) and _was_fired(event_id):
			continue
		var payload := {"event_id": event_id, "context": context.duplicate(true)}
		_apply_effects(definition.get("effects", []))
		if bool(definition.get("once", true)):
			_mark_fired(event_id)
		event_triggered.emit(event_id, payload)
		fired.append(event_id)
	_dispatching = false
	return fired

func _matches_context(definition: Dictionary, context: Dictionary) -> bool:
	for key in ["region", "interaction_id"]:
		var expected := String(definition.get(key, ""))
		if not expected.is_empty() and String(context.get(key, "")) != expected:
			return false
	return true

func _conditions_met(conditions: Array) -> bool:
	for condition in conditions:
		if not condition is Dictionary or not _condition_met(condition):
			return false
	return true

func _condition_met(condition: Dictionary) -> bool:
	var kind := String(condition.get("type", ""))
	var value := String(condition.get("value", ""))
	match kind:
		"flag":
			return value in _world_state.achievement_flags
		"flag_absent":
			return not value in _world_state.achievement_flags
		"route":
			return String(_world_state.selected_route) == value
		"humanity_state":
			return String(_world_state.get_humanity_state()) == value
		"region_entered":
			return value in _world_state.entered_hidden_regions or String(_world_state.current_location) == value
		"location":
			return String(_world_state.current_location) == value
		"flag_count_at_least":
			var count := 0
			for flag in _world_state.achievement_flags:
				if String(flag).begins_with(value):
					count += 1
			return count >= int(condition.get("count", 1))
		"item_count_at_least":
			return int(_world_state.inventory_items.get(value, 0)) >= int(condition.get("count", 1))
		"item_collected":
			return value in _world_state.collected_world_item_ids
		"item_read":
			return value in _world_state.read_item_ids
		"custom_method":
			var method_name := String(condition.get("method", ""))
			return _world_state.has_method(method_name) and bool(_world_state.call(method_name))
		_:
			push_warning("[WorldEventDirector] Unknown condition type: %s" % kind)
			return false

func _apply_effects(effects: Array) -> void:
	for effect in effects:
		if not effect is Dictionary:
			continue
		var kind := String(effect.get("type", ""))
		var value := String(effect.get("value", ""))
		match kind:
			"add_flag":
				if not value.is_empty() and not value in _world_state.achievement_flags:
					_world_state.achievement_flags.append(value)
					_world_state.save_game()
			"remove_flag":
				if value in _world_state.achievement_flags:
					_world_state.achievement_flags.erase(value)
					_world_state.save_game()
			"emit_signal":
				# Named gameplay effects are deliberately delegated to listeners.
				pass
			_:
				push_warning("[WorldEventDirector] Unknown effect type: %s" % kind)

func _was_fired(event_id: String) -> bool:
	return ("world_event_fired:" + event_id) in _world_state.achievement_flags

func _mark_fired(event_id: String) -> void:
	var marker := "world_event_fired:" + event_id
	if not marker in _world_state.achievement_flags:
		_world_state.achievement_flags.append(marker)
		_world_state.save_game()
