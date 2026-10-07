extends CanvasLayer

var hero: Node
var debug_enabled := true
var debug_panel: ColorRect
var debug_label: Label
var title_label: Label
var controls_label: Label
var region_label: Label

func _ready() -> void:
    layer = 10

    title_label = Label.new()
    title_label.position = Vector2(36, 26)
    title_label.text = "NEREIS HERO // VERTICAL SLICE 001"
    title_label.add_theme_font_size_override("font_size", 22)
    add_child(title_label)

    controls_label = Label.new()
    controls_label.position = Vector2(36, 62)
    controls_label.text = "A/D Move   Space Jump   J / LMB Attack   K / Shift Dodge   E Speak   F3 Debug   F9 Reset"
    controls_label.add_theme_font_size_override("font_size", 16)
    add_child(controls_label)

    region_label = Label.new()
    region_label.position = Vector2(36, 94)
    region_label.text = "The village remembers what the hero has forgotten."
    region_label.add_theme_font_size_override("font_size", 18)
    add_child(region_label)

    debug_panel = ColorRect.new()
    debug_panel.position = Vector2(930, 24)
    debug_panel.size = Vector2(326, 260)
    debug_panel.color = Color("#0a090d", 0.88)
    add_child(debug_panel)

    debug_label = Label.new()
    debug_label.position = Vector2(18, 14)
    debug_label.size = Vector2(290, 230)
    debug_label.add_theme_font_size_override("font_size", 15)
    debug_panel.add_child(debug_label)

func bind_hero(target: Node) -> void:
    hero = target

func set_debug_visible(value: bool) -> void:
    debug_enabled = value
    debug_panel.visible = value

func _process(_delta: float) -> void:
    if not debug_enabled or not hero:
        return

    var state_name := hero.get_debug_state()
    var hp := int(hero.get("health"))
    var stamina := int(hero.get("stamina"))
    var invulnerable := bool(hero.get("invulnerable"))

    debug_label.text = (
        "DEBUG [F3]\n"
        + "Hero HP: %d\n" % hp
        + "Stamina: %d\n" % stamina
        + "State: %s\n" % state_name
        + "Invulnerable: %s\n" % invulnerable
        + "Memory: %d\n" % WorldState.hero_memory
        + "Humanity: %d\n" % WorldState.hero_humanity
        + "Church Alignment: %d\n" % WorldState.church_alignment
        + "Lullaby Resonance: %d\n" % WorldState.lullaby_resonance
        + "Boss Defeated: %s\n" % WorldState.boss_defeated
        + "Slice Complete: %s" % WorldState.slice_complete
    )
