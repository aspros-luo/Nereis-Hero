extends Node

## Creates minimal keyframe examples at runtime so the rig remains editable in the scene.
## 运行时创建最小关键帧动画示例，骨骼层级仍可在场景中编辑。

@export var animation_player_path: NodePath = ^"../AnimationPlayer"
@export var body_bone_path: NodePath = ^"../Rig/RootBone/BodyBone"
@export var left_arm_path: NodePath = ^"../Rig/RootBone/BodyBone/LeftArmBone"
@export var right_arm_path: NodePath = ^"../Rig/RootBone/BodyBone/RightArmBone"
@export var left_leg_path: NodePath = ^"../Rig/RootBone/LeftLegBone"
@export var right_leg_path: NodePath = ^"../Rig/RootBone/RightLegBone"

var _player: AnimationPlayer


func _ready() -> void:
	_player = get_node_or_null(animation_player_path) as AnimationPlayer
	if _player == null:
		push_warning("Character animation setup could not find AnimationPlayer.")
		return
	_build_animation("idle", 1.2, [
		_track(body_bone_path, NodePath("position:y"), [0.0, 0.6, 1.2], [-20.0, -21.0, -20.0]),
	])
	_build_animation("run", 0.48, [
		_track(left_arm_path, NodePath("rotation"), [0.0, 0.24, 0.48], [-0.45, 0.45, -0.45]),
		_track(right_arm_path, NodePath("rotation"), [0.0, 0.24, 0.48], [0.45, -0.45, 0.45]),
		_track(left_leg_path, NodePath("rotation"), [0.0, 0.24, 0.48], [0.55, -0.55, 0.55]),
		_track(right_leg_path, NodePath("rotation"), [0.0, 0.24, 0.48], [-0.55, 0.55, -0.55]),
	])
	_build_animation("attack", 0.42, [
		_track(right_arm_path, NodePath("rotation"), [0.0, 0.12, 0.42], [-0.25, -1.15, 0.2]),
		_track(body_bone_path, NodePath("rotation"), [0.0, 0.12, 0.42], [0.0, -0.18, 0.08]),
	])
	_build_animation("dodge", 0.36, [
		_track(body_bone_path, NodePath("rotation"), [0.0, 0.12, 0.36], [0.0, -0.38, 0.0]),
		_track(body_bone_path, NodePath("position:x"), [0.0, 0.12, 0.36], [0.0, 7.0, 0.0]),
	])


func _track(node_path: NodePath, property: NodePath, times: Array, values: Array) -> Dictionary:
	return {"path": NodePath("%s:%s" % [str(node_path), str(property)]), "times": times, "values": values}


func _build_animation(animation_name: String, duration: float, tracks: Array[Dictionary]) -> void:
	var animation := Animation.new()
	animation.resource_name = animation_name
	animation.length = duration
	animation.loop_mode = Animation.LOOP_LINEAR if animation_name in ["idle", "run"] else Animation.LOOP_NONE
	for definition in tracks:
		var track_index := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track_index, definition["path"])
		animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_CUBIC)
		var times: Array = definition["times"]
		var values: Array = definition["values"]
		for key_index in range(times.size()):
			animation.track_insert_key(track_index, float(times[key_index]), values[key_index])
	var library := _player.get_animation_library(&"")
	if library == null:
		library = AnimationLibrary.new()
		_player.add_animation_library(&"", library)
	if library.has_animation(animation_name):
		library.remove_animation(animation_name)
	library.add_animation(animation_name, animation)
