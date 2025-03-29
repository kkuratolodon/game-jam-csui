extends Node2D

@onready var castle = Castle.instance

func _ready() -> void:
    castle.health_changed.connect(_on_castle_health_changed)

func _on_castle_health_changed(new_health: int) -> void:
    var max_health = castle.max_health
    
    if float(new_health)/float(max_health) <= 0.5:
        print(new_health, " ",max_health)
        for child in castle.get_children():
            if child.has_node("AnimatedSprite2D"):
                child.get_node("AnimatedSprite2D").play("destroyed")
    print("Konz: " + str(new_health))