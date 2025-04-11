extends Node2D

@export var wave_progress_bar: PackedScene
@export var spawner_location: Node2D

# Game state
var game_can_start = false  # Game starts frozen until config is loaded
var game_initialized = false  # Flag to track if game has been initialized

# Wave configuration
var current_wave = 0
var total_waves = 5
var wave_active = false
var wave_complete = false
var spawn_timer = 0
var enemies_remaining = 0

# Wave transition timing
const WAVE_TRANSITION_TIME = 15.0  # 15 seconds between waves
const INITIAL_TRANSITION_TIME = 5.0  # 5 seconds before first wave
var transition_timer = 0.0
var in_transition = false  # Changed to false initially
var progress_bar_instance = null

# Wave timing
var wave_timer = 0.0     # Tracks the current time within a wave
var wave_duration = 45.0  # Default wave duration (can be adjusted per wave)

# UI references
@onready var ui = $CanvasLayer/InGameUi
@onready var enemy_paths = $EnemyPaths

# Wave data structure - Each wave defines what enemies to spawn and when
# Format: [path_index, enemy_index, spawn_time_in_seconds]
var waves = [
    # Wave 1: Gentle introduction with more enemies
    [
        # Path 1 enemies
        [1, 0, 0.0],   # Goblin at 0s
        [1, 0, 5.0],   # Goblin at 5s
        [1, 0, 10.0],  # Goblin at 10s
        [1, 0, 15.0],  # Goblin at 15s
        [1, 0, 20.0],  # Goblin at 20s
        [1, 0, 25.0],  # Goblin at 25s
        [1, 0, 30.0],  # Goblin at 30s
        [1, 0, 35.0],  # Goblin at 35s
        [1, 0, 38.0],  # Goblin at 38s
    ],
    
    # Wave 2: Both paths with faster spawns
    [
        # Path 0 enemies
        [0, 0, 0.0],   # Goblin at 0s
        [0, 0, 4.0],   # Goblin at 4s
        [0, 0, 8.0],   # Goblin at 8s
        [0, 0, 12.0],  # Goblin at 12s
        [0, 0, 16.0],  # Goblin at 16s
        [0, 0, 22.0],  # Goblin at 22s
        [0, 0, 28.0],  # Goblin at 28s
        [0, 0, 34.0],  # Goblin at 34s
        
        # Path 1 enemies too (both paths at once)
        [1, 0, 2.0],   # Goblin at 2s
        [1, 0, 6.0],   # Goblin at 6s
        [1, 0, 10.0],  # Goblin at 10s
        [1, 0, 20.0],  # Goblin at 20s
        [1, 0, 26.0],  # Goblin at 26s
        [1, 0, 32.0],  # Goblin at 32s
        [1, 0, 38.0],  # Goblin at 38s
    ],
    
    # Wave 3: Introducing knights earlier with coordinated attacks
    [
        # Path 0 enemies
        [0, 0, 0.0],   # Goblin at 0s
        [0, 1, 4.0],   # Knight at 4s - Early knight!
        [0, 0, 8.0],   # Goblin at 8s
        [0, 0, 12.0],  # Goblin at 12s
        [0, 0, 16.0],  # Goblin at 16s
        [0, 1, 20.0],  # Knight at 20s
        [0, 0, 24.0],  # Goblin at 24s
        [0, 0, 28.0],  # Goblin at 28s
        [0, 0, 32.0],  # Goblin at 32s
        [0, 1, 36.0],  # Knight at 36s
        
        # Path 1 enemies - alternating pattern for challenge
        [1, 0, 2.0],   # Goblin at 2s
        [1, 0, 6.0],   # Goblin at 6s
        [1, 1, 10.0],  # Knight at 10s
        [1, 0, 14.0],  # Goblin at 14s
        [1, 0, 18.0],  # Goblin at 18s
        [1, 1, 22.0],  # Knight at 22s
        [1, 0, 26.0],  # Goblin at 26s
        [1, 0, 30.0],  # Goblin at 30s
        [1, 1, 34.0],  # Knight at 34s
        [1, 0, 38.0],  # Goblin at 38s
    ],
    
    # Wave 4: Introducing knights but carefully
    [
        # Path 0 enemies
        [0, 0, 0.0],   # Goblin at 0s
        [0, 0, 7.0],   # Goblin at 7s
        [0, 0, 14.0],  # Goblin at 14s
        [0, 1, 21.0],  # Knight at 21s (first knight!)
        [0, 0, 28.0],  # Goblin at 28s
        [0, 0, 35.0],  # Goblin at 35s
        
        # Path 1 enemies
        [1, 0, 3.0],   # Goblin at 3s
        [1, 0, 10.0],  # Goblin at 10s
        [1, 0, 17.0],  # Goblin at 17s
        [1, 0, 24.0],  # Goblin at 24s
        [1, 1, 31.0],  # Knight at 31s (second knight, different path)
        [1, 0, 38.0],  # Goblin at 38s
    ],
    
    # Wave 5: Final challenge with coordinated attacks
    [
        # Path 0 enemies
        [0, 0, 0.0],   # Goblin at 0s
        [0, 0, 6.0],   # Goblin at 6s
        [0, 1, 12.0],  # Knight at 12s
        [0, 0, 18.0],  # Goblin at 18s
        [0, 0, 24.0],  # Goblin at 24s
        [0, 1, 30.0],  # Knight at 30s
        [0, 0, 36.0],  # Goblin at 36s
        
        # Path 1 enemies
        [1, 0, 3.0],   # Goblin at 3s
        [1, 0, 9.0],   # Goblin at 9s
        [1, 0, 15.0],  # Goblin at 15s
        [1, 1, 21.0],  # Knight at 21s
        [1, 0, 27.0],  # Goblin at 27s
        [1, 1, 33.0],  # Knight at 33s
        [1, 0, 39.0],  # Goblin at 39s
    ]
]

