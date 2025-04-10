extends Node2D

var tutorial_manager: TutorialManager = null
var build_controller
var move_controller
var current_tutorial_index = 0
# Make sure to only include tutorials that are available 
var tutorial_sequence = ["move_wasd", "build_mode", "move_tower", "build_tower", "merge_tower", "defeat_enemy"]

func _ready() -> void:
    Player.instance.money = 1000
    # Wait a moment before starting tutorials to ensure all nodes are ready
    await get_tree().create_timer(0.5).timeout
    
    # Find controllers
    build_controller = find_child("BuildController", true, false)
    move_controller = find_child("MoveController", true, false)
    
    if !build_controller or !move_controller:
        print("Warning: Build or Move controller not found!")
        return
    
    # Initialize tutorial manager
    tutorial_manager = TutorialManager.new()
    add_child(tutorial_manager)
    
    # Setup tutorial manager with required references
    tutorial_manager.setup(self, build_controller, move_controller)
    
    # Connect tutorial completion signal
    tutorial_manager.connect("tutorial_completed", Callable(self, "_on_tutorial_completed"))
    
    # Start with the first tutorial in the sequence
    start_next_tutorial()

func _process(delta: float) -> void:
    pass

func start_next_tutorial():
    if current_tutorial_index < tutorial_sequence.size():
        var next_tutorial = tutorial_sequence[current_tutorial_index]
        print("Starting tutorial: " + next_tutorial + " (index: " + str(current_tutorial_index) + ")")
        
        # Debug to check if the tutorial is registered before starting
        if tutorial_manager:
            var available_tutorials = tutorial_manager.get_available_tutorials() if tutorial_manager.has_method("get_available_tutorials") else []
            print("Available tutorials: ", available_tutorials)
            
        tutorial_manager.start_tutorial(next_tutorial)
        current_tutorial_index += 1
    else:
        print("All tutorials completed!")
        # Show the tutorial finished scene when all tutorials are completed
        if tutorial_manager:
            tutorial_manager.show_tutorial_finished()

# This function is called when a tutorial is completed
func _on_tutorial_completed(tutorial_name: String):
    print("Level received tutorial completed signal: " + tutorial_name)
    
    # Wait a short moment before starting next tutorial
    await get_tree().create_timer(0.5).timeout
    start_next_tutorial()
