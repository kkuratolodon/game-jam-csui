extends TutorialState
class_name MergeTowerTutorial

var same_tower_built := false
var move_mode_activated := false
var tower_merged := false
var first_tower_type: String = ""
var check_timer: Timer

func _init(tutorial_manager):
    super._init(tutorial_manager)
    tutorial_name = "merge_tower"
    total_steps = 4  # Introduction, build same tower, move mode, merge

func enter():
    # Connect to necessary signals
    if manager.move_controller:
        if not manager.move_controller.is_connected("move_state_changed", _on_move_state_changed):
            manager.move_controller.connect("move_state_changed", _on_move_state_changed)
    
    # Create check timer to periodically check tower types
    check_timer = Timer.new()
    check_timer.wait_time = 0.5
    check_timer.one_shot = false
    manager.add_child(check_timer)
    check_timer.timeout.connect(_on_check_timer)
    check_timer.start()
    
    # Identify the type of the first tower
    first_tower_type = identify_existing_tower_type()
    
    # Reset state variables
    same_tower_built = false
    move_mode_activated = false
    tower_merged = false
    
    # Start tutorial
    super.enter()
    print("Merge Tower Tutorial started - Looking for tower type: ", first_tower_type)

func exit():
    # Disconnect signals
    if manager.move_controller:
        if manager.move_controller.is_connected("move_state_changed", _on_move_state_changed):
            manager.move_controller.disconnect("move_state_changed", _on_move_state_changed)
    
    # Clean up timers
    if check_timer:
        check_timer.stop()
        check_timer.queue_free()
    
    super.exit()

func show_current_step():
    match current_step:
        0: # Introduction
            manager.tutorial_ui.set_title("Merging Towers")
            manager.tutorial_ui.set_content("Towers of the same type can be merged to create more powerful towers! This is a key strategy for defending against tougher enemies.")
            manager.tutorial_ui.show_next_button(true)
            manager.tutorial_ui.show_panel()
            
        1: # Build same tower type
            var tower_name = first_tower_type if first_tower_type != "" else "tower"
            manager.tutorial_ui.set_title("Build Another Tower")
            manager.tutorial_ui.set_content("Build another " + tower_name + " tower. Click on a tower base and select the same tower type as before.")
            manager.tutorial_ui.show_next_button(false)
            manager.tutorial_ui.show_panel()
            
        2: # Enter move mode
            manager.tutorial_ui.set_title("Enter Move Mode")
            manager.tutorial_ui.set_content("Now press M to enter move mode. We'll merge these two towers together to make them stronger!")
            manager.tutorial_ui.show_next_button(false)
            manager.tutorial_ui.show_panel()
            
        3: # Merge towers
            manager.tutorial_ui.set_title("Merge Towers")
            manager.tutorial_ui.set_content("Select one of the towers, then place it on top of the other tower of the same type. This will merge them into a more powerful tower!")
            manager.tutorial_ui.show_next_button(false)
            manager.tutorial_ui.show_panel()

func update(delta: float):
    # Check for step completion
    match current_step:
        1: # Waiting for same tower type to be built
            if same_tower_built:
                next_step()
                
        2: # Waiting for move mode activation
            if move_mode_activated:
                next_step()
                
        3: # Waiting for towers to be merged
            if tower_merged:
                next_step()

func identify_existing_tower_type() -> String:
    # Get all regular towers (not base towers)
    var towers = manager.get_tree().get_nodes_in_group("Towers")
    
    # Find the first tower and get its type
    for tower in towers:
        if tower.has_method("get_type"):
            return tower.get_type()
    
    # Default if no tower type found
    return "Basic"

func check_for_same_tower_type():
    # Get all regular towers (not base towers)
    var towers = manager.get_tree().get_nodes_in_group("Towers")
    
    # Count towers of first_tower_type
    var count = 0
    for tower in towers:
        if tower.has_method("get_type") and tower.get_type() == first_tower_type:
            count += 1
    
    # If we have at least 2 towers of the same type, mark this step as complete
    if count >= 2:
        same_tower_built = true
        print("Found at least 2 towers of type: ", first_tower_type)

func check_for_tower_merged():
    # Get all regular towers (not base towers)
    var towers = manager.get_tree().get_nodes_in_group("Towers")
    
    # Check for level 2 or higher towers of the same type
    for tower in towers:
        if tower.has_method("get_type") and tower.has_method("get_level"):
            if tower.get_type() == first_tower_type and tower.get_level() >= 2:
                tower_merged = true
                print("Tower merged detected! Level: ", tower.get_level())
                break

func _on_move_state_changed(is_active):
    move_mode_activated = is_active

func _on_check_timer():
    # Periodic checks based on current step
    match current_step:
        1: # Check if another tower of the same type was built
            if not same_tower_built:
                check_for_same_tower_type()
                
        3: # Check if towers were merged
            if not tower_merged:
                check_for_tower_merged()
