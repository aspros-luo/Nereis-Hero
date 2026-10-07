extends CanvasLayer

var panel: ColorRect
var title_label: Label
var body_label: Label
var timer := 0.0

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
    if not panel.visible:
        return
    timer -= delta
    if timer <= 0.0:
        panel.visible = false
        print("[NEREIS][STORY] Memory display ended")

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
