extends Area2D

var host: Node

func setup(actor: Node, shape_size: Vector2, offset: Vector2) -> void:
    host = actor
    position = offset
    collision_layer = 2
    collision_mask = 0
    var collision := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = shape_size
    collision.shape = rectangle
    add_child(collision)

func receive_hit(damage: int, source: Node) -> void:
    if host and host.has_method("receive_damage"):
        host.receive_damage(damage, source)
