class_name ArcherTower
extends StaticBody2D

# Called when the node enters the scene tree for the first time.
static var buy_cost := 75
static var cooldown_time := 1.0
@export var archer : PackedScene
@export var tower_levels: Array[ArcherTowerState] = []
@onready var anim = $AnimationPlayer
@onready var enemies_node := get_node("/root/Node2D/Enemies")
@onready var current_state: ArcherTowerState = null
@onready var roof: AnimatedSprite2D = $Roof
@onready var max_level = tower_levels.size()
@onready var start_level = Config.archer_start_level
@onready var build_controller = get_node("/root/Node2D/BuildController")
@onready var move_controller = get_node("/root/Node2D/MoveController")

var debug_overlay: Node2D
var sell_price : int = 0
var is_upgrading:=false
var current_level_index: int = 0
var type = "ArcherTower"
func _ready() -> void:
    add_to_group("Towers")
    var speed_up = min((start_level),2.0)
    anim.speed_scale = (start_level)
    if tower_levels.size() > 0:
        if current_level_index < start_level - 2:
            change_state(tower_levels[0], false, speed_up)
        else:
            print(speed_up)
            change_state(tower_levels[0], true, speed_up)
    while current_level_index < start_level - 2:
        print("masuk")
        if current_level_index >= tower_levels.size():
            break
        await get_tree().create_timer(current_state.upgrade_duration/speed_up).timeout
        upgrade_tower(false, speed_up)
    if current_level_index < start_level - 1:
        print("masuk12")
        await get_tree().create_timer(current_state.upgrade_duration/speed_up).timeout
        upgrade_tower(true, speed_up)
    anim.speed_scale = 1
    
    # Update the sell price after initial setup
    update_sell_price()

    debug_overlay = Node2D.new()
    debug_overlay.name = "DebugOverlay"
    debug_overlay.z_index = 1000  # Very high z-index to always be on top
    add_child(debug_overlay)
    
    # Connect the overlay's draw signal
    debug_overlay.connect("draw", _on_debug_overlay_draw)

func change_state(new_state: ArcherTowerState, is_spawn_archer:bool = true, speed_up:float = 1) -> void:
    if current_state:
        current_state.exit_state(self)
    
    current_state = new_state
    current_state.enter_state(self, is_spawn_archer, speed_up)

func upgrade_tower( is_spawn_archer:bool = true, speed_up:float = 1) -> bool:
    current_level_index += 1
    # Check if we can upgrade by at least 1 level
    if current_level_index >= tower_levels.size():
        return false
    
    # First upgrade (+1)
    change_state(tower_levels[current_level_index], is_spawn_archer, speed_up) 
    
    # Update the sell price after upgrading
    update_sell_price()
    
    return true

# Calculate the total cost spent on the tower
func calculate_total_cost() -> int:
    print("current state", current_state)
    var current_level = current_state.level  # Convert from 0-indexed to 1-indexed
    if current_level <= start_level:
        # If we haven't upgraded past the start level, cost is just buy_cost
        return buy_cost
    else:
        # If we've upgraded, use the formula: 2^(current_level - start_level) * buy_cost
        var level_diff = current_level - start_level
        return pow(2, level_diff) * buy_cost

# Update the sell price (60% of total costs)
func update_sell_price() -> void:
    var total_cost = calculate_total_cost()
    sell_price = int(total_cost * 0.6)  # 60% of total cost

func spawn_archer(offset : Vector2) -> void:
    var archer_instance = archer.instantiate()
    archer_instance.position = offset
    
    # Pass the current state's attributes to the archer
    
    archer_instance.damage = current_state.attack_damage
    archer_instance.attack_speed = current_state.attack_speed
    archer_instance.attack_range = current_state.attack_range
    
    $Archer.add_child(archer_instance)

func clear_archers() -> void:
    for child in $Archer.get_children():
        child.queue_free()

func get_type() -> String:
    return "ArcherTower"
    
func get_level() -> int:
    if current_state and current_state is ArcherTowerState:
        return current_state.level
    return 0

# Replace these functions only
var show_debug_shapes := false

func _on_button_pressed() -> void:
    # Toggle debug visualization
    show_debug_shapes = !show_debug_shapes
    print("Debug shapes: ", "ON" if show_debug_shapes else "OFF")
    if debug_overlay:
        debug_overlay.queue_redraw()  # Queue redraw on the overlay, not self
        turn_off_other_debug_shapes()
        show_info_ui()
        show_sell_button()

