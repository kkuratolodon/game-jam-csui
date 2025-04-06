extends Control

@onready var castle = Castle.instance
@onready var player = Player.instance
@onready var health_label = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Panel/HBoxContainer/HeartLabel
@onready var money_label = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Panel2/HBoxContainer/MoneyLabel

func _ready() -> void:
    castle.health_changed.connect(_on_castle_health_changed)
    player.money_changed.connect(_on_money_changed)
    _on_money_changed(player.money)
    _on_castle_health_changed(castle.current_health)
    
func _on_castle_health_changed(new_health: int) -> void:
    print("Castle health changed to: " + str(new_health))
    health_label.text = str(new_health)

func _on_money_changed(new_money: int) -> void:
    print("Money to: " + str(new_money))
    money_label.text = str(new_money)

