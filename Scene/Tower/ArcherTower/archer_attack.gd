extends Node2D

@export var arrow_scene: PackedScene
@export var cooldown_time: float = 1.0

var attack_speed := 1.0
var can_shoot: bool = true
var cooldown_timer: Timer
var damage: int

func _ready() -> void:
    cooldown_time = 1.0 / attack_speed
    cooldown_timer = Timer.new()
    cooldown_timer.wait_time = cooldown_time
    cooldown_timer.one_shot = true
    cooldown_timer.autostart = false
    add_child(cooldown_timer)
    cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)

func _process(delta: float) -> void:
    if can_shoot and owner.nearest_enemy:
        var target_enemy = owner.nearest_enemy
        if target_enemy and is_instance_valid(target_enemy):
            shoot_arrow(target_enemy)

func shoot_arrow(target: Node2D) -> void:
    if not can_shoot:
        return
    
    can_shoot = false
    cooldown_timer.start()
    
    if arrow_scene:
        var arrow_instance = arrow_scene.instantiate()
        arrow_instance.init(target, damage, global_position)
        
        get_tree().current_scene.add_child(arrow_instance)
    else:
        push_error("Arrow scene not assigned in archer_attack.gd")

func _on_cooldown_timer_timeout() -> void:
    can_shoot = true