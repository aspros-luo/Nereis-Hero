extends Node2D

## Isolated sprite-sheet lab; it never replaces or controls the production Hero.
## 独立序列帧实验场景，不替换或控制正式 Hero。

const SHEET_PATH := "res://assets/art/hero_sprite_lab/muramasa_reference_sheet.png"
const FRAME_SIZE := Vector2i(204, 243)
const COLUMN_COUNT := 10
const ROW_COUNT := 8
const LAST_ROW_FRAME_COUNT := 4

@export_range(1.0, 24.0, 1.0) var playback_fps := 8.0
@export var sprite_scale := 0.85

var sheet: Texture2D
var sprite: Sprite2D
var frame_index := 0
var animation_row := 0
var elapsed := 0.0
var playing := true
var status_label: Label


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#17151b"))
	var camera := Camera2D.new()
	camera.position = Vector2.ZERO
	camera.zoom = Vector2(1.5, 1.5)
	add_child(camera)
	camera.make_current()

	sprite = Sprite2D.new()
	sprite.name = "SpriteFramePreview"
	sprite.centered = true
	sprite.position = Vector2(0, 10)
	sprite.scale = Vector2.ONE * sprite_scale
	add_child(sprite)

	var floor := Line2D.new()
	floor.name = "GroundGuide"
	floor.points = PackedVector2Array([Vector2(-160, 105), Vector2(160, 105)])
	floor.width = 2.0
	floor.default_color = Color("#665b65")
	add_child(floor)

	var layer := CanvasLayer.new()
	layer.name = "InstructionsLayer"
	add_child(layer)
	status_label = Label.new()
	status_label.position = Vector2(16, 14)
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color("#f4ead9"))
	layer.add_child(status_label)

	if not ResourceLoader.exists(SHEET_PATH):
		status_label.text = "Sprite Animation Lab / 序列帧实验场景\n\nSprite sheet not installed. / 尚未放入序列帧图片。\nCopy the uploaded 2048x1945 PNG to:\n" + SHEET_PATH + "\n\nThe production Hero is unchanged. / 正式 Hero 未被修改。"
		push_warning("Sprite lab sheet missing: " + SHEET_PATH)
		return

	sheet = load(SHEET_PATH) as Texture2D
	if sheet == null:
		status_label.text = "Failed to load sprite sheet. / 序列帧图片加载失败。"
		return
	sprite.texture = sheet
	_update_frame()
	_update_label()


func _process(delta: float) -> void:
	if sheet == null or not playing:
		return
	elapsed += delta
	var frame_duration := 1.0 / maxf(playback_fps, 1.0)
	while elapsed >= frame_duration:
		elapsed -= frame_duration
		frame_index = (frame_index + 1) % _frame_count_for_row(animation_row)
		_update_frame()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	var key: int = (event as InputEventKey).keycode
	if key >= KEY_1 and key <= KEY_8:
		animation_row = key - KEY_1
		_select_row()
	elif key == KEY_SPACE:
		playing = not playing
		_update_label()
	elif key == KEY_LEFT:
		frame_index = posmod(frame_index - 1, _frame_count_for_row(animation_row))
		playing = false
		_update_frame()
	elif key == KEY_RIGHT:
		frame_index = (frame_index + 1) % _frame_count_for_row(animation_row)
		playing = false
		_update_frame()
	elif key == KEY_UP:
		animation_row = posmod(animation_row - 1, ROW_COUNT)
		_select_row()
	elif key == KEY_DOWN:
		animation_row = (animation_row + 1) % ROW_COUNT
		_select_row()
	elif key == KEY_R:
		frame_index = 0
		elapsed = 0.0
		playing = true
		_update_frame()

	get_viewport().set_input_as_handled()

func _select_row() -> void:
	frame_index = 0
	elapsed = 0.0
	_update_frame()


func _frame_count_for_row(row: int) -> int:
	return LAST_ROW_FRAME_COUNT if row == ROW_COUNT - 1 else COLUMN_COUNT


func _update_frame() -> void:
	if sprite == null or sheet == null:
		return
	sprite.region_enabled = true
	sprite.region_rect = Rect2(
		float(frame_index * FRAME_SIZE.x),
		float(animation_row * FRAME_SIZE.y),
		float(FRAME_SIZE.x),
		float(FRAME_SIZE.y)
	)
	_update_label()


func _update_label() -> void:
	if status_label == null:
		return
	status_label.text = "Sprite Animation Lab / 序列帧实验场景\nRow %d / 8   Frame %d / %d   %s\n\n1–8: select row | ↑/↓: change row\n←/→: step frame (pause) | Space: play/pause | R: restart\n\nGrid assumption: 204×243 px cells; verify each row visually.\n网格暂按 204×243 像素切分，需逐行动画验收。" % [
		animation_row + 1,
		frame_index + 1,
		_frame_count_for_row(animation_row),
		"Playing" if playing else "Paused"
	]
