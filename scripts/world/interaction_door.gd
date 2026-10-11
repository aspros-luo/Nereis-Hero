extends Area2D

signal interacted

const INTERACTION_FOCUS_SCRIPT = preload("res://scripts/core/interaction_focus.gd")

@export var prompt_text: String = "E  Enter"
@export var enabled := true
@export var unlock_once_flag_id: String = ""
@export var opened_prompt_text: String = ""

var hero_nearby := false
var cooldown := 0.0

func _ready() -> void:
    collision_layer = 8
    collision_mask = 1
    monitoring = true
    set_meta("interaction_priority", 100)
    if not unlock_once_flag_id.is_empty() and unlock_once_flag_id in WorldState.achievement_flags and not opened_prompt_text.is_empty():
        prompt_text = opened_prompt_text
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    queue_redraw()

func _process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    # Proximity is physical state, not input state. Do not clear it during dialogue:
    # Area2D body_entered will not fire again if the Hero never leaves the trigger.
    # 距离状态与输入锁无关；对话期间不能清空距离，否则主角不离开触发区就不会再次收到 body_entered。
    var available := enabled and not WorldState.input_locked and hero_nearby and cooldown <= 0.0
    INTERACTION_FOCUS_SCRIPT.sync(self, available, 100)
    queue_redraw()

func _on_body_entered(body: Node) -> void:
    if body.name == "Hero":
        hero_nearby = true
        queue_redraw()

func _on_body_exited(body: Node) -> void:
    if body.name == "Hero":
        hero_nearby = false
        queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if WorldState.input_locked or not hero_nearby or cooldown > 0.0 or not INTERACTION_FOCUS_SCRIPT.is_focused(self):
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        cooldown = 0.6
        if not unlock_once_flag_id.is_empty() and unlock_once_flag_id not in WorldState.achievement_flags:
            WorldState.record_achievement(unlock_once_flag_id)
            if not opened_prompt_text.is_empty():
                prompt_text = opened_prompt_text
            print("[NEREIS][MAP] One-way hatch opened id=%s" % unlock_once_flag_id)
            queue_redraw()
            var opened_viewport := get_viewport()
            if opened_viewport:
                opened_viewport.set_input_as_handled()
            return
        interacted.emit()
        var viewport := get_viewport()
        if viewport:
            viewport.set_input_as_handled()

func _draw() -> void:
    if hero_nearby and not WorldState.input_locked and INTERACTION_FOCUS_SCRIPT.is_focused(self):
        draw_string(
            ThemeDB.fallback_font,
            Vector2(-54, 30),
            NereisLocalization.translate_text(prompt_text),
            HORIZONTAL_ALIGNMENT_LEFT,
            -1,
            16,
            Color("#d6c7b2")
        )
