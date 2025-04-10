extends Panel
class_name TutorialPanel

signal next_pressed

@onready var title_label = $Panel/VBoxContainer/MarginContainer/TitleLabel
@onready var content_label = $Panel/VBoxContainer/MarginContainer2/ContentLabel
@onready var next_button = $Panel/VBoxContainer/ButtonContainer/NextButton

func _ready():
    next_button.connect("pressed", Callable(self, "_on_next_button_pressed"))

func set_title(title_text: String):
    title_label.text = title_text

func set_content(content_text: String):
    content_label.text = content_text

func show_next_button(visible: bool):
    next_button.visible = visible
    
    # Adjust content margins based on next button visibility
    var content_margin = $Panel/VBoxContainer/MarginContainer2
    
    if visible:
        # Default margins with button
        content_margin.add_theme_constant_override("margin_bottom", 10)
    else:
        # Increase bottom margin when button is hidden to avoid large gap
        content_margin.add_theme_constant_override("margin_bottom", 20)
    
    # Force layout update
    content_margin.size = content_margin.size

func _on_next_button_pressed():
    print("Next button pressed")
    # Ensure any highlight is hidden before emitting the signal
    var tutorial_highlights = get_tree().get_nodes_in_group("TutorialHighlight")
    for highlight in tutorial_highlights:
        if highlight is ColorRect:
            highlight.visible = false
    
    # Small delay before emitting the signal to avoid blinking highlight
    await get_tree().create_timer(0.05).timeout
    emit_signal("next_pressed")

func show_panel():
    # Make sure the panel is visible
    self.visible = true
