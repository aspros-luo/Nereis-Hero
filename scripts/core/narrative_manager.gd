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

func _mark_input_handled() -> void:        _mark_input_handled()

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
    title_label.text = "MEMORY"
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
                _finish_message()        _mark_input_handled()
                return
        if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
            _finish_message()        _mark_input_handled()
            return
        return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_1:
            _select_choice(1)
        elif event.keycode == KEY_2:
            _select_choice(2)

func play_first_memory() -> void:
    if WorldState.first_memory_unlocked:
        show_message("OLD HUNTER", "You have already heard this memory.")
        return

    WorldState.unlock_first_memory()
    show_message(
        "A MEMORY THAT DOES NOT FEEL LIKE YOURS",
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
    title_label.text = NereisLocalization.translate_text("THE ROAD REMEMBERS YOU")
    body_label.text = NereisLocalization.translate_text("Inside the fallen armor you find a church seal.\n\nFrom the village, the lullaby begins again. You can follow the seal, or follow the song.\n\n[1] Follow the church seal\n[2] Follow the lullaby")
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
        show_message("THE CHURCH SEAL", "You close your hand around the seal.\n\nThe metal is warm. Someone, somewhere, expected you to come back.")
    else:
        show_message("THE LULLABY", "You turn toward the song.\n\nFor one heartbeat, you remember the village before the church found you.")
    print("[NEREIS][STORY] First choice resolved=%d" % choice)        _mark_input_handled()

 
func play_weapon_upgrade() -> void:
    if WorldState.weapon_level >= 2:
        show_message("OLD HUNTER", "The blade is as sharp as it needs to be. For now.")
        return
    WorldState.upgrade_weapon()
    show_message("A BETTER GRIP", "The old hunter corrects your stance.\n\n\"You keep fighting like you remember dying.\"\n\nYour sword cuts deeper now.")
    print("[NEREIS][STORY] First weapon upgrade delivered")
