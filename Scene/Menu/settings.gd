extends Node2D

# Color constants for button states
const COLOR_NORMAL = Color("ffffff")  # Normal button color
const COLOR_HOVER = Color("cccccc")   # Light gray hover color
const COLOR_ACTIVE = Color("666666")  # Dark gray when settings panel is active
# Animation constants
const HOVER_SCALE = Vector2(1.1, 1.1)
const NORMAL_SCALE = Vector2(1.0, 1.0)
const CLICK_SCALE = Vector2(0.9, 0.9)

# Keep track of previous game state
var was_paused = false
var is_settings_active = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Set this node to process even when the game is paused
    process_mode = Node.PROCESS_MODE_ALWAYS

    # Connect hover signals for all buttons
    var buttons = [
        $CanvasLayer2/SettingPanel/BackButton,
        $CanvasLayer2/SettingPanel/CloseButton, 
        $CanvasLayer2/SettingPanel/RestartButton,
        $CanvasLayer2/SettingsButton
    ]
    
    for button in buttons:
        if button:
            # Connect hover signals
            button.mouse_entered.connect(func(): _on_button_mouse_entered(button))
            button.mouse_exited.connect(func(): _on_button_mouse_exited(button))
            button.button_down.connect(func(): _on_button_down(button))
            button.button_up.connect(func(): _on_button_up(button))
            
            # Set initial color for settings button
            if button == $CanvasLayer2/SettingsButton:
                button.modulate = COLOR_NORMAL

# Handle button hover effect
func _on_button_mouse_entered(button):
    # For settings button, don't change color on hover if settings panel is active
    if button == $CanvasLayer2/SettingsButton and not is_settings_active:
        button.modulate = COLOR_HOVER
    
    # Add a subtle scale effect
    var tween = create_tween()
    tween.tween_property(button, "scale", HOVER_SCALE, 0.1)

# Handle button hover exit effect
func _on_button_mouse_exited(button):
    # For settings button, restore appropriate color based on active state
    if button == $CanvasLayer2/SettingsButton:
        button.modulate = COLOR_ACTIVE if is_settings_active else COLOR_NORMAL
    
    # Restore original scale
    var tween = create_tween()
    tween.tween_property(button, "scale", NORMAL_SCALE, 0.1)

# Button press animation
func _on_button_down(button):
    var tween = create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_IN)
    tween.tween_property(button, "scale", CLICK_SCALE, 0.05)

# Button release animation
func _on_button_up(button):
    var tween = create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_OUT)
    
    # Go back to hover scale if still hovered, otherwise normal scale
    var target_scale = HOVER_SCALE if button.is_hovered() else NORMAL_SCALE
    tween.tween_property(button, "scale", target_scale, 0.1)

# Navigate back to level select
func _on_back_button_pressed() -> void:
    # Unpause the game if it was paused
    if get_tree().paused:
        get_tree().paused = false
    
    # Create a fade out animation
    var tween = create_tween()
    tween.tween_property($CanvasLayer2/SettingPanel, "modulate", Color(1, 1, 1, 0), 0.3)
    tween.parallel().tween_property($CanvasLayer2/DarkOverlay, "modulate", Color(1, 1, 1, 0), 0.3)
    await tween.finished
    
    # Transition to level select scene
    SceneTransition.change_scene("res://Scene/Menu/LevelSelect.tscn", 
                               SceneTransition.TransitionType.IRIS, 
                               0.7)

# Close the settings panel
func _on_close_button_pressed() -> void:
    # Animate closing the panel
    var tween = create_tween()
    tween.tween_property($CanvasLayer2/SettingPanel, "modulate", Color(1, 1, 1, 0), 0.3)
    tween.parallel().tween_property($CanvasLayer2/DarkOverlay, "modulate", Color(1, 1, 1, 0), 0.3)
    await tween.finished
    
    # Hide panels
    $CanvasLayer2/SettingPanel.visible = false
    $CanvasLayer2/DarkOverlay.visible = false
    
    # Update settings state and button color
    is_settings_active = false
    var settings_button = $CanvasLayer2/SettingsButton
    if settings_button:
        settings_button.modulate = COLOR_HOVER if settings_button.is_hovered() else COLOR_NORMAL
    
    # Unpause the game if it was paused
    if get_tree().paused:
        get_tree().paused = false

# Restart the current scene
func _on_restart_button_pressed() -> void:
    # Get the current scene path
    var current_scene = get_tree().current_scene.scene_file_path
    
    # Unpause the game if it was paused
    if get_tree().paused:
        get_tree().paused = false
    
    # Create a fade out animation
    var tween = create_tween()
    tween.tween_property($CanvasLayer2/SettingPanel, "modulate", Color(1, 1, 1, 0), 0.3)
    tween.parallel().tween_property($CanvasLayer2/DarkOverlay, "modulate", Color(1, 1, 1, 0), 0.3)
    await tween.finished
    
    # Transition to same scene (restart)
    SceneTransition.change_scene(current_scene, 
                               SceneTransition.TransitionType.SWEEP, 
                               0.7)

# Toggle settings panel visibility
func _on_settings_button_pressed() -> void:
    if $CanvasLayer2/SettingPanel.visible:
        # Panel is visible, hide it (same as close)
        _on_close_button_pressed()
    else:
        # Store current pause state
        was_paused = get_tree().paused
        
        # Update settings state and button color
        is_settings_active = true
        var settings_button = $CanvasLayer2/SettingsButton
        if settings_button:
            settings_button.modulate = COLOR_ACTIVE
        
        # Pause the game
        get_tree().paused = true
        
        # Show panel with animation
        $CanvasLayer2/SettingPanel.visible = true
        $CanvasLayer2/DarkOverlay.visible = true
        
        $CanvasLayer2/SettingPanel.modulate = Color(1, 1, 1, 0)
        $CanvasLayer2/DarkOverlay.modulate = Color(1, 1, 1, 0)
        
        var tween = create_tween()
        tween.tween_property($CanvasLayer2/SettingPanel, "modulate", Color(1, 1, 1, 1), 0.3)
        tween.parallel().tween_property($CanvasLayer2/DarkOverlay, "modulate", Color(1, 1, 1, 1), 0.3)

