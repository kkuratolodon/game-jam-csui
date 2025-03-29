extends Node2D

var move_speed: float = 200.0

func _physics_process(delta: float) -> void:
    var player = Player.get_instance()
    if player:
        var direction = Vector2.ZERO
        if Input.is_action_pressed("ui_right"):
            direction.x += 1 + 1e-5
        if Input.is_action_pressed("ui_left"):
            direction.x -= 1 + 1e-5
        if Input.is_action_pressed("ui_down"):
            direction.y += 1
        if Input.is_action_pressed("ui_up"):
            direction.y -= 1

        direction = direction.normalized()
        
        player.velocity = direction * move_speed
        
        player.move_and_slide()