extends Node2D

var current_level = ""  # Stores the path to the current level for restarting
var tween = null

# Get direct references to the nodes in our scene
@onready var dark_overlay = $CanvasLayer2/DarkOverlay
@onready var game_over_panel = $CanvasLayer2/GameOverPanel
@onready var restart_button = $CanvasLayer2/GameOverPanel/RestartButton
@onready var back_button = $CanvasLayer2/GameOverPanel/BackButton

func _ready():
    # Make this node process while paused
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    # Pause the game immediately
    get_tree().paused = true
    if Config.user_data:
        # Force save cached data to make sure it's persistent
        Config.save_cached_user_data()
        print("Progress saved on win screen")
    # Setup initial appearance
    if dark_overlay:
        dark_overlay.modulate = Color(1, 1, 1, 0)
    
    if game_over_panel:
        # Store original position and move down for animation
        var original_pos = game_over_panel.position
        game_over_panel.position.y += 100
        game_over_panel.modulate = Color(1, 1, 1, 0)
        
        # Set up button pivot points for scaling animation
        if restart_button:
            restart_button.pivot_offset = Vector2(restart_button.size.x/2, restart_button.size.y/2)
            restart_button.scale = Vector2(0.8, 0.8)
            restart_button.modulate = Color(1, 1, 1, 0)
            restart_button.mouse_entered.connect(func(): _on_button_hover(restart_button))
            restart_button.mouse_exited.connect(func(): _on_button_unhover(restart_button))
        
        if back_button:
            back_button.pivot_offset = Vector2(back_button.size.x/2, back_button.size.y/2)
            back_button.scale = Vector2(0.8, 0.8)
            back_button.modulate = Color(1, 1, 1, 0)
            back_button.mouse_entered.connect(func(): _on_button_hover(back_button))
            back_button.mouse_exited.connect(func(): _on_button_unhover(back_button))
        
        # Create animation sequence
        tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_CUBIC)
        
        # Animate overlay fade in
        if dark_overlay:
            tween.tween_property(dark_overlay, "modulate", Color(1, 1, 1, 1), 0.5)
        
        # Animate panel slide in
        tween.tween_property(game_over_panel, "position", original_pos, 0.6)
        tween.parallel().tween_property(game_over_panel, "modulate", Color(1, 1, 1, 1), 0.5)
        
        # Animate buttons fade and scale in
        if restart_button:
            tween.tween_property(restart_button, "modulate", Color(1, 1, 1, 1), 0.3)
            tween.parallel().tween_property(restart_button, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_ELASTIC)
        
        if back_button:
            tween.tween_property(back_button, "modulate", Color(1, 1, 1, 1), 0.3)
            tween.parallel().tween_property(back_button, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_ELASTIC)
    
    # Connect button signals
    if restart_button and not restart_button.is_connected("pressed", _on_restart_button_pressed):
        restart_button.pressed.connect(_on_restart_button_pressed)
    
    if back_button and not back_button.is_connected("pressed", _on_back_button_pressed):
        back_button.pressed.connect(_on_back_button_pressed)
    
# Button hover animation
func _on_button_hover(button):
    var hover_tween = create_tween()
    hover_tween.set_ease(Tween.EASE_OUT)
    hover_tween.set_trans(Tween.TRANS_ELASTIC)
    hover_tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.3)
    hover_tween.parallel().tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1), 0.2)

# Button unhover animation
func _on_button_unhover(button):
    var unhover_tween = create_tween()
    unhover_tween.set_ease(Tween.EASE_OUT)
    unhover_tween.set_trans(Tween.TRANS_ELASTIC)
    unhover_tween.tween_property(button, "scale", Vector2(1, 1), 0.3)
    unhover_tween.parallel().tween_property(button, "modulate", Color(1, 1, 1, 1), 0.2)

# Back button pressed
func _on_back_button_pressed():
    transition_to("res://Scene/Menu/LevelSelect.tscn")

# Restart button pressed
func _on_restart_button_pressed():
    if current_level.is_empty():
        transition_to("res://Scene/Level/Level1.tscn")
    else:
        transition_to(current_level)

# Scene transition
func transition_to(target_scene):
    if tween:
        tween.kill()
    
    tween = create_tween()
    tween.set_ease(Tween.EASE_IN)
    tween.set_trans(Tween.TRANS_CUBIC)
    
    # Fade out buttons first
    if restart_button:
        tween.tween_property(restart_button, "scale", Vector2(0.8, 0.8), 0.2)
        tween.parallel().tween_property(restart_button, "modulate", Color(1, 1, 1, 0), 0.2)
    
    if back_button:
        tween.tween_property(back_button, "scale", Vector2(0.8, 0.8), 0.2)
        tween.parallel().tween_property(back_button, "modulate", Color(1, 1, 1, 0), 0.2)
    
    # Then slide out panel
    if game_over_panel:
        tween.tween_property(game_over_panel, "position:y", game_over_panel.position.y + 100, 0.3)
        tween.parallel().tween_property(game_over_panel, "modulate", Color(1, 1, 1, 0), 0.3)
    
    # Fade out overlay last
    if dark_overlay:
        tween.tween_property(dark_overlay, "modulate", Color(1, 1, 1, 0), 0.3)
    
    # Change scene after animations complete
    tween.tween_callback(func(): 
        var tree = get_tree()
        if tree:
            tree.change_scene_to_file(target_scene)
            tree.paused = false
    )
