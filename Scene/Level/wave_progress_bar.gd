extends TextureProgressBar

@onready var arrow = $Arrow
var spawner_position = Vector2.ZERO
var screen_size = Vector2.ZERO
var player_node = null  # Reference to the player node
var debug_counter = 0   # For reducing debug output frequency
var script_ready = false

func _init():
    # Initialize script
    print("[PROG_BAR] _init() called")

func _ready():
    print("[PROG_BAR] _ready() called")
    script_ready = true
    
    # Initialize
    value = 0
    min_value = 0
    max_value = 100
    screen_size = get_viewport_rect().size
    
    # Initial positioning will be updated in process
    position = Vector2(screen_size.x/2, screen_size.y/2)
    
    # Make sure arrow is visible and properly setup
    if arrow:
        arrow.visible = true
        
        # Debug print arrow properties
        print("[PROG_BAR] Arrow found: ", arrow)
        print("[PROG_BAR] Arrow properties - position:", arrow.position, " size:", arrow.size, " pivot:", arrow.pivot_offset)
    else:
        push_error("[PROG_BAR] ERROR: Arrow not found!")
    
    # Try to find player instance globally if not set
    if player_node == null:
        find_player()
    
    # Initialize angle if possible
    if player_node and spawner_position != Vector2.ZERO and arrow:
        update_arrow_direction()

func _process(delta):
    # Critical debug to see if _process is being called
    debug_counter += 1
    
    if not script_ready:
        return
    
    # Update player reference if lost
    if player_node == null or !is_instance_valid(player_node):
        find_player()
    
    if spawner_position != Vector2.ZERO and player_node and is_instance_valid(player_node):
        # Get player's position
        var player_pos = player_node.global_position
        
        # Calculate the direction vector from player to spawner
        var to_spawner = spawner_position - player_pos
        var direction = to_spawner.normalized()
        
        # Position the bar at the edge of the screen in the direction of the spawner
        position_at_screen_edge(direction)
        
        # Update arrow direction
        update_arrow_direction()

func position_at_screen_edge(direction):
    # Get viewport center
    var viewport = get_viewport()
    var center = Vector2(screen_size.x/2, screen_size.y/2)
    
    # Calculate margin to keep bar visible
    var margin = 50
    
    # Calculate position on screen edge
    var edge_pos = center
    
    # Determine which edge to place the bar on based on the direction vector
    # This uses the most significant component of the direction vector
    if abs(direction.x) > abs(direction.y):
        # Horizontal placement (left or right edge)
        if direction.x > 0:
            # Right edge
            edge_pos.x = screen_size.x - size.x * scale.x - margin
        else:
            # Left edge
            edge_pos.x = margin
        
        # Y position proportional to direction.y but clamped to screen
        edge_pos.y = center.y + (direction.y * center.y)
        edge_pos.y = clamp(edge_pos.y, margin + size.y * scale.y/2, screen_size.y - margin - size.y * scale.y/2)
    else:
        # Vertical placement (top or bottom edge)
        if direction.y > 0:
            # Bottom edge
            edge_pos.y = screen_size.y - size.y * scale.y - margin
        else:
            # Top edge
            edge_pos.y = margin
        
        # X position proportional to direction.x but clamped to screen
        edge_pos.x = center.x + (direction.x * center.x)
        edge_pos.x = clamp(edge_pos.x, margin + size.x * scale.x/2, screen_size.x - margin - size.x * scale.x/2)
    
    # Set the progress bar position
    position = edge_pos

func update_arrow_direction():
    # Point the arrow towards the spawner
    if arrow and player_node and is_instance_valid(player_node):
        # Use the global player instance position
        var player_pos = player_node.global_position
        var to_spawner = spawner_position - player_pos
        
        # Calculate angle from player to spawner
        var angle = to_spawner.angle()
        
        # Add 180 degrees to point in the correct direction
        angle = angle + PI
        
        # Set the arrow rotation
        arrow.rotation = angle
        
        # Make sure arrow is visible
        arrow.visible = true
    

func find_player():
    # Try to find player in the scene tree
    var scene_tree = get_tree()
    if scene_tree:
        var player_nodes = scene_tree.get_nodes_in_group("player")
        if player_nodes.size() > 0:
            player_node = player_nodes[0]
            return
        
        var root = scene_tree.get_root()
        player_node = root.find_child("Player", true, false)

# Set the spawner's position
func set_spawner_position(pos):
    spawner_position = pos
    
    # Apply rotation immediately
    if player_node and is_instance_valid(player_node) and arrow:
        var to_spawner = spawner_position - player_node.global_position
        var angle = to_spawner.angle() + PI  # Add 180 degrees
        arrow.rotation = angle

# Set the player reference
func set_player(player):
    player_node = player
    
    if player_node and spawner_position != Vector2.ZERO and arrow:
        var to_spawner = spawner_position - player_node.global_position
        var angle = to_spawner.angle() + PI  # Add 180 degrees
        arrow.rotation = angle
