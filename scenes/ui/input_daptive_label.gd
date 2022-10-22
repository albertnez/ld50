""" Shows one text or its variant depending on whether the last input received
	was Keyboard/Mouse input, or a GamePad input.
"""
extends Control
class_name InputAdaptiveLabel

onready var _keyboard_text := $KeyboardText
onready var _gamepad_text := $GamepadText


func _ready() -> void:
	KeyboardOrGamepad.connect("keyboard_or_gamepad_changed", self, "_update")
	_keyboard_text.show()
	_gamepad_text.hide()


func _update(new_input: int) -> void:
	_keyboard_text.visible = (new_input == KeyboardOrGamepad.LastPressed.KEYBOARD)
	_gamepad_text.visible = (new_input == KeyboardOrGamepad.LastPressed.GAMEPAD)
