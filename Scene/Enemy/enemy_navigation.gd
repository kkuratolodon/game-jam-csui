extends NavigationAgent2D

@onready var target := get_node("/root/Node2D/Target") as Node2D
@onready var timer := Timer.new()

var _can_deal_damage: bool = true
var recalc_timer : Timer

func _ready() -> void:
    
    recalc_timer = Timer.new()
    recalc_timer.wait_time = 0.5
    recalc_timer.autostart = true
    recalc_timer.one_shot = false
    add_child(recalc_timer)
    recalc_timer.timeout.connect(_on_recalc_timer_timeout)
    await get_tree().process_frame
  
    make_path()

func _physics_process(delta: float) -> void:
    var current_agent_position: Vector2 = owner.global_position
    var next_path_position: Vector2 = get_next_path_position()
    var new_velocity = current_agent_position.direction_to(next_path_position) * owner.speed
    if avoidance_enabled:
        set_velocity(new_velocity)
    else:
        _on_navigation_agent_2d_velocity_computed(new_velocity)

func make_path() -> void:
    target_position = target.global_position

func _on_navigation_agent_2d_target_reached() -> void:
    if _can_deal_damage:
        _can_deal_damage = false
        var castle = Castle.instance
        castle.take_damage(owner.damage_dealt)
        owner.queue_free()


func _on_navigation_agent_2d_velocity_computed(safe_velocity:Vector2) -> void:
    owner.velocity = safe_velocity
    owner.move_and_slide()

func _on_recalc_timer_timeout() -> void:
    make_path()
