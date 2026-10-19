extends Node2D
## Inspect the committed packed character atlas and identify texture regions before rigging.
## 纹理拆件检查器：先定位图集部件，再制作真正的纹理骨骼角色。

const ATLAS_PATH := "res://assets/characters/hero/tex1_512x512_4d6c36bcbd5d9ddc_423915aa39e773f2_9.png"
const DISPLAY_WIDTH := 900.0
const GRID_STEP := 64

var _atlas: Texture2D
var _atlas_sprite: Sprite2D
var _overlay: Node2D
var _status: Label
var _zoom := 1.0
var _show_grid := true
var _selected := Rect2i()
var _drag_start := Vector2i(-1, -1)
var _drag_current := Vector2i(-1, -1)


func _ready() -> void:
	_build_ui()
	if not ResourceLoader.exists(ATLAS_PATH):
		_status.text = "找不到纹理图集：\n" + ATLAS_PATH
		return
	_atlas = load(ATLAS_PATH) as Texture2D
	if _atlas == null:
		_status.text = "无法加载 PNG 纹理图集。"
		return
	_atlas_sprite = Sprite2D.new()
	_atlas_sprite.texture = _atlas
	_atlas_sprite.centered = false
	_atlas_sprite.position = Vector2(20, 70)
	_atlas_sprite.scale = Vector2.ONE * _zoom
	add_child(_atlas_sprite)
	_overlay = Node2D.new()
	_overlay.position = _atlas_sprite.position
	add_child(_overlay)
	_update_status()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1600, 1200)
	bg.color = Color("#17151b")
	bg.z_index = -10
	add_child(bg)
	var layer := CanvasLayer.new()
	add_child(layer)
	_status = Label.new()
	_status.position = Vector2(18, 14)
	_status.add_theme_font_size_override("font_size", 16)
	_status.add_theme_color_override("font_color", Color("#f7eee3"))
	layer.add_child(_status)


func _unhandled_input(event: InputEvent) -> void:
	if _atlas == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_G:
				_show_grid = not _show_grid
				_redraw_overlay()
			KEY_EQUAL, KEY_KP_ADD:
				_zoom = minf(_zoom * 1.2, 3.0)
				_apply_zoom()
			KEY_MINUS, KEY_KP_SUBTRACT:
				_zoom = maxf(_zoom / 1.2, 0.35)
				_apply_zoom()
			KEY_C:
				_selected = Rect2i()
				_redraw_overlay()
			KEY_ENTER:
				DisplayServer.clipboard_set("Rect2(%d, %d, %d, %d)" % [_selected.position.x, _selected.position.y, _selected.size.x, _selected.size.y])
	_update_status()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_start = _to_atlas(get_global_mouse_position())
			_drag_current = _drag_start
		else:
			if _drag_start.x >= 0:
				_drag_current = _to_atlas(get_global_mouse_position())
				var left := mini(_drag_start.x, _drag_current.x)
				var top := mini(_drag_start.y, _drag_current.y)
				var right := maxi(_drag_start.x, _drag_current.x)
				var bottom := maxi(_drag_start.y, _drag_current.y)
				_selected = Rect2i(left, top, maxi(1, right - left), maxi(1, bottom - top))
				_drag_start = Vector2i(-1, -1)
				_redraw_overlay()
				_update_status()
	elif event is InputEventMouseMotion and _drag_start.x >= 0:
		_drag_current = _to_atlas(get_global_mouse_position())
		_redraw_overlay()


func _to_atlas(global_pos: Vector2) -> Vector2i:
	var local := (global_pos - _atlas_sprite.global_position) / _zoom
	return Vector2i(roundi(local.x), roundi(local.y))


func _apply_zoom() -> void:
	if _atlas_sprite != null:
		_atlas_sprite.scale = Vector2.ONE * _zoom
		_redraw_overlay()


func _redraw_overlay() -> void:
	if _overlay == null:
		return
	for child in _overlay.get_children():
		child.queue_free()
	if _atlas == null:
		return
	var size := Vector2(_atlas.get_width(), _atlas.get_height())
	if _show_grid:
		for x in range(0, int(size.x), GRID_STEP):
			_add_line(Vector2(x, 0), Vector2(x, size.y), Color(0.35, 0.8, 1.0, 0.24), 1.0)
			_add_label(Vector2(x + 3, 14), str(x))
		for y in range(0, int(size.y), GRID_STEP):
			_add_line(Vector2(0, y), Vector2(size.x, y), Color(0.35, 0.8, 1.0, 0.24), 1.0)
			_add_label(Vector2(3, y + 14), str(y))
	if _selected.size.x > 0 and _selected.size.y > 0:
		var rect := ColorRect.new()
		rect.position = _selected.position
		rect.size = _selected.size
		rect.color = Color(0.2, 0.85, 0.5, 0.22)
		_overlay.add_child(rect)
		_add_line(_selected.position, Vector2(_selected.end.x, _selected.position.y), Color.LIME, 2.0)
		_add_line(Vector2(_selected.position.x, _selected.end.y), _selected.end, Color.LIME, 2.0)
		_add_line(_selected.position, Vector2(_selected.position.x, _selected.end.y), Color.LIME, 2.0)
		_add_line(Vector2(_selected.end.x, _selected.position.y), _selected.end, Color.LIME, 2.0)
	if _drag_start.x >= 0:
		_add_line(Vector2(_drag_start), Vector2(_drag_current.x, _drag_start.y), Color.YELLOW, 2.0)
		_add_line(Vector2(_drag_current.x, _drag_start.y), Vector2(_drag_current), Color.YELLOW, 2.0)
		_add_line(Vector2(_drag_current), Vector2(_drag_start.x, _drag_current.y), Color.YELLOW, 2.0)
		_add_line(Vector2(_drag_start.x, _drag_current.y), Vector2(_drag_start), Color.YELLOW, 2.0)


func _add_line(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([a, b])
	line.default_color = color
	line.width = width
	_overlay.add_child(line)


func _add_label(at: Vector2, value: String) -> void:
	var label := Label.new()
	label.position = at
	label.text = value
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color("#8edcff"))
	_overlay.add_child(label)


func _update_status() -> void:
	if _status == null:
		return
	var dims := "等待图集载入"
	if _atlas != null:
		dims = "%d×%d" % [_atlas.get_width(), _atlas.get_height()]
	var selected_text := "未选区"
	if _selected.size.x > 0:
		selected_text = "Rect2(%d, %d, %d, %d)" % [_selected.position.x, _selected.position.y, _selected.size.x, _selected.size.y]
	_status.text = "纹理拆件检查器 | %s | %s\n鼠标拖框选择部件；Enter 复制 Rect2；G 网格；+/- 缩放；C 清除选择。" % [dims, selected_text]
