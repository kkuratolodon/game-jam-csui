extends TutorialState
class_name MoveTowerTutorial

var move_mode_activated := false
var tower_selected := false
var tower_moved := false
var move_mode_canceled := false
var tracking_tower: Node = null

func _init(tutorial_manager):
    super._init(tutorial_manager)
    tutorial_name = "move_tower"
    total_steps = 5  # Updated from 4 to 5 to include new intro step

func enter():
    # Connect to move controller signals
    if manager.move_controller:
        if not manager.move_controller.is_connected("move_state_changed", _on_move_state_changed):
            manager.move_controller.connect("move_state_changed", _on_move_state_changed)
    
    # Reset variables
    move_mode_activated = false
    tower_selected = false
    tower_moved = false
    move_mode_canceled = false
    
    # Connect to tower selection signal if available
    if manager.move_controller:
        if manager.move_controller.has_signal("tower_selected") and not manager.move_controller.is_connected("tower_selected", _on_tower_selected):
            manager.move_controller.connect("tower_selected", _on_tower_selected)
    
    # Start with first step
    super.enter()
    
    print("Move Tower Tutorial started")

func exit():
    # Disconnect signals
    if manager.move_controller:
        if manager.move_controller.is_connected("move_state_changed", _on_move_state_changed):
            manager.move_controller.disconnect("move_state_changed", _on_move_state_changed)
        
        if manager.move_controller.has_signal("tower_selected") and manager.move_controller.is_connected("tower_selected", _on_tower_selected):
            manager.move_controller.disconnect("tower_selected", _on_tower_selected)
    
    super.exit()

func show_current_step():
    match current_step:
        0: # General introduction
            manager.tutorial_ui.set_title("Moving Towers")
            manager.tutorial_ui.set_content("Now let's learn how to move and reposition your towers! Moving towers allows you to optimize your defense layout as the game progresses.")
            manager.tutorial_ui.show_next_button(true)
            manager.tutorial_ui.show_panel()
            
        1: # Instruction to press M
            manager.tutorial_ui.set_title("Activate Move Mode")
            manager.tutorial_ui.set_content("Press the M key to enter move mode. You'll see a blue indicator at the bottom left of your screen.")
            manager.tutorial_ui.show_next_button(false)
            manager.tutorial_ui.show_panel()
            
        2: # Selecting towers
            manager.tutorial_ui.set_title("Selecting Towers")
            manager.tutorial_ui.set_content("Click on a tower base to select it for moving. You can reposition base towers.")
            manager.tutorial_ui.show_next_button(false)
            manager.tutorial_ui.show_panel()
            
        3: # Moving towers
            manager.tutorial_ui.set_title("Moving Towers")
            manager.tutorial_ui.set_content("Great! Now click to place the tower base in a new valid location. Make sure the preview is green before placing.")
            manager.tutorial_ui.show_next_button(false)
            manager.tutorial_ui.show_panel()
            
        4: # Cancel move mode
            manager.tutorial_ui.set_title("Cancel Move Mode")
            manager.tutorial_ui.set_content("Perfect! Now press M again to exit move mode.")
            manager.tutorial_ui.show_next_button(false)
            manager.tutorial_ui.show_panel()

func update(delta: float):
    # Check for step completion
    match current_step:
        1: # Waiting for move mode activation
            if move_mode_activated:
                next_step()
                
        2: # Waiting for tower selection
            if tower_selected:
                next_step()
            else:
                check_for_tower_selection()
                
        3: # Waiting for tower movement
            check_for_tower_movement() # Continuously check for tower movement
            if tower_moved:
                next_step()
                
        4: # Waiting for move mode cancellation
            if !move_mode_activated:
                move_mode_canceled = true
                next_step()

func _on_move_state_changed(is_active):
    print("Move mode changed: ", is_active)
    move_mode_activated = is_active
    
    # If move mode was deactivated and we're on cancel step, mark as completed
    if !is_active && current_step == 4:
        move_mode_canceled = true

func check_for_tower_movement():
    # print("Checking for tower movement...")
    if manager.move_controller:
        # Check if any tower has been moved
        if manager.move_controller.recently_moved_towers.size() > 0:
            tower_moved = true
            print("Tutorial detected tower movement!")

func check_for_tower_selection():
    if manager.move_controller and manager.move_controller.selected_tower != null:
        # Check if the selected tower is in the "Basetower" group
        if manager.move_controller.selected_tower.is_in_group("BaseTower"):
            tracking_tower = manager.move_controller.selected_tower
            tower_selected = true
            print("Tutorial detected tower selection!")
        else:
            print("Selected tower is not a base tower")
            tower_selected = false
        print("Tutorial detected tower selection!")

func _on_tower_selected():
    if current_step == 2:
        tower_selected = true
        print("Tower selection signal received!")
