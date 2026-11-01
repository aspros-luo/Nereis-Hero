extends Node
## Selects and records NPC dialogue progress. Presentation remains owned by NarrativeManager.
## 对话进度只负责选择与记录；画面展示仍由 NarrativeManager 负责。

const DIALOGUE_SETS: Dictionary = {
	"village_gatekeeper": {
		"entries": [
			{
				"id": "GK_INTRO_01",
				"priority": 30,
				"order": 10,
				"conditions": [],
				"title": "守门人",
				"text": "“新面孔。”\n\n“村里能歇脚的地方不多。要出去的话，先认清路，天黑以后雾会压得很低。”"
			},
			{
				"id": "GK_ROUTE_FOREST_01",
				"priority": 20,
				"order": 20,
				"conditions": [],
				"title": "守门人",
				"text": "“北边那片雾林，林子深处有座旧钟墓。”\n\n“我没进去过。小时候只远远见过那座塔，后来就很少有人提起了。”"
			},
			{
				"id": "GK_ROUTE_DRAIN_01",
				"priority": 20,
				"order": 30,
				"conditions": [],
				"title": "守门人",
				"text": "“村子右边还有条旧下水道。战争那会儿就被堵住了，后来也没人修。”\n\n“现在算是废弃了。里面什么样，我可说不上来。”"
			},
			{
				"id": "GK_ROUTE_BACKHILL_01",
				"priority": 20,
				"order": 40,
				"conditions": [],
				"title": "守门人",
				"text": "“后山那边……我小时候好像见过一条飞龙。”\n\n“那时离得远，天又快黑了。也可能只是看错了。反正这么多年，我没再见过。”"
			},
			{
				"id": "GK_FOREST_ENTERED",
				"priority": 80,
				"order": 10,
				"conditions": [{ "type": "room_explored", "value": "A2-R01" }],
				"title": "守门人",
				"text": "“你去过北边了？那片林子比我记得的还要静。”"
			},
			{
				"id": "GK_BELL_TOMB_EVIDENCE",
				"priority": 90,
				"order": 10,
				"conditions": [{ "type": "achievement", "value": "a1_gatekeeper_bell_tomb_evidence" }],
				"title": "守门人",
				"text": "“钟墓里面也有东西？我只知道它在那儿。里面的事，你比我清楚。”"
			},
			{
				"id": "GK_DRAIN_ENTERED",
				"priority": 80,
				"order": 20,
				"conditions": [{ "type": "achievement", "value": "old_drain_first_visit_seen" }],
				"title": "守门人",
				"text": "“你真进了那条旧排水道？我还以为它早就彻底塌了。里面的路还能走到哪儿，我就不知道了。”"
			},
			{
				"id": "GK_BACKHILL_ENTERED",
				"priority": 80,
				"order": 30,
				"conditions": [{ "type": "achievement", "value": "a1_gatekeeper_backhill_cliff_entered" }],
				"title": "守门人",
				"text": "“你去了后山？那地方现在还走得通？飞龙的事……我小时候说过吧。”"
			},
			{
				"id": "GK_DRAGON_EVIDENCE",
				"priority": 90,
				"order": 40,
				"conditions": [{ "type": "achievement", "value": "a1_gatekeeper_dragon_evidence" }],
				"title": "守门人",
				"text": "“你真找到了痕迹？……看来我小时候看到的，也许不是眼花。”"
			}
		],
		"repeat": {
			"id": "GK_REPEAT_01",
			"title": "守门人",
			"text": "“今天没什么新消息。看好脚下的路。”"
		}
	}
}

func get_next_dialogue(npc_id: String) -> Dictionary:
	var definition: Dictionary = DIALOGUE_SETS.get(npc_id, {})
	if definition.is_empty():
		return {}
	var entries: Array = definition.get("entries", [])
	var candidates: Array[Dictionary] = []
	for entry_value in entries:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		var dialogue_id := String(entry.get("id", ""))
		if dialogue_id.is_empty() or WorldState.read_dialogue_ids.has(_save_id(npc_id, dialogue_id)):
			continue
		if not _conditions_met(entry.get("conditions", [])):
			continue
		candidates.append(entry)
	if candidates.is_empty():
		return _with_npc_id(definition.get("repeat", {}), npc_id)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var priority_a := int(a.get("priority", 0))
		var priority_b := int(b.get("priority", 0))
		if priority_a == priority_b:
			return int(a.get("order", 0)) < int(b.get("order", 0))
		return priority_a > priority_b
	)
	return _with_npc_id(candidates[0], npc_id)

func mark_dialogue_completed(npc_id: String, dialogue_id: String) -> void:
	var save_id := _save_id(npc_id, dialogue_id)
	if dialogue_id.is_empty() or WorldState.read_dialogue_ids.has(save_id):
		return
	WorldState.read_dialogue_ids.append(save_id)
	WorldState.save_game()

func _save_id(npc_id: String, dialogue_id: String) -> String:
	return npc_id + ":" + dialogue_id

func _with_npc_id(entry_value: Variant, npc_id: String) -> Dictionary:
	if not entry_value is Dictionary or entry_value.is_empty():
		return {}
	var result: Dictionary = entry_value.duplicate(true)
	result["npc_id"] = npc_id
	return result

func _conditions_met(conditions: Array) -> bool:
	for condition_value in conditions:
		if not condition_value is Dictionary:
			return false
		var condition: Dictionary = condition_value
		match String(condition.get("type", "")):
			"achievement":
				if not String(condition.get("value", "")) in WorldState.achievement_flags:
					return false
			"location":
				if WorldState.current_location != String(condition.get("value", "")):
					return false
			"room_explored":
				if not WorldState.is_room_explored(String(condition.get("value", ""))):
					return false
			_:
				push_warning("[DialogueProgression] Unknown condition type: %s" % String(condition.get("type", "")))
				return false
	return true
