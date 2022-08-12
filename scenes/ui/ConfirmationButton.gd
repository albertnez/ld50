extends Button
class_name ConfirmationButton

signal confirmed()


export (String) var confirmation_text = "Are you sure?"

var _previous_text : String
var _showing_confirmation = false


func _ready() -> void:
	if not is_connected("pressed", self, "_on_ConfirmationButton_pressed"):
		assert(connect("pressed", self, "_on_ConfirmationButton_pressed") == OK)
	if not is_connected("focus_exited", self, "_reset_confirmation"):
		assert(connect("focus_exited", self, "_reset_confirmation") == OK)


func _reset_confirmation() -> void:
	if _showing_confirmation:
		_showing_confirmation = false
		text = _previous_text


func _on_ConfirmationButton_pressed() -> void:
	if _showing_confirmation:
		emit_signal("confirmed")
	else:
		_previous_text = text
	_showing_confirmation = not _showing_confirmation
	text = confirmation_text if _showing_confirmation else _previous_text
