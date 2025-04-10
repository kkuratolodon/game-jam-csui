extends Node2D

signal move_state_changed(is_active)

var is_move_mode: bool = false
var selected_tower = null
var preview_tower: Node2D = null
var valid_placement: bool = false
var original_position: Vector2 = Vector2.ZERO
var build_controller = null

var can_move: bool = true
var move_cooldown: float = 0.5
var current_move_cooldown: float = 0.0

var can_toggle: bool = true
var toggle_cooldown: float = 0.3
var current_toggle_cooldown: float = 0.0

var can_click: bool = true
var click_cooldown: float = 0.2
var current_click_cooldown: float = 0.0

var tower_being_moved: bool = false

var mode_label: Label

var recently_moved_towers = []
var recent_move_timer = 0.0

var compatible_tower: Node2D = null

func _ready() -> void:
    
    var canvas_layer = CanvasLayer.new()
    canvas_layer.layer = 100
    add_child(canvas_layer)
    
    # Create mode indicator label
    mode_label = Label.new()
    mode_label.text = "MOVE MODE"
    mode_label.visible = false
    mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    mode_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    
    # Make label fill the entire container
    mode_label.set_anchors_preset(Control.PRESET_FULL_RECT)
    mode_label.size_flags_horizontal = Control.SIZE_FILL
    mode_label.size_flags_vertical = Control.SIZE_FILL
    
    # Style the label
    var font_size = 32
    
    # Load custom font
    var custom_font = load("res://Assets/Font/CraftPixNet Survival Kit.otf")
    mode_label.add_theme_font_override("font", custom_font)
    
    mode_label.add_theme_font_size_override("font_size", font_size)
    mode_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
    mode_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
    mode_label.add_theme_constant_override("outline_size", 3)
    
    # Add a container and background for the label - position at bottom left
    var container = Control.new()
    container.name = "ModeIndicator"
    container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    container.size = Vector2(200, 50)  # Wider container (350px instead of 200px)
    # Add margins
    container.position = Vector2(20, -70)  # 20px from left, 70px from bottom
    container.visible = false  # Start hidden
    
    var bg = ColorRect.new()
    bg.color = Color(0.0, 0.0, 0.0, 0.5)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    container.add_child(bg)
    container.add_child(mode_label)
    canvas_layer.add_child(container)
    
    var parent = get_parent()
    build_controller = parent.find_child("BuildController", true, false)

func _process(delta: float) -> void:
    if recently_moved_towers.size() > 0:
        recent_move_timer -= delta
        if recent_move_timer <= 0:
            recently_moved_towers.clear()
    
    if !can_move:
        current_move_cooldown -= delta
        if current_move_cooldown <= 0:
            can_move = true
            if preview_tower:
                update_preview_color()
    
    if !can_toggle:
        current_toggle_cooldown -= delta
        if current_toggle_cooldown <= 0:
            can_toggle = true
    
    if !can_click:
        current_click_cooldown -= delta
        if current_click_cooldown <= 0:
            can_click = true
    
    if Input.is_key_pressed(KEY_M) and can_toggle:
        if !is_move_mode:
            if build_controller and build_controller.is_build_mode:
                build_controller.toggle_build_mode()
            
            toggle_move_mode()
        else:
            if tower_being_moved:
                cancel_tower_move()
            toggle_move_mode()
        
        can_toggle = false
        current_toggle_cooldown = toggle_cooldown
    
    if Input.is_key_pressed(KEY_B) and can_toggle and is_move_mode:
        if tower_being_moved:
            cancel_tower_move()
        toggle_move_mode()
        
        can_toggle = false
        current_toggle_cooldown = toggle_cooldown
    
    if Input.is_key_pressed(KEY_ESCAPE) and is_move_mode:
        toggle_move_mode()
    
    if is_move_mode:
        if tower_being_moved:
            update_preview_position()
            check_placement_validity()
            
            if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
                if can_click and can_move and valid_placement:
                    confirm_tower_move()
                    can_click = false
                    current_click_cooldown = click_cooldown
        else:
            if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
                if can_click:
                    try_select_tower()
                    can_click = false
                    current_click_cooldown = click_cooldown

func toggle_move_mode() -> void:
    if is_move_mode and tower_being_moved and selected_tower:
        selected_tower.modulate = Color(1.0, 1.0, 1.0, 1.0)
    
    is_move_mode = !is_move_mode
    
    mode_label.visible = is_move_mode
    mode_label.get_parent().visible = is_move_mode  # Show/hide the container
    
    print("Move mode toggled: ", is_move_mode)
    
    if preview_tower:
        if preview_tower.get_parent() == self:
            preview_tower.queue_free()
        preview_tower = null
    
    tower_being_moved = false
    selected_tower = null
    
    emit_signal("move_state_changed", is_move_mode)
    
