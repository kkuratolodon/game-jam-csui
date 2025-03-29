extends Node2D

signal move_state_changed(is_active)

var is_move_mode: bool = false
var selected_tower: BaseTower = null
var preview_tower: Node2D = null
var valid_placement: bool = false
var original_position: Vector2 = Vector2.ZERO
var build_controller = null  # Reference to build controller

# Cooldown variables
var can_move: bool = true
var move_cooldown: float = 0.5
var current_move_cooldown: float = 0.0

# Toggle cooldown variables
var can_toggle: bool = true
var toggle_cooldown: float = 0.3
var current_toggle_cooldown: float = 0.0

# Click cooldown variables
var can_click: bool = true
var click_cooldown: float = 0.2
var current_click_cooldown: float = 0.0

# Tower state
var tower_being_moved: bool = false

# Visual indicator for move mode
var move_mode_indicator: ColorRect

# Track recently moved towers to prevent immediate reselection
var recently_moved_towers = []
var recent_move_timer = 0.0

func _ready() -> void:
    # Create a visual indicator for move mode
    move_mode_indicator = ColorRect.new()
    move_mode_indicator.color = Color(0.2, 0.4, 0.8, 0.1)  # Semi-transparent blue
    move_mode_indicator.size = Vector2(get_viewport_rect().size.x, get_viewport_rect().size.y)
    move_mode_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse events
    move_mode_indicator.visible = false
    
    # Add to UI layer
    var canvas_layer = CanvasLayer.new()
    canvas_layer.layer = 100
    add_child(canvas_layer)
    canvas_layer.add_child(move_mode_indicator)
    
    # Find build controller
    var parent = get_parent()
    build_controller = parent.find_child("BuildController", true, false)

func _process(delta: float) -> void:
    # Update recently moved towers timer
    if recently_moved_towers.size() > 0:
        recent_move_timer -= delta
        if recent_move_timer <= 0:
            recently_moved_towers.clear()
    
    # Update cooldown timers
    if !can_move:
        current_move_cooldown -= delta
        if current_move_cooldown <= 0:
            can_move = true
            if preview_tower:
                update_preview_color()
    
    # Update toggle cooldown timer
    if !can_toggle:
        current_toggle_cooldown -= delta
        if current_toggle_cooldown <= 0:
            can_toggle = true
    
    # Update click cooldown timer
    if !can_click:
        current_click_cooldown -= delta
        if current_click_cooldown <= 0:
            can_click = true
    
    # Toggle move mode with M key - IMPROVED HANDLING
    if Input.is_key_pressed(KEY_M) and can_toggle:
        # If we're not already in move mode, ensure we're entering it
        if !is_move_mode:
            # If build mode is active, exit it first
            if build_controller and build_controller.is_build_mode:
                build_controller.toggle_build_mode()
            
            # Then enter move mode
            toggle_move_mode()
        else:
            # If already in move mode, just exit
            if tower_being_moved:
                cancel_tower_move()
            toggle_move_mode()
        
        can_toggle = false
        current_toggle_cooldown = toggle_cooldown
    
    # Exit move mode if B is pressed (build mode toggle)
    if Input.is_key_pressed(KEY_B) and can_toggle and is_move_mode:
        # Exit move mode first
        if tower_being_moved:
            cancel_tower_move()
        toggle_move_mode()
        
        can_toggle = false
        current_toggle_cooldown = toggle_cooldown
    
    # Cancel with ESC key - now just exits move mode completely
    if Input.is_key_pressed(KEY_ESCAPE) and is_move_mode:
        toggle_move_mode()  # Exit move mode (this will also clean up any tower being moved)
    
    if is_move_mode:
        if tower_being_moved:
            update_preview_position()
            check_placement_validity()
            
            # Use LEFT CLICK to place tower - modified to use just_pressed
            if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
                if can_click and can_move and valid_placement:
                    confirm_tower_move()
                    can_click = false
                    current_click_cooldown = click_cooldown
        else:
            # Check for tower selection - only on click down
            if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
                if can_click:
                    try_select_tower()
                    can_click = false
                    current_click_cooldown = click_cooldown

