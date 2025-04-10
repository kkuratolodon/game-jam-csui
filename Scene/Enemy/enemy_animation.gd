extends Node2D

var last_position: Vector2
var direction: Vector2
var is_dying = false
var prev_blocking_state = false

@onready var animation_tree = $"../AnimationTree"
@onready var enemy = $"../../" as PathFollow2D
@onready var timer = Timer.new()

func _ready() -> void:
    last_position = global_position
    
    # Connect to the health_changed signal
    enemy.health_changed.connect(_on_health_changed)
    
    # Setup timer for death animation completion
    add_child(timer)
    timer.one_shot = true
    timer.timeout.connect(_on_death_animation_finished)

func _process(delta: float) -> void:
    # Skip movement animation processing if dying
    if is_dying:
        return
    
    # Handle blocking animation
    if enemy.is_blocking != prev_blocking_state:
        prev_blocking_state = enemy.is_blocking
        animation_tree.set("parameters/conditions/Block", enemy.is_blocking)
        
    # With PathFollow2D, we can use the path's direction at the current position
    if enemy.path and enemy.path.curve and enemy.progress < enemy.path.curve.get_baked_length():
        # Get tangent at current position
        var offset = enemy.progress
        var next_offset = min(offset + 10.0, enemy.path.curve.get_baked_length())
        
        if next_offset > offset:
            var current_pos = enemy.path.curve.sample_baked(offset, true)
            var next_pos = enemy.path.curve.sample_baked(next_offset, true)
            
            direction = (next_pos - current_pos).normalized()
            animation_tree.set("parameters/Walk/blend_position", direction)
            # Also set the direction for Block animation if needed
            animation_tree.set("parameters/Block/blend_position", direction)
    
    last_position = global_position

func _on_health_changed(new_health: int) -> void:
    if new_health <= 0 and not is_dying:
        print("death: ", new_health)
        is_dying = true
        # Set death animation parameter
        animation_tree.set("parameters/Death/blend_position", direction)
        animation_tree.set("parameters/conditions/death", true)
        # Set the last direction for death animation
        
        # Start timer for cleanup after animation
        timer.start(1.0)  # Adjust time to match death animation length

func _on_death_animation_finished() -> void:
    # Queue the enemy for deletion after death animation completes
    enemy.queue_free()