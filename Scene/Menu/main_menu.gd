extends Node2D

# The path to the game's main scene
const GAME_SCENE = "res://Scene/Game/game.tscn"

# Color constants for button states
const COLOR_NORMAL = Color("d1851e")  # Normal button color
const COLOR_HOVER = Color("ffd569")   # Hovered button color

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

func _on_start_button_pressed() -> void:
    # Add login panel immediately
    var login_scene = load("res://Scene/Menu/Login.tscn").instantiate()
    add_child(login_scene)
    
    # Apply a subtle darkening effect to the background elements
    $CanvasLayer/Background.modulate = Color(0.7, 0.7, 0.7, 1.0)
    # Make dark overlay slightly more visible for better contrast with login panel
    $CanvasLayer/DarkOverlay.color = Color(0, 0, 0, 0.7)
    
    # Set up the login panel for animation
    if login_scene.has_node("CanvasLayer/Panel"):
        var panel = login_scene.get_node("CanvasLayer/Panel")
        panel.visible = true
        
        # Store the center position of the panel
        var center_position = panel.position
        
        # Start from above
        panel.position.y = -600
        panel.modulate = Color(1, 1, 1, 0)
        
        # Simple animation to the adjusted position
        var tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_BACK)
        tween.tween_property(panel, "position", center_position, 0.5)
        tween.parallel().tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3)

func _on_exit_button_pressed() -> void:
    # Add a short transition before quitting
    var tween = create_tween()
    tween.tween_property($CanvasLayer/Background, "modulate", Color(0, 0, 0, 0), 0.5)
    tween.parallel().tween_property($CanvasLayer/DarkOverlay, "modulate", Color(0, 0, 0, 0), 0.5)
    tween.parallel().tween_property($CanvasLayer/Logo, "modulate", Color(0, 0, 0, 0), 0.5)
    tween.parallel().tween_property($CanvasLayer/StartButton, "modulate", Color(0, 0, 0, 0), 0.5)
    tween.parallel().tween_property($CanvasLayer/ExitButton, "modulate", Color(0, 0, 0, 0), 0.5)
    await tween.finished
    get_tree().quit()

func _on_start_button_mouse_entered() -> void:
    # Change text color to hover color
    if $CanvasLayer/StartButton/Label:
        $CanvasLayer/StartButton/Label.add_theme_color_override("font_color", COLOR_HOVER)
    # Scale up the button slightly
    var tween = create_tween()
    tween.tween_property($CanvasLayer/StartButton, "scale", Vector2(2.9, 2.9), 0.2)

func _on_start_button_mouse_exited() -> void:
    # Change text color back to normal
    if $CanvasLayer/StartButton/Label:
        $CanvasLayer/StartButton/Label.add_theme_color_override("font_color", COLOR_NORMAL)
    # Scale back to normal
    var tween = create_tween()
    tween.tween_property($CanvasLayer/StartButton, "scale", Vector2(2.735, 2.735), 0.2)

func _on_exit_button_mouse_entered() -> void:
    # Change text color to hover color
    if $CanvasLayer/ExitButton/Label:
        $CanvasLayer/ExitButton/Label.add_theme_color_override("font_color", COLOR_HOVER)
    # Scale up the button slightly
    var tween = create_tween()
    tween.tween_property($CanvasLayer/ExitButton, "scale", Vector2(2.9, 2.9), 0.2)

func _on_exit_button_mouse_exited() -> void:
    # Change text color back to normal
    if $CanvasLayer/ExitButton/Label:
        $CanvasLayer/ExitButton/Label.add_theme_color_override("font_color", COLOR_NORMAL)
    # Scale back to normal
    var tween = create_tween()
    tween.tween_property($CanvasLayer/ExitButton, "scale", Vector2(2.735, 2.735), 0.2)
