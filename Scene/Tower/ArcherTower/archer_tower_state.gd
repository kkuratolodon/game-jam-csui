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
    tower.clear_archers()
    var has_roof = roof_position != Vector2.ZERO
    tower.roof.position = roof_position
    tower.roof.visible = has_roof and is_spawn_archer
    if has_roof:
        tower.roof.play("Tier%d-Upgrade" % (level-1))
    tower.is_upgrading = true
    tower.anim.play("Tier%d-Upgrade" % (level-1))
    await tower.get_tree().create_timer(upgrade_duration/speed_up).timeout
    if is_spawn_archer:
        for position in archer_positions:
            tower.spawn_archer(position)
    tower.is_upgrading = false
    tower.anim.play("Tier%d-Idle" % (level))
    if has_roof:
        tower.roof.play("Tier%d-Idle" % (level))
        
func exit_state(_tower) -> void:
    pass
    
func update(_tower, _delta: float) -> void:
    pass
