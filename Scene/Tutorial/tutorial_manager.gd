extends Node

class_name TutorialManager

var current_state: TutorialState = null
var tutorial_states = {}
var tutorial_ui: TutorialUI = null

var level_node
var build_controller
var move_controller

signal tutorial_completed(tutorial_name)
signal tutorial_step_completed(tutorial_name, step)

func _ready():
    # Create tutorial UI
    tutorial_ui = preload("res://Scene/Tutorial/tutorial_ui.tscn").instantiate()
    add_child(tutorial_ui)
    tutorial_ui.connect("next_pressed", Callable(self, "_on_next_pressed"))

func setup(level, build_ctrl, move_ctrl):
    level_node = level
    build_controller = build_ctrl
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
    
    print("Registered tutorial states: ", tutorial_states.keys())

func start_tutorial(tutorial_name: String):
    print("TutorialManager: Starting tutorial: " + tutorial_name)
    
    # First hide any current UI
    tutorial_ui.hide_panel()
    
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
    
    emit_signal("tutorial_completed", tutorial_name)

func _process(delta):
    if current_state:
        current_state.update(delta)

func _on_next_pressed():
    if current_state:
        current_state.next_step()