var current_wave_spawns = []
var spawned_indices = []  # Tracks which enemies have been spawned

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Connect to Config's user_data_updated signal
    if Config.has_signal("user_data_updated"):
        Config.user_data_updated.connect(_on_user_data_updated)
        print("Connected to Config.user_data_updated signal. Waiting for data...")
        
        # Check if data is already loaded (immediate start)
        if Config.user_data != null:
            call_deferred("_on_user_data_updated")
    else:
        print("WARNING: Config doesn't have user_data_updated signal")
        # Fallback in case the signal doesn't exist - start the game anyway
        call_deferred("_on_user_data_updated")
    
    # Setup UI connection
    ui.wave_started.connect(_on_wave_started)
    
    # Initialize the wave label to show 0/5
    ui._on_wave_changed(current_wave, total_waves)
    
    # Freeze player and disable input
    var player_node = $Player
    if player_node and player_node.has_method("set_process_input"):
        player_node.set_process_input(false)
        player_node.set_physics_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    # Don't process anything until game can start
    if not game_can_start:
        return
        
    # Initialize game on the first frame after data is loaded
    if not game_initialized:
        game_initialized = true
        start_initial_transition()
        return
    
    if in_transition:
        # Handle transition countdown
        transition_timer -= delta
        
        # Update progress bar
        if progress_bar_instance:
            var max_time = INITIAL_TRANSITION_TIME if current_wave == 0 else WAVE_TRANSITION_TIME
            var progress = 100 - (transition_timer / max_time * 100)
            progress_bar_instance.value = progress
        
        # Start wave when transition timer is done
        if transition_timer <= 0:
            in_transition = false
            
            # Remove progress bar
            if progress_bar_instance:
                progress_bar_instance.queue_free()
                progress_bar_instance = null
            
            # Now we can start the wave
            if current_wave < total_waves:
                prepare_wave(current_wave)
                wave_active = true  # Activate the wave immediately
                wave_timer = 0.0  # Explicit reset here
            else:
                print("All waves complete!")
    
    # Only process wave spawning if wave is active and not in transition
    elif wave_active and !in_transition:
        # Update wave timer
        wave_timer += delta
        
        # Spawn enemies at their designated times
        for i in range(current_wave_spawns.size()):
            var spawn_data = current_wave_spawns[i]
            
            # Check if it's time to spawn this enemy
            if wave_timer >= spawn_data[2] and i not in spawned_indices:
                spawn_enemy(spawn_data[0], spawn_data[1])
                spawned_indices.append(i)
                enemies_remaining -= 1
        
        # Check if wave is complete
        if is_wave_complete():
            end_wave()

