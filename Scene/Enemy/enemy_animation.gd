extends Node2D

var last_position: Vector2
var direction: Vector2

@onready var animation_tree = $"../AnimationTree"
@onready var nav_agent := $"../../NavigationAgent2D" as NavigationAgent2D

func _ready() -> void:
    last_position = global_position

func _process(delta: float) -> void:
    direction = to_local(nav_agent.get_next_path_position()).normalized()
    
    animation_tree.set("parameters/blend_position", direction)
    
    last_position = global_position
