extends Control

onready var _back_button: Button = $"%BackButton"


func _ready() -> void:
	_back_button.grab_focus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		EventBus.emit_signal("change_menu_scene", EventBus.TargetMenuScene.MAIN_MENU, 0)


func _on_BackButton_pressed() -> void:
	EventBus.emit_signal("change_menu_scene", EventBus.TargetMenuScene.MAIN_MENU, 0)


func _on_RichTextLabel_meta_clicked(meta) -> void:
	# warning-ignore:return_value_discarded
	OS.shell_open(str(meta))
