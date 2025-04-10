extends Node2D

signal build_state_changed(is_active)

var is_build_mode: bool = false
var preview_tower: Node2D = null
var base_tower_scene: PackedScene
var valid_placement: bool = false
# Add cooldown variables
var can_build: bool = true
var build_cooldown: float = 0.1  # 1 second cooldown
var current_cooldown: float = 0.0
# Add toggle cooldown variables
var can_toggle: bool = true
var toggle_cooldown: float = 0.3  # 300ms cooldown for toggle
var current_toggle_cooldown: float = 0.0
var move_controller = null 
var mode_label: Label
var mode_indicator: Control
var can_build_tower: bool = true

func _ready() -> void:
    base_tower_scene = load("res://Scene/Tower/base_tower.tscn")
    
    # Buat preview tower
    preview_tower = base_tower_scene.instantiate()
    preview_tower.set_name("PreviewTower")
    preview_tower.modulate.a = 0.5  # Transparan
    preview_tower.visible = false
    
    # Set z-index to make sure preview is always on top
    preview_tower.z_index = 100
    
    add_child(preview_tower)
    
    # Pastikan preview tidak mendeteksi collision
    if preview_tower.has_node("CollisionShape2D"):
        var collision = preview_tower.get_node("CollisionShape2D")
        collision.disabled = true
    
    # Sembunyikan UI options pada preview
    if preview_tower.has_node("TowerOptions"):
        preview_tower.get_node("TowerOptions").visible = false
    
    # Create a UI indicator for build mode
    var canvas_layer = CanvasLayer.new()
    canvas_layer.layer = 100
    add_child(canvas_layer)
    
    # Create container for the mode indicator - position at bottom left
    mode_indicator = Control.new()
    mode_indicator.name = "ModeIndicator"
    mode_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
    mode_indicator.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    mode_indicator.size = Vector2(200, 50)  # Wider container (350px instead of 200px)
    # Add margins
    mode_indicator.position = Vector2(20, -70)  # 20px from left, 70px from bottom
    mode_indicator.visible = false
    
    var bg = ColorRect.new()
    bg.color = Color(0.0, 0.0, 0.0, 0.5)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    mode_label = Label.new()
    mode_label.text = "BUILD MODE"
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
    mode_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
    mode_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
    mode_label.add_theme_constant_override("outline_size", 3)
    
    mode_indicator.add_child(bg)
    mode_indicator.add_child(mode_label)
    canvas_layer.add_child(mode_indicator)
    
    # Find move controller
    var parent = get_parent()
    move_controller = parent.find_child("MoveController", true, false)

