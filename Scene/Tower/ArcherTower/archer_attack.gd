extends Node2D

@export var arrow_scene: PackedScene
@export var cooldown_time: float = 1  # Time between shots in seconds

var can_shoot: bool = true
var cooldown_timer: Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Setup cooldown timer
    cooldown_timer = Timer.new()
    cooldown_timer.wait_time = cooldown_time
    cooldown_timer.one_shot = true
    cooldown_timer.autostart = false
    add_child(cooldown_timer)
    cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    # Check if we can shoot and if there's an enemy to target
    if can_shoot and owner.nearest_enemy:
        var target_enemy = owner.nearest_enemy
        if target_enemy and is_instance_valid(target_enemy):
            shoot_arrow(target_enemy)

func shoot_arrow(target: Node2D) -> void:
    # Don't shoot if we're on cooldown
    if not can_shoot:
        return
    
    # Start cooldown
    can_shoot = false
    cooldown_timer.start()
    
    # Instantiate arrow and initialize with target
    if arrow_scene:
        var arrow_instance = arrow_scene.instantiate()
        arrow_instance.init(target, global_position)
        
        # Add arrow to scene tree (add to the main scene rather than as a child of this node)
        get_tree().current_scene.add_child(arrow_instance)
    else:
        push_error("Arrow scene not assigned in archer_attack.gd")

func _on_cooldown_timer_timeout() -> void:
    can_shoot = true