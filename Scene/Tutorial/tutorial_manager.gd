extends Node

class_name TutorialManager

var current_state: TutorialState = null
var tutorial_states = {}
var tutorial_ui: TutorialUI = null
var tutorial_ui_canvas_layer: CanvasLayer = null
var tutorial_finished_scene = preload("res://Scene/Tutorial/tutorial_finished.tscn")
var tutorial_finished_instance = null

var level_node
var build_controller
var move_controller

signal tutorial_completed(tutorial_name)
signal tutorial_step_completed(tutorial_name, step)
signal all_tutorials_completed

func _ready():
    print("config user data:",Config.user_data)
    # Create canvas layer for UI elements
    tutorial_ui_canvas_layer = CanvasLayer.new()
    tutorial_ui_canvas_layer.layer = 10
    add_child(tutorial_ui_canvas_layer)
    
    # Create tutorial UI
    tutorial_ui = preload("res://Scene/Tutorial/tutorial_ui.tscn").instantiate()
    tutorial_ui_canvas_layer.add_child(tutorial_ui)
    tutorial_ui.connect("next_pressed", Callable(self, "_on_next_pressed"))

func setup(level, build_ctrl, move_ctrl):
    level_node = level
    build_controller = build_ctrl
    build_controller.can_build_tower = false
    move_controller = move_ctrl
    
    # Register tutorial states
    register_tutorial_states()
    
    # Debug - print registered tutorials
    print("Registered tutorials: ", tutorial_states.keys())

func register_tutorial_states():
    # Create and register tutorial states
    tutorial_states["move_wasd"] = MoveWASDTutorial.new(self)  # Add WASD movement tutorial
    tutorial_states["build_mode"] = BuildModeTutorial.new(self)
    tutorial_states["move_tower"] = MoveTowerTutorial.new(self)
    tutorial_states["build_tower"] = BuildTowerTutorial.new(self)
    tutorial_states["merge_tower"] = MergeTowerTutorial.new(self)
    tutorial_states["defeat_enemy"] = DefeatEnemyTutorial.new(self)
    
    print("Registered tutorial states: ", tutorial_states.keys())

func start_tutorial(tutorial_name: String):
    print("TutorialManager: Starting tutorial: " + tutorial_name)
    
    # First hide any current UI
    tutorial_ui.hide_panel()
    
    # Enable tower building before build_tower tutorial
    if tutorial_name == "build_tower" and not build_controller.can_build_tower:
        print("Enabling tower building for build tutorial")
        build_controller.can_build_tower = true
    
    if tutorial_states.has(tutorial_name):
        if current_state:
            current_state.exit()
            
        current_state = tutorial_states[tutorial_name]
        current_state.enter()
        
        print("Tutorial started: " + tutorial_name)
    else:
        print("ERROR: Tutorial not found: " + tutorial_name)
        
        # Debug - print available tutorials
        print("Available tutorials: ", tutorial_states.keys())

func complete_tutorial(tutorial_name: String):
    print("Tutorial completed: " + tutorial_name)
    tutorial_ui.hide_panel()  
    
    if current_state and current_state == tutorial_states[tutorial_name]:
        current_state.exit()
        current_state = null
        
        # Print a success message for debugging
        print("Successfully cleaned up tutorial: " + tutorial_name)
    
    # Enable tower building after move_tower tutorial
    if tutorial_name == "move_tower":
        print("Enabling tower building")
        build_controller.can_build_tower = true
    
    emit_signal("tutorial_completed", tutorial_name)

func show_tutorial_finished():
    print("Showing tutorial finished panel")
    
    # Hide current tutorial UI if any
    tutorial_ui.hide_panel()
    
    # Clean up any existing tutorial state
    if current_state:
        current_state.exit()
        current_state = null
    
    # Create and show the tutorial finished panel
    if tutorial_finished_instance:
        tutorial_finished_instance.queue_free()
    
    tutorial_finished_instance = tutorial_finished_scene.instantiate()
    # Add to canvas layer instead of directly to this node
    tutorial_ui_canvas_layer.add_child(tutorial_finished_instance)
    
    # Connect to the next/continue button if it exists
    if tutorial_finished_instance.has_node("Panel/VBoxContainer/ButtonContainer/NextButton"):
        var next_button = tutorial_finished_instance.get_node("Panel/VBoxContainer/ButtonContainer/NextButton")
        next_button.pressed.connect(_on_tutorial_finished_continue)
    
    # Signal that all tutorials are completed
    emit_signal("all_tutorials_completed")

func _on_tutorial_finished_continue():
    # Handle continue button press from tutorial finished panel
    if tutorial_finished_instance:
        tutorial_finished_instance.queue_free()
        tutorial_finished_instance = null
    
    print("Tutorial sequence completed and acknowledged by player")
    
    # Update the user's tutorial completion status
    var config = Config
    if config and config.user_data:
        print("Updating tutorial completion status in user profile")
        var success = config.update_tutorial_completed(true)
        if success:
            print("Tutorial completion status update request sent")
        else:
            print("Failed to send tutorial completion update")
    
    # Change to LevelSelect scene
    var level_select_path = "res://Scene/Menu/LevelSelect.tscn"
    print("Transitioning to level select: " + level_select_path)
    get_tree().change_scene_to_file(level_select_path)

func _process(delta):
    if current_state:
        current_state.update(delta)

func _on_next_pressed():
    if current_state:
        current_state.next_step()
