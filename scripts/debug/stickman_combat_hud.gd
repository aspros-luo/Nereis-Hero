extends Label

var controller: StickmanSkeletonController

func _ready() -> void:
	# Resolve from the scene root so a renamed CanvasLayer/Label does not break the HUD.
	controller = get_tree().current_scene.get_node_or_null("StickmanHero") as StickmanSkeletonController
	z_index = 100
	position = Vector2(16.0, 14.0)
	size = Vector2(430.0, 190.0)
	autowrap_mode = TextServer.AUTOWRAP_OFF
	add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)
	add_theme_font_size_override("font_size", 15)
	text = "S1.2.2 COMBAT TEST\nJ: Long sword   K: Short blade\nSpace: Dodge   F3: Skeleton   F4: Hitbox\nU: Simulate incoming hit"


func _process(_delta: float) -> void:
	if controller == null or not is_instance_valid(controller):
		controller = get_tree().current_scene.get_node_or_null("StickmanHero") as StickmanSkeletonController
	if controller == null:
		text = "S1.2.2 COMBAT TEST\nController missing — check scene instance"
		return
	text = "S1.2.2 COMBAT TEST\nJ: Long sword   K: Short blade\nSpace: Dodge   F3: Skeleton   F4: Hitbox\nU: Simulate incoming hit\nState: %s   Combo: %d/3\nStamina: %d / %d" % [
		controller.get_state_name(),
		controller.get_combo_step(),
		roundi(controller.get_stamina()),
		roundi(controller.get_max_stamina())
	]
