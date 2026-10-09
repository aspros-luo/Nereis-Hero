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

    active_time -= delta
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
            area.receive_hit(damage, host)
            hit_targets.append(area)
            if host and host.has_method("_on_attack_hit"):
                host._on_attack_hit(damage, target_host)

func is_active() -> bool:
    return active
