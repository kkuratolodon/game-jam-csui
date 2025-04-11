extends Node2D

var path : Path2D
var speed: float
var _can_deal_damage: bool = true

func _ready() -> void:
    # Get the path reference from owner
    path = owner.get_parent()
    speed = owner.speed

func _process(delta):
    # Check if enemy is dying, don't move if health is zero or below
    if owner.current_health <= 0:
        return
        
    owner.progress += speed * delta
    
    # Check if the owner node has reached the end of the path
    if owner.progress >= path.curve.get_baked_length() and _can_deal_damage:
        _can_deal_damage = false
        var castle_node = Castle.instance
        # Emit a signal or call a function to deal damage to the target
        castle_node.take_damage(owner.damage_dealt)
        # Optionally, you can queue_free() the arrow after dealing damage
        owner.queue_free()
