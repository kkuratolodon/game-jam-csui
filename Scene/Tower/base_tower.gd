extends Area2D
class_name BaseTower

# New variable to track build mode state
var is_build_mode_active: bool = false
var is_move_mode_active: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Add self to towers group for easier detection
    add_to_group("BaseTower")
    
    $TowerOptions/Container/ArcherPanel/ArcherButton.pressed.connect(_on_archer_button_pressed)
    $TowerOptions/Container/MagicPanel/MagicButton.pressed.connect(_on_magic_button_pressed)
    $TowerOptions/Container/CatapultPanel/CatapultButton.pressed.connect(_on_catapult_button_pressed)
    $TowerOptions/Container/GuardianPanel/GuardianButton.pressed.connect(_on_guardian_button_pressed)
    $TowerOptions.visible = false
    
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

func create_tower(tower_type: String) -> Node2D:
    var tower_options = {
        "ArcherTower": preload("res://Scene/Tower/ArcherTower/archer_tower.tscn"),
    }
    var new_tower = tower_options[tower_type].instantiate()
    new_tower.position = position
    get_parent().add_child(new_tower)
    queue_free()
    return new_tower

func _on_archer_button_pressed() -> void:
    create_tower("ArcherTower")

func _on_magic_button_pressed() -> void:
    create_tower("MagicTower")
    
func _on_catapult_button_pressed() -> void:
    create_tower("CatapultTower")
    
func _on_guardian_button_pressed() -> void:
    create_tower("GuardianTower")

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