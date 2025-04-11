extends Control

@onready var username_input = $CanvasLayer/Panel/VBoxContainer/UsernameInput
@onready var password_input = $CanvasLayer/Panel/VBoxContainer/PasswordInput
@onready var message_label = $CanvasLayer/Panel/VBoxContainer/MessageLabel
@onready var login_button = $CanvasLayer/Panel/VBoxContainer/ButtonContainer/LoginButton
@onready var register_button = $CanvasLayer/Panel/VBoxContainer/RegisterContainer/RegisterButton
@onready var back_button = $CanvasLayer/Panel/VBoxContainer/BackContainer/BackButton

# Color constants for button states
const COLOR_NORMAL = Color("d1851e")  # Normal button color
const COLOR_HOVER = Color("ffd569")   # Hovered button color

var config = Config
var main_menu_scene = null

func _ready():
    # Clear any previous messages
    message_label.text = ""
    
    # Set initial button text colors
    var login_label = login_button.get_node("Label")
    var register_label = register_button.get_node("Label")
    var back_label = back_button.get_node("Label")
    
    if login_label:
        login_label.add_theme_color_override("font_color", COLOR_NORMAL)
    if register_label:
        register_label.add_theme_color_override("font_color", COLOR_NORMAL)
    if back_label:
        back_label.add_theme_color_override("font_color", COLOR_NORMAL)
    
    # Connect button hover signals
    login_button.mouse_entered.connect(func(): _on_button_mouse_entered(login_button))
    login_button.mouse_exited.connect(func(): _on_button_mouse_exited(login_button))
    
    register_button.mouse_entered.connect(func(): _on_button_mouse_entered(register_button))
    register_button.mouse_exited.connect(func(): _on_button_mouse_exited(register_button))
    
    back_button.mouse_entered.connect(func(): _on_button_mouse_entered(back_button))
    back_button.mouse_exited.connect(func(): _on_button_mouse_exited(back_button))

func _on_button_mouse_entered(button):
    # Change text color to hover color
    if button.get_node("Label"):
        button.get_node("Label").add_theme_color_override("font_color", COLOR_HOVER)

func _on_button_mouse_exited(button):
    # Change text color back to normal
    if button.get_node("Label"):
        button.get_node("Label").add_theme_color_override("font_color", COLOR_NORMAL)

func _on_login_button_pressed():
    var username = username_input.text.strip_edges()
    var password = password_input.text
    
    # Validate inputs
    if username.is_empty() or password.is_empty():
        message_label.text = "Please enter both username and password"
        return
    
    # Disable login button during API call
    login_button.disabled = true
    message_label.text = "Logging in..."
    
    # Call the user data API
    var success = config.get_user_data(username, password)
    print(success)
    if !success:
        message_label.text = "Network error. Please try again."
        login_button.disabled = false
        return
    
    # Wait for the API response
    config.user_data_updated.connect(_on_login_completed, CONNECT_ONE_SHOT)

func _on_login_completed():
    login_button.disabled = false
    
    if config.user_data:
        # Login successful - Use a brighter green color
        message_label.modulate = Color(0.3, 1.0, 0.3)
        message_label.text = "Login successful!"
        
        # Save credentials for future auto-login
        config.save_credentials(config.username, config.password)
        
        # Check if tutorial has been completed
        var tutorial_completed = config.user_data.get("tutorial_complete")
        
        # Create fade animation before scene change
        var tween = create_tween()
        tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
        await tween.finished
        
        # Navigate to appropriate scene with fancy transition
        if tutorial_completed:
            # If tutorial completed, go to level select with iris transition
            SceneTransition.change_scene("res://Scene/Menu/LevelSelect.tscn", 
                                         SceneTransition.TransitionType.IRIS, 
                                         0.8)
        else:
            # If tutorial not completed, go to tutorial with fade transition
            SceneTransition.change_scene("res://Scene/Level/tutorial.tscn", 
                                         SceneTransition.TransitionType.FADE, 
                                         0.7)
    else:
        # Login failed
        message_label.text = "Invalid username or password. Please try again."

func _on_register_button_pressed():
    print("Register button pressed")
    
    # Create register scene
    var register_scene = load("res://Scene/Menu/Register.tscn").instantiate()
    # Add it to the same parent node
    get_parent().add_child(register_scene)
    print("Register scene instantiated and added")
    
    # Make sure register panel is visible and positioned correctly
    if register_scene.has_node("CanvasLayer"):
        var canvas = register_scene.get_node("CanvasLayer")
        canvas.visible = true
        canvas.layer = 15  # Ensure it's on top but not too high
        
        if canvas.has_node("Panel"):
            var panel = canvas.get_node("Panel")
            panel.visible = true
            
            # Store the center position of the panel and adjust it to be slightly lower
            var center_position = panel.position
            var target_position = Vector2(center_position.x, center_position.y)  # Adjust by 50 pixels down
            
            # Start from above
            panel.position.y = -600
            panel.modulate = Color(1, 1, 1, 0)
            
            # Simple animation to the adjusted position
            var tween = create_tween()
            tween.set_ease(Tween.EASE_OUT)
            tween.set_trans(Tween.TRANS_BACK)
            tween.tween_property(panel, "position", target_position, 0.5)
            tween.parallel().tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3)
            print("Register panel animation started")
    
    # Hide login panel immediately
    $CanvasLayer.visible = false
    
    # Don't queue_free yet - just hide it so we can come back
    # (The register.gd will handle this)

func _on_back_button_pressed():
    # Create closing animation
    var tween = create_tween()
    tween.tween_property($CanvasLayer/Panel, "position:y", -600, 0.5)
    tween.parallel().tween_property($CanvasLayer/BackgroundOverlay, "modulate", Color(1, 1, 1, 0), 0.3)
    await tween.finished
    
    # Remove self, which will return to main menu
    queue_free()
