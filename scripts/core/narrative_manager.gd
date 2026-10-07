extends CanvasLayer

var panel: ColorRect
var title_label: Label
var body_label: Label
var timer := 0.0
var choice_active := false

func _ready() -> void:
    layer = 20

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

func _process(delta: float) -> void:
    if not panel.visible or choice_active:
        return
    timer -= delta
    if timer <= 0.0:
        panel.visible = false
        print("[NEREIS][STORY] Narrative display ended")

func _unhandled_input(event: InputEvent) -> void:
    if not choice_active:
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
    title_label.text = "A MEMORY THAT DOES NOT FEEL LIKE YOURS"
    body_label.text = "The old hunter looks at your face and goes pale.\n\n"You used to come here before the church took you. You always asked whether the song was still playing."\n\nSomewhere beyond the village, a lullaby answers."
    panel.visible = true
    timer = 8.0
    print("[NEREIS][STORY] First memory event displayed")

func show_message(title: String, message: String) -> void:
    title_label.text = title
    body_label.text = message
    panel.visible = true
    timer = 4.0

    
func begin_first_choice() -> void:
    choice_active = true
    title_label.text = "THE ROAD REMEMBERS YOU"
    body_label.text = "Inside the fallen armor you find a church seal.\n\nFrom the village, the lullaby begins again. You can follow the seal, or follow the song.\n\n[1] Follow the church seal\n[2] Follow the lullaby"
    panel.visible = true
    timer = 0.0
    print("[NEREIS][STORY] First choice opened")

func _select_choice(choice: int) -> void:
    choice_active = false
    WorldState.make_first_choice(choice)
    if choice == 1:
        show_message("THE CHURCH SEAL", "You close your hand around the seal.\n\nThe metal is warm. Someone, somewhere, expected you to come back.")
    else:
        show_message("THE LULLABY", "You turn toward the song.\n\nFor one heartbeat, you remember the village before the church found you.")
    print("[NEREIS][STORY] First choice resolved=%d" % choice)
    get_viewport().set_input_as_handled()
