extends TutorialState
class_name MoveWASDTutorial

var moved_up := false
var moved_left := false
var moved_down := false
var moved_right := false
var check_timer: Timer
var player = null

func _init(tutorial_manager):
    super._init(tutorial_manager)
    tutorial_name = "move_wasd"
    total_steps = 2  # Introduction and movement testing

func enter():
    # Create timer to periodically check player movement
    check_timer = Timer.new()
    check_timer.wait_time = 0.2
    check_timer.one_shot = false
    manager.add_child(check_timer)
    check_timer.timeout.connect(_on_check_timer)
    check_timer.start()
    
    # Reset movement tracking
    moved_up = false
    moved_left = false
    moved_down = false
    moved_right = false
    
    # Find player
    player = manager.get_tree().get_first_node_in_group("Player")
    
    # Start tutorial
    super.enter()
    print("WASD Movement Tutorial started")

func exit():
    # Ensure panel size is reset when exiting
    manager.tutorial_ui.reset_panel_size()
    
    # Clean up timers
    if check_timer:
        check_timer.stop()
        check_timer.queue_free()
    
    super.exit()

func show_current_step():
    match current_step:
        0: # Introduction
            manager.tutorial_ui.set_title("Basic Movement")
            manager.tutorial_ui.set_content("Welcome! Let's learn how to move your character using the keyboard.")
            manager.tutorial_ui.show_next_button(true)
            # Use default panel size and position
            manager.tutorial_ui.show_panel()
            
        1: # Movement practice - larger panel with adjusted elements
            manager.tutorial_ui.set_title("Practice Moving")
            manager.tutorial_ui.set_content("Try moving in all directions:\n• W - Move up\n• A - Move left\n• S - Move down\n• D - Move right")
            manager.tutorial_ui.show_next_button(false)
            # Use taller panel with adjusted margins for title
            manager.tutorial_ui.show_panel(Vector2(400, 250), true)

func update(delta: float):
    # Check for step completion
    match current_step:
        1: # Check if moved in all directions
            # Check direct input for immediate feedback
            check_movement_input()
            
            if moved_up && moved_left && moved_down && moved_right:
                print("Player has moved in all directions!")
                next_step()

func check_movement_input():
    if Input.is_key_pressed(KEY_W):
        moved_up = true
    if Input.is_key_pressed(KEY_A):
        moved_left = true
    if Input.is_key_pressed(KEY_S):
        moved_down = true
    if Input.is_key_pressed(KEY_D):
        moved_right = true
        
    # Update movement completion visualization
    if current_step == 1:
        var directions_moved = 0
        if moved_up: directions_moved += 1
        if moved_left: directions_moved += 1
        if moved_down: directions_moved += 1
        if moved_right: directions_moved += 1
        
        # Update the content to show progress - shorter format to avoid overflow
        var content = "Try moving in all directions:\n"
        content += "• W - Up " + ("✓" if moved_up else "") + "\n"
        content += "• A - Left " + ("✓" if moved_left else "") + "\n"
        content += "• S - Down " + ("✓" if moved_down else "") + "\n" 
        content += "• D - Right " + ("✓" if moved_right else "") + "\n"
        content += "Progress: " + str(directions_moved) + "/4"
        
        manager.tutorial_ui.set_content(content)

func _on_check_timer():
    # Check movement based on player velocity or position changes
    if player && current_step == 1:
        if player.has_method("get_velocity") && player.get_velocity().length() > 0:
            var velocity = player.get_velocity()
            
            if velocity.y < -0.5:  # Moving up
                moved_up = true
            if velocity.x < -0.5:  # Moving left
                moved_left = true
            if velocity.y > 0.5:   # Moving down
                moved_down = true
            if velocity.x > 0.5:   # Moving right
                moved_right = true
        
        # Direct input check as fallback
        check_movement_input()

func next_step():
    # Reset panel size when advancing from step 1
    if current_step == 1:
        manager.tutorial_ui.reset_panel_size()
    
    # Call the parent method
    super.next_step()
