extends PathFollow2D

signal health_changed(new_health)


@export var speed: float = 100
@export var damage_dealt: int = 10
@export var max_health: int = 100
@export var money_reward: int = 10

@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
@onready var timer := Timer.new()
@onready var hp_bar = $HealthBar
@onready var shield = $Shield

var is_blocking : bool = false
var path : Path2D
var predicted_health: int # Track health after all in-flight damage

var current_health: int :
    set(value):
        current_health = clamp(value, 0, max_health)
        health_changed.emit(current_health)

func _ready():
    path = get_parent()
    current_health = max_health
    predicted_health = max_health
    hp_bar.max_value = max_health
    hp_bar.value = current_health

    health_changed.connect(func(new_health): hp_bar.value = new_health)

func take_damage(damage_taken: int, can_be_blocked: bool) -> void:
    if !can_be_blocked or !check_shield():
        current_health -= damage_taken
        # Update predicted health when actual damage is taken
        predicted_health = min(predicted_health, current_health)
        if current_health <= 0:
            Player.instance.money += money_reward

# Register incoming damage to update predicted health
func register_incoming_damage(damage_amount: int) -> void:
    predicted_health -= damage_amount
    
# Cancel incoming damage if projectile misses or is destroyed
func cancel_incoming_damage(damage_amount: int) -> void:
    predicted_health += damage_amount
    predicted_health = min(predicted_health, current_health)

func check_shield() -> bool:
    if !shield:
        return false
    else:
        return shield.check_shield()