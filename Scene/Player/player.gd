extends CharacterBody2D
class_name Player
static var instance: Player = null

var in_base_tower: BaseTower
var money : int : 
    set(value):
        money = value
        money_changed.emit(money)
@export var map_limits: Rect2 = Rect2(0, 0, 1920, 1080) # Sesuaikan dengan ukuran map Anda
@export var move_speed: float = 200.0

signal money_changed(new_health)

func _enter_tree() -> void:
    if instance != null:
        queue_free()
        return
    
    instance = self
    money = Config.start_money

static func get_instance() -> CharacterBody2D:
    return instance

func _process(delta: float) -> void:
    if in_base_tower:
        if Input.is_key_pressed(KEY_SPACE):
            var tower = in_base_tower.create_tower("ArcherTower")
            get_parent().add_child(tower)

func _exit_tree() -> void:
    if instance == self:
        instance = null
