extends Node2D

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
        
        player.velocity = direction * player.move_speed
        
        player.move_and_slide()

        player.global_position.x = clamp(player.global_position.x, player.map_limits.position.x, player.map_limits.end.x)
        player.global_position.y = clamp(player.global_position.y, player.map_limits.position.y, player.map_limits.end.y)   