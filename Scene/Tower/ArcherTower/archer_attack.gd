extends Node2D

@export var arrow_scene: PackedScene
@export var cooldown_time: float = 1

var attack_speed := 1.0
var can_shoot: bool = true
var cooldown_timer: Timer
var damage: int

# Static dictionary to track damage in flight to each enemy
static var damage_in_flight = {}

func _ready() -> void:
    cooldown_time = ArcherTower.cooldown_time / attack_speed
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
            shoot_arrow(target_enemy)

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
    # (This is a fallback - ideally, we avoid shooting at doomed enemies)
    return enemies[0] if enemies.size() > 0 else null

func shoot_arrow(target: Node2D) -> void:
    if not can_shoot:
        return
    
    can_shoot = false
    cooldown_timer.start()
    
    if arrow_scene:
        # Check if target is still valid right before creating the arrow
        if is_instance_valid(target):
            var arrow_instance = arrow_scene.instantiate()
            
            # Register damage prediction with the enemy
            target.register_incoming_damage(damage)
            
            arrow_instance.init(target, damage, global_position)
            get_tree().current_scene.add_child(arrow_instance)
        else:
            # Target was destroyed between target acquisition and firing
            print("Target was destroyed before arrow could be fired")
    else:
        push_error("Arrow scene not assigned in archer_attack.gd")

func _on_cooldown_timer_timeout() -> void:
    can_shoot = true

# Call this when projectile hits or misses to remove damage from tracking
static func unregister_damage(enemy, damage_amount):
    var enemy_id = enemy.get_instance_id()
    if damage_in_flight.has(enemy_id):
        damage_in_flight[enemy_id] -= damage_amount
        if damage_in_flight[enemy_id] <= 0:
            damage_in_flight.erase(enemy_id)
