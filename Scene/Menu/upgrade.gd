extends Node2D

# Color constants for button states
const COLOR_NORMAL = Color("d1851e")  # Normal button color
const COLOR_HOVER = Color("ffd569")   # Hovered button color

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
    
    # Transition to the LevelSelect scene with a simple fade transition
    SceneTransition.change_scene("res://Scene/Menu/LevelSelect.tscn", 
                                SceneTransition.TransitionType.FADE, 
                                0.7)

func _on_upgrade_button_pressed() -> void:
    if selected_upgrade.is_empty():
        # Nothing selected, show a message
        return
        
    # Get the current level of the selected upgrade
    var current_level = 1
    var max_level = Config.MAX_RESOURCE_LEVEL  # Default for resources
    
    match selected_upgrade:
        "money":
            current_level = Config.start_money_level
        "hp":
            current_level = Config.start_hp_level
        "archer":
            current_level = Config.archer_start_level
            max_level = Config.MAX_TOWER_LEVEL
        "catapult":
            current_level = Config.catapult_start_level
            max_level = Config.MAX_TOWER_LEVEL
    
    # Check if already at max level
    if current_level >= max_level:
        # Show "max level reached" message
        if $CanvasLayer/UpgradePanel.has_node("MessageLabel"):
            $CanvasLayer/UpgradePanel/MessageLabel.text = "Maximum level reached!"
        return
        
    # Get upgrade cost
    var upgrade_cost = 0
    if selected_upgrade == "archer":
        upgrade_cost = Config.ARCHER_UPGRADE_COSTS.get(current_level + 1, 0)
    elif selected_upgrade == "catapult":
        upgrade_cost = Config.CATAPULT_UPGRADE_COSTS.get(current_level + 1, 0)
    else:
        upgrade_cost = Config.RESOURCE_UPGRADE_COSTS.get(current_level + 1, 0)
    
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
    if selected_upgrade.is_empty():
        # Nothing selected, just close the panel
        hide_upgrade_info_panel()
        return
        
    # Get the current level of the selected upgrade
    var current_level = 1
    var max_level = Config.MAX_RESOURCE_LEVEL  # Default for resources
    print("selected", selected_upgrade)
    match selected_upgrade:
        "money":
            current_level = Config.start_money_level
        "hp":
            current_level = Config.start_hp_level
        "archer":
            current_level = Config.archer_start_level
            max_level = Config.MAX_TOWER_LEVEL
        "catapult":
            current_level = Config.catapult_start_level
            max_level = Config.MAX_TOWER_LEVEL
    
    # Check if already at max level
    if current_level >= max_level:
        # Hide the panel - max level already reached
        hide_upgrade_info_panel()
        return
    print(current_level)
    # Get upgrade cost
    var upgrade_cost = 0
    if selected_upgrade == "archer":
        # Ensure current_level is an integer before adding 1
        var next_level_key = int(current_level) + 1
        upgrade_cost = Config.ARCHER_UPGRADE_COSTS.get(next_level_key, 0)
    elif selected_upgrade == "catapult":
        # Ensure current_level is an integer before adding 1
        var next_level_key = int(current_level) + 1
        upgrade_cost = Config.CATAPULT_UPGRADE_COSTS.get(next_level_key, 0)
    else:
        upgrade_cost = Config.RESOURCE_UPGRADE_COSTS.get(current_level + 1, 0)
    
    # Check if player has enough resources
    if Config.user_data.get("money", 0) < upgrade_cost:
        # Show "not enough money" message with better styling
        show_message("Not enough money!", false)
        return
    
    # Player has enough money, proceed with upgrade
    match selected_upgrade:
        "money":
            Config.update_user_data({
                "money": Config.user_data.get("money", 0) - upgrade_cost,
                "start_money": current_level + 1
            })
        "hp":
            Config.update_user_data({
                "money": Config.user_data.get("money", 0) - upgrade_cost,
                "start_hp": current_level + 1
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
    
    # Show success message
    show_message("Upgrade successful!", true)
    
    # Hide the panel after a short delay
    await get_tree().create_timer(1.0).timeout
    hide_upgrade_info_panel()

# Function to show attractive styled messages
func show_message(text, is_success):
    # Remove any existing message
    if $CanvasLayer.has_node("MessagePanel"):
        $CanvasLayer/MessagePanel.queue_free()
    
    # Create panel background
    var panel = Panel.new()
    panel.name = "MessagePanel"
    $CanvasLayer.add_child(panel)
    
    # Style panel based on message type
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0, 0, 0, 0.7)  # Dark background
    style.border_width_left = 4
    style.border_width_top = 4
    style.border_width_right = 4
    style.border_width_bottom = 4
    style.corner_radius_top_left = 8
    style.corner_radius_top_right = 8
    style.corner_radius_bottom_right = 8
    style.corner_radius_bottom_left = 8
    
    # Set border color based on message type
    if is_success:
        style.border_color = Color(0.2, 0.8, 0.2)  # Success green
    else:
        style.border_color = Color(0.9, 0.3, 0.2)  # Error red
    
    panel.add_theme_stylebox_override("panel", style)
    
    # Create message label
    var label = Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    
    # Style label
    var font_size = 20
    label.add_theme_font_size_override("font_size", font_size)
    if is_success:
        label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))  # Bright green
    else:
        label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))  # Light orange-red
    
    # Size the panel before adding the label
    panel.size = Vector2(320, 70)
    
    # Add label to panel
    panel.add_child(label)
    
    # Position the panel in the center of the viewport
    var viewport_size = get_viewport_rect().size
    var target_position = Vector2(viewport_size.x / 2, viewport_size.y / 2)
    
    # Set starting position (above the screen)
    panel.position = Vector2(target_position.x - panel.size.x/2, -100)
    
    # Position the label within the panel (centered)
    label.size = Vector2(panel.size.x - 20, panel.size.y - 20)  # Leave some padding
    label.position = Vector2(10, 10)  # 10px padding from panel edges
    
    # Create show animation from top to center
    panel.modulate = Color(1, 1, 1, 0)
    var tween = create_tween()
    tween.set_trans(Tween.TRANS_BACK)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(panel, "position:y", target_position.y - panel.size.y/2, 0.5)
    tween.parallel().tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3)
    
    # Auto-hide message after a delay
    await get_tree().create_timer(2.0).timeout
    
    if is_instance_valid(panel):
        var hide_tween = create_tween()
        hide_tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.5)
        await hide_tween.finished
        if is_instance_valid(panel):
            panel.queue_free()

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
    
    # Update the money display in the upgrade info panel
    if $CanvasLayer.has_node("UpgradeInfo/DarkOverlay3/HBoxContainer/MoneyLabel"):
        var money_label = $CanvasLayer/UpgradeInfo/DarkOverlay3/HBoxContainer/MoneyLabel
        print(Config.user_data)
        money_label.text = str(Config.user_data.get("money", 0))
        
    # Update the upgrade info panel with correct data for this upgrade type
    update_upgrade_info(type, level)
    
