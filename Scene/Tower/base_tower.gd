extends Area2D
class_name BaseTower

# New variable to track build mode state
var is_build_mode_active: bool = false
var is_move_mode_active: bool = false

# Tower costs
var TOWER_COSTS = {
    "ArcherTower": ArcherTower.buy_cost,
    "MagicTower": 0,
    "CatapultTower": CatapultTower.buy_cost,
    "GuardianTower": 0
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    get_tree().set_debug_collisions_hint(true)
    # Add self to towers group for easier detection
    add_to_group("BaseTower")
    $TowerOptions.visible = false
    
    # Setup cost labels
    $TowerOptions/Container/ArcherPanel/CostLabel.text = str(TOWER_COSTS["ArcherTower"]) 
    $TowerOptions/Container/MagicPanel/CostLabel.text = str(TOWER_COSTS["MagicTower"]) 
    $TowerOptions/Container/CatapultPanel/CostLabel.text = str(TOWER_COSTS["CatapultTower"])
    $TowerOptions/Container/GuardianPanel/CostLabel.text = str(TOWER_COSTS["GuardianTower"])
    
    # Try to find the build controller and connect to its signal
    var main_scene = get_tree().root.get_child(0)
    var build_controller = main_scene.find_child("BuildController", true, false)
    if build_controller:
        if not build_controller.build_state_changed.is_connected(_on_build_state_changed):
            build_controller.build_state_changed.connect(_on_build_state_changed)
        # Initialize with current build mode state
        initialize_build_mode(build_controller.is_build_mode)
        
    # Connect to move controller
    var move_controller = main_scene.find_child("MoveController", true, false)
    if move_controller:
        if not move_controller.move_state_changed.is_connected(_on_move_state_changed):
            move_controller.move_state_changed.connect(_on_move_state_changed)
        # Initialize with current move mode state
        initialize_move_mode(move_controller.is_move_mode)

# New method to initialize build mode state
func initialize_build_mode(build_mode_state: bool) -> void:
    is_build_mode_active = build_mode_state
    # Hide options if build mode is active
    if is_build_mode_active and $TowerOptions.visible:
        $TowerOptions.visible = false

func _on_build_state_changed(is_active: bool) -> void:
    is_build_mode_active = is_active
    # If build mode is activated and options are visible, hide them
    if is_active and $TowerOptions.visible:
        $TowerOptions.visible = false
        # Also inform player that we're no longer interacting with tower
        var player = Player.instance
        if player and player.in_base_tower == self:
            player.in_base_tower = null

func _process(delta: float) -> void:
    pass

func _on_body_entered(body: Node2D) -> void:
    # Only allow interaction if not in build mode AND not in move mode
    if body.name == "Player" and !is_build_mode_active and !is_move_mode_active:
        var player = Player.instance
        player.in_base_tower = self
        $TowerOptions.visible = true
        

func _on_body_exited(body: Node2D) -> void:
    if body.name == "Player":
        var player = Player.instance
        player.in_base_tower = null
        $TowerOptions.visible = false
        hide_all_cost_labels()
        $TowerOptions/Container/ErrorMessage.visible = false

# Method to check if player can afford a tower
func can_afford_tower(tower_type: String) -> bool:
    var player = Player.instance
    if player and TOWER_COSTS.has(tower_type):
        print( player.money , TOWER_COSTS[tower_type])
        return player.money >= TOWER_COSTS[tower_type]
    return false

# Method to create a tower if player has enough money
func create_tower(tower_type: String) -> Node2D:
    print("konz")
    if can_afford_tower(tower_type) and tower_type in ["ArcherTower", "CatapultTower", ]:
        var tower_options = {
            "ArcherTower": preload("res://Scene/Tower/ArcherTower/archer_tower.tscn"),
            # "MagicTower": preload("res://Scene/Tower/MagicTower/magic_tower.tscn"),
            "CatapultTower": preload("res://Scene/Tower/CatapultTower/catapult_tower.tscn"),
            # "GuardianTower": preload("res://Scene/Tower/GuardianTower/guardian_tower.tscn"),
        }
        
        if tower_options.has(tower_type):
            # Deduct cost from player's money
            Player.instance.money -= TOWER_COSTS[tower_type]
            
            # Create the tower
            var new_tower = tower_options[tower_type].instantiate()
            new_tower.position = position
            get_parent().add_child(new_tower)
            get_parent().move_child(new_tower, 0)
            queue_free()
            return new_tower
    elif !can_afford_tower(tower_type):
        # Show error message when player can't afford it
        $TowerOptions/Container/ErrorMessage.visible = true
        $TowerOptions/Container/ErrorMessage.text = "Not enough money!"
        # Hide after 2 seconds
        get_tree().create_timer(2.0).timeout.connect(func(): $TowerOptions/Container/ErrorMessage.visible = false)
    elif tower_type == "GuardianTower":
        # Show error message when player tries to create Guardian Tower
        $TowerOptions/Container/ErrorMessage.visible = true
        $TowerOptions/Container/ErrorMessage.text = "Guardian Tower is\nnot available yet!"
        # Hide after 2 seconds
        get_tree().create_timer(2.0).timeout.connect(func(): $TowerOptions/Container/ErrorMessage.visible = false)
    elif tower_type == "MagicTower":
        # Show error message when player tries to create Magic Tower
        $TowerOptions/Container/ErrorMessage.visible = true
        $TowerOptions/Container/ErrorMessage.text = "Magic Tower is\nnot available yet!"
        # Hide after 2 seconds
        get_tree().create_timer(2.0).timeout.connect(func(): $TowerOptions/Container/ErrorMessage.visible = false)
    else:
        print("Invalid tower type or tower type not supported.")

    return null

# Hide all cost labels
func hide_all_cost_labels() -> void:
    $TowerOptions/Container/ArcherPanel/CostLabel.visible = false
    $TowerOptions/Container/MagicPanel/CostLabel.visible = false
    $TowerOptions/Container/CatapultPanel/CostLabel.visible = false
    $TowerOptions/Container/GuardianPanel/CostLabel.visible = false

# Update cost label color based on affordability
func update_cost_label_color(label: Label, tower_type: String) -> void:
    if can_afford_tower(tower_type):
        label.add_theme_color_override("font_color", Color(0.2, 1, 0.2))
    else:
        label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

# Button press event handlers
func _on_archer_button_pressed() -> void:
    create_tower("ArcherTower")

func _on_magic_button_pressed() -> void:
    create_tower("MagicTower")
    
func _on_catapult_button_pressed() -> void:
    create_tower("CatapultTower")
    
func _on_guardian_button_pressed() -> void:
    create_tower("GuardianTower")

# Mouse hover event handlers
func _on_archer_button_mouse_entered() -> void:
    hide_all_cost_labels()
    var label = $TowerOptions/Container/ArcherPanel/CostLabel
    update_cost_label_color(label, "ArcherTower")
    label.visible = true

func _on_magic_button_mouse_entered() -> void:
    hide_all_cost_labels()
    var label = $TowerOptions/Container/MagicPanel/CostLabel
    update_cost_label_color(label, "MagicTower")
    label.visible = true

func _on_catapult_button_mouse_entered() -> void:
    hide_all_cost_labels()
    var label = $TowerOptions/Container/CatapultPanel/CostLabel
    update_cost_label_color(label, "CatapultTower")
    label.visible = true

func _on_guardian_button_mouse_entered() -> void:
    hide_all_cost_labels()
    var label = $TowerOptions/Container/GuardianPanel/CostLabel
    update_cost_label_color(label, "GuardianTower")
    label.visible = true

func _on_tower_button_mouse_exited() -> void:
    hide_all_cost_labels()

func _on_mouse_entered() -> void:
    if !is_build_mode_active:
        _on_body_entered(Player.instance)

func _on_container_mouse_exited() -> void:
    if !is_build_mode_active:
        _on_body_exited(Player.instance)
        
func initialize_move_mode(move_mode_state: bool) -> void:
    is_move_mode_active = move_mode_state
    # Hide options if move mode is active
    if is_move_mode_active and $TowerOptions.visible:
        $TowerOptions.visible = false
        # Also inform player that we're no longer interacting with tower
        var player = Player.instance
        if player and player.in_base_tower == self:
            player.in_base_tower = null

func _on_move_state_changed(is_active: bool) -> void:
    is_move_mode_active = is_active
    # If move mode is activated and options are visible, hide them
    if is_active and $TowerOptions.visible:
        $TowerOptions.visible = false
        # Also inform player that we're no longer interacting with tower
        var player = Player.instance
        if player and player.in_base_tower == self:
            player.in_base_tower = null