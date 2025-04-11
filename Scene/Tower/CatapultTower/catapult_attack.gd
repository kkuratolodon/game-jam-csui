extends Node2D

@export var projectile_scene: PackedScene
var cooldown_time: float

var attack_speed
var can_shoot: bool = true
var cooldown_timer: Timer
var damage: int

# Use the same static dictionary as archer to track all damage
static var damage_in_flight = {}

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
    if can_shoot and owner.best_target:
        var target_enemy = owner.best_target
        if target_enemy and is_instance_valid(target_enemy):
            shoot_projectile(target_enemy)

# Find a target that won't die from damage already in flight
func find_best_target() -> Node2D:
    var enemies = owner.enemies_in_area.duplicate()
    if enemies.size() == 0:
        return null
        
    # Sort by progress (farthest along path first)
    enemies.sort_custom(func(a, b): return a.progress > b.progress)
    
    # Find enemies that will survive current in-flight damage
    var valid_targets = []
    for enemy in enemies:
        if not is_instance_valid(enemy):
            continue
            
        # Only target enemies that won't die from existing in-flight damage
        if enemy.predicted_health > 0:
            valid_targets.append(enemy)
    
    # If we have valid targets, return the one furthest along the path
    if valid_targets.size() > 0:
        valid_targets.sort_custom(func(a, b): return a.progress > b.progress)
        return valid_targets[0]
    
    # If all enemies are predicted to die, return the one farthest along
    return enemies[0] if enemies.size() > 0 else null

func shoot_projectile(target: Node2D) -> void:
    if not can_shoot:
        return
    
    can_shoot = false
    cooldown_timer.start()
    
    if projectile_scene:
        owner.animation_tree.set("parameters/conditions/attack", true)
        
        # Store target reference and register damage
        var target_path = target.get_path() if target else null
        
        # Register the damage that will be dealt
        if is_instance_valid(target):
            target.register_incoming_damage(damage)
        
        await get_tree().create_timer(1.0/9.0).timeout
        owner.animation_tree.set("parameters/conditions/attack", false)
        
        # Check if target is still valid after the animation delay
        if target_path and get_node_or_null(target_path) and is_instance_valid(get_node(target_path)):
            var projectile_instance = projectile_scene.instantiate()
            var current_target = get_node(target_path)
            projectile_instance.init(current_target, damage, z_index, global_position)
            get_tree().current_scene.add_child(projectile_instance)
        else:
            # Target was destroyed during animation - cancel the damage prediction
            if is_instance_valid(target):
                target.cancel_incoming_damage(damage)
            print("Target destroyed during catapult animation")
    else:
        push_error("projectile scene not assigned in catapult_attack.gd")

func _on_cooldown_timer_timeout() -> void:
    can_shoot = true

# Call this when projectile hits or misses to remove damage from tracking
static func unregister_damage(enemy, damage_amount):
    var enemy_id = enemy.get_instance_id()
    if damage_in_flight.has(enemy_id):
        damage_in_flight[enemy_id] -= damage_amount
        if damage_in_flight[enemy_id] <= 0:
            damage_in_flight.erase(enemy_id)
