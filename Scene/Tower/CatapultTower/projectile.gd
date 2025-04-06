extends Node2D

@onready var enemy_paths_node := get_node("/root/Node2D/EnemyPaths")
@onready var anim = $AnimatedSprite2D
var target: Node2D
var target_initial_position: Vector2
var predicted_position: Vector2
var direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var damage: int = 20
var has_reached_target: bool = false
var target_reached_distance: float = 10.0
var travel_time: float = 1.0
var elapsed_time: float = 0.0
var start_position: Vector2
var curve_height: float = 0.5

var path_progress: float = 0.0
var path_start: Vector2
var path_control: Vector2
func init(new_target: Node2D, new_damage: int, new_z_index: int, spawn_position: Vector2 = Vector2.ZERO) -> Node2D:
    target = new_target
    damage = new_damage
    z_index = new_z_index
    # Set proper position first if provided
    if spawn_position != Vector2.ZERO:
        global_position = spawn_position

    if target:
        target_initial_position = target.global_position
        
        # First predict the future position
        predict_future_position()
        
        # Calculate travel time based on distance to predicted position
        var distance_to_predicted = global_position.distance_to(predicted_position)
        
        var min_distance = 100.0  # Distance for minimum travel time
        var max_distance = 300.0  # Distance for maximum travel time
        
        # Adjust travel time based on distance to predicted position
        var normalized_distance = clamp((distance_to_predicted - min_distance) / (max_distance - min_distance), 0.0, 1.0)
        travel_time = lerp(1.0,2.0, normalized_distance)
        
    return self

func _ready() -> void:
    if target:
        start_position = global_position
        path_start = global_position
        
        direction = global_position.direction_to(predicted_position)
        
        var distance_to_target = global_position.distance_to(predicted_position)
        
        var world_up = Vector2(0, -1)
        
        var control_dir = world_up + direction * 0.2
        control_dir = control_dir.normalized()
        
        path_control = start_position + Vector2(0, -distance_to_target * 0.7) + direction * (distance_to_target * 0.3)
        
func move_along_arc(delta: float) -> void:
    path_progress = min(elapsed_time / travel_time, 1.0)
    
    var t = path_progress
    var one_minus_t = 1.0 - t
    
    var new_position = one_minus_t * one_minus_t * path_start + 2.0 * one_minus_t * t * path_control + t * t * predicted_position
    
    velocity = (new_position - global_position) / delta
    
    global_position = new_position
    
    if velocity.length() > 0:
        var target_dir = global_position.direction_to(predicted_position)
        var curve_dir = velocity.normalized()
        
        var blend_factor = min(1.0, path_progress * 2.0)  
        direction = curve_dir.lerp(target_dir, blend_factor)
        
    
    var height_factor = 4.0 * path_progress * (1.0 - path_progress)
    
func _process(delta: float) -> void:
    elapsed_time += delta
    
    # If we've reached the target, just wait for animation to finish
    if has_reached_target:
        if !anim or !anim.is_playing():
            queue_free()
        return
        
    if !target or !is_instance_valid(target):
        move_along_arc(delta)
        check_target_reached()
        return
    
    move_along_arc(delta)
    
    check_target_reached()
    
    if elapsed_time >= travel_time and !has_reached_target:
        global_position = predicted_position
        check_target_reached()


func check_target_reached() -> void:
    var distance_to_target = global_position.distance_to(predicted_position)
    
    if distance_to_target < target_reached_distance and !has_reached_target:
        has_reached_target = true
        print("Target reached")
        # Apply area damage to all enemies within range
        scale = Vector2(0.25,0.25)
        var considered_enemies = []
        for path in enemy_paths_node.get_children():
            for enemy in path.get_children():
                if not is_instance_valid(enemy):
                    continue
                considered_enemies.append(enemy)
        for enemy in considered_enemies:
            print("Checking enemy", enemy)
            if enemy.has_method("take_damage"):
                var distance = global_position.distance_to(enemy.global_position)
                print(distance)
                if distance <= 35.0:
                    enemy.take_damage(damage)
        
        # Play the break animation
        if anim:
            anim.play("break")
        else:
            # If no animation, free immediately
            queue_free()

