extends Node2D

@export var level_buttons: Array[TextureButton]
@export var completed_texture: Texture
@export var not_completed_texture: Texture
@onready var button_node = $CanvasLayer/TextureRect/Buttons

# Animation constants
const HOVER_SCALE = Vector2(1.1, 1.1)
const NORMAL_SCALE = Vector2(1.0, 1.0)
const CLICK_SCALE = Vector2(0.9, 0.9)
const HOVER_TINT = Color(1.2, 1.2, 0.8, 1.0)  # Slight yellow tint
const NORMAL_TINT = Color(1.0, 1.0, 1.0, 1.0)

func _ready():
    # Check if we need to update tutorial completion
    if Engine.has_singleton("GlobalFlags"):
        var flags = Engine.get_singleton("GlobalFlags")
        if flags.has_method("get") and flags.get("tutorial_just_completed"):
            _update_tutorial_completion()
            flags.set("tutorial_just_completed", false)
    
    # Connect signals for level buttons
    for button in button_node.get_children():
        if button is TextureButton:
            button.pressed.connect(_on_level_button_pressed.bind(button.name))
            
            # Add animation signals
            button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
            button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
            button.button_down.connect(_on_button_down.bind(button))
            button.button_up.connect(_on_button_up.bind(button))
    
    # Connect back button - corrected path
    if has_node("CanvasLayer/BackButton"):
        var back_button = $CanvasLayer/BackButton
        back_button.pressed.connect(_on_back_button_pressed)
        back_button.mouse_entered.connect(_on_button_mouse_entered.bind(back_button))
        back_button.mouse_exited.connect(_on_button_mouse_exited.bind(back_button))
        back_button.button_down.connect(_on_button_down.bind(back_button))
        back_button.button_up.connect(_on_button_up.bind(back_button))
    
    # Alternative path for back button - if it's in a different location
    elif has_node("CanvasLayer/TextureRect/BackButton"):
        var back_button = $CanvasLayer/TextureRect/BackButton
        back_button.pressed.connect(_on_back_button_pressed)
        back_button.mouse_entered.connect(_on_button_mouse_entered.bind(back_button))
        back_button.mouse_exited.connect(_on_button_mouse_exited.bind(back_button))
        back_button.button_down.connect(_on_button_down.bind(back_button))
        back_button.button_up.connect(_on_button_up.bind(back_button))
    
    # Continue with normal initialization
    _initialize_level_select()

func _update_tutorial_completion():
    print("Level select detected tutorial was just completed")
    
    # Get the credentials from the current login
    var config = Config
    if config and config.user_data:
        # We should have valid credentials at this point because we just logged in
        if not config.username.is_empty() and not config.password.is_empty():
            print("Updating tutorial completion status with valid credentials")
            var success = config.update_tutorial_completed(true)
            if success:
                print("Tutorial completion status update sent successfully")
            else:
                print("Failed to send tutorial completion update request")
        else:
            print("ERROR: Missing credentials in Config singleton")
            print("Username empty: ", config.username.is_empty())
            print("Password empty: ", config.password.is_empty())
    else:
        print("ERROR: Config singleton or user_data not available")

func _initialize_level_select():
    print("Level select initialized")
    
    # Get the latest user data if needed
    var config = Config
    if config and config.user_data:
        _update_level_completion_status(config.user_data)
    else:
        # If user data isn't available yet, try to fetch it
        if not config.username.is_empty() and not config.password.is_empty():
            var success = config.get_user_data(config.username, config.password)
            if success:
                # Connect to the signal to update UI when data arrives
                config.user_data_updated.connect(_on_user_data_updated, CONNECT_ONE_SHOT)
        else:
            print("ERROR: No credentials available for fetching user data")
            # Default to showing all levels as incomplete
            _update_level_completion_status(null)

func _on_user_data_updated():
    var config = Config
    if config and config.user_data:
        _update_level_completion_status(config.user_data)
    else:
        print("User data update received but data is null")
        _update_level_completion_status(null)