func toggle_move_mode() -> void:
    # When exiting move mode, reset the selected tower visibility if needed
    if is_move_mode and tower_being_moved and selected_tower:
        selected_tower.modulate = Color(1.0, 1.0, 1.0, 1.0)
    
    is_move_mode = !is_move_mode
    
    # Show/hide the visual indicator
    move_mode_indicator.visible = is_move_mode
    
    # Print debug info
    print("Move mode toggled: ", is_move_mode)
    
    # Reset state when toggling
    if preview_tower:
        if preview_tower.get_parent() == self:
            preview_tower.queue_free()
        preview_tower = null
    
    tower_being_moved = false
    selected_tower = null
    
    # Notify all towers of the move mode change
    emit_signal("move_state_changed", is_move_mode)
    
func try_select_tower() -> void:
    var mouse_position = get_global_mouse_position()
    print("Trying to select tower at position: ", mouse_position)
    
    # Directly search for base towers instead of using raycasts
    var base_towers = get_tree().get_nodes_in_group("BaseTower")  # Use BaseTower group instead
    print("Found base towers: ", base_towers.size())
    
    var closest_tower = null
    var closest_distance = 100.0  # Maximum selection distance in pixels
    
    for tower in base_towers:
        # Skip recently moved towers
        if recently_moved_towers.has(tower):
            print("Skipping recently moved tower: ", tower)
            continue
            
        # Skip preview towers
        if tower.name == "PreviewTower" or "preview" in tower.name.to_lower():
            continue
            
        var distance = tower.global_position.distance_to(mouse_position)
        print("Tower at ", tower.global_position, " distance: ", distance)
        if distance < closest_distance:
            closest_tower = tower
            closest_distance = distance
    
    if closest_tower:
        print("Selected tower: ", closest_tower)
        selected_tower = closest_tower
        original_position = selected_tower.global_position
        
        # Create preview for movement
        create_preview_tower()
        tower_being_moved = true

func create_preview_tower() -> void:
    # Clone the selected tower as preview
    preview_tower = selected_tower.duplicate()
    preview_tower.name = "MovementPreview"  # Give it a clear name
    preview_tower.modulate = Color(0.5, 0.5, 1.0, 0.5)  # Blue tint, semi-transparent
    preview_tower.z_index = 100  # Ensure it's on top
    
    # Make it non-interactive
    if preview_tower.has_node("CollisionShape2D"):
        preview_tower.get_node("CollisionShape2D").disabled = true
    
    # Hide any UI options
    if preview_tower.has_node("TowerOptions"):
        preview_tower.get_node("TowerOptions").visible = false
    
    # IMPORTANT: Remove preview from groups to avoid self-collision
    preview_tower.remove_from_group("Towers")
    preview_tower.remove_from_group("BaseTower")
    
    # Hide the actual tower temporarily
    selected_tower.modulate.a = 0.3
    
    add_child(preview_tower)
    update_preview_position()

func update_preview_position() -> void:
    if preview_tower:
        preview_tower.global_position = get_global_mouse_position()

