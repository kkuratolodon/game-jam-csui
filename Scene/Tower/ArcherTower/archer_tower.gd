extends StaticBody2D

# Called when the node enters the scene tree for the first time.

@export var archer : PackedScene

@onready var enemies_node := get_node("/root/Node2D/Enemies")

func _ready() -> void:
    await get_tree().create_timer(1.0).timeout
    spawn_archer(Vector2(0, -5))

func spawn_archer(offset : Vector2):
    var archer_instance = archer.instantiate()
    archer_instance.position = offset
    $Archer.add_child(archer_instance)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