# Called when Config's user data is updated
func _on_user_data_updated():
    print("Config user data updated! Starting game...")
    game_can_start = true
    
    # Unfreeze player movement
    var player_node = $Player
    if player_node:
        player_node.set_process_input(true)
        player_node.set_physics_process(true)
    
    # We'll start the initial transition in the next _process frame
    # This ensures we don't create any objects during signal callback

func start_initial_transition() -> void:
    print("Starting initial transition of 5 seconds before first wave")
    in_transition = true
    transition_timer = INITIAL_TRANSITION_TIME
    
    # Create and setup progress bar
    setup_progress_bar()

func setup_progress_bar() -> void:
    # Remove any existing progress bar
    if progress_bar_instance:
        progress_bar_instance.queue_free()
    
    # Create a new progress bar instance
    if wave_progress_bar:
        progress_bar_instance = wave_progress_bar.instantiate()
        
        # Explicitly set the script if needed
        var script = load("res://Scene/Level/wave_progress_bar.gd")
        if script:
            progress_bar_instance.set_script(script)
        else:
            push_error("Could not load wave_progress_bar.gd script")
        
        # Add progress bar to scene after configuring the script
        $CanvasLayer.add_child(progress_bar_instance)
        
        # Reset progress value
        progress_bar_instance.value = 0
        
        # Connect the button click signal
        var button = progress_bar_instance.get_node("Button")
        if button:
            button.pressed.connect(_on_progress_bar_button_pressed)
            
            # Add hover animation signals to the button
            button.mouse_entered.connect(_on_progress_bar_hover)
            button.mouse_exited.connect(_on_progress_bar_unhover)
        
        # Set the player reference for dynamic arrow updates - FIXED VERSION
        var player_node = $Player
        if player_node:
            # Add player to a group for easier finding
            player_node.add_to_group("player")
            
            if progress_bar_instance.has_method("set_player"):
                progress_bar_instance.call_deferred("set_player", player_node)
            else:
                push_error("Progress bar doesn't have set_player method!")
        else:
            push_error("Player node not found!")
        
        # Set the spawner position so the arrow can point to it
        if spawner_location:
            # Get the spawner's global position
            var spawner_global_pos = spawner_location.global_position
            
            if progress_bar_instance.has_method("set_spawner_position"):
                progress_bar_instance.call_deferred("set_spawner_position", spawner_global_pos)
            else:
                push_error("Progress bar missing set_spawner_position method!")
        else:
            push_error("No spawner location set!")
        
        # Force process to run at least once to initialize everything
        progress_bar_instance.call_deferred("update_arrow_direction")

# Called when the progress bar button is clicked
func _on_progress_bar_button_pressed() -> void:
    print("Progress bar button clicked - proceeding to next wave")
    
    # If we're in a transition between waves, immediately end it
    if in_transition:
        # Skip the rest of the transition
        transition_timer = 0.0
        
        # This will trigger the end of transition in the next _process call
        # which will start the next wave
    elif wave_active:
        # If we're in an active wave, mark current wave as complete
        # but let any remaining spawning continue
        wave_active = false
        
        # Start transition to next wave
        start_wave_transition()

