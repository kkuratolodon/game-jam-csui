extends Control

@onready var castle = Castle.instance
@onready var player = Player.instance
@onready var health_label = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Panel/HBoxContainer/HeartLabel
@onready var money_label = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Panel2/HBoxContainer/MoneyLabel
@onready var wave_label = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/Panel3/HBoxContainer/WaveLabel

signal wave_started

func _ready() -> void:
    castle.health_changed.connect(_on_castle_health_changed)
    player.money_changed.connect(_on_money_changed)
    _on_money_changed(player.money)
    _on_castle_health_changed(castle.current_health)
    
    # Initialize wave label for tutorial
    wave_label.text = "0/1"
    
func _on_castle_health_changed(new_health: int) -> void:
    print("Castle health changed to: " + str(new_health))
    health_label.text = str(new_health)

func _on_money_changed(new_money: int) -> void:
    print("Money to: " + str(new_money))
    money_label.text = str(new_money)
    
# New method that gets called when the wave changes
func _on_wave_changed(current_wave: int, total_waves: int) -> void:
    print("Wave changed to: " + str(current_wave) + "/" + str(total_waves))
    wave_label.text = str(current_wave) + "/" + str(total_waves)
    
    # If wave changes from 0 to 1, emit the wave_started signal
    if current_wave == 1 and current_wave <= total_waves:
        emit_signal("wave_started")

