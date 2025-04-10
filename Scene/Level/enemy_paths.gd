extends Node2D

# Array of enemy scene resources that can be assigned in the editor
@export var enemy_scenes: Array[PackedScene] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # Check if enemy_scenes is configured
    print("EnemyPaths ready, enemy scenes count: ", enemy_scenes.size())
    if enemy_scenes.size() == 0:
        push_error("No enemy scenes configured in enemy_paths.gd - please add enemy scenes in Inspector")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

# Spawns an enemy of type enemy_index on the path at path_index
# Returns the spawned enemy instance or null if the indices are invalid
func spawn(path_index: int, enemy_index: int) -> Node:
    print("SPAWN METHOD CALLED - path_index:", path_index, ", enemy_index:", enemy_index)
    print("Child count:", get_child_count())
    
    # Validate indices
    if path_index < 0 or path_index >= get_child_count():
        print("Invalid path index: " + str(path_index))
        return null
    
    if enemy_scenes.size() == 0:
        print("No enemy scenes available - please add them in the Inspector")
        return null
    
    if enemy_index < 0 or enemy_index >= enemy_scenes.size():
        print("Invalid enemy index: " + str(enemy_index))
        return null
    
    # Get the specified path
    var path = get_child(path_index)
    print("Path found:", path, ", type:", typeof(path), ", is_Path2D:", path is Path2D)
    
    if not path is Path2D:
        print("Child at index " + str(path_index) + " is not a Path2D")
        return null
    
    # Validate path has curve
    if !path.curve:
        print("Path does not have a curve")
        return null
    
    # Instantiate the enemy
    var enemy_scene = enemy_scenes[enemy_index]
    if !enemy_scene:
        print("Enemy scene at index " + str(enemy_index) + " is null")
        return null
        
    print("Trying to instantiate enemy scene:", enemy_scene)
    var enemy_instance = enemy_scene.instantiate()
    
    # Add enemy to the path
    path.add_child(enemy_instance)
    print("Added enemy to path:", enemy_instance)
    
    # Set initial position on path (0.0 is the start of the path)
    if enemy_instance is PathFollow2D:
        enemy_instance.progress = 0.0
    
    print("Spawned enemy type " + str(enemy_index) + " on path " + str(path_index))
    return enemy_instance
