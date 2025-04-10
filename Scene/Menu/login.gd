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
        
        # Navigate to appropriate scene after a short delay
        await get_tree().create_timer(0.5).timeout
        
        if tutorial_completed:
            # If tutorial completed, go to level select
            get_tree().change_scene_to_file("res://Scene/Menu/LevelSelect.tscn")
        else:
            # If tutorial not completed, go to tutorial
            get_tree().change_scene_to_file("res://Scene/Level/tutorial.tscn")
    else:
        # Login failed
        message_label.text = "Invalid username or password. Please try again."

func _on_register_button_pressed():
    # Show register screen
    var register_scene = load("res://Scene/Menu/Register.tscn").instantiate()
    get_parent().add_child(register_scene)
    queue_free()

func _on_back_button_pressed():
    # Remove self, which will return to main menu
    queue_free()
