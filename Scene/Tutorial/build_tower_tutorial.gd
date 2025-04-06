extends TutorialState
class_name BuildTowerTutorial

var base_tower_hovered := false
var tower_built := false
var money_checked := false

var highlight_rect: ColorRect
var highlight_timer: Timer
var towers_group: Array = []
var check_hover_timer: Timer

func _init(tutorial_manager):
    super._init(tutorial_manager)
    tutorial_name = "build_tower"
    total_steps = 3

func enter():
    # Setup highlight rect for UI elements
    highlight_rect = ColorRect.new()
    highlight_rect.color = Color(0.2, 1.0, 0.4, 0.3) # Green semi-transparent
    highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    highlight_rect.visible = false
    highlight_rect.add_to_group("TutorialHighlight") # Add to group for easy management
    manager.add_child(highlight_rect)
    
    # Timer for pulsing highlight effect
    highlight_timer = Timer.new()
    highlight_timer.wait_time = 0.6
    highlight_timer.one_shot = false
    manager.add_child(highlight_timer)
    highlight_timer.timeout.connect(_on_highlight_timer)
    highlight_timer.start()
    
    # Connect to base tower signals
    # Use manager to access tree since RefCounted doesn't have get_tree()
    var base_towers = manager.get_tree().get_nodes_in_group("BaseTower")
    towers_group = base_towers
    for tower in base_towers:
        if tower.has_signal("tower_options_shown"):
            if not tower.is_connected("tower_options_shown", _on_tower_options_shown):
                tower.connect("tower_options_shown", _on_tower_options_shown)
        
        if tower.has_signal("mouse_entered"):
            if not tower.is_connected("mouse_entered", _on_tower_mouse_entered):
                tower.connect("mouse_entered", _on_tower_mouse_entered)
        
        if tower.has_signal("tower_built"):
            if not tower.is_connected("tower_built", _on_tower_built):
                tower.connect("tower_built", _on_tower_built)
    
    # Add a timer to periodically check for hovering
    check_hover_timer = Timer.new()
    check_hover_timer.wait_time = 0.2
    check_hover_timer.one_shot = false
    manager.add_child(check_hover_timer)
    check_hover_timer.timeout.connect(_on_check_hover_timer)
    check_hover_timer.start()
    
    # Start with first step
    super.enter()
    
    print("Build Tower Tutorial started")

func exit():
    # Disconnect signals and clean up
    for i in range(towers_group.size() - 1, -1, -1):
        var tower = towers_group[i]
        
        # Skip invalid tower instances
        if not is_instance_valid(tower):
            continue
            
        # Now it's safe to check signals and disconnect them
        if tower.has_signal("tower_options_shown") and tower.is_connected("tower_options_shown", _on_tower_options_shown):
            tower.disconnect("tower_options_shown", _on_tower_options_shown)
            
        if tower.has_signal("mouse_entered") and tower.is_connected("mouse_entered", _on_tower_mouse_entered):
            tower.disconnect("mouse_entered", _on_tower_mouse_entered)
            
        if tower.has_signal("tower_built") and tower.is_connected("tower_built", _on_tower_built):
            tower.disconnect("tower_built", _on_tower_built)
    
    if highlight_timer:
        highlight_timer.stop()
        highlight_timer.queue_free()
    
    if highlight_rect:
        highlight_rect.queue_free()
    
    if check_hover_timer:
        check_hover_timer.stop()
        check_hover_timer.queue_free()
    
    super.exit()

func show_current_step():
    match current_step:
        0: # Introduction
            manager.tutorial_ui.set_title("Building Towers")
            manager.tutorial_ui.set_content("Now let's learn how to build towers to defend your base! Towers can be built on tower bases you've placed.")
            manager.tutorial_ui.show_next_button(true)
            manager.tutorial_ui.show_panel()
            
        1: # Hover over base tower
            manager.tutorial_ui.set_title("Tower Options")
            manager.tutorial_ui.set_content("Move your mouse over a tower base to see available tower options. Check your money in the top left corner.")
            manager.tutorial_ui.show_next_button(false)
            manager.tutorial_ui.show_panel()
            
            # Highlight money display
            highlight_money_display()
            
        2: # Select a tower to build
            manager.tutorial_ui.set_title("Build a Tower")
            manager.tutorial_ui.set_content("Click on one of the tower options to build it. Each tower has different costs and abilities. Choose one that fits your budget.")
            manager.tutorial_ui.show_next_button(false)
            manager.tutorial_ui.show_panel()

