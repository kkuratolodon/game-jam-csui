class_name Catapult
extends Node2D

# Called when the node enters the scene tree for the first time.

@onready var enemy_paths_node := get_node("/root/Node2D/EnemyPaths")
@onready var animation_tree := $AnimationTree
@onready var catapult_gunpoint := $CatapultAttack
@onready var area_2d := $Area2D
@onready var collision : CollisionShape2D = $Area2D/CollisionShape2D

var attack_range = 1000
var nearest_enemy
var enemies_in_area = []
var can_attack : bool
var damage: int
var attack_speed

func _ready():
    print("ready")
    catapult_gunpoint.damage = damage
    catapult_gunpoint.attack_speed = attack_speed
    var unique_shape = collision.shape.duplicate()
    unique_shape.radius = attack_range
    unique_shape.height = attack_range*2.2
    collision.shape = unique_shape


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
    var dir_to_enemy = get_direction_to_nearest_enemy()
    change_gunpoint_position(dir_to_enemy)
    animation_tree.set("parameters/Idle/blend_position", dir_to_enemy)
    animation_tree.set("parameters/Attack/blend_position", dir_to_enemy)
    nearest_enemy = find_nearest_enemy_in_range()
    # can_attack = nearest_enemy != null
    # animation_tree.set("parameters/conditions/attack", can_attack)


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
    var up_left = Vector2(-1, -1).normalized()
    var up_right = Vector2(1, -1).normalized()
    var down_left = Vector2(-1, 1).normalized()
    var down_right = Vector2(1, 1).normalized()

    var dot_left = direction.dot(left)
    var dot_up = direction.dot(up)
    var dot_right = direction.dot(right)
    var dot_down = direction.dot(down)
    var dot_up_left = direction.dot(up_left)
    var dot_up_right = direction.dot(up_right)
    var dot_down_left = direction.dot(down_left)
    var dot_down_right = direction.dot(down_right)

    var max_dot = max(dot_left, dot_up, dot_right, dot_down, dot_up_left, dot_up_right, dot_down_left, dot_down_right)
    var closest_direction = ""

    # Set the catapult gunpoint position based on direction
    if max_dot == dot_left:
        closest_direction = "left"
        catapult_gunpoint.position = Vector2(-8, -11)
        catapult_gunpoint.z_index = 0
    elif max_dot == dot_up:
        closest_direction = "up"
        catapult_gunpoint.position = Vector2(0, -13)
        catapult_gunpoint.z_index = 0
    elif max_dot == dot_right:
        closest_direction = "right"
        catapult_gunpoint.position = Vector2(8, -11)
        catapult_gunpoint.z_index = 0
    elif max_dot == dot_down:
        closest_direction = "down"
        catapult_gunpoint.position = Vector2(0, 0)
        catapult_gunpoint.z_index = 2
    elif max_dot == dot_up_left:
        closest_direction = "up_left"
        catapult_gunpoint.position = Vector2(-8, -13)
        catapult_gunpoint.z_index = 0
    elif max_dot == dot_up_right:
        closest_direction = "up_right"
        catapult_gunpoint.position = Vector2(8, -13)
        catapult_gunpoint.z_index = 0
    elif max_dot == dot_down_left:
        closest_direction = "down_left"
        catapult_gunpoint.position = Vector2(-5, -3)
        catapult_gunpoint.z_index = 2
    elif max_dot == dot_down_right:
        closest_direction = "down_right"
        catapult_gunpoint.position = Vector2(5, -3)
        catapult_gunpoint.z_index = 2
        

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
