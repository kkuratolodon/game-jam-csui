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
    # Show login screen
    var login_scene = load("res://Scene/Menu/Login.tscn").instantiate()
    get_parent().add_child(login_scene)
    queue_free()