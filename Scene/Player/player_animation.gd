extends Node2D

@onready var player = Player.get_instance()
@onready var animation_tree = $"../AnimationTree"

var last_facing_direction: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:

    var idle = !player.velocity
    if !idle:
        last_facing_direction = player.velocity.normalized()

    animation_tree.set("parameters/conditions/idle", idle)
    animation_tree.set("parameters/conditions/walk", !idle)
    
    animation_tree.set("parameters/Walk/blend_position", last_facing_direction)
    animation_tree.set("parameters/Idle/blend_position", last_facing_direction)
