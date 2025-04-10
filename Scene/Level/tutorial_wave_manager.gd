extends Node

class_name TutorialWaveManager

@export var enemy_paths: NodePath
@export var ui: NodePath
@export var tutorial_enemy_count: int = 10
@export var spawn_interval_min: float = 1.0
@export var spawn_interval_max: float = 2.0
@export var start_delay: float = 3.0

var paths_node
var ui_node
var enemy_count: int = 0
var active_enemies: int = 0
var spawn_timer: Timer
var has_started: bool = false
var is_completed: bool = false
var victory_panel_scene = preload("res://Scene/UI/victory_panel.tscn")
var victory_panel

func _ready():
    paths_node = get_node(enemy_paths)
    ui_node = get_node(ui)
    
    # Connect signals
    if ui_node and ui_node.has_signal("wave_started"):
        ui_node.wave_started.connect(_on_wave_started)
    
    # Create timer
    spawn_timer = Timer.new()
    spawn_timer.one_shot = true
    add_child(spawn_timer)
    spawn_timer.timeout.connect(_on_spawn_timer)
    
    # Start the tutorial wave after a delay
    get_tree().create_timer(start_delay).timeout.connect(func(): 
        if ui_node and ui_node.has_method("start_tutorial_wave"):
            ui_node.start_tutorial_wave()
    )

func _on_wave_started():
    if !has_started:
        has_started = true
        _start_spawn_sequence()

func _start_spawn_sequence():
    # Schedule first enemy spawn
    _schedule_next_spawn()
    
func _schedule_next_spawn():
    if enemy_count >= tutorial_enemy_count:
        print("All enemies scheduled for tutorial wave")
        return
        
    var interval = randf_range(spawn_interval_min, spawn_interval_max)
    spawn_timer.start(interval)

func _on_spawn_timer():
    # Spawn an enemy
    if enemy_count < tutorial_enemy_count:
        # Alternate between paths 0 and 1
        var path_index = enemy_count % 2
        var enemy = paths_node.spawn(path_index, 0)  # Always use enemy type 0 for tutorial
        
        if enemy:
            active_enemies += 1
            enemy_count += 1
            
            # Connect to enemy death to track active enemies
            if enemy.has_signal("health_changed"):
                enemy.health_changed.connect(func(health): 
                    if health <= 0:
                        active_enemies -= 1
                        _check_wave_completion()
                )
            
            print("Spawned tutorial enemy " + str(enemy_count) + "/" + str(tutorial_enemy_count))
            
            # Schedule next spawn if we still have more enemies to spawn
            if enemy_count < tutorial_enemy_count:
                _schedule_next_spawn()
        else:
            print("Failed to spawn enemy")
            # Try again
            spawn_timer.start(1.0)

func _check_wave_completion():
    if enemy_count >= tutorial_enemy_count and active_enemies <= 0 and !is_completed:
        is_completed = true
        print("Tutorial wave completed!")
        # Show victory panel
        _show_victory_panel()

func _show_victory_panel():
    if !victory_panel:
        victory_panel = victory_panel_scene.instantiate()
        get_tree().root.add_child(victory_panel)
        
        # Connect continue button if available
        if victory_panel.has_node("ContinueButton"):
            victory_panel.get_node("ContinueButton").pressed.connect(func():
                # Handle continue button press - could transition to next level
                victory_panel.queue_free()
            )
