extends Node2D

const HERO_SCRIPT = preload("res://scripts/player/hero.gd")
const ENEMY_SCRIPT = preload("res://scripts/enemies/cultist.gd")

var hero: CharacterBody2D
var enemy: CharacterBody2D

func _ready() -> void:
    hero = CharacterBody2D.new()
    hero.set_script(HERO_SCRIPT)
    hero.position = Vector2(320, 500)
    add_child(hero)

    enemy = CharacterBody2D.new()
    enemy.set_script(ENEMY_SCRIPT)
    enemy.position = Vector2(850, 500)
    add_child(enemy)

    queue_redraw()

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color("#111018"))
    draw_rect(Rect2(0, 520, 1280, 200), Color("#201c22"))
    for x in range(0, 1280, 64):
        draw_line(Vector2(x, 520), Vector2(x + 32, 552), Color("#302a30"), 2.0)

    draw_string(ThemeDB.fallback_font, Vector2(40, 55), "NEREIS HERO // VERTICAL SLICE 001", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#d6c7b2"))
    draw_string(ThemeDB.fallback_font, Vector2(40, 88), "A/D Move   Space Jump   J / LMB Attack   K / Shift Dodge", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#9b9189"))
    draw_string(ThemeDB.fallback_font, Vector2(40, 125), "The village remembers what the hero has forgotten.", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#8e7777"))
