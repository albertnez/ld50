extends Control

onready var _fast_forward_button := $"%FastForwardButton"

func _ready() -> void:
	# warning-ignore:return_value_discarded
	EventBus.connect("level_restart", self, "_on_EventBus_level_restart")


func _on_EventBus_level_restart() -> void:
	_fast_forward_button.pressed = false


func _on_FastForwardButton_toggled(button_pressed: bool) -> void:
	GlobalState.fast_forward = button_pressed


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("fast_forward"):
		_fast_forward_button.pressed = not _fast_forward_button.pressed
