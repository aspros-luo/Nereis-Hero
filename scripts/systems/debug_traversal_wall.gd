extends StaticBody2D
## Temporary marked climbing surface for the Debug override; never added by normal progression.
## Debug 覆盖下临时生成的可攀墙面，正常成长流程不会生成它。

const WALL_SIZE := Vector2(24.0, 180.0)

func _ready() -> void:
    add_to_group("wall_climb_surfaces")
    collision_layer = 1
    collision_mask = 1
    var collision := CollisionShape2D.new()
    var rectangle := RectangleShape2D.new()
    rectangle.size = WALL_SIZE
    collision.shape = rectangle
    add_child(collision)
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(-WALL_SIZE.x * 0.5, -WALL_SIZE.y * 0.5, WALL_SIZE.x, WALL_SIZE.y), Color("#5d9187", 0.85), true)
    draw_rect(Rect2(-WALL_SIZE.x * 0.5, -WALL_SIZE.y * 0.5, WALL_SIZE.x, WALL_SIZE.y), Color("#a6ded0", 0.95), false, 2.0)
    for y in range(-72, 73, 24):
        draw_line(Vector2(-7.0, float(y)), Vector2(7.0, float(y)), Color("#172923", 0.8), 2.0)
