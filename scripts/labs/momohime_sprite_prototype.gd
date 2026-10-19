extends Node2D
## Standalone sprite-sheet prototype. Does not replace the production Hero scene.
## 独立精灵表原型，不替换正式 Hero 场景。

const SHEET_PATH := "res://assets/art/hero_sprite_lab/153143.png"
const SOURCE_SIZE := Vector2i(2048, 1945)
const CELL_SIZE := Vector2i(204, 243)
const COLUMNS := 10
const ROWS := 8
const DISPLAY_HEIGHT := 210.0

# Provisional classifications based on the published sheet preview; verify against the
# downloaded full-resolution image before calling these final animation labels.
const SEQUENCES := {
	"idle": {"row": 0, "start": 0, "count": 10, "fps": 7.0, "loop": true},
	"walk": {"row": 2, "start": 0, "count": 6, "fps": 9.0, "loop": true},
	"slash": {"row": 4, "start": 0, "count": 10, "fps": 14.0, "loop": false},
}

var _sheet: Texture2D
var _sprite: Sprite2D
var _status: Label
var _sequence_name := "idle"
var _frame := 0
var _elapsed := 0.0
var _playing := true
var _sequence_data: Dictionary = {}

func _ready() -> void:
	_build_stage()
	if not ResourceLoader.exists(SHEET_PATH):
		_status.text = "百姬精灵表未找到\n请将下载的 153143.png 放到：\n" + SHEET_PATH
		return
	_sheet = load(SHEET_PATH) as Texture2D
	if _sheet == null:
		_status.text = "精灵表加载失败：" + SHEET_PATH
		return
	if _sheet.get_width() != SOURCE_SIZE.x or _sheet.get_height() != SOURCE_SIZE.y:
		_status.text = "尺寸不符：检测到 %d×%d，预期 %d×%d。请重新检查帧网格。" % [
			_sheet.get_width(), _sheet.get_height(), SOURCE_SIZE.x, SOURCE_SIZE.y
		]
		return
	_set_sequence("idle")
	_status.text = _help_text()

func _process(delta: float) -> void:
	if _sheet == null or not _playing or _sequence_data.is_empty():
		return
	_elapsed += delta
	var frame_time := 1.0 / float(_sequence_data["fps"])
	while _elapsed >= frame_time:
		_elapsed -= frame_time
		_frame += 1
		if _frame >= int(_sequence_data["count"]):
			if bool(_sequence_data["loop"]):
				_frame = 0
			else:
				_frame = int(_sequence_data["count"]) - 1
				_playing = false
		_update_frame()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1:
			_set_sequence("idle")
		KEY_2:
			_set_sequence("walk")
		KEY_3:
			_set_sequence("slash")
		KEY_SPACE:
			_playing = not _playing
		KEY_LEFT, KEY_RIGHT:
			if _sprite != null:
				_sprite.flip_h = event.keycode == KEY_LEFT
		KEY_R:
			_set_sequence(_sequence_name)

func _build_stage() -> void:
	var floor := Line2D.new()
	floor.name = "PrototypeFloor"
	floor.points = PackedVector2Array([Vector2(-420, 0), Vector2(420, 0)])
	floor.width = 3.0
	floor.default_color = Color("#8b7d70")
	add_child(floor)

	_sprite = Sprite2D.new()
	_sprite.name = "MomohimeSprite"
	_sprite.centered = true
	_sprite.position = Vector2(0, -DISPLAY_HEIGHT * 0.5)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)

	var layer := CanvasLayer.new()
	layer.name = "PrototypeUI"
	add_child(layer)
	_status = Label.new()
	_status.position = Vector2(20, 18)
	_status.add_theme_font_size_override("font_size", 18)
	_status.add_theme_color_override("font_color", Color("#f5eadb"))
	layer.add_child(_status)

	var camera := Camera2D.new()
	camera.position = Vector2.ZERO
	add_child(camera)
	camera.make_current()

func _set_sequence(name: String) -> void:
	if not SEQUENCES.has(name) or _sheet == null:
		return
	_sequence_name = name
	_sequence_data = SEQUENCES[name]
	_frame = 0
	_elapsed = 0.0
	_playing = true
	_update_frame()
	_status.text = _help_text()

func _update_frame() -> void:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = _sheet
	var source_row := int(_sequence_data["row"])
	var source_col := int(_sequence_data["start"]) + _frame
	atlas_texture.region = Rect2(
		Vector2(source_col * CELL_SIZE.x, source_row * CELL_SIZE.y),
		Vector2(CELL_SIZE)
	)
	_sprite.texture = atlas_texture
	var frame_height := float(CELL_SIZE.y)
	_sprite.scale = Vector2.ONE * (DISPLAY_HEIGHT / frame_height)
	# All cells retain a common baseline for this first pass; fine alignment follows alpha-bound analysis.
	_sprite.position.y = -DISPLAY_HEIGHT * 0.5 + 8.0

func _help_text() -> String:
	return "百姬精灵原型 | 动作：%s | 帧：%d/%d\n1 待机  2 移动(暂定)  3 挥刀(暂定)  Space 暂停/播放  ←/→ 翻转  R 重播\n网格：204×243；动作分类仍需逐帧复核，纹理部件图集已纳入后续骨骼拆件计划。" % [
		_sequence_name, _frame + 1, int(_sequence_data.get("count", 0))
	]