# Called when mouse hovers over the progress bar
func _on_progress_bar_hover() -> void:
    if progress_bar_instance:
        # Create a tween for hover animation
        var tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_ELASTIC)
        
        # Animate the entire progress bar to become slightly larger
        tween.tween_property(progress_bar_instance, "scale", Vector2(0.45, 0.45), 0.3)
        
        # Animate the button too
        var button = progress_bar_instance.get_node("Button")
        if button:
            # Pulse opacity for additional attention
            tween.parallel().tween_property(progress_bar_instance, "modulate:a", 0.9, 0.15)
            tween.parallel().tween_property(progress_bar_instance, "modulate:a", 1.0, 0.15)

# Called when mouse exits the progress bar
func _on_progress_bar_unhover() -> void:
    if progress_bar_instance:
        # Create a tween to return to normal size
        var tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_ELASTIC)
        
        # Return progress bar to normal size
        tween.tween_property(progress_bar_instance, "scale", Vector2(0.4, 0.4), 0.3)
        tween.parallel().tween_property(progress_bar_instance, "modulate:a", 1.0, 0.1)

# Called when mouse hovers over the progress bar button
func _on_progress_button_hover() -> void:
    if progress_bar_instance:
        # Create a tween for hover animation
        var tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_ELASTIC)
        
        # Animate the button to become slightly larger
        var button = progress_bar_instance.get_node("Button")
        if button:
            tween.tween_property(button, "scale", Vector2(1.15, 1.15), 0.3)
            
            # Also pulse the opacity slightly to draw attention
            tween.parallel().tween_property(button, "modulate:a", 0.85, 0.3)
            tween.parallel().tween_property(button, "modulate:a", 1.0, 0.3)

# Called when mouse exits the progress bar button
func _on_progress_button_unhover() -> void:
    if progress_bar_instance:
        # Create a tween to return to normal size
        var tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_ELASTIC)
        
        # Animate the button back to normal size
        var button = progress_bar_instance.get_node("Button")
        if button:
            tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.3)
            tween.parallel().tween_property(button, "modulate:a", 1.0, 0.1)

func prepare_wave(wave_index: int) -> void:
    print("Preparing wave ", wave_index + 1)
    current_wave = wave_index + 1
    
    # Update UI
    ui._on_wave_changed(current_wave, total_waves)
    
    # Reset spawn data and wave timer
    current_wave_spawns = []
    spawned_indices = []
    wave_timer = 0.0  # Reset wave timer here
    
    # Setup spawn data for this wave 
    enemies_remaining = 0  # Reset before counting
    if wave_index < waves.size():
        for spawn in waves[wave_index]:
            # Format: [path_index, enemy_index, spawn_time]
            current_wave_spawns.append(spawn)
            
            # Add to total enemies remaining
            enemies_remaining += 1

func spawn_enemy(path_index: int, enemy_index: int) -> void:
    print("Spawning enemy type ", enemy_index, " on path ", path_index)
    var enemy = enemy_paths.spawn(path_index, enemy_index)
    if enemy:
        # Connect to enemy defeat signal if needed
        print("Enemy spawned successfully")
    else:
        print("Failed to spawn enemy")

func is_wave_complete() -> bool:
    # Check if all enemies have been spawned and defeated
    return enemies_remaining <= 0

func end_wave() -> void:
    print("Wave ", current_wave, " complete!")
    wave_active = false
    
    # Start transition to next wave
    start_wave_transition()

func start_wave_transition() -> void:
    # Only start transition if not all waves are complete
    if current_wave >= total_waves:
        print("All waves completed!")
        return
    
    in_transition = true
    transition_timer = WAVE_TRANSITION_TIME
    
    # Setup progress bar for wave transition
    setup_progress_bar()

func _on_wave_started() -> void:
    print("Wave started signal received")
    # This gets called when the player clicks the start button in tutorial
    wave_active = true
    wave_timer = 0.0  # Reset timer when wave is manually started
