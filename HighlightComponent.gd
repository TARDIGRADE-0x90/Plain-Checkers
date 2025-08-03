extends Node
class_name HighlightComponent

const HIGHLIGHT_COLOR = Color(0.7, 0.2, 0.7)

func _ready() -> void:
	highlight()

func highlight() -> void:
	owner.set_modulate(HIGHLIGHT_COLOR)
	#print(owner)
