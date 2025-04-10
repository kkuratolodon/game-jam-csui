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

var current_health: int :
    set(value):
        current_health = clamp(value, 0, max_health)
        health_changed.emit(current_health)

func _ready():
    path = get_parent()
    current_health = max_health
    hp_bar.max_value = max_health
    hp_bar.value = current_health

    health_changed.connect(func(new_health): hp_bar.value = new_health)

func take_damage(damage_taken: int, can_be_blocked: bool) -> void:
    if !can_be_blocked or !check_shield():
        current_health -= damage_taken

func check_shield() -> bool:
    if !shield:
        return false
    else:
        return shield.check_shield()