func update(delta: float):
    # Check for step completion
    match current_step:
        1: # Waiting for hover
            check_if_tower_hovered()
            if base_tower_hovered:
                print("Base tower hovered detected!")
                next_step()
                
        2: # Waiting for tower build
            check_for_built_tower()
            if tower_built:
                print("Tower built detected!")
                next_step()
    
    # Update highlight effect if visible
    if highlight_rect and highlight_rect.visible:
        # Pulse the highlight alpha for better visibility
        var alpha = highlight_rect.color.a
        if highlight_timer.time_left < highlight_timer.wait_time / 2:
            alpha = lerp(0.2, 0.4, highlight_timer.time_left / (highlight_timer.wait_time / 2))
        else:
            alpha = lerp(0.4, 0.2, highlight_timer.time_left / (highlight_timer.wait_time / 2))
        highlight_rect.color.a = alpha
        
        # If in step 1, also try to highlight a base tower
        if current_step == 1 and not base_tower_hovered:
            highlight_base_tower()

func highlight_money_display():
    # Find the money display in the UI
    var ui_node = manager.get_tree().get_first_node_in_group("InGameUI")
    if ui_node and ui_node.has_node("ResourceDisplay"):
        var money_display = ui_node.get_node("ResourceDisplay")
        
        # Get the global position and size of the money display
        var global_rect = Rect2(money_display.global_position, money_display.size)
        
        # Add some padding
        global_rect = global_rect.grow(5)
        
        # Update highlight rect
        highlight_rect.visible = true
        highlight_rect.global_position = global_rect.position
        highlight_rect.size = global_rect.size
        
        # Set money checked flag
        money_checked = true

func highlight_base_tower():
    # Find the closest base tower to highlight
    var base_towers = manager.get_tree().get_nodes_in_group("BaseTower")
    var player = manager.get_tree().get_first_node_in_group("Player")
    
    if base_towers.size() > 0 and player:
        # Find closest tower to player
        var closest_tower = base_towers[0]
        var closest_dist = closest_tower.global_position.distance_to(player.global_position)
        
        for tower in base_towers:
            var dist = tower.global_position.distance_to(player.global_position)
            if dist < closest_dist:
                closest_tower = tower
                closest_dist = dist
        
        # Get the global rect of the tower
        var global_rect = Rect2(closest_tower.global_position - Vector2(30, 30), Vector2(60, 60))
        
        # Update highlight rect
        highlight_rect.visible = true
        highlight_rect.global_position = global_rect.position
        highlight_rect.size = global_rect.size

func check_if_tower_hovered():
    # Check if any tower has its options panel visible
    for tower in towers_group:
        if is_instance_valid(tower) and tower.has_node("TowerOptions"):
            var options = tower.get_node("TowerOptions")
            if options.visible:
                base_tower_hovered = true
                print("Tower options visible, marking as hovered")
                return
            
    # Check if the player's mouse is over a base tower
    var mouse_pos = manager.get_viewport().get_mouse_position()
    for tower in towers_group:
        if is_instance_valid(tower) and tower.has_method("get_global_rect"):
            var tower_rect = tower.get_global_rect()
            if tower_rect.has_point(mouse_pos):
                base_tower_hovered = true
                print("Mouse is over tower, marking as hovered")
                return

func check_for_built_tower():
    var towers = manager.get_tree().get_nodes_in_group("Towers")
    for tower in towers:
        # Skip preview towers
        if tower.name == "PreviewTower" or "preview" in tower.name.to_lower():
            continue
        
        # If we found a real tower, mark as built
        tower_built = true
        print("Found tower: ", tower.name)
        return

func _on_tower_options_shown():
    base_tower_hovered = true
    print("Tower options shown signal received")

func _on_tower_mouse_entered():
    base_tower_hovered = true
    print("Tower mouse entered signal received") 

func _on_check_hover_timer():
    if current_step == 1 and not base_tower_hovered:
        check_if_tower_hovered()

func _on_tower_built():
    tower_built = true

func _on_highlight_timer():
    # This just helps update the pulsing effect
    pass
