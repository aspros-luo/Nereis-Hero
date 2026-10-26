extends Area2D

var host: Node

func setup(actor: Node, shape_size: Vector2, offset: Vector2) -> void:
    host = actor
    position = offset
    collision_layer = 2
    collision_mask = 0
    var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
    if collision == null:
        collision = CollisionShape2D.new()
        collision.name = "CollisionShape2D"
        add_child(collision)
    var rectangle := collision.shape as RectangleShape2D
    if rectangle == null:
        rectangle = RectangleShape2D.new()
        collision.shape = rectangle
    rectangle.size = shape_size

func receive_hit(damage: int, source: Node) -> void:
    if host and host.has_method("receive_damage"):
        host.receive_damage(damage, source)
