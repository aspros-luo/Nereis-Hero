extends CanvasLayer

@onready var overlay: ColorRect = $FadeRect
var transitioning := false


func _ready() -> void:
	layer = 100


func fade_to_scene(
	scene_path: String,
	fade_out_duration: float = 0.22,
	fade_in_duration: float = 0.32,
	black_hold_duration: float = 0.0
) -> void:
	if transitioning:
		return
	transitioning = true

	# Persistent autoload overlay stays above outgoing and incoming scenes.
	# Death respawns can use a slower fade and short black hold; normal doors keep defaults.
	WorldState.prepare_scene_runtime()
	var fade_out := create_tween()
	fade_out.tween_property(overlay, "modulate:a", 1.0, maxf(0.01, fade_out_duration)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade_out.finished
	if black_hold_duration > 0.0:
		await get_tree().create_timer(black_hold_duration, true, false, true).timeout

	var result := get_tree().change_scene_to_file(scene_path)
	if result != OK:
		print("[NEREIS][SCENE][ERROR] Failed to load scene=%s error=%d" % [scene_path, result])
		var recover := create_tween()
		recover.tween_property(overlay, "modulate:a", 0.0, maxf(0.01, fade_in_duration))
		await recover.finished
		transitioning = false
		return

	await get_tree().process_frame
	WorldState.prepare_scene_runtime()

	var fade_in := create_tween()
	fade_in.tween_property(overlay, "modulate:a", 0.0, maxf(0.01, fade_in_duration)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_in.finished
	transitioning = false
	print("[NEREIS][SCENE] Transition complete scene=%s" % scene_path)
