extends Area2D
class_name Castle

signal health_changed(new_health)

static var instance : Castle

var max_health: int = Config.start_hp
var current_health: int :
    set(value):
        current_health = clamp(value, 0, max_health)
        health_changed.emit(current_health)

func _enter_tree():
    if instance == null:
        instance = self
    else:
        queue_free()
    current_health = max_health



func take_damage(damage: int):
    current_health -= damage
    # if current_health <= 0:
    #     queue_free()

func _on_area_entered(area:Area2D) -> void:
    print(area)
    pass # Replace with function body.
