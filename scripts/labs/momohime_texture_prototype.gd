extends Node2D
## Texture-backed Momohime animation study. Uses the committed original sprite sheet.
## 真实精灵纹理驱动的独立动画实验，不替换正式 Hero。

const SHEET_PATH := "res://assets/characters/hero/153143.png"
const SOURCE_SIZE := Vector2i(2048, 1945)
const COLUMNS := 10
const ROWS := 8
const CELL_SIZE := Vector2(204.8, 243.125)
const DISPLAY_HEIGHT := 340.0

# Grid positions are provisional and intentionally kept in one place for later frame audit.
const SEQUENCES := {
	"idle": {"row": 0, "start": 0, "count": 10, "fps": 6.0, "loop": true},
	"walk": {"row": 2, "start": 0, "count": 6, "fps": 9.0, "loop": true},
	"slash": {"row": 4, "start": 0, "count": 10, "fps": 12.0, "loop": false},
}

var _sheet: Texture2D
var _sprite: Sprite2D
var _status: Label
var _sequence_name := "idle"
var _sequence_data: Dictionary = {}
var _frame := 0
var _elapsed := 0.0
var _playing := true
var _facing_left := false


func _ready() -> void:
	_build_stage()
	if not ResourceLoader.exists(SHEET_PATH):
		_status.text = "找不到百姬精灵表：\n" + SHEET_PATH
		return
	_sheet = load(SHEET_PATH) as Texture2D
	if _sheet == null:
		_status.text = "无法载入纹理：\n" + SHEET_PATH
		return
	if Vector2i(_sheet.get_width(), _sheet.get_height()) != SOURCE_SIZE:
		_status.text = "纹理尺寸与记录不符：%d×%d" % [_sheet.get_width(), _sheet.get_height()]
		return
	_set_sequence("idle")


func _process(delta: float) -> void:
	if _sheet == null or not _playing or _sequence_data.is_empty():
		return
	_elapsed += delta
	var duration := 1.0 / float(_sequence_data["fps"])
	while _elapsed >= duration:
		_elapsed -= duration
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
		KEY_R:
			_set_sequence(_sequence_name)
		KEY_LEFT:
			_facing_left = true
			_update_facing()
		KEY_RIGHT:
			_facing_left = false
			_update_facing()
	_update_status()


func _build_stage() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#17151b")
	backdrop.position = Vector2(-640, -720)
	backdrop.size = Vector2(1280, 1440)
	backdrop.z_index = -10
	add_child(backdrop)

	var floor := Line2D.new()
	floor.name = "Floor"
	floor.points = PackedVector2Array([Vector2(-540, 0), Vector2(540, 0)])
	floor.width = 2.0
	floor.default_color = Color("#887c77")
	add_child(floor)

	_sprite = Sprite2D.new()
	_sprite.name = "MomohimeTexture"
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.position = Vector2(0, -DISPLAY_HEIGHT * 0.5)
	add_child(_sprite)

	var camera := Camera2D.new()
	camera.position = Vector2(0, -150)
	add_child(camera)
	camera.make_current()

	var layer := CanvasLayer.new()
	add_child(layer)
	_status = Label.new()
	_status.position = Vector2(22, 18)
	_status.add_theme_font_size_override("font_size", 18)
	_status.add_theme_color_override("font_color", Color("#f7eee3"))
	layer.add_child(_status)


func _set_sequence(name: String) -> void:
	if _sheet == null or not SEQUENCES.has(name):
		return
	_sequence_name = name
	_sequence_data = SEQUENCES[name]
	_frame = 0
	_elapsed = 0.0
	_playing = true
	_update_frame()
	_update_status()


func _update_frame() -> void:
	var row := int(_sequence_data["row"])
	var col := int(_sequence_data["start"]) + _frame
	var atlas := AtlasTexture.new()
	atlas.atlas = _sheet
	atlas.region = Rect2(Vector2(col, row) * CELL_SIZE, CELL_SIZE)
	_sprite.texture = atlas
	_sprite.scale = Vector2.ONE * (DISPLAY_HEIGHT / CELL_SIZE.y)
	_update_facing()


func _update_facing() -> void:
	if _sprite != null:
		_sprite.flip_h = _facing_left


func _update_status() -> void:
	if _status == null:
		return
	var labels := {"idle": "待机", "walk": "移动", "slash": "挥刀"}
	_status.text = "百姬真实纹理动画原型 | %s | 帧 %d/%d\n1 待机  2 移动  3 挥刀  Space 暂停/播放  ←/→ 朝向  R 重播\n注意：等分网格和动作行仍为暂定，下一步需逐帧校准。" % [
		str(labels.get(_sequence_name, _sequence_name)), _frame + 1, int(_sequence_data.get("count", 0))
	]
