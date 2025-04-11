extends Node2D

var target
var damage: int
var speed: float = 200.0
var has_hit: bool = false
var z_idx: int

func init(target_enemy, damage_value, z_index_value, start_position):
    target = target_enemy
    damage = damage_value
    z_idx = z_index_value
    global_position = start_position
    z_index = z_idx

func _process(delta):
    if not is_instance_valid(target):
        # Target was destroyed before the projectile hit
        queue_free()
        return
        
    # Move toward target
    var direction = (target.global_position - global_position).normalized()
    global_position += direction * speed * delta
    
    # Check if we're close enough to hit
    if global_position.distance_to(target.global_position) < 15:
        _on_hit()

func _on_hit():
    if has_hit:
        return
        
    has_hit = true
    
    # Apply damage to target if it has a take_damage method
    if target.has_method("take_damage"):
        target.take_damage(damage, true)
    
    queue_free()

func _exit_tree():
    # If the projectile is destroyed without hitting, cancel the damage prediction
    if not has_hit and is_instance_valid(target):
        target.cancel_incoming_damage(damage)
