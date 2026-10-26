extends CanvasLayer

signal message_finished

@onready var panel: ColorRect = $Panel
@onready var title_label: Label = $Panel/TitleLabel
@onready var body_label: Label = $Panel/BodyLabel
var timer := 0.0
var choice_active := false
@onready var skip_label: Label = $Panel/SkipLabel
@onready var continue_button: Button = $Panel/ContinueButton
var paused_for_narrative := false
var blocks_input := true

func _mark_input_handled() -> void:
    var viewport := get_viewport()
    if viewport:
        viewport.set_input_as_handled()

func _ready() -> void:
	continue_button.pressed.connect(_finish_message)
func _process(delta: float) -> void:
    if not panel.visible:
        return
    if choice_active:
        return
    timer -= delta
    if timer <= 0.0:
        _finish_message()

func _finish_message() -> void:
    timer = 0.0
    panel.visible = false
    continue_button.visible = false
    choice_active = false
    blocks_input = true
    WorldState.input_locked = false
    get_tree().paused = false
    paused_for_narrative = false
    print("[NEREIS][STORY] Narrative display ended")
    message_finished.emit()

func _unhandled_input(event: InputEvent) -> void:
    if not panel.visible or not blocks_input:
        return

    if not choice_active:
        if event is InputEventKey and event.pressed and not event.echo:
            if event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_ESCAPE, KEY_J]:
                _finish_message()
                var viewport := get_viewport()
                if viewport:
                    viewport.set_input_as_handled()
                return
        if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
            _finish_message()
            _mark_input_handled()
            return
        return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_1:
            _select_choice(1)
        elif event.keycode == KEY_2:
            _select_choice(2)

func play_first_memory() -> void:
    if WorldState.first_memory_unlocked:
        show_message("老猎人", "那首歌……你以前总要问我，它还在不在。")
        return

    WorldState.unlock_first_memory()
    # Keep this as the old hunter's own recollection. Do not narrate his facial reaction
    # or use an off-screen lullaby as an omniscient explanation.
    show_message(
        "老猎人",
        "教会带走你之前，你常来这里。你每次都会问，那首歌是否还在继续。",
        5.0
    )
    print("[NEREIS][STORY] First memory dialogue displayed")

func show_message(title: String, message: String, duration: float = 4.0) -> void:
    NereisInteractionFocus.clear_all(get_tree())
    if panel.visible:
        _finish_message()
    title_label.text = NereisLocalization.translate_text(title)
    body_label.text = NereisLocalization.translate_text(message)
    skip_label.text = NereisLocalization.t("narrative.skip")
    continue_button.text = NereisLocalization.t("narrative.continue")
    continue_button.visible = true
    panel.visible = true
    blocks_input = true
    WorldState.input_locked = true
    timer = duration
    if not get_tree().paused:
        get_tree().paused = true
        paused_for_narrative = true

    
func show_caption(title: String, message: String, duration: float = 2.5) -> void:
    NereisInteractionFocus.clear_all(get_tree())
    get_tree().paused = false
    WorldState.input_locked = false
    paused_for_narrative = false
    if panel.visible:
        _finish_message()
    title_label.text = NereisLocalization.translate_text(title)
    body_label.text = NereisLocalization.translate_text(message)
    skip_label.text = ""
    continue_button.visible = false
    panel.visible = true
    blocks_input = false
    choice_active = false
    WorldState.input_locked = false
    timer = duration

func begin_first_choice() -> void:
    choice_active = true
    blocks_input = true
    if not get_tree().paused:
        get_tree().paused = true
        paused_for_narrative = true
    title_label.text = NereisLocalization.translate_text("道路记得你")
    body_label.text = NereisLocalization.translate_text("你在倒下的铠甲中找到一枚教会印记。\n\n村庄方向再次传来摇篮曲。你可以追随印记，也可以循着歌声前行。\n\n[1] 追随教会印记\n[2] 追随摇篮曲")
    continue_button.visible = false
    panel.visible = true
    WorldState.input_locked = true
    timer = 0.0
    print("[NEREIS][STORY] First choice opened")

func _select_choice(choice: int) -> void:
    choice_active = false
    if paused_for_narrative:
        get_tree().paused = false
        paused_for_narrative = false
    WorldState.make_first_choice(choice)
    if choice == 1:
        show_message("教会印记", "你将印记握在掌心。\n\n金属仍有温度。某个地方的某个人，早已料到你会回来。")
    else:
        show_message("摇篮曲", "你转向歌声传来的方向。\n\n有那么一瞬间，你想起了教会找到你之前的村庄。")
    print("[NEREIS][STORY] First choice resolved=%d" % choice)
    _mark_input_handled()

 
func play_weapon_upgrade() -> void:
    if WorldState.weapon_level >= 2:
        show_message("老猎人", "这把刀暂时已经足够锋利。")
        return
    WorldState.upgrade_weapon()
    show_message("老猎人", "手腕放松。肩膀别先送出去。", 3.0)
    print("[NEREIS][STORY] First weapon upgrade delivered")