func _process(delta: float) -> void:
    if show_debug_shapes and debug_overlay:
        debug_overlay.queue_redraw()  # Queue redraw on the overlay, not self
    if move_controller and build_controller:
        if move_controller.is_move_mode or build_controller.is_build_mode:
            show_debug_shapes = false
            if debug_overlay:
                debug_overlay.queue_redraw()  # Queue redraw on the overlay, not self
                show_info_ui()
                show_sell_button()
    else:
        print(move_controller, build_controller)
# Move drawing logic to the overlay's draw function
func _on_debug_overlay_draw() -> void:
    if !show_debug_shapes:
        return
    
    # Draw shapes for each archer
    for archer_instance in $Archer.get_children():
        var area = archer_instance.get_node_or_null("Area2D")
        if !area or !area.has_node("CollisionShape2D"):
            continue
            
        var collision_shape = area.get_node("CollisionShape2D")
        if !collision_shape or !collision_shape.shape:
            continue
        
        # Get positioning info - relative to the overlay
        var pos = archer_instance.position + area.position + collision_shape.position
        
        
        # Set colors based on enemy presence
        var fill_color = Color(0.3, 0.3, 0.3, 0.2)  # Darker gray with transparency when no enemies
        var outline_color = Color(0.4, 0.4, 0.4, 0.7)  # Darker gray outline
        print(archer_instance.nearest_enemy)
        if archer_instance.nearest_enemy:
            fill_color = Color(0, 1, 0, 0.1)  # Lighter green fill with more transparency
            outline_color = Color(0, 0.7, 0, 0.7)  # Darker green outline
        
        if collision_shape.shape is CapsuleShape2D:
            # Draw capsule shape
            var radius = collision_shape.shape.radius
            var height = collision_shape.shape.height
            
            # Use transform to handle rotation
            debug_overlay.draw_set_transform(pos, collision_shape.rotation, Vector2.ONE)
            
            # Calculate capsule parameters
            var half_height = height / 2
            var capsule_center_offset = half_height - radius
            
            # Create points for capsule polygon
            var points = []
            var segments = 32  # Number of segments for each semicircle
            
            # Top semicircle
            for i in range(segments + 1):
                var angle = PI + i * PI / segments
                var x = radius * cos(angle)
                var y = -capsule_center_offset + radius * sin(angle)
                points.append(Vector2(x, y))
            
            # Bottom semicircle
            for i in range(segments + 1):
                var angle = i * PI / segments
                var x = radius * cos(angle)
                var y = capsule_center_offset + radius * sin(angle)
                points.append(Vector2(x, y))
            
            # Draw filled capsule as one continuous shape
            debug_overlay.draw_colored_polygon(points, fill_color)
            
            # Draw outline
            for i in range(points.size() - 1):
                debug_overlay.draw_line(points[i], points[i + 1], outline_color, 1.5)
            # Connect last and first points to close the outline
            debug_overlay.draw_line(points[points.size() - 1], points[0], outline_color, 1.5)
            
            # Reset transform
            debug_overlay.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func turn_off_other_debug_shapes() -> void:
    for tower in get_tree().get_nodes_in_group("Towers"):
        if tower != self:
            tower.show_debug_shapes = false
            if tower.debug_overlay:
                tower.debug_overlay.queue_redraw() 
                tower.show_info_ui()
                tower.show_sell_button()

func show_info_ui() -> void:
    $CanvasLayer/TowerInfo.visible = show_debug_shapes
    $CanvasLayer/TowerInfo/LevelLabel.text = str(current_state.level)
    $CanvasLayer/TowerInfo/Panel2/Control/DamageLabel.text = str(current_state.attack_damage)
    $CanvasLayer/TowerInfo/Panel2/Control2/RangeLabel.text = str(current_state.attack_range)
    $CanvasLayer/TowerInfo/Panel2/Control3/CooldownLabel.text = "%.1f" % (ArcherTower.cooldown_time/current_state.attack_speed)

func show_sell_button() -> void:
    $SellPanel.visible = show_debug_shapes
    $SellPanel/CostLabel.text = '$'
    $SellPanel/CostLabel.add_theme_font_size_override("font_size", 24)

func _on_sell_button_pressed() -> void:
    if $SellPanel/CostLabel.text == '$':
        # First click - change text and size
        $SellPanel/CostLabel.text = str(sell_price)
        
        # Determine font size based on number of digits
        var digits = len(str(sell_price))
        var font_size = 16  # Default size for 1-2 digits
        
        if digits == 3:
            font_size = 14
        elif digits > 3:
            font_size = 12
            
        $SellPanel/CostLabel.add_theme_font_size_override("font_size", font_size)
    else:
        # Second click - sell the tower
        sell_tower()

func sell_tower() -> void:
    # Add the sell price to the player's resources
    var player = Player.instance
    if player:
        player.money += sell_price
    
    # Remove the tower from the scene
    queue_free()
