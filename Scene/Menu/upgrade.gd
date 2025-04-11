extends Node2D

# Color constants for button states
const COLOR_NORMAL = Color("d1851e")  # Normal button color
const COLOR_HOVER = Color("ffd569")   # Hovered button color

# Dictionaries mapping upgrade levels to actual values
const MONEY_LEVEL_VALUES = {
    1: 200,  # Level 1: 200 starting money
    2: 250,  # Level 2: 250 starting money
    3: 300,  # Level 3: 300 starting money
    4: 350,  # Level 4: 350 starting money
    5: 400   # Level 5: 400 starting money
}

const HP_LEVEL_VALUES = {
    1: 100,  # Level 1: 100 starting HP
    2: 120,  # Level 2: 120 starting HP
    3: 140,  # Level 3: 140 starting HP
    4: 160,  # Level 4: 160 starting HP
    5: 200   # Level 5: 200 starting HP
}

# Maximum levels for different upgrade types
const MAX_TOWER_LEVEL = 4  # Archer and Catapult max level is 4
const MAX_RESOURCE_LEVEL = 5  # Money and HP max level is 5

# Upgrade costs for each level
const UPGRADE_COSTS = {
    # Level to upgrade to: cost
    2: 500,
    3: 1000,
    4: 2000,
    5: 3500
}


# Currently selected upgrade type
var selected_upgrade = ""

@export var level_textures : Array[Texture2D]
@export var archer_button_scene: PackedScene
@export var catapult_button_scene: PackedScene
@export var hp_button_scene: PackedScene
@export var money_button_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Connect hover signals for all buttons
    var buttons = [
        $CanvasLayer/UpgradePanel/Buttons/Archer,
        $CanvasLayer/UpgradePanel/Buttons/Money,
        $CanvasLayer/UpgradePanel/Buttons/Heart, 
        $CanvasLayer/UpgradePanel/Buttons/Catapult,
        $CanvasLayer/UpgradePanel/BackButton,
        $CanvasLayer/UpgradePanel/UpgradeButton
    ]
    
    for button in buttons:
        if button:
            # Set initial color
            if button.has_node("Label"):
                button.get_node("Label").add_theme_color_override("font_color", COLOR_NORMAL)
            
            # Connect hover signals
            button.mouse_entered.connect(func(): _on_button_mouse_entered(button))
            button.mouse_exited.connect(func(): _on_button_mouse_exited(button))
    
    # Also connect hover signals for close/done buttons
    if $CanvasLayer.has_node("UpgradeInfo/CloseButton"):
        var close_button = $CanvasLayer/UpgradeInfo/CloseButton
        close_button.mouse_entered.connect(func(): _on_button_mouse_entered(close_button))
        close_button.mouse_exited.connect(func(): _on_button_mouse_exited(close_button))
    
    if $CanvasLayer.has_node("UpgradeInfo/DoneButton"):
        var done_button = $CanvasLayer/UpgradeInfo/DoneButton
        done_button.mouse_entered.connect(func(): _on_button_mouse_entered(done_button))
        done_button.mouse_exited.connect(func(): _on_button_mouse_exited(done_button))
    
    # Update the UI with current levels
    update_ui_display()

# Function to update all UI elements based on current player data
func update_ui_display():
    # Get current levels from the Config singleton
    var money_level = Config.start_money_level
    var hp_level = Config.start_hp_level
    var archer_level = Config.archer_start_level
    var catapult_level = Config.catapult_start_level
    
    # Update tower level indicators using level_textures
    if $CanvasLayer/UpgradePanel/Buttons/Archer.has_node("Level") and archer_level <= level_textures.size():
        $CanvasLayer/UpgradePanel/Buttons/Archer/Level.texture = level_textures[archer_level - 1]
    
    if $CanvasLayer/UpgradePanel/Buttons/Catapult.has_node("Level") and catapult_level <= level_textures.size():
        $CanvasLayer/UpgradePanel/Buttons/Catapult/Level.texture = level_textures[catapult_level - 1]
    
    # Update resource level labels
    if $CanvasLayer/UpgradePanel/Buttons/Money/Level.has_node("Label"):
        $CanvasLayer/UpgradePanel/Buttons/Money/Level/Label.text = str(money_level-1)
    
    if $CanvasLayer/UpgradePanel/Buttons/Heart/Level.has_node("Label"):
        $CanvasLayer/UpgradePanel/Buttons/Heart/Level/Label.text = str(hp_level-1)
    
    # Update money display if there is one
    if $CanvasLayer/UpgradePanel.has_node("MoneyDisplay"):
        $CanvasLayer/UpgradePanel/MoneyDisplay.text = str(Config.user_data.get("money", 0))

# Handle button hover effect
func _on_button_mouse_entered(button):
    # Change text color to hover color
    if button.has_node("Label"):
        button.get_node("Label").add_theme_color_override("font_color", COLOR_HOVER)
    
    # Optional: Add a subtle scale effect
    var tween = create_tween()
    tween.tween_property(button, "scale", button.scale * 1.05, 0.1)

# Handle button hover exit effect
func _on_button_mouse_exited(button):
    # Change text color back to normal
    if button.has_node("Label"):
        button.get_node("Label").add_theme_color_override("font_color", COLOR_NORMAL)
    
    # Restore original scale
    var tween = create_tween()
    tween.tween_property(button, "scale", button.scale / 1.05, 0.1)

