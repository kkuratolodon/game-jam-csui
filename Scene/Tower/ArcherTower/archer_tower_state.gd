class_name ArcherTowerState
extends Resource

@export var level: int = 1
@export var attack_damage: int = 5
@export var attack_speed: float = 1.0
@export var attack_range: float = 100.0
@export var archer_positions: Array[Vector2] = [Vector2(0, -5)]
@export var upgrade_duration: float = 1.0
@export var roof_position: Vector2 = Vector2.ZERO

func enter_state(tower: ArcherTower, is_spawn_archer: bool = true, speed_up: float = 1) -> void:
    if !is_instance_valid(tower):
        return
        
    tower.clear_archers()
    var has_roof = roof_position != Vector2.ZERO
    tower.roof.position = roof_position
    tower.roof.visible = has_roof and is_spawn_archer
    if has_roof:
        tower.roof.play("Tier%d-Upgrade" % (level-1))
    tower.is_upgrading = true
    tower.anim.play("Tier%d-Upgrade" % (level-1))
    
    # Store reference to tower for safe checking later
    var tower_ref = weakref(tower)
    
    await tower.get_tree().create_timer(upgrade_duration/speed_up).timeout
    
    # Check if tower still exists after the timer
    if !tower_ref.get_ref():
        print("Tower was freed during upgrade - aborting archer spawn")
        return
    
    if is_spawn_archer:
        for position in archer_positions:
            # Double check tower still exists before each archer spawn
            if tower_ref.get_ref() and is_instance_valid(tower):
                tower.spawn_archer(position)
            else:
                print("Tower was freed during archer spawning")
                return
    
    # Final check before setting states
    if tower_ref.get_ref() and is_instance_valid(tower):
        tower.is_upgrading = false
        tower.anim.play("Tier%d-Idle" % (level))
        if has_roof:
            tower.roof.play("Tier%d-Idle" % (level))
        
func exit_state(_tower) -> void:
    pass
    
func update(_tower, _delta: float) -> void:
    pass
