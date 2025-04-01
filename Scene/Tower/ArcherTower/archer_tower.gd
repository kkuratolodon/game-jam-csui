class_name ArcherTower
extends StaticBody2D

# Called when the node enters the scene tree for the first time.
static var buy_cost := 75

@export var archer : PackedScene
@export var tower_levels: Array[ArcherTowerState] = []
@onready var anim = $AnimationPlayer
@onready var enemies_node := get_node("/root/Node2D/Enemies")
@onready var current_state: ArcherTowerState = null
@onready var roof: AnimatedSprite2D = $Roof
@onready var max_level = tower_levels.size()
@onready var start_level = Config.archer_start_level

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

func clear_archers() -> void:
    for child in $Archer.get_children():
        child.queue_free()

func get_type() -> String:
    return "ArcherTower"
    
func get_level() -> int:
    if current_state and current_state is ArcherTowerState:
        return current_state.level
    return 0