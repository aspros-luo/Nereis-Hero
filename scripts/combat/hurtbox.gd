extends Area2D

var host: Node

func setup(actor: Node, shape_size: Vector2, offset: Vector2) -> void:
    host = actor
    position = offset
    collision_layer = 2
    collision_mask = 0
    var collision := get_node("CollisionShape2D") as CollisionShape2D
    var rectangle := collision.shape as RectangleShape2D
    if rectangle == null:
        push_error("Hurtbox scene requires a RectangleShape2D child")
        return
    rectangle.size = shape_size

func receive_hit(damage: int, source: Node) -> void:
    if host and host.has_method("receive_damage"):
        host.receive_damage(damage, source)
