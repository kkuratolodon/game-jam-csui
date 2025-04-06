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
    tower.clear_catapults()
    tower.roof.visible = has_roof
    tower.is_upgrading = true
    tower.anim.play("Tier%d-Upgrade" % (level-1))
    await tower.get_tree().create_timer(upgrade_duration/speed_up).timeout
    if is_spawn_catapult:
        for position in catapult_positions:
            tower.spawn_catapult(position)
    tower.is_upgrading = false
    tower.anim.play("Tier%d-Idle" % (level))
        
func exit_state(_tower) -> void:
    pass
    
func update(_tower, _delta: float) -> void:
    pass
