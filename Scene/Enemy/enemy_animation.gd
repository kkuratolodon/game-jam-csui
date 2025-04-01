extends Node2D

var last_position: Vector2
var direction: Vector2

@onready var animation_tree = $"../AnimationTree"
@onready var enemy = $"../../" as PathFollow2D

func _ready() -> void:
    last_position = global_position

func _process(delta: float) -> void:
    # With PathFollow2D, we can use the path's direction at the current position
    if enemy.path and enemy.path.curve and enemy.progress < enemy.path.curve.get_baked_length():
        # Get tangent at current position
        var offset = enemy.progress
        var next_offset = min(offset + 10.0, enemy.path.curve.get_baked_length())
        
        if next_offset > offset:
            var current_pos = enemy.path.curve.sample_baked(offset, true)
            var next_pos = enemy.path.curve.sample_baked(next_offset, true)
            
            direction = (next_pos - current_pos).normalized()
            animation_tree.set("parameters/blend_position", direction)
    
    last_position = global_position