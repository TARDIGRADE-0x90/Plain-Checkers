extends Node

signal clicked

const SIGNAL_MOUSE_ENTERED: String = "mouse_entered"
const ERR_MSG_NOT_CLICKABLE: String = "Error in ClickableComponent - owner does not have cursor detection"

var hovered: bool = false

func _ready() -> void:
	assert(owner.has_signal(SIGNAL_MOUSE_ENTERED), ERR_MSG_NOT_CLICKABLE)

func _process(delta):
	if Input.is_action_just_pressed("lmb") and hovered:
		clicked.emit()

func detect_hover() -> void:
	hovered = true

func clear_hover() -> void:
	hovered = false
