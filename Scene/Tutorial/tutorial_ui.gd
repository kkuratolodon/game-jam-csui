class_name TutorialUI
extends CanvasLayer

signal next_pressed

var tutorial_panel: TutorialPanel

func _ready():
    # Make sure the UI is hidden by default
    self.visible = false
    
    # Instance the tutorial panel scene
    tutorial_panel = preload("res://Scene/Tutorial/tutorial_panel.tscn").instantiate()
    add_child(tutorial_panel)
    
    # Position the panel in the center bottom of the screen
    tutorial_panel.position = Vector2(
        get_viewport().size.x / 2 - tutorial_panel.size.x / 2,
        get_viewport().size.y - tutorial_panel.size.y - 50  # 50px from bottom
    )
    
    # Connect signals
    tutorial_panel.connect("next_pressed", Callable(self, "_on_next_pressed"))
    
    # Hide by default
    hide_panel()

func set_title(title_text: String):
    tutorial_panel.set_title(title_text)

func set_content(content_text: String):
    tutorial_panel.set_content(content_text)

func show_next_button(visible: bool, inside_panel: bool = true):
    tutorial_panel.show_next_button(visible)

# Renamed from show() to show_panel() to avoid overriding native method
func show_panel(custom_size: Vector2 = Vector2.ZERO, adjust_margins: bool = false):
    # First reset any previous custom size and margins
    reset_panel_size()
    
    self.visible = true
    tutorial_panel.visible = true
    
    if custom_size != Vector2.ZERO:
        # Apply custom size to panel
        tutorial_panel.custom_minimum_size = custom_size
        tutorial_panel.size = custom_size
        
        # Adjust internal margins if needed
        if adjust_margins and tutorial_panel.has_node("Panel/VBoxContainer/MarginContainer"):
            var title_margin = tutorial_panel.get_node("Panel/VBoxContainer/MarginContainer")
            title_margin.add_theme_constant_override("margin_top", 50)  # Move title down

# Add method to reset panel size
func reset_panel_size():
    # Reset panel to default size
    tutorial_panel.custom_minimum_size = Vector2(400, 200)
    tutorial_panel.size = Vector2(400, 200)
    
    # Reset any custom margins
    if tutorial_panel.has_node("Panel/VBoxContainer/MarginContainer"):
        var title_margin = tutorial_panel.get_node("Panel/VBoxContainer/MarginContainer")
        title_margin.add_theme_constant_override("margin_top", 15)

# Renamed from hide() to hide_panel() to avoid overriding native method
func hide_panel():
    # Reset size and margins when hiding the panel
    reset_panel_size()
    self.visible = false
    tutorial_panel.visible = false

func _on_next_pressed():
    emit_signal("next_pressed")