func update_upgrade_info(type, level):
    # Convert level to integer to ensure proper dictionary lookup
    level = int(level)
    
    # Get the appropriate button scene based on type
    var button_scene = null
    match type:
        "archer":
            button_scene = archer_button_scene
        "catapult":
            button_scene = catapult_button_scene
        "hp":
            button_scene = hp_button_scene
        "money":
            button_scene = money_button_scene
    
    if button_scene == null:
        print("Error: No button scene found for type: ", type)
        return
    
    # Get next level (respecting max levels for different types)
    var max_level = Config.MAX_TOWER_LEVEL if (type == "archer" or type == "catapult") else Config.MAX_RESOURCE_LEVEL
    var next_level = min(level + 1, max_level)
    var is_max_level = level >= max_level
    
    # Get the current and next level values based on type (only for resources)
    var current_value = 0
    var next_value = 0
    
    match type:
        "money":
            current_value = Config.MONEY_LEVEL_VALUES.get(level, 0)
            next_value = Config.MONEY_LEVEL_VALUES.get(next_level, current_value)
        "hp":
            current_value = Config.HP_LEVEL_VALUES.get(level, 0)
            next_value = Config.HP_LEVEL_VALUES.get(next_level, current_value)
    
    # Update value displays only for resources (money/hp)
    if type == "money" or type == "hp":
        if $CanvasLayer.has_node("UpgradeInfo/CurrentValue"):
            $CanvasLayer/UpgradeInfo/CurrentValue.text = str(current_value)
        
        if $CanvasLayer.has_node("UpgradeInfo/NextValue"):
            if is_max_level:
                $CanvasLayer/UpgradeInfo/NextValue.text = "MAX"
            else:
                $CanvasLayer/UpgradeInfo/NextValue.text = str(next_value)
    else:
        # Clear or hide value displays for towers
        if $CanvasLayer.has_node("UpgradeInfo/CurrentValue"):
            $CanvasLayer/UpgradeInfo/CurrentValue.text = ""
        
        if $CanvasLayer.has_node("UpgradeInfo/NextValue"):
            $CanvasLayer/UpgradeInfo/NextValue.text = ""
    
    # Get the upgrade cost (this is kept for all types)
    var upgrade_cost = 0
    if not is_max_level:
        if type == "archer":
            # Ensure current_level is an integer before adding 1
            var next_level_key = int(level) + 1
            upgrade_cost = Config.ARCHER_UPGRADE_COSTS.get(next_level_key, 0)
        elif type == "catapult":
            # Ensure current_level is an integer before adding 1
            var next_level_key = int(level) + 1
            upgrade_cost = Config.CATAPULT_UPGRADE_COSTS.get(next_level_key, 0)
        else:
            upgrade_cost = Config.RESOURCE_UPGRADE_COSTS.get(next_level, 0)
    
    # Update the price label in the upgrade info panel
    if $CanvasLayer.has_node("UpgradeInfo/HBoxContainer/PriceLabel"):
        var price_label = $CanvasLayer/UpgradeInfo/HBoxContainer/PriceLabel
        if is_max_level:
            price_label.text = "0"
        else:
            price_label.text = str(upgrade_cost)
    else:
        print("ERROR: PriceLabel node not found!")
    
    # Update the description text based on upgrade type
    if $CanvasLayer.has_node("UpgradeInfo/TextureRect/BeforeInfo") and $CanvasLayer.has_node("UpgradeInfo/TextureRect/AfterInfo"):
        var before_info = $CanvasLayer/UpgradeInfo/TextureRect/BeforeInfo
        var after_info = $CanvasLayer/UpgradeInfo/TextureRect/AfterInfo
        
        match type:
            "archer":
                if level == 1:
                    before_info.text = "Start with Level 1 Archer Tower"
                else:
                    before_info.text = "Start with Level " + str(level) + " Archer Tower"
                if is_max_level:
                    after_info.text = "Maximum Level Reached"
                else:
                    after_info.text = "Start with Level " + str(next_level) + " Archer Tower"
            
            "catapult":
                if level == 1:
                    before_info.text = "Start with Level 1 Catapult Tower"
                else:
                    before_info.text = "Start with Level " + str(level) + " Catapult Tower"
                if is_max_level:
                    after_info.text = "Maximum Level Reached"
                else:
                    after_info.text = "Start with Level " + str(next_level) + " Catapult Tower"
            
            "money":
                before_info.text = "Start with " + str(Config.MONEY_LEVEL_VALUES[level]) + " money"
                if is_max_level:
                    after_info.text = "Maximum Level Reached"
                else:
                    after_info.text = "Start with " + str(Config.MONEY_LEVEL_VALUES[next_level]) + " money"
            
            "hp":
                before_info.text = "Start with " + str(Config.HP_LEVEL_VALUES[level]) + " HP"
                if is_max_level:
                    after_info.text = "Maximum Level Reached"
                else:
                    after_info.text = "Start with " + str(Config.HP_LEVEL_VALUES[next_level]) + " HP"
    
    # Clear existing children from Before and After containers
    for child in $CanvasLayer/UpgradeInfo/Before.get_children():
        child.queue_free()
    
    for child in $CanvasLayer/UpgradeInfo/After.get_children():
        child.queue_free()
    
    # Instantiate button for current level (Before)
    var before_button = button_scene.instantiate()
    $CanvasLayer/UpgradeInfo/Before.add_child(before_button)
    before_button.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Make non-interactable
    
    # Update level display for Before button
    if type == "archer" or type == "catapult":
        if before_button.has_node("Level") and level_textures.size() >= level:
            before_button.get_node("Level").texture = level_textures[level - 1]
    else:  # money or hp
        if before_button.has_node("Level/Label"):
            before_button.get_node("Level/Label").text = str(level-1)
    
    # Instantiate button for next level (After)
    var after_button = button_scene.instantiate()
    $CanvasLayer/UpgradeInfo/After.add_child(after_button)
    after_button.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Make non-interactable
    
    # Update level display for After button
    if type == "archer" or type == "catapult":
        if after_button.has_node("Level") and level_textures.size() >= next_level:
            after_button.get_node("Level").texture = level_textures[next_level - 1]
    else:  # money or hp
        if after_button.has_node("Level/Label"):
            after_button.get_node("Level/Label").text = str(next_level-1)
    
    # Add any additional information display as needed
    # For example, update stats, descriptions, etc.

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
