extends RefCounted
class_name NereisEndingEvaluator

# Ending routes depend on Resonance, truth-anchor items and exploration, never physical intimacy.
# 结局由鸣响、真相锚点道具与探索决定，绝不以身体结合为门槛。
const COSMIC_RESONANCE_THRESHOLD: int = 68
const PARADISE_TRACE_SOURCE: String = "anomaly_observer_reaction"
const REQUIRED_ARTIFACT_PIECES: int = 3
const REQUIRED_HIDDEN_REGIONS_FOR_FIRE: int = 2


# Resolve the autoload through the active SceneTree rather than a parser-time global identifier.
# This keeps the evaluator loadable from Godot's --script acceptance harness as well as normal scenes.
# 通过当前 SceneTree 解析单例，避免 --script 验收入口解析全局标识时的加载顺序问题。
static func _world_state() -> Node:
	var main_loop := Engine.get_main_loop()
	if not (main_loop is SceneTree):
		return null
	return (main_loop as SceneTree).root.get_node_or_null("WorldState")


static func get_candidate() -> String:
	var state := _world_state()
	if state == null:
		return "凡人之墓"

	var resonance := int(state.get("hero_resonance"))
	var pieces := int(state.get("hidden_artifact_pieces"))
	var entered_regions: Array = state.get("entered_hidden_regions")
	var sources: Array = state.get("resonance_sources")
	var explored := entered_regions.size()
	var has_outer_trace := PARADISE_TRACE_SOURCE in sources

	if resonance >= COSMIC_RESONANCE_THRESHOLD and pieces >= REQUIRED_ARTIFACT_PIECES and explored >= REQUIRED_HIDDEN_REGIONS_FOR_FIRE:
		return "烈火天罚"

	if resonance >= COSMIC_RESONANCE_THRESHOLD and has_outer_trace and explored >= 1:
		return "永恒乐园"

	return "凡人之墓"


static func get_candidate_reason() -> String:
	var state := _world_state()
	if state == null:
		return "WorldState is unavailable; the human political ending remains the safe fallback."

	var resonance := int(state.get("hero_resonance"))
	var pieces := int(state.get("hidden_artifact_pieces"))
	var entered_regions: Array = state.get("entered_hidden_regions")
	var sources: Array = state.get("resonance_sources")
	var explored := entered_regions.size()
	var has_outer_trace := PARADISE_TRACE_SOURCE in sources

	if resonance < COSMIC_RESONANCE_THRESHOLD:
		return "Resonance %d/%d: the Hero has not become a strong enough signal; the human political ending remains." % [resonance, COSMIC_RESONANCE_THRESHOLD]
	if pieces >= REQUIRED_ARTIFACT_PIECES and explored >= REQUIRED_HIDDEN_REGIONS_FOR_FIRE:
		return "High Resonance, %d truth anchors, and %d hidden regions explored preserve the Hero's agency." % [pieces, explored]
	if has_outer_trace and explored >= 1:
		return "High Resonance and the recorded Observer Reaction, but no complete resistance anchor: the vessel path is open."
	return "High Resonance alone is insufficient; the required Outer-God trace or deep exploration is missing."
