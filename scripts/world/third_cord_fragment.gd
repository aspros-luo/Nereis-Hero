extends Node2D
## Optional ending-condition relic dropped by the ancient-god test subject.
## 古神实验体掉落的可选结局条件遗物。

signal collected

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

var hero_nearby := false
var animation_time := 0.0

func _ready() -> void:
	set_meta("interaction_priority", 35)
	set_meta("interaction_focus_position", global_position)
	queue_redraw()

func _process(delta: float) -> void:
	animation_time += delta
	var hero := get_node_or_null("../Hero") as Node2D
	hero_nearby = hero != null and global_position.distance_to(hero.global_position) <= 92.0
	set_meta("interaction_focus_position", global_position)
	INTERACTION_FOCUS_SCRIPT.sync(self, hero_nearby and not WorldState.input_locked, 35)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if (
		WorldState.input_locked
		or not hero_nearby
		or not INTERACTION_FOCUS_SCRIPT.is_focused(self)
	):
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		if WorldState.record_achievement("third_umbilical_cord_fragment_acquired"):
			WorldState.record_hidden_artifact_source("third_umbilical_cord_fragment")
			collected.emit()
			print("[NEREIS][ENDING] Third umbilical cord fragment acquired; hidden anchor added.")
		queue_free()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	var bob := sin(animation_time * 2.2) * 3.0
	# A pale cord curls around a fractured bone ring, suspended in a dim violet pulse.
	# 苍白脐带缠绕破裂骨环，悬浮在微弱紫色脉动中。
	draw_circle(Vector2(0.0, -24.0 + bob), 30.0, Color("#8d5f8d", 0.10))
	draw_circle(Vector2(0.0, -24.0 + bob), 20.0, Color("#9b72a4", 0.12))
	draw_arc(Vector2(0.0, -23.0 + bob), 17.0, 0.2, TAU - 0.4, 24, Color("#c9b6bd"), 3.0)
	draw_arc(Vector2(0.0, -24.0 + bob), 10.0, PI * 0.15, PI * 1.85, 18, Color("#d8c8c9"), 4.0)
	draw_line(Vector2(-5.0, -38.0 + bob), Vector2(7.0, -22.0 + bob), Color("#c7a3b9"), 3.0)
	draw_line(Vector2(7.0, -22.0 + bob), Vector2(-4.0, -11.0 + bob), Color("#c7a3b9"), 3.0)
	draw_circle(Vector2(0.0, -24.0 + bob), 3.0, Color("#e3c7df"))
	if hero_nearby and INTERACTION_FOCUS_SCRIPT.is_focused(self) and not WorldState.input_locked:
		draw_string(ThemeDB.fallback_font, Vector2(-54.0, 18.0), "E  拾取脐带残片", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("#e1c6df"))
