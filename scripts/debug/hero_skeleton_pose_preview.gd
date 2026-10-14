extends Node2D

## Standalone pose gallery for S1.2.3-A2. This is not the production player.
## S1.2.3-A2 独立姿势预览，不是正式玩家场景。

@onready var rig: HeroSkeletonController = $HeroSkeleton
var selected_pose: HeroSkeletonController.PoseState = HeroSkeletonController.PoseState.IDLE
var selected_combo_step: int = 1
var selected_facing: float = 1.0
var status_label: Label


func _ready() -> void:
	$Camera2D.make_current()
	status_label = Label.new()
	status_label.name = "PoseInstructions"
	status_label.position = Vector2(16, 14)
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color("#f4ead9"))
	status_label.add_theme_color_override("font_shadow_color", Color("#16131b"))
	status_label.add_theme_constant_override("shadow_offset_x", 2)
	status_label.add_theme_constant_override("shadow_offset_y", 2)
	var layer := CanvasLayer.new()
	layer.name = "InstructionsLayer"
	add_child(layer)
	layer.add_child(status_label)
	_apply_selected_pose()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_1:
			selected_pose = HeroSkeletonController.PoseState.IDLE
		KEY_2:
			selected_pose = HeroSkeletonController.PoseState.RUN
		KEY_3:
			selected_pose = HeroSkeletonController.PoseState.ATTACK_LONG
		KEY_4:
			selected_pose = HeroSkeletonController.PoseState.ATTACK_SHORT
		KEY_5:
			selected_pose = HeroSkeletonController.PoseState.DODGE
		KEY_6:
			selected_pose = HeroSkeletonController.PoseState.HURT
		KEY_7:
			selected_pose = HeroSkeletonController.PoseState.DEATH
		KEY_Z:
			selected_combo_step = 1
		KEY_X:
			selected_combo_step = 2
		KEY_C:
			selected_combo_step = 3
		KEY_LEFT:
			selected_facing = -1.0
		KEY_RIGHT:
			selected_facing = 1.0
		_:
			return
	_apply_selected_pose()
	get_viewport().set_input_as_handled()


func _apply_selected_pose() -> void:
	if not is_instance_valid(rig):
		return
	rig.set_pose(selected_pose, selected_combo_step, selected_facing)
	if status_label:
		status_label.text = "S1.2.3-A2 | Skeleton Pose Preview\n" + _pose_name(selected_pose) + " | combo %d | facing %s\n\n1 Idle   2 Run   3 Long Sword   4 Short Blade\n5 Dodge   6 Hurt   7 Death\nZ/X/C combo stage 1/2/3 | Left/Right facing" % [selected_combo_step, "Left" if selected_facing < 0.0 else "Right"]


func _pose_name(pose: HeroSkeletonController.PoseState) -> String:
	match pose:
		HeroSkeletonController.PoseState.IDLE:
			return "Idle"
		HeroSkeletonController.PoseState.RUN:
			return "Run"
		HeroSkeletonController.PoseState.JUMP:
			return "Jump"
		HeroSkeletonController.PoseState.FALL:
			return "Fall"
		HeroSkeletonController.PoseState.ATTACK_LONG:
			return "Long Sword Attack"
		HeroSkeletonController.PoseState.ATTACK_SHORT:
			return "Short Blade Attack"
		HeroSkeletonController.PoseState.DODGE:
			return "Dodge"
		HeroSkeletonController.PoseState.QUICK_DASH:
			return "Quick Dash"
		HeroSkeletonController.PoseState.HURT:
			return "Hurt"
		HeroSkeletonController.PoseState.DEATH:
			return "Death"
	return "Idle"
