extends Node2D

# Color constants for button states
const COLOR_NORMAL = Color("d1851e")  # Normal button color
const COLOR_HOVER = Color("ffd569")   # Hovered button color

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Set initial button colors
    if $CanvasLayer/StartButton/Label:
        $CanvasLayer/StartButton/Label.add_theme_color_override("font_color", COLOR_NORMAL)
    if $CanvasLayer/ExitButton/Label:
        $CanvasLayer/ExitButton/Label.add_theme_color_override("font_color", COLOR_NORMAL)
    
    # Check if user has saved credentials for auto-login
    var saved_username = Config.get_saved_username()
    if saved_username != "":
        print("Found saved credentials for: " + saved_username)
        # Could automatically show login screen with username filled in
        # Auto-login is another option but is typically not done for games without user confirmation

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

func _on_start_button_pressed() -> void:
    print("Showing login screen...")
    # Instead of changing scene, instantiate the login screen as an overlay
    var login_scene = load("res://Scene/Menu/Login.tscn").instantiate()
    add_child(login_scene)

func _on_start_button_mouse_entered() -> void:
    # Change text color to hover color
    if $CanvasLayer/StartButton/Label:
        $CanvasLayer/StartButton/Label.add_theme_color_override("font_color", COLOR_HOVER)

func _on_start_button_mouse_exited() -> void:
    # Change text color back to normal
    if $CanvasLayer/StartButton/Label:
        $CanvasLayer/StartButton/Label.add_theme_color_override("font_color", COLOR_NORMAL)

func _on_exit_button_pressed() -> void:
    print("Exiting game...")
    # Quit the game when Exit is pressed
    get_tree().quit()

func _on_exit_button_mouse_entered() -> void:
    # Change text color to hover color
    if $CanvasLayer/ExitButton/Label:
        $CanvasLayer/ExitButton/Label.add_theme_color_override("font_color", COLOR_HOVER)

func _on_exit_button_mouse_exited() -> void:
    # Change text color back to normal
    if $CanvasLayer/ExitButton/Label:
        $CanvasLayer/ExitButton/Label.add_theme_color_override("font_color", COLOR_NORMAL)
