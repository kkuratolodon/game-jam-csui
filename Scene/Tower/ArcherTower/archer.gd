extends Node2D
class_name Archer
# Called when the node enters the scene tree for the first time.

@onready var enemy_paths_node := get_node("/root/Node2D/EnemyPaths")
@onready var animation_tree := $AnimationTree
@onready var archer_gunpoint := $ArcherAttack
@onready var area_2d := $Area2D
@onready var collision : CollisionShape2D = $Area2D/CollisionShape2D

var attack_range = 1000
var nearest_enemy
var best_target # Store the best target for both shooting and animation
var enemies_in_area = []
var can_attack : bool
var damage: int
var attack_speed: float = 1.0

func _ready():
    print("ready")
    archer_gunpoint.damage = damage
    archer_gunpoint.attack_speed = attack_speed
    var unique_shape = collision.shape.duplicate()
    unique_shape.radius = attack_range
    unique_shape.height = attack_range*2.2
    collision.shape = unique_shape

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
    # Find the best target (that won't be killed by other projectiles)
    best_target = find_best_target()
    
    # Get direction to the best target, or nearest enemy if no best target
    var dir_to_enemy = Vector2.ZERO
    if best_target and is_instance_valid(best_target):
        dir_to_enemy = (best_target.global_position - global_position).normalized()
    else:
        dir_to_enemy = get_direction_to_nearest_enemy()
    
    # Update gunpoint position and animations
    change_gunpoint_position(dir_to_enemy)
    animation_tree.set("parameters/Idle/blend_position", dir_to_enemy)
    animation_tree.set("parameters/Attack/blend_position", dir_to_enemy)
    animation_tree.set("parameters/PreAttack/blend_position", dir_to_enemy)
    
    # Update nearest_enemy for compatibility with existing code
    nearest_enemy = best_target if best_target else find_nearest_enemy_in_range()
    can_attack = nearest_enemy != null
    animation_tree.set("parameters/conditions/attack", can_attack)

# Find target that won't die from damage already in flight
func find_best_target() -> Node2D:
    var enemies = enemies_in_area.duplicate()
    if enemies.size() == 0:
        return null
        
    # Sort by progress (farthest along path first)
    enemies.sort_custom(func(a, b): return a.progress > b.progress)
    
    # Find enemies that will survive current in-flight damage
    var valid_targets = []
    for enemy in enemies:
        if not is_instance_valid(enemy):
            continue
            
        # Only target enemies that won't die from existing in-flight damage
        if enemy.predicted_health > 0:
            valid_targets.append(enemy)
    
    # If we have valid targets, return the one furthest along the path
    if valid_targets.size() > 0:
        valid_targets.sort_custom(func(a, b): return a.progress > b.progress)
        return valid_targets[0]
    
    # If all enemies are predicted to die, return the one farthest along
    return enemies[0] if enemies.size() > 0 else null

func find_nearest_enemy():
    if enemy_paths_node == null or enemy_paths_node.get_child_count() == 0:
        return null
    
    var nearest_enemy = null
    var considered_enemies = []
    var highest_progress = -1
    if enemies_in_area:
        considered_enemies = enemies_in_area
    else:
        considered_enemies = []
        for path in enemy_paths_node.get_children():
            for enemy in path.get_children():
                if not is_instance_valid(enemy):
                    continue
                considered_enemies.append(enemy)
    
    # Iterate through all paths
    for enemy in considered_enemies:
        if not is_instance_valid(enemy):
            continue
            
        var progress = enemy.progress
        
        if highest_progress < progress:
            highest_progress = progress
            nearest_enemy = enemy
    return nearest_enemy

func find_nearest_enemy_in_range():
    var enemy = find_nearest_enemy()
    
    if enemy != null:
        if enemy in enemies_in_area:
            return enemy
    
    return null


func get_direction_to_nearest_enemy():
    var enemy = find_nearest_enemy()
    
    if enemy == null:
        return Vector2.ZERO
    
    var direction = enemy.global_position - global_position
    
    return direction.normalized()

func change_gunpoint_position(direction):
    var left = Vector2(-1, 0)
    var up = Vector2(0, -1)
    var right = Vector2(1, 0)
    var down = Vector2(0, 1)

    var dot_left = direction.dot(left)
    var dot_up = direction.dot(up)
    var dot_right = direction.dot(right)
    var dot_down = direction.dot(down)

    var max_dot = max(dot_left, dot_up, dot_right, dot_down)
    var closest_direction = ""

    # Set the archer gunpoint position based on direction
    if max_dot == dot_left:
        closest_direction = "left"
        archer_gunpoint.position = Vector2(-15, -5)
    elif max_dot == dot_up:
        closest_direction = "up"
        archer_gunpoint.position = Vector2(0, -15)
    elif max_dot == dot_right:
        closest_direction = "right"
        archer_gunpoint.position = Vector2(15, -5)
    else:  # max_dot == dot_down
        closest_direction = "down"
        archer_gunpoint.position = Vector2(0, 5)
        

func _on_area_2d_body_entered(body:Node2D) -> void:
    
    # Check if body is an enemy in any path
    for path in enemy_paths_node.get_children():
        if body.get_parent() == path:
            enemies_in_area.append(body)
            break

func _on_area_2d_body_exited(body:Node2D) -> void:
    if body in enemies_in_area:
        enemies_in_area.erase(body)


func _on_area_2d_area_entered(area:Area2D) -> void:
    for path in enemy_paths_node.get_children():
        if area.get_parent().get_parent() == path:
            enemies_in_area.append(area.get_parent())
            break



func _on_area_2d_area_exited(area:Area2D) -> void:
    if area.get_parent() in enemies_in_area:
        enemies_in_area.erase(area.get_parent())