func check_placement_validity() -> void:
    if !preview_tower:
        valid_placement = false
        return
        
    # Start with valid placement
    valid_placement = true
    
    # Get all towers in the scene - ALWAYS GET FRESH DATA
    var towers_in_scene = get_tree().get_nodes_in_group("Towers")
    var base_towers = get_tree().get_nodes_in_group("BaseTower")
    
    # Combine both lists for complete checking
    for base_tower in base_towers:
        if !towers_in_scene.has(base_tower):
            towers_in_scene.append(base_tower)
    
    # Set minimum allowed distance between towers
    var tower_radius = 45.0
    var min_distance = tower_radius * 2
    
    # Check towers for distance
    for tower in towers_in_scene:
        # Skip the tower we're moving AND the preview
        if tower == selected_tower or tower == preview_tower:
            continue
            
        # Skip if it's another preview tower or has "preview" in name
        if tower.name == "MovementPreview" or tower.name == "PreviewTower" or "preview" in tower.name.to_lower():
            continue
            
        # Check if close to existing tower
        var distance = tower.global_position.distance_to(preview_tower.global_position)
        if distance < min_distance:
            print("Too close to tower at: ", tower.global_position, " distance: ", distance)
            valid_placement = false
            break
    
    # Skip collision check with self and do proper obstacle detection
    if valid_placement:
        # Force world update to get latest collision info
        get_tree().call_deferred("process_frame")
        
        var space_state = get_world_2d().direct_space_state
        var shape_query = PhysicsShapeQueryParameters2D.new()
        
        # Safety check for CollisionShape2D
        if !preview_tower.has_node("CollisionShape2D"):
            print("Preview tower missing CollisionShape2D")
            valid_placement = false
            return
            
        # Use collision shape from preview tower
        var collision_shape = preview_tower.get_node("CollisionShape2D").shape
        shape_query.set_shape(collision_shape)
        shape_query.transform = Transform2D(0, preview_tower.global_position)
        
        # Exclude player (layer 2) and build areas (layer 1) - match build controller
        shape_query.collision_mask = ~(1 << 0 | 1 << 1)
        
        var result = space_state.intersect_shape(shape_query)
        
        # Check each collision
        for collision in result:
            var collider = collision["collider"]
            
            # Skip selected tower and preview
            if collider == selected_tower or collider == preview_tower:
                continue
                
            # Skip other towers (already checked above)
            if collider.is_in_group("Towers") or collider.is_in_group("BaseTower"):
                continue

            # Skip previews or temporary towers
            if collider.name == "MovementPreview" or collider.name == "PreviewTower" or "preview" in collider.name.to_lower():
                continue
                
            # Any other collision makes placement invalid
            valid_placement = false
            break
    
    # Update preview color based on validity
    update_preview_color()

func update_preview_color() -> void:
    if !preview_tower:
        return
        
    if !can_move:
        preview_tower.modulate = Color(0.5, 0.5, 1.0, 0.3)  # Blue tint during cooldown
    elif valid_placement:
        preview_tower.modulate = Color(0.5, 1.0, 0.5, 0.5)  # Green transparent
    else:
        preview_tower.modulate = Color(1.0, 0.5, 0.5, 0.5)  # Red transparent

func confirm_tower_move() -> bool:
    print("Confirming tower move: is_move_mode=", is_move_mode, " valid_placement=", valid_placement, 
          " can_move=", can_move, " selected_tower=", selected_tower != null)
          
    if !is_move_mode or !valid_placement or !can_move or !selected_tower:
        print("Cannot place tower: invalid conditions")
        return false
    
    # Store reference to the tower we're about to move
    var moved_tower = selected_tower
    
    # Move the tower to the new position
    moved_tower.global_position = preview_tower.global_position
    print("Tower moved to position: ", preview_tower.global_position)
    
    # Add to recently moved towers to prevent immediate reselection
    recently_moved_towers.append(moved_tower)
    recent_move_timer = 0.5  # 0.5 seconds cooldown before selection
    
    # Restore visibility - completely reset modulate property to default
    moved_tower.modulate = Color(1.0, 1.0, 1.0, 1.0)
    
    # Clean up preview properly
    if preview_tower:
        if preview_tower.get_parent() == self:
            preview_tower.queue_free()
        preview_tower = null
    
    # Reset state
    tower_being_moved = false
    selected_tower = null
    
    # Force the scene to update physics
    get_tree().call_deferred("process_frame")
    
    # Start cooldown
    start_move_cooldown()
    
    return true
    
func cancel_tower_move() -> void:
    if selected_tower:
        # Restore visibility - completely reset modulate
        selected_tower.modulate = Color(1.0, 1.0, 1.0, 1.0)
    
    # Clean up preview properly
    if preview_tower:
        if preview_tower.get_parent() == self:
            preview_tower.queue_free()
        preview_tower = null
    
    # Reset state
    tower_being_moved = false
    selected_tower = null

func start_move_cooldown() -> void:
    can_move = false
    current_move_cooldown = move_cooldown