extends Node2D

@export var projectile_scene: PackedScene
var cooldown_time: float

var attack_speed
var can_shoot: bool = true
var cooldown_timer: Timer
var damage: int

func _ready() -> void:
    attack_speed = owner.attack_speed
    damage = owner.damage
    can_shoot = false
    # await get_tree().create_timer(1.0).timeout
    can_shoot = true
    cooldown_time = CatapultTower.cooldown_time / attack_speed
    print("cooldown time", cooldown_time)
    cooldown_timer = Timer.new()
    cooldown_timer.wait_time = cooldown_time
    cooldown_timer.one_shot = true
    cooldown_timer.autostart = false
    add_child(cooldown_timer)
    cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)

func _process(delta: float) -> void:
    # print(can_shoot)
    if can_shoot and owner.nearest_enemy:
        # print("can shoot")
        var target_enemy = owner.nearest_enemy
        print(target_enemy)
        if target_enemy and is_instance_valid(target_enemy):
            shoot_projectile(target_enemy)
    # else:
    #     print("cannot shoot", can_shoot, owner.nearest_enemy)

func shoot_projectile(target: Node2D) -> void:
    if not can_shoot:
        return
    
    can_shoot = false
    cooldown_timer.start()
    
    if projectile_scene:
        owner.animation_tree.set("parameters/conditions/attack", true)
        # owner.animation_tree.set("parameters/conditions/attack", false)
        await get_tree().create_timer(1.0/9.0).timeout
        owner.animation_tree.set("parameters/conditions/attack", false)
        var projectile_instance = projectile_scene.instantiate()
        projectile_instance.init(target, damage, z_index, global_position)
        
        get_tree().current_scene.add_child(projectile_instance)
    else:
        push_error("projectile scene not assigned in catapult_attack.gd")
    

func _on_cooldown_timer_timeout() -> void:
    can_shoot = true
