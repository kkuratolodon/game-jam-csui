extends TutorialState
class_name BuildModeTutorial

var build_mode_activated := false
var tower_placed := false
var build_mode_canceled := false
var highlight_timer: Timer
var initial_tower_count := 0  # Track initial tower count

func _init(tutorial_manager):
    super._init(tutorial_manager)
    tutorial_name = "build_mode"
    total_steps = 4  # Update from 3 to 4 to include cancel build mode step

func enter():
    # Setup highlight rect for UI elements
    
    # Timer for pulsing highlight effect
    highlight_timer = Timer.new()
    highlight_timer.wait_time = 0.6
    highlight_timer.one_shot = false
    manager.add_child(highlight_timer)
    highlight_timer.timeout.connect(_on_highlight_timer)
    highlight_timer.start()
    
    # Connect to build controller signals only
    if manager.build_controller:
        if not manager.build_controller.is_connected("build_state_changed", _on_build_state_changed):
            manager.build_controller.connect("build_state_changed", _on_build_state_changed)
    
    # Start with first step
    super.enter()

func exit():
    # Disconnect signals
    if manager.build_controller:
        if manager.build_controller.is_connected("build_state_changed", _on_build_state_changed):
            manager.build_controller.disconnect("build_state_changed", _on_build_state_changed)
    
    # Clean up highlight elements
    if highlight_timer:
        highlight_timer.stop()
        highlight_timer.queue_free()
    
    super.exit()

func show_current_step():
    match current_step:
        0: # Introduction
            manager.tutorial_ui.set_title("Build Mode")
            manager.tutorial_ui.set_content("Let's learn how to build tower bases! These are platforms where you'll place defensive towers.")
            manager.tutorial_ui.show_next_button(true)
            manager.tutorial_ui.show_panel()
            
        1: # Enter build mode
            manager.tutorial_ui.set_title("Build Mode")
            manager.tutorial_ui.set_content("First, press B to enter build mode. You'll see a green indicator at the bottom left of your screen.")
            manager.tutorial_ui.show_next_button(false)
            manager.tutorial_ui.show_panel()
            build_mode_activated = false  # Reset in case we're returning to this step
            
        2: # Place a tower
            manager.tutorial_ui.set_title("Placing Tower Bases")
            manager.tutorial_ui.set_content("You're now in build mode! Move your mouse to position the tower base. Click to place it when the preview is green.")
            manager.tutorial_ui.show_next_button(false)
            manager.tutorial_ui.show_panel()
            tower_placed = false  # Reset in case we're returning to this step
            
            # Store the initial tower count when entering this step
            initial_tower_count = count_base_towers()
            print("Initial tower count: ", initial_tower_count)
            
        3: # Cancel build mode
            manager.tutorial_ui.set_title("Cancel Build Mode")
            manager.tutorial_ui.set_content("Great job! Now press B again to exit build mode.")
            manager.tutorial_ui.show_next_button(false)
            manager.tutorial_ui.show_panel()
            build_mode_canceled = false  # Reset in case we're returning to this step

func update(delta: float):
    # Check for step completion
    match current_step:
        1: # Waiting for build mode activation
            if build_mode_activated:
                next_step()
                
        2: # Waiting for tower placement
            if !tower_placed:
                # Continuously check for tower placement during this step
                check_for_tower_placement()
            else:
                next_step()
                
        3: # Waiting for build mode cancellation
            if build_mode_canceled:
                next_step()

func _on_build_state_changed(is_active):
    if current_step == 1 && is_active:
        build_mode_activated = true
    
    if current_step == 3 && !is_active:
        build_mode_canceled = true

func check_for_tower_placement():
    # Count current base towers
    var current_tower_count = count_base_towers()
    print("Current tower count: ", current_tower_count, ", Initial count: ", initial_tower_count)
    
    # Check if tower count has increased since entering this step
    if current_tower_count > initial_tower_count:
        tower_placed = true
        print("Tower placed detected! Count increased from ", initial_tower_count, " to ", current_tower_count)
        return

# Helper function to count actual (non-preview) base towers
func count_base_towers() -> int:
    var count = 0
    var base_towers = manager.get_tree().get_nodes_in_group("BaseTower")
    for tower in base_towers:
        if tower.name == "PreviewTower" or "preview" in tower.name.to_lower():
            continue  # Skip preview towers
        count += 1
    return count

func _on_highlight_timer():
    # This just helps update the pulsing effect
    pass
