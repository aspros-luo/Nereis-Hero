extends Area2D

var damage := 0
var active := false
var active_time := 0.0
var host: Node
var collision_shape: CollisionShape2D
var hit_targets: Array[Node] = []

func setup(actor: Node, shape_size: Vector2, offset: Vector2) -> void:
    host = actor
    position = offset
    collision_layer = 0
    collision_mask = 2
    collision_shape = CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = shape_size
    collision_shape.shape = rectangle
    add_child(collision_shape)

func set_shape_size(shape_size: Vector2) -> void:
    if not collision_shape:
        return
    var rectangle := collision_shape.shape as RectangleShape2D
    if rectangle:
        rectangle.size = shape_size

func activate(new_damage: int, duration: float) -> void:
    damage = new_damage
    active_time = duration
    active = true
    hit_targets.clear()

func _physics_process(delta: float) -> void:
    if not active:
        return

    var timer_delta := delta
    # Enemy attack windows belong to the enemy's local time during Witch Time; Hero hitboxes remain normal.
    # 魔女时间期间敌方攻击窗口随敌人局部时间变慢；主角自己的命中框不受影响。
    if is_instance_valid(host) and host.is_in_group("combat_enemies"):
        timer_delta *= WorldState.get_combat_enemy_time_scale()
    active_time -= timer_delta
    if active_time <= 0.0:
        active = false
        return

    for area in get_overlapping_areas():
        if area == self or area in hit_targets:
            continue

        var target_host = area.get("host")
        if target_host == host or not target_host:
            continue

        if area.has_method("receive_hit"):
            var resolved_damage := damage
            if host and host.has_method("modify_outgoing_damage"):
                resolved_damage = int(host.call("modify_outgoing_damage", damage))
            area.receive_hit(resolved_damage, host)
            hit_targets.append(area)
            if host and host.has_method("_on_attack_hit"):
                host._on_attack_hit(resolved_damage, target_host)

func deactivate() -> void:
    active = false
    active_time = 0.0
    hit_targets.clear()

func is_active() -> bool:
    return active
