class_name ArcherTower
extends StaticBody2D

# Called when the node enters the scene tree for the first time.

@export var archer : PackedScene
@export var tower_levels: Array[ArcherTowerState] = []
@onready var anim = $AnimationPlayer
@onready var enemies_node := get_node("/root/Node2D/Enemies")
@onready var current_state: ArcherTowerState = null
@onready var roof: AnimatedSprite2D = $Roof
@onready var max_level = tower_levels.size()

var buy_cost : int
var is_upgrading:=false
var current_level_index: int = 0
var type = "ArcherTower"
func _ready() -> void:
    add_to_group("Towers")
    if tower_levels.size() > 0:
        change_state(tower_levels[0])


func change_state(new_state: ArcherTowerState) -> void:
    if current_state:
        current_state.exit_state(self)
    
    current_state = new_state
    current_state.enter_state(self)

func upgrade_tower() -> bool:
    current_level_index += 1
    current_level_index = max_level - 1
    if current_level_index >= tower_levels.size():
        current_level_index = tower_levels.size() - 1
        return false
        
    change_state(tower_levels[current_level_index])
    return true

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