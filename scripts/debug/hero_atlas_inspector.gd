extends Node2D
## Local-only atlas inspection helper. The third-party atlas is never committed.
## 本地纹理图集检查器；第三方图集本身不会提交到仓库。

const ATLAS_PATH := "res://assets/characters/hero/tex1_512x512_4d6c36bcbd5d9ddc_423915aa39e773f2_9.png"
const GRID_STEP := 32
const GRID_COLOR := Color(0.9, 0.85, 0.65, 0.38)
const SELECTION_COLOR := Color(0.25, 0.95, 0.65, 0.95)

@onready var camera: Camera2D = $Camera2D

var atlas_sprite: Sprite2D
var status_label: Label
var selecting := false
var selection_start := Vector2.ZERO
var selection_end := Vector2.ZERO
var has_selection := false
var atlas_size := Vector2.ZERO


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("#242329")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background_layer := CanvasLayer.new()
	background_layer.layer = -1
	add_child(background_layer)
	background_layer.add_child(background)

	if not ResourceLoader.exists(ATLAS_PATH):
		_build_status("Missing local atlas / 缺少本地图集：\n" + ATLAS_PATH)
		return

	var atlas := load(ATLAS_PATH) as Texture2D
	if atlas == null:
		_build_status("Failed to load atlas / 图集加载失败")
		return

	atlas_size = Vector2(atlas.get_width(), atlas.get_height())
	atlas_sprite = Sprite2D.new()
	atlas_sprite.name = "Atlas"
	atlas_sprite.texture = atlas
	atlas_sprite.centered = false
	atlas_sprite.position = -atlas_size * 0.5
	atlas_sprite.z_index = -1
	add_child(atlas_sprite)

	camera.position = Vector2.ZERO
	camera.zoom = Vector2(0.8, 0.8)
	_build_status("Texture atlas inspector / 纹理图集检查器\nSource: committed PNG atlas · Wheel: zoom · Drag: measure crop · Right click: reset\n使用仓库内 PNG 纹理；滚轮缩放 · 拖框测量区域 · 右键重置")
	queue_redraw()


func _build_status(message: String) -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	status_label = Label.new()
	status_label.position = Vector2(16, 12)
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color("#f4ead9"))
	status_label.text = message
	layer.add_child(status_label)


func _draw() -> void:
	if atlas_sprite == null:
		return
	var half := atlas_size * 0.5
	for coordinate in range(0, int(atlas_size.x) + 1, GRID_STEP):
		var x := float(coordinate) - half.x
		draw_line(Vector2(x, -half.y), Vector2(x, half.y), GRID_COLOR, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(x + 4.0, -half.y + 18.0), str(coordinate), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#fff0b3"))
	for coordinate in range(0, int(atlas_size.y) + 1, GRID_STEP):
		var y := float(coordinate) - half.y
		draw_line(Vector2(-half.x, y), Vector2(half.x, y), GRID_COLOR, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(-half.x + 4.0, y - 4.0), str(coordinate), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#fff0b3"))
	if has_selection or selecting:
		var rect := Rect2(selection_start, selection_end - selection_start).abs()
		draw_rect(rect, SELECTION_COLOR, false, 2.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(3.0, -5.0), "%d,%d  %dx%d" % [roundi(rect.position.x + half.x), roundi(rect.position.y + half.y), roundi(rect.size.x), roundi(rect.size.y)], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, SELECTION_COLOR)


func _atlas_local_position() -> Vector2:
	return get_global_mouse_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			camera.zoom = (camera.zoom * 1.12).clamp(Vector2(0.12, 0.12), Vector2(3.0, 3.0))
			get_viewport().set_input_as_handled()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			camera.zoom = (camera.zoom / 1.12).clamp(Vector2(0.12, 0.12), Vector2(3.0, 3.0))
			get_viewport().set_input_as_handled()
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			camera.position = Vector2.ZERO
			camera.zoom = Vector2(0.8, 0.8)
			get_viewport().set_input_as_handled()
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT and atlas_sprite != null:
			if mouse_event.pressed:
				selecting = true
				has_selection = false
				selection_start = _atlas_local_position()
				selection_end = selection_start
			else:
				if selecting:
					selection_end = _atlas_local_position()
					selecting = false
					has_selection = true
					var rect := Rect2(selection_start, selection_end - selection_start).abs()
					var atlas_rect := Rect2(rect.position + atlas_size * 0.5, rect.size)
					print("Atlas crop / 图集裁切: Rect2(%d, %d, %d, %d)" % [roundi(atlas_rect.position.x), roundi(atlas_rect.position.y), roundi(atlas_rect.size.x), roundi(atlas_rect.size.y)])
					if status_label:
						status_label.text = "Selected crop / 已选区域: %d, %d — %d × %d\nDrag another region to replace / 再次拖框可重新选择" % [roundi(atlas_rect.position.x), roundi(atlas_rect.position.y), roundi(atlas_rect.size.x), roundi(atlas_rect.size.y)]
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and selecting:
		selection_end = _atlas_local_position()
		queue_redraw()
		get_viewport().set_input_as_handled()
