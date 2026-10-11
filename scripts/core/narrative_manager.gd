extends CanvasLayer

signal message_finished

var panel: ColorRect
var title_label: Label
var body_label: Label
var timer := 0.0
var choice_active := false
var skip_label: Label
var continue_button: Button
var paused_for_narrative := false
var blocks_input := true

func _mark_input_handled() -> void:
    var viewport := get_viewport()
    if viewport:
        viewport.set_input_as_handled()

func _ready() -> void:
    layer = 20
    process_mode = Node.PROCESS_MODE_ALWAYS

    panel = ColorRect.new()
    panel.color = Color("#0a090d", 0.94)
    panel.position = Vector2(170, 500)
    panel.size = Vector2(940, 150)
    panel.visible = false
    add_child(panel)

    title_label = Label.new()
    title_label.position = Vector2(28, 18)
    title_label.add_theme_font_size_override("font_size", 22)
    title_label.text = "记忆"
    panel.add_child(title_label)

    body_label = Label.new()
    body_label.position = Vector2(28, 58)
    body_label.size = Vector2(880, 75)
    body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body_label.add_theme_font_size_override("font_size", 19)
    panel.add_child(body_label)

    skip_label = Label.new()
    skip_label.position = Vector2(28, 126)
    skip_label.size = Vector2(880, 20)
    skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    skip_label.add_theme_font_size_override("font_size", 12)
    skip_label.add_theme_color_override("font_color", Color("#756d72"))
    skip_label.text = NereisLocalization.t("narrative.skip")
    panel.add_child(skip_label)

    continue_button = Button.new()
    continue_button.position = Vector2(730, 116)
    continue_button.size = Vector2(170, 28)
    continue_button.add_theme_font_size_override("font_size", 13)
    continue_button.text = NereisLocalization.t("narrative.continue")
    continue_button.pressed.connect(_finish_message)
    panel.add_child(continue_button)

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
        show_message("老猎人", "这段记忆，你已经听过了。")
        return

    WorldState.unlock_first_memory()
    show_message(
        "A 记忆 THAT DOES NOT FEEL LIKE YOURS",
        "The old hunter looks at your face and goes pale.\n\n\"You used to come here before the church took you. You always asked whether the song was still playing.\"\n\nSomewhere beyond the village, a lullaby answers.",
        8.0
    )
    print("[NEREIS][STORY] First memory event displayed")

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
    show_message("更稳的握法", "老猎人纠正了你的架势。\n\n“你一直像记得自己如何死去一样战斗。”\n\n如今，你的剑刃更加致命。")
    print("[NEREIS][STORY] First weapon upgrade delivered")