func predict_future_position() -> void:
    if !target:
        return
        
    # Check if target is using PathFollow2D
    var path_follow = null
    
    # First check if the target itself is a PathFollow2D
    if target is PathFollow2D:
        path_follow = target
    else:
        # Check if the target has a PathFollow2D parent
        if target.get_parent() is PathFollow2D:
            path_follow = target.get_parent()
        else:
            # Look for PathFollow2D in children
            for child in target.get_children():
                if child is PathFollow2D:
                    path_follow = child
                    break
    
    if path_follow:
        # Handle PathFollow2D prediction
        var path = path_follow.get_parent()
        var current_progress = path_follow.progress
        
        # Try to get speed from target
        var target_speed = 0
        if target.has_method("get_speed"):
            target_speed = target.get_speed()
        elif "speed" in target:
            target_speed = target.speed
        else:
            # Default estimate
            target_speed = 100
        
        # Calculate future progress
        var future_progress = current_progress + (target_speed * travel_time)
        
        # Calculate future position based on the path
        var future_pos = path_follow.global_position
        
        # Store original progress to restore it after calculation
        var original_progress = path_follow.progress
        
        # Temporarily set progress to the future value to get position
        path_follow.progress = future_progress
        future_pos = path_follow.global_position
        
        # Restore original progress
        path_follow.progress = original_progress
        
        predicted_position = future_pos
    else:
        # Use existing prediction logic for NavigationAgent2D
        var nav_agent = null
        
        for child in target.get_children():
            if child is NavigationAgent2D:
                nav_agent = child
                break
        
        if nav_agent:
            var target_velocity = Vector2.ZERO
            
            if target.has_method("get_velocity"):
                target_velocity = target.get_velocity()
            elif "velocity" in target:
                target_velocity = target.velocity
            
            if target_velocity == Vector2.ZERO and nav_agent.is_navigation_finished() == false:
                # For more accurate prediction, try to get the path and calculate where
                # the enemy will be after travel_time seconds
                var current_pos = target.global_position
                
                # Get path points if available
                var path_points = []
                if nav_agent.get_navigation_path().size() > 0:
                    path_points = nav_agent.get_navigation_path()
                
                # Calculate how far the target can travel in the travel_time
                var target_speed = 0
                if target.has_method("get_speed"):
                    target_speed = target.get_speed()
                elif "speed" in target:
                    target_speed = target.speed
                else:
                    # Estimate speed from navigation
                    target_speed = 100  # Default estimate
                
                # Distance target will travel during arrow flight
                var travel_distance = target_speed * travel_time
                
                # Follow the path to find where target will be
                var remaining_distance = travel_distance
                var predicted_pos = current_pos
                
                if path_points.size() > 1:
                    for i in range(1, path_points.size()):
                        var segment_length = path_points[i-1].distance_to(path_points[i])
                        
                        if remaining_distance <= segment_length:
                            # Target will be on this segment
                            var t = remaining_distance / segment_length
                            predicted_pos = path_points[i-1].lerp(path_points[i], t)
                            break
                        else:
                            # Move to next segment
                            remaining_distance -= segment_length
                            
                            # If this is the last segment, use its endpoint
                            if i == path_points.size() - 1:
                                predicted_pos = path_points[i]
                else:
                    # Fallback: use direction to next path position
                    var next_pos = nav_agent.get_next_path_position()
                    target_velocity = current_pos.direction_to(next_pos) * target_speed
                    predicted_pos = current_pos + (target_velocity * travel_time)
                    
                predicted_position = predicted_pos
            else:
                # Use target's velocity if available
                predicted_position = target_initial_position + (target_velocity * travel_time)
        else:
            # Fallback to initial position if no navigation is available
            predicted_position = target_initial_position
