extends Control

const SETTINGS_PATH := "user://nereis_hero_settings.cfg"
const LANGUAGES := ["zh_cn", "zh_tw", "en", "ja"]
const LABELS := {
	"zh_cn": {"title":"设置", "master":"主音量", "fullscreen":"全屏显示", "language":"语言", "back":"返回标题", "volume":"音量", "saved":"设置已保存"},
	"zh_tw": {"title":"設定", "master":"主音量", "fullscreen":"全螢幕顯示", "language":"語言", "back":"返回標題", "volume":"音量", "saved":"設定已儲存"},
	"en": {"title":"Settings", "master":"Master Volume", "fullscreen":"Fullscreen", "language":"Language", "back":"Back to Title", "volume":"Volume", "saved":"Settings saved"},
	"ja": {"title":"設定", "master":"マスター音量", "fullscreen":"全画面表示", "language":"言語", "back":"タイトルへ戻る", "volume":"音量", "saved":"設定を保存しました"}
}

@onready var title_label: Label = $Panel/Layout/Title
@onready var master_label: Label = $Panel/Layout/MasterLabel
@onready var master_slider: HSlider = $Panel/Layout/MasterSlider
@onready var fullscreen_check: CheckButton = $Panel/Layout/FullscreenCheck
@onready var language_label: Label = $Panel/Layout/LanguageLabel
@onready var language_option: OptionButton = $Panel/Layout/LanguageOption
@onready var status_label: Label = $Panel/Layout/StatusLabel
@onready var back_button: Button = $Panel/Layout/BackButton

var settings := ConfigFile.new()

func _ready() -> void:
	for language_id in LANGUAGES:
		language_option.add_item(NereisLocalization.language_name(language_id))
	_load_settings()
	master_slider.value_changed.connect(_on_master_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	language_option.item_selected.connect(_on_language_selected)
	back_button.pressed.connect(_on_back_pressed)
	_refresh_labels()

func _load_settings() -> void:
	var error := settings.load(SETTINGS_PATH)
	var volume := 1.0
	var fullscreen := false
	if error == OK:
		volume = clampf(float(settings.get_value("audio", "master_volume", 1.0)), 0.0, 1.0)
		fullscreen = bool(settings.get_value("display", "fullscreen", false))
	master_slider.set_value_no_signal(volume)
	fullscreen_check.set_pressed_no_signal(fullscreen)
	language_option.select(NereisLocalization.language_index(str(WorldState.language)))
	_apply_volume(volume)
	_apply_fullscreen(fullscreen)

func _save_settings() -> void:
	settings.set_value("audio", "master_volume", master_slider.value)
	settings.set_value("display", "fullscreen", fullscreen_check.button_pressed)
	var error := settings.save(SETTINGS_PATH)
	status_label.text = _label("saved") if error == OK else "Settings save failed (%s)" % error

func _apply_volume(value: float) -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index >= 0:
		AudioServer.set_bus_volume_linear(bus_index, clampf(value, 0.0, 1.0))

func _apply_fullscreen(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_master_volume_changed(value: float) -> void:
	_apply_volume(value)
	_save_settings()

func _on_fullscreen_toggled(enabled: bool) -> void:
	_apply_fullscreen(enabled)
	_save_settings()

func _on_language_selected(index: int) -> void:
	var language_id := LANGUAGES[clampi(index, 0, LANGUAGES.size() - 1)]
	WorldState.set_language(language_id)
	_refresh_labels()
	_save_settings()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/boot.tscn")

func _label(key: String) -> String:
	var language_id := str(WorldState.language)
	if not LABELS.has(language_id):
		language_id = "zh_cn"
	return str(LABELS[language_id].get(key, key))

func _refresh_labels() -> void:
	title_label.text = _label("title")
	master_label.text = _label("master")
	fullscreen_check.text = _label("fullscreen")
	language_label.text = _label("language")
	back_button.text = _label("back")
	language_option.select(NereisLocalization.language_index(str(WorldState.language)))
