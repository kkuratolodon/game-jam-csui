class_name CatapultTowerState
extends Resource

@export var level: int = 1
@export var attack_damage: int = 5
@export var attack_speed: float = 1.0
@export var attack_range: float = 100.0
@export var catapult_positions: Array[Vector2] = [Vector2(0, -5)]
@export var upgrade_duration: float = 1.0
@export var has_roof: bool

func enter_state(tower: CatapultTower, is_spawn_catapult: bool = true, speed_up: float = 1) -> void:
    # Initial validity check
    if !is_instance_valid(tower):
        return
        
    tower.clear_catapults()
    tower.roof.visible = has_roof and is_spawn_catapult
    tower.is_upgrading = true
    tower.anim.play("Tier%d-Upgrade" % (level-1))
    
    # Store reference to tower for safe checking later
    var tower_ref = weakref(tower)
    
    await tower.get_tree().create_timer(upgrade_duration/speed_up).timeout
    
    # Check if tower still exists after the timer
    if !tower_ref.get_ref():
        print("Tower was freed during upgrade - aborting catapult spawn")
        return
    
    if is_spawn_catapult:
        for position in catapult_positions:
            # Double check tower still exists before each catapult spawn
            if tower_ref.get_ref() and is_instance_valid(tower):
                tower.spawn_catapult(position)
            else:
                print("Tower was freed during catapult spawning")
                return
    
    # Final check before setting states
    if tower_ref.get_ref() and is_instance_valid(tower):
        tower.is_upgrading = false
        tower.anim.play("Tier%d-Idle" % (level))
        
func exit_state(_tower) -> void:
    pass
    
func update(_tower, _delta: float) -> void:
    pass
