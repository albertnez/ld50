extends Node
# AutoLoad KeyboardOrGamepad

signal keyboard_or_gamepad_changed(new)

# We assume we start with keyboard.
enum LastPressed {
	GAMEPAD,
	KEYBOARD
}
onready var _last_pressed : int = LastPressed.KEYBOARD

func current() -> int:
	return _last_pressed


func _update(new : int) -> void:
	if _last_pressed == new:
		emit_signal("keyboard_or_gamepad_changed", new)
	_last_pressed = new


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		_update(LastPressed.KEYBOARD)
	elif event is InputEventJoypadButton:
		_update(LastPressed.GAMEPAD)
	elif event is InputEventJoypadMotion and (event as InputEventJoypadMotion).axis_value > 0.45:
		_update(LastPressed.GAMEPAD)