func try_select_tower() -> void:
    var mouse_position = get_global_mouse_position()
    var base_towers = get_tree().get_nodes_in_group("BaseTower")
    var towers = get_tree().get_nodes_in_group("Towers")
    var closest_tower = null
    var closest_distance = 50.0
    
    for tower in base_towers:
        if recently_moved_towers.has(tower):
            print("Skipping recently moved tower: ", tower)
            continue
            
        if tower.name == "PreviewTower" or "preview" in tower.name.to_lower():
            continue
            
        var distance = tower.global_position.distance_to(mouse_position)
        if distance < closest_distance:
            closest_tower = tower
            closest_distance = distance
    
    for tower in towers:
        if recently_moved_towers.has(tower):
            print("Skipping recently moved tower: ", tower)
            continue
            
        if tower.name == "PreviewTower" or "preview" in tower.name.to_lower():
            continue
            
        var distance = tower.global_position.distance_to(mouse_position)
        if distance < closest_distance:
            closest_tower = tower
            closest_distance = distance
    
    if closest_tower:
        selected_tower = closest_tower
        if selected_tower.get("is_upgrading"):
            selected_tower = null
            return
        original_position = selected_tower.global_position
        
        create_preview_tower()
        tower_being_moved = true

func create_preview_tower() -> void:
    # Create a sprite-only preview
    preview_tower = Node2D.new()
    preview_tower.name = "MovementPreview"
    preview_tower.z_index = 100
    
    # Find and duplicate the sprite from the tower
    var tower_sprite = find_sprite_in_tower(selected_tower)
    if tower_sprite:
        # Create a visual representation that matches the original tower
        create_sprite_preview(tower_sprite)
    else:
        # Fallback if no sprite is found
        var fallback = Sprite2D.new()
        fallback.modulate = Color(0.5, 0.5, 1.0, 0.5)
        preview_tower.add_child(fallback)
    
    preview_tower.modulate = Color(0.5, 0.5, 1.0, 0.5)
    selected_tower.modulate.a = 0.3
    
    add_child(preview_tower)
    update_preview_position()

# Helper function to create a more accurate sprite preview
func create_sprite_preview(original_sprite: Node) -> void:
    var new_sprite = null
    
    # Determine the sprite's global transform relative to its tower
    var original_transform = original_sprite.get_global_transform()
    var tower_transform = selected_tower.get_global_transform()
    var relative_transform = tower_transform.affine_inverse() * original_transform
    
    if original_sprite is Sprite2D:
        new_sprite = Sprite2D.new()
        new_sprite.texture = original_sprite.texture
        new_sprite.hframes = original_sprite.hframes
        new_sprite.vframes = original_sprite.vframes
        new_sprite.frame = original_sprite.frame
        
        # Copy all relevant visual properties
        new_sprite.offset = original_sprite.offset
        new_sprite.centered = original_sprite.centered
        new_sprite.flip_h = original_sprite.flip_h
        new_sprite.flip_v = original_sprite.flip_v
        
    elif original_sprite is AnimatedSprite2D:
        new_sprite = AnimatedSprite2D.new()
        new_sprite.sprite_frames = original_sprite.sprite_frames
        new_sprite.animation = original_sprite.animation
        new_sprite.frame = original_sprite.frame
        
        # Copy animation state if playing
        if original_sprite.is_playing():
            new_sprite.play()
            
        # Copy other properties
        new_sprite.centered = original_sprite.centered
        new_sprite.flip_h = original_sprite.flip_h
        new_sprite.flip_v = original_sprite.flip_v
    
    if new_sprite:
        # Apply the relative transformation to maintain proper positioning
        # This helps preserve the sprite's position and scale relative to the tower
        preview_tower.add_child(new_sprite)
        new_sprite.transform = relative_transform
        
        # If still having size issues, directly copy the global scale
        new_sprite.global_scale = original_sprite.global_scale

# Helper function to find a sprite in a tower
func find_sprite_in_tower(tower_node: Node) -> Node:
    # Check if the tower itself is a sprite
    if tower_node is Sprite2D or tower_node is AnimatedSprite2D:
        return tower_node
    
    # Search for sprites in children
    for child in tower_node.get_children():
        if child is Sprite2D or child is AnimatedSprite2D:
            return child
        
        # Recursive search in children
        var sprite = find_sprite_in_tower(child)
        if sprite:
            return sprite
    
    return null

func update_preview_position() -> void:
    if preview_tower:
        preview_tower.global_position = get_global_mouse_position()

