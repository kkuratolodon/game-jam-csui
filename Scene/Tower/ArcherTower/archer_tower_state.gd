extends RefCounted
class_name ArcherTowerState

# Properties yang berubah berdasarkan level
var attack_damage: int = 0
var attack_speed: float = 0
var attack_range: float = 0
var archer_count: int = 1

# Method yang akan diimplementasikan oleh setiap state
func enter_state(tower) -> void:
    pass
    
func exit_state(tower) -> void:
    pass
    
func update(tower, delta: float) -> void:
    pass
    
func get_level() -> int:
    return 0
    
func get_upgrade_cost() -> int:
    return 0