extends Area2D

const CHECKPOINT_VISUAL_SCENE = preload("res://scenes/world/checkpoint_visual.tscn")

var active := false
var animation_time := 0.0

func _process(_delta: float) -> void:
    _refresh_visual_state()

func _ready() -> void:
    active = WorldState.checkpoint_active
    collision_layer = 4
    collision_mask = 1
    monitoring = true
    if not has_node("CheckpointVisual"):
        var visual := CHECKPOINT_VISUAL_SCENE.instantiate()
        visual.name = "CheckpointVisual"
        add_child(visual)
    body_entered.connect(_on_body_entered)
    _refresh_visual_state()


func _refresh_visual_state() -> void:
    var visual := get_node_or_null("CheckpointVisual")
    if visual == null:
        return
    visual.get_node("InactiveState").visible = not active
    visual.get_node("ActiveState").visible = active

func _on_body_entered(body: Node) -> void:
    if active or body.name != "Hero":
        return
    active = true
    WorldState.set_checkpoint(global_position + Vector2(0, 0))
    print("[NEREIS][WORLD] Hero reached checkpoint")