func _on_back_button_pressed() -> void:
    # Create a fade out animation for just the upgrade panel (not the background)
    var tween = create_tween()
    tween.tween_property($CanvasLayer/UpgradePanel, "modulate", Color(1, 1, 1, 0), 0.3)
    await tween.finished
    
    # Transition to the LevelSelect scene with a fancy transition
    SceneTransition.change_scene("res://Scene/Menu/LevelSelect.tscn", 
                                SceneTransition.TransitionType.IRIS, 
                                0.7)

func _on_upgrade_button_pressed() -> void:
    if selected_upgrade.is_empty():
        # Nothing selected, show a message
        return
        
    # Get the current level of the selected upgrade
    var current_level = 1
    var max_level = MAX_RESOURCE_LEVEL  # Default for resources
    
    match selected_upgrade:
        "money":
            current_level = Config.start_money_level
        "hp":
            current_level = Config.start_hp_level
        "archer":
            current_level = Config.archer_start_level
            max_level = MAX_TOWER_LEVEL
        "catapult":
            current_level = Config.catapult_start_level
            max_level = MAX_TOWER_LEVEL
    
    # Check if already at max level
    if current_level >= max_level:
        # Show "max level reached" message
        if $CanvasLayer/UpgradePanel.has_node("MessageLabel"):
            $CanvasLayer/UpgradePanel/MessageLabel.text = "Maximum level reached!"
        return
        
    # Get upgrade cost
    var upgrade_cost = UPGRADE_COSTS[current_level + 1]
    
    # Check if player has enough resources
    if Config.user_data.get("money", 0) < upgrade_cost:
        # Show "not enough money" message
        if $CanvasLayer/UpgradePanel.has_node("MessageLabel"):
            $CanvasLayer/UpgradePanel/MessageLabel.text = "Not enough money!"
        return
        
    # Update the level
    match selected_upgrade:
        "money":
            Config.update_user_data({
                "money": Config.user_data.get("money", 0) - upgrade_cost,
                "money_level": current_level + 1
            })
        "hp":
            Config.update_user_data({
                "money": Config.user_data.get("money", 0) - upgrade_cost,
                "hp_level": current_level + 1
            })
        "archer":
            Config.update_user_data({
                "money": Config.user_data.get("money", 0) - upgrade_cost,
                "archer_level": current_level + 1
            })
        "catapult":
            Config.update_user_data({
                "money": Config.user_data.get("money", 0) - upgrade_cost,
                "catapult_level": current_level + 1
            })
    
    # Connect to the user_data_updated signal to refresh UI when the update completes
    Config.user_data_updated.connect(_on_upgrade_completed, CONNECT_ONE_SHOT)

func _on_upgrade_completed():
    # Refresh the UI with new values
    update_ui_display()
    
    # Clear selection
    selected_upgrade = ""

func _on_close_button_pressed() -> void:
    # Hide the upgrade info panel with animation
    hide_upgrade_info_panel()

func _on_done_button_pressed() -> void:
    # Same functionality as close button
    hide_upgrade_info_panel()

func _on_archer_pressed() -> void:
    selected_upgrade = "archer"
    show_upgrade_info_panel("archer", Config.archer_start_level)

func _on_money_pressed() -> void:
    selected_upgrade = "money"
    show_upgrade_info_panel("money", Config.start_money_level)

func _on_heart_pressed() -> void:
    selected_upgrade = "hp"
    show_upgrade_info_panel("hp", Config.start_hp_level)

func _on_catapult_pressed() -> void:
    selected_upgrade = "catapult"
    show_upgrade_info_panel("catapult", Config.catapult_start_level)

func show_upgrade_info_panel(type, level):
    # Make the overlay visible
    if $CanvasLayer.has_node("DarkOverlay2"):
        var overlay = $CanvasLayer/DarkOverlay2
        overlay.modulate = Color(1, 1, 1, 0)
        overlay.visible = true
    
    # Make the upgrade info panel visible with animation
    if $CanvasLayer.has_node("UpgradeInfo"):
        var panel = $CanvasLayer/UpgradeInfo
        
        # Set initial state
        panel.modulate = Color(1, 1, 1, 0)
        panel.scale = Vector2(0.8, 0.8)
        panel.visible = true
        
        # Create animation
        var tween = create_tween()
        tween.set_parallel(true)
        tween.tween_property($CanvasLayer/DarkOverlay2, "modulate", Color(1, 1, 1, 1), 0.3)
        tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3)
        tween.tween_property(panel, "scale", Vector2(1, 1), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
        
    # Update the upgrade info panel with correct data for this upgrade type
    update_upgrade_info(type, level)
    
func update_upgrade_info(type, level):
    # This function would update the content of the upgrade info panel
    # based on the upgrade type and current level
    # You can implement the specifics based on your requirements
    pass

# Also add a function to hide the panels
func hide_upgrade_info_panel():
    if $CanvasLayer.has_node("DarkOverlay2") and $CanvasLayer.has_node("UpgradeInfo"):
        var overlay = $CanvasLayer/DarkOverlay2
        var panel = $CanvasLayer/UpgradeInfo
        
        # Create fade-out animation
        var tween = create_tween()
        tween.set_parallel(true)
        tween.tween_property(overlay, "modulate", Color(1, 1, 1, 0), 0.3)
        tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.3)
        tween.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.2)
        
        # Hide after animation completes
        await tween.finished
        overlay.visible = false
        panel.visible = false
