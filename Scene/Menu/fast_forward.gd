extends Node2D

# Color constants for button states
const COLOR_NORMAL = Color("ffffff")  # Normal button color
const COLOR_HOVER = Color("cccccc")   # Light gray hover color
const COLOR_ACTIVE = Color("666666")  # Dark gray when fast forward is active

# Animation constants
const HOVER_SCALE = Vector2(1.1, 1.1)
const NORMAL_SCALE = Vector2(1.0, 1.0)
const CLICK_SCALE = Vector2(0.9, 0.9)

# Fast forward variables
var is_fast_forward = false
var previous_timescale = 1.0
const FAST_FORWARD_MULTIPLIER = 1.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Set this node to process even when the game is paused
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    # Store initial timescale
    previous_timescale = Engine.time_scale

    # Connect hover signals for fast forward button
    var button = $CanvasLayer2/SettingsButton  # This is now our fast forward button
    
    if button:
        # Connect hover signals
        button.mouse_entered.connect(func(): _on_button_mouse_entered(button))
        button.mouse_exited.connect(func(): _on_button_mouse_exited(button))
        button.button_down.connect(func(): _on_button_down(button))
        button.button_up.connect(func(): _on_button_up(button))
        
        # Set initial color
        button.modulate = COLOR_NORMAL

# Handle button hover effect
func _on_button_mouse_entered(button):
    # Don't change color on hover if fast forward is active
    if not is_fast_forward:
        button.modulate = COLOR_HOVER
    
    # Add a subtle scale effect
    var tween = create_tween()
    tween.tween_property(button, "scale", HOVER_SCALE, 0.1)

# Handle button hover exit effect
func _on_button_mouse_exited(button):
    # Restore appropriate color based on fast forward state
    button.modulate = COLOR_ACTIVE if is_fast_forward else COLOR_NORMAL
    
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

# Toggle fast forward functionality
func _on_settings_button_pressed() -> void:
    var button = $CanvasLayer2/SettingsButton
    
    if is_fast_forward:
        # Turn off fast forward - restore previous timescale
        Engine.time_scale = previous_timescale
        is_fast_forward = false
        
        # Change color back to normal (or hover if still hovered)
        button.modulate = COLOR_HOVER if button.is_hovered() else COLOR_NORMAL
    else:
        # Turn on fast forward - save current timescale and apply multiplier
        previous_timescale = Engine.time_scale
        Engine.time_scale *= FAST_FORWARD_MULTIPLIER
        is_fast_forward = true
        
        # Change color to active (darker)
        button.modulate = COLOR_ACTIVE