func _process(delta: float) -> void:
    # Update cooldown timer
    if !can_build:
        current_cooldown -= delta
        if current_cooldown <= 0:
            can_build = true
            # Reset preview color when cooldown finishes
            update_preview_color()
    
    # Update toggle cooldown timer
    if !can_toggle:
        current_toggle_cooldown -= delta
        if current_toggle_cooldown <= 0:
            can_toggle = true
    # Only toggle if the cooldown allows it
    if (Input.is_key_pressed(KEY_B)) and can_toggle:
        # If we're not already in build mode, ensure we're entering it
        if !is_build_mode:
            # If move mode is active, exit it first
            if move_controller and move_controller.is_move_mode:
                move_controller.toggle_move_mode()
            
            # Then enter build mode
            toggle_build_mode()
        else:
            # If already in build mode, just exit
            toggle_build_mode()
        
        # Start toggle cooldown
        can_toggle = false
        current_toggle_cooldown = toggle_cooldown
    
    # Exit build mode if M is pressed (move mode toggle)
    if Input.is_key_pressed(KEY_M) and can_toggle and is_build_mode:
        toggle_build_mode()
        can_toggle = false
        current_toggle_cooldown = toggle_cooldown
    
    # Jika dalam build mode dan player klik, tempatkan tower
    if (Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and can_build:
        try_place_tower()
    if is_build_mode:
        update_preview_position()
        check_placement_validity()

func toggle_build_mode() -> void:
    is_build_mode = !is_build_mode
    preview_tower.visible = is_build_mode
    mode_indicator.visible = is_build_mode  # Show/hide the indicator only when in build mode
    emit_signal("build_state_changed", is_build_mode)
    
    # If entering build mode, ensure we're not interacting with any existing tower
    if is_build_mode:
        var player = Player.instance
        if player and player.in_base_tower != null:
            player.in_base_tower = null

func update_preview_position() -> void:
    if preview_tower:
        preview_tower.global_position = get_global_mouse_position()

func check_placement_validity() -> void:
    # Start with assuming placement is valid
    valid_placement = true
    
    # Get all towers in the scene
    var base_towers = get_tree().get_nodes_in_group("BaseTower")
    var towers = get_tree().get_nodes_in_group("Towers")
    var towers_in_scene = base_towers + towers
    # Set minimum allowed distance between towers
    var tower_radius = 45.0  # 32px radius as specified
    var min_distance = tower_radius * 2  # Need 2 times the radius (one for each tower)
    
    # Check distance to each existing tower
    for tower in towers_in_scene:
        # Skip preview tower itself
        if tower == preview_tower:
            continue
            
        # Check if close to existing tower
        var distance = tower.global_position.distance_to(preview_tower.global_position)
        if distance < min_distance:
            valid_placement = false
            break
    
    # Also check collision with obstacles (excluding player and valid build areas)
    if valid_placement:
        var space_state = get_world_2d().direct_space_state
        var shape_query = PhysicsShapeQueryParameters2D.new()
        
        # Dapatkan collision shape dari preview tower untuk digunakan dalam query
        var collision_shape = preview_tower.get_node("CollisionShape2D").shape
        shape_query.set_shape(collision_shape)
        shape_query.transform = Transform2D(0, preview_tower.global_position)
        
        # Exclude build areas (layer 1) and players (layer 2)
        shape_query.collision_mask = ~(1 << 0 | 1 << 1)  # Exclude layers 1 and 2
        
        var result = space_state.intersect_shape(shape_query)
        
        # If any collision was found (other than towers we've already checked), placement is invalid
        for collision in result:
            var collider = collision["collider"]
            # Skip the preview tower itself
            if collider == preview_tower:
                continue
                
            # Skip if the collider is a tower (already checked above)
            if collider.is_in_group("Towers") or collider.is_in_group("BaseTower"):
                continue
                
            # Any other collision makes the placement invalid
            valid_placement = false
            break
    
    # Update preview color based on validity
    update_preview_color()

func try_place_tower() -> bool:
    if !is_build_mode or !valid_placement or !can_build:
        return false
    
    # Buat tower baru
    var new_tower = base_tower_scene.instantiate()
    new_tower.global_position = preview_tower.global_position
    
    # Initialize the tower's build mode state before adding to scene
    if new_tower.has_method("initialize_build_mode"):
        new_tower.initialize_build_mode(is_build_mode)
    
    # Tambahkan tower ke scene tree (parent harus diatur di luar atau dipass sebagai parameter)
    var parent = get_parent()
    if parent.has_node("Towers"):
        parent.get_node("Towers").add_child(new_tower)
    else:
        parent.add_child(new_tower)
    
    # Connect signal to the newly added tower
    build_state_changed.connect(new_tower._on_build_state_changed)
    
    # Start cooldown after placing a tower
    start_build_cooldown()
    
    return true

func start_build_cooldown() -> void:
    can_build = false
    current_cooldown = build_cooldown
    # Visual feedback for cooldown
    preview_tower.modulate = Color(0.5, 0.5, 1.0, 0.3)  # Blue tint during cooldown

func update_preview_color() -> void:
    if !can_build:
        preview_tower.modulate = Color(0.5, 0.5, 1.0, 0.3)  # Blue tint during cooldown
    elif valid_placement:
        preview_tower.modulate = Color(0.5, 1.0, 0.5, 0.5)  # Hijau transparan
    else:
        preview_tower.modulate = Color(1.0, 0.5, 0.5, 0.5)  # Merah transparan
