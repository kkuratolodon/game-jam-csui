extends Area2D

var attack_counter: int = 0
var block_timer: Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Setup timer for block animation duration
    block_timer = Timer.new()
    block_timer.one_shot = true
    block_timer.wait_time = 0.5  # Block animation duration in seconds
    block_timer.timeout.connect(_on_block_timer_timeout)
    add_child(block_timer)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

func _on_area_entered(area:Area2D) -> void:
    print("Area entered: " + area.name)

func check_shield() -> bool:
    # Check if the shield is active
    attack_counter += 1
    if attack_counter >= 3:
        attack_counter = 0
        # Set parent enemy's blocking state to true
        var parent_enemy = get_parent()
        parent_enemy.is_blocking = true
        # Start timer to reset blocking state
        block_timer.start()
        return true
    else:
        return false

func _on_block_timer_timeout() -> void:
    # Reset parent's blocking state
    var parent_enemy = get_parent()
    parent_enemy.is_blocking = false
