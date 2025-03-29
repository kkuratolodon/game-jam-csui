extends Control

@onready var castle = Castle.instance
@onready var health_label = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Label

func _ready() -> void:
    castle.health_changed.connect(_on_castle_health_changed)
    _on_castle_health_changed(castle.current_health)
    health_label.custom_minimum_size = Vector2(60, health_label.custom_minimum_size.y)
func _on_castle_health_changed(new_health: int) -> void:
    print("Castle health changed to: " + str(new_health))
    health_label.text = "HP: " + str(new_health)