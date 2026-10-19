extends "res://scripts/player/hero_skeleton_controller.gd"
class_name HeroSkeletonTextureLab

## Atlas inspection lab for the existing Bone2D rig.
## This UV atlas is not a sprite sheet: never treat arbitrary rectangles as finished body parts.
## 该图是 UV 纹理图集而非完整精灵表；禁止把未经识别的矩形裁片伪装成完整身体部件。

const ATLAS_PATH := "res://assets/art/hero_sprite_lab/muramasa_texture_atlas.png"
const ATLAS_SIZE := Vector2(2048.0, 2048.0)
const GRID_STEP := 64
const PREVIEW_SIZE := Vector2(512.0, 512.0)
const PREVIEW_POSITION := Vector2(680.0, 72.0)

@export var show_atlas_inspector: bool = true
@export var keep_rig_line_art: bool = true
@export_range(0.01, 1.0, 0.01) var atlas_preview_scale: float = 0.25

var _atlas: Texture2D
var _atlas_status: Label
var _atlas_view: TextureRect
var _grid_overlay: AtlasGridOverlay


class AtlasGridOverlay extends Control:
	signal cell_selected(source_rect: Rect2i)

	var source_size := Vector2(2048.0, 2048.0)
	var grid_step := 128
	var selected_cell := Vector2i(-1, -1)

	func _draw() -> void:
		var cell_size := size.x * float(grid_step) / source_size.x
		var font := get_theme_default_font()
		for coordinate in range(0, int(source_size.x) + 1, grid_step):
			var screen_pos := float(coordinate) / source_size.x * size.x
			draw_line(Vector2(screen_pos, 0), Vector2(screen_pos, size.y), Color(0.2, 0.9, 0.95, 0.55), 1.0)
			draw_line(Vector2(0, screen_pos), Vector2(size.x, screen_pos), Color(0.2, 0.9, 0.95, 0.55), 1.0)
			if coordinate < int(source_size.x):
				draw_string(font, Vector2(screen_pos + 3.0, 13.0), str(coordinate), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		if selected_cell.x >= 0 and selected_cell.y >= 0:
			var selected_rect := Rect2(Vector2(selected_cell) * cell_size, Vector2.ONE * cell_size)
			draw_rect(selected_rect, Color(1.0, 0.7, 0.15, 0.25), true)
			draw_rect(selected_rect, Color(1.0, 0.7, 0.15, 1.0), false, 2.0)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var cell_size := size.x * float(grid_step) / source_size.x
			selected_cell = Vector2i(
				clampi(int(floor(event.position.x / cell_size)), 0, int(source_size.x / grid_step) - 1),
				clampi(int(floor(event.position.y / cell_size)), 0, int(source_size.y / grid_step) - 1)
			)
			queue_redraw()
			cell_selected.emit(Rect2i(selected_cell * grid_step, Vector2i.ONE * grid_step))


func _ready() -> void:
	super._ready()
	_build_status_label()
	if not keep_rig_line_art:
		# Deliberately opt-in only. Default keeps the known rig visible beside the atlas.
		_hide_line_art()
	if not show_atlas_inspector:
		_atlas_status.text = "Atlas inspector disabled / 已关闭图集检查器。"
		return
	if not ResourceLoader.exists(ATLAS_PATH):
		_atlas_status.text = (
			"Atlas not found at project path / 项目路径未找到图集：\n" + ATLAS_PATH
			+ "\nThe original atlas is UV-mapped artwork, not a finished sprite sheet."
			+ "\n原图集是 UV 表面纹理，不是可直接拼装的完整精灵表。"
		)
		return
	_atlas = load(ATLAS_PATH) as Texture2D
	if _atlas == null:
		_atlas_status.text = "Atlas failed to load / 图集加载失败：" + ATLAS_PATH
		return
	_build_atlas_view()


func _build_status_label() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TextureLabOverlay"
	add_child(layer)
	_atlas_status = Label.new()
	_atlas_status.position = Vector2(16.0, 12.0)
	_atlas_status.add_theme_font_size_override("font_size", 15)
	_atlas_status.add_theme_color_override("font_color", Color("#f4ead9"))
	layer.add_child(_atlas_status)


func _build_atlas_view() -> void:
	var layer := get_node_or_null("TextureLabOverlay") as CanvasLayer
	if layer == null:
		return
	var scale_factor := clampf(atlas_preview_scale, 0.01, 1.0)
	var preview_size := ATLAS_SIZE * scale_factor
	_atlas_view = TextureRect.new()
	_atlas_view.name = "AtlasPreview"
	_atlas_view.texture = _atlas
	_atlas_view.position = PREVIEW_POSITION
	_atlas_view.size = preview_size
	_atlas_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_atlas_view.stretch_mode = TextureRect.STRETCH_SCALE
	_atlas_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_atlas_view)

	_grid_overlay = AtlasGridOverlay.new()
	_grid_overlay.name = "AtlasCoordinateGrid"
	_grid_overlay.position = PREVIEW_POSITION
	_grid_overlay.size = preview_size
	_grid_overlay.source_size = ATLAS_SIZE
	_grid_overlay.grid_step = GRID_STEP
	_grid_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_grid_overlay.cell_selected.connect(_on_atlas_cell_selected)
	layer.add_child(_grid_overlay)
	_atlas_status.position = Vector2(16.0, 12.0)
	_atlas_status.text = (
		"Hero texture atlas inspection / 主角纹理图集检查\n"
		+ "Click a grid cell to read its source coordinates (64 px grid).\n"
		+ "点击网格读取原图坐标（每格 64 像素）。\n"
		+ "Rig line art stays visible for comparison; this atlas needs its source mesh/UV mapping "
		+ "before its surface islands can be assembled faithfully.\n"
		+ "保留骨骼线稿作对照；要准确还原表面纹理，需要原模型网格/UV 对应关系。"
	)


func _on_atlas_cell_selected(source_rect: Rect2i) -> void:
	_atlas_status.text = (
		"Selected atlas region / 已选图集区域：x=%d, y=%d, w=%d, h=%d\n"
		% [source_rect.position.x, source_rect.position.y, source_rect.size.x, source_rect.size.y]
		+ "This is a coordinate aid, not an automatically identified body part.\n"
		+ "坐标辅助工具不会自动判断该区域属于哪个身体部位。"
	)


func _hide_line_art() -> void:
	for node in find_children("*", "Line2D", true, false):
		(node as CanvasItem).visible = false
	for node in find_children("*", "Polygon2D", true, false):
		(node as CanvasItem).visible = false
