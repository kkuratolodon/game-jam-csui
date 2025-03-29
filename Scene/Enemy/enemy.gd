extends CharacterBody2D

signal health_changed(new_health)

@export var speed: float = 100
@export var damage_dealt: int = 10
@export var max_health: int = 100

@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
@onready var timer := Timer.new()
@onready var hp_bar = $HealthBar

var current_health: int :
    set(value):
        current_health = clamp(value, 0, max_health)
        health_changed.emit(current_health)

func _ready():
    current_health = max_health
    hp_bar.max_value = max_health
    hp_bar.value = current_health

    health_changed.connect(func(new_health): hp_bar.value = new_health)

func take_damage(damage_taken: int):
    current_health -= damage_taken
    if current_health <= 0:
        queue_free()
