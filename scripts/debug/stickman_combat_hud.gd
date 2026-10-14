extends Label

@onready var controller: StickmanSkeletonController = get_node_or_null("../../StickmanHero") as StickmanSkeletonController

func _process(_delta: float) -> void:
	if controller == null:
		text = "Combat prototype: controller missing"
		return
	text = "S1.2.2 COMBAT TEST\nJ: long sword   K: short blade\nSpace: dodge   F3: skeleton   F4: hitbox debug\nU: simulate incoming hit\nState: %s   Combo: %d/3\nStamina: %d / %d" % [
		controller.get_state_name(),
		controller.get_combo_step(),
		roundi(controller.get_stamina()),
		roundi(controller.get_max_stamina())
	]
