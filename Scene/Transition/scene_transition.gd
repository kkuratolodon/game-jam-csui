extends CanvasLayer

signal transition_completed
signal panel_transition_completed

# Transition types
enum TransitionType {
    FADE_BLACK,
    FADE_WHITE
}

var current_type = TransitionType.FADE_BLACK
var current_panel: Control = null

@onready var animation_player = $AnimationPlayer
@onready var color_rect = $ColorRect
@onready var panel_container = $Panel

func _ready():
    # Make sure we start with the transition invisible
    animation_player.play("RESET")
    color_rect.visible = true

# Transition to a new scene
func change_scene(target_scene: String, type: int = TransitionType.FADE_BLACK, duration: float = 0.5):
    # Set the transition type
    current_type = type
    
    # Set the color based on transition type
    if type == TransitionType.FADE_WHITE:
        color_rect.color = Color.WHITE
    else:
        color_rect.color = Color.BLACK
    
    # Setup animation speed
    animation_player.speed_scale = 1.0 / duration
    
    # Play the transition animation
    animation_player.play("dissolve")
    await animation_player.animation_finished
    
    # Change to the new scene
    get_tree().change_scene_to_file(target_scene)
    
    # Play the animation backwards to reveal the new scene
    animation_player.play_backwards("dissolve")
    await animation_player.animation_finished
    
    # Signal that the transition is completed
    transition_completed.emit()

# Display a panel with animation
func show_panel(panel_scene: PackedScene, fade_background: bool = true):
    # Clear any existing panel
    if current_panel:
        current_panel.queue_free()
    
    # Add background fade if requested
    if fade_background:
        color_rect.color = Color(0, 0, 0, 0.75)
        color_rect.modulate = Color(1, 1, 1, 0)
        var tween = create_tween()
        tween.tween_property(color_rect, "modulate", Color(1, 1, 1, 1), 0.3)
    
    # Instantiate new panel
    current_panel = panel_scene.instantiate()
    
    # If the panel is a Control node, we'll animate it
    if current_panel is Control:
        # Remove its own CanvasLayer if it has one
        var canvas_layers = []
        for child in current_panel.get_children():
            if child is CanvasLayer:
                canvas_layers.append(child)
        
        for canvas_layer in canvas_layers:
            var parent = canvas_layer.get_parent()
            for child in canvas_layer.get_children():
                canvas_layer.remove_child(child)
                parent.add_child(child)
            canvas_layer.queue_free()
            
        # Add the panel to our container
        panel_container.add_child(current_panel)
        
        # Setup for slide-in animation
        current_panel.modulate = Color(1, 1, 1, 0)
        current_panel.position.y = -current_panel.size.y
        
        # Create tween for panel animation
        var tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_BACK)
        tween.tween_property(current_panel, "position:y", 0, 0.5)
        tween.parallel().tween_property(current_panel, "modulate", Color(1, 1, 1, 1), 0.3)
        await tween.finished
    else:
        # For non-Control nodes, just add them
        panel_container.add_child(current_panel)
    
    # Signal completion
    panel_transition_completed.emit()

# Remove the current panel with animation
func hide_panel(fade_background: bool = true):
    if !current_panel:
        return
    
    if current_panel is Control:
        # Animate the panel sliding out
        var tween = create_tween()
        tween.set_ease(Tween.EASE_IN)
        tween.set_trans(Tween.TRANS_BACK)
        tween.tween_property(current_panel, "position:y", -current_panel.size.y, 0.5)
        tween.parallel().tween_property(current_panel, "modulate", Color(1, 1, 1, 0), 0.3)
        
        if fade_background:
            tween.parallel().tween_property(color_rect, "modulate", Color(1, 1, 1, 0), 0.3)
        
        await tween.finished
    
    # Clean up the panel
    current_panel.queue_free()
    current_panel = null
    
    panel_transition_completed.emit()

# Switch between panels with animation
func switch_panel(new_panel_scene: PackedScene):
    if current_panel:
        # Animate current panel out to the left
        var tween = create_tween()
        tween.set_ease(Tween.EASE_IN)
        tween.set_trans(Tween.TRANS_BACK)
        tween.tween_property(current_panel, "position:x", -1200, 0.4)
        tween.parallel().tween_property(current_panel, "modulate", Color(1, 1, 1, 0), 0.3)
        await tween.finished
        
        current_panel.queue_free()
        current_panel = null
    
    # Instantiate new panel
    current_panel = new_panel_scene.instantiate()
    
    # Handle CanvasLayer issue
    var canvas_layers = []
    for child in current_panel.get_children():
        if child is CanvasLayer:
            canvas_layers.append(child)
    
    for canvas_layer in canvas_layers:
        var parent = canvas_layer.get_parent()
        for child in canvas_layer.get_children():
            canvas_layer.remove_child(child)
            parent.add_child(child)
        canvas_layer.queue_free()
    
    # Add to container
    panel_container.add_child(current_panel)
    
    # Setup for slide-in animation from right
    current_panel.modulate = Color(1, 1, 1, 0)
    current_panel.position.x = 1200
    
    # Animate in from right
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_BACK)
    tween.tween_property(current_panel, "position:x", 0, 0.4)
    tween.parallel().tween_property(current_panel, "modulate", Color(1, 1, 1, 1), 0.3)
    await tween.finished
    
    panel_transition_completed.emit()
