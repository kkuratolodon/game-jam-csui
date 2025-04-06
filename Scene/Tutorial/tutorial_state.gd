class_name TutorialState
extends RefCounted

var manager
var current_step: int = 0
var total_steps: int = 0
var tutorial_name: String = ""

func _init(tutorial_manager):
    manager = tutorial_manager

func get_name() -> String:
    return tutorial_name

func enter():
    # Called when entering this tutorial state
    current_step = 0
    show_current_step()

func exit():
    # Called when exiting this tutorial state
    pass

func update(delta: float):
    # Called every frame while this tutorial state is active
    pass

func next_step():
    # Progress to the next step in the tutorial
    current_step += 1
    
    if current_step >= total_steps:
        manager.complete_tutorial(tutorial_name)
        return
        
    show_current_step()
    
    # Emit signal for step completion
    manager.emit_signal("tutorial_step_completed", tutorial_name, current_step - 1)

func show_current_step():
    # Update UI for the current step
    # This will be overridden in child classes
    pass
