extends Control

@onready var username_input = $CanvasLayer/Panel/VBoxContainer/UsernameInput
@onready var display_name_input = $CanvasLayer/Panel/VBoxContainer/DisplayNameInput
@onready var password_input = $CanvasLayer/Panel/VBoxContainer/PasswordInput
@onready var confirm_password_input = $CanvasLayer/Panel/VBoxContainer/ConfirmPasswordInput
@onready var message_label = $CanvasLayer/Panel/VBoxContainer/MessageLabel
@onready var register_button = $CanvasLayer/Panel/VBoxContainer/ButtonContainer/RegisterButton
@onready var back_button = $CanvasLayer/Panel/VBoxContainer/BackContainer/BackButton

# Color constants for button states
const COLOR_NORMAL = Color("d1851e")  # Normal button color
const COLOR_HOVER = Color("ffd569")   # Hovered button color

var config = Config

func _ready():
    # Make extra sure we're visible
    modulate = Color(1, 1, 1, 1)
    visible = true
    
    # Ensure CanvasLayer is visible
    if $CanvasLayer:
        $CanvasLayer.visible = true
        $CanvasLayer.layer = 100
        
        # Set panel visibility
        if $CanvasLayer/Panel:
            $CanvasLayer/Panel.visible = true
            $CanvasLayer/Panel.modulate = Color(1, 1, 1, 1)
            print("Register panel visibility explicitly set")
    
    # Clear any previous messages
    message_label.text = ""
    
    # Set initial button text colors
    var register_label = register_button.get_node("Label")
    var back_label = back_button.get_node("Label")
    
    if register_label:
        register_label.add_theme_color_override("font_color", COLOR_NORMAL)
    if back_label:
        back_label.add_theme_color_override("font_color", COLOR_NORMAL)
    
    # Connect button hover signals
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

func _on_register_button_pressed():
    var username = username_input.text.strip_edges()
    var display_name = display_name_input.text.strip_edges()
    var password = password_input.text
    var confirm_password = confirm_password_input.text
    
    # Basic validation
    if username.is_empty() or display_name.is_empty() or password.is_empty() or confirm_password.is_empty():
        message_label.text = "Please fill in all fields"
        return
    
    if password != confirm_password:
        message_label.text = "Passwords do not match"
        return
    
    if username.length() < 4:
        message_label.text = "Username must be at least 4 characters"
        return
        
    if password.length() < 6:
        message_label.text = "Password must be at least 6 characters"
        return
    
    # Disable register button during API call
    register_button.disabled = true
    message_label.text = "Creating account..."
    
    # Call the registration API
    var success = config.register_user(username, display_name, password, confirm_password)
    if !success:
        message_label.text = "Network error. Please try again."
        register_button.disabled = false
        return
    
    # Wait for the API response
    config.user_data_updated.connect(_on_registration_completed, CONNECT_ONE_SHOT)

func _on_registration_completed():
    register_button.disabled = false
    
    if config.user_data:
        # Registration successful - Use a brighter green color
        message_label.modulate = Color(0.3, 1.0, 0.3)
        message_label.text = "Registration successful!"
        
        # Go back to login screen after a short delay
        await get_tree().create_timer(1.5).timeout
        _on_back_button_pressed()
    else:
        # Registration failed
        message_label.text = "Registration failed. Username may already be taken."

func _on_back_button_pressed():
    print("Back button pressed - returning to login")
    
    # First create a login scene
    var login_scene = load("res://Scene/Menu/Login.tscn").instantiate()
    # Add it to the same parent node
    get_parent().add_child(login_scene)
    print("Login scene instantiated and added")
    
    # Make sure login panel is visible and positioned correctly
    if login_scene.has_node("CanvasLayer"):
        var canvas = login_scene.get_node("CanvasLayer")
        canvas.visible = true
        canvas.layer = 15  # Ensure it's on top but not too high
        
        if canvas.has_node("Panel"):
            var panel = canvas.get_node("Panel")
            panel.visible = true
            
            # Store the center position of the panel and adjust it to be slightly lower
            var center_position = panel.position
            var target_position = Vector2(center_position.x, center_position.y)
            
            # Start from above
            panel.position.y = -600
            panel.modulate = Color(1, 1, 1, 0)
            
            # Simple animation to the adjusted position
            var tween = create_tween()
            tween.set_ease(Tween.EASE_OUT)
            tween.set_trans(Tween.TRANS_BACK)
            tween.tween_property(panel, "position", target_position, 0.5)
            tween.parallel().tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3)
            print("Login panel animation started")
    
    # Hide register panel immediately instead of destroying it
    $CanvasLayer.visible = false
    
    # IMPORTANT: Use a timer to delay the queue_free call
    # This gives the login scene time to properly establish itself
    var free_timer = Timer.new()
    add_child(free_timer)
    free_timer.wait_time = 0.7  # Wait longer than the animation duration
    free_timer.one_shot = true
    free_timer.timeout.connect(func(): queue_free())
    free_timer.start()
    
    print("Register scene hiding, will be removed after delay")