func _update_level_completion_status(user_data):
    # Get the last completed level (default to 0 if not found or null)
    var last_completed = 0
    if user_data != null:
        last_completed = user_data.get("last_completed_level", 0)
    
    print("Last completed level: ", last_completed)
    
    # Update each level button's completion flag
    for button in button_node.get_children():
        if button is TextureButton:
            var level_number = int(button.name.substr(5))  # Extract number from "Level1"
            var completion_flag = button.get_node("CompletedFlag")
            
            if completion_flag:
                # Update texture based on completion status
                if level_number <= last_completed:
                    # Level is completed
                    completion_flag.texture = completed_texture
                else:
                    # Level is not completed
                    completion_flag.texture = not_completed_texture
                
                # Add a subtle animation to the completion flags
                var tween = create_tween()
                tween.set_trans(Tween.TRANS_BOUNCE)
                tween.set_ease(Tween.EASE_OUT)
                
                # Start with a slightly scaled down flag
                completion_flag.scale = Vector2(0.9, 0.9)
                # Animate to normal scale with a bounce effect
                tween.tween_property(completion_flag, "scale", Vector2(1.0, 1.0), 0.5)

func _on_level_button_pressed(button_name: String) -> void:
    # Extract level number from button name (e.g., "Level1" -> "1")
    var level_number = button_name.substr(5)
    print("Level " + level_number + " button pressed")
    
    # Animate only the UI elements, not the background
    if $CanvasLayer/TextureRect:
        var ui_tween = create_tween()
        ui_tween.set_parallel(true)
        ui_tween.tween_property($CanvasLayer/TextureRect, "modulate", Color(1, 1, 1, 0), 0.3)
        
        # If any other UI elements exist, fade them too
        if has_node("CanvasLayer/DarkOverlay"):
            ui_tween.tween_property($CanvasLayer/DarkOverlay, "modulate", Color(0, 0, 0, 0), 0.3)
        
        await ui_tween.finished
    
    # Use a transition that will look good with the background
    # The SWEEP type will create a nice horizontal sweep that keeps the background visible
    # until the last moment of transition
    SceneTransition.set_transition_color(Color(0.0, 0.0, 0.0, 0.95))  # Almost black, slightly transparent
    SceneTransition.change_scene("res://Scene/Level/Level" + level_number + ".tscn", 
                               SceneTransition.TransitionType.SWEEP, 
                               0.8)

func _on_back_button_pressed() -> void:
    print("Back button pressed - returning to main menu")
    
    # Play button click animation first
    var back_button = $CanvasLayer/BackButton if has_node("CanvasLayer/BackButton") else $CanvasLayer/TextureRect/BackButton
    if back_button:
        var click_tween = create_tween()
        click_tween.tween_property(back_button, "scale", CLICK_SCALE, 0.05)
        click_tween.tween_property(back_button, "scale", NORMAL_SCALE, 0.1)
        await click_tween.finished
    
    # Only animate UI elements
    var ui_tween = create_tween()
    ui_tween.set_parallel(true)
    ui_tween.tween_property($CanvasLayer/TextureRect, "position:y", 800, 0.4)
    
    if has_node("CanvasLayer/DarkOverlay"):
        ui_tween.tween_property($CanvasLayer/DarkOverlay, "modulate", Color(0, 0, 0, 0), 0.3)
    
    await ui_tween.finished
    
    # Use IRIS transition that will show a circular transition, keeping background visible
    # until the circle closes
    SceneTransition.set_transition_color(Color(0.0, 0.0, 0.0, 0.9))
    SceneTransition.change_scene("res://Scene/Menu/MainMenu.tscn", 
                               SceneTransition.TransitionType.IRIS, 
                               0.6)

# Button hover animation
func _on_button_mouse_entered(button: TextureButton) -> void:
    var tween = create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", HOVER_SCALE, 0.1)
    tween.parallel().tween_property(button, "modulate", HOVER_TINT, 0.1)

# Button unhover animation
func _on_button_mouse_exited(button: TextureButton) -> void:
    var tween = create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", NORMAL_SCALE, 0.1)
    tween.parallel().tween_property(button, "modulate", NORMAL_TINT, 0.1)

# Button press animation
func _on_button_down(button: TextureButton) -> void:
    var tween = create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_IN)
    tween.tween_property(button, "scale", CLICK_SCALE, 0.05)

# Button release animation
func _on_button_up(button: TextureButton) -> void:
    var tween = create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_OUT)
    
    # Go back to hover scale if still hovered, otherwise normal scale
    var target_scale = HOVER_SCALE if button.is_hovered() else NORMAL_SCALE
    var target_tint = HOVER_TINT if button.is_hovered() else NORMAL_TINT
    
    tween.tween_property(button, "scale", target_scale, 0.1)
    tween.parallel().tween_property(button, "modulate", target_tint, 0.1)
