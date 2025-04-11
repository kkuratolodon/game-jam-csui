extends CanvasLayer

signal transition_finished

enum TransitionType {
    FADE,       # Simple fade transition
    DISSOLVE,   # Subtle noise-based dissolve
    SWEEP,      # Gentle horizontal sweep
    IRIS,       # Soft iris/circle transition
    RANDOM
}

var is_transitioning = false
var scene_to_load = ""

@onready var animation_player = $AnimationPlayer
@onready var fade_rect = $Fade
@onready var dissolve_rect = $Dissolve
@onready var sweep_rect = $Sweep
@onready var iris_rect = $Iris

func _ready():
    animation_player.play("RESET")
    
    # Create animations dynamically with subtle, elegant transitions
    _create_transition_animations()

func _create_transition_animations():
    # Simple Fade transition (most subtle)
    var fade_animation = Animation.new()
    fade_animation.length = 0.6  # Shorter animation
    
    var track_index = fade_animation.add_track(Animation.TYPE_VALUE)
    fade_animation.track_set_path(track_index, "Fade:modulate")
    fade_animation.track_insert_key(track_index, 0.0, Color(1, 1, 1, 0))
    fade_animation.track_insert_key(track_index, 0.6, Color(1, 1, 1, 1))
    fade_animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_CUBIC)
    
    track_index = fade_animation.add_track(Animation.TYPE_VALUE)
    fade_animation.track_set_path(track_index, "Fade:visible")
    fade_animation.track_insert_key(track_index, 0.0, true)
    
    animation_player.get_animation_library("").add_animation("fade", fade_animation)
    
    # Dissolve transition
    var dissolve_animation = Animation.new()
    track_index = dissolve_animation.add_track(Animation.TYPE_VALUE)
    dissolve_animation.track_set_path(track_index, "Dissolve:material:shader_parameter/progress")
    dissolve_animation.track_insert_key(track_index, 0.0, 0.0)
    dissolve_animation.track_insert_key(track_index, 1.0, 1.0)
    
    track_index = dissolve_animation.add_track(Animation.TYPE_VALUE)
    dissolve_animation.track_set_path(track_index, "Dissolve:visible")
    dissolve_animation.track_insert_key(track_index, 0.0, true)
    
    animation_player.get_animation_library("").add_animation("dissolve", dissolve_animation)
    
    # Sweep transition
    var sweep_animation = Animation.new()
    track_index = sweep_animation.add_track(Animation.TYPE_VALUE)
    sweep_animation.track_set_path(track_index, "Sweep:material:shader_parameter/progress")
    sweep_animation.track_insert_key(track_index, 0.0, 0.0)
    sweep_animation.track_insert_key(track_index, 1.0, 1.0)
    
    track_index = sweep_animation.add_track(Animation.TYPE_VALUE)
    sweep_animation.track_set_path(track_index, "Sweep:visible")
    sweep_animation.track_insert_key(track_index, 0.0, true)
    
    animation_player.get_animation_library("").add_animation("sweep", sweep_animation)
    
    # Iris transition
    var iris_animation = Animation.new()
    track_index = iris_animation.add_track(Animation.TYPE_VALUE)
    iris_animation.track_set_path(track_index, "Iris:material:shader_parameter/progress")
    iris_animation.track_insert_key(track_index, 0.0, 0.0)
    iris_animation.track_insert_key(track_index, 1.0, 1.0)
    
    track_index = iris_animation.add_track(Animation.TYPE_VALUE)
    iris_animation.track_set_path(track_index, "Iris:visible")
    iris_animation.track_insert_key(track_index, 0.0, true)
    
    animation_player.get_animation_library("").add_animation("iris", iris_animation)