func check_placement_validity() -> void:
    if !preview_tower:
        valid_placement = false
        return
        
    valid_placement = true
    
    var is_base_tower = selected_tower.is_in_group("BaseTower")
    var towers_in_scene = get_tree().get_nodes_in_group("Towers")
    var base_towers = get_tree().get_nodes_in_group("BaseTower")
    
    for base_tower in base_towers:
        if !towers_in_scene.has(base_tower):
            towers_in_scene.append(base_tower)
    
    var tower_radius = 45.0
    var min_distance = tower_radius * 2
    
    # Standard checks for all tower types (minimum distance from other towers)
    for tower in towers_in_scene:
        if tower == selected_tower or tower == preview_tower:
            continue
            
        if tower.name == "MovementPreview" or tower.name == "PreviewTower" or "preview" in tower.name.to_lower():
            continue
        var distance = tower.global_position.distance_to(preview_tower.global_position)
        if distance < min_distance:
            valid_placement = false
            break
    
    # Special handling for non-BaseTower towers
    if !is_base_tower:
        # For non-BaseTower, it MUST intersect with a compatible tower
        compatible_tower = check_for_compatible_tower_intersection(towers_in_scene)
        valid_placement = compatible_tower != null and !compatible_tower.get("is_upgrading")
    
    if valid_placement and is_base_tower:
        get_tree().call_deferred("process_frame")
        
        var space_state = get_world_2d().direct_space_state
        var shape_query = PhysicsShapeQueryParameters2D.new()
        
        # Use collision shape from original tower instead of preview
        if !selected_tower.has_node("CollisionShape2D"):
            print("Selected tower missing CollisionShape2D")
            valid_placement = false
            return
            
        var collision_shape = selected_tower.get_node("CollisionShape2D").shape
        shape_query.set_shape(collision_shape)
        shape_query.transform = Transform2D(0, preview_tower.global_position)
        
        shape_query.collision_mask = ~(1 << 0 | 1 << 1)
        
        var result = space_state.intersect_shape(shape_query)
        
        for collision in result:
            var collider = collision["collider"]
            
            if collider == selected_tower or collider == preview_tower:
                continue
                
            if collider.is_in_group("Towers") or collider.is_in_group("BaseTower"):
                continue

            if collider.name == "MovementPreview" or collider.name == "PreviewTower" or "preview" in collider.name.to_lower():
                continue
                
            valid_placement = false
            break
    
    update_preview_color()

func check_for_compatible_tower_intersection(towers_in_scene: Array) -> Node2D:
    var intersection_radius = 60.0
    var found_compatible_tower = false
    var compatible_tower = null
    
    # Check for intersection with towers of same type and level
    for tower in towers_in_scene:
        if tower == selected_tower or tower == preview_tower:
            continue
        if tower.name == "MovementPreview" or tower.name == "PreviewTower" or "preview" in tower.name.to_lower():
            continue
        # Check if the tower is of the same type and level
        # Adjust these property names based on your actual implementation
        if tower.has_method("get_type") and selected_tower.has_method("get_type") and \
           tower.has_method("get_level") and selected_tower.has_method("get_level"):
            if tower.get_type() == selected_tower.get_type() and \
               tower.get_level() == selected_tower.get_level():
                if tower.get_level() < tower.max_level:
                    # Check if within intersection radius
                    var distance = tower.global_position.distance_to(preview_tower.global_position)
                    if distance <= intersection_radius:
                        found_compatible_tower = true
                        compatible_tower = tower
                        break
        
    # For non-BaseTower, placement is valid only if it intersects with a compatible tower
    return compatible_tower

func update_preview_color() -> void:
    if !preview_tower:
        return
        
    if !can_move:
        preview_tower.modulate = Color(0.5, 0.5, 1.0, 0.3)
    elif valid_placement:
        preview_tower.modulate = Color(0.5, 1.0, 0.5, 0.5)
    else:
        preview_tower.modulate = Color(1.0, 0.5, 0.5, 0.5)

func confirm_tower_move() -> bool:
    print("Confirming tower move: is_move_mode=", is_move_mode, " valid_placement=", valid_placement, 
          " can_move=", can_move, " selected_tower=", selected_tower != null)
          
    if !is_move_mode or !valid_placement or !can_move or !selected_tower:
        print("Cannot place tower: invalid conditions")
        return false
    
    var moved_tower = selected_tower
    var is_base_tower = moved_tower.is_in_group("BaseTower")
    if is_base_tower:
        moved_tower.global_position = preview_tower.global_position
        print("Tower moved to position: ", preview_tower.global_position)
        
        recently_moved_towers.append(moved_tower)
        recent_move_timer = 0.5
        
        moved_tower.modulate = Color(1.0, 1.0, 1.0, 1.0)
    else:
        moved_tower.queue_free()
        compatible_tower.upgrade_tower()

    if preview_tower:
        if preview_tower.get_parent() == self:
            preview_tower.queue_free()
        preview_tower = null
    
    tower_being_moved = false
    selected_tower = null
    
    get_tree().call_deferred("process_frame")
    
    start_move_cooldown()
    
    return true
    
func cancel_tower_move() -> void:
    if selected_tower:
        selected_tower.modulate = Color(1.0, 1.0, 1.0, 1.0)
    
    if preview_tower:
        if preview_tower.get_parent() == self:
            preview_tower.queue_free()
        preview_tower = null
    
    tower_being_moved = false
    selected_tower = null

func start_move_cooldown() -> void:
    can_move = false
    current_move_cooldown = move_cooldown
