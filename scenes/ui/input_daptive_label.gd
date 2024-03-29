""" Shows one text or its variant depending on whether the last input received
	was Keyboard/Mouse input, or a GamePad input.
"""
extends Control
class_name InputAdaptiveLabel

onready var _keyboard_text := $KeyboardText
onready var _gamepad_text := $GamepadText


func _ready() -> void:
	# warning-ignore:return_value_discarded
	KeyboardOrGamepad.connect("keyboard_or_gamepad_changed", self, "_update")
	_update(KeyboardOrGamepad.current())


func _update(new_input: int) -> void:
	_keyboard_text.visible = (new_input == KeyboardOrGamepad.LastPressed.KEYBOARD)
	_gamepad_text.visible = (new_input == KeyboardOrGamepad.LastPressed.GAMEPAD)
