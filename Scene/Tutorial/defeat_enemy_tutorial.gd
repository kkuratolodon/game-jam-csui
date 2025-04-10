extends TutorialState
class_name DefeatEnemyTutorial

var enemy_spawned := false
var enemy_paths = null
var enemy_instance = null
var enemy_defeated := false
var check_timer: Timer

func _init(tutorial_manager):
    super._init(tutorial_manager)
    tutorial_name = "defeat_enemy"
    total_steps = 2  # Just Introduction and defeat enemy (removed completion step)

func enter():
    # Reset player state - remove all towers and set money to 200
    var player = Player.instance
    if player:
        print("Resetting player state for defeat enemy tutorial")
        # Reset money
        player.money = 200
        await manager.get_tree().create_timer(1.0).timeout
        # Find and remove all towers
        var towers_group = manager.get_tree().get_nodes_in_group("Towers")
        var base_tower_group = manager.get_tree().get_nodes_in_group("BaseTower")
        # Filter out towers that start with "Preview" or "preview"
        var towers_to_remove = []
        for tower in towers_group + base_tower_group:
            if not tower.name.begins_with("Preview") and not tower.name.begins_with("preview"):
                towers_to_remove.append(tower)
        print("Removing", towers_to_remove.size(), "existing towers")
        for tower in towers_to_remove:
            tower.queue_free()
    else:
        print("Could not find player instance")

    # Find enemy paths node - try multiple approaches
    print("Searching for EnemyPaths node...")
    
    # Approach 1: Direct node path - Try to get EnemyPaths directly
    enemy_paths = manager.get_node_or_null("/root/Level/EnemyPaths")
    
    # Approach 2: Group-based search
    if !enemy_paths:
        var nodes_in_group = manager.get_tree().get_nodes_in_group("EnemyPaths")
        if nodes_in_group.size() > 0:
            enemy_paths = nodes_in_group[0]
            print("Found EnemyPaths via group")
    
    # Approach 3: Find from level node
    if !enemy_paths:
        var level_node = manager.get_tree().current_scene
        if level_node and level_node.has_node("EnemyPaths"):
            enemy_paths = level_node.get_node("EnemyPaths")
            print("Found EnemyPaths via level scene")
    
    # Approach 4: Deep search (may be slower but more thorough)
    if !enemy_paths:
        enemy_paths = _find_node_by_name("EnemyPaths", manager.get_tree().root)
        if enemy_paths:
            print("Found EnemyPaths via deep search")
    
    # Debug output
    if enemy_paths:
        print("Found EnemyPaths node: ", enemy_paths)
    else:
        push_error("Could not find EnemyPaths node by any method")
    
    # Create timer to check enemy status
    check_timer = Timer.new()
    check_timer.wait_time = 0.5
    check_timer.one_shot = false
    manager.add_child(check_timer)
    check_timer.timeout.connect(_check_enemy_status)
    check_timer.start()
    
    # Reset tracking variables
    enemy_spawned = false
    enemy_defeated = false
    enemy_instance = null
    
    # Start tutorial
    super.enter()
    print("Defeat Enemy Tutorial started")

func exit():
    # Clean up
    manager.tutorial_ui.reset_panel_size()
    
    if check_timer:
        check_timer.stop()
        check_timer.queue_free()
    
    # Clean up enemy if not defeated
    if enemy_instance and is_instance_valid(enemy_instance):
        enemy_instance.queue_free()
    
    super.exit()

func show_current_step():
    match current_step:
        0: # Introduction
            manager.tutorial_ui.set_title("Defeat Enemies")
            manager.tutorial_ui.set_content("Let's learn how to defeat enemies!\n\nYou'll need to place and upgrade towers to stop them.")
            manager.tutorial_ui.show_next_button(true)
            manager.tutorial_ui.reset_panel_size()
            manager.tutorial_ui.show_panel()
            
        1: # Defeat enemy practice
            # Spawn an enemy
            _spawn_enemy()
            
            manager.tutorial_ui.set_title("Defeat the Enemy")
            manager.tutorial_ui.set_content("An enemy has appeared!\n\nPlace towers to defeat it before it reaches the end of the path.")
            manager.tutorial_ui.show_next_button(false)
            manager.tutorial_ui.reset_panel_size()
            manager.tutorial_ui.show_panel()

func update(delta: float):
    # Check for step completion
    match current_step:
        1: # Check if enemy has been defeated
            if enemy_defeated:
                # Instead of going to next step, complete this tutorial
                manager.complete_tutorial(tutorial_name)
                # Show tutorial finished panel instead
                manager.show_tutorial_finished()
                
            # Update instruction if enemy is still alive
            elif enemy_instance and is_instance_valid(enemy_instance):
                var health = enemy_instance.current_health
                var max_health = enemy_instance.max_health
                var health_percent = int((float(health) / max_health) * 100)
                
                var content = "Enemy health: " + str(health_percent) + "%\n\n"
                content += "Place and upgrade towers to defeat the enemy!"
                
                if health_percent <= 50:
                    content += "\n\nKeep going! The enemy is weakening!"
                
                manager.tutorial_ui.set_content(content)

func _spawn_enemy():
    print("Attempting to spawn enemy, enemy_paths=", enemy_paths)
    if enemy_spawned:
        print("Enemy already spawned, skipping")
        return
        
    if !enemy_paths:
        push_error("EnemyPaths node not found, cannot spawn enemy")
        return
    
    print(enemy_paths)
    
    if enemy_paths.has_method("spawn"):
        print("Spawning enemy for tutorial")
        enemy_instance = enemy_paths.spawn(0, 0)  # Spawn enemy at path 0, enemy type 0
        
        if enemy_instance:
            enemy_spawned = true
            # Connect to health changes to detect defeat
            enemy_instance.health_changed.connect(_on_enemy_health_changed)
            print("Enemy spawned successfully")
        else:
            print("failed to spawn enemy - spawn returned null")
            push_error("Failed to spawn enemy - spawn returned null")
    else:
        push_error("EnemyPaths doesn't have spawn method")

func _check_enemy_status():
    # Check if enemy has been defeated or reached end of path
    if enemy_spawned and enemy_instance and !is_instance_valid(enemy_instance):
        print("Enemy no longer valid - assuming defeated")
        enemy_defeated = true

func _on_enemy_health_changed(new_health: int):
    if new_health <= 0:
        print("Enemy defeated through health reduction")
        enemy_defeated = true

# Helper function to find a node by name recursively
func _find_node_by_name(node_name: String, in_node: Node) -> Node:
    if in_node.name == node_name:
        return in_node
        
    for child in in_node.get_children():
        var found = _find_node_by_name(node_name, child)
        if found:
            return found
    
    return null