# Change scene with a transition effect
func change_scene(target_scene: String, transition_type: int = TransitionType.FADE, duration: float = 0.7):
    if is_transitioning:
        return
        
    is_transitioning = true
    scene_to_load = target_scene
    
    # Add null check for all transition rects
    var has_fade = fade_rect != null
    var has_dissolve = dissolve_rect != null
    var has_sweep = sweep_rect != null
    var has_iris = iris_rect != null
    
    # Select a random transition that exists
    if transition_type == TransitionType.RANDOM:
        var available_transitions = []
        if has_fade: available_transitions.append(TransitionType.FADE)
        if has_dissolve: available_transitions.append(TransitionType.DISSOLVE)
        if has_sweep: available_transitions.append(TransitionType.SWEEP)
        if has_iris: available_transitions.append(TransitionType.IRIS)
        
        # If no transitions are available, default to simple fade
        if available_transitions.size() > 0:
            transition_type = available_transitions[randi() % available_transitions.size()]
        else:
            # Fall back to no transition if none are available
            get_tree().change_scene_to_file(target_scene)
            is_transitioning = false
            return
    
    # Reset all transition rects that exist
    if has_fade: fade_rect.visible = false
    if has_dissolve: dissolve_rect.visible = false
    if has_sweep: sweep_rect.visible = false
    if has_iris: iris_rect.visible = false
    
    # Get the animation name based on transition type, checking if it exists
    var animation_name = ""
    match transition_type:
        TransitionType.FADE:
            if has_fade:
                animation_name = "fade"
            else:
                # Fall back to another transition
                if has_dissolve: animation_name = "dissolve"
                elif has_sweep: animation_name = "sweep"
                elif has_iris: animation_name = "iris"
                else:
                    # No transitions available
                    get_tree().change_scene_to_file(target_scene)
                    is_transitioning = false
                    return
        TransitionType.DISSOLVE:
            if has_dissolve:
                animation_name = "dissolve"
            else:
                # Fall back to fade or another available transition
                if has_fade: animation_name = "fade"
                elif has_sweep: animation_name = "sweep"
                elif has_iris: animation_name = "iris"
                else:
                    get_tree().change_scene_to_file(target_scene)
                    is_transitioning = false
                    return
        TransitionType.SWEEP:
            if has_sweep:
                animation_name = "sweep"
            else:
                # Fall back
                if has_fade: animation_name = "fade"
                elif has_dissolve: animation_name = "dissolve"
                elif has_iris: animation_name = "iris"
                else:
                    get_tree().change_scene_to_file(target_scene)
                    is_transitioning = false
                    return
        TransitionType.IRIS:
            if has_iris:
                animation_name = "iris"
            else:
                # Fall back
                if has_fade: animation_name = "fade"
                elif has_dissolve: animation_name = "dissolve"
                elif has_sweep: animation_name = "sweep"
                else:
                    get_tree().change_scene_to_file(target_scene)
                    is_transitioning = false
                    return
    
    # Use a gentler default duration for smoother transitions
    animation_player.speed_scale = 0.7 / duration  # Slowed down a bit for smoothness
    
    # Play transition animation with proper easing
    animation_player.play(animation_name)
    await animation_player.animation_finished
    
    # Change the scene
    get_tree().change_scene_to_file(target_scene)
    
    # Add a tiny delay for smoother feel
    await get_tree().create_timer(0.05).timeout
    
    # Reveal the new scene
    animation_player.play_backwards(animation_name)
    await animation_player.animation_finished
    
    # Reset the state
    animation_player.play("RESET")
    is_transitioning = false
    transition_finished.emit()

# Set the transition colors to match your game's aesthetics
func set_transition_color(color: Color):
    # Slightly transparent to make it more subtle
    var soft_color = Color(color.r, color.g, color.b, 0.9)
    
    # Update colors for all transitions with null checks
    if fade_rect != null:
        fade_rect.color = soft_color
    
    if sweep_rect != null and sweep_rect.material != null:
        sweep_rect.material.set_shader_parameter("color", soft_color)
        
    # Apply to other transition rects with null checks
    if dissolve_rect != null and dissolve_rect.material != null:
        dissolve_rect.material.set_shader_parameter("color", soft_color)
        
    if iris_rect != null and iris_rect.material != null:
        iris_rect.material.set_shader_parameter("color", soft_color)
