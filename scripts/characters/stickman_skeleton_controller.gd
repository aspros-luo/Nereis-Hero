extends CharacterBody2D
class_name StickmanSkeletonController

# S1.2.2-A3: minimal AnimationPlayer + Skeleton2D integration test.
# This controller is a prototype harness, not the final gameplay controller.

enum State {
    IDLE,
    RUN,
    ATTACK,
    HURT,
    DODGE
}

@export var move_speed: float = 160.0

var current_state: State = State.IDLE
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer


func _ready() -> void:
    _build_prototype_animations()
    set_state(State.IDLE)


func _physics_process(_delta: float) -> void:
    # Use the built-in ui_left / ui_right actions so the prototype can be tested
    # without adding project-wide input actions. No gravity/floor is required here.
    var direction := Input.get_axis("ui_left", "ui_right")
    velocity.x = direction * move_speed
    move_and_slide()

    if absf(direction) > 0.01:
        set_state(State.RUN)
    else:
        set_state(State.IDLE)


func set_state(next_state: State) -> void:
    if current_state == next_state:
        return

    current_state = next_state
    if animation_player == null:
        return

    match current_state:
        State.IDLE:
            animation_player.play("Idle")
        State.RUN:
            animation_player.play("Run")
        # Reserved states intentionally have no prototype animation yet.
        State.ATTACK, State.HURT, State.DODGE:
            animation_player.stop()


func get_state_name() -> String:
    return State.keys()[current_state]


func _build_prototype_animations() -> void:
    if animation_player == null:
        push_warning("Stickman prototype is missing its AnimationPlayer node.")
        return

    var library := AnimationLibrary.new()
    library.add_animation("Idle", _make_idle_animation())
    library.add_animation("Run", _make_run_animation())

    var existing_library := animation_player.get_animation_library("")
    if existing_library != null:
        animation_player.remove_animation_library("")
    var result := animation_player.add_animation_library("", library)
    if result != OK:
        push_error("Could not register stickman prototype animation library.")
        return

    animation_player.root_node = NodePath("..")


func _make_idle_animation() -> Animation:
    var animation := Animation.new()
    animation.resource_name = "Idle"
    animation.length = 1.6
    animation.loop_mode = Animation.LOOP_LINEAR

    _add_rotation_track(animation, "Skeleton2D/RootBone/Spine", [0.0, 0.8, 1.6], [0.0, 0.018, 0.0])
    _add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Head", [0.0, 0.8, 1.6], [0.0, -0.025, 0.0])
    _add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_L", [0.0, 0.8, 1.6], [-0.025, -0.01, -0.025])
    _add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_R", [0.0, 0.8, 1.6], [0.025, 0.01, 0.025])
    return animation


func _make_run_animation() -> Animation:
    var animation := Animation.new()
    animation.resource_name = "Run"
    animation.length = 0.8
    animation.loop_mode = Animation.LOOP_LINEAR

    var times := [0.0, 0.2, 0.4, 0.6, 0.8]
    _add_rotation_track(animation, "Skeleton2D/RootBone/Spine", times, [0.04, -0.04, 0.04, -0.04, 0.04])
    _add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_L", times, [-0.65, 0.65, -0.65, 0.65, -0.65])
    _add_rotation_track(animation, "Skeleton2D/RootBone/Spine/Arm_R", times, [0.65, -0.65, 0.65, -0.65, 0.65])
    _add_rotation_track(animation, "Skeleton2D/RootBone/Leg_L", times, [0.7, -0.7, 0.7, -0.7, 0.7])
    _add_rotation_track(animation, "Skeleton2D/RootBone/Leg_R", times, [-0.7, 0.7, -0.7, 0.7, -0.7])
    return animation


func _add_rotation_track(animation: Animation, bone_path: String, times: Array, values: Array) -> void:
    var track_index := animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(track_index, NodePath(bone_path + ":rotation"))
    animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_LINEAR)
    for index in range(times.size()):
        animation.track_insert_key(track_index, times[index], values[index])
