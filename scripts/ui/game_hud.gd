extends CanvasLayer

var hero: Node
var debug_enabled := true
var debug_panel: ColorRect
var debug_label: Label
var title_label: Label
var controls_label: Label
var region_label: Label
var boss: Node
var boss_panel: ColorRect
var boss_bar: ColorRect
var boss_title: Label
var status_panel: ColorRect
var hp_bar: ColorRect
var stamina_bar: ColorRect
var hp_label: Label
var stamina_label: Label

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

    status_panel = ColorRect.new()
    status_panel.position = Vector2(36, 630)
    status_panel.size = Vector2(330, 70)
    status_panel.color = Color("#0a090d", 0.78)
    add_child(status_panel)

    hp_label = Label.new()
    hp_label.position = Vector2(12, 7)
    hp_label.add_theme_font_size_override("font_size", 13)
    status_panel.add_child(hp_label)

    var hp_bg := ColorRect.new()
    hp_bg.position = Vector2(72, 10)
    hp_bg.size = Vector2(235, 10)
    hp_bg.color = Color("#2a2026")
    status_panel.add_child(hp_bg)

    hp_bar = ColorRect.new()
    hp_bar.position = Vector2(72, 10)
    hp_bar.size = Vector2(235, 10)
    hp_bar.color = Color("#a4505a")
    status_panel.add_child(hp_bar)

    stamina_label = Label.new()
    stamina_label.position = Vector2(12, 37)
    stamina_label.add_theme_font_size_override("font_size", 13)
    status_panel.add_child(stamina_label)

    var stamina_bg := ColorRect.new()
    stamina_bg.position = Vector2(72, 40)
    stamina_bg.size = Vector2(235, 10)
    stamina_bg.color = Color("#2a2026")
    status_panel.add_child(stamina_bg)

    stamina_bar = ColorRect.new()
    stamina_bar.position = Vector2(72, 40)
    stamina_bar.size = Vector2(235, 10)
    stamina_bar.color = Color("#9e8b72")
    status_panel.add_child(stamina_bar)

    boss_panel = ColorRect.new()
    boss_panel.position = Vector2(390, 24)
    boss_panel.size = Vector2(500, 54)
    boss_panel.color = Color("#0a090d", 0.88)
    boss_panel.visible = false
    add_child(boss_panel)

    boss_title = Label.new()
    boss_title.position = Vector2(16, 7)
    boss_title.text = "ASHEN KNIGHT"
    boss_title.add_theme_font_size_override("font_size", 15)
    boss_panel.add_child(boss_title)

    boss_bar = ColorRect.new()
    boss_bar.position = Vector2(16, 31)
    boss_bar.size = Vector2(468, 10)
    boss_bar.color = Color("#9e5961")
    boss_panel.add_child(boss_bar)

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

func bind_boss(target: Node) -> void:
    boss = target

func set_debug_visible(value: bool) -> void:
    debug_enabled = value
    debug_panel.visible = value

func _process(_delta: float) -> void:
    _update_status_bars()
    _update_boss_bar()
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
        + "Location: %s\n" % WorldState.current_location
        + "Route: %s\n" % WorldState.selected_route
        + "Clues: %d\n" % WorldState.interior_clues_seen.size()
        + "Boss Defeated: %s\n" % WorldState.boss_defeated
        + "Route Complete: %s\n" % WorldState.route_complete
        + "Slice Complete: %s" % WorldState.slice_complete
    )

    
func _update_status_bars() -> void:
    if not hero or not is_instance_valid(hero):
        return
    var hp := clamp(int(hero.get("health")), 0, 100)
    var stamina := clamp(float(hero.get("stamina")), 0.0, 100.0)
    hp_bar.size.x = 235.0 * float(hp) / 100.0
    stamina_bar.size.x = 235.0 * stamina / 100.0
    hp_label.text = "HP %d" % hp
    stamina_label.text = "STA %d" % int(stamina)

func _update_boss_bar() -> void:
    if not boss or not is_instance_valid(boss) or boss.is_queued_for_deletion() or WorldState.boss_defeated:
        boss_panel.visible = false
        return

    if not hero or hero.global_position.distance_to(boss.global_position) > 720.0:
        boss_panel.visible = false
        return

    var hp := int(boss.get("health"))
    var ratio := clamp(float(hp) / 240.0, 0.0, 1.0)
    boss_panel.visible = true
    boss_bar.size.x = 468.0 * ratio
