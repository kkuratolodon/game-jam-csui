extends CanvasLayer

# This script contains additional transitions that can be added to the main SceneTransition

# Add a radial wipe transition
static func add_radial_wipe(animation_player):
    var radial_wipe = Animation.new()
    radial_wipe.length = 1.0
    
    # Create a shader material for the ColorRect
    var shader_code = """
    shader_type canvas_item;
    
    uniform float progress : hint_range(0.0, 1.0) = 0.0;
    uniform float smoothness : hint_range(0.0, 1.0) = 0.1;
    
    void fragment() {
        float dist = distance(UV, vec2(0.5));
        float circle = smoothstep(progress, progress + smoothness, dist);
        COLOR.a = circle;
    }
    """
    
    var shader = Shader.new()
    shader.code = shader_code
    var material = ShaderMaterial.new()
    material.shader = shader
    
    # Add track for material
    var track_index = radial_wipe.add_track(Animation.TYPE_VALUE)
    radial_wipe.track_set_path(track_index, "ColorRect:material")
    radial_wipe.track_insert_key(track_index, 0.0, material)
    
    # Add track for progress uniform
    track_index = radial_wipe.add_track(Animation.TYPE_VALUE)
    radial_wipe.track_set_path(track_index, "ColorRect:material:shader_parameter/progress")
    radial_wipe.track_insert_key(track_index, 0.0, 0.0)
    radial_wipe.track_insert_key(track_index, 1.0, 1.0)
    
    # Add animation to library
    animation_player.get_animation_library("").add_animation("radial_wipe", radial_wipe)

# Add a pixel transition
static func add_pixel_transition(animation_player):
    var pixel_transition = Animation.new()
    pixel_transition.length = 1.0
    
    # Create a shader material for the ColorRect
    var shader_code = """
    shader_type canvas_item;
    
    uniform float progress : hint_range(0.0, 1.0) = 0.0;
    uniform float pixels = 100.0;
    
    void fragment() {
        float pixelSize = 1.0 / pixels;
        vec2 uv = floor(UV / pixelSize) * pixelSize;
        
        float random = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
        
        if (random > progress) {
            COLOR.a = 0.0;
        } else {
            COLOR.a = 1.0;
        }
    }
    """
    
    var shader = Shader.new()
    shader.code = shader_code
    var material = ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter("pixels", 100.0)
    
    # Add track for material
    var track_index = pixel_transition.add_track(Animation.TYPE_VALUE)
    pixel_transition.track_set_path(track_index, "ColorRect:material")
    pixel_transition.track_insert_key(track_index, 0.0, material)
    
    # Add track for progress uniform
    track_index = pixel_transition.add_track(Animation.TYPE_VALUE)
    pixel_transition.track_set_path(track_index, "ColorRect:material:shader_parameter/progress")
    pixel_transition.track_insert_key(track_index, 0.0, 0.0)
    pixel_transition.track_insert_key(track_index, 1.0, 1.0)
    
    # Add animation to library
    animation_player.get_animation_library("").add_animation("pixel_transition", pixel_transition)